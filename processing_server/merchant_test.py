import requests
import json
import random
import time

# --- Configuration ---
# URL of your sub-server
SUB_SERVER_URL = "http://172.20.10.2:5001"

# --- Helper Functions ---

def generate_random_string(length=10):
    """Generates a random alphanumeric string."""
    characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return ''.join(random.choice(characters) for i in range(length))

# --- Test Functions ---

def test_sub_register_palm():
    """
    Tests the /registerPalm endpoint of the sub-server.
    This endpoint expects no data from the client.
    """
    print("\n--- Testing sub-server's /registerPalm endpoint ---")
    print(f"Attempting to call {SUB_SERVER_URL}/registerPalm with no client data.")
    try:
        response = requests.post(f"{SUB_SERVER_URL}/registerPalm")
        print(f"Response Status: {response.status_code}")
        print(f"Response Body: {response.json()}")
        if response.status_code == 200:
            print("✅ Sub-server /registerPalm test successful!")
        else:
            print("❌ Sub-server /registerPalm test failed.")
    except requests.exceptions.ConnectionError:
        print(f"❌ Connection Error: Is the sub-server running at {SUB_SERVER_URL}?")
    except json.JSONDecodeError:
        print(f"❌ JSON Decode Error: Response was not valid JSON. Raw response: {response.text}")
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

def test_sub_scan_palm():
    """
    Tests the /scanPalm endpoint of the sub-server.
    This endpoint expects a JSON body with 'merchant' and 'amount'.
    """
    print("\n--- Testing sub-server's /scanPalm endpoint ---")
    merchant_name = f"SubTestMerchant_{generate_random_string(5)}"
    amount = round(random.uniform(5.0, 1000.0), 2)

    # Prepare the JSON payload for the sub-server
    payload = {
        "merchant": merchant_name,
        "amount": amount
    }

    print(f"Attempting to call {SUB_SERVER_URL}/scanPalm with JSON payload:")
    print(f"  Merchant: {merchant_name}, Amount: {amount}")

    try:
        response = requests.post(
            f"{SUB_SERVER_URL}/scanPalm",
            json=payload, # 'json' parameter automatically sets Content-Type to application/json
            headers={'Content-Type': 'application/json'} # Explicitly set header for clarity
        )
        print(f"Response Status: {response.status_code}")
        print(f"Response Body: {response.json()}")
        if response.status_code == 200:
            print("✅ Sub-server /scanPalm test successful!")
        else:
            print("❌ Sub-server /scanPalm test failed.")
    except requests.exceptions.ConnectionError:
        print(f"❌ Connection Error: Is the sub-server running at {SUB_SERVER_URL}?")
    except json.JSONDecodeError:
        print(f"❌ JSON Decode Error: Response was not valid JSON. Raw response: {response.text}")
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

# --- Main Execution ---
if __name__ == "__main__":
    print("Starting sub-server tests...")
    time.sleep(1) # Give the server a moment to start if it's just been launched

    # Run the registration test
    test_sub_register_palm()

    # Run the payment scan test
    test_sub_scan_palm()

    print("\nSub-server tests finished.")
