# Route53 Module for DNS and Failover

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Hosted Zone (create if domain_name is provided)
resource "aws_route53_zone" "main" {
  count = var.domain_name != "example.com" ? 1 : 0
  name  = var.domain_name

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}

# Primary ALB Record
resource "aws_route53_record" "alb_primary" {
  count   = var.domain_name != "example.com" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.primary_region_alb_dns
    zone_id                = data.aws_elb_hosted_zone_id.primary.id
    evaluate_target_health = true
  }

  set_identifier = "Primary"

  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Secondary ALB Record  
resource "aws_route53_record" "alb_secondary" {
  count   = var.domain_name != "example.com" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.secondary_region_alb_dns
    zone_id                = data.aws_elb_hosted_zone_id.secondary.id
    evaluate_target_health = true
  }

  set_identifier = "Secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }
}

# Data sources for ALB hosted zone IDs
data "aws_elb_hosted_zone_id" "primary" {
  provider = aws
}

data "aws_elb_hosted_zone_id" "secondary" {
  provider = aws
}

# Health Check for Primary ALB
resource "aws_route53_health_check" "primary_alb" {
  count             = var.domain_name != "example.com" ? 1 : 0
  fqdn              = var.primary_region_alb_dns
  port              = 80
  type              = "HTTP"
  failure_threshold = 3

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-primary-health-check"
    }
  )
}

# Health Check for Secondary ALB
resource "aws_route53_health_check" "secondary_alb" {
  count             = var.domain_name != "example.com" ? 1 : 0
  fqdn              = var.secondary_region_alb_dns
  port              = 80
  type              = "HTTP"
  failure_threshold = 3

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-secondary-health-check"
    }
  )
}

# CloudWatch Alarm for Primary Health
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  count           = var.domain_name != "example.com" ? 1 : 0
  alarm_name      = "${var.project_name}-primary-lb-health"
  alarm_actions   = [aws_sns_topic.alerts[0].arn]
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  metric_name     = "HealthCheckStatus"
  namespace       = "AWS/Route53"
  period          = 60
  statistic       = "Minimum"
  threshold       = 1

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary_alb[0].id
  }

  tags = var.tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  count = var.domain_name != "example.com" ? 1 : 0
  name  = "${var.project_name}-route53-alerts"

  tags = var.tags
}
