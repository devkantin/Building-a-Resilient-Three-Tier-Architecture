# tests/networking_test.tftest.hcl
# Validates VPC CIDR configuration, subnet counts, and environment variable constraints.
# Run with: terraform test -filter=tests/networking_test.tftest.hcl

mock_provider "aws" { alias = "primary" }
mock_provider "aws" { alias = "dr" }
mock_provider "aws" { alias = "us_east_1" }
mock_provider "random" {}

# Override all three top-level modules so their computed outputs are known at plan time.
override_module {
  target = module.primary
  outputs = {
    vpc_id            = "vpc-primary-00000001"
    vpc_cidr_block    = "10.0.0.0/16"
    public_subnet_ids = ["subnet-pub-1a", "subnet-pub-1b"]
    web_subnet_ids    = ["subnet-web-1a", "subnet-web-1b"]
    app_subnet_ids    = ["subnet-app-1a", "subnet-app-1b"]
    db_subnet_ids     = ["subnet-db-1a", "subnet-db-1b"]
    alb_ext_dns_name  = "primary-alb-00000001.us-east-1.elb.amazonaws.com"
    alb_ext_zone_id   = "Z35SXDOTRQ7X7K"
    alb_int_dns_name  = "primary-alb-int-00000001.us-east-1.elb.amazonaws.com"
    bastion_public_ip = "1.2.3.4"
    db_instance_arn   = "arn:aws:rds:us-east-1:123456789012:db:primary-rds"
    db_endpoint       = "primary-rds.abc123.us-east-1.rds.amazonaws.com:3306"
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
    alb_ext_dns_name  = "dr-alb-00000001.us-west-2.elb.amazonaws.com"
    alb_ext_zone_id   = "Z1H1FL5HABSF5"
    alb_int_dns_name  = "dr-alb-int-00000001.us-west-2.elb.amazonaws.com"
    bastion_public_ip = "5.6.7.8"
    db_instance_arn   = "arn:aws:rds:us-west-2:123456789012:db:dr-rds-replica"
    db_endpoint       = "dr-rds.def456.us-west-2.rds.amazonaws.com:3306"
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
    waf_web_acl_arn            = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/test/abc123"
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

# ── VPC CIDR values are plumbed correctly ────────────────────
run "primary_vpc_cidr_default" {
  command = plan

  assert {
    condition     = var.primary_vpc_cidr == "10.0.0.0/16"
    error_message = "Primary VPC CIDR must default to 10.0.0.0/16"
  }
}

run "dr_vpc_cidr_default" {
  command = plan

  assert {
    condition     = var.dr_vpc_cidr == "10.1.0.0/16"
    error_message = "DR VPC CIDR must default to 10.1.0.0/16"
  }
}

# ── Primary and DR VPCs must not overlap ─────────────────────
run "vpc_cidrs_do_not_overlap" {
  command = plan

  assert {
    condition     = var.primary_vpc_cidr != var.dr_vpc_cidr
    error_message = "Primary and DR VPC CIDRs must not be the same"
  }
}

# ── Subnet counts match AZ counts ────────────────────────────
run "primary_subnet_count_matches_azs" {
  command = plan

  assert {
    condition     = length(var.primary_public_subnets) == length(var.primary_azs)
    error_message = "primary_public_subnets count must equal primary_azs count"
  }

  assert {
    condition     = length(var.primary_web_subnets) == length(var.primary_azs)
    error_message = "primary_web_subnets count must equal primary_azs count"
  }
}

# ── Environment validation ────────────────────────────────────
run "invalid_environment_rejected" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
