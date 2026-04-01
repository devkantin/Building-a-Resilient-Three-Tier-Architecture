#!/bin/bash
set -e

# Update system
yum update -y

# Install PostgreSQL client (for DB server)
yum install -y postgresql

# Install MySQL client (for compatibility)
yum install -y mysql

# Install monitoring tools
yum install -y sysstat

# Create data directory
mkdir -p /data
chmod 700 /data

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

echo "Database server setup complete"
