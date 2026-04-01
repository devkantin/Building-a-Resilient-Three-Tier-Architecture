# Monitoring and Alerting Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alarms"
    }
  )
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/application/${var.project_name}"
  retention_in_days = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logs"
    }
  )
}

# ALB Target Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "${var.project_name}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Alert when ALB response time exceeds 1 second"

  dimensions = {
    LoadBalancer = data.aws_lb.primary.arn_suffix
  }

  tags = var.tags
}

# ALB Unhealthy Host Count Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Alert when ALB has unhealthy hosts"

  dimensions = {
    LoadBalancer = data.aws_lb.primary.arn_suffix
  }

  tags = var.tags
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Alert when RDS CPU exceeds 80%"

  dimensions = {
    DBInstanceIdentifier = var.primary_db_id
  }

  tags = var.tags
}

# RDS Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Alert when RDS connections exceed 80% of max"

  dimensions = {
    DBInstanceIdentifier = var.primary_db_id
  }

  tags = var.tags
}

# RDS Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240  # 10 GB
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Alert when RDS free storage is below 10GB"

  dimensions = {
    DBInstanceIdentifier = var.primary_db_id
  }

  tags = var.tags
}

# Data source for primary ALB
data "aws_lb" "primary" {
  arn = var.primary_alb_arn
}

# Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }],
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Application Metrics"
        }
      }
    ]
  })
}
