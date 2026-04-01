variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs map"
  type        = map(string)
}

variable "web_sg_id" {
  description = "Web server security group ID"
  type        = string
}

variable "app_sg_id" {
  description = "App server security group ID"
  type        = string
}

variable "db_sg_id" {
  description = "Database security group ID"
  type        = string
}

variable "web_instance_count" {
  description = "Number of web instances"
  type        = number
}

variable "app_instance_count" {
  description = "Number of app instances"
  type        = number
}

variable "db_instance_count" {
  description = "Number of database instances"
  type        = number
}

variable "instance_type_web" {
  description = "Instance type for web servers"
  type        = string
}

variable "instance_type_app" {
  description = "Instance type for app servers"
  type        = string
}

variable "instance_type_db" {
  description = "Instance type for DB servers"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
