output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "web_subnet_ids" {
  description = "Web-tier subnet IDs"
  value       = module.vpc.private_subnets
}

output "app_subnet_ids" {
  description = "App-tier subnet IDs"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "DB-tier subnet IDs"
  value       = module.vpc.database_subnets
}

output "alb_ext_dns_name" {
  description = "External ALB DNS name"
  value       = module.alb_ext.dns_name
}

output "alb_ext_zone_id" {
  description = "External ALB hosted zone ID (for Route53 alias)"
  value       = module.alb_ext.zone_id
}

output "alb_int_dns_name" {
  description = "Internal ALB DNS name"
  value       = module.alb_int.dns_name
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = module.bastion.public_ip
}

output "db_instance_arn" {
  description = "RDS instance ARN (primary) or read-replica ARN (DR)"
  value = var.is_dr ? (
    length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].arn : null
    ) : (
    length(module.rds) > 0 ? module.rds[0].db_instance_arn : null
  )
}

output "db_endpoint" {
  description = "RDS endpoint"
  sensitive   = true
  value = var.is_dr ? (
    length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].endpoint : null
    ) : (
    length(module.rds) > 0 ? module.rds[0].db_instance_endpoint : null
  )
}

output "web_asg_name" {
  description = "Web-tier Auto Scaling Group name"
  value       = module.web_asg.autoscaling_group_name
}

output "app_asg_name" {
  description = "App-tier Auto Scaling Group name"
  value       = module.app_asg.autoscaling_group_name
}
