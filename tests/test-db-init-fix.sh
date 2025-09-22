#!/bin/bash

echo "🔧 TESTING DATABASE INITIALIZATION FIX"
echo "======================================="
echo ""

# Get JWT token
echo "🔑 Getting JWT Token..."
TOKEN=$(curl -s "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "ChangeMe123!"}' \
  | jq -r '.token')

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get JWT token"
    echo "   API may not be deployed yet or auth endpoint not working"
    exit 1
fi

echo "✅ JWT Token obtained"

echo ""
echo "📊 Testing Connection with Retry Logic..."
echo "   (This should now work with EnableRetryOnFailure enabled)"
echo ""

# Test Database Status first (should work immediately)
echo "1. Testing Database Status:"
STATUS_RESPONSE=$(curl -s -w "\nHTTP_CODE: %{http_code}" \
  "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/status" \
  -H "Authorization: Bearer $TOKEN")

if [[ $STATUS_RESPONSE == *"HTTP_CODE:200"* ]]; then
    echo "   ✅ Database Status: SUCCESSFUL"
else
    echo "   ❌ Database Status: FAILED"
    echo "Response: $STATUS_RESPONSE"
fi

echo ""

# Test Database Initialize with retry logic
echo "2. Testing Database Initialize (with retry logic):"
INIT_RESPONSE=$(curl -s -w "\nHTTP_CODE: %{http_code}" -X POST \
  "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/initialize" \
  -H "Authorization: Bearer $TOKEN")

if [[ $INIT_RESPONSE == *"HTTP_CODE:200"* ]]; then
    echo "   ✅ Database Initialize: SUCCESSFUL"
    echo "   📋 Tables should now be created!"
elif [[ $INIT_RESPONSE == *"HTTP_CODE:400"* ]]; then
    # Check if it's still the same connection error
    if [[ $INIT_RESPONSE == *"EnableRetryOnFailure"* ]]; then
        echo "   ❌ Retry logic not yet deployed"
        echo "   💡 Need to redeploy with EnableRetryOnFailure fix"
    else
        echo "   ⚠️  Different database error (not connection timeout)"
        echo "   📋 Checking response details..."
        echo "$INIT_RESPONSE" | jq '.message'
    fi
else
    echo "   ❌ Unexpected response"
    echo "Response: $INIT_RESPONSE"
fi

echo ""

# Test Deals endpoint to verify tables work
echo "3. Testing Deals Endpoint (after database initialization):"
DEALS_RESPONSE=$(curl -s -w "\nHTTP_CODE: %{http_code}" \
  "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/deals" \
  -H "Authorization: Bearer $TOKEN")

if [[ $DEALS_RESPONSE == *"HTTP_CODE:200"* ]]; then
    echo "   ✅ Deals endpoint working!"
elif [[ $DEALS_RESPONSE == *"HTTP_CODE:400"* ]]; then
    echo "   ⚠️  Deals endpoint responding (database may need initialization)"
else
    echo "   ❌ Deals endpoint not responding"
fi

echo ""
echo "🚀 NEXT STEPS:"
echo "   1. Run: ./build-push-local.sh to deploy the EnableRetryOnFailure fix"
echo "   2. Wait ~2 minutes for deployment"
echo "   3. Re-run this test: ./tests/test-db-init-fix.sh"
echo "   4. Database initialization should now work successfully!"
echo ""

if [[ $INIT_RESPONSE == *"HTTP_CODE:200"* ]]; then
    echo "🎉 SUCCESS: Database initialization is working!"
else
    echo "⚠️  Database initialization still has issues. Check deployment status."
fi
