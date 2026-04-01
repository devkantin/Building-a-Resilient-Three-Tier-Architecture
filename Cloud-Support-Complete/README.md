# Building a Resilient Three-Tier Architecture

A comprehensive cloud infrastructure solution for deploying resilient, scalable, and secure three-tier applications on AWS and Azure. This repository provides complete Infrastructure-as-Code (IaC), CI/CD automation, security policies, and operational monitoring tools.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security & Compliance](#security--compliance)
- [Monitoring & Performance](#monitoring--performance)
- [Deployment Guide](#deployment-guide)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

This project provides enterprise-grade cloud infrastructure automation for deploying resilient three-tier applications. It includes:

- **Infrastructure-as-Code** using Terraform for AWS
- **Policy-as-Code** using Sentinel for AWS and Azure compliance
- **Automated CI/CD pipelines** using Jenkins and GitHub Actions
- **Built-in security hardening** with security groups, encryption, and IAM policies
- **Comprehensive monitoring** and performance optimization tools
- **Automated compliance checking** for regulatory requirements

## Architecture

### Three-Tier Architecture Components

1. **Presentation Tier (Web Layer)**
   - Load balancers distributing traffic
   - Autoscaling EC2 instances running web servers
   - CloudFront CDN for content delivery

2. **Application Tier (Business Logic)**
   - EC2 instances running application servers
   - Auto-scaling groups for dynamic capacity
   - Private networking for security

3. **Data Tier (Database Layer)**
   - Amazon RDS for relational databases with multi-AZ replication
   - DynamoDB for NoSQL workloads
   - ElastiCache for in-memory caching
   - Automated backup and recovery

### AWS Services Used

- **Compute**: EC2, Auto Scaling, Lambda
- **Database**: RDS, DynamoDB, ElastiCache
- **Networking**: VPC, Application Load Balancer, Route 53, CloudFront
- **Security**: IAM, Security Groups, KMS, Secrets Manager
- **Monitoring**: CloudWatch, CloudTrail
- **Storage**: S3 buckets with encryption and backup

### Multi-Region & High Availability

- Cross-region replication for disaster recovery
- Database failover and backup strategies
- Load balancing across availability zones

## Directory Structure

```
├── ci-cd/                          # CI/CD Pipeline Configuration
│   ├── Jenkinsfile                 # Jenkins pipeline definition
│   ├── github-actions-deploy.yml   # GitHub Actions workflow
│   ├── Dockerfile                  # Container image for deployment
│   ├── docker-compose.yml          # Local Docker environment setup
│   ├── deploy.sh                   # Deployment automation script
│   ├── push-to-ecr.sh             # ECR image push script
│   ├── init.sql                    # Database initialization
│   └── README.md                   # CI/CD documentation
│
├── terraform-aws-infrastructure/   # AWS Infrastructure Terraform Modules
│   ├── main.tf                     # Root Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── terraform.tfvars.example    # Example variable values
│   └── modules/                    # Reusable Terraform modules
│       ├── vpc/                    # VPC and networking
│       ├── ec2/                    # Compute instances
│       ├── rds/                    # Relational databases
│       ├── load_balancer/          # Application load balancers
│       ├── security_groups/        # Network security policies
│       ├── route53/                # DNS management
│       ├── monitoring/             # CloudWatch and alerting
│       ├── backup/                 # Backup and disaster recovery
│       └── cross_region/           # Multi-region setup
│
├── terraform-sentinel/             # AWS Sentinel Policies
│   ├── aws_allowed_resources.sentinel        # Allowed AWS resource types
│   ├── aws_api_gateway_security.sentinel     # API Gateway security
│   ├── aws_cloudtrail_audit.sentinel        # Audit logging compliance
│   ├── aws_cloudwatch_monitoring.sentinel   # Monitoring requirements
│   ├── aws_compliance_regulatory.sentinel   # Regulatory compliance
│   ├── aws_cost_control.sentinel            # Cost optimization
│   ├── aws_database_backup.sentinel         # Database backup policies
│   ├── aws_dynamodb_security.sentinel       # DynamoDB encryption
│   ├── aws_ebs_encryption.sentinel          # EBS volume encryption
│   ├── aws_elasticache_security.sentinel    # ElastiCache security
│   ├── aws_iam_security.sentinel            # IAM best practices
│   ├── aws_instance_tagging.sentinel        # Resource tagging
│   ├── aws_kms_key_management.sentinel      # KMS key policies
│   ├── aws_lambda_security.sentinel         # Lambda security
│   ├── aws_load_balancer_security.sentinel  # Load balancer security
│   ├── aws_network_security.sentinel        # Network security
│   ├── aws_rds_security.sentinel            # RDS security
│   ├── aws_s3_encryption.sentinel           # S3 encryption
│   ├── aws_sns_sqs_security.sentinel        # SNS/SQS security
│   ├── aws_storage_backup.sentinel          # Storage backup policies
│   ├── aws_vpc_flow_logs.sentinel           # VPC flow logging
│   ├── sentinel.hcl                         # Sentinel policy configuration
│   └── README.md                            # AWS Sentinel documentation
│
├── terraform-sentinel-azure/       # Azure Sentinel Policies
│   ├── azure_aks_security.sentinel          # Kubernetes security
│   ├── azure_app_service_security.sentinel  # App Service security
│   ├── azure_backup_recovery.sentinel       # Backup requirements
│   ├── azure_compliance_cis.sentinel        # CIS benchmark compliance
│   ├── azure_container_registry.sentinel    # Container registry security
│   ├── azure_cost_control.sentinel          # Cost optimization
│   ├── azure_data_protection.sentinel       # Data protection
│   ├── azure_database_backup.sentinel       # Database backup policies
│   ├── azure_firewall_ddos.sentinel         # Firewall and DDoS protection
│   ├── azure_keyvault_security.sentinel     # Key Vault security
│   ├── azure_monitoring_logging.sentinel    # Monitoring and logging
│   ├── azure_network_security.sentinel      # Network security
│   ├── azure_private_endpoints.sentinel     # Private endpoints
│   ├── azure_rbac_access_control.sentinel   # RBAC policies
│   ├── azure_resource_tagging.sentinel      # Resource tagging
│   ├── azure_sql_database_security.sentinel # SQL Database security
│   ├── azure_storage_encryption.sentinel    # Storage encryption
│   ├── azure_vm_security.sentinel           # VM security hardening
│   ├── sentinel.hcl                         # Azure Sentinel configuration
│   └── README.md                            # Azure Sentinel documentation
│
├── security/                       # Security Tools and Audits
│   ├── aws-security-audit.sh       # AWS security compliance scanner
│   └── azure-compliance-checker.sh # Azure compliance validation
│
├── performance/                    # Performance Optimization
│   ├── aws-rightsizing.sh          # EC2 right-sizing analysis
│   └── database-optimization.sh    # Database performance tuning
│
├── monitoring/                     # Monitoring and Observability
│   └── (Monitoring configurations and scripts)
│
└── README.md                       # This file
```

## Prerequisites

### Required Tools

- **Terraform** (v1.0+) - Infrastructure-as-Code
- **AWS CLI** (v2.0+) - AWS credential management
- **Azure CLI** (v2.0+) - Azure credential management
- **Git** (v2.20+) - Version control
- **Docker** (v20.0+) - Container support
- **Sentinel CLI** (v0.15+) - Policy-as-Code validation

### AWS Requirements

- AWS account with appropriate IAM permissions
- AWS credentials configured locally (`aws configure`)
- Amazon ECR repository for container images

### Azure Requirements

- Azure subscription with appropriate permissions
- Azure CLI authentication (`az login`)
- Azure Container Registry (if using Azure)

### Git Clone

```bash
git clone git@github.com:devkantin/Building-a-Resilient-Three-Tier-Architecture.git
cd Building-a-Resilient-Three-Tier-Architecture
```

## Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
```

### 2. Initialize Terraform

```bash
cd terraform-aws-infrastructure
terraform init
terraform plan -out=tfplan
```

### 3. Review and Apply Plan

```bash
terraform apply tfplan
```

### 4. Validate Security Policies

```bash
cd ../terraform-sentinel
sentinel apply -config=sentinel.hcl
```

### 5. Deploy Application

```bash
cd ../ci-cd
./deploy.sh
```

### 6. Monitor Infrastructure

Access monitoring dashboards:
- AWS CloudWatch: https://console.aws.amazon.com/cloudwatch/
- Application logs: Check CloudWatch Logs groups

## CI/CD Pipeline

### Jenkins Pipeline

The Jenkins pipeline (`ci-cd/Jenkinsfile`) automates:

1. **Build**: Compile application code
2. **Test**: Run unit and integration tests
3. **Security Scan**: Check for vulnerabilities
4. **Build Image**: Create Docker container image
5. **Push to ECR**: Push to AWS ECR registry
6. **Deploy**: Update infrastructure and deploy application
7. **Validate**: Run smoke tests and health checks

### GitHub Actions Workflow

The GitHub Actions workflow (`ci-cd/github-actions-deploy.yml`) provides:

- Automated testing on pull requests
- Infrastructure validation
- Security scanning
- Automated deployment to AWS

### Running Local Deployment

```bash
cd ci-cd
docker-compose up
./deploy.sh --environment staging
```

## Security & Compliance

### Terraform Sentinel Policies

#### AWS Policies (23 policies)

- **Encryption**: EBS, RDS, DynamoDB, S3, Secrets Manager
- **Access Control**: IAM, Security Groups, Network ACLs
- **Monitoring**: CloudWatch, CloudTrail, VPC Flow Logs
- **Backup**: Database, EBS, S3 snapshots
- **Cost Control**: Resource right-sizing, unused resources
- **Compliance**: CIS Benchmarks, regulatory requirements

#### Azure Policies (19 policies)

- **AKS Security**: Pod security, network policies
- **Database Security**: SQL encryption, backup policies
- **Access Control**: RBAC, Key Vault security
- **Monitoring**: Logging, diagnostic settings
- **Compliance**: CIS benchmarks, regulatory standards

### Security Best Practices Implemented

- ✅ Encryption at-rest and in-transit
- ✅ VPC isolation and security groups
- ✅ IAM principle of least privilege
- ✅ Multi-factor authentication enforcement
- ✅ Automated security scanning and compliance checks
- ✅ Audit logging and CloudTrail
- ✅ Network segmentation
- ✅ Database encryption and backups
- ✅ Secrets management

### Running Security Audits

```bash
# AWS Security Audit
./security/aws-security-audit.sh

# Azure Compliance Check
./security/azure-compliance-checker.sh
```

## Monitoring & Performance

### CloudWatch Monitoring

Integrated monitoring includes:

- **EC2 Instances**: CPU, memory, disk usage
- **RDS Database**: Query performance, connections, replication lag
- **Load Balancer**: Request count, latency, error rates
- **Application Logs**: Centralized logging in CloudWatch Logs

### Alarms and Notifications

Pre-configured alarms for:

- High CPU utilization
- Database connection failures
- Load balancer errors
- Replication lag
- Backup failures

### Performance Optimization

```bash
# Run AWS Right-sizing Analysis
./performance/aws-rightsizing.sh

# Optimize Database Performance
./performance/database-optimization.sh
```

## Deployment Guide

### Prerequisites Check

```bash
terraform validate
terraform fmt -check
sentinel test
```

### Staging Environment

```bash
terraform apply -var-file=staging.tfvars
ansible-playbook playbooks/deploy-staging.yml
```

### Production Environment

```bash
# Plan production changes
terraform plan -var-file=production.tfvars -out=prod.tfplan

# Review changes carefully
terraform show prod.tfplan

# Apply with approval
terraform apply prod.tfplan

# Validate deployment
./ci-cd/deploy.sh --environment production
```

### Disaster Recovery

```bash
# Backup database
aws rds create-db-snapshot --db-instance-identifier production-db

# Cross-region failover
terraform apply -var-file=failover.tfvars
```

## Contributing

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and commit**
   ```bash
   git add .
   git commit -m "Add: description of changes"
   ```

3. **Validate changes**
   ```bash
   terraform validate
   terraform fmt
   sentinel test
   ```

4. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Standards

- Follow Terraform best practices
- Use meaningful variable and resource names
- Add comments for complex logic
- Update documentation for changes
- Ensure all policies pass Sentinel validation

### Testing

- Unit tests for Terraform modules
- Integration tests for infrastructure
- Security policy validation
- Compliance checking

## Maintenance

### Regular Tasks

- **Weekly**: Review CloudWatch metrics and alarms
- **Monthly**: Run security audits and compliance checks
- **Quarterly**: Review and optimize costs
- **Annually**: Disaster recovery drills

### Updating Terraform Providers

```bash
terraform init -upgrade
terraform plan
terraform apply
```

## Troubleshooting

### Common Issues

**Terraform State Lock**
```bash
terraform force-unlock LOCK_ID
```

**AWS Credential Issues**
```bash
aws sts get-caller-identity
```

**Sentinel Policy Failures**
```bash
sentinel test -verbose
```

## Support and Documentation

- [Terraform AWS Infrastructure README](terraform-aws-infrastructure/README.md)
- [CI/CD Pipeline README](ci-cd/README.md)
- [AWS Sentinel Policies README](terraform-sentinel/README.md)
- [Azure Sentinel Policies README](terraform-sentinel-azure/README.md)

## License

This project is provided as-is for building resilient cloud architectures. Refer to individual component licenses.

## Changelog

- **v1.0** - Initial release with AWS three-tier architecture, Sentinel policies, and CI/CD pipelines

---

**Last Updated**: April 2026

For questions, issues, or contributions, please open an issue or contact the development team.
