# Multi-Region AWS Infrastructure with Terraform

This Terraform configuration deploys a highly available, multi-region AWS infrastructure that mirrors the architecture diagram provided. It includes:

## Architecture Overview

### Primary Region (us-east-1)
- **VPC** with public and private subnets across 2 Availability Zones
- **Internet Gateway** for public internet access
- **NAT Gateways** for private subnet internet access
- **Application Load Balancer** for distributing traffic
- **EC2 Instances**:
  - 2 Web servers (t3.medium)
  - 2 Application servers (t3.medium)
  - 2 Database servers (t3.large)
- **RDS Database** with Multi-AZ, automated backups, and monitoring
- **AWS Backup** vault for disaster recovery

### Secondary Region (us-west-2)
- Identical infrastructure for failover and disaster recovery
- Read replicas for database cross-region replication

### Cross-Region Components
- **Route53** with failover routing and health checks
- **Cross-Region Database Replication**
- **AWS Backup** for point-in-time recovery

## Directory Structure

```
terraform-aws-infrastructure/
├── main.tf                      # Main configuration with all modules
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example tfvars file
├── .gitignore                   # Git ignore rules
├── modules/
│   ├── vpc/                     # VPC with subnets, NAT, IGW
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security_groups/         # Security group definitions
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── load_balancer/           # Application Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/                     # EC2 instances (web, app, db)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── user_data_web.sh
│   │   ├── user_data_app.sh
│   │   └── user_data_db.sh
│   ├── rds/                     # RDS database configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── backup/                  # AWS Backup configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cross_region/            # Cross-region replication
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── route53/                 # Route53 DNS and failover
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/              # CloudWatch alarms and logs
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md                    # This file
```

## Prerequisites

1. **AWS Account**: With appropriate IAM permissions
2. **Terraform**: >= 1.0 installed
3. **AWS CLI**: Configured with credentials

```bash
# Verify installations
terraform version
aws --version
aws sts get-caller-identity
```

## Getting Started

### 1. Clone/Setup

```bash
cd terraform-aws-infrastructure
```

### 2. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Important variables to update**:
- `db_password`: Change from default
- `alarm_email`: Your email for notifications
- `domain_name`: If using Route53
- `instance types`: Adjust for your needs
- `backup_retention_period`: Your backup requirements

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure it matches your expectations.

### 5. Apply Configuration

```bash
terraform apply tfplan
```

This will take approximately 10-15 minutes to complete.

### 6. Verify Deployment

```bash
terraform output
terraform output connection_info
```

## Configuration Details

### Network Architecture

- **Primary Region VPC**: 10.0.0.0/16
  - Public Subnets: 10.0.1.0/24, 10.0.2.0/24
  - Private Subnets: 10.0.10.0/24, 10.0.11.0/24

- **Secondary Region VPC**: 10.1.0.0/16
  - Public Subnets: 10.1.1.0/24, 10.1.2.0/24
  - Private Subnets: 10.1.10.0/24, 10.1.11.0/24

### Security Groups

- **ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **Web Server SG**: Allows HTTP/HTTPS from ALB
- **App Server SG**: Allows app ports (8080, 8443) from web servers
- **Database SG**: Allows PostgreSQL (5432) and MySQL (3306) from app servers

### Database Configuration

- **Engine**: PostgreSQL (customizable)
- **Instance Class**: db.t3.medium
- **Storage**: 100 GB gp3
- **Backup**: 30-day retention, daily backups
- **Multi-AZ**: Enabled for high availability
- **Monitoring**: Enhanced monitoring with 1-minute granularity
- **Encryption**: At-rest encryption with KMS

### Backup Strategy

- **Backup Vault**: Encrypted with KMS
- **Retention**: 30 days daily backups
- **Cold Storage**: After 90 days
- **Resources Included**: RDS, EC2 instances

### Monitoring & Alarms

- **ALB Response Time**: Alert > 1 second
- **RDS CPU**: Alert > 80%
- **RDS Connections**: Alert > 80% of max
- **RDS Storage**: Alert when < 10 GB free
- **Unhealthy Hosts**: Alert on any unhealthy targets

### Route53 Configuration (Optional)

If `domain_name` is set (not "example.com"):
- Creates Route53 hosted zone
- Configures failover routing
- Health checks every 30 seconds
- Automatic failover to secondary region

## Common Operations

### View Current State

```bash
terraform state list
terraform state show aws_instance.web
```

### Scale Up/Down

```bash
# Edit terraform.tfvars
web_instance_count = 3  # Change from 2 to 3

# Apply changes
terraform plan
terraform apply
```

### Update Database

```bash
# Edit database parameters in terraform.tfvars
db_instance_class = "db.t3.large"  # Upgrade instance

terraform plan
terraform apply
```

### Destroy Resources

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm prompt
yes
```

## Troubleshooting

### Error: "No valid credential sources found"

```bash
# Configure AWS credentials
aws configure

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Error: "InvalidParameterValue - DB instance class not supported"

Check available instance classes for your region:
```bash
aws rds describe-orderable-db-instance-options \
  --engine postgres \
  --region us-east-1 \
  --query 'OrderableDBInstanceOptions[].DBInstanceClass'
```

### VPC Flow Logs Fails

If Flow Logs creation fails, check IAM permissions or run later:
```bash
terraform apply -target=module.primary_vpc.aws_flow_log.main
```

### Database Creation Timeout

First RDS creation can take 15+ minutes. Monitor in AWS Console:
- Open RDS Dashboard
- Check Events tab for progress

## Cost Optimization

### To Reduce Costs:

1. **Instance Counts**: Set to 1 per tier
   ```hcl
   web_instance_count = 1
   app_instance_count = 1
   db_instance_count = 1
   ```

2. **Instance Types**: Use smaller types
   ```hcl
   instance_type_web = "t3.micro"
   db_instance_class = "db.t3.micro"
   ```

3. **Disable Multi-AZ**:
   ```hcl
   multi_az = false
   ```

4. **Reduce Backup Retention**:
   ```hcl
   backup_retention_period = 7
   ```

### Estimated Monthly Costs (us-east-1):
- 2x t3.medium EC2: ~$30
- 2x t3.large EC2: ~$60
- RDS db.t3.medium Multi-AZ: ~$200
- NAT Gateways (2): ~$32
- Load Balancer: ~$16
- **Total: ~$338/month**

## Security Best Practices Implemented

✅ VPC Flow Logs enabled for traffic analysis
✅ Encryption at rest (EBS, RDS)
✅ Encryption in transit (HTTPS ready)
✅ Security groups with least privilege
✅ IAM roles for EC2 instances
✅ RDS backup encryption with KMS
✅ Multi-AZ for high availability
✅ Private subnets for databases
✅ Automated backups and snapshots
✅ CloudWatch monitoring and alarms
✅ Deletion protection on RDS

## Disaster Recovery

### RTO/RPO Targets:
- **RTO**: < 5 minutes (auto-failover)
- **RPO**: < 1 hour (cross-region replication)

### Recovery Procedures:
See [RECOVERY.md](RECOVERY.md) for detailed procedures.

## Support & Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Terraform Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/terraform-on-aws.html)

## License

This configuration is provided as-is for reference purposes.
