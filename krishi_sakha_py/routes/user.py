from fastapi import APIRouter, Depends, Form, HTTPException
from pydantic import BaseModel, validator
from typing import Optional
import logging

from routes.middlewares.auth_middleware import supabase_jwt_middleware
from configs.supabase_key import SUPABASE

router = APIRouter()

# Set up logging
logger = logging.getLogger(__name__)

class UserProfile(BaseModel):
    name: str
    phone: str
    city_name: str
    state_name: str
    latitude: float
    longitude: float
    locationiq_place_id: str
    
    @validator('phone')
    def validate_phone(cls, v):
        if not v or len(v) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        return v
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not (-90 <= v <= 90):
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not (-180 <= v <= 180):
            raise ValueError('Longitude must be between -180 and 180')
        return v

@router.post("/user/profile")
async def set_user_profile(
    name: str = Form(...),
    phone: str = Form(...),
    city_name: str = Form(...),
    state_name: str = Form(...),
    latitude: str = Form(...),  # Changed to str since Flutter sends as string
    longitude: str = Form(...), # Changed to str since Flutter sends as string
    locationiq_place_id: str = Form(...),
    user=Depends(supabase_jwt_middleware)
):
    try:
        user_id = user.get("sub")
        if not user_id:
            raise HTTPException(status_code=400, detail="Invalid user ID")
        
        # Convert string coordinates to float
        try:
            lat_float = float(latitude)
            lon_float = float(longitude)
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail="Invalid latitude or longitude format"
            )
        
        # Get role from user metadata (adjust based on your JWT structure)
        # Check common locations for role in Supabase JWT
        print(user)
        role = "normal"  # default
        if user.get("app_metadata", {}).get("app_role"):
            role = user["app_metadata"]["app_role"]
        elif user.get("user_metadata", {}).get("role"):
            role = user["user_metadata"]["role"]
        elif user.get("role"):
            role = user["role"]
        
        # Validate role
        valid_roles = ["normal", "asha", "panchayat", "gov"]
        if role not in valid_roles:
            role = "normal"
        
        # Validate data using Pydantic model
        profile_data = UserProfile(
            name=name,
            phone=phone,
            city_name=city_name,
            state_name=state_name,
            latitude=lat_float,
            longitude=lon_float,
            locationiq_place_id=locationiq_place_id
        )
        
        # Prepare data for Supabase
        supabase_data = {
            "id": user_id,
            "name": profile_data.name,
            "phone": profile_data.phone,
            "city_name": profile_data.city_name,
            "state_name": profile_data.state_name,
            "latitude": profile_data.latitude,
            "longitude": profile_data.longitude,
            "locationiq_place_id": profile_data.locationiq_place_id,
            "role": role
        }
        
        logger.info(f"Updating profile for user {user_id} with data: {supabase_data}")
        
        # Use upsert to handle both insert and update
        result = SUPABASE.table("users").upsert(
            supabase_data,
            on_conflict="id"
        ).execute()
        
        logger.info(f"Profile updated successfully for user {user_id}")
        
        return {
            "msg": "User profile updated successfully",
            "data": result.data
        }
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error updating user profile: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating user profile: {str(e)}")