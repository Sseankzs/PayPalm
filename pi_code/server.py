import os
from flask import Flask, request, jsonify
import requests
import json
import io
import random
import time
from PIL import Image # For simulating image capture
import cv2
import numpy as np
from pyzbar.pyzbar import decode
from picamera2 import Picamera2
import onnxruntime as ort

# === Flask App Init ===
app = Flask(__name__)

# --- Configuration ---
# URL of your main Flask server
MAIN_SERVER_URL = "https://paypalm-server.onrender.com" # Assuming your main server runs on 8080

# --- Raspberry Pi Specific Functions (Simulated) ---

MODEL_PATH = "palm_detection_mediapipe_2023feb.onnx"
PALM_IMAGE_PATH = "palm_captured.jpg"
INPUT_SIZE = 192
CONFIDENCE_THRESHOLD = 1

# Load model
ort_session = ort.InferenceSession(MODEL_PATH)

def preprocess(image):
    image = cv2.resize(image, (INPUT_SIZE, INPUT_SIZE))
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    input_tensor = np.expand_dims(image.astype(np.float32) / 255.0, axis=0)
    return input_tensor

def detect_palm(image):
    input_tensor = preprocess(image)
    outputs = ort_session.run(None, {"input_1": input_tensor})
    scores = outputs[0][0, :, 0]
    max_score = np.max(scores)
    return max_score >= CONFIDENCE_THRESHOLD
def capture_palm():
    print("🖐️ Initializing camera...")
    picam2 = Picamera2()
    picam2.configure(picam2.create_preview_configuration(main={"size": (640, 480)}))
    picam2.start()
    
    print("⌛ Warming up... displaying camera feed for 2 seconds")
    warmup_start = time.time()
    while time.time() - warmup_start < 2:
        frame = picam2.capture_array()
        cv2.imshow("Palm Detection", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            picam2.stop()
            cv2.destroyAllWindows()
            return None

    print("🔍 Starting palm detection...")

    while True:
        frame = picam2.capture_array()
        if detect_palm(frame):
            print("✅ Palm detected! Waiting 2 seconds before capturing...")
            time.sleep(2)
            frame = picam2.capture_array()
            cv2.imwrite(PALM_IMAGE_PATH, frame)
            print(f"📸 Image saved as {PALM_IMAGE_PATH}")
            break

        cv2.imshow("Palm Detection", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    picam2.stop()
    cv2.destroyAllWindows()

    with open(PALM_IMAGE_PATH, "rb") as f:
        return ("palm.jpg", f.read(), "image/jpeg")

def capture_qr():
    picam2 = Picamera2()
    config = picam2.create_preview_configuration(main={"size": (640, 480)})
    picam2.configure(config)
    picam2.start()
    time.sleep(2)  # Warm-up time

    print("Scanning for QR code... Press Ctrl+C to exit.")

    while True:
        frame = picam2.capture_array()

        # Decode QR codes
        qr_codes = decode(frame)
        for qr in qr_codes:
            qr_data = qr.data.decode('utf-8')
            print(f"QR Code detected: {qr_data}")

            # Draw bounding box
            pts = qr.polygon
            if len(pts) == 4:
                pts = [(pt.x, pt.y) for pt in pts]
                cv2.polylines(frame, [np.array(pts)], isClosed=True, color=(0, 255, 0), thickness=2)

            # Display the decoded text
            cv2.putText(frame, qr_data, (qr.rect.left, qr.rect.top - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 255), 2)

            cv2.imshow("QR Scanner", frame)
            cv2.waitKey(1000)
            cv2.destroyAllWindows()
            picam2.close()
            return qr_data

        cv2.imshow("QR Scanner", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cv2.destroyAllWindows()
    picam2.close()
    return None
    ##backup
    ##print("[Pi-Sub-Server] Simulating QR code capture and decoding...")
    ##characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    ##user_id = "uZsYmasM5B3dVXTYjt3J"
    ##print(f"[Pi-Sub-Server] Generated simulated QR User ID: {user_id}")
    ##return user_id

# --- Flask Routes ---

@app.route("/registerPalm", methods=["POST"])
def sub_register_palm():
    """
    Sub-server endpoint for registration.
    Receives nothing from the client.
    Generates a user ID via capture_qr() and an image via capture_palm().
    Forwards these to the main server's /registerPalm endpoint.
    """
    print("\n[Pi-Sub-Server] Received request on /registerPalm")

    # Generate user ID from simulated QR code capture
    user_id = capture_qr()
    if not user_id:
        return jsonify({"error": "Failed to generate user ID from QR capture"}), 500

    # Capture palm image (returns filename, raw_bytes, content_type)
    image_file_data = capture_palm()
    if not image_file_data:
        return jsonify({"error": "Failed to capture palm image"}), 500

    # Prepare data for the main server
    # requests will automatically handle the multipart/form-data encoding
    # image_file_data is already in the (filename, raw_bytes, content_type) format
    files = {'image': image_file_data}
    data = {'token': user_id}

    print(f"[Pi-Sub-Server] Forwarding to main server /registerPalm with token: {user_id}")
    try:
        # Make the POST request to the main server
        response = requests.post(f"{MAIN_SERVER_URL}/registerPalm", data=data, files=files)

        # Return the main server's response to the client
        print(f"[Pi-Sub-Server] Main server response status: {response.status_code}")
        print(f"[Pi-Sub-Server] Main server response body: {response.text}")
        return jsonify(response.json()), response.status_code
    except requests.exceptions.ConnectionError:
        return jsonify({"error": f"Could not connect to main server at {MAIN_SERVER_URL}. Is it running?"}), 503
    except json.JSONDecodeError:
        return jsonify({"error": f"Main server response was not valid JSON: {response.text}"}), 500
    except Exception as e:
        print(f"[Pi-Sub-Server] Error forwarding /registerPalm request: {e}")
        return jsonify({"error": f"Internal sub-server error: {str(e)}"}), 500

@app.route("/scanPalm", methods=["POST"])
def sub_scan_palm():
    """
    Sub-server endpoint for scanning.
    Receives a JSON body with {"merchant": merchant_name, "amount": amount} from the client.
    Captures an image via capture_palm().
    Forwards the merchant/amount (as separate form fields) and a dummy token JSON string
    to the main server's /scanPalm endpoint.
    """
    print("\n[Pi-Sub-Server] Received request on /scanPalm")

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
        print(f"[Pi-Sub-Server] Error parsing client JSON for /scanPalm: {e}")
        return jsonify({"error": "Invalid JSON format or missing data in request body"}), 400

    # Capture palm image (returns filename, raw_bytes, content_type)
    image_file_data = capture_palm()
    if not image_file_data:
        return jsonify({"error": "Failed to capture palm image"}), 500

    # Prepare data for the main server's /scanPalm endpoint
    # image_file_data is already in the (filename, raw_bytes, content_type) format
    dummy_token_json_string = json.dumps({"dummy_key": "dummy_value"})

    files = {'image': image_file_data}
    data = {
        'token': dummy_token_json_string, # Required by main server's parsing, but content not used for merchant/amount
        'merchant': merchant,             # Actual merchant name
        'amount': amount_str              # Actual amount
    }

    print(f"[Pi-Sub-Server] Forwarding to main server /scanPalm with merchant: {merchant}, amount: {amount_str}")
    try:
        # Make the POST request to the main server
        response = requests.post(f"{MAIN_SERVER_URL}/scanPalm", data=data, files=files)

        # Return the main server's response to the client
        print(f"[Pi-Sub-Server] Main server response status: {response.status_code}")
        print(f"[Pi-Sub-Server] Main server response body: {response.text}")
        return jsonify(response.json()), response.status_code
    except requests.exceptions.ConnectionError:
        return jsonify({"error": f"Could not connect to main server at {MAIN_SERVER_URL}. Is it running?"}), 503
    except json.JSONDecodeError:
        return jsonify({"error": f"Main server response was not valid JSON: {response.text}"}), 500
    except Exception as e:
        print(f"[Pi-Sub-Server] Error forwarding /scanPalm request: {e}")
        return jsonify({"error": f"Internal sub-server error: {str(e)}"}), 500

if __name__ == "__main__":
    print(f"Raspberry Pi Sub-server starting on port 5001. Main server URL: {MAIN_SERVER_URL}")
    app.run(host="0.0.0.0", port=5001, debug=True)
