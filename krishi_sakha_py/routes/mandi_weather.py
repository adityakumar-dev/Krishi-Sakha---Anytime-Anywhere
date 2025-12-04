from fastapi import APIRouter
from typing import Dict, Any

from fastapi.params import Depends
from routes.middlewares.auth_middleware import supabase_jwt_middleware
from scripts.enam_mandi import all_states_mandi_details, mandi_details, mandi_list, request_districts
from scripts.enam_price import all_states_mandi_price
from scripts.imd_handler import get_imd_weather, get_imd_by_location

router = APIRouter()

# ---------------------- GET DISTRICTS ----------------------
@router.get("/mandi/districts/{state_name}")
async def get_districts(state_name: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    if state_name not in all_states_mandi_details:
        return {"success": False, "message": "Invalid state name"}
    result = await request_districts(state_name)
    return {"success": True, "data": result}

# ---------------------- GET MANDI LIST ----------------------
@router.get("/mandi/list/{state_code}/{district}")
async def get_mandi_list(state_code: str, district: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    if state_code not in all_states_mandi_details:
        return {"success": False, "message": "Invalid state code"}
    result = await mandi_list(state_code, district)
    return {"success": True, "data": result}
# ---------------------- GET MANDI DETAILS ----------------------
@router.get("/mandi/details/{state_name}/{district_name}/{mandi_id}")
async def get_mandi_details(state_name: str, district_name: str, mandi_id: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    if state_name not in all_states_mandi_details:
        return {"success": False, "message": "Invalid state name"}
    result = await mandi_details(mandi_id, state_name, district_name)
    return {"success": True, "data": result}

# ---------------------- GET TRADE DATA ----------------------
@router.get("/mandi/trade_data/{state_name}/{from_date}/{to_date}")
async def get_trade_data(state_name: str, from_date: str, to_date: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    if state_name not in all_states_mandi_price:
        return {"success": False, "message": "Invalid state name"}
    result = await all_states_mandi_price(state_name, from_date, to_date)
    return {"success": True, "data": result}

# ---------------------- GET WEATHER DATA (IMD) ----------------------
@router.get("/weather/{station_id}")
async def get_weather_by_station(station_id: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    """
    Get weather data for a specific IMD station
    
    Example: /weather/99462
    """
    result = get_imd_weather(station_id)
    return result

@router.get("/weather/location/{location_name}")
async def get_weather_by_location(location_name: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    """
    Get weather data by location name
    
    Example: /weather/location/pattambi
    Supported locations: pattambi, thiruvananthapuram, kochi, kannur, kozhikode
    """
    result = get_imd_by_location(location_name)
    return result