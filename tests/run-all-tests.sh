#!/bin/bash

# HL-API Test Suite Runner
# Executes all test suites in proper order

set -e  # Exit on any error

echo "🚀 HL-API: Running All Tests"
echo "============================"

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

# Track test results
total_tests=0
passed_tests=0
failed_tests=0

# Function to run a test script
run_test() {
    local test_name="$1"
    local test_script="$2"
    local description="$3"

    echo ""
    print_status "Running $test_name - $description"
    echo "--------------------------------"

    total_tests=$((total_tests + 1))

    # Check if script exists and is executable
    if [ ! -f "$test_script" ]; then
        print_error "Test script not found: $test_script"
        failed_tests=$((failed_tests + 1))
        return 1
    fi

    if [ ! -x "$test_script" ]; then
        print_warning "Making script executable: $test_script"
        chmod +x "$test_script"
    fi

    # Run the test script
    if "$test_script"; then
        print_success "$test_name passed"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        print_error "$test_name failed"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

# Generate test timestamp
TEST_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo -e "Test execution started at: ${BLUE}$TEST_TIMESTAMP${NC}"
echo ""

# Test 1: AWS Connectivity
run_test "AWS Connectivity Test" "./tests/aws-services/test-aws-connectivity.sh" "Verify AWS CLI connectivity and permissions"

# Test 2: Docker Build
run_test "Docker Build Test" "./tests/docker/test-docker-build.sh" "Test Docker image build and container functionality"

# Test 3: Local Development
run_test "Local Development Test" "./tests/local-dev/test-local-setup.sh" "Test local .NET development environment"

# Test 4: API Endpoints (requires Docker container running or .NET app running)
run_test "API Endpoints Test" "./tests/api/test-api-endpoints.sh" "Test all API endpoints and authentication flow"

# Test 5: Integration Tests
run_test "Integration Test" "./tests/integration/test-full-workflow.sh" "Full workflow integration test"

# Print final results
echo ""
echo "================================"
echo "      TEST RESULTS SUMMARY      "
echo "================================"

echo "Total Tests Run: $total_tests"
echo "Passed Tests: $passed_tests"
echo "Failed Tests: $failed_tests"

if [ $failed_tests -eq 0 ]; then
    echo ""
    print_success "🎉 All tests passed! Your HL-API project is working correctly!"
    echo ""
    echo "Next steps:"
    echo "1. Run 'terraform apply' to deploy infrastructure if not already done"
    echo "2. Push your Docker image: ./build-push-local.sh"
    echo "3. Deploy to AWS: ./deploy-api-image-from-ecr.sh"
    echo "4. Monitor the deployment: ./is-api-running.sh"
else
    echo ""
    print_error "❌ $failed_tests test(s) failed"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check individual test outputs above for specific error details"
    echo "2. Ensure all prerequisites are installed (Docker, .NET 8, AWS CLI)"
    echo "3. Verify AWS credentials and permissions"
    echo "4. Check that no conflicting services are running on test ports"
fi

# Generate test report
REPORT_FILE="tests/test-results-$(date +%Y%m%d-%H%M%S).log"
echo ""
echo "Test execution completed at: $(date +"%Y-%m-%d %H:%M:%S")" | tee "$REPORT_FILE"
echo "Results saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Test Summary:" | tee -a "$REPORT_FILE"
echo "- Total: $total_tests" | tee -a "$REPORT_FILE"
echo "- Passed: $passed_tests" | tee -a "$REPORT_FILE"
echo "- Failed: $failed_tests" | tee -a "$REPORT_FILE"

# Exit with proper code
if [ $failed_tests -eq 0 ]; then
    exit 0
else
    exit 1
fi
