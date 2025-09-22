#!/bin/bash

# HL-API Docker Build Test Script
# Tests Docker image build process and container functionality

set -e  # Exit on any error

echo "🐳 HL-API: Testing Docker Build"
echo "=============================="

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

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Get Docker version
docker_version=$(docker --version)
print_success "Docker found: $docker_version"

# Check if running in project directory
if [ ! -f "hl-api/Dockerfile" ]; then
    print_error "Not in project directory or Dockerfile not found"
    exit 1
fi

# Set image name
DOCKER_IMAGE="hl-api-test:$(date +%Y%m%d-%H%M%S)"
print_status "Using test image name: $DOCKER_IMAGE"

# Clean up any existing test containers
print_status "Cleaning up existing test containers..."
docker rm -f hl-api-test-container >/dev/null 2>&1 || true
docker images -q "$DOCKER_IMAGE" | xargs -r docker rmi >/dev/null 2>&1 || true

# Test Docker build
print_status "Building Docker image..."
cd hl-api
if docker build -t "$DOCKER_IMAGE" .; then
    print_success "Docker image built successfully"
else
    print_error "Docker build failed"
    exit 1
fi
cd ..

# Check if image exists
print_status "Checking Docker image..."
if docker images "$DOCKER_IMAGE" | grep -q "$DOCKER_IMAGE"; then
    image_info=$(docker images "$DOCKER_IMAGE" | tail -n 1)
    image_size=$(echo "$image_info" | awk '{print $7}')
    print_success "Docker image created"
    echo -e "  Image Size: ${BLUE}$image_size${NC}"
else
    print_error "Docker image not found"
    exit 1
fi

# Test container startup
print_status "Testing container startup..."
if docker run -d --name hl-api-test-container -p 8090:8080 "$DOCKER_IMAGE" >/dev/null; then
    print_success "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait for container to be ready
print_status "Waiting for container to be ready..."
sleep 10

# Test health check endpoint
print_status "Testing health endpoint..."
max_attempts=5
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s -f http://localhost:8090/healthz >/dev/null 2>&1; then
        print_success "Health check endpoint responsive"
        break
    elif [ $attempt -eq $max_attempts ]; then
        print_error "Health check endpoint not responding after $max_attempts attempts"
        print_status "Container logs:"
        docker logs hl-api-test-container | head -20
        docker stop hl-api-test-container >/dev/null 2>&1 || true
        docker rm hl-api-test-container >/dev/null 2>&1 || true
        exit 1
    else
        print_warning "Health check failed (attempt $attempt/$max_attempts), retrying..."
        sleep 5
    fi
    attempt=$((attempt + 1))
done

# Test Swagger endpoint (if available)
print_status "Testing Swagger endpoint..."
if curl -s -f http://localhost:8090/swagger/index.html >/dev/null 2>&1; then
    print_success "Swagger documentation accessible"
else
    print_warning "Swagger documentation not accessible (may be normal in production build)"
fi

# Get container info
print_status "Getting container information..."
container_info=$(docker inspect hl-api-test-container)
container_status=$(echo "$container_info" | grep -o '"Status":"[^"]*"' | cut -d'"' -f4)
container_health=$(echo "$container_info" | grep -o '"Health":{"Status":"[^"]*"' | cut -d'"' -f2 2>/dev/null || echo "N/A")

echo -e "  Container Status: ${BLUE}$container_status${NC}"
if [ "$container_health" != "N/A" ]; then
    echo -e "  Container Health: ${BLUE}$container_health${NC}"
fi

# Check container logs
print_status "Checking container logs..."
logs_summary=$(docker logs hl-api-test-container 2>&1 | tail -10)
print_success "Container logs (last 10 lines):"
echo "$logs_summary" | sed 's/^/    /'

# Test environment variables (if any)
print_status "Testing environment-variable handling..."
env_output=$(docker exec hl-api-test-container printenv | grep -E "(ASPNETCORE|DOTNET)" || echo "No standard ASP.NET variables found")
if [ -n "$env_output" ]; then
    print_success "Environment variables found:"
    echo "$env_output" | sed 's/^/    /'
else
    print_warning "No standard ASP.NET environment variables detected"
fi

# Cleanup
print_status "Cleaning up test resources..."
docker stop hl-api-test-container >/dev/null 2>&1 || true
docker rm hl-api-test-container >/dev/null 2>&1 || true
docker rmi "$DOCKER_IMAGE" >/dev/null 2>&1 || true
print_success "Test resources cleaned up"

echo ""
echo "=============================="
print_success "Docker Build Test Completed!"
echo ""
echo "All tests passed! Your Docker setup is working correctly."
echo ""
echo "Next steps:"
echo "1. Run './build-push-local.sh' to build and push to ECR"
echo "2. Create tests for database connectivity"
echo "3. Test with local database connection"
echo "4. Set up CI/CD with automated testing"
