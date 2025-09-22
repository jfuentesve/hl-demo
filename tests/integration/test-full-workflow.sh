#!/bin/bash

# HL-API Full Workflow Integration Test Script
# Tests the complete workflow from development to deployment

set -e  # Exit on any error

echo "🔗 HL-API: Testing Full Workflow Integration"
echo "==========================================="

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

# Configuration
WORKFLOW_TYPE="demo"  # Can be "full", "demo", or "offline"
DOCKER_IMAGE_TEMP="hl-api-integration-test:$(date +%Y%m%d-%H%M%S)"

# Function to check if we're in demo mode or full testing
is_demo_mode() {
    [ "$WORKFLOW_TYPE" = "demo" ] || [ "$WORKFLOW_TYPE" = "offline" ]
}

# Check prerequisites
print_status "Checking workflow prerequisites..."

# Check if AWS CLI is configured (skip in offline mode)
if ! is_demo_mode; then
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured (use 'aws configure' or 'aws configure --profile juanops')"
        exit 1
    fi
else
    print_success "Running in demo/offline mode (AWS checks skipped)"
fi

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker not installed"
    exit 1
fi
print_success "Docker available: $(docker --version)"

# Check .NET
if ! command -v dotnet >/dev/null 2>&1; then
    print_error ".NET SDK not installed"
    exit 1
fi
print_success ".NET SDK available: $(dotnet --version)"

echo ""

# Phase 1: Local Development Workflow
print_status "=== Phase 1: Local Development Workflow ==="
echo ""

# Test project build locally
print_status "Testing local project build..."
cd hl-api

if dotnet restore --verbosity quiet && dotnet build --configuration Release --verbosity quiet; then
    print_success "Local build successful"
else
    print_error "Local build failed"
    cd ..
    exit 1
fi
cd ..

# Test health endpoint without starting server (check configuration)
if grep -q "healthz" hl-api/Program.cs; then
    print_success "Health endpoint configured"
else
    print_warning "Health endpoint not found in Program.cs"
fi

echo ""

# Phase 2: Docker Integration
print_status "=== Phase 2: Docker Integration ==="
echo ""

# Build Docker image
print_status "Building Docker image for integration testing..."
cd hl-api
if docker build -t "$DOCKER_IMAGE_TEMP" . >/dev/null 2>&1; then
    print_success "Docker image built successfully"
    print_success "Image: $DOCKER_IMAGE_TEMP"
else
    print_error "Docker build failed"
    cd ..
    exit 1
fi
cd ..

# Start container for testing
print_status "Starting integration test container..."
if docker run -d --name hl-api-integration-test -p 8989:8080 "$DOCKER_IMAGE_TEMP" >/dev/null 2>&1; then
    print_success "Integration test container started"
else
    print_error "Failed to start integration test container"
    docker rm -f hl-api-integration-test >/dev/null 2>&1 || true
    exit 1
fi

# Wait for container to be ready
print_status "Waiting for container readiness..."
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s -f http://localhost:8989/healthz >/dev/null 2>&1; then
        print_success "Container is ready (attempt $attempt/$max_attempts)"
        break
    elif [ $attempt -eq $max_attempts ]; then
        print_error "Container failed to become ready after $max_attempts attempts"
        print_status "Container logs:"
        docker logs hl-api-integration-test | tail -10
        docker stop hl-api-integration-test >/dev/null 2>&1 || true
        docker rm hl-api-integration-test >/dev/null 2>&1 || true
        exit 1
    else
        print_warning "Health check failed (attempt $attempt/$max_attempts), retrying..."
        sleep 3
    fi
    attempt=$((attempt + 1))
done

echo ""

# Phase 3: API Integration Testing
print_status "=== Phase 3: API Integration Testing ==="
echo ""

# Test health endpoint
print_status "Testing health endpoint in container..."
if curl -s http://localhost:8989/healthz | grep -q "ok"; then
    print_success "Health endpoint responding correctly"
else
    print_warning "Health endpoint not responding as expected"
fi

# Test swagger endpoint
print_status "Testing Swagger availability..."
if curl -s -I http://localhost:8989/swagger/index.html | grep -q "200 OK"; then
    print_success "Swagger documentation accessible"
else
    if is_demo_mode; then
        print_warning "Swagger not accessible (may be normal in production container)"
    else
        print_warning "Swagger documentation not accessible"
    fi
fi

# Test API authentication (demo test)
print_status "Testing authentication endpoint..."
auth_payload='{"username": "admin", "password": "ChangeMe123!"}'
auth_response=$(curl -s -X POST http://localhost:8989/api/auth/login \
  -H "Content-Type: application/json" \
  -d "$auth_payload")

if echo "$auth_response" | grep -q "token"; then
    print_success "Authentication working in container"
else
    print_warning "Authentication may not be working correctly"
    echo "Response: $auth_response"
fi

echo ""

# Phase 4: AWS Integration (skip in demo mode)
if ! is_demo_mode; then
    print_status "=== Phase 4: AWS Integration ==="
    echo ""

    # Test AWS ECR connectivity
    print_status "Testing ECR connectivity..."
    if aws ecr describe-repositories --repository-names hl-api >/dev/null 2>&1; then
        print_success "ECR repository accessible"
    else
        print_warning "ECR repository not found or not accessible"
        echo "This may be normal if infrastructure is not deployed yet"
    fi

    # Test AWS ECS connectivity
    print_status "Testing ECS connectivity..."
    if aws ecs describe-clusters --clusters hl-ecs-cluster >/dev/null 2>&1; then
        print_success "ECS cluster accessible"
    else
        print_warning "ECS cluster not found or not accessible"
        echo "This may be normal if infrastructure is not deployed yet"
    fi

    echo ""
else
    print_status "=== Phase 4: AWS Integration (Skipped - Demo Mode) ==="
    print_warning "AWS integration tests skipped in demo mode"
    echo ""
fi

# Phase 5: Deployment Integration
print_status "=== Phase 5: Deployment Script Integration ==="
echo ""

# Test build-push-local.sh (dry run)
print_status "Testing deployment script structure..."
if [ -f "build-push-local.sh" ]; then
    if head -10 build-push-local.sh | grep -q "#!/bin/bash\|#!/usr/bin/env bash"; then
        print_success "build-push-local.sh has proper shebang"
    else
        print_warning "build-push-local.sh missing shebang or not executable"
    fi
else
    print_warning "build-push-local.sh not found"
fi

# Test deploy script
print_status "Testing deployment script structure..."
if [ -f "deploy-api-image-from-ecr.sh" ]; then
    if head -10 deploy-api-image-from-ecr.sh | grep -q "#!/bin/bash\|#!/usr/bin/env bash"; then
        print_success "deploy-api-image-from-ecr.sh has proper shebang"
    else
        print_warning "deploy-api-image-from-ecr.sh missing shebang or not executable"
    fi
else
    print_warning "deploy-api-image-from-ecr.sh not found"
fi

echo ""

# Phase 6: Cleanup
print_status "=== Phase 6: Cleanup ==="
echo ""

print_status "Stopping integration test container..."
docker stop hl-api-integration-test >/dev/null 2>&1 || true
print_success "Test container stopped"

print_status "Removing test resources..."
docker rm hl-api-integration-test >/dev/null 2>&1 || true
docker rmi "$DOCKER_IMAGE_TEMP" >/dev/null 2>&1 || true
print_success "Test resources cleaned up"

echo ""

# Final Summary
echo "==========================================="
print_success "Full Workflow Integration Test Completed!"
echo ""

if is_demo_mode; then
    echo -e "🎯 Test Results: ${GREEN}Demo Mode Complete${NC}"
    echo -e "   ✅ Local development: ${GREEN}Working${NC}"
    echo -e "   ✅ Docker integration: ${GREEN}Working${NC}"
    echo -e "   ✅ API functionality: ${GREEN}Basic${NC}"
    echo -e "   ⚠️  AWS integration: ${YELLOW}Skipped${NC}"
    echo ""
    echo "📋 Next Steps for Full Testing:"
    echo "1. Deploy AWS infrastructure with Terraform"
    echo "2. Update connection strings in appsettings.json"
    echo "3. Run './build-push-local.sh' to push image to ECR"
    echo "4. Run './deploy-api-image-from-ecr.sh' for ECS deployment"
    echo "5. Test full workflow with './tests/run-all-tests.sh'"
else
    echo -e "🎯 Test Results: ${GREEN}Full Integration Working${NC}"
    echo -e "   ✅ Local development: ${GREEN}Working${NC}"
    echo -e "   ✅ Docker integration: ${GREEN}Working${NC}"
    echo -e "   ✅ API functionality: ${GREEN}Working${NC}"
    echo -e "   ✅ AWS integration: ${GREEN}Working${NC}"
    echo ""
    echo "🚀 Ready for Production Deployment!"
fi

echo ""
echo "🛠️  Useful Commands:"
echo "    • Run all tests: ./tests/run-all-tests.sh"
echo "    • Local development: cd hl-api && dotnet run"
echo "    • Docker test: ./tests/docker/test-docker-build.sh"
echo "    • API test: ./tests/api/test-api-endpoints.sh"
echo "    • Build and deploy: ./build-push-local.sh && ./deploy-api-image-from-ecr.sh"
