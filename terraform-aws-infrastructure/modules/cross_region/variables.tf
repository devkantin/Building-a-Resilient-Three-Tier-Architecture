terraform {
  required_providers {
    aws_primary = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    aws_secondary = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "primary_db_arn" {
  description = "Primary database ARN"
  type        = string
}

variable "secondary_db_arn" {
  description = "Secondary database ARN"
  type        = string
}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
