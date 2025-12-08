"""
Test script for IMD weather context retrieval in pipeline
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from brain.pipeline import get_imd_weather_context

def test_imd_with_station_id():
    """Test with direct station ID (99952)"""
    print("\n" + "="*60)
    print("Test 1: Direct Station ID (99952)")
    print("="*60)
    
    result = get_imd_weather_context(station_id="99952")
    
    print(f"\nSuccess: {result['success']}")
    print(f"Source: {result['source']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        print(f"\nStation: {context['station_name']}")
        print(f"Location: {context['location']}")
        print(f"Sunrise: {context['sun_timings']['sunrise']}")
        print(f"Sunset: {context['sun_timings']['sunset']}")
        print(f"\nForecast (first 3 days):")
        for i, day in enumerate(context['forecast'][:3]):
            print(f"\n  Day {i+1} ({day['date']}):")
            print(f"    Temp: {day['min_temp']}°C - {day['max_temp']}°C")
            print(f"    Description: {day['description']}")
            print(f"    Warning: {day['warning']}")
    else:
        print(f"Error: {result.get('error')}")


def test_imd_default():
    """Test with no parameters (should use default 99952)"""
    print("\n" + "="*60)
    print("Test 2: No Parameters (Default)")
    print("="*60)
    
    result = get_imd_weather_context()
    
    print(f"\nSuccess: {result['success']}")
    print(f"Station ID used: {result.get('station_id')}")
    
    if result['success']:
        context = result['context']
        print(f"Station: {context['station_name']}")
        print(f"Forecast days: {len(context['forecast'])}")


def test_imd_with_station_name():
    """Test with station name lookup"""
    print("\n" + "="*60)
    print("Test 3: Station Name Lookup (Kozhikode)")
    print("="*60)
    
    result = get_imd_weather_context(station_name="Kozhikode", state_name="Kerala")
    
    print(f"\nSuccess: {result['success']}")
    
    if result['success']:
        context = result['context']
        print(f"Station: {context['station_name']}")
        print(f"Station ID: {result.get('station_id')}")
        print(f"Forecast days: {len(context['forecast'])}")
    else:
        print(f"Error: {result.get('error')}")


if __name__ == "__main__":
    print("\n🌤️  Testing IMD Weather Context Retrieval")
    
    test_imd_with_station_id()
    test_imd_default()
    test_imd_with_station_name()
    
    print("\n✅ All tests completed\n")
