output "cloudfront_domain" {
  description = "CloudFront distribution domain name (use this as your site URL)"
  value       = module.global.cloudfront_domain_name
}

output "route53_nameservers" {
  description = "Route53 nameservers — update your domain registrar with these"
  value       = module.global.route53_nameservers
}

output "primary_alb_dns" {
  description = "Primary region external ALB DNS name"
  value       = module.primary.alb_ext_dns_name
}

output "dr_alb_dns" {
  description = "DR region external ALB DNS name"
  value       = module.dr.alb_ext_dns_name
}

output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = module.primary.vpc_id
}

output "dr_vpc_id" {
  description = "DR VPC ID"
  value       = module.dr.vpc_id
}

output "primary_bastion_public_ip" {
  description = "Primary bastion host public IP"
  value       = module.primary.bastion_public_ip
}

output "dr_bastion_public_ip" {
  description = "DR bastion host public IP"
  value       = module.dr.bastion_public_ip
}

output "primary_db_endpoint" {
  description = "Primary RDS endpoint"
  value       = module.primary.db_endpoint
  sensitive   = true
}

output "dr_db_endpoint" {
  description = "DR RDS read-replica endpoint"
  value       = module.dr.db_endpoint
  sensitive   = true
}

output "backup_vault_primary_arn" {
  description = "ARN of the primary backup vault"
  value       = module.backup.primary_vault_arn
}

output "backup_vault_dr_arn" {
  description = "ARN of the DR backup vault"
  value       = module.backup.dr_vault_arn
}
