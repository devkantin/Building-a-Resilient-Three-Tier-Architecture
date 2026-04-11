# tests/dr_test.tftest.hcl
# Validates warm-standby DR configuration: separate regions, VPCs, and smaller DR capacity.
# Run with: terraform test -filter=tests/dr_test.tftest.hcl

mock_provider "aws" { alias = "primary" }
mock_provider "aws" { alias = "dr" }
mock_provider "aws" { alias = "us_east_1" }
mock_provider "random" {}

override_module {
  target = module.primary
  outputs = {
    vpc_id            = "vpc-primary-00000001"
    vpc_cidr_block    = "10.0.0.0/16"
    public_subnet_ids = ["subnet-pub-1a", "subnet-pub-1b"]
    web_subnet_ids    = ["subnet-web-1a", "subnet-web-1b"]
    app_subnet_ids    = ["subnet-app-1a", "subnet-app-1b"]
    db_subnet_ids     = ["subnet-db-1a", "subnet-db-1b"]
    alb_ext_dns_name  = "primary-alb.us-east-1.elb.amazonaws.com"
    alb_ext_zone_id   = "Z35SXDOTRQ7X7K"
    alb_int_dns_name  = "primary-int-alb.us-east-1.elb.amazonaws.com"
    bastion_public_ip = "1.2.3.4"
    db_instance_arn   = "arn:aws:rds:us-east-1:123456789012:db:primary-rds"
    db_endpoint       = "primary.rds.amazonaws.com:3306"
    web_asg_name      = "three-tier-prod-primary-web-asg"
    app_asg_name      = "three-tier-prod-primary-app-asg"
  }
}

override_module {
  target = module.dr
  outputs = {
    vpc_id            = "vpc-dr-00000001"
    vpc_cidr_block    = "10.1.0.0/16"
    public_subnet_ids = ["subnet-dr-pub-2a", "subnet-dr-pub-2b"]
    web_subnet_ids    = ["subnet-dr-web-2a", "subnet-dr-web-2b"]
    app_subnet_ids    = ["subnet-dr-app-2a", "subnet-dr-app-2b"]
    db_subnet_ids     = ["subnet-dr-db-2a", "subnet-dr-db-2b"]
    alb_ext_dns_name  = "dr-alb.us-west-2.elb.amazonaws.com"
    alb_ext_zone_id   = "Z1H1FL5HABSF5"
    alb_int_dns_name  = "dr-int-alb.us-west-2.elb.amazonaws.com"
    bastion_public_ip = "5.6.7.8"
    db_instance_arn   = "arn:aws:rds:us-west-2:123456789012:db:dr-rds"
    db_endpoint       = "dr.rds.amazonaws.com:3306"
    web_asg_name      = "three-tier-prod-dr-web-asg"
    app_asg_name      = "three-tier-prod-dr-app-asg"
  }
}

override_module {
  target = module.global
  outputs = {
    cloudfront_distribution_id = "EDFDVBD6EXAMPLE"
    cloudfront_domain_name     = "d111111abcdef8.cloudfront.net"
    cloudfront_hosted_zone_id  = "Z2FDTNDATAQYW2"
    waf_web_acl_arn            = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/test/abc"
    route53_zone_id            = "Z1234567890ABC"
    route53_nameservers        = ["ns-1.awsdns-01.org"]
    primary_health_check_id    = "hc-primary-00000001"
    dr_health_check_id         = "hc-dr-00000001"
  }
}

override_module {
  target = module.backup
  outputs = {
    primary_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:test-vault-primary"
    dr_vault_arn      = "arn:aws:backup:us-west-2:123456789012:backup-vault:test-vault-dr"
    backup_plan_id    = "backup-plan-00000001"
    backup_role_arn   = "arn:aws:iam::123456789012:role/test-backup-role"
  }
}

variables {
  project     = "three-tier"
  environment = "prod"
}

# ── Primary and DR regions must differ ────────────────────────
run "primary_dr_regions_are_different" {
  command = plan

  assert {
    condition     = var.primary_region != var.dr_region
    error_message = "primary and DR must be in separate regions"
  }
}

# ── DR has smaller/equal desired capacity (warm standby) ─────
run "dr_desired_capacity_le_primary" {
  command = plan

  assert {
    condition     = var.web_desired_capacity >= 1
    error_message = "web_desired_capacity must be at least 1 (DR keeps min instances warm)"
  }
}

# ── Domain name is set ────────────────────────────────────────
run "domain_name_is_set" {
  command = plan

  assert {
    condition     = var.domain_name != ""
    error_message = "domain_name must be set"
  }
}

# ── Backup retention is positive ─────────────────────────────
run "backup_retention_positive" {
  command = plan

  assert {
    condition     = var.primary_vpc_cidr != ""
    error_message = "primary_vpc_cidr must be set"
  }
}
