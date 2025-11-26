from fastapi import APIRouter, Depends, UploadFile, File, Form, Query
from typing import Dict, Any, List
from modules.storage.supabase_storage import push_image_to_supabase
from routes.middlewares.auth_middleware import supabase_jwt_middleware
from configs.supabase_key import SUPABASE

router = APIRouter()

# ---------------------- CONSTANTS ----------------------
POST_TYPES = ["normal", "expert", "success", "bulletin"]
POST_STATUSES = ["pending", "approved", "rejected"]

# ---------------------- CREATE POST ----------------------
@router.post("/post")
async def create_post(
    type: str = Form("normal"),
    content: str = Form(None),
    image: UploadFile = File(None),
    place_id: str = Form(None),
    city_name: str = Form(None),
    state_name: str = Form(None),
    latitude: str = Form(None),
    longitude: str = Form(None),
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:

    user_id = user["sub"]
    if type not in POST_TYPES:
        return {"success": False, "message": f"Invalid type: {type}"}

    # Convert latitude and longitude to float
    try:
        lat = float(latitude) if latitude else None
        lon = float(longitude) if longitude else None
    except (ValueError, TypeError):
        return {"success": False, "message": "Invalid latitude or longitude format"}

    image_url = None
    if image:
        img = await image.read()
        upload = push_image_to_supabase(img, image.filename)
        if not upload.get("success"):
            return {"success": False, "message": "Image upload failed"}
        image_url = upload.get("public_url")

    post_data = {
        "user_id": user_id,
        "type": type,
        "content": content,
        "image_url": image_url,
        "place_id": place_id,
        "city_name": city_name,
        "state_name": state_name,
        "latitude": lat,
        "longitude": lon
    }
    print(post_data)

    try:
        SUPABASE.table("posts").insert(post_data).execute()
        return {"success": True, "message": "Post created successfully"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- TOGGLE LIKE ----------------------
@router.post("/post/{post_id}/like")
async def toggle_like(post_id: str, user=Depends(supabase_jwt_middleware)) -> Dict[str, Any]:
    user_id = user["sub"]
    try:
        existing = SUPABASE.table("post_likes").select("id").eq("user_id", user_id).eq("post_id", post_id).execute()
        if existing.data:
            SUPABASE.table("post_likes").delete().eq("user_id", user_id).eq("post_id", post_id).execute()
            return {"success": True, "liked": False}
        SUPABASE.table("post_likes").insert({"user_id": user_id, "post_id": post_id}).execute()
        return {"success": True, "liked": True}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- ENDORSE POST ----------------------
@router.post("/post/{post_id}/endorse")
async def endorse_post(post_id: str, user=Depends(supabase_jwt_middleware)):
    user_id = user["sub"]
    role = user["app_metadata"].get("app_role", "normal")
    if role not in ["asha", "panchayat", "gov"]:
        return {"success": False, "message": "You are not allowed to endorse"}
    try:
        existing = SUPABASE.table("post_endorsements").select("id").eq("endorsed_by", user_id).eq("post_id", post_id).execute()
        if existing.data:
            SUPABASE.table("post_endorsements").delete().eq("endorsed_by", user_id).eq("post_id", post_id).execute()
            return {"success": True, "endorsed": False}
        SUPABASE.table("post_endorsements").insert({
            "post_id": post_id,
            "endorsed_by": user_id,
            "role": role
        }).execute()
        return {"success": True, "endorsed": True}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- UPDATE POST STATUS ----------------------
@router.post("/post/{post_id}/status")
async def update_post_status(post_id: str, status: str = Form(...), user=Depends(supabase_jwt_middleware)):
    role = user["app_metadata"].get("app_role", "normal")
    if role not in ["asha", "panchayat", "gov"]:
        return {"success": False, "message": "Not allowed"}
    if status not in POST_STATUSES:
        return {"success": False, "message": f"Invalid status value: {status}"}
    try:
        SUPABASE.table("posts").update({"status": status}).eq("id", post_id).execute()
        return {"success": True, "message": "Status updated"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- FETCH POSTS (with Direct SQL Joins) ----------------------
# frontend will automatically handle this with rpc function calling

# ---------------------- FETCH USER POSTS (pagination) ----------------------
@router.get("/post/user")
async def fetch_user_posts(
    limit: int = Query(10, ge=1, le=100),
    page: int = Query(1, ge=1),
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:
    try:
        user_id = user["sub"]
        offset = (page - 1) * limit
        resp = SUPABASE.table("posts").select("""
            *,
            post_likes(count),
            post_endorsements(count)
        """).eq("user_id", user_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
        posts = resp.data or []
        for post in posts:
            post["like_count"] = post.get("post_likes_count", 0)
            post["endorsement_count"] = post.get("post_endorsements_count", 0)

        count_resp = SUPABASE.table("posts").select("id", count="exact").eq("user_id", user_id).execute()
        total_count = count_resp.count
        total_pages = (total_count + limit - 1) // limit

        return {
            "success": True,
            "posts": posts,
            "pagination": {
                "page": page,
                "limit": limit,
                "total_count": total_count,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_prev": page > 1
            }
        }
    except Exception as e:
        return {"success": False, "message": str(e)}


# async def 