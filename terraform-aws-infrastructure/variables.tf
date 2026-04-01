# General Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "multi-region-app"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# Region Configuration
variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration - Primary Region
variable "primary_vpc_cidr" {
  description = "CIDR block for primary region VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "primary_public_subnets" {
  description = "Public subnet CIDR blocks for primary region"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
}

variable "primary_private_subnets" {
  description = "Private subnet CIDR blocks for primary region"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.10.0/24"
    "us-east-1b" = "10.0.11.0/24"
  }
}

# VPC Configuration - Secondary Region
variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary region VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "secondary_public_subnets" {
  description = "Public subnet CIDR blocks for secondary region"
  type        = map(string)
  default = {
    "us-west-2a" = "10.1.1.0/24"
    "us-west-2b" = "10.1.2.0/24"
  }
}

variable "secondary_private_subnets" {
  description = "Private subnet CIDR blocks for secondary region"
  type        = map(string)
  default = {
    "us-west-2a" = "10.1.10.0/24"
    "us-west-2b" = "10.1.11.0/24"
  }
}

# EC2 Configuration
variable "web_instance_count" {
  description = "Number of web server instances per region"
  type        = number
  default     = 2

  validation {
    condition     = var.web_instance_count >= 1 && var.web_instance_count <= 10
    error_message = "Web instance count must be between 1 and 10."
  }
}

variable "app_instance_count" {
  description = "Number of application server instances per region"
  type        = number
  default     = 2

  validation {
    condition     = var.app_instance_count >= 1 && var.app_instance_count <= 10
    error_message = "App instance count must be between 1 and 10."
  }
}

variable "db_instance_count" {
  description = "Number of database server instances per region"
  type        = number
  default     = 2

  validation {
    condition     = var.db_instance_count >= 1 && var.db_instance_count <= 5
    error_message = "DB instance count must be between 1 and 5."
  }
}

variable "instance_type_web" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.medium"
}

variable "instance_type_app" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.medium"
}

variable "instance_type_db" {
  description = "EC2 instance type for database servers"
  type        = string
  default     = "t3.large"
}

# RDS Configuration
variable "db_engine" {
  description = "Database engine (postgres, mysql, mariadb, oracle-ee, sqlserver-ex)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "oracle-ee", "sqlserver-ex"], var.db_engine)
    error_message = "Database engine must be a supported RDS engine."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.2"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be gp2, gp3, io1, or io2."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "enable_backtrack" {
  description = "Enable Aurora backtrack (PostgreSQL only)"
  type        = bool
  default     = false
}

variable "enable_iam_auth" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

# Route53 Configuration
variable "domain_name" {
  description = "Domain name for Route53 (optional)"
  type        = string
  default     = "example.com"
}

# Monitoring Configuration
variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "ops@example.com"
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
