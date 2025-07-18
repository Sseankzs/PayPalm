import requests
import json
import random
import time


# === CONFIG ===
BASE_URL = "https://paypalm-server.onrender.com"
IMAGE_PATH = "uploads/palm_20250717-030033.jpg"
MERCHANTS = [
    # 🍔 Food & Beverage
    "McDonald's", "KFC", "BurgerLab", "Texas Chicken", "Marrybrown", "Dominos", "Pizza Hut",
    "Subway", "Chatime", "Tealive", "Starbucks", "ZUS Coffee", "FamilyMart", "7-Eleven",
    "OldTown White Coffee", "Mamak Corner", "Nando's", "Kenny Rogers Roasters", "Secret Recipe",
    "Boat Noodle", "Ayamas", "Dunkin Donuts", "myBurgerLab", "Coolblog",

    # 🛒 Groceries & Convenience
    "Tesco", "Giant", "Econsave", "Mydin", "Jaya Grocer", "Village Grocer", "NSK", "Aeon Big",
    "Billion", "HeroMarket", "Speedmart99", "Watsons", "Guardian", "Caring Pharmacy",

    # 🚗 Transport & Petrol
    "Petronas", "Shell", "Petron", "Caltex", "BHPetrol", "Grab", "RapidKL", "MyCar",

    # 💡 Bills & Utilities
    "TNB", "Syabas", "Unifi", "Maxis", "Celcom", "Digi", "Yes", "Astro", "TM",

    # 🛍 Retail & Lifestyle
    "Shopee", "Lazada", "Zalora", "MR.DIY", "MR.TOY", "BookXcess", "Popular Bookstore",
    "Sports Direct", "Uniqlo", "H&M", "IKEA", "Decathlon",

    # 🏥 Health & Wellness
    "Guardian", "Watsons", "Caring Pharmacy", "AA Pharmacy", "BIG Pharmacy", "Alpro Pharmacy",

    # 💼 Services
    "Pos Malaysia", "J&T Express", "Lalamove", "Pgeon", "GDEX", "Klook", "AirAsia", "Malaysia Airlines"
]

# === POST FUNCTION ===
def send_post(endpoint, image_path, token_dict):
    url = f"{BASE_URL}/{endpoint}"
    with open(image_path, "rb") as img_file:
        files = {"image": img_file}
        if isinstance(token_dict, dict):
            data = {
                "token": json.dumps(token_dict),
                "merchant": token_dict.get("merchant"),
                "amount": token_dict.get("amount")
            }
        else:
            data = {"token": token_dict}
        print(f"🚀 Sending to {endpoint}... ({data['merchant']} - RM{data['amount']})")
        response = requests.post(url, files=files, data=data)
        print(f"✅ {endpoint} status:", response.status_code)
        try:
            print(f"📦 {endpoint} response:", response.json())
        except Exception as e:
            print("❌ Failed to parse JSON response:", e)
            print("📦 Raw response:", response.text)
        print("-" * 40)

# === SPAM LOOP ===
for i in range(15):
    merchant = MERCHANTS[i % len(MERCHANTS)]
    amount = round(random.uniform(1.5, 50.0), 2)  # Random RM1.50 - RM50.00
    scan_token = {
        "merchant": merchant,
        "amount": amount
    }
    send_post("scanPalm", IMAGE_PATH, scan_token)
    time.sleep(1)  # optional delay to not flood the server too hard
