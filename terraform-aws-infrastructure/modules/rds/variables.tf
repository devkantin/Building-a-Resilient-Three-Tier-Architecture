variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "db_security_group_id" {
  description = "DB security group ID"
  type        = string
}

variable "db_identifier" {
  description = "Database identifier"
  type        = string
}

variable "db_engine" {
  description = "Database engine"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "storage_type" {
  description = "Storage type"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Backup retention days"
  type        = number
}

variable "backup_window" {
  description = "Backup window"
  type        = string
}

variable "multi_az" {
  description = "Multi-AZ enabled"
  type        = bool
}

variable "enable_backtrack" {
  description = "Enable backtrack"
  type        = bool
  default     = false
}

variable "enable_iam_auth" {
  description = "Enable IAM authentication"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
