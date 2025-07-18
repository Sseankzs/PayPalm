import requests
import json

# === CONFIG ===
BASE_URL = "https://paypalm-server.onrender.com"  # Replace with your actual Render URL
IMAGE_PATH = "uploads/palm_20250717-030033.jpg"  # Replace with a valid image path
USER_ID = "test_user_123"
MERCHANT = "TestMart"
AMOUNT = 19.99

# === COMMON ===
def send_post(endpoint, image_path, token_dict):
    url = f"{BASE_URL}/{endpoint}"
    with open(image_path, "rb") as img_file:
        files = {
            "image": img_file
        }
        data = {
            "token": "uZsYmasM5B3dVXTYjt3J"
        }
        print(f"🚀 Sending to {endpoint}...")
        response = requests.post(url, files=files, data=data)
        print(f"✅ {endpoint} status:", response.status_code)
        print(f"📦 {endpoint} response:", response.json())
        print("-" * 40)

# === TEST /registerPalm ===
register_token = "uZsYmasM5B3dVXTYjt3J"
send_post("registerPalm", IMAGE_PATH, register_token)

# === TEST /scanPalm ===
scan_token = {
    "merchant": MERCHANT,
    "amount": AMOUNT
}
send_post("scanPalm", IMAGE_PATH, scan_token)
