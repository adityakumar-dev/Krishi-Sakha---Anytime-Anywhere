#!/bin/bash

# Test script for /chat/agri endpoint
# Make sure the FastAPI server is running on localhost:8000

BASE_URL="http://localhost:8000"
ENDPOINT="/chat/agri"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Testing /chat/agri endpoint${NC}"
echo -e "${BLUE}================================${NC}\n"

# Generate a mock JWT token (replace with real token from your auth system)
# For testing, you need to get a real JWT token from your authentication
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsImtpZCI6Ik4wcVFEejJEOXdEMVhrakIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2JpdmFuanlndXh2amN0Y3NjbmptLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI0OTU5OWNlMy1hNzA1LTQ3YjgtYTc1MS02ZGY0ODAxNzE5MTAiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzY1MjA4NTU4LCJpYXQiOjE3NjUxNzI1NTgsImVtYWlsIjoiaGVsbG9AZ21haWwuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6eyJlbWFpbCI6ImhlbGxvQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInN1YiI6IjQ5NTk5Y2UzLWE3MDUtNDdiOC1hNzUxLTZkZjQ4MDE3MTkxMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzY0ODY3NDgwfV0sInNlc3Npb25faWQiOiJjMDA4M2UzZi00ZjY1LTRkYWQtOWRhZi01ZTQyNWUxZTQzNTAiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.DAsat3P6xC7GxZTt_CyRhs18bWh4BA8tDuzs5afy6rM"

echo -e "${YELLOW}Note: Replace JWT_TOKEN with a real token from your auth system${NC}\n"

# Test 1: Simple agricultural query
echo -e "${GREEN}Test 1: Simple agricultural query${NC}"
echo "Query: 'How to control pests in banana plants?'"
echo ""

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=How to control pests in banana plants?" \
  -F "conversation_id=test-conv-001" \
  -F "history=[]"

echo -e "\n\n"

# Test 2: Query with state preference
echo -e "${GREEN}Test 2: Query with state preference (Kerala)${NC}"
echo "Query: 'What's the weather today?'"
echo "State: Kerala"
echo ""

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What's the weather today?" \
  -F "conversation_id=26" \
  -F "state=Kerala" \
  -F "history=[]"

echo -e "\n\n"

# Test 3: Query with station_id preference
echo -e "${GREEN}Test 3: Query with station_id preference (Dehradun)${NC}"
echo "Query: 'Tell me the weather forecast'"
echo "Station ID: 99952"
echo ""

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=Tell me the weather forecast" \
  -F "conversation_id=test-conv-003" \
  -F "station_id=99952" \
  -F "history=[]"

echo -e "\n\n"

# Test 4: Price query with state
echo -e "${GREEN}Test 4: Price query with state preference${NC}"
echo "Query: 'What is the price of banana today?'"
echo "State: Tamil Nadu"
echo ""

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What is the price of banana today?" \
  -F "conversation_id=test-conv-004" \
  -F "state=Tamil Nadu" \
  -F "history=[]"

echo -e "\n\n"

# Test 5: Follow-up query with conversation history
echo -e "${GREEN}Test 5: Follow-up query with conversation history${NC}"
echo "Query: 'What about fertilizer?'"
echo "History: Previous discussion about rice cultivation"
echo ""

HISTORY='[{"sender":"user","message":"How to grow rice?"},{"sender":"assistant","message":"Rice cultivation requires proper water management. The field should be flooded to 5-10 cm depth during transplanting."}]'

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What about fertilizer?" \
  -F "conversation_id=test-conv-005" \
  -F "history=${HISTORY}" \
  -F "state=Kerala"

echo -e "\n\n"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Tests completed${NC}"
echo -e "${BLUE}================================${NC}"
