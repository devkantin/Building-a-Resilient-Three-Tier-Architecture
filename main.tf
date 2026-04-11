locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      DR_Strategy = "warm-standby"
    },
    var.tags
  )
}

# ─────────────────────────────────────────────────────────────
# KMS key in DR region — required for cross-region encrypted RDS replica
# ─────────────────────────────────────────────────────────────
resource "aws_kms_key" "dr_rds" {
  provider = aws.dr

  description             = "${var.project}-${var.environment} DR RDS replica encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "dr_rds" {
  provider = aws.dr

  name          = "alias/${var.project}-${var.environment}-dr-rds"
  target_key_id = aws_kms_key.dr_rds.key_id
}

# ─────────────────────────────────────────────────────────────
# PRIMARY REGION — us-east-1 (Active traffic)
# ─────────────────────────────────────────────────────────────
module "primary" {
  source = "./modules/region"

  providers = {
    aws    = aws.primary
    random = random
  }

  name                = "${var.project}-${var.environment}-primary"
  vpc_cidr            = var.primary_vpc_cidr
  availability_zones  = var.primary_azs
  public_subnet_cidrs = var.primary_public_subnets
  web_subnet_cidrs    = var.primary_web_subnets
  app_subnet_cidrs    = var.primary_app_subnets
  db_subnet_cidrs     = var.primary_db_subnets

  web_instance_type    = var.web_instance_type
  app_instance_type    = var.app_instance_type
  web_min_size         = var.web_min_size
  web_max_size         = var.web_max_size
  web_desired_capacity = var.web_desired_capacity
  app_min_size         = var.app_min_size
  app_max_size         = var.app_max_size
  app_desired_capacity = var.app_desired_capacity
  trusted_cidr         = var.trusted_cidr

  db_instance_class   = var.db_instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  deletion_protection = var.deletion_protection

  is_dr                   = false
  primary_db_instance_arn = null

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# DR REGION — us-west-2 (Warm standby)
# ─────────────────────────────────────────────────────────────
module "dr" {
  source = "./modules/region"

  providers = {
    aws    = aws.dr
    random = random
  }

  name                = "${var.project}-${var.environment}-dr"
  vpc_cidr            = var.dr_vpc_cidr
  availability_zones  = var.dr_azs
  public_subnet_cidrs = var.dr_public_subnets
  web_subnet_cidrs    = var.dr_web_subnets
  app_subnet_cidrs    = var.dr_app_subnets
  db_subnet_cidrs     = var.dr_db_subnets

  web_instance_type    = var.web_instance_type
  app_instance_type    = var.app_instance_type
  web_min_size         = 1
  web_max_size         = var.web_max_size
  web_desired_capacity = 1
  app_min_size         = 1
  app_max_size         = var.app_max_size
  app_desired_capacity = 1
  trusted_cidr         = var.trusted_cidr

  db_instance_class       = var.db_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username
  deletion_protection     = var.deletion_protection
  is_dr                   = true
  primary_db_instance_arn = module.primary.db_instance_arn
  dr_kms_key_arn          = aws_kms_key.dr_rds.arn

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# GLOBAL — CloudFront, WAF, Route53
# ─────────────────────────────────────────────────────────────
module "global" {
  source = "./modules/global"

  providers = {
    aws = aws.us_east_1
  }

  name                = "${var.project}-${var.environment}"
  domain_name         = var.domain_name
  create_route53_zone = var.create_route53_zone

  primary_alb_dns_name  = module.primary.alb_ext_dns_name
  primary_alb_zone_id   = module.primary.alb_ext_zone_id
  dr_alb_dns_name       = module.dr.alb_ext_dns_name
  dr_alb_zone_id        = module.dr.alb_ext_zone_id
  primary_alb_origin_id = "primary-alb"
  dr_alb_origin_id      = "dr-alb"

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# BACKUP — Cross-region AWS Backup
# ─────────────────────────────────────────────────────────────
module "backup" {
  source = "./modules/backup"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  name                    = "${var.project}-${var.environment}"
  primary_db_instance_arn = module.primary.db_instance_arn
  dr_db_instance_arn      = module.dr.db_instance_arn

  tags = local.common_tags
}
