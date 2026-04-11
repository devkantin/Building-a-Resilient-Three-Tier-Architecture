variable "project" {
  description = "Project name used for all resource naming and tagging"
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "primary_region" {
  description = "Primary AWS region (active traffic)"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster Recovery AWS region (warm standby)"
  type        = string
  default     = "us-west-2"
}

# ── Primary region networking ─────────────────────────────────
variable "primary_vpc_cidr" {
  description = "VPC CIDR for the primary region"
  type        = string
  default     = "10.0.0.0/16"
}

variable "primary_azs" {
  description = "Availability zones in the primary region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "primary_public_subnets" {
  description = "Public subnet CIDRs in the primary region (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "primary_web_subnets" {
  description = "Web-tier private subnet CIDRs in the primary region"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "primary_app_subnets" {
  description = "App-tier private subnet CIDRs in the primary region"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "primary_db_subnets" {
  description = "DB-tier private subnet CIDRs in the primary region"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

# ── DR region networking ──────────────────────────────────────
variable "dr_vpc_cidr" {
  description = "VPC CIDR for the DR region"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dr_azs" {
  description = "Availability zones in the DR region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "dr_public_subnets" {
  description = "Public subnet CIDRs in the DR region"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "dr_web_subnets" {
  description = "Web-tier private subnet CIDRs in the DR region"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "dr_app_subnets" {
  description = "App-tier private subnet CIDRs in the DR region"
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24"]
}

variable "dr_db_subnets" {
  description = "DB-tier private subnet CIDRs in the DR region"
  type        = list(string)
  default     = ["10.1.31.0/24", "10.1.32.0/24"]
}

# ── Compute ───────────────────────────────────────────────────
variable "web_instance_type" {
  description = "EC2 instance type for web-tier servers"
  type        = string
  default     = "t3.small"
}

variable "app_instance_type" {
  description = "EC2 instance type for app-tier servers"
  type        = string
  default     = "t3.small"
}

variable "web_min_size" {
  description = "Minimum number of web-tier instances"
  type        = number
  default     = 1
}

variable "web_max_size" {
  description = "Maximum number of web-tier instances"
  type        = number
  default     = 4
}

variable "web_desired_capacity" {
  description = "Desired number of web-tier instances"
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "Minimum number of app-tier instances"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum number of app-tier instances"
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "Desired number of app-tier instances"
  type        = number
  default     = 2
}

variable "trusted_cidr" {
  description = "CIDR block allowed SSH access to bastion hosts"
  type        = string
  default     = "0.0.0.0/0"
}

# ── Database ──────────────────────────────────────────────────
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "deletion_protection" {
  description = "Enable deletion protection on RDS instances"
  type        = bool
  default     = false
}

# ── DNS / CDN ─────────────────────────────────────────────────
variable "domain_name" {
  description = "Route53 domain name (must be a hosted zone you own)"
  type        = string
  default     = "threetier.ankitjodhani.club"
}

variable "create_route53_zone" {
  description = "Set to false if the hosted zone already exists in AWS"
  type        = bool
  default     = true
}

# ── Tags ──────────────────────────────────────────────────────
variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
