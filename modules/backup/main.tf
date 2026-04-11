terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.dr]
    }
  }
}

# ─────────────────────────────────────────────────────────────
# Account identity — used in KMS key policies
# ─────────────────────────────────────────────────────────────
data "aws_caller_identity" "primary" {
  provider = aws.primary
}

data "aws_caller_identity" "dr" {
  provider = aws.dr
}

# ─────────────────────────────────────────────────────────────
# KMS Keys — one per region for vault encryption
# ─────────────────────────────────────────────────────────────
resource "aws_kms_key" "primary" {
  provider = aws.primary

  description             = "${var.name} backup vault key — primary"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.primary.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowBackupService"
        Effect    = "Allow"
        Principal = { Service = "backup.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey"]
        Resource  = "*"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.name}-backup-key-primary" })
}

resource "aws_kms_alias" "primary" {
  provider = aws.primary

  name          = "alias/${var.name}-backup-primary"
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_kms_key" "dr" {
  provider = aws.dr

  description             = "${var.name} backup vault key — DR"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.dr.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowBackupService"
        Effect    = "Allow"
        Principal = { Service = "backup.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey"]
        Resource  = "*"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.name}-backup-key-dr" })
}

resource "aws_kms_alias" "dr" {
  provider = aws.dr

  name          = "alias/${var.name}-backup-dr"
  target_key_id = aws_kms_key.dr.key_id
}

# ─────────────────────────────────────────────────────────────
# Backup Vaults — encrypted, one per region
# ─────────────────────────────────────────────────────────────
resource "aws_backup_vault" "primary" {
  provider = aws.primary

  name        = "${var.name}-vault-primary"
  kms_key_arn = aws_kms_key.primary.arn

  tags = merge(var.tags, { Name = "${var.name}-vault-primary" })
}

resource "aws_backup_vault" "dr" {
  provider = aws.dr

  name        = "${var.name}-vault-dr"
  kms_key_arn = aws_kms_key.dr.arn

  tags = merge(var.tags, { Name = "${var.name}-vault-dr" })
}

# ─────────────────────────────────────────────────────────────
# IAM Role — AWS Backup service role
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "backup" {
  provider = aws.primary

  name = "${var.name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  provider = aws.primary

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  provider = aws.primary

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ─────────────────────────────────────────────────────────────
# Backup Plan — daily backups with cross-region copy to DR vault
# ─────────────────────────────────────────────────────────────
resource "aws_backup_plan" "this" {
  provider = aws.primary

  name = "${var.name}-backup-plan"

  rule {
    rule_name         = "daily-with-cross-region-copy"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = var.backup_schedule
    start_window      = 60
    completion_window = 120

    lifecycle {
      delete_after = var.retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = var.retention_days
      }
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Backup Selection — protect primary RDS
# ─────────────────────────────────────────────────────────────
resource "aws_backup_selection" "primary_db" {
  provider = aws.primary

  # Use a tag-based selector to avoid count depending on computed ARN.
  # All RDS instances tagged with BackupEnabled=true are included.
  name         = "${var.name}-primary-db"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupEnabled"
    value = "true"
  }
}
