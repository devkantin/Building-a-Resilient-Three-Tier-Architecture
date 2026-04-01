# Terraform Sentinel Policies

This directory contains a comprehensive collection of Terraform Sentinel policies for enforcing infrastructure as code best practices across AWS resources.

## Overview

Sentinel is a policy-as-code framework used by Terraform Cloud and Terraform Enterprise to enforce policies on Terraform configurations before they are applied.

## Policies Included

### 1. aws_instance_tagging.sentinel
**Enforcement Level**: Mandatory

Ensures all EC2 instances have required tags for cost allocation and management.

**Required Tags**:
- Name
- Environment
- Owner
- CostCenter
- Application

**Validates**:
- All required tags are present
- Tag values are strings (1-255 characters)

### 2. aws_s3_encryption.sentinel
**Enforcement Level**: Mandatory

Ensures all S3 buckets have server-side encryption enabled.

**Validates**:
- Encryption configuration is set (SSE-S3 or SSE-KMS)
- Proper encryption algorithm is specified
- Buckets are not configured to disable encryption

### 3. aws_database_backup.sentinel
**Enforcement Level**: Mandatory

Enforces RDS backup configuration and retention policies.

**Validates**:
- Backup retention period is >= 7 days
- Backup window is configured
- Production databases skip final snapshot is disabled
- Enhanced monitoring/CloudWatch logs are enabled

### 4. aws_cost_control.sentinel
**Enforcement Level**: Soft-mandatory

Enforces cost optimization practices.

**Validates**:
- EC2 instance types don't exceed approved list
- RDS storage type is optimized (gp3/gp2)
- RDS storage size is reasonable (<= 500 GB)
- Non-production resources don't have unnecessary deletion protection

**Restrictions**:
- Blocks: t3.2xlarge, r5.4xlarge+, c5.4xlarge+

### 5. aws_allowed_resources.sentinel
**Enforcement Level**: Mandatory

Restricts which AWS resource types can be created.

**Approved Resources**:
- EC2 (instances, auto-scaling groups, launch templates)
- RDS Database
- S3 (buckets and related resources)
- Lambda Functions
- VPC (VPCs, subnets, route tables, internet/NAT gateways)
- Security Groups and rules
- Load Balancers
- IAM (roles, policies)
- CloudWatch Logs
- EFS
- ACM Certificates
- And more...

### 6. aws_network_security.sentinel
**Enforcement Level**: Mandatory

Enforces network security best practices.

**Validates**:
- Security groups don't allow SSH (22) to 0.0.0.0/0
- Security groups don't allow RDP (3389) to 0.0.0.0/0
- Dangerous ports are restricted from public access
- VPC has DNS hostnames enabled
- Network ACLs are properly configured

### 7. aws_lambda_security.sentinel
**Enforcement Level**: Mandatory

Enforces Lambda security best practices.

**Validates**:
- Timeout is configured (1-900 seconds)
- Memory is configured (128-10240 MB)
- Functions accessing databases are in a VPC with security groups
- Execution role is configured
- Production functions have reserved concurrent executions set

### 8. aws_rds_security.sentinel
**Enforcement Level**: Mandatory

Enforces RDS security best practices.

**Validates**:
- Production databases have Multi-AZ enabled
- Storage encryption is enabled
- Production databases are not publicly accessible
- VPC security groups are configured
- IAM database authentication is enabled (for MySQL/PostgreSQL)
- Automated backups are enabled

### 9. aws_iam_security.sentinel
**Enforcement Level**: Mandatory

Enforces IAM security best practices and proper role management.

**Validates**:
- IAM roles have descriptions
- IAM roles have tags
- IAM policy names are descriptive (3-128 characters)
- IAM assume role policies are properly configured
- Inline policies are monitored for broad permissions
- IAM users have appropriate tags

### 10. aws_cloudwatch_monitoring.sentinel
**Enforcement Level**: Mandatory

Enforces CloudWatch monitoring and logging best practices.

**Validates**:
- Log groups have retention policies (>= 7 days)
- Log groups have KMS encryption option
- Log group names are descriptive
- CloudWatch alarms have actions configured
- Alarms have proper evaluation periods and thresholds
- Metrics are enabled for monitoring

### 11. aws_vpc_flow_logs.sentinel
**Enforcement Level**: Mandatory

Enforces VPC Flow Logs for network traffic analysis and compliance.

**Validates**:
- Flow logs have traffic type specified (ACCEPT, REJECT, ALL)
- Flow logs have destination configured (CloudWatch or S3)
- Flow logs have IAM role ARN
- Flow logs have tags for tracking
- Production VPCs are set up for flow log monitoring

### 12. aws_ebs_encryption.sentinel
**Enforcement Level**: Mandatory

Enforces EBS volume encryption for data protection at rest.

**Validates**:
- All EBS volumes are encrypted
- EBS volumes use KMS encryption
- EBS volumes have tags
- EC2 root volumes are encrypted
- EC2 EBS block devices are encrypted
- Launch templates have encrypted volumes

### 13. aws_elasticache_security.sentinel
**Enforcement Level**: Mandatory

Enforces ElastiCache security and operational best practices.

**Validates**:
- ElastiCache clusters are in VPC
- Encryption at rest is enabled
- Encryption in transit is enabled
- Auth tokens are configured for encrypted clusters
- Production clusters have automatic failover enabled
- Production clusters have backup/snapshots enabled
- Engine version is specified

### 14. aws_api_gateway_security.sentinel
**Enforcement Level**: Mandatory

Enforces API Gateway security and operational best practices.

**Validates**:
- API Gateway has descriptions
- Stages have CloudWatch logging enabled
- Logging levels are properly configured
- Throttling settings are configured
- Metrics are enabled
- Stages have tags
- API methods have proper authorization (not NONE)

### 15. aws_dynamodb_security.sentinel
**Enforcement Level**: Mandatory

Enforces DynamoDB security and best practices.

**Validates**:
- Server-side encryption is enabled
- SSE specification is configured and enabled
- Point-in-time recovery is enabled for production tables
- Backup is configured for production tables
- Billing mode is properly set (PAY_PER_REQUEST or PROVISIONED)
- Tables have tags
- Tables have attribute definitions
- Hash keys are configured

### 16. aws_sns_sqs_security.sentinel
**Enforcement Level**: Mandatory

Enforces SNS and SQS security and messaging best practices.

**Validates**:
- SNS topics have KMS encryption
- SNS topics have access policies
- SNS topics have tags
- SQS queues have KMS encryption
- SQS message retention is configured properly
- SQS visibility timeout is set
- SQS long polling is configured
- SQS has access policies
- Production SQS queues have Dead-Letter Queues
- SQS queues have tags

### 17. aws_cloudtrail_audit.sentinel
**Enforcement Level**: Mandatory

Enforces CloudTrail configuration for compliance and audit logging.

**Validates**:
- CloudTrail is enabled
- Trail includes global service events
- Trail is multi-region
- Log file validation is enabled
- S3 bucket is configured for logs
- CloudWatch logs are configured (optional)
- Trail has tags
- Event selectors are configured
- KMS encryption is used for log files

### 18. aws_compliance_regulatory.sentinel
**Enforcement Level**: Mandatory

Enforces compliance with regulatory standards (HIPAA, PCI-DSS, SOC2, CIS).

**Validates**:
- Resources have compliance-required tags (Compliance, DataClassification, Owner, CostCenter)
- PII-tagged resources have encryption enabled
- Confidential resources have access logging
- Production resources have proper retention policies
- Sensitive resources are not publicly accessible
- Sensitive S3 buckets have versioning enabled

Required Tags: `Compliance`, `DataClassification`, `Owner`, `CostCenter`

Data Classifications: `PII`, `Confidential`, `Secret`, `Public`

### 19. aws_load_balancer_security.sentinel
**Enforcement Level**: Mandatory

Enforces load balancer security and best practices.

**Validates**:
- Load balancers are in VPC
- Load balancers have security groups configured
- Production load balancers have access logging enabled
- Load balancers have tags
- Listeners use HTTPS/TLS or HTTP (with redirect option)
- Target groups have health checks configured
- Health checks have proper thresholds and intervals
- Target groups have stickiness configured

### 20. aws_kms_key_management.sentinel
**Enforcement Level**: Mandatory

Enforces KMS key security and proper key management practices.

**Validates**:
- Key rotation is enabled
- Keys have descriptions
- Keys are not scheduled for deletion
- Key policies are configured
- Keys have tags
- Aliases are named descriptively
- Aliases target valid keys
- KMS grants have retiring principals
- Grant operations are properly defined

### 21. aws_storage_backup.sentinel
**Enforcement Level**: Mandatory

Enforces backup and disaster recovery best practices.

**Validates**:
- AWS Backup plans have rules configured
- Backup rules have lifecycle policies
- Backup vaults have encryption
- Backup vaults have tags
- Production S3 buckets have versioning enabled
- Production S3 buckets have replication configured (when required)
- Replication configurations are valid
- Replication rules have proper status and destinations

## sentinel.hcl

This is the Sentinel policy configuration file that defines:
- Policy file locations
- Enforcement levels for each policy
- Policy metadata

## Setup Instructions

### 1. Terraform Cloud/Enterprise Configuration

Add the following to your Terraform block or policy_set configuration:

```hcl
# main.tf or in your policy_set configuration
terraform {
  cloud {
    organization = "your-org"
    
    workspaces {
      name = "your-workspace"
    }
  }
}
```

### 2. Create a Policy Set

In Terraform Cloud/Enterprise:

1. Navigate to Settings > Policy Sets
2. Click "Create a new policy set"
3. Name: `terraform-best-practices`
4. Description: "Terraform Sentinel policies for infrastructure governance"
5. Point to this repository
6. Policy VCS path: `terraform-sentinel/`
7. Set enforcement level for each workspace

### 3. Apply Policies

Policies will automatically run on:
- Plan operations (shows policy violations)
- Apply operations (can be mandatory or optional override)

## Policy Testing

To test policies locally:

```bash
# Install Sentinel CLI
# On macOS: brew install sentinel
# On Linux: Download from HashiCorp releases

# Validate policy syntax
sentinel test

# Run specific test
sentinel test -run="TestPolicyName"
```

## Usage Examples

### Example: EC2 Instance with Valid Tags

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  
  tags = {
    Name        = "my-instance"
    Environment = "production"
    Owner       = "devops-team"
    CostCenter  = "engineering"
    Application = "api-server"
  }
}
```

### Example: RDS Instance with Security Best Practices

```hcl
resource "aws_db_instance" "example" {
  identifier     = "mydb"
  engine         = "postgres"
  engine_version = "14.5"
  instance_class = "db.t3.micro"
  
  allocated_storage    = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  publicly_accessible  = false
  multi_az             = true
  
  backup_retention_period           = 30
  backup_window                     = "03:00-04:00"
  iam_database_authentication_enabled = true
  skip_final_snapshot               = false
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_parameter_group_name = aws_db_parameter_group.example.name
  
  tags = {
    Environment = "production"
  }
}
```

## Customization

To customize policies for your organization:

1. Modify policy files in the `terraform-sentinel/` directory
2. Update enforcement levels in `sentinel.hcl`
3. Push changes to your VCS
4. Policies will automatically update in Terraform Cloud/Enterprise

## Common Overrides

Certain soft-mandatory policies can be overridden during apply:

1. In Terraform Cloud UI: Shows policy violations with "Override" option
2. In CLI: Use `terraform apply -auto-approve` after review

## Enforcement Levels

- **Mandatory**: Policy must pass; apply cannot proceed
- **Soft-mandatory**: Policy violations show but can be overridden
- **Advisory**: Violations are logged but don't block operations

## Best Practices

1. **Start Advisory**: Begin with advisory policies to understand behavior
2. **Graduate to Soft-mandatory**: Move to soft-mandatory for visibility
3. **Enforce Gradually**: Make mandatory after team adjustment
4. **Regular Review**: Review policy violations regularly
5. **Update Policies**: Update policies as security and cost requirements evolve

## Support and Contributions

- Review policy outputs in Terraform Cloud for violations
- Adjust policies based on team requirements
- Test policies in development workspaces first

## References

- [Terraform Sentinel Documentation](https://www.terraform.io/cloud-docs/sentinel)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
