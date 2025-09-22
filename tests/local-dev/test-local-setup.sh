#!/bin/bash

# HL-API Local Development Test Script
# Tests the local development environment setup

set -e  # Exit on any error

echo "🏠 HL-API: Testing Local Development"
echo "==================================="

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

# Test .NET installation
print_status "Checking .NET SDK installation..."
if ! command -v dotnet &> /dev/null; then
    print_error ".NET SDK is not installed or not in PATH"
    echo "Please install .NET 8.0 SDK from: https://dotnet.microsoft.com/download"
    exit 1
fi

dotnet_version=$(dotnet --version)
dotnet_runtime=$(dotnet --list-runtimes | head -1)
print_success ".NET SDK found: $dotnet_version"
echo -e "  Runtime: ${BLUE}$dotnet_runtime${NC}"

# Test project structure
print_status "Checking project structure..."
if [ ! -f "firstDemo.sln" ]; then
    print_error "Solution file not found: firstDemo.sln"
    exit 1
fi

if [ ! -d "hl-api" ]; then
    print_error "API project directory not found: hl-api/"
    exit 1
fi

if [ ! -f "hl-api/HLApi.csproj" ]; then
    print_error "Project file not found: hl-api/HLApi.csproj"
    exit 1
fi

print_success "Project structure intact"

# Test dotnet restore
print_status "Testing dotnet restore..."
cd hl-api
if dotnet restore --verbosity quiet; then
    print_success "Package restoration successful"
else
    print_error "Package restoration failed"
    cd ..
    exit 1
fi
cd ..

# Test dotnet build
print_status "Testing dotnet build..."
cd hl-api
if dotnet build --verbosity quiet --configuration Release; then
    print_success "Project build successful"
else
    print_error "Project build failed"
    cd ..
    exit 1
fi
cd ..

# Test webhook endpoint mapping for health check
print_status "Checking health check endpoint..."
if grep -q "app.MapGet.*healthz" hl-api/Program.cs; then
    print_success "Health check endpoint mapped"
else
    print_warning "Health check endpoint may be missing"
fi

# Test environment files
print_status "Checking environment configuration..."
if [ -f "hl-api/appsettings.json" ]; then
    print_success "Appsettings.json found"
    # Check if JWT configuration exists
    if grep -q "Jwt" hl-api/appsettings.json; then
        print_success "JWT configuration found"
    else
        print_warning "JWT configuration not found in appsettings.json"
    fi
else
    print_error "Appsettings.json not found"
    exit 1
fi

# Test JWT setup script
print_status "Checking JWT setup script..."
if [ -x "jwt-key-setup.sh" ]; then
    print_success "JWT setup script executable"
    ./jwt-key-setup.sh status 2>/dev/null || print_warning "JWT setup script may need configuration"
else
    print_warning "JWT setup script not executable or missing"
fi

# Test database connection string
print_status "Checking database configuration..."
if grep -q "DefaultConnection" hl-api/appsettings.json; then
    print_success "Database connection string configured"
    # Extract connection string (basic check)
    if grep -q "YOUR_RDS_ENDPOINT" hl-api/appsettings.json; then
        print_warning "Database connection string contains placeholder values"
        echo "  Please update with actual RDS endpoint"
    fi
else
    print_warning "Database connection string not found"
    print_warning "Local SQLite may be used instead"
fi

# Test CORS configuration
print_status "Checking CORS configuration..."
if grep -q "UseCors\|AddCors" hl-api/Program.cs; then
    print_success "CORS configuration found"
else
    print_warning "CORS configuration not found (may be handled by default policies)"
fi

# Test HTTPS redirection
print_status "Checking HTTPS configuration..."
if grep -q "UseHttpsRedirection" hl-api/Program.cs; then
    print_success "HTTPS redirection configured"
else
    print_warning "HTTPS redirection not configured (may be normal in development)"
fi

# Test Swagger configuration
print_status "Checking Swagger configuration..."
if grep -q "AddSwaggerGen\|UseSwaggerUI" hl-api/Program.cs; then
    print_success "Swagger/OpenAPI configured"
else
    print_warning "Swagger not configured (may be normal in production)"
fi

# Test static file serving
print_status "Checking static file configuration..."
if grep -q "UseStaticFiles\|UseSpaStaticFiles" hl-api/Program.cs; then
    print_success "Static file serving configured"
elif [ -d "hl-api/wwwroot" ]; then
    print_warning "Static files folder exists but not configured"
else
    print_warning "Static file serving may not be configured"
fi

# Test controller structure
print_status "Checking API controller structure..."
if [ -d "hl-api/Controllers" ]; then
    controller_count=$(find hl-api/Controllers -name "*.cs" | wc -l)
    if [ "$controller_count" -gt 0 ]; then
        print_success "Found $controller_count controller(s)"
        # List controllers
        find hl-api/Controllers -name "*.cs" -exec basename {} \; | sed 's/^/    /'
    else
        print_error "No controllers found in Controllers directory"
        exit 1
    fi
else
    print_error "Controllers directory not found"
    exit 1
fi

# Test model structure
print_status "Checking data model structure..."
if [ -d "hl-api/Models" ]; then
    model_count=$(find hl-api/Models -name "*.cs" | wc -l)
    if [ "$model_count" -gt 0 ]; then
        print_success "Found $model_count model(s)"
        find hl-api/Models -name "*.cs" -exec basename {} \; | sed 's/^/    /'
    else
        print_warning "No data models found"
    fi
else
    print_error "Models directory not found"
    exit 1
fi

# Test DTO structure
print_status "Checking DTO structure..."
if [ -d "hl-api/Dtos" ]; then
    dto_count=$(find hl-api/Dtos -name "*.cs" | wc -l)
    if [ "$dto_count" -gt 0 ]; then
        print_success "Found $dto_count DTO(s)"
        find hl-api/Dtos -name "*.cs" -exec basename {} \; | sed 's/^/    /'
    else
        print_warning "No DTOs found"
    fi
else
    print_warning "DTOs directory not found (using model classes directly?)"
fi

# Check authentication services
print_status "Checking authentication services..."
if [ -d "hl-api/Services" ]; then
    service_count=$(find hl-api/Services -name "*.cs" | wc -l)
    if [ "$service_count" -gt 0 ]; then
        print_success "Found $service_count service(s)"
        if find hl-api/Services -name "*Token*" -o -name "*Auth*" |grep -q .; then
            print_success "Authentication service(s) found"
        else
            print_warning "No authentication services found"
        fi
    fi
else
    print_warning "Services directory not found"
fi

# Check database context
print_status "Checking database context..."
if find hl-api -name "*Context.cs" | grep -q .; then
    print_success "Database context found"
    find hl-api -name "*Context.cs" | sed 's/^/    /'
else
    print_error "Database context not found"
    exit 1
fi

# Final checks
echo ""
print_status "Performing final setup validation..."

# Check for proper solution structure
if dotnet sln list | grep -q "hl-api"; then
    print_success "Project properly included in solution"
else
    print_warning "Project may not be properly included in solution"
fi

# Check for .gitignore
if [ -f ".gitignore" ]; then
    print_success ".gitignore configured"
    if grep -q "bin\|obj" .gitignore; then
        print_success "Build artifacts properly ignored"
    fi
else
    print_warning ".gitignore not found"
fi

echo ""
echo "==================================="
print_success "Local Development Initialization Check Completed!"
echo ""
echo "✅ Prerequisites Met:"
echo -e "   • .NET SDK installed: ${GREEN}Yes${NC}"
echo -e "   • Project structure valid: ${GREEN}Yes${NC}"
echo -e "   • Dependencies resolvable: ${GREEN}Yes${NC}"
echo -e "   • Build successful: ${GREEN}Yes${NC}"
echo ""

echo "🎯 Next Steps:"
echo "1. Run 'dotnet run --project hl-api' to start the API locally"
echo "2. Open browser to https://localhost:5001/swagger for testing"
echo "3. Configure actual database connection string"
echo "4. Run './build-push-local.sh' when ready to deploy"

echo ""
echo "🛠️  Development Commands:"
echo "    • Start API: cd hl-api && dotnet run"
echo "    • Clean build: cd hl-api && dotnet clean && dotnet build"
echo "    • Restore packages: cd hl-api && dotnet restore"
echo "    • Watch mode: cd hl-api && dotnet watch run"
