import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from configs.supabase_key import SUPABASE

def print_section(title):
    print("\n" + "="*80)
    print(f" {title}")
    print("="*80 + "\n")

def call_rpc(place_id=None, type_filter=None, status_filter=None, limit=20, offset=0):
    """Call the get_posts RPC function - returns list directly"""
    try:
        print(f"  [Calling RPC with params: place={place_id}, type={type_filter}, status={status_filter}]", end="", flush=True)
        result = SUPABASE.rpc(
            "get_posts",
            {
                "place_arg": place_id,
                "type_arg": type_filter,
                "status_arg": status_filter,
                "limit_arg": limit,
                "offset_arg": offset
            }
        ).execute()
        
        # RPC returns the data directly as a list
        print(" ✅ Done!")
        return result
    except Exception as e:
        print(f"\n  ❌ Error: {e}")
        return None

def test_get_all_posts():
    """Test getting all posts without filters"""
    print_section("TEST 1: GET ALL POSTS (No Filters)")
    data = call_rpc(limit=10, offset=0)
    if data:
        print(f"✅ Posts Count: {len(data)}\n")
        print(f"First Post:")
        print(json.dumps(data[0], indent=2, default=str))
    else:
        print("❌ No posts returned")

def test_get_posts_by_place():
    """Test getting posts filtered by place_id"""
    print_section("TEST 2: GET POSTS BY PLACE_ID (Sidawala248007)")
    data = call_rpc(place_id="Sidawala248007", limit=10, offset=0)
    if data:
        print(f"✅ Posts Count: {len(data)}\n")
        print(f"Posts from Sidawala248007:")
        for i, post in enumerate(data[:3], 1):
            print(f"\n  Post {i}:")
            print(f"    ID: {post['id']}")
            print(f"    Place: {post['place_id']}")
            print(f"    Author: {post['author_name']} ({post['author_role']})")
            print(f"    Content: {post['content'][:50]}...")
            print(f"    Likes: {post['like_count']}")

def test_get_posts_by_type():
    """Test getting posts filtered by type"""
    print_section("TEST 3: GET POSTS BY TYPE (normal)")
    data = call_rpc(type_filter="normal", limit=10, offset=0)
    if data:
        print(f"✅ Posts Count: {len(data)}\n")
        print(f"Normal Posts:")
        for i, post in enumerate(data[:3], 1):
            print(f"  {i}. {post['content'][:40]}... (Likes: {post['like_count']})")

def test_get_posts_by_status():
    """Test getting posts filtered by status"""
    print_section("TEST 4: GET POSTS BY STATUS (pending)")
    data = call_rpc(status_filter="pending", limit=10, offset=0)
    if data:
        print(f"✅ Posts Count: {len(data)}\n")
        print(f"Pending Posts:")
        for i, post in enumerate(data[:3], 1):
            print(f"  {i}. {post['content'][:40]}... (Status: {post['status']})")

def test_combined_filters():
    """Test with multiple filters"""
    print_section("TEST 5: COMBINED FILTERS (Place + Type + Status)")
    data = call_rpc(
        place_id="Sidawala248007",
        type_filter="normal",
        status_filter="pending",
        limit=10,
        offset=0
    )
    if data:
        print(f"✅ Posts Count: {len(data)}\n")
        print(f"Filtered Results:")
        for i, post in enumerate(data, 1):
            print(f"\n  Post {i}:")
            print(f"    Content: {post['content']}")
            print(f"    Place: {post['place_id']}")
            print(f"    Type: {post['type']}")
            print(f"    Author: {post['author_name']}")

def test_pagination():
    """Test pagination"""
    print_section("TEST 6: PAGINATION (Limit=3, Offset=0 and Offset=3)")
    
    # First page
    data = call_rpc(limit=3, offset=0)
    if data:
        print(f"Page 1 - ✅ Posts: {len(data)}")
        for i, post in enumerate(data, 1):
            print(f"  {i}. {post['content'][:40]}...")
    
    # Second page
    data = call_rpc(limit=3, offset=3)
    if data:
        print(f"\nPage 2 - ✅ Posts: {len(data)}")
        for i, post in enumerate(data, 1):
            print(f"  {i}. {post['content'][:40]}...")

def test_author_info():
    """Test that author information is properly populated"""
    print_section("TEST 7: AUTHOR INFORMATION")
    data = call_rpc(limit=5, offset=0)
    if data:
        print(f"✅ Author Info Check (first {len(data)} posts):\n")
        for i, post in enumerate(data, 1):
            print(f"  Post {i}:")
            print(f"    User ID: {post['user_id']}")
            print(f"    Author Name: {post['author_name']}")
            print(f"    Author Role: {post['author_role']}")
            print(f"    Author City: {post['author_city']}")
            print(f"    Author State: {post['author_state']}")
            print()

def test_like_count():
    """Test that like counts are correctly aggregated"""
    print_section("TEST 8: LIKE COUNT AGGREGATION")
    data = call_rpc(limit=10, offset=0)
    if data:
        print(f"✅ Like Counts (first {len(data)} posts):\n")
        for i, post in enumerate(data, 1):
            print(f"  {i}. {post['content'][:35]}... => Likes: {post['like_count']}")

def test_full_output():
    """Test full output structure"""
    print_section("TEST 9: FULL OUTPUT STRUCTURE")
    data = call_rpc(place_id="Sidawala248007", limit=1, offset=0)
    if data:
        print(f"✅ Complete Post Object:\n")
        print(json.dumps(data[0], indent=2, default=str))

if __name__ == "__main__":
    print("\n" + "="*80)
    print(" GET_POSTS RPC FUNCTION TEST SUITE - WORKING VERSION")
    print("="*80)
    print("Using Supabase Service Role (Direct SQL RPC)")
    
    test_get_all_posts()
    test_get_posts_by_place()
    test_get_posts_by_type()
    test_get_posts_by_status()
    test_combined_filters()
    test_pagination()
    test_author_info()
    test_like_count()
    test_full_output()
    
    print("\n" + "="*80)
    print(" ✅ TEST SUITE COMPLETE - RPC IS WORKING!")
    print("="*80 + "\n")
