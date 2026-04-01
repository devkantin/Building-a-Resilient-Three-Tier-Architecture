# VPC Outputs - Primary Region
output "primary_vpc_id" {
  description = "Primary region VPC ID"
  value       = module.primary_vpc.vpc_id
}

output "primary_public_subnet_ids" {
  description = "Primary region public subnet IDs"
  value       = module.primary_vpc.public_subnet_ids
}

output "primary_private_subnet_ids" {
  description = "Primary region private subnet IDs"
  value       = module.primary_vpc.private_subnet_ids
}

# VPC Outputs - Secondary Region
output "secondary_vpc_id" {
  description = "Secondary region VPC ID"
  value       = module.secondary_vpc.vpc_id
}

output "secondary_public_subnet_ids" {
  description = "Secondary region public subnet IDs"
  value       = module.secondary_vpc.public_subnet_ids
}

output "secondary_private_subnet_ids" {
  description = "Secondary region private subnet IDs"
  value       = module.secondary_vpc.private_subnet_ids
}

# Load Balancer Outputs - Primary Region
output "primary_alb_dns_name" {
  description = "Primary region ALB DNS name"
  value       = module.primary_load_balancer.alb_dns_name
}

output "primary_alb_arn" {
  description = "Primary region ALB ARN"
  value       = module.primary_load_balancer.alb_arn
}

output "primary_alb_zone_id" {
  description = "Primary region ALB zone ID"
  value       = module.primary_load_balancer.alb_zone_id
}

# Load Balancer Outputs - Secondary Region
output "secondary_alb_dns_name" {
  description = "Secondary region ALB DNS name"
  value       = module.secondary_load_balancer.alb_dns_name
}

output "secondary_alb_arn" {
  description = "Secondary region ALB ARN"
  value       = module.secondary_load_balancer.alb_arn
}

output "secondary_alb_zone_id" {
  description = "Secondary region ALB zone ID"
  value       = module.secondary_load_balancer.alb_zone_id
}

# EC2 Outputs - Primary Region
output "primary_web_instance_ids" {
  description = "Primary region web server instance IDs"
  value       = module.primary_ec2_instances.web_instance_ids
}

output "primary_app_instance_ids" {
  description = "Primary region app server instance IDs"
  value       = module.primary_ec2_instances.app_instance_ids
}

output "primary_db_instance_ids" {
  description = "Primary region database server instance IDs"
  value       = module.primary_ec2_instances.db_instance_ids
}

# EC2 Outputs - Secondary Region
output "secondary_web_instance_ids" {
  description = "Secondary region web server instance IDs"
  value       = module.secondary_ec2_instances.web_instance_ids
}

output "secondary_app_instance_ids" {
  description = "Secondary region app server instance IDs"
  value       = module.secondary_ec2_instances.app_instance_ids
}

output "secondary_db_instance_ids" {
  description = "Secondary region database server instance IDs"
  value       = module.secondary_ec2_instances.db_instance_ids
}

# RDS Outputs - Primary Region
output "primary_db_endpoint" {
  description = "Primary region RDS database endpoint"
  value       = module.primary_database.db_endpoint
  sensitive   = true
}

output "primary_db_identifier" {
  description = "Primary region RDS database identifier"
  value       = module.primary_database.db_identifier
}

output "primary_db_arn" {
  description = "Primary region RDS database ARN"
  value       = module.primary_database.db_arn
}

# RDS Outputs - Secondary Region
output "secondary_db_endpoint" {
  description = "Secondary region RDS database endpoint"
  value       = module.secondary_database.db_endpoint
  sensitive   = true
}

output "secondary_db_identifier" {
  description = "Secondary region RDS database identifier"
  value       = module.secondary_database.db_identifier
}

output "secondary_db_arn" {
  description = "Secondary region RDS database ARN"
  value       = module.secondary_database.db_arn
}

# Backup Outputs - Primary Region
output "primary_backup_vault_arn" {
  description = "Primary region backup vault ARN"
  value       = module.primary_backup.backup_vault_arn
}

# Backup Outputs - Secondary Region
output "secondary_backup_vault_arn" {
  description = "Secondary region backup vault ARN"
  value       = module.secondary_backup.backup_vault_arn
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = try(module.route53.zone_id, null)
}

output "route53_record_name" {
  description = "Route53 record name for failover"
  value       = try(module.route53.record_name, null)
}

# Monitoring Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = module.monitoring.sns_topic_arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}

# Connection Information
output "connection_info" {
  description = "Summary of connection information"
  value = {
    primary_region         = var.primary_region
    secondary_region       = var.secondary_region
    primary_alb_dns        = module.primary_load_balancer.alb_dns_name
    secondary_alb_dns      = module.secondary_load_balancer.alb_dns_name
    primary_db_endpoint    = module.primary_database.db_endpoint
    secondary_db_endpoint  = module.secondary_database.db_endpoint
  }
  sensitive = true
}
