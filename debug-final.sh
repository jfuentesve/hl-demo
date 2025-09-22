#!/bin/bash

echo "=== FINAL API DEBUG SCRIPT ==="
echo "==============================="

API_URL="http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com"

echo ""
echo "🔍 CHECKING ECS SERVICE STATUS:"
aws ecs describe-services --cluster hl-ecs-cluster --services hl-api-service --query 'services[0].{status:status,runningCount:runningCount,lastDeploymentAt:lastDeploymentAt}' --output json

echo ""
echo "🔍 TESTING HEALTH ENDPOINT:"
curl -s "$API_URL/healthz" && echo " ✅ Health OK" || echo " ❌ Health FAILED"

echo ""
echo "🔍 TESTING AUTHENTICATION & DEAL ENDPOINT:"

# Test authentication
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "ChangeMe123!"}')

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo "✅ Authentication: SUCCESS"
    echo "📝 Token obtained: ${TOKEN:0:50}..."

    echo ""
    echo "🔍 TESTING DEALS ENDPOINT:"
    # Test deals endpoint
    echo "Testing GET /api/deals..."
    RESPONSE=$(curl -s "$API_URL/api/deals" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -m 10)

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep "error\|Error" > /dev/null 2>&1; then
        echo "❌ Deals API: ERROR in response"
    elif [ -z "$RESPONSE" ]; then
        echo "❌ Deals API: EMPTY response (still failing)"
    else
        echo "✅ Deals API: SUCCESS!"
    fi
else
    echo "❌ Authentication: FAILED"
fi

echo ""
echo "📊 SUMMARY:"
echo "=========="
echo "This script will tell us the exact current status."
echo "If deals API returns EMPTY response: Database issue persists"
echo "If deals API returns error message: Specific error details"
echo "If deals API returns empty array: SUCCESS!"
