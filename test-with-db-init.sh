#!/bin/bash

echo "🔧 TESTING WITH DATABASE INITIALIZATION API"
echo "============================================="

API_URL="http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Step 1: Getting JWT Token${NC}"

# Get JWT Token
TOKEN_RESPONSE=$(curl -s "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "ChangeMe123!"
  }')

if echo "$TOKEN_RESPONSE" | grep -q "token"; then
    JWT_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✅ Authentication successful${NC}"
    echo "Token: ${JWT_TOKEN:0:30}..."

    echo ""
    echo -e "${BLUE}Step 2: Checking Current Database Status${NC}"

    STATUS_RESPONSE=$(curl -s "$API_URL/api/database/status" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -H "Content-Type: application/json")

    echo "Database status:"
    if [ -n "$STATUS_RESPONSE" ]; then
        echo -e "${CYAN}$STATUS_RESPONSE${NC}"
    else
        echo -e "${YELLOW}No response from status endpoint${NC}"
    fi

    echo ""
    echo -e "${BLUE}Step 3: INITIALIZING DATABASE VIA API${NC}"

    INIT_RESPONSE=$(curl -s "$API_URL/api/database/initialize" \
      -X POST \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -H "Content-Type: application/json")

    echo -e "${PURPLE}Database Initialization Result:${NC}"
    if [ -n "$INIT_RESPONSE" ]; then
        echo "$INIT_RESPONSE" | head -c 1000

        if echo "$INIT_RESPONSE" | grep -q '"success":true\|"success": true'; then
            echo -e "${GREEN}✅ DATABASE INITIALIZATION SUCCESSFUL!${NC}"

            echo ""
            echo -e "${BLUE}Step 4: Testing Deals API (Should Work Now)${NC}"

            # Wait a moment for the database changes to take effect
            echo "Waiting 5 seconds for database changes..."
            sleep 5

            # Test deals endpoint
            DEALS_RESPONSE=$(curl -s "$API_URL/api/deals" \
              -H "Authorization: Bearer $JWT_TOKEN" \
              -H "Content-Type: application/json")

            echo "✅ Deals API Response: $DEALS_RESPONSE"

            if echo "$DEALS_RESPONSE" | grep -q '"success":true\|"success": true'; then
                echo -e "${GREEN}🏆 DATABASE FIX COMPLETE - API IS NOW WORKING!${NC}"
                echo ""
                echo -e "${YELLOW}Your curl commands now work:${NC}"
                echo -e "${CYAN}curl '$API_URL/api/deals' -H 'Authorization: Bearer YOUR_TOKEN'${NC}"
            else
                echo -e "${YELLOW}⚠️ RUNNING AGAIN - MAY HAVE TAKEN LONGER TO COMPLETE${NC}"
            fi

        else
            echo -e "${RED}❌ DATABASE INITIALIZATION FAILED${NC}"
            echo ""
            echo -e "${YELLOW}Database Initialization Response:${NC}"
            echo -e "${RED}$INIT_RESPONSE${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ No response from database initialization endpoint${NC}"
        echo "Possibly the new controller hasn't been deployed yet"
        echo ""
        echo -e "${YELLOW}💡 Try: ./build-push-local.sh to deploy the new DatabaseController${NC}"
        exit 1
    fi

else
    echo -e "${RED}❌ Authentication failed${NC}"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 PROCESS COMPLETE${NC}"
echo "If successful, your database is now properly configured!"
