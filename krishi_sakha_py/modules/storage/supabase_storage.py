from datetime import datetime
from configs.supabase_key import SUPABASE
import supabase
from typing import Optional, Dict, Any
import os
import uuid

BUCKET_NAME = "krishi-community"

# Folder paths for different types of images
POST_IMAGES_FOLDER = "post_images/"

def push_image_to_supabase(image_raw: bytes, image_name: str, folder: str = POST_IMAGES_FOLDER) -> Dict[str, Any]:
    """
    Upload an image to Supabase storage bucket

    Args:
        image_raw (bytes): Raw image data
        image_name (str): Name of the image file (e.g., 'image.jpg')
        folder (str): Folder path within the bucket (default: post_images/)

    Returns:
        Dict containing upload status and file path
    """
    try:
        # Ensure folder ends with '/'
        if not folder.endswith('/'):
            folder += '/'

        # Create full file path with unique name
        # Sanitize image_name to avoid invalid characters
        safe_name = "".join(c for c in image_name if c.isalnum() or c in "._-").rstrip()
        if not safe_name:
            safe_name = "image"
        # Extract extension
        if "." in safe_name:
            name_part, ext = safe_name.rsplit(".", 1)
            ext = ext.lower()
        else:
            name_part = safe_name
            ext = "jpg"  # default
        # Create unique filename
        unique_id = str(uuid.uuid4())
        file_path = f"{folder}{unique_id}_{name_part}.{ext}"

        # Upload file to Supabase storage
        response = SUPABASE.storage.from_(BUCKET_NAME).upload(
            path=file_path,
            file=image_raw,
            file_options={"content-type": "image/jpeg"}  # Default to JPEG, can be made dynamic
        )

        # Check if upload was successful
        if hasattr(response, 'status_code') and response.status_code != 200:
            return {
                "success": False,
                "message": f"Upload failed with status code: {response.status_code}",
                "error": response.json() if hasattr(response, 'json') else str(response)
            }

        # Get public URL for the uploaded image
        public_url = SUPABASE.storage.from_(BUCKET_NAME).get_public_url(file_path)

        return {
            "success": True,
            "message": "Image uploaded successfully",
            "file_path": file_path,
            "public_url": public_url,
            "bucket": BUCKET_NAME
        }

    except Exception as e:
        return {
            "success": False,
            "message": f"Error uploading image: {str(e)}",
            "error": str(e)
        }

def upload_post_image(image_raw: bytes, image_name: str) -> Dict[str, Any]:
    """
    Upload an image for a post

    Args:
        image_raw (bytes): Raw image data
        image_name (str): Name of the image file

    Returns:
        Dict containing upload status and file path
    """
    return push_image_to_supabase(image_raw, image_name, POST_IMAGES_FOLDER)

def delete_image(file_path: str) -> Dict[str, Any]:
    """
    Delete an image from Supabase storage

    Args:
        file_path (str): Path of the file to delete

    Returns:
        Dict containing deletion status
    """
    try:
        response = SUPABASE.storage.from_(BUCKET_NAME).remove([file_path])

        if response.status_code == 200:
            return {
                "success": True,
                "message": "Image deleted successfully"
            }
        else:
            return {
                "success": False,
                "message": f"Delete failed with status code: {response.status_code}",
                "error": response.json() if hasattr(response, 'json') else str(response)
            }

    except Exception as e:
        return {
            "success": False,
            "message": f"Error deleting image: {str(e)}",
            "error": str(e)
        }