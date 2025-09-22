#!/bin/bash
echo "🔍 TESTING NEW DATABASECONTROLLER ENDPOINTS IN PRODUCTION"
echo "======================================================="

# Get JWT token
echo "🔑 Getting JWT Token..."
TOKEN=$(curl -s "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "ChangeMe123!"}' \
  | jq -r '.token')

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get JWT token"
  exit 1
fi

echo "✅ JWT Token obtained: $(echo $TOKEN | cut -c1-30)..."

# Test Database Status endpoint
echo ""
echo "📊 TESTING DATABASE STATUS ENDPOINT"
STATUS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/status" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

if echo "$STATUS_RESPONSE" | grep -q "HTTP_STATUS:200"; then
  echo "✅ Database Status available!"
else
  echo "❌ Database Status endpoint not found or not working"
  echo "Response: $STATUS_RESPONSE"
fi

# Test Database Initialize endpoint
echo ""
echo "🛠 TESTING DATABASE INITIALIZE ENDPOINT"
INIT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  "http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com/api/database/initialize" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

if echo "$INIT_RESPONSE" | grep -q "HTTP_STATUS:200"; then
  echo "✅ Database Initialize available!"
else
  echo "❌ Database Initialize endpoint not found or not working"
  echo "Response: $INIT_RESPONSE"
fi

echo ""
echo "🎯 SUMMARY:"
echo "Database Status endpoint: $(if echo "$STATUS_RESPONSE" | grep -q "HTTP_STATUS:200"; then echo "✅ WORKING"; else echo "❌ NOT FOUND"; fi)"
echo "Database Initialize endpoint: $(if echo "$INIT_RESPONSE" | grep -q "HTTP_STATUS:200"; then echo "✅ WORKING"; else echo "❌ NOT FOUND"; fi)"

if echo "$STATUS_RESPONSE" | grep -q "HTTP_STATUS:200" && echo "$INIT_RESPONSE" | grep -q "HTTP_STATUS:200"; then
  echo ""
  echo "🎉 SUCCESS: DatabaseController endpoints are AVAILABLE and WORKING!"
else
  echo ""
  echo "⚠️ DatabaseController endpoints are NOT yet available in production"
fi
