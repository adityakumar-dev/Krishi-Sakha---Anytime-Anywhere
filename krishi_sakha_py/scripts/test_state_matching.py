#!/usr/bin/env python3
"""
Test state name normalization and date fallback features
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from brain.pipeline import (
    normalize_state_name_for_enam,
    get_imd_weather_context,
    get_enam_price_context,
    get_stations_by_state
)
import json

def test_state_normalization():
    """Test eNAM state name normalization"""
    print("\n" + "="*80)
    print("TEST 1: eNAM STATE NAME NORMALIZATION")
    print("="*80)
    
    test_cases = [
        "kerala",
        "KERALA",
        "Kerala",
        "tamil nadu",
        "TamilNadu",
        "Tamil",
        "Uttarakhand",
        "uttrakhand",  # Misspelling
        "UP",
        "Invalid State"
    ]
    
    for test_input in test_cases:
        result = normalize_state_name_for_enam(test_input)
        print(f"  {test_input:20} → {result}")

def test_imd_station_lookup():
    """Test IMD weather station lookup by state"""
    print("\n" + "="*80)
    print("TEST 2: IMD WEATHER STATION LOOKUP")
    print("="*80)
    
    test_states = ["Kerala", "Tamil Nadu", "Uttarakhand", "Punjab"]
    
    for state in test_states:
        print(f"\n📍 State: {state}")
        stations = get_stations_by_state(state)
        if stations.get('success'):
            print(f"   Total stations: {stations.get('total_stations')}")
            # Show first 3 stations
            for station in stations.get('stations', [])[:3]:
                print(f"   - {station['station_name']} (ID: {station['station_id']})")
        else:
            print(f"   Error: {stations.get('error')}")

def test_weather_with_state():
    """Test weather fetching using state name (auto-selects first station)"""
    print("\n" + "="*80)
    print("TEST 3: WEATHER FETCH BY STATE (Auto-select station)")
    print("="*80)
    
    test_states = ["Kerala", "Tamil Nadu"]
    
    for state in test_states:
        print(f"\n🌤️  State: {state}")
        weather = get_imd_weather_context(state_name=state)
        
        if weather.get('success'):
            context = weather.get('context', {})
            print(f"   Station: {context.get('station_name')}")
            print(f"   Station ID: {weather.get('station_id')}")
            print(f"   Forecast days: {weather.get('results_count')}")
            
            # Show first forecast
            forecast = context.get('forecast', [])
            if forecast:
                day = forecast[0]
                print(f"   Today: {day['min_temp']}°C - {day['max_temp']}°C, {day['description']}")
        else:
            print(f"   Error: {weather.get('error')}")

def test_weather_with_station_id():
    """Test weather fetching with explicit station ID"""
    print("\n" + "="*80)
    print("TEST 4: WEATHER FETCH WITH EXPLICIT STATION ID")
    print("="*80)
    
    # Test with specific station IDs
    stations = [
        ("43003", "Thiruvananthapuram"),
        ("99952", "Dehradun-Jhajhara"),
    ]
    
    for station_id, expected_name in stations:
        print(f"\n🌤️  Station ID: {station_id}")
        weather = get_imd_weather_context(station_id=station_id)
        
        if weather.get('success'):
            context = weather.get('context', {})
            print(f"   Station: {context.get('station_name')} (expected: {expected_name})")
            print(f"   Forecast days: {weather.get('results_count')}")
        else:
            print(f"   Error: {weather.get('error')}")

def test_enam_date_fallback():
    """Test eNAM price fetching with date fallback"""
    print("\n" + "="*80)
    print("TEST 5: eNAM PRICE FETCH WITH DATE FALLBACK")
    print("="*80)
    
    from datetime import datetime, timedelta
    
    # Test with today's date (might not have data)
    print("\n📊 Test A: Fetching today's prices with fallback")
    today = datetime.now().strftime('%Y-%m-%d')
    
    prices = get_enam_price_context(state_name="Kerala", from_date=today, to_date=today, max_days_back=7)
    
    if prices.get('success'):
        print(f"   ✓ Success: {prices.get('results_count')} price entries")
        print(f"   State: {prices.get('state')}")
        
        # Show first 3 prices
        price_list = prices.get('context', {}).get('prices', [])
        for i, price in enumerate(price_list[:3], 1):
            print(f"   {i}. {price['commodity']}: ₹{price['modal_price']}/{price['unit']}")
    else:
        print(f"   ✗ Error: {prices.get('error')}")
    
    # Test with old date (should fall back)
    print("\n📊 Test B: Fetching future date (should fall back to available data)")
    future = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
    
    prices = get_enam_price_context(state_name="Tamil Nadu", from_date=future, to_date=future, max_days_back=5)
    
    if prices.get('success'):
        print(f"   ✓ Success after fallback: {prices.get('results_count')} price entries")
    else:
        print(f"   ✗ No data found even after 5 days fallback")

def test_state_normalization_in_enam():
    """Test eNAM with different state name formats"""
    print("\n" + "="*80)
    print("TEST 6: eNAM WITH STATE NAME NORMALIZATION")
    print("="*80)
    
    test_states = [
        "kerala",
        "KERALA",
        "Tamil Nadu",
        "tamil",
        "Uttarakhand"
    ]
    
    for state in test_states:
        print(f"\n📊 Input state: '{state}'")
        # Just test normalization, not actual API call (to save time)
        normalized = normalize_state_name_for_enam(state)
        print(f"   Normalized to: '{normalized}'")

if __name__ == "__main__":
    print("\n" + "🧪 STATE & STATION MATCHING TEST SUITE" + "\n")
    
    # Test 1: State normalization
    test_state_normalization()
    
    # Test 2: Station lookup
    test_imd_station_lookup()
    
    # Test 3: Weather by state
    test_weather_with_state()
    
    # Test 4: Weather by station ID
    test_weather_with_station_id()
    
    # Test 5: eNAM date fallback
    test_enam_date_fallback()
    
    # Test 6: State normalization in eNAM
    test_state_normalization_in_enam()
    
    print("\n" + "="*80)
    print("✅ ALL TESTS COMPLETED")
    print("="*80 + "\n")
