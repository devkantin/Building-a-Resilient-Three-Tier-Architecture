# EC2 Instances Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Web Server Instances
resource "aws_instance" "web" {
  count                    = var.web_instance_count
  ami                      = data.aws_ami.amazon_linux_2.id
  instance_type            = var.instance_type_web
  subnet_id                = values(var.private_subnets)[count.index % length(var.private_subnets)]
  vpc_security_group_ids   = [var.web_sg_id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = base64encode(templatefile("${path.module}/user_data_web.sh", {
    region = var.region
  }))

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-web-${count.index + 1}"
      Role = "web"
    }
  )
}

# App Server Instances
resource "aws_instance" "app" {
  count                    = var.app_instance_count
  ami                      = data.aws_ami.amazon_linux_2.id
  instance_type            = var.instance_type_app
  subnet_id                = values(var.private_subnets)[count.index % length(var.private_subnets)]
  vpc_security_group_ids   = [var.app_sg_id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = base64encode(templatefile("${path.module}/user_data_app.sh", {
    region = var.region
  }))

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-${count.index + 1}"
      Role = "app"
    }
  )
}

# Database Server Instances
resource "aws_instance" "db" {
  count                    = var.db_instance_count
  ami                      = data.aws_ami.amazon_linux_2.id
  instance_type            = var.instance_type_db
  subnet_id                = values(var.private_subnets)[count.index % length(var.private_subnets)]
  vpc_security_group_ids   = [var.db_sg_id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = base64encode(templatefile("${path.module}/user_data_db.sh", {
    region = var.region
  }))

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 500
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-${count.index + 1}"
      Role = "database"
    }
  )
}

# Register web instances with ALB
resource "aws_lb_target_group_attachment" "web" {
  count            = var.web_instance_count
  target_group_arn = var.alb_target_group_arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
