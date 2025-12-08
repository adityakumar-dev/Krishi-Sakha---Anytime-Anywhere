#!/bin/bash

# Test script for /chat/agri endpoint with output collection
# Saves complete response to a file for analysis

BASE_URL="http://localhost:8000"
ENDPOINT="/chat/agri"
OUTPUT_DIR="./test_results"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# JWT Token
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsImtpZCI6Ik4wcVFEejJEOXdEMVhrakIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2JpdmFuanlndXh2amN0Y3NjbmptLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI0OTU5OWNlMy1hNzA1LTQ3YjgtYTc1MS02ZGY0ODAxNzE5MTAiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzY1MjA4NTU4LCJpYXQiOjE3NjUxNzI1NTgsImVtYWlsIjoiaGVsbG9AZ21haWwuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6eyJlbWFpbCI6ImhlbGxvQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInN1YiI6IjQ5NTk5Y2UzLWE3MDUtNDdiOC1hNzUxLTZkZjQ4MDE3MTkxMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzY0ODY3NDgwfV0sInNlc3Npb25faWQiOiJjMDA4M2UzZi00ZjY1LTRkYWQtOWRhZi01ZTQyNWUxZTQzNTAiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.DAsat3P6xC7GxZTt_CyRhs18bWh4BA8tDuzs5afy6rM"

# Function to run test and save output
run_test() {
    local test_num=$1
    local test_name=$2
    local prompt=$3
    local conversation_id=$4
    local extra_params=$5
    local output_file="${OUTPUT_DIR}/test_${test_num}_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Test ${test_num}: ${test_name}${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Query:${NC} ${prompt}"
    echo -e "${BLUE}Output:${NC} ${output_file}"
    echo ""
    
    # Run curl and save to file while showing progress
    curl -N -X POST "${BASE_URL}${ENDPOINT}" \
      -H "Content-Type: multipart/form-data" \
      -H "Authorization: Bearer ${JWT_TOKEN}" \
      -F "prompt=${prompt}" \
      -F "conversation_id=${conversation_id}" \
      -F "history=[]" \
      ${extra_params} \
      2>&1 | tee "$output_file"
    
    echo ""
    echo -e "${YELLOW}Response saved to: ${output_file}${NC}"
    echo ""
    
    # Extract and display summary
    echo -e "${BLUE}Response Summary:${NC}"
    echo -e "${BLUE}────────────────${NC}"
    
    # Count status updates
    local status_count=$(grep -c '"type": "status"' "$output_file" 2>/dev/null || echo "0")
    echo -e "  Status updates: ${status_count}"
    
    # Count text chunks
    local text_count=$(grep -c '"type": "text"' "$output_file" 2>/dev/null || echo "0")
    echo -e "  Text chunks: ${text_count}"
    
    # Check for URLs
    if grep -q '"type": "urls"' "$output_file" 2>/dev/null; then
        echo -e "  URLs: ${GREEN}✓ Present${NC}"
    else
        echo -e "  URLs: ${RED}✗ None${NC}"
    fi
    
    # Check for YouTube
    if grep -q '"type": "youtube"' "$output_file" 2>/dev/null; then
        echo -e "  YouTube: ${GREEN}✓ Present${NC}"
    else
        echo -e "  YouTube: ${RED}✗ None${NC}"
    fi
    
    # Check completion
    if grep -q '"type": "complete"' "$output_file" 2>/dev/null; then
        echo -e "  Status: ${GREEN}✓ Completed${NC}"
    else
        echo -e "  Status: ${RED}✗ Incomplete${NC}"
    fi
    
    # Extract full response text
    echo ""
    echo -e "${BLUE}Full Response Text:${NC}"
    echo -e "${BLUE}──────────────────${NC}"
    grep '"type": "text"' "$output_file" | sed 's/.*"chunk": "\(.*\)".*/\1/' | tr -d '\n' | sed 's/\\n/ /g'
    echo ""
    echo ""
    
    sleep 2
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Testing /chat/agri Endpoint (Collected)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Simple agricultural query
run_test "1" \
    "Simple agricultural query" \
    "How to control pests in banana plants?" \
    "test-conv-001"

# Test 2: Weather query with state
run_test "2" \
    "Weather query with state preference" \
    "What's the weather today?" \
    "test-conv-002" \
    '-F "state=Kerala"'

# Test 3: Weather with station ID
run_test "3" \
    "Weather with station ID (Dehradun)" \
    "Tell me the weather forecast" \
    "test-conv-003" \
    '-F "station_id=99952"'

# Test 4: Price query
run_test "4" \
    "Price query with state" \
    "What is the price of banana today?" \
    "test-conv-004" \
    '-F "state=Tamil Nadu"'

# Test 5: Follow-up with context
HISTORY='[{"sender":"user","message":"How to grow rice?"},{"sender":"assistant","message":"Rice cultivation requires proper water management. The field should be flooded to 5-10 cm depth during transplanting."}]'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Test 5: Follow-up query with conversation history${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Query:${NC} What about fertilizer?"
echo -e "${BLUE}History:${NC} Previous rice cultivation discussion"
echo ""

output_file="${OUTPUT_DIR}/test_5_$(date +%Y%m%d_%H%M%S).txt"

curl -N -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -F "prompt=What about fertilizer?" \
  -F "conversation_id=test-conv-005" \
  -F "history=${HISTORY}" \
  -F "state=Kerala" \
  2>&1 | tee "$output_file"

echo ""
echo -e "${YELLOW}Response saved to: ${output_file}${NC}"
echo ""

# Final summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Test Summary                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}All test results saved to: ${OUTPUT_DIR}/${NC}"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo -e "${YELLOW}Tip: View any file with: cat ${OUTPUT_DIR}/test_N_*.txt${NC}"
echo ""
