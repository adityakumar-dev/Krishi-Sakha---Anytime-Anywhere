from fastapi import APIRouter, Depends, UploadFile, File, Form, Query
from typing import Dict, Any, List
from modules.storage.supabase_storage import push_image_to_supabase
from routes.middlewares.auth_middleware import supabase_jwt_middleware
from configs.supabase_key import SUPABASE

router = APIRouter()

# ---------------------- CONSTANTS ----------------------
POST_TYPES = ["normal", "expert", "success", "bulletin"]
POST_STATUSES = ["pending", "approved", "rejected"]
SPECIAL_POST_TYPES = ["expert", "success", "bulletin"]  # Posts that require special permissions
VERIFICATION_ROLES = ["asha", "panchayat", "gov", "expert"]  # Roles that can verify/reject posts

# ---------------------- CREATE POST (Normal Users) ----------------------
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
    """
    Create a post. Normal users can only create 'normal' type posts (pending approval).
    Special roles can create expert/success/bulletin posts (auto-approved).
    """
    user_id = user["sub"]
    role = user.get("app_metadata", {}).get("app_role", "normal")
    
    if type not in POST_TYPES:
        return {"success": False, "message": f"Invalid type: {type}"}
    
    # Check if user has permission to create special post types
    if type in SPECIAL_POST_TYPES and role not in VERIFICATION_ROLES:
        return {"success": False, "message": f"You don't have permission to create {type} posts"}

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

    # Determine post status based on type and role
    # Normal posts need approval, special posts from verified roles are auto-approved
    status = "approved" if (type in SPECIAL_POST_TYPES and role in VERIFICATION_ROLES) else "pending"

    post_data = {
        "user_id": user_id,
        "type": type,
        "content": content,
        "image_url": image_url,
        "place_id": place_id,
        "city_name": city_name,
        "state_name": state_name,
        "latitude": lat,
        "longitude": lon,
        "status": status
    }

    try:
        SUPABASE.table("posts").insert(post_data).execute()
        message = "Post created and approved" if status == "approved" else "Post created, pending verification"
        return {"success": True, "message": message, "status": status}
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


# ---------------------- CREATE SPECIAL POST (Expert/Success/Bulletin) ----------------------
@router.post("/post/special")
async def create_special_post(
    type: str = Form(...),
    content: str = Form(None),
    image: UploadFile = File(None),
    place_id: str = Form(None),
    city_name: str = Form(None),
    state_name: str = Form(None),
    latitude: str = Form(None),
    longitude: str = Form(None),
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:
    """
    Create special post types (expert, success, bulletin).
    Only users with special roles can create these posts.
    These posts are auto-approved.
    """
    user_id = user["sub"]
    role = user.get("app_metadata", {}).get("app_role", "normal")
    
    # Validate post type
    if type not in SPECIAL_POST_TYPES:
        return {"success": False, "message": f"Invalid special post type. Must be one of: {', '.join(SPECIAL_POST_TYPES)}"}
    
    # Check role permission
    if role not in VERIFICATION_ROLES:
        return {"success": False, "message": f"Only {', '.join(VERIFICATION_ROLES)} roles can create {type} posts"}

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
        "longitude": lon,
        "status": "approved"  # Special posts are auto-approved
    }

    try:
        SUPABASE.table("posts").insert(post_data).execute()
        return {"success": True, "message": f"{type.capitalize()} post created and approved", "status": "approved"}
    except Exception as e:
        return {"success": False, "message": str(e)}
    

# ---------------------- VERIFY/APPROVE POST ----------------------
@router.post("/post/verify/{post_id}")
async def verify_post(
    post_id: str, 
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:
    """
    Approve a pending post. Only special roles can verify posts.
    Used to approve normal user posts after moderation.
    """
    user_id = user["sub"]
    role = user.get("app_metadata", {}).get("app_role", "normal")
    
    if role not in VERIFICATION_ROLES:
        return {"success": False, "message": f"Only {', '.join(VERIFICATION_ROLES)} roles can verify posts"}
    
    try:
        # Get post details first
        post_resp = SUPABASE.table("posts").select("*").eq("id", post_id).execute()
        if not post_resp.data:
            return {"success": False, "message": "Post not found"}
        
        post = post_resp.data[0]
        if post["status"] == "approved":
            return {"success": False, "message": "Post is already approved"}
        
        # Update post status to approved
        SUPABASE.table("posts").update({
            "status": "approved"
        }).eq("id", post_id).execute()
        
        return {"success": True, "message": "Post approved successfully"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- REJECT POST ----------------------
@router.post("/post/reject/{post_id}")
async def reject_post(
    post_id: str,
    reason: str = Form(None),
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:
    """
    Reject a pending post. Only special roles can reject posts.
    Used to reject inappropriate or low-quality content.
    """
    user_id = user["sub"]
    role = user.get("app_metadata", {}).get("app_role", "normal")
    
    if role not in VERIFICATION_ROLES:
        return {"success": False, "message": f"Only {', '.join(VERIFICATION_ROLES)} roles can reject posts"}
    
    try:
        # Get post details first
        post_resp = SUPABASE.table("posts").select("*").eq("id", post_id).execute()
        if not post_resp.data:
            return {"success": False, "message": "Post not found"}
        
        post = post_resp.data[0]
        if post["status"] == "rejected":
            return {"success": False, "message": "Post is already rejected"}
        
        # Update post status to rejected
        # Note: rejection_reason not stored in DB (would need schema update)
        SUPABASE.table("posts").update({
            "status": "rejected"
        }).eq("id", post_id).execute()
        
        return {"success": True, "message": "Post rejected successfully"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# ---------------------- GET PENDING POSTS (For Moderation) ----------------------
@router.get("/post/pending")
async def get_pending_posts(
    limit: int = Query(20, ge=1, le=100),
    page: int = Query(1, ge=1),
    user=Depends(supabase_jwt_middleware)
) -> Dict[str, Any]:
    """
    Get all pending posts for moderation.
    Only accessible by verification roles (asha, panchayat, gov, expert).
    """
    role = user.get("app_metadata", {}).get("app_role", "normal")
    
    if role not in VERIFICATION_ROLES:
        return {"success": False, "message": "Not authorized to view pending posts"}
    
    try:
        offset = (page - 1) * limit
        
        # Get pending posts without user join (auth.users is not directly joinable)
        # Frontend should fetch user details separately if needed
        resp = SUPABASE.table("posts").select("*").eq("status", "pending").order("created_at", desc=False).range(offset, offset + limit - 1).execute()
        
        posts = resp.data or []
        
        # Get total count
        count_resp = SUPABASE.table("posts").select("id", count="exact").eq("status", "pending").execute()
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