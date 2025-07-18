
import os
from flask import Flask, request, jsonify
import requests
import json
import io

# === Flask App Init ===
app = Flask(__name__)

# --- Configuration ---
# URL of your main Flask server
MAIN_SERVER_URL = "https://paypalm-server.onrender.com" # Assuming your main server runs on 8080

# Fixed user ID for /registerPalm as requested
FIXED_USER_ID = "uZsYmasM5B3dVXTYjt3J"

# Path to the dummy image file
DUMMY_IMAGE_PATH = os.path.join("uploads", "palm_20250717-030033.jpg")

# --- Helper Function (Simplified) ---
# This function now just returns the path, the file will be opened directly in the route
def get_dummy_image_path():
    """Returns the path to the dummy image file."""
    if not os.path.exists(DUMMY_IMAGE_PATH):
        print(f"Error: Dummy image file not found at {DUMMY_IMAGE_PATH}. Please create it.")
        return None
    return DUMMY_IMAGE_PATH

@app.route("/registerPalm", methods=["POST"])
def sub_register_palm():
    """
    Sub-server endpoint for registration.
    Receives nothing from the client, but generates a fixed user ID and uses a dummy image.
    Forwards these to the main server's /registerPalm endpoint.
    """
    print("\n[Sub-Server] Received request on /registerPalm")

    image_path = get_dummy_image_path()
    if not image_path:
        return jsonify({"error": "Failed to find dummy image for registration"}), 500

    # Open the image file directly when making the request
    try:
        with open(image_path, 'rb') as img_file:
            # Prepare data for the main server
            # requests will automatically handle the multipart/form-data encoding
            files = {'image': (os.path.basename(image_path), img_file, 'image/jpeg')} # Specify filename and content type
            data = {'token': FIXED_USER_ID}

            print(f"[Sub-Server] Forwarding to main server /registerPalm with token: {FIXED_USER_ID}")
            # Make the POST request to the main server
            response = requests.post(f"{MAIN_SERVER_URL}/registerPalm", data=data, files=files)

            # Return the main server's response to the client
            print(f"[Sub-Server] Main server response status: {response.status_code}")
            print(f"[Sub-Server] Main server response body: {response.text}")
            return jsonify(response.json()), response.status_code
    except requests.exceptions.ConnectionError:
        return jsonify({"error": f"Could not connect to main server at {MAIN_SERVER_URL}. Is it running?"}), 503
    except FileNotFoundError:
        return jsonify({"error": f"Dummy image file not found at {image_path}"}), 500
    except json.JSONDecodeError:
        return jsonify({"error": f"Main server response was not valid JSON: {response.text}"}), 500
    except Exception as e:
        print(f"[Sub-Server] Error forwarding /registerPalm request: {e}")
        return jsonify({"error": f"Internal sub-server error: {str(e)}"}), 500

@app.route("/scanPalm", methods=["POST"])
def sub_scan_palm():
    """
    Sub-server endpoint for scanning.
    Receives a JSON body with {"merchant": merchant_name, "amount": amount} from the client.
    Uses a dummy image and forwards the merchant/amount (as separate form fields)
    and a dummy token JSON string to the main server's /scanPalm endpoint.
    """
    print("\n[Sub-Server] Received request on /scanPalm")

    # Expecting JSON body from the client
    try:
        client_data = request.get_json()
        if not client_data:
            return jsonify({"error": "Expected JSON body with 'merchant' and 'amount'"}), 400
        merchant = client_data.get("merchant")
        amount = client_data.get("amount")

        if not merchant or amount is None: # Check for None for amount to allow 0
            return jsonify({"error": "Missing 'merchant' or 'amount' in JSON body"}), 400

        # Ensure amount is a string for form data, as main server expects it
        amount_str = str(amount)

    except Exception as e:
        print(f"[Sub-Server] Error parsing client JSON for /scanPalm: {e}")
        return jsonify({"error": "Invalid JSON format or missing data in request body"}), 400

    image_path = get_dummy_image_path()
    if not image_path:
        return jsonify({"error": "Failed to find dummy image for scanning"}), 500

    # Open the image file directly when making the request
    try:
        with open(image_path, 'rb') as img_file:
            # Prepare data for the main server's /scanPalm endpoint
            # The main server's /scanPalm expects 'token' as a JSON string,
            # and 'merchant'/'amount' as separate form fields.
            # We'll create a dummy token JSON string as it's required by the main server's parsing logic,
            # but the actual merchant/amount will come from the separate form fields.
            dummy_token_json_string = json.dumps({"dummy_key": "dummy_value"})

            files = {'image': (os.path.basename(image_path), img_file, 'image/jpeg')} # Specify filename and content type
            data = {
                'token': dummy_token_json_string, # Required by main server's parsing, but content not used for merchant/amount
                'merchant': merchant,             # Actual merchant name
                'amount': amount_str              # Actual amount
            }

            print(f"[Sub-Server] Forwarding to main server /scanPalm with merchant: {merchant}, amount: {amount_str}")
            # Make the POST request to the main server
            response = requests.post(f"{MAIN_SERVER_URL}/scanPalm", data=data, files=files)

            # Return the main server's response to the client
            print(f"[Sub-Server] Main server response status: {response.status_code}")
            print(f"[Sub-Server] Main server response body: {response.text}")
            return jsonify(response.json()), response.status_code
    except requests.exceptions.ConnectionError:
        return jsonify({"error": f"Could not connect to main server at {MAIN_SERVER_URL}. Is it running?"}), 503
    except FileNotFoundError:
        return jsonify({"error": f"Dummy image file not found at {image_path}"}), 500
    except json.JSONDecodeError:
        return jsonify({"error": f"Main server response was not valid JSON: {response.text}"}), 500
    except Exception as e:
        print(f"[Sub-Server] Error forwarding /scanPalm request: {e}")
        return jsonify({"error": f"Internal sub-server error: {str(e)}"}), 500

if __name__ == "__main__":
    # Run the sub-server on a different port, e.g., 5001
    # Ensure your main server is running on port 8080 (or adjust MAIN_SERVER_URL)
    print(f"Sub-server starting on port 5001. Main server URL: {MAIN_SERVER_URL}")
    app.run(host="0.0.0.0", port=5001, debug=True)
