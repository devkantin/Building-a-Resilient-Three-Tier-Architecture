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
