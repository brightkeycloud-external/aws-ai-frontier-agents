#!/bin/bash
# Send test requests to the Notes API to verify it's working
set -euo pipefail

BASE_URL=$(terraform output -raw custom_domain_url)

echo "🔍 Testing Notes API at $BASE_URL"
echo ""

echo "1. Health check..."
curl -s "$BASE_URL/health" | jq .
echo ""

echo "2. Create a note..."
NOTE=$(curl -s -X POST "$BASE_URL/notes" \
  -H "Content-Type: application/json" \
  -d '{"userId": "user-1", "title": "Test Note", "content": "Hello from the demo"}')
echo "$NOTE" | jq .
NOTE_ID=$(echo "$NOTE" | jq -r '.noteId')
echo ""

echo "3. List notes for user-1..."
curl -s "$BASE_URL/notes?userId=user-1" | jq .
echo ""

echo "4. Get specific note..."
curl -s "$BASE_URL/notes/$NOTE_ID?userId=user-1" | jq .
echo ""

echo "5. IDOR test — access user-1's notes as user-2 (should work — this is a vuln)..."
curl -s "$BASE_URL/notes?userId=user-1" | jq .
echo ""

echo "6. SSRF test — fetch external URL..."
curl -s -X POST "$BASE_URL/fetch" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://httpbin.org/get"}' | jq .status
echo ""

echo "✅ All endpoints responding. API is ready for Security Agent testing."
