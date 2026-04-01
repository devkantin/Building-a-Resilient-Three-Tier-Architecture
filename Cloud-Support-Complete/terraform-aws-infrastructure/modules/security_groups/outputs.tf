output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "Web server security group ID"
  value       = aws_security_group.web.id
}

output "app_sg_id" {
  description = "App server security group ID"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}
