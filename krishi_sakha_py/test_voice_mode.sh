#!/bin/bash

# Test voice mode with chat_agri endpoint
# Usage: ./test_voice_mode.sh

BASE_URL="http://localhost:8000"
ENDPOINT="/chat/agri"

# You'll need a valid JWT token - replace this
JWT_TOKEN="your_jwt_token_here"

echo "=========================================="
echo "Testing Voice Mode (TTS-Optimized)"
echo "=========================================="
echo ""

# Test 1: Regular text mode (verbose response)
echo "Test 1: Regular Text Mode (is_voice=false)"
echo "Query: What is the weather forecast for tomorrow?"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What is the weather forecast for tomorrow?" \
  -F "conversation_id=test_voice_$(date +%s)" \
  -F "state=Kerala" \
  -F "is_voice=false"
echo ""
echo ""

# Test 2: Voice mode (concise TTS-friendly response)
echo "Test 2: Voice Mode (is_voice=true)"
echo "Query: What is the weather forecast for tomorrow?"
echo "Expected: Short 50-100 word response, no special characters"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What is the weather forecast for tomorrow?" \
  -F "conversation_id=test_voice_$(date +%s)" \
  -F "state=Kerala" \
  -F "is_voice=true"
echo ""
echo ""

# Test 3: Voice mode with price query
echo "Test 3: Voice Mode - Price Query"
echo "Query: What is the price of coconut today?"
echo "Expected: Direct price info in 50-100 words"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What is the price of coconut today?" \
  -F "conversation_id=test_voice_$(date +%s)" \
  -F "state=Kerala" \
  -F "is_voice=true"
echo ""
echo ""

# Test 4: Voice mode with farming question
echo "Test 4: Voice Mode - Farming Question"
echo "Query: How to control pests in rice?"
echo "Expected: Brief actionable advice in 50-100 words"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=How to control pests in rice?" \
  -F "conversation_id=test_voice_$(date +%s)" \
  -F "state=Kerala" \
  -F "is_voice=true"
echo ""
echo ""

echo "=========================================="
echo "Voice Mode Testing Complete!"
echo "=========================================="
echo ""
echo "Note: Voice mode responses should be:"
echo "  - 50-100 words maximum"
echo "  - No special characters or emojis"
echo "  - Simple, conversational language"
echo "  - Numbers written as words"
echo "  - TTS-friendly formatting"
