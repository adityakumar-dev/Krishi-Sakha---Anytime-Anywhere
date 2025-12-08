#!/usr/bin/env python3
"""
Test script to verify user preferences (state and station_id) are correctly prioritized by Gemini
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from brain.pipeline import process_farmer_query
import json

def print_test_header(test_num: int, description: str):
    print("\n" + "="*80)
    print(f"TEST {test_num}: {description}")
    print("="*80)

def print_result(result: dict):
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print()

# Test 1: Query with user preferred state (should override detected state)
print_test_header(1, "User Preferred State Override")
print("Query: 'What is the weather in Kerala?' with user_preferred_state='Tamil Nadu'")
print("Expected: state_name should be 'Tamil Nadu' (user preference wins)")
print("-"*80)

result = process_farmer_query(
    query="What is the weather in Kerala?",
    user_preferred_state="Tamil Nadu"
)
print_result(result)
assert result.get('state_name') == 'Tamil Nadu', f"❌ Expected Tamil Nadu but got {result.get('state_name')}"
print("✅ PASSED: User preferred state correctly prioritized over query mention")

# Test 2: Query with user preferred station_id
print_test_header(2, "User Preferred Station ID")
print("Query: 'Weather forecast for tomorrow' with user_preferred_station_id='101669'")
print("Expected: station_id='101669' should be included in response")
print("-"*80)

result = process_farmer_query(
    query="Weather forecast for tomorrow",
    user_preferred_station_id="101669"
)
print_result(result)
assert result.get('station_id') == '101669', f"❌ Expected station_id 101669 but got {result.get('station_id')}"
print("✅ PASSED: User preferred station_id correctly included")

# Test 3: Both state and station_id preferences
print_test_header(3, "Both State and Station ID Preferences")
print("Query: 'Will it rain?' with state='Uttarakhand' and station_id='42867'")
print("Expected: Both should be in response")
print("-"*80)

result = process_farmer_query(
    query="Will it rain?",
    user_preferred_state="Uttarakhand",
    user_preferred_station_id="42867"
)
print_result(result)
assert result.get('state_name') == 'Uttarakhand', f"❌ Expected Uttarakhand but got {result.get('state_name')}"
assert result.get('station_id') == '42867', f"❌ Expected station_id 42867 but got {result.get('station_id')}"
print("✅ PASSED: Both state and station_id correctly returned")

# Test 4: No user preferences (should use detected or default)
print_test_header(4, "No User Preferences - Default Behavior")
print("Query: 'Weather in Maharashtra' with NO user preferences")
print("Expected: Should detect 'Maharashtra' from query or default to 'Kerala'")
print("-"*80)

result = process_farmer_query(query="Weather in Maharashtra")
print_result(result)
state = result.get('state_name')
print(f"Detected/Default state: {state}")
assert state in ['Maharashtra', 'Kerala'], f"❌ Expected Maharashtra or Kerala but got {state}"
print("✅ PASSED: Query processed without user preferences")

# Test 5: User preference with conversation context
print_test_header(5, "User Preferences with Conversation Context")
print("Last Response: 'Rice cultivation requires proper water management...'")
print("Query: 'What about fertilizer?' with state='Punjab' and station_id='42101'")
print("Expected: Should understand 'rice fertilizer' AND use Punjab preferences")
print("-"*80)

result = process_farmer_query(
    query="What about fertilizer?",
    last_response="Rice cultivation requires proper water management and proper drainage system.",
    user_preferred_state="Punjab",
    user_preferred_station_id="42101"
)
print_result(result)
assert result.get('state_name') == 'Punjab', f"❌ Expected Punjab but got {result.get('state_name')}"
assert result.get('station_id') == '42101', f"❌ Expected station_id 42101 but got {result.get('station_id')}"
print("✅ PASSED: User preferences work with conversation context")

# Test 6: Conflicting state in query vs user preference
print_test_header(6, "Conflicting State - Query vs User Preference")
print("Query: 'Kerala coconut prices' with user_preferred_state='Karnataka'")
print("Expected: state_name should be 'Karnataka' (user preference ALWAYS wins)")
print("-"*80)

result = process_farmer_query(
    query="Kerala coconut prices",
    user_preferred_state="Karnataka"
)
print_result(result)
assert result.get('state_name') == 'Karnataka', f"❌ Expected Karnataka but got {result.get('state_name')}"
print("✅ PASSED: User preference correctly overrides query-mentioned state")

# Test 7: Weather query with all preferences
print_test_header(7, "Weather Query with Complete Preferences")
print("Query: 'What is the temperature today?' with state='Tamil Nadu' and station_id='101669'")
print("Expected: actions should include 'imd', state='Tamil Nadu', station_id='101669'")
print("-"*80)

result = process_farmer_query(
    query="What is the temperature today?",
    user_preferred_state="Tamil Nadu",
    user_preferred_station_id="101669"
)
print_result(result)
assert 'imd' in result.get('actions', []), f"❌ Expected 'imd' in actions but got {result.get('actions')}"
assert result.get('state_name') == 'Tamil Nadu', f"❌ Expected Tamil Nadu but got {result.get('state_name')}"
assert result.get('station_id') == '101669', f"❌ Expected station_id 101669 but got {result.get('station_id')}"
print("✅ PASSED: Weather query with complete user preferences")

print("\n" + "="*80)
print("🎉 ALL TESTS PASSED!")
print("="*80)
print("\nSummary:")
print("✅ User preferred state correctly overrides detected state")
print("✅ User preferred station_id correctly included when provided")
print("✅ Both preferences work together")
print("✅ System works without user preferences (default behavior)")
print("✅ User preferences work with conversation context")
print("✅ User preferences take absolute priority over query mentions")
print("✅ Weather queries correctly use all user preferences")
