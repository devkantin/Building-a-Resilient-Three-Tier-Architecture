output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_identifier" {
  description = "RDS database identifier"
  value       = aws_db_instance.main.identifier
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_arn" {
  description = "RDS database ARN"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}
