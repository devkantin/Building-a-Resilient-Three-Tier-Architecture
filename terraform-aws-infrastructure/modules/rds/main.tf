# RDS Database Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = var.db_identifier
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  iops                  = var.storage_type == "io1" ? 1000 : null

  db_name  = replace(lower(var.db_identifier), "-", "")
  username = var.db_username
  password = var.db_password

  # Subnet and security
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  # Backup and recovery
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Maintenance
  maintenance_window            = "sun:04:00-sun:04:30"
  auto_minor_version_upgrade    = true

  # High Availability
  multi_az = var.multi_az

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  enable_cloudwatch_logs_exports = [
    var.db_engine == "postgres" ? "postgresql" : 
    var.db_engine == "mysql" ? "mysql" : 
    var.db_engine == "mariadb" ? "mariadb" : 
    "error"
  ]

  # Security
  iam_database_authentication_enabled = var.enable_iam_auth
  deletion_protection                 = true

  # Aurora Backtrack (PostgreSQL only)
  backtrack_window = var.enable_backtrack && var.db_engine == "postgres" ? 24 : 0

  tags = merge(
    var.tags,
    {
      Name = var.db_identifier
    }
  )

  depends_on = [aws_iam_role_policy.rds_monitoring]
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.db_identifier}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy for RDS Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role_policy" "rds_monitoring" {
  name = "${var.db_identifier}-monitoring-policy"
  role = aws_iam_role.rds_monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# RDS Snapshot
resource "aws_db_snapshot" "daily" {
  db_instance_identifier = aws_db_instance.main.id
  db_snapshot_identifier = "${var.db_identifier}-daily-snapshot"

  tags = merge(
    var.tags,
    {
      Name = "${var.db_identifier}-daily-snapshot"
    }
  )
}
