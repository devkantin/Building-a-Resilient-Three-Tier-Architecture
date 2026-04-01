policy "aws_instance_tagging" {
  enforcement_level = "mandatory"
}

policy "aws_s3_encryption" {
  enforcement_level = "mandatory"
}

policy "aws_database_backup" {
  enforcement_level = "mandatory"
}

policy "aws_cost_control" {
  enforcement_level = "soft-mandatory"
}

policy "aws_allowed_resources" {
  enforcement_level = "mandatory"
}

policy "aws_network_security" {
  enforcement_level = "mandatory"
}

policy "aws_lambda_security" {
  enforcement_level = "mandatory"
}

policy "aws_rds_security" {
  enforcement_level = "mandatory"
}
