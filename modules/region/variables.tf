variable "name" {
  description = "Name prefix for all resources in this region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs (exactly 2)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (NAT + Bastion)"
  type        = list(string)
}

variable "web_subnet_cidrs" {
  description = "CIDR blocks for web-tier private subnets"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for app-tier private subnets"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for DB-tier private subnets"
  type        = list(string)
}

variable "web_instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "app_instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.small"
}

variable "web_min_size" {
  description = "Web ASG minimum capacity"
  type        = number
  default     = 1
}

variable "web_max_size" {
  description = "Web ASG maximum capacity"
  type        = number
  default     = 4
}

variable "web_desired_capacity" {
  description = "Web ASG desired capacity"
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "App ASG minimum capacity"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "App ASG maximum capacity"
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "App ASG desired capacity"
  type        = number
  default     = 2
}

variable "trusted_cidr" {
  description = "CIDR allowed SSH into bastion"
  type        = string
  default     = "0.0.0.0/0"
}

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
  description = "RDS deletion protection"
  type        = bool
  default     = false
}

variable "is_dr" {
  description = "Set to true for the DR region — creates RDS read replica instead of primary"
  type        = bool
  default     = false
}

variable "primary_db_instance_arn" {
  description = "ARN of the primary RDS instance (required when is_dr = true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN in the DR region for encrypting the cross-region read replica. Required when is_dr = true."
  type        = string
  default     = null
}
