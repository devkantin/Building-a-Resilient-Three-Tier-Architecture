variable "name" {
  description = "Name prefix for backup resources"
  type        = string
}

variable "primary_db_instance_arn" {
  description = "ARN of the primary RDS instance to back up"
  type        = string
  default     = null
}

variable "dr_db_instance_arn" {
  description = "ARN of the DR RDS read replica to back up"
  type        = string
  default     = null
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule (UTC)"
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "retention_days" {
  description = "Number of days to retain backups in each vault"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all backup resources"
  type        = map(string)
  default     = {}
}
