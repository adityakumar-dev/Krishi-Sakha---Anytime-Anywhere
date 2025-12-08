#!/bin/bash

# Test script for weather station finder endpoint
# Usage: ./test_weather_station.sh

BASE_URL="http://localhost:8000"
ENDPOINT="/weather/find-station"

echo "=========================================="
echo "Testing Weather Station Finder API"
echo "=========================================="
echo ""

# Test 1: Kerala - Trivandrum coordinates
echo "Test 1: Finding station near Trivandrum, Kerala"
echo "Location: (8.5241, 76.9366)"
echo "Expected: Should find Alappuzha station"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "state_name": "Kerala",
    "latitude": 8.5241,
    "longitude": 76.9366,
    "max_distance_km": 150
  }' | jq '.'
echo ""
echo ""

# Test 2: Tamil Nadu - Chennai coordinates
echo "Test 2: Finding station near Chennai, Tamil Nadu"
echo "Location: (13.0827, 80.2707)"
echo "Expected: Should find Chennai/MEENAMBAKKAM station"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "state_name": "Tamil Nadu",
    "latitude": 13.0827,
    "longitude": 80.2707,
    "max_distance_km": 100
  }' | jq '.'
echo ""
echo ""

# Test 3: Uttarakhand - Dehradun coordinates
echo "Test 3: Finding station near Dehradun, Uttarakhand"
echo "Location: (30.3165, 78.0322)"
echo "Expected: Should find Dehradun station"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "state_name": "Uttarakhand",
    "latitude": 30.3165,
    "longitude": 78.0322,
    "max_distance_km": 50
  }' | jq '.'
echo ""
echo ""

# Test 4: Invalid state name
echo "Test 4: Invalid state name (should fail)"
echo "State: XYZ (non-existent)"
echo "Expected: Error 404"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "state_name": "XYZ",
    "latitude": 28.7041,
    "longitude": 77.1025,
    "max_distance_km": 100
  }' | jq '.'
echo ""
echo ""

# Test 5: Get all stations in Kerala
echo "Test 5: Get all stations in Kerala"
echo "Expected: List of 21 stations"
echo "------------------------------------------"
curl -X GET "${BASE_URL}/weather/stations/Kerala" | jq '.'
echo ""
echo ""

# Test 6: Tight distance constraint (should find within range or not)
echo "Test 6: Very strict distance (10 km) near Kozhikode"
echo "Location: (11.2588, 75.7804)"
echo "Expected: May or may not find station within 10km"
echo "------------------------------------------"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "state_name": "Kerala",
    "latitude": 11.2588,
    "longitude": 75.7804,
    "max_distance_km": 10
  }' | jq '.'
echo ""
echo ""

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
