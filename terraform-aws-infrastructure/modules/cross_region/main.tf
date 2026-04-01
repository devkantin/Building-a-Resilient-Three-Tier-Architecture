# Cross-Region Replication Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create read replica in secondary region
resource "aws_db_instance" "read_replica" {
  provider              = aws_secondary
  replicate_source_db   = var.primary_db_arn
  identifier            = "${var.project_name}-read-replica"
  skip_final_snapshot   = false
  publicly_accessible   = false
  storage_encrypted     = true
  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-read-replica"
    }
  )
}
