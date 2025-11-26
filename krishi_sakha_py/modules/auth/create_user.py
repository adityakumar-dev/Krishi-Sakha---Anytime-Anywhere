from configs.supabase_key import SUPABASE, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
from pydantic import BaseModel
import requests

# create user as different roles like 'normal', 'asha', 'panchayat', 'gov'

class CreateUser(BaseModel):
    email: str
    password: str
    app_role: str

def create_user(email: str, password: str, app_role: str) -> dict:
    """
    Create a new user in the Supabase database with the specified app_role set in app_metadata.

    Args:
        email (str): User's email
        password (str): User's password
        app_role (str): Role to assign ('normal', 'asha', 'panchayat', 'gov')

    Returns:
        A dictionary containing the response from the Supabase API.
    """
    url = f"{SUPABASE_URL}/auth/v1/admin/users"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "email": email,
        "password": password,
        "app_metadata": {"app_role": app_role},
        "email_confirm": True  # True means user is created as already confirmed
    }
    response = requests.post(url, json=payload, headers=headers)
    if response.status_code == 201:
        return response.json()
    else:
        raise Exception(f"Failed to create user: {response.text}")
