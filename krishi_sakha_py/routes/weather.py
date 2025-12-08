from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import logging

from scripts.station_finder import find_nearest_station

logger = logging.getLogger(__name__)
router = APIRouter()


class StationFinderRequest(BaseModel):
    state_name: str = Field(..., description="Name of the state (e.g., 'Kerala', 'Tamil Nadu')")
    latitude: float = Field(..., ge=-90, le=90, description="User's latitude")
    longitude: float = Field(..., ge=-180, le=180, description="User's longitude")
    max_distance_km: Optional[float] = Field(100.0, ge=1, le=500, description="Maximum acceptable distance in km")
    max_workers: Optional[int] = Field(10, ge=1, le=20, description="Number of parallel workers")


class StationInfo(BaseModel):
    station_id: str
    station_name: str
    lat: float
    lon: float
    distance_km: float


class StationFinderResponse(BaseModel):
    success: bool
    station: Optional[StationInfo] = None
    total_stations_checked: Optional[int] = None
    valid_stations_found: Optional[int] = None
    within_range: Optional[bool] = None
    alternatives: Optional[list] = None
    error: Optional[str] = None


@router.post("/weather/find-station", response_model=StationFinderResponse)
async def find_weather_station(request: StationFinderRequest):
    """
    Find the nearest IMD weather station based on user's GPS coordinates
    
    This endpoint helps automatically detect the best weather station for a user
    based on their location. It uses parallel processing to quickly check multiple
    stations and returns the nearest one along with alternatives.
    
    **Use Case:**
    Frontend sends user's state and GPS coordinates, backend finds the nearest
    weather station and returns the station_id that can be used for weather queries.
    
    **Example:**
    ```
    POST /weather/find-station
    {
        "state_name": "Kerala",
        "latitude": 8.5241,
        "longitude": 76.9366,
        "max_distance_km": 100
    }
    ```
    
    **Response:**
    ```
    {
        "success": true,
        "station": {
            "station_id": "43352",
            "station_name": "Alappuzha",
            "lat": 9.49,
            "lon": 76.34,
            "distance_km": 108.5
        },
        "within_range": false,
        "alternatives": [...]
    }
    ```
    """
    try:
        logger.info(f"Finding station for {request.state_name} at ({request.latitude}, {request.longitude})")
        
        result = find_nearest_station(
            state_name=request.state_name,
            user_lat=request.latitude,
            user_lon=request.longitude,
            max_distance_km=request.max_distance_km,
            max_workers=request.max_workers
        )
        
        if not result.get('success'):
            raise HTTPException(
                status_code=404,
                detail=result.get('error', 'Failed to find nearest station')
            )
        
        return StationFinderResponse(**result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in find_weather_station: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/weather/stations/{state_name}")
async def get_state_stations(state_name: str):
    """
    Get all weather stations in a specific state
    
    **Example:**
    ```
    GET /weather/stations/Kerala
    ```
    
    **Response:**
    ```
    {
        "success": true,
        "state": "Kerala",
        "total_stations": 21,
        "stations": [
            {"station_id": "43352", "station_name": "Alappuzha"},
            ...
        ]
    }
    ```
    """
    from scripts.station_finder import get_stations_in_state
    
    try:
        stations = get_stations_in_state(state_name)
        
        if not stations:
            raise HTTPException(
                status_code=404,
                detail=f"No stations found for state: {state_name}"
            )
        
        return {
            "success": True,
            "state": state_name,
            "total_stations": len(stations),
            "stations": stations
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting stations for {state_name}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
