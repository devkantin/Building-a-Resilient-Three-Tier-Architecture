# AWS Backup Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Backup Vault
resource "aws_backup_vault" "main" {
  name        = var.backup_vault_name
  kms_key_arn = aws_kms_key.backup.arn

  tags = merge(
    var.tags,
    {
      Name = var.backup_vault_name
    }
  )
}

# KMS Key for Backup Encryption
resource "aws_kms_key" "backup" {
  description             = "KMS key for ${var.backup_vault_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.backup_vault_name}-key"
    }
  )
}

# KMS Key Alias
resource "aws_kms_alias" "backup" {
  name          = "alias/${var.backup_vault_name}"
  target_key_id = aws_kms_key.backup.key_id
}

# Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.backup_vault_name}-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 ? * * *)"  # 2 AM UTC daily

    lifecycle {
      delete_after = 30
      cold_storage_after = 90
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.main.arn

      lifecycle {
        delete_after       = 90
        cold_storage_after = 365
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.backup_vault_name}-plan"
    }
  )
}

# Backup Selection
resource "aws_backup_selection" "main" {
  name         = "${var.backup_vault_name}-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = flatten(var.resource_arns)

  selection_tag {
    type   = "STRINGEQUALS"
    key    = "Environment"
    value  = var.environment
  }
}

# IAM Role for Backup
resource "aws_iam_role" "backup" {
  name = "${var.backup_vault_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy
resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Additional policy for restoration
resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Custom policy for KMS encryption
resource "aws_iam_role_policy" "backup_kms" {
  name = "${var.backup_vault_name}-kms-policy"
  role = aws_iam_role.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.backup.arn
      }
    ]
  })
}

# CloudWatch Log Group for Backup
resource "aws_cloudwatch_log_group" "backup" {
  name              = "/aws/backup/${var.backup_vault_name}"
  retention_in_days = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.backup_vault_name}-logs"
    }
  )
}
