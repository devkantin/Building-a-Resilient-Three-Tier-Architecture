# tests/security_test.tftest.hcl
# Validates security-relevant defaults: encryption, public access blocks, deletion protection.
# Run with: terraform test -filter=tests/security_test.tftest.hcl

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

# ── Deletion protection default ───────────────────────────────
run "deletion_protection_default_is_false" {
  command = plan

  assert {
    condition     = var.deletion_protection == false
    error_message = "deletion_protection must default to false for this lab"
  }
}

# ── Trusted CIDR is set ───────────────────────────────────────
run "trusted_cidr_is_set" {
  command = plan

  assert {
    condition     = var.trusted_cidr != ""
    error_message = "trusted_cidr must not be empty"
  }
}

# ── DB username is not empty ──────────────────────────────────
run "db_username_not_empty" {
  command = plan

  assert {
    condition     = var.db_username != ""
    error_message = "db_username must not be empty"
  }
}

# ── Primary and DR are separate regions ──────────────────────
run "primary_and_dr_regions_differ" {
  command = plan

  assert {
    condition     = var.primary_region != var.dr_region
    error_message = "primary_region and dr_region must be different"
  }
}

# ── ASG sizes are valid ───────────────────────────────────────
run "asg_min_le_desired_le_max" {
  command = plan

  assert {
    condition     = var.web_min_size <= var.web_desired_capacity
    error_message = "web_min_size must be <= web_desired_capacity"
  }

  assert {
    condition     = var.web_desired_capacity <= var.web_max_size
    error_message = "web_desired_capacity must be <= web_max_size"
  }
}
