"""
Script to create the get_posts RPC function on Supabase.
Run this script once to set up the function.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from configs.supabase_key import SUPABASE

# SQL to create the RPC function
CREATE_FUNCTION_SQL = """
CREATE OR REPLACE FUNCTION get_posts(
    place_arg text DEFAULT NULL,
    type_arg text DEFAULT NULL,
    status_arg text DEFAULT NULL,
    limit_arg INT DEFAULT 20,
    offset_arg INT DEFAULT 0
)
RETURNS TABLE (
    id uuid,
    user_id uuid,
    type text,
    content text,
    image_url text,
    status text,
    place_id text,
    city_name text,
    state_name text,
    created_at timestamptz,
    author_name text,
    author_role text,
    author_city text,
    author_state text,
    like_count int
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT
        p.id,
        p.user_id,
        p.type,
        p.content,
        p.image_url,
        p.status,
        p.place_id,
        p.city_name,
        p.state_name,
        p.created_at,
        u.name AS author_name,
        u.role AS author_role,
        u.city_name AS author_city,
        u.state_name AS author_state,
        COALESCE(l.like_count, 0) AS like_count
    FROM public.posts p
    LEFT JOIN public.users u ON p.user_id = u.id
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_count
        FROM public.post_likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE
        (place_arg IS NULL OR p.place_id = place_arg)
        AND (type_arg IS NULL OR p.type = type_arg)
        AND (status_arg IS NULL OR p.status = status_arg)
    ORDER BY p.created_at DESC
    LIMIT limit_arg
    OFFSET offset_arg;
$$;
"""

def setup_rpc_function():
    """
    Create the get_posts RPC function on Supabase.
    You need to run this manually in Supabase SQL Editor due to SDK limitations.
    """
    print("="*80)
    print(" SETUP: CREATE GET_POSTS RPC FUNCTION")
    print("="*80)
    print("\n⚠️  IMPORTANT: Supabase Python SDK doesn't support executing raw DDL.")
    print("You need to create this function manually using the Supabase SQL Editor.\n")
    
    print("Steps to create the function:")
    print("1. Go to your Supabase project dashboard")
    print("2. Click on 'SQL Editor' in the left sidebar")
    print("3. Click 'New Query'")
    print("4. Copy and paste the SQL below:")
    print("\n" + "="*80)
    print(CREATE_FUNCTION_SQL)
    print("="*80)
    print("\n5. Click 'Run' button")
    print("6. You should see 'Success' message")
    print("\n✅ After that, the RPC function will be available!\n")

def test_rpc_function():
    """
    Test if the RPC function exists and works
    """
    print("="*80)
    print(" TEST: VERIFY RPC FUNCTION")
    print("="*80 + "\n")
    
    try:
        # Try to call the get_posts function
        response = SUPABASE.rpc(
            "get_posts",
            {
                "place_arg": None,
                "type_arg": None,
                "status_arg": None,
                "limit_arg": 5,
                "offset_arg": 0
            }
        ).execute()
        
        print("✅ RPC Function exists and works!")
        print(f"✅ Retrieved {len(response.data)} posts\n")
        
        if response.data:
            print("Sample post structure:")
            import json
            print(json.dumps(response.data[0], indent=2, default=str))
        
        return True
        
    except Exception as e:
        print(f"❌ RPC Function not found or error occurred:")
        print(f"   Error: {str(e)}\n")
        print("   Solution: Create the function first using the SQL provided above.\n")
        return False

if __name__ == "__main__":
    print("\n")
    
    # First, show instructions for creating the function
    setup_rpc_function()
    
    # Then try to test if it exists
    import time
    print("Waiting 2 seconds before testing...\n")
    time.sleep(2)
    
    test_rpc_function()
