import requests
from typing import Dict, Any, List
from datetime import datetime


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


def parse_imd_response(raw_data: List[Dict], station_id: str) -> Dict[str, Any]:
    """
    Parse and transform IMD response with readable field names
    
    Args:
        raw_data: Raw JSON response from IMD
        station_id: Station ID for reference
    
    Returns:
        Formatted dictionary with readable field names
    """
    if not raw_data or len(raw_data) < 1:
        return {"error": "No data received from IMD"}
    
    current_weather = raw_data[0]
    historical_data = raw_data[1] if len(raw_data) > 1 else {}
    
    # Parse current weather
    current = {
        "station_id": current_weather.get("station_id"),
        "station_name": current_weather.get("station"),
        "date": current_weather.get("dat"),
        "update_time": current_weather.get("updat"),
        "latitude": current_weather.get("lat"),
        "longitude": current_weather.get("lon"),
        
        # Current observations
        "current": {
            "max_temp": f"{current_weather.get('max')}°C",
            "min_temp": f"{current_weather.get('min')}°C",
            "max_temp_departure": current_weather.get("maxdep", "NA"),
            "min_temp_departure": current_weather.get("mindep", "NA"),
            "rainfall": f"{current_weather.get('rainfall')} mm",
            "humidity_0830": f"{current_weather.get('rh0830')}%",
            "humidity_1730": current_weather.get("rh1730"),
            "sunrise": current_weather.get("sunrise"),
            "sunset": current_weather.get("sunset"),
            "moonrise": current_weather.get("moonrise"),
            "moonset": current_weather.get("moonset"),
        },
        
        # 7-day forecast
        "forecast": parse_forecast(current_weather),
        
        # Alerts/Warnings
        "alerts": parse_warnings(current_weather),
        
        # Historical data (past 14 days)
        "historical": parse_historical(historical_data),
    }
    
    return {
        "success": True,
        "status": current_weather.get("status"),
        "data": current
    }


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


if __name__ == "__main__":
    # Test with PATTAMBI station
    result = get_imd_weather("99462")
    print(result)
