import requests
import json
import os

def test_create_post():
    # Assuming the FastAPI server is running on localhost:8000
    url = "http://localhost:8000/post"

    # Test data
    user_id = "6d0644bc-859e-46b9-a6f2-43d96872301c"
    post_data = {
        "user_id": user_id,
        "type": "normal",
        "content": "This is a test post from the test script",
        "place_id": "test_place_123",
        "city_name": "Test City",
        "state_name": "Test State",
        "latitude": 28.6139,  # Example coordinates for Delhi
        "longitude": 77.2090
    }

    print("Step 1: Preparing post data...")
    print(f"User ID: {user_id}")
    print(f"Content: {post_data['content']}")
    print(f"Type: {post_data['type']}")
    print()

    # Check if image exists
    image_path = "1751751787328.jpeg"
    files = None
    if os.path.exists(image_path):
        print("Step 2: Image file found, including in upload...")
        files = {'image': open(image_path, 'rb')}
        print(f"Image: {image_path}")
    else:
        print("Step 2: No image file found, proceeding without image...")
    print()

    print("Step 3: Sending POST request to create post...")
    try:
        response = requests.post(url, data=post_data, files=files)
        print(f"Response Status Code: {response.status_code}")
        print("Response JSON:")
        print(json.dumps(response.json(), indent=2))
        print()

        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print("Step 4: Post created successfully!")
            else:
                print("Step 4: Failed to create post.")
                print(f"Message: {result.get('message')}")
        else:
            print("Step 4: Request failed.")
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text}")

    except Exception as e:
        print(f"Error during request: {e}")

    finally:
        if files:
            files['image'].close()

if __name__ == "__main__":
    test_create_post()