import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from modules.storage.supabase_storage import upload_post_image
import json

def test_supabase_upload():
    # Path to the sample image
    image_path = "1751751787328.jpeg"  # Assuming the image is in the current directory or provide full path

    print("Step 1: Checking if image file exists...")
    if not os.path.exists(image_path):
        print(f"Error: Image file '{image_path}' not found.")
        return

    print(f"Image file '{image_path}' found.")

    print("\nStep 2: Reading image file...")
    try:
        with open(image_path, 'rb') as f:
            image_raw = f.read()
        print(f"Successfully read {len(image_raw)} bytes from image file.")
    except Exception as e:
        print(f"Error reading image file: {e}")
        return

    print("\nStep 3: Extracting image name...")
    image_name = os.path.basename(image_path)
    print(f"Image name: {image_name}")

    print("\nStep 4: Uploading image to Supabase...")
    result = upload_post_image(image_raw, image_name)
    print("Upload result:")
    print(json.dumps(result, indent=2))

    if result.get("success"):
        print("\nStep 5: Upload successful!")
        print(f"Public URL: {result.get('public_url')}")
    else:
        print("\nStep 5: Upload failed!")
        print(f"Error: {result.get('message')}")

if __name__ == "__main__":
    test_supabase_upload()