variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "primary_alb_arn" {
  description = "Primary ALB ARN"
  type        = string
}

variable "secondary_alb_arn" {
  description = "Secondary ALB ARN"
  type        = string
}

variable "primary_db_id" {
  description = "Primary database ID"
  type        = string
}

variable "secondary_db_id" {
  description = "Secondary database ID"
  type        = string
}

variable "alarm_email" {
  description = "Email for alarms"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
