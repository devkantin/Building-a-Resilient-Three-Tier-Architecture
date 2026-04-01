output "web_instance_ids" {
  description = "Web instance IDs"
  value       = aws_instance.web[*].id
}

output "web_instance_arns" {
  description = "Web instance ARNs"
  value       = aws_instance.web[*].arn
}

output "app_instance_ids" {
  description = "App instance IDs"
  value       = aws_instance.app[*].id
}

output "app_instance_arns" {
  description = "App instance ARNs"
  value       = aws_instance.app[*].arn
}

output "db_instance_ids" {
  description = "DB instance IDs"
  value       = aws_instance.db[*].id
}

output "db_instance_arns" {
  description = "DB instance ARNs"
  value       = aws_instance.db[*].arn
}
