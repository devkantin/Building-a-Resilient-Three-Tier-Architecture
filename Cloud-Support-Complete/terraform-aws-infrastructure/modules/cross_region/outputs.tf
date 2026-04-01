output "read_replica_arn" {
  description = "Read replica ARN"
  value       = aws_db_instance.read_replica.arn
}

output "read_replica_endpoint" {
  description = "Read replica endpoint"
  value       = aws_db_instance.read_replica.endpoint
  sensitive   = true
}
