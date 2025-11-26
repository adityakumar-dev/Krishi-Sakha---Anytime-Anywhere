import requests
import json

# JWT Token
JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ik4wcVFEejJEOXdEMVhrakIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2JpdmFuanlndXh2amN0Y3NjbmptLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI2ZDA2NDRiYy04NTllLTQ2YjktYTZmMi00M2Q5Njg3MjMwMWMiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzYzOTk4ODM1LCJpYXQiOjE3NjM5NjI4MzUsImVtYWlsIjoiYWRpdHlha3VtYXI5NDEwMzVAZ21haWwuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6eyJlbWFpbCI6ImFkaXR5YWt1bWFyOTQxMDM1QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInN1YiI6IjZkMDY0NGJjLTg1OWUtNDZiOS1hNmYyLTQzZDk2ODcyMzAxYyJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzYzOTYyODM1fV0sInNlc3Npb25faWQiOiJjOWNkMWQ0ZC03ZTA3LTQ5ZDItODQ3ZS1jZTY3M2FhODI2ZmYiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.Vu7J0cTI_nJrxg-Ksls00FPpWKgjQ2G1zlqtrOCETf4"
BASE_URL = "http://localhost:8000"

headers = {
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json"
}

def print_section(title):
    print("\n" + "="*80)
    print(f" {title}")
    print("="*80 + "\n")

def test_get_all_posts():
    """Test getting all posts with pagination"""
    print_section("TEST 1: GET ALL POSTS (Default)")
    try:
        response = requests.get(f"{BASE_URL}/posts", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('pagination'):
            print(f"Pagination: Page {data['pagination']['page']}/{data['pagination']['total_pages']}, Total: {data['pagination']['total_count']}")
        if data.get('posts'):
            print(f"\nFirst Post Sample:")
            print(json.dumps(data['posts'][0], indent=2))
    except Exception as e:
        print(f"Error: {e}")

def test_get_posts_by_place():
    """Test getting posts filtered by place_id"""
    print_section("TEST 2: GET POSTS BY PLACE_ID")
    try:
        response = requests.get(f"{BASE_URL}/posts?place_id=Sidawala248007", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('pagination'):
            print(f"Pagination: Page {data['pagination']['page']}/{data['pagination']['total_pages']}, Total: {data['pagination']['total_count']}")
        if data.get('posts'):
            print(f"\nPosts from Sidawala248007:")
            for post in data['posts'][:2]:
                print(f"  - ID: {post['id']}, Place: {post['place_id']}, Author: {post['author_name']}")
    except Exception as e:
        print(f"Error: {e}")

def test_get_posts_by_type():
    """Test getting posts filtered by type"""
    print_section("TEST 3: GET POSTS BY TYPE")
    try:
        response = requests.get(f"{BASE_URL}/posts?type_filter=normal", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('posts'):
            print(f"\nNormal Posts:")
            for post in data['posts'][:2]:
                print(f"  - ID: {post['id']}, Type: {post['type']}, Content: {post['content'][:30]}...")
    except Exception as e:
        print(f"Error: {e}")

def test_get_posts_by_status():
    """Test getting posts filtered by status"""
    print_section("TEST 4: GET POSTS BY STATUS")
    try:
        response = requests.get(f"{BASE_URL}/posts?status_filter=approved", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('posts'):
            print(f"\nApproved Posts:")
            for post in data['posts'][:2]:
                print(f"  - ID: {post['id']}, Status: {post['status']}")
    except Exception as e:
        print(f"Error: {e}")

def test_get_posts_combined_filters():
    """Test getting posts with multiple filters"""
    print_section("TEST 5: GET POSTS WITH COMBINED FILTERS")
    try:
        response = requests.get(
            f"{BASE_URL}/posts?place_id=Sidawala248007&type_filter=normal&status_filter=pending&limit=5&page=1",
            headers=headers
        )
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('pagination'):
            print(f"Pagination: Page {data['pagination']['page']}/{data['pagination']['total_pages']}")
        if data.get('posts'):
            print(f"\nFiltered Posts (Place, Type, Status):")
            for post in data['posts']:
                print(f"  - ID: {post['id']}")
                print(f"    Place: {post['place_id']}, Type: {post['type']}, Status: {post['status']}")
                print(f"    Author: {post['author_name']} ({post['author_role']})")
                print(f"    Likes: {post['like_count']}")
    except Exception as e:
        print(f"Error: {e}")

def test_get_posts_pagination():
    """Test pagination"""
    print_section("TEST 6: GET POSTS WITH PAGINATION")
    try:
        # Page 1
        response = requests.get(f"{BASE_URL}/posts?limit=3&page=1", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Page 1 - Posts: {len(data.get('posts', []))}")
        if data.get('pagination'):
            pag = data['pagination']
            print(f"  Total: {pag['total_count']}, Total Pages: {pag['total_pages']}")
            print(f"  Has Next: {pag['has_next']}, Has Prev: {pag['has_prev']}")
        
        # Page 2
        if data['pagination']['has_next']:
            response = requests.get(f"{BASE_URL}/posts?limit=3&page=2", headers=headers)
            data = response.json()
            print(f"\nPage 2 - Posts: {len(data.get('posts', []))}")
            if data.get('pagination'):
                pag = data['pagination']
                print(f"  Total: {pag['total_count']}, Total Pages: {pag['total_pages']}")
                print(f"  Has Next: {pag['has_next']}, Has Prev: {pag['has_prev']}")
    except Exception as e:
        print(f"Error: {e}")

def test_get_user_posts():
    """Test getting user's own posts"""
    print_section("TEST 7: GET USER'S OWN POSTS")
    try:
        response = requests.get(f"{BASE_URL}/post/user?page=1&limit=10", headers=headers)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Posts Count: {len(data.get('posts', []))}")
        if data.get('pagination'):
            print(f"Pagination: Page {data['pagination']['page']}/{data['pagination']['total_pages']}, Total: {data['pagination']['total_count']}")
        if data.get('posts'):
            print(f"\nUser's Posts:")
            for post in data['posts'][:3]:
                print(f"  - ID: {post['id']}, Type: {post['type']}, Likes: {post['like_count']}, Endorsements: {post['endorsement_count']}")
    except Exception as e:
        print(f"Error: {e}")

def test_like_post():
    """Test liking a post"""
    print_section("TEST 8: LIKE/UNLIKE POST")
    try:
        # First get a post to like
        response = requests.get(f"{BASE_URL}/posts?limit=1", headers=headers)
        posts = response.json().get('posts', [])
        
        if not posts:
            print("No posts available to like")
            return
        
        post_id = posts[0]['id']
        initial_likes = posts[0]['like_count']
        
        print(f"Post ID: {post_id}")
        print(f"Initial Likes: {initial_likes}")
        
        # Like the post
        response = requests.post(f"{BASE_URL}/post/{post_id}/like", headers=headers)
        print(f"\nLike Request Status: {response.status_code}")
        data = response.json()
        print(f"Liked: {data.get('liked')}")
        
        # Unlike the post
        response = requests.post(f"{BASE_URL}/post/{post_id}/like", headers=headers)
        print(f"\nUnlike Request Status: {response.status_code}")
        data = response.json()
        print(f"Liked (after toggle): {data.get('liked')}")
    except Exception as e:
        print(f"Error: {e}")

def test_endorse_post():
    """Test endorsing a post (if user has permission)"""
    print_section("TEST 9: ENDORSE POST")
    try:
        # First get a post to endorse
        response = requests.get(f"{BASE_URL}/posts?limit=1", headers=headers)
        posts = response.json().get('posts', [])
        
        if not posts:
            print("No posts available to endorse")
            return
        
        post_id = posts[0]['id']
        print(f"Post ID: {post_id}")
        
        # Try to endorse
        response = requests.post(f"{BASE_URL}/post/{post_id}/endorse", headers=headers)
        print(f"Endorse Request Status: {response.status_code}")
        data = response.json()
        print(f"Response: {data}")
        print(f"\nNote: Endorsement only works if user has 'asha', 'panchayat', or 'gov' role")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("\n" + "="*80)
    print(" KRISHI SAKHA POST ENDPOINTS TEST SUITE")
    print("="*80)
    print(f"Base URL: {BASE_URL}")
    print(f"User ID: 6d0644bc-859e-46b9-a6f2-43d96872301c")
    
    test_get_all_posts()
    test_get_posts_by_place()
    test_get_posts_by_type()
    test_get_posts_by_status()
    test_get_posts_combined_filters()
    test_get_posts_pagination()
    test_get_user_posts()
    test_like_post()
    test_endorse_post()
    
    print("\n" + "="*80)
    print(" TEST SUITE COMPLETE")
    print("="*80 + "\n")
