#!/bin/bash

echo "🔍 PRODUCTION API COMPREHENSIVE TEST"
echo "====================================="

API_URL="http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}1. Checking ECS Service Health${NC}"
echo -e "${YELLOW}Note: This requires AWS CLI configured with proper permissions${NC}"

echo ""
echo -e "${BLUE}2. Testing Health Endpoint${NC}"
HEALTH_RESPONSE=$(curl -s "$API_URL/healthz" 2>/dev/null)
if [ "$HEALTH_RESPONSE" = '"ok"' ]; then
    echo -e "✅ ${GREEN}Health endpoint: SUCCESS${NC}"
else
    echo -e "❌ ${RED}Health endpoint: FAILED${NC}"
    echo "Response: $HEALTH_RESPONSE"
fi

echo ""
echo -e "${BLUE}3. Testing Authentication${NC}"
echo "Getting JWT token..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "ChangeMe123!"
  }')

if echo "$AUTH_RESPONSE" | grep -q "token"; then
    echo -e "✅ ${GREEN}Authentication: SUCCESS${NC}"
    echo "Raw response:"
    echo "$AUTH_RESPONSE" | head -c 200
    echo "..."

    JWT_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
    if [ -n "$JWT_TOKEN" ]; then
        echo ""
        echo -e "${BLUE}4. Testing Deals API${NC}"
        echo "Using JWT token: ${JWT_TOKEN:0:30}..."

        echo ""
        echo "Testing GET /api/deals..."
        DEALS_RESPONSE=$(curl -s "$API_URL/api/deals" \
          -H "Authorization: Bearer $JWT_TOKEN" \
          -H "Content-Type: application/json")

        if [ -z "$DEALS_RESPONSE" ]; then
            echo -e "❌ ${RED}Deals API: EMPTY RESPONSE (500 error likely)${NC}"
            echo ""
            echo -e "${YELLOW}⚠️  POTENTIAL ISSUES:${NC}"
            echo "1. Database 'hldeals' not created in RDS"
            echo "2. EF Core migrations not run in production"
            echo "3. Database connection issues in ECS containers"
            echo "4. Security group/network ACL blocking connections"
            echo ""
            echo -e "${BLUE}RECOMMENDED FIXES:${NC}"
            echo "1. Run: docker run --rm -v \$(pwd)/create-deals-migration.sql:/create-deals-migration.sql mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com,1433 -U hladmin -P StrongP4ssw0rd123! -i /create-deals-migration.sql -C"
            echo "2. Redeploy ECS service: ./build-push-local.sh"
            echo "3. Check CloudWatch logs for detailed error messages"
        elif echo "$DEALS_RESPONSE" | grep -q "error\|Error"; then
            echo -e "❌ ${RED}Deals API: ERROR RESPONSE${NC}"
            echo "Response: $DEALS_RESPONSE"
        elif [ "$DEALS_RESPONSE" = "[]" ]; then
            echo -e "✅ ${GREEN}Deals API: SUCCESS (Empty array as expected)${NC}"
        else
            echo -e "✅ ${GREEN}Deals API: SUCCESS${NC}"
            echo "Response: $DEALS_RESPONSE"
        fi

        echo ""
        echo -e "${BLUE}5. Testing CRUD Operations${NC}"
        echo "Creating a test deal..."

        CREATE_RESPONSE=$(curl -s -X POST "$API_URL/api/deals" \
          -H "Authorization: Bearer $JWT_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Test Deal from Prod Test",
            "client": "Test Client",
            "amount": 1000.00
          }')

        if [ -z "$CREATE_RESPONSE" ]; then
            echo -e "❌ ${RED}Create deal: FAILED${NC}"
        elif echo "$CREATE_RESPONSE" | grep -q "id\|Id"; then
            echo -e "✅ ${GREEN}Create deal: SUCCESS${NC}"
            echo "Created deal: $(echo "$CREATE_RESPONSE" | jq '.name' 2>/dev/null || echo "$CREATE_RESPONSE")"
        else
            echo -e "❌ ${RED}Create deal: ERROR${NC}"
            echo "Response: $CREATE_RESPONSE"
        fi

    else
        echo -e "❌ ${RED}JWT token extraction: FAILED${NC}"
    fi
else
    echo -e "❌ ${RED}Authentication: FAILED${NC}"
    echo "Response: $AUTH_RESPONSE"
fi

echo ""
echo -e "${BLUE}PRODUCTION TEST SUMMARY${NC}"
echo "==============================="
echo "✅ Run this script anytime with: ./test-production.sh"
echo "🔍 Check CloudWatch logs: /aws/ecs/hl-api"
echo "🗄️ Database: hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com"
echo ""
echo -e "${YELLOW}If still failing, check ECS container logs and RDS security groups${NC}"
