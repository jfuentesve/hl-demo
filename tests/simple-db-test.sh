#!/bin/bash

echo "🔍 CHECKING DATABASECONTROLLER ENDPOINT AVAILABILITY"
echo "======================================================="
echo ""

# Check basic API connectivity
echo "1. Testing API connectivity..."
HEALTH_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/healthz")
echo "Health: $HEALTH_RESPONSE"
echo ""

if [[ $HEALTH_RESPONSE != *"HTTP_STATUS:200"* ]]; then
    echo "❌ API is not responding"
    exit 1
fi

# Get JWT token
echo "2. Getting JWT token..."
TOKEN=$(curl -s "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/auth/login" -H "Content-Type: application/json" -d '{"username": "admin", "password": "ChangeMe123!"}' | jq -r '.token')

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get JWT token"
    exit 1
fi

echo "✅ JWT Token obtained"
echo ""

# Test Database Status endpoint directly (no jq formatting)
echo "3. Testing /api/database/status endpoint (RAW RESPONSE):"
STATUS_RAW=$(curl -s -w "\nHTTP_CODE:%{http_code}" "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/status" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")
echo "$STATUS_RAW"
echo ""

# Test Database Initialize endpoint directly (no jq formatting)
echo "4. Testing /api/database/initialize endpoint (RAW RESPONSE):"
INIT_RAW=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/initialize" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")
echo "$INIT_RAW"
echo ""

echo "🎯 ANALYSIS:"
if [[ $STATUS_RAW == *"HTTP_CODE:200"* ]] || [[ $STATUS_RAW == *"HTTP_CODE:201"* ]]; then
    echo "✅ Database Status endpoint: AVAILABLE"
else
    echo "❌ Database Status endpoint: NOT FOUND or NOT WORKING"
fi

if [[ $INIT_RAW == *"HTTP_CODE:200"* ]] || [[ $INIT_RAW == *"HTTP_CODE:201"* ]]; then
    echo "✅ Database Initialize endpoint: AVAILABLE"
else
    echo "❌ Database Initialize endpoint: NOT FOUND or NOT WORKING"
fi

echo ""
echo "💡 Tip: If endpoints are not working, wait 2-3 minutes for the deployment to fully complete."
