variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "backup_vault_name" {
  description = "Backup vault name"
  type        = string
}

variable "resource_arns" {
  description = "ARNs of resources to backup"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
