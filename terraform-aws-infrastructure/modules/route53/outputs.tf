output "zone_id" {
  description = "Hosted zone ID"
  value       = try(aws_route53_zone.main[0].zone_id, null)
}

output "zone_name_servers" {
  description = "Hosted zone name servers"
  value       = try(aws_route53_zone.main[0].name_servers, null)
}

output "record_name" {
  description = "Route53 record name"
  value       = try(aws_route53_record.alb_primary[0].fqdn, null)
}

output "primary_health_check_id" {
  description = "Primary health check ID"
  value       = try(aws_route53_health_check.primary_alb[0].id, null)
}

output "secondary_health_check_id" {
  description = "Secondary health check ID"
  value       = try(aws_route53_health_check.secondary_alb[0].id, null)
}
