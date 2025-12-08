# cURL Commands for Testing /chat/agri Endpoint

## Prerequisites
1. FastAPI server running on `localhost:8000`
2. Valid JWT token from authentication

## Get JWT Token First
Replace `YOUR_JWT_TOKEN` with actual token from your auth system.

---

## Test 1: Simple Agricultural Query
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=How to control pests in banana plants?" \
  -F "conversation_id=test-conv-001" \
  -F "history=[]"
```

**Expected Response:**
- Status updates: "Processing query...", "Analyzing query...", "Searching knowledge base..."
- Text chunks streaming the answer
- Complete signal at end

---

## Test 2: Weather Query with State Preference
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=What's the weather today?" \
  -F "conversation_id=test-conv-002" \
  -F "state=Kerala" \
  -F "history=[]"
```

**Expected Response:**
- Status: "Fetching weather forecast..."
- Weather data for Kerala (auto-selects first station)
- 6-day forecast with temperatures

---

## Test 3: Weather Query with Station ID
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=Tell me the weather forecast" \
  -F "conversation_id=test-conv-003" \
  -F "station_id=99952" \
  -F "history=[]"
```

**Expected Response:**
- Weather for Dehradun-Jhajhara (station 99952)
- 6-day forecast

---

## Test 4: Price Query with State
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=What is the price of banana today?" \
  -F "conversation_id=test-conv-004" \
  -F "state=Tamil Nadu" \
  -F "history=[]"
```

**Expected Response:**
- Status: "Fetching mandi prices..."
- Date fallback attempts (if today's data not available)
- Price data for Tamil Nadu

---

## Test 5: Follow-up Query with Conversation History
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=What about fertilizer?" \
  -F "conversation_id=test-conv-005" \
  -F 'history=[{"sender":"user","message":"How to grow rice?"},{"sender":"assistant","message":"Rice cultivation requires proper water management. The field should be flooded to 5-10 cm depth during transplanting."}]' \
  -F "state=Kerala"
```

**Expected Response:**
- Query processor understands "fertilizer" is for rice (from context)
- Relevant fertilizer recommendations for rice

---

## Test 6: General Query (Should Skip YouTube)
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=Hello, how are you?" \
  -F "conversation_id=test-conv-006" \
  -F "history=[]"
```

**Expected Response:**
- No YouTube videos fetched (is_general=true)
- Shorter processing time

---

## Test 7: Complete Pipeline Query
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=How to grow tomatoes? What's the weather? What's the price?" \
  -F "conversation_id=test-conv-007" \
  -F "state=Kerala" \
  -F "history=[]"
```

**Expected Response:**
- Multiple status updates (knowledge base, weather, prices, web search, videos)
- Comprehensive response with all context sources
- URLs and YouTube videos at the end

---

## Test 8: With Image Upload
```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "prompt=What disease is this?" \
  -F "conversation_id=test-conv-008" \
  -F "image=@/path/to/your/plant_image.jpg" \
  -F "history=[]"
```

**Expected Response:**
- Image processing status
- Vision model analysis
- Disease identification and treatment recommendations

---

## Response Format

All responses stream as Server-Sent Events (SSE):

```
data: {"type": "status", "message": "Processing query..."}

data: {"type": "status", "message": "Analyzing query..."}

data: {"type": "status", "message": "Searching knowledge base..."}

data: {"type": "status", "message": "Generating response..."}

data: {"type": "text", "chunk": "For banana"}

data: {"type": "text", "chunk": " pest control,"}

data: {"type": "text", "chunk": " use neem oil spray..."}

data: {"type": "urls", "urls": ["https://example.com/article1", "https://example.com/article2"]}

data: {"type": "youtube", "results": [{"title": "Banana Pest Control", "url": "https://youtube.com/...", ...}]}

data: {"type": "complete"}
```

---

## Quick Test (No Auth for Development)

If you want to test without authentication (disable middleware temporarily):

```bash
curl -N -X POST "http://localhost:8000/chat/agri" \
  -H "Content-Type: multipart/form-data" \
  -F "prompt=What is organic farming?" \
  -F "conversation_id=dev-test-001" \
  -F "state=Kerala" \
  -F "history=[]"
```

---

## Tips

1. **Use `-N` flag**: Disables buffering for streaming responses
2. **Save to file**: Add `> response.txt` to save output
3. **Pretty print**: Pipe through `jq` for JSON formatting (won't work for SSE)
4. **Watch real-time**: Just run the command as-is to see streaming

---

## Troubleshooting

**401 Unauthorized**: JWT token invalid or expired
**422 Unprocessable Entity**: Missing required fields
**500 Internal Server Error**: Check server logs for details

**No streaming**: Remove `-N` flag or check if server is running
