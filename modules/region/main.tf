terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  n = var.name
}

# ─────────────────────────────────────────────────────────────
# Data: Latest Amazon Linux 2023 AMI
# ─────────────────────────────────────────────────────────────
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─────────────────────────────────────────────────────────────
# VPC - terraform-aws-modules/vpc/aws (Anton Babenko)
# 3 tiers natively: public, web (private), db
# ─────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.n}-vpc"
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.web_subnet_cidrs
  database_subnets = var.db_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  public_subnet_tags   = { Tier = "public" }
  private_subnet_tags  = { Tier = "web" }
  database_subnet_tags = { Tier = "db" }

  tags = var.tags
}

# App-tier subnets - VPC module supports 3 tiers; app is the 4th
resource "aws_subnet" "app" {
  count = length(var.availability_zones)

  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${local.n}-app-${var.availability_zones[count.index]}"
    Tier = "app"
  })
}

# Route app subnets via the same NAT gateways as the web tier
resource "aws_route_table_association" "app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = module.vpc.private_route_table_ids[count.index]
}

# ─────────────────────────────────────────────────────────────
# Security Groups - terraform-aws-modules/security-group/aws
# ─────────────────────────────────────────────────────────────

# External ALB - open to internet
module "alb_ext_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-alb-ext-sg"
  description = "External ALB - HTTP/HTTPS from internet"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

# Web servers - inbound from external ALB only
module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-web-sg"
  description = "Web servers - HTTP from external ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "HTTP from external ALB"
      source_security_group_id = module.alb_ext_sg.security_group_id
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

# Internal ALB - inbound from web servers
module "alb_int_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-alb-int-sg"
  description = "Internal ALB - HTTP from web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "HTTP from web servers"
      source_security_group_id = module.web_sg.security_group_id
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

# App servers - inbound from internal ALB only
module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-app-sg"
  description = "App servers - port 8080 from internal ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "App traffic from internal ALB"
      source_security_group_id = module.alb_int_sg.security_group_id
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

# RDS - inbound from app servers only
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-rds-sg"
  description = "RDS MySQL - port 3306 from app servers"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL from app servers"
      source_security_group_id = module.app_sg.security_group_id
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

# Bastion - SSH from trusted CIDR
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.n}-bastion-sg"
  description = "Bastion host - SSH from trusted CIDR"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from trusted IP"
      cidr_blocks = var.trusted_cidr
    },
  ]
  egress_rules = ["all-all"]

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# External ALB - internet-facing, public subnets → web tier
# terraform-aws-modules/alb/aws (Anton Babenko)
# ─────────────────────────────────────────────────────────────
module "alb_ext" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "${local.n}-alb-ext"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_groups = [module.alb_ext_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "web" }
    }
  }

  target_groups = {
    web = {
      name              = "${local.n}-web-tg"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 5
        matcher             = "200"
      }
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Internal ALB - private, web subnets → app tier
# ─────────────────────────────────────────────────────────────
module "alb_int" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name     = "${local.n}-alb-int"
  vpc_id   = module.vpc.vpc_id
  subnets  = module.vpc.private_subnets
  internal = true

  enable_deletion_protection = false

  security_groups = [module.alb_int_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "app" }
    }
  }

  target_groups = {
    app = {
      name              = "${local.n}-app-tg"
      protocol          = "HTTP"
      port              = 8080
      target_type       = "instance"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/health"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 5
        matcher             = "200"
      }
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Web-tier ASG - terraform-aws-modules/autoscaling/aws
# Runs the Tooplate "Infinite Loop" HTML template via Apache
# ─────────────────────────────────────────────────────────────
module "web_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = "${local.n}-web-asg"

  vpc_zone_identifier = module.vpc.private_subnets
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_desired_capacity
  health_check_type   = "ELB"

  image_id          = data.aws_ami.al2023.id
  instance_type     = var.web_instance_type
  enable_monitoring = true

  # IMDSv2 required - prevents SSRF credential theft (AWS-0130)
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypt root EBS volume
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]

  security_groups = [module.web_sg.security_group_id]

  # Apache + Tooplate 2117_infinite_loop template (Amazon Linux 2023)
  user_data = base64encode(<<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y wget unzip httpd telnet
    systemctl start httpd
    systemctl enable httpd
    chmod -R 755 /var/www/html
    wget https://www.tooplate.com/zip-templates/2117_infinite_loop.zip
    unzip -o 2117_infinite_loop.zip
    cp -r 2117_infinite_loop/* /var/www/html/
    systemctl restart httpd
    apache_status=$(systemctl is-active httpd)
    if [ "$apache_status" = "active" ]; then
      echo "Apache is running."
    else
      echo "Apache is not running."
      exit 1
    fi
    http_status=$(curl -o /dev/null -s -w "%%{http_code}\n" http://localhost)
    if [ "$http_status" = "200" ]; then
      echo "Apache is serving pages correctly."
    else
      echo "Failed to serve pages. HTTP status: $http_status."
      exit 1
    fi
  EOT
  )

  target_group_arns = [module.alb_ext.target_groups["web"].arn]

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# App-tier ASG
# ─────────────────────────────────────────────────────────────
module "app_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = "${local.n}-app-asg"

  vpc_zone_identifier = aws_subnet.app[*].id
  min_size            = var.app_min_size
  max_size            = var.app_max_size
  desired_capacity    = var.app_desired_capacity
  health_check_type   = "ELB"

  image_id          = data.aws_ami.al2023.id
  instance_type     = var.app_instance_type
  enable_monitoring = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]

  security_groups = [module.app_sg.security_group_id]

  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum install -y python3
    cat > /etc/systemd/system/appserver.service <<'SERVICE'
    [Unit]
    Description=Simple App Server
    After=network.target
    [Service]
    ExecStart=/usr/bin/python3 -m http.server 8080 --directory /var/www/app
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SERVICE
    mkdir -p /var/www/app
    echo '{"status":"ok","service":"app-tier"}' > /var/www/app/health
    systemctl daemon-reload
    systemctl start appserver
    systemctl enable appserver
  EOT
  )

  target_group_arns = [module.alb_int.target_groups["app"].arn]

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Bastion Host - terraform-aws-modules/ec2-instance/aws
# ─────────────────────────────────────────────────────────────
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${local.n}-bastion"

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.bastion_sg.security_group_id]
  associate_public_ip_address = true
  monitoring                  = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device = [
    {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  ]

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# VPC Flow Logs (terrascan AC-AWS-NS-FL-M-0036)
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${local.n}"
  retention_in_days = 90

  tags = var.tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${local.n}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.n}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = merge(var.tags, { Name = "${local.n}-flow-log" })
}

# ─────────────────────────────────────────────────────────────
# RDS - Primary (Multi-AZ MySQL 8.0)
# terraform-aws-modules/rds/aws (Anton Babenko)
# ─────────────────────────────────────────────────────────────
resource "random_password" "db" {
  count = var.is_dr ? 0 : 1

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "rds" {
  count = var.is_dr ? 0 : 1

  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.n}-rds"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db[0].result

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot   = true

  # CloudWatch logs (terrascan)
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # IAM database authentication
  iam_database_authentication_enabled = true

  skip_final_snapshot = true
  deletion_protection = var.deletion_protection

  tags = merge(var.tags, { BackupEnabled = "true" })
}

# ─────────────────────────────────────────────────────────────
# RDS Read Replica - DR region
# ─────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "dr_replica" {
  count = var.is_dr ? 1 : 0

  name       = "${local.n}-rds-subnet-group"
  subnet_ids = module.vpc.database_subnets

  tags = merge(var.tags, { Name = "${local.n}-rds-subnet-group" })
}

resource "aws_db_instance" "replica" {
  count = var.is_dr ? 1 : 0

  identifier          = "${local.n}-rds-replica"
  replicate_source_db = var.primary_db_instance_arn
  instance_class      = var.db_instance_class
  storage_encrypted   = true

  kms_key_id          = var.dr_kms_key_arn
  publicly_accessible    = false
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.dr_replica[0].name

  backup_retention_period             = 7
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  skip_final_snapshot                 = true
  deletion_protection                 = var.deletion_protection

  tags = merge(var.tags, { Name = "${local.n}-rds-replica" })
}
