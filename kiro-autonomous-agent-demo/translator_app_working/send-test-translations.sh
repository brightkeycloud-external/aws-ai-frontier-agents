#!/bin/bash
# Send test translations to verify the API is working
set -euo pipefail

API_URL=$(terraform output -raw api_url)

PHRASES=(
  "Hello, how are you doing today?"
  "The quick brown fox jumps over the lazy dog."
  "I would like to order a large pizza with extra cheese."
  "The meeting has been rescheduled to next Tuesday."
  "Please send me the report by end of day."
)

echo "📤 Sending ${#PHRASES[@]} test translations..."
echo ""

for phrase in "${PHRASES[@]}"; do
  echo "Modern: $phrase"
  RESULT=$(curl -s -X POST "${API_URL}/translate" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"$phrase\"}")
  TRANSLATED=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('translated','ERROR'))" 2>/dev/null || echo "ERROR")
  echo "Olde:   $TRANSLATED"
  echo "---"
done

echo ""
echo "✅ Test translations complete."
echo ""
echo "📜 Checking history..."
curl -s "${API_URL}/history" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"  {len(data.get('translations', []))} translations in history\")
"
