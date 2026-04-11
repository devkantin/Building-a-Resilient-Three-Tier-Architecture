output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "waf_web_acl_arn" {
  description = "WAF WebACL ARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.zone_id
}

output "route53_nameservers" {
  description = "Route53 nameservers (update your domain registrar)"
  value       = var.create_route53_zone ? aws_route53_zone.this[0].name_servers : []
}

output "primary_health_check_id" {
  description = "Route53 health check ID for primary ALB"
  value       = aws_route53_health_check.primary.id
}

output "dr_health_check_id" {
  description = "Route53 health check ID for DR ALB"
  value       = aws_route53_health_check.dr.id
}
