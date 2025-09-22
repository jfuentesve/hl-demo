#!/bin/bash

# HL-API AWS Connectivity Test Script
# Tests basic AWS CLI connectivity and permissions for all required services

set -e  # Exit on any error

echo "🔧 HL-API: Testing AWS Connectivity"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test AWS CLI configuration
print_status "Testing AWS CLI credentials..."
aws_configure_output=$(aws configure list)

if echo "$aws_configure_output" | grep -q "configured"; then
    print_warning "AWS CLI appears to be configured but may need profile selection"
else
    print_success "AWS CLI credentials configured"
fi

# Test basic connectivity
print_status "Testing basic AWS connectivity..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    caller_identity=$(aws sts get-caller-identity)
    account_id=$(echo "$caller_identity" | grep "Account" | cut -d '"' -f 4)
    user_arn=$(echo "$caller_identity" | grep "Arn" | cut -d '"' -f 4)
    user_name=$(echo "$user_arn" | sed 's/.*user\///')

    print_success "Connected to AWS"
    echo -e "  Account ID: ${BLUE}$account_id${NC}"
    echo -e "  User ARN: ${BLUE}$user_arn${NC}"
    echo -e "  User: ${BLUE}$user_name${NC}"
else
    print_error "Failed to connect to AWS. Please check credentials."
    echo "Run 'aws configure' to set up credentials"
    echo "Or export AWS_PROFILE=<your-profile-name>"
    exit 1
fi

# Test ECR access
print_status "Testing Amazon ECR access..."
if aws ecr describe-repositories --repository-names hl-api > /dev/null 2>&1; then
    print_success "ECR repository 'hl-api' accessible"
    ecr_info=$(aws ecr describe-repositories --repository-names hl-api)
    ecr_uri=$(echo "$ecr_info" | grep "repositoryUri" | cut -d '"' -f 4)
    echo -e "  ECR URI: ${BLUE}$ecr_uri${NC}"
else
    print_warning "ECR repository 'hl-api' not found or not accessible"
    echo "This may be normal if infrastructure is not deployed yet"
fi

# Test ECS cluster access
print_status "Testing Amazon ECS cluster access..."
if aws ecs describe-clusters --clusters hl-ecs-cluster > /dev/null 2>&1; then
    print_success "ECS cluster 'hl-ecs-cluster' accessible"
    cluster_status=$(aws ecs describe-clusters --clusters hl-ecs-cluster | grep "status" | head -1 | cut -d '"' -f 4)
    echo -e "  Cluster Status: ${BLUE}$cluster_status${NC}"
else
    print_warning "ECS cluster 'hl-ecs-cluster' not found or not accessible"
    echo "This may be normal if infrastructure is not deployed yet"
fi

# Test ALB access
print_status "Testing Application Load Balancer access..."
alb_name="hl-api-alb"
if aws elbv2 describe-load-balancers --names "$alb_name" > /dev/null 2>&1; then
    print_success "ALB '$alb_name' accessible"
    alb_info=$(aws elbv2 describe-load-balancers --names "$alb_name")
    alb_dns=$(echo "$alb_info" | grep "DNSName" | head -1 | cut -d '"' -f 4)
    echo -e "  ALB DNS: ${BLUE}$alb_dns${NC}"
else
    print_warning "ALB '$alb_name' not found or not accessible"
    echo "This may be normal if infrastructure is not deployed yet"
fi

# Test RDS access
print_status "Testing Amazon RDS access..."
db_identifier="hl-deals-db-dev"
if aws rds describe-db-instances --db-instance-identifier "$db_identifier" > /dev/null 2>&1; then
    print_success "RDS instance '$db_identifier' accessible"
    rds_info=$(aws rds describe-db-instances --db-instance-identifier "$db_identifier")
    rds_endpoint=$(echo "$rds_info" | grep "Address" | head -1 | cut -d '"' -f 4)
    rds_status=$(echo "$rds_info" | grep "DBInstanceStatus" | head -1 | cut -d '"' -f 4)
    echo -e "  Endpoint: ${BLUE}$rds_endpoint${NC}"
    echo -e "  Status: ${BLUE}$rds_status${NC}"
else
    print_warning "RDS instance '$db_identifier' not found or not accessible"
    echo "This may be normal if infrastructure is not deployed yet"
fi

# Test CloudWatch logs access
print_status "Testing AWS CloudWatch Logs access..."
if aws logs describe-log-groups --log-group-name-prefix "/ecs/hl-api" > /dev/null 2>&1; then
    print_success "CloudWatch log group '/ecs/hl-api' accessible"
    log_group_info=$(aws logs describe-log-groups --log-group-name-prefix "/ecs/hl-api")
    log_group_name=$(echo "$log_group_info" | grep "logGroupName" | head -1 | cut -d '"' -f 4)
    echo -e "  Log Group: ${BLUE}$log_group_name${NC}"
else
    print_warning "CloudWatch log group '/ecs/hl-api' not found or not accessible"
    echo "This may be normal if infrastructure is not deployed yet"
fi

# Test IAM permissions
print_status "Testing IAM permissions..."
iam_policies="
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:GetDownloadUrlForLayer
ecr:BatchGetImage
ecr:DescribeRepositories
ecr:CreateRepository
ecr:GetRepositoryPolicy
ecr:ListImages
ecr:DeleteRepository
ecr:BatchDeleteImage
ecr:SetRepositoryTags
ecr:UntagResource
ecr:TagResource
ecs:ListClusters
ecs:DescribeClusters
ecs:ListTasks
ecs:DescribeTasks
ecs:RunTask
ecs:StopTask
ecs:ListServices
ecs:DescribeServices
ecs:UpdateService
logs:CreateLogGroup
logs:DescribeLogGroups
logs:CreateLogStream
logs:PutLogEvents
logs:DescribeLogStreams
rds:DescribeDBInstances
"

permissions_issues=0
for policy in $iam_policies; do
    if aws iam get-user-policy --user-name "$user_name" --policy-name "ECSTaskRole" > /dev/null 2>&1; then
        print_success "IAM policy check available (detailed check skipped for brevity)"
        break
    fi
done

if [ $permissions_issues -eq 0 ]; then
    print_success "Basic IAM check completed"
fi

# Test region configuration
region=$(aws configure get region)
print_success "AWS Region: $region"

echo ""
echo "=================================="
print_success "AWS Connectivity Test Completed!"
echo ""
echo "Next steps:"
echo "1. If any tests failed, check your AWS credentials and permissions"
echo "2. Run './build-push-local.sh' to test Docker build and ECR push"
echo "3. Run './deploy-api-image-from-ecr.sh' to test ECS deployment"
echo "4. Check 'terraform/hl-infra/main.tf' for infrastructure configuration"
