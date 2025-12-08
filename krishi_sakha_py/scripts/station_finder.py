#!/usr/bin/env python3
"""
Station Finder for IMD Weather
Finds nearest weather station based on user's GPS coordinates
"""

import requests
from typing import Dict, Any, List, Optional, Tuple
from math import radians, cos, sin, asin, sqrt
from concurrent.futures import ThreadPoolExecutor, as_completed
import logging

logger = logging.getLogger(__name__)


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points on earth (in kilometers)
    
    Args:
        lat1, lon1: Coordinates of first point
        lat2, lon2: Coordinates of second point
    
    Returns:
        Distance in kilometers
    """
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    
    # Radius of earth in kilometers
    r = 6371
    
    return c * r


def get_station_coordinates(station_id: str) -> Optional[Tuple[float, float]]:
    """
    Fetch coordinates for a specific station by making weather API call
    
    Args:
        station_id: IMD station ID
    
    Returns:
        Tuple of (lat, lon) or None if failed
    """
    try:
        url = "https://city.imd.gov.in/citywx/responsive/api/fetchCity_static.php"
        data = {"ID": station_id}
        
        response = requests.post(url, data=data, timeout=5)
        response.raise_for_status()
        
        raw_data = response.json()
        if not raw_data or len(raw_data) == 0:
            return None
        
        current_weather = raw_data[0]
        
        def _float(v):
            if v is None or v == "" or v == "NA":
                return None
            try:
                return float(v)
            except:
                return None
        
        lat = _float(current_weather.get("lat"))
        lon = _float(current_weather.get("lon"))
        
        if lat is not None and lon is not None:
            return (lat, lon)
        
        return None
        
    except Exception as e:
        logger.debug(f"Failed to get coordinates for station {station_id}: {e}")
        return None


def get_stations_in_state(state_name: str) -> List[Dict[str, str]]:
    """
    Get all weather stations in a specific state
    
    Args:
        state_name: Name of the state
    
    Returns:
        List of stations with station_id and station_name
    """
    try:
        url = "https://city.imd.gov.in/citywx/responsive/api"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        raw_data = response.json()
        if not raw_data or "data" not in raw_data:
            return []
        
        stations_by_state = raw_data.get("data", {})
        
        # Find matching state (case-insensitive)
        for state, stations in stations_by_state.items():
            if state.lower() == state_name.lower():
                if isinstance(stations, dict):
                    return [
                        {
                            "station_id": station_id,
                            "station_name": station_name.strip(),
                        }
                        for station_id, station_name in stations.items()
                    ]
        
        return []
        
    except Exception as e:
        logger.error(f"Failed to fetch stations for {state_name}: {e}")
        return []


def fetch_station_with_distance(
    station: Dict[str, str], 
    user_lat: float, 
    user_lon: float
) -> Optional[Dict[str, Any]]:
    """
    Fetch coordinates for a station and calculate distance from user
    
    Args:
        station: Station dict with station_id and station_name
        user_lat: User's latitude
        user_lon: User's longitude
    
    Returns:
        Station dict with coordinates and distance, or None if failed
    """
    station_id = station["station_id"]
    coords = get_station_coordinates(station_id)
    
    if coords:
        station_lat, station_lon = coords
        distance = haversine_distance(user_lat, user_lon, station_lat, station_lon)
        
        return {
            "station_id": station_id,
            "station_name": station["station_name"],
            "lat": station_lat,
            "lon": station_lon,
            "distance_km": round(distance, 2)
        }
    
    return None


def find_nearest_station(
    state_name: str,
    user_lat: float,
    user_lon: float,
    max_distance_km: float = 100.0,
    max_workers: int = 10,
    max_stations_to_check: int = 50
) -> Dict[str, Any]:
    """
    Find the nearest weather station to user's location
    Uses parallel processing to fetch station coordinates quickly
    
    Args:
        state_name: Name of the state
        user_lat: User's latitude
        user_lon: User's longitude
        max_distance_km: Maximum acceptable distance (default: 100 km)
        max_workers: Number of parallel workers (default: 10)
        max_stations_to_check: Maximum stations to check (default: 50)
    
    Returns:
        Dict with nearest station info or error
    """
    try:
        logger.info(f"Finding nearest station in {state_name} to ({user_lat}, {user_lon})")
        
        # Get all stations in the state
        stations = get_stations_in_state(state_name)
        
        if not stations:
            return {
                "success": False,
                "error": f"No stations found in {state_name}"
            }
        
        logger.info(f"Found {len(stations)} stations in {state_name}")
        
        # Limit stations to check (to avoid too many API calls)
        stations_to_check = stations[:max_stations_to_check]
        logger.info(f"Checking first {len(stations_to_check)} stations")
        
        # Fetch coordinates for all stations in parallel
        valid_stations = []
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all tasks
            future_to_station = {
                executor.submit(fetch_station_with_distance, station, user_lat, user_lon): station
                for station in stations_to_check
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_station):
                result = future.result()
                if result:
                    valid_stations.append(result)
                    
                    # Early exit if we find a very close station (within 10 km)
                    if result["distance_km"] <= 10.0:
                        logger.info(f"Found very close station: {result['station_name']} ({result['distance_km']} km)")
                        # Cancel remaining tasks for efficiency
                        for f in future_to_station:
                            f.cancel()
                        break
        
        if not valid_stations:
            return {
                "success": False,
                "error": f"Could not fetch coordinates for any station in {state_name}"
            }
        
        # Sort by distance
        valid_stations.sort(key=lambda x: x["distance_km"])
        
        nearest = valid_stations[0]
        
        logger.info(f"Nearest station: {nearest['station_name']} ({nearest['distance_km']} km away)")
        
        # Check if within acceptable range
        if nearest["distance_km"] > max_distance_km:
            logger.warning(f"Nearest station is {nearest['distance_km']} km away (exceeds {max_distance_km} km limit)")
        
        return {
            "success": True,
            "station": nearest,
            "total_stations_checked": len(stations_to_check),
            "valid_stations_found": len(valid_stations),
            "within_range": nearest["distance_km"] <= max_distance_km,
            "alternatives": valid_stations[1:6] if len(valid_stations) > 1 else []  # Top 5 alternatives
        }
        
    except Exception as e:
        logger.error(f"Error finding nearest station: {e}", exc_info=True)
        return {
            "success": False,
            "error": str(e)
        }


# Example usage
if __name__ == "__main__":
    import sys
    
    # Test cases
    test_cases = [
        {
            "name": "Thiruvananthapuram area",
            "state": "Kerala",
            "lat": 8.5241,
            "lon": 76.9366
        },
        {
            "name": "Kozhikode area",
            "state": "Kerala",
            "lat": 11.2588,
            "lon": 75.7804
        },
        {
            "name": "Chennai area",
            "state": "Tamil Nadu",
            "lat": 13.0827,
            "lon": 80.2707
        },
        {
            "name": "Dehradun area",
            "state": "Uttarakhand",
            "lat": 30.3165,
            "lon": 78.0322
        }
    ]
    
    for test in test_cases:
        print(f"\n{'='*80}")
        print(f"Test: {test['name']}")
        print(f"State: {test['state']}, Location: ({test['lat']}, {test['lon']})")
        print('='*80)
        
        result = find_nearest_station(
            state_name=test['state'],
            user_lat=test['lat'],
            user_lon=test['lon'],
            max_distance_km=100.0,
            max_workers=10
        )
        
        if result.get('success'):
            station = result['station']
            print(f"\n✓ Found nearest station:")
            print(f"  Name: {station['station_name']}")
            print(f"  ID: {station['station_id']}")
            print(f"  Location: ({station['lat']}, {station['lon']})")
            print(f"  Distance: {station['distance_km']} km")
            print(f"  Within range: {result['within_range']}")
            print(f"\n  Checked {result['total_stations_checked']} stations")
            print(f"  Found {result['valid_stations_found']} valid stations")
            
            if result['alternatives']:
                print(f"\n  Alternative stations:")
                for alt in result['alternatives']:
                    print(f"    - {alt['station_name']}: {alt['distance_km']} km")
        else:
            print(f"\n✗ Error: {result.get('error')}")
