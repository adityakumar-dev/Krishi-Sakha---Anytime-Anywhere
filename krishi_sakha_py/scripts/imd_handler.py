import requests
from typing import Dict, Any, List
from datetime import datetime, timedelta


def get_imd_stations() -> Dict[str, Any]:
    """
    Fetch list of all IMD weather stations organized by state
    
    Returns:
        Dictionary with states and their stations
    """
    url = "https://city.imd.gov.in/citywx/responsive/api"
    
    response = requests.get(url)
    response.raise_for_status()
    
    raw_data = response.json()
    
    # Parse and format station list for frontend
    return parse_station_list(raw_data)


def parse_station_list(raw_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Parse IMD station list and format with readable structure
    
    Args:
        raw_data: Raw JSON response from IMD stations API
    
    Returns:
        Formatted dictionary with organized station data
    """
    if not raw_data or "data" not in raw_data:
        return {"error": "No stations data received from IMD"}
    
    stations_by_state = raw_data.get("data", {})
    
    # Transform into a more usable format
    formatted_stations = {}
    
    for state, stations in stations_by_state.items():
        if isinstance(stations, dict):
            formatted_stations[state] = [
                {
                    "station_id": station_id,
                    "station_name": station_name.strip(),
                }
                for station_id, station_name in stations.items()
            ]
    
    return {
        "success": True,
        "status": raw_data.get("status"),
        "message": raw_data.get("message"),
        "total_states": len(formatted_stations),
        "total_stations": sum(len(stations) for stations in formatted_stations.values()),
        "data": formatted_stations
    }


def get_stations_by_state(state_name: str) -> Dict[str, Any]:
    """
    Get all stations for a specific state
    
    Args:
        state_name: Name of the state (e.g., 'Kerala', 'Tamil Nadu')
    
    Returns:
        List of stations for that state
    """
    stations_data = get_imd_stations()
    
    if "error" in stations_data:
        return stations_data
    
    # Find matching state (case-insensitive)
    for state, stations in stations_data.get("data", {}).items():
        if state.lower() == state_name.lower():
            return {
                "success": True,
                "state": state,
                "total_stations": len(stations),
                "stations": stations
            }
    
    return {
        "success": False,
        "error": f"State '{state_name}' not found"
    }


def get_station_by_name(station_name: str) -> Dict[str, Any]:
    """
    Search for a station by name across all states
    
    Args:
        station_name: Name of the station to search for
    
    Returns:
        Station info with station_id and state
    """
    stations_data = get_imd_stations()
    
    if "error" in stations_data:
        return stations_data
    
    # Search for matching station
    for state, stations in stations_data.get("data", {}).items():
        for station in stations:
            if station["station_name"].lower() == station_name.lower():
                return {
                    "success": True,
                    "state": state,
                    "station_id": station["station_id"],
                    "station_name": station["station_name"]
                }
    
    return {
        "success": False,
        "error": f"Station '{station_name}' not found"
    }


def get_imd_weather(station_id: str) -> Dict[str, Any]:
    """
    Fetch weather data from IMD (Indian Meteorological Department)
    
    Args:
        station_id: IMD station ID (e.g., '99462' for PATTAMBI)
    
    Returns:
        Dictionary with current weather and 7-day forecast
    """
    url = "https://city.imd.gov.in/citywx/responsive/api/fetchCity_static.php"
    data = {"ID": station_id}
    
    response = requests.post(url, data=data)
    response.raise_for_status()
    
    raw_data = response.json()
    
    # Parse and rename fields for frontend readability
    return parse_imd_response(raw_data, station_id)


def parse_imd_response(raw_data: List[Dict], station_id: str = None) -> Dict[str, Any]:
    """
    Parse IMD city weather JSON and return clean, structured data
    with all forecast days in one array (including humidity & warnings per day)
    """
    if not raw_data or len(raw_data) == 0:
        return {"error": "No data received from IMD"}

    current_weather = raw_data[0]

    def _float(v):
        if v is None or v == "" or v == "NA":
            return None
        try:
            return float(v)
        except:
            return None

    def _int(v):
        if v is None or v == "" or v == "NA":
            return None
        try:
            return int(float(v))
        except:
            return None

    # Base date from the forecast
    base_date_str = current_weather.get("dat", datetime.now().strftime("%Y-%m-%d"))
    try:
        base_date = datetime.strptime(base_date_str, "%Y-%m-%d")
    except:
        base_date = datetime.now()

    # Station info
    station_name = current_weather.get("station", "Unknown Station")
    lat = _float(current_weather.get("lat"))
    lon = _float(current_weather.get("lon"))

    # Sunrise/Sunset (today only)
    sunrise = current_weather.get("sunrise")
    sunset = current_weather.get("sunset")
    moonrise = current_weather.get("moonrise")
    moonset = current_weather.get("moonset")

    # Prefer summarized arrays (more reliable)
    ffc   = current_weather.get("ffc") or []
    fimg  = current_weather.get("fimg") or []
    fmax  = current_weather.get("fmax") or []
    fmin  = current_weather.get("fmin") or []
    rh0830d = current_weather.get("rh0830d") or []
    rh1730d = current_weather.get("rh1730d") or []
    wText   = current_weather.get("wText") or []
    wColor  = current_weather.get("wColor") or []

    forecast_period = []

    for day_offset in range(6):  # IMD gives 6 days (today + 5)
        if day_offset >= len(ffc):
            break

        forecast_date = (base_date + timedelta(days=day_offset)).strftime("%Y-%m-%d")

        desc = ffc[day_offset] if day_offset < len(ffc) else None
        img  = fimg[day_offset] if day_offset < len(fimg) else None
        max_temp = _float(fmax[day_offset]) if day_offset < len(fmax) else None
        min_temp = _float(fmin[day_offset]) if day_offset < len(fmin) else None

        rh_morning = _int(rh0830d[day_offset]) if day_offset < len(rh0830d) else None
        rh_evening = _int(rh1730d[day_offset]) if day_offset < len(rh1730d) else None

        warning_text = wText[day_offset] if day_offset < len(wText) else "No warning"
        warning_color = wColor[day_offset] if day_offset < len(wColor) else "green"

        forecast_period.append({
            "date_offset": day_offset,
            "date": forecast_date,
            "max": max_temp,
            "min": min_temp,
            "desc": desc or "Mainly Clear sky",
            "img": img or "2",
            "rh_0830": rh_morning,
            "rh_1730": rh_evening,
            "warning": warning_text,
            "warning_color": warning_color.lower() if warning_color else "green"
        })

    # Final clean output
    result = {
        "station": station_name,
        "lat": lat,
        "lon": lon,
        "sunrise": sunrise,
        "sunset": sunset,
        "moonrise": moonrise,
        "moonset": moonset,
        "forecast_period": forecast_period,
        "last_updated": current_weather.get("updat") or datetime.now().isoformat()
    }

    return result


def parse_forecast(weather_data: Dict) -> List[Dict[str, Any]]:
    """
    Parse 7-day forecast from IMD response
    """
    forecast = []
    
    for day in range(7):
        forecast_key = f"forecast{day}"
        max_key = f"max{day}"
        min_key = f"min{day}"
        img_key = f"img{day}"
        
        forecast.append({
            "day": day,
            "description": weather_data.get(forecast_key, ""),
            "max_temp": f"{weather_data.get(max_key)}°C",
            "min_temp": f"{weather_data.get(min_key)}°C",
            "icon_code": weather_data.get(img_key),
            "humidity_0830": f"{weather_data.get(f'rh0830d{day}')}%",
            "humidity_1730": f"{weather_data.get(f'rh1730d{day}')}%",
        })
    
    return forecast


def parse_warnings(weather_data: Dict) -> List[Dict[str, Any]]:
    """
    Parse weather warnings/alerts from IMD response
    """
    warnings = []
    
    for day in range(7):
        warning_key = f"warning{day}"
        color_key = f"color{day}"
        img_key = f"wImg"
        text_key = f"wText"
        
        warning_code = weather_data.get(warning_key)
        if warning_code and warning_code != "0":
            warnings.append({
                "day": day,
                "warning_code": warning_code,
                "alert_level": weather_data.get(color_key),  # 0=green, 1=yellow, etc
                "alert_text": weather_data.get(f"{text_key}")[day] if isinstance(weather_data.get(text_key), list) else "",
                "alert_icon": weather_data.get(f"wImg")[day] if isinstance(weather_data.get("wImg"), list) else "",
            })
    
    return warnings


def parse_historical(historical_data: Dict) -> List[Dict[str, Any]]:
    """
    Parse historical temperature data
    """
    history = []
    
    for date_str, day_data in sorted(historical_data.items()):
        if isinstance(day_data, dict) and "DATE" in day_data:
            history.append({
                "date": date_str,
                "display_date": day_data.get("DATE"),
                "max_temp": day_data.get("MAX"),
                "min_temp": day_data.get("MIN"),
                "forecast_max": day_data.get("F_MAX"),
                "forecast_min": day_data.get("F_MIN"),
            })
    
    return history


# Station IDs reference
COMMON_STATIONS = {
    "pattambi": "99462",
    "thiruvananthapuram": "43003",
    "kochi": "43007",
    "kannur": "43015",
    "kozhikode": "43012",
}


def get_imd_by_location(location_name: str) -> Dict[str, Any]:
    """
    Convenience function to get weather by location name
    """
    station_id = COMMON_STATIONS.get(location_name.lower())
    if not station_id:
        return {"error": f"Location '{location_name}' not found in station database"}
    
    return get_imd_weather(station_id)

def search_stationList(query: str) -> List[Dict[str, str]]:
    """
    Search for IMD stations by name substring
    
    Args:
        query: Substring to search in station names
    
    Returns:
        List of matching stations with their IDs
    """
    stations_data = get_imd_stations()
    
    if "error" in stations_data:
        return []
    
    results = []
    query_lower = query.lower()
    
    for state, stations in stations_data.get("data", {}).items():
        for station in stations:
            if query_lower in station["station_name"].lower():
                results.append({
                    "state": state,
                    "station_id": station["station_id"],
                    "station_name": station["station_name"]
                })
    
    return results


if __name__ == "__main__":
    # Test with PATTAMBI station
    # result = get_imd_weather("99462")
    # print(result)

    # print(get_stations_by_state("Uttrakhand"))
    print(get_imd_weather("99952"))
