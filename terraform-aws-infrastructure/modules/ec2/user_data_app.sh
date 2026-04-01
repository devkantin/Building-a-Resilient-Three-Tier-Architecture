#!/bin/bash
set -e

# Update system
yum update -y

# Install Java for application server
amazon-linux-extras install -y java-11-openjdk

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch Logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/app/app.log",
            "log_group_name": "/aws/ec2/app-server/logs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

echo "Application server setup complete"
