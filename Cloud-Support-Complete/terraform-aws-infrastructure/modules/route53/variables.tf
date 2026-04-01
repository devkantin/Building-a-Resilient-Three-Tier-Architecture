variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "primary_region_alb_dns" {
  description = "Primary region ALB DNS"
  type        = string
}

variable "secondary_region_alb_dns" {
  description = "Secondary region ALB DNS"
  type        = string
}

variable "domain_name" {
  description = "Domain name for Route53"
  type        = string
  default     = "example.com"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
