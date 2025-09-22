#!/bin/bash

# Debug script for the deals endpoint issue
echo "🔍 Debugging Deals Endpoint Issue"
echo "==================================="

API_URL="http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com"

echo "1. Testing health endpoint..."
curl -s "$API_URL/healthz" && echo " ✅ Health OK" || echo " ❌ Health FAILED"

echo ""
echo "2. Testing authentication..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "ChangeMe123!"}')

echo "$AUTH_RESPONSE" | jq . 2>/dev/null || echo "$AUTH_RESPONSE"

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
    echo "✅ JWT Token obtained"
    echo "Token: ${TOKEN:0:50}..."
    echo ""
    echo "3. Testing deals endpoint (with token)..."
    echo "Command: curl -v -X GET $API_URL/api/deals with Authorization Bearer"
    echo "Response:"

    # Test with verbose output to see exact error
    RESPONSE=$(curl -v -X GET "$API_URL/api/deals" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      --connect-timeout 10 \
      --max-time 30 \
      2>&1)

    echo "---------- RESPONSE ----------"
    echo "$RESPONSE"

    # Extract HTTP status if possible
    STATUS_CODE=$(echo "$RESPONSE" | grep "< HTTP/.* " | head -1 | sed 's/.*< HTTP\/[^ ]* \([0-9]*\).*/\1/')

    if [ -n "$STATUS_CODE" ]; then
        echo "---------- STATUS CODE ----------"
        echo "HTTP Status: $STATUS_CODE"
        if [ "$STATUS_CODE" = "200" ]; then
            echo "✅ SUCCESS: Deals endpoint works!"
        elif [ "$STATUS_CODE" = "500" ]; then
            echo "❌ ERROR: Internal server error (likely database issue)"
        elif [ "$STATUS_CODE" = "401" ]; then
            echo "❌ ERROR: Unauthorized (token issue)"
        else
            echo "❌ ERROR: HTTP $STATUS_CODE"
        fi
    else
        echo "❌ ERROR: Could not determine HTTP status"
    fi
else
    echo "❌ ERROR: Could not obtain JWT token"
fi

echo ""
echo "4. Testing deals endpoint without authentication (should fail)..."
curl -X GET "$API_URL/api/deals" -H "Content-Type: application/json" --connect-timeout 5 2>&1 | head -5
