#!/bin/bash

# SSM Bastion Host Setup Script
# This script configures AWS Session Manager bastion host for database administration

# Update system packages
yum update -y

# Install and start SSM Agent (usually pre-installed, but ensure it's running)
if ! systemctl is-enabled amazon-ssm-agent 2>/dev/null; then
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
fi

# Install Microsoft SQL Tools for database administration
curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/pki/rpm-gpg/microsoft.asc.key
curl -s https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/microsoft-prod.repo
yum install -y mssql-tools unixODBC-devel

# Configure PATH for SQL Tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/ec2-user/.bashrc

# Create database connection test script
cat > /home/ec2-user/test-db-connection.sh << 'EOF'
#!/bin/bash

# Database Connection Test Script for HL Deals Bastion
echo "🔌 Testing RDS SQL Server Connection..."
echo "======================================="

# Database connection parameters (passed from Terraform)
RDS_ENDPOINT="$${rds_endpoint}"
DB_USER="$${db_username}"
DB_PASS="$${db_password}"
DB_NAME="$${db_name}"

echo "📊 Connection Details:"
echo "  Server: $RDS_ENDPOINT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

echo "🔍 Attempting database connection..."
sqlcmd -S "$RDS_ENDPOINT" -U "$DB_USER" -P "$DB_PASS" -d "$DB_NAME" \
  -Q "SELECT TOP 1 @@VERSION AS SqlVersion; SELECT DB_NAME() AS CurrentDB;" \
  -b -o /tmp/db_test_result.txt 2>/tmp/db_test_error.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ DATABASE CONNECTION SUCCESSFUL!"
    echo ""
    echo "📋 SQL Server Information:"
    echo "---------------------------"
    cat /tmp/db_test_result.txt
    echo ""
    echo "🛠️  Available Database Administration Tools:"
    echo "  • sqlcmd (SQL Server Commander)"
    echo "  • bcp (Bulk Copy Program)"
    echo "  • SQL Server Management Tools (via sqlcmd)"
    echo ""
    echo "📝 Usage Examples:"
    echo "  # Interactive SQL:"
    echo "  sqlcmd -S $RDS_ENDPOINT -U $DB_USER -P 'your_password' -d $DB_NAME"
    echo ""
    echo "  # Run SQL file:"
    echo "  sqlcmd -S $RDS_ENDPOINT -U $DB_USER -P 'your_password' -d $DB_NAME -i query.sql"
    echo ""
    echo "  # Bulk operations:"
    echo "  bcp 'SELECT * FROM deals' queryout deals.csv -S \$RDS_ENDPOINT -U \$DB_USER -P 'your_password' -d \$DB_NAME -c -t '\\t'"
    echo ""
    echo "🎉 You are ready to administer the HL Deals database!"
else
    echo ""
    echo "❌ DATABASE CONNECTION FAILED"
    echo "==============================="
    echo "Possible issues:"
    echo "• Network connectivity blocked (check security groups)"
    echo "• Database credentials incorrect"
    echo "• Database server unreachable"
    echo "• MSSQL tools installation problem"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Check VPC security group rules"
    echo "2. Verify database endpoint and port"
    echo "3. Validate credentials"
    echo "4. Test with: nc -zv $RDS_ENDPOINT.split(",")[0] $${RDS_ENDPOINT.split(",")[1]}"
    echo ""
    if [ -f /tmp/db_test_error.txt ]; then
        echo "📋 Detailed Error:"
        cat /tmp/db_test_error.txt
    fi
fi
EOF

# Make test script executable and set ownership
chmod +x /home/ec2-user/test-db-connection.sh
chown ec2-user:ec2-user /home/ec2-user/test-db-connection.sh

# Create welcome message for SSM sessions
cat > /home/ec2-user/.bashrc << 'EOF'
# Welcome message for HL Deals Bastion
if [ "$PS1" ]; then
    echo "🏗️  HL Deals Database Administration Bastion"
    echo "============================================"
    echo "✅ SSM Session Manager access - No IP restrictions required!"
    echo ""
    echo "🛠️  Available tools:"
    echo "  • sqlcmd - SQL Server command-line tool"
    echo "  • test-db-connection.sh - Test database connectivity"
    echo ""
    echo "📚 Quick Start:"
    echo "  ./test-db-connection.sh          # Test DB connection"
    echo "  sqlcmd -S <endpoint> -U user -P pwd -d db    # Interactive SQL"
    echo ""
    echo "🔥 Your database is: hl-deals-db-dev"
    echo ""
fi
EOF

chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Create documentation file
cat > /home/ec2-user/README-BASTION.txt << 'EOF'
# HL Deals Database Administration Bastion
#
# This bastion host provides secure access to the HL Deals database
# via AWS Systems Manager Session Manager.
#
# 🛡️  Security:
# • Access controlled by AWS IAM (no SSH keys)
# • All sessions logged in CloudTrail
# • No public internet exposure
# • Works from anywhere without IP restrictions
#
# 🗄️  Database Connection:
# • Server: hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com,1433
# • Database: hldeals
# • Type: SQL Server (Microsoft)
#
# 🚀 Quick Start:
# 1. Test connection: ./test-db-connection.sh
# 2. Interactive SQL: sqlcmd -S <endpoint> -U <user> -P <pass> -d hldeals
# 3. Run migrations: sqlcmd -i migration.sql -S <endpoint> -U <user> -P <pass>
#
# 📋 Available Tools:
# • SQL Server Command Line Tools (sqlcmd, bcp)
# • Connection test scripts
# • Standard AWS CLI tools (already available)
EOF

chown ec2-user:ec2-user /home/ec2-user/README-BASTION.txt

# Install additional useful tools for database administration
yum install -y jq curl wget htop

# Create system information script
cat > /home/ec2-user/system-info.sh << 'EOF'
#!/bin/bash
echo "🔧 HL Bastion System Information"
echo "==============================="
echo "Instance ID:  $(ec2-metadata -i)"
echo "Public IP:    $(ec2-metadata -v)"
echo "Region:       $(ec2-metadata -z | sed 's/.*\(us-[a-z]*-[0-9]*\).*/\1/')"
echo "Uptime:       $(uptime)"
echo ""
echo "🗄️  Database Access:"
echo "• Endpoint: hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com:1433"
echo "• Database: hldeals"
echo "• Tools: sqlcmd, bcp"
EOF

chmod +x /home/ec2-user/system-info.sh
chown ec2-user:ec2-user /home/ec2-user/system-info.sh

echo "✅ SSM Bastion setup complete!"
echo "🔥 Ready for database administration via Session Manager"
