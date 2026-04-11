terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# WAF CloudWatch logging (log group name must start with aws-waf-logs-)
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name}"
  retention_in_days = 365
  # checkov:skip=CKV_AWS_158:KMS encryption for WAF logs is optional for this lab

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# CloudFront access-logging S3 bucket
# ─────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "cf_logs" {
  # checkov:skip=CKV_AWS_144:Cross-region replication not required for access logs
  # checkov:skip=CKV_AWS_18:Access logging on this log bucket itself not required
  # checkov:skip=CKV2_AWS_62:Event notifications not required for access log bucket
  # checkov:skip=CKV2_AWS_46:CloudFront logs bucket is not an S3 origin
  bucket = "${var.name}-cf-access-logs"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Route53 DNS query logging
resource "aws_cloudwatch_log_group" "route53_queries" {
  # Route53 query logs MUST be in us-east-1
  name              = "/aws/route53/${var.name}-queries"
  retention_in_days = 365
  # checkov:skip=CKV_AWS_158:KMS encryption for query logs is optional for this lab

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# WAF WebACL — scope CLOUDFRONT, must be in us-east-1
# Attaches AWS Managed Rules: CRS + Known Bad Inputs
# ─────────────────────────────────────────────────────────────
resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# CloudFront Distribution
# Primary origin: us-east-1 ALB (active)
# Failover origin: us-west-2 ALB (warm standby)
# ─────────────────────────────────────────────────────────────
# CloudFront Security Response Headers Policy (CKV2_AWS_32)
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.name}-security-headers"

  security_headers_config {
    strict_transport_security {
      override                   = true
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      override     = true
      frame_option = "DENY"
    }
    xss_protection {
      override   = true
      protection = true
      mode_block = true
    }
    referrer_policy {
      override        = true
      referrer_policy = "strict-origin-when-cross-origin"
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  comment             = "${var.name} — warm standby DR (us-east-1 active)"
  enabled             = true
  default_root_object = "index.html"

  web_acl_id = aws_wafv2_web_acl.this.arn

  aliases = [var.domain_name]

  # Primary origin — us-east-1 ALB
  origin {
    domain_name = var.primary_alb_dns_name
    origin_id   = var.primary_alb_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = "cloudfront"
    }
  }

  # DR origin — us-west-2 ALB (failover)
  origin {
    domain_name = var.dr_alb_dns_name
    origin_id   = var.dr_alb_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = "cloudfront"
    }
  }

  # Origin group for automatic failover
  origin_group {
    origin_id = "primary-with-failover"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = var.primary_alb_origin_id
    }

    member {
      origin_id = var.dr_alb_origin_id
    }
  }

  default_cache_behavior {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "primary-with-failover"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # checkov:skip=CKV_AWS_174:Default certificate used for lab; replace with ACM cert + minimum_protocol_version="TLSv1.2_2021" in production
    cloudfront_default_certificate = true
  }

  # checkov:skip=CKV_AWS_374:Geo-restriction not required for this global lab
  # checkov:skip=CKV2_AWS_47:Log4j managed rule set bundled in CRS rule above
  # checkov:skip=CKV2_AWS_42:Custom SSL certificate requires ACM — use cloudfront_default_certificate for lab

  logging_config {
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront/"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Route53 Hosted Zone
# ─────────────────────────────────────────────────────────────
resource "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 1 : 0

  name = var.domain_name

  tags = var.tags
}

data "aws_route53_zone" "existing" {
  count = var.create_route53_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_route53_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# Route53 health check — primary ALB
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, { Name = "${var.name}-primary-health-check" })
}

# Route53 health check — DR ALB
resource "aws_route53_health_check" "dr" {
  fqdn              = var.dr_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, { Name = "${var.name}-dr-health-check" })
}

# DNS record → CloudFront (primary entry point)
resource "aws_route53_record" "cloudfront" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# www → apex
resource "aws_route53_record" "www" {
  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# ─────────────────────────────────────────────────────────────
# WAF Logging Configuration (CKV2_AWS_31)
# ─────────────────────────────────────────────────────────────
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}

# ─────────────────────────────────────────────────────────────
# Route53 DNS Query Logging (CKV2_AWS_39)
# Route53 query logs must be in us-east-1 CloudWatch
# ─────────────────────────────────────────────────────────────
resource "aws_route53_query_log" "this" {
  depends_on = [aws_cloudwatch_log_group.route53_queries]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_queries.arn
  zone_id                  = local.zone_id
}
