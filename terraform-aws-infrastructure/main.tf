terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to enable remote state in S3
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# Primary Region Provider (us-east-1)
provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = local.common_tags
  }
}

# Secondary Region Provider (us-west-2)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = local.common_tags
  }
}

# Local variables for common tags
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    CreatedAt   = timestamp()
  }
}

# ============================================================================
# PRIMARY REGION (us-east-1)
# ============================================================================

module "primary_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.primary
  }

  project_name   = var.project_name
  environment    = var.environment
  region         = var.primary_region
  vpc_cidr       = var.primary_vpc_cidr
  public_subnets = var.primary_public_subnets
  private_subnets = var.primary_private_subnets
  
  tags = local.common_tags
}

module "primary_security_groups" {
  source = "./modules/security_groups"
  providers = {
    aws = aws.primary
  }

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.primary_vpc.vpc_id

  tags = local.common_tags
}

module "primary_load_balancer" {
  source = "./modules/load_balancer"
  providers = {
    aws = aws.primary
  }

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.primary_vpc.vpc_id
  public_subnets        = module.primary_vpc.public_subnet_ids
  alb_security_group_id = module.primary_security_groups.alb_sg_id

  tags = local.common_tags
}

module "primary_ec2_instances" {
  source = "./modules/ec2"
  providers = {
    aws = aws.primary
  }

  project_name       = var.project_name
  environment        = var.environment
  region             = var.primary_region
  private_subnets   = module.primary_vpc.private_subnet_ids
  web_sg_id         = module.primary_security_groups.web_sg_id
  app_sg_id         = module.primary_security_groups.app_sg_id
  db_sg_id          = module.primary_security_groups.db_sg_id
  
  web_instance_count = var.web_instance_count
  app_instance_count = var.app_instance_count
  db_instance_count  = var.db_instance_count
  
  instance_type_web = var.instance_type_web
  instance_type_app = var.instance_type_app
  instance_type_db  = var.instance_type_db

  alb_target_group_arn = module.primary_load_balancer.target_group_arn
  
  tags = local.common_tags

  depends_on = [module.primary_load_balancer]
}

module "primary_database" {
  source = "./modules/rds"
  providers = {
    aws = aws.primary
  }

  project_name            = var.project_name
  environment             = var.environment
  db_subnet_group_name   = module.primary_vpc.db_subnet_group_name
  db_security_group_id   = module.primary_security_groups.db_sg_id
  
  db_identifier          = "${var.project_name}-primary-db"
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  
  db_username            = var.db_username
  db_password            = var.db_password
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  multi_az               = var.multi_az
  
  enable_backtrack       = var.enable_backtrack
  enable_iam_auth        = var.enable_iam_auth

  tags = local.common_tags
}

module "primary_backup" {
  source = "./modules/backup"
  providers = {
    aws = aws.primary
  }

  project_name       = var.project_name
  environment        = var.environment
  region             = var.primary_region
  
  backup_vault_name = "${var.project_name}-primary-vault"
  
  resource_arns = [
    module.primary_database.db_arn,
    module.primary_ec2_instances.web_instance_arns,
    module.primary_ec2_instances.app_instance_arns
  ]

  tags = local.common_tags
}

# ============================================================================
# SECONDARY REGION (us-west-2)
# ============================================================================

module "secondary_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.secondary
  }

  project_name   = var.project_name
  environment    = var.environment
  region         = var.secondary_region
  vpc_cidr       = var.secondary_vpc_cidr
  public_subnets = var.secondary_public_subnets
  private_subnets = var.secondary_private_subnets
  
  tags = local.common_tags
}

module "secondary_security_groups" {
  source = "./modules/security_groups"
  providers = {
    aws = aws.secondary
  }

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.secondary_vpc.vpc_id

  tags = local.common_tags
}

module "secondary_load_balancer" {
  source = "./modules/load_balancer"
  providers = {
    aws = aws.secondary
  }

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.secondary_vpc.vpc_id
  public_subnets        = module.secondary_vpc.public_subnet_ids
  alb_security_group_id = module.secondary_security_groups.alb_sg_id

  tags = local.common_tags
}

module "secondary_ec2_instances" {
  source = "./modules/ec2"
  providers = {
    aws = aws.secondary
  }

  project_name       = var.project_name
  environment        = var.environment
  region             = var.secondary_region
  private_subnets   = module.secondary_vpc.private_subnet_ids
  web_sg_id         = module.secondary_security_groups.web_sg_id
  app_sg_id         = module.secondary_security_groups.app_sg_id
  db_sg_id          = module.secondary_security_groups.db_sg_id
  
  web_instance_count = var.web_instance_count
  app_instance_count = var.app_instance_count
  db_instance_count  = var.db_instance_count
  
  instance_type_web = var.instance_type_web
  instance_type_app = var.instance_type_app
  instance_type_db  = var.instance_type_db

  alb_target_group_arn = module.secondary_load_balancer.target_group_arn
  
  tags = local.common_tags

  depends_on = [module.secondary_load_balancer]
}

module "secondary_database" {
  source = "./modules/rds"
  providers = {
    aws = aws.secondary
  }

  project_name            = var.project_name
  environment             = var.environment
  db_subnet_group_name   = module.secondary_vpc.db_subnet_group_name
  db_security_group_id   = module.secondary_security_groups.db_sg_id
  
  db_identifier          = "${var.project_name}-secondary-db"
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  
  db_username            = var.db_username
  db_password            = var.db_password
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  multi_az               = var.multi_az
  
  enable_backtrack       = var.enable_backtrack
  enable_iam_auth        = var.enable_iam_auth

  tags = local.common_tags
}

module "secondary_backup" {
  source = "./modules/backup"
  providers = {
    aws = aws.secondary
  }

  project_name       = var.project_name
  environment        = var.environment
  region             = var.secondary_region
  
  backup_vault_name = "${var.project_name}-secondary-vault"
  
  resource_arns = [
    module.secondary_database.db_arn,
    module.secondary_ec2_instances.web_instance_arns,
    module.secondary_ec2_instances.app_instance_arns
  ]

  tags = local.common_tags
}

# ============================================================================
# CROSS-REGION REPLICATION & MONITORING
# ============================================================================

module "cross_region_replication" {
  source = "./modules/cross_region"
  providers = {
    aws_primary   = aws.primary
    aws_secondary = aws.secondary
  }

  project_name          = var.project_name
  environment           = var.environment
  
  primary_db_arn        = module.primary_database.db_arn
  secondary_db_arn      = module.secondary_database.db_arn
  
  primary_region        = var.primary_region
  secondary_region      = var.secondary_region

  tags = local.common_tags
}

module "route53" {
  source = "./modules/route53"
  providers = {
    aws = aws.primary
  }

  project_name = var.project_name
  environment  = var.environment
  
  primary_region_alb_dns   = module.primary_load_balancer.alb_dns_name
  secondary_region_alb_dns = module.secondary_load_balancer.alb_dns_name
  
  domain_name            = var.domain_name
  
  tags = local.common_tags
}

# ============================================================================
# MONITORING & LOGGING
# ============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  providers = {
    aws = aws.primary
  }

  project_name = var.project_name
  environment  = var.environment
  
  primary_alb_arn      = module.primary_load_balancer.alb_arn
  secondary_alb_arn    = module.secondary_load_balancer.alb_arn
  primary_db_id        = module.primary_database.db_identifier
  secondary_db_id      = module.secondary_database.db_identifier
  
  alarm_email          = var.alarm_email

  tags = local.common_tags
}
