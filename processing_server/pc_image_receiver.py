import os
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
import time
import json
import random

# === Firebase Init ===
# Ensure FIREBASE_CREDS environment variable is set with your Firebase service account key JSON
try:
    firebase_creds = json.loads(os.environ["FIREBASE_CREDS"])
    cred = credentials.Certificate(firebase_creds)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase initialized successfully.")
except KeyError:
    print("Error: FIREBASE_CREDS environment variable not set. Firebase will not function.")
    # You might want to exit or handle this more gracefully in a production app
except Exception as e:
    print(f"Error initializing Firebase: {e}")

# === Flask App Init ===
app = Flask(__name__)

# === Helper: Generate a fake vector ===
def GenerateVector():
    """Generates a random 128-dimension vector."""
    return [round(random.uniform(0, 1), 8) for _ in range(128)]

@app.route("/registerPalm", methods=["POST"])
def register_palm():
    """
    Handles user registration requests with a token (UID) and an image.
    Expects 'token' as form data and an 'image' file.
    The 'token' will be used as the document ID in Firestore.
    The image is acknowledged but not stored in Firestore directly due to size limits.
    A 'palmHash' (generated vector) is stored for the user.
    """
    token = request.form.get("token")
    image = request.files.get("image")

    # Validate incoming data
    if not token:
        return jsonify({"error": "Missing 'token' in form data"}), 400
    if not image:
        return jsonify({"error": "Missing 'image' file"}), 400
    if image.filename == '':
        return jsonify({"error": "No selected image file"}), 400

    try:
        # Generate a fake vector for palmHash
        vector = GenerateVector()

        # Update or create the user document in Firestore with the palmHash
        # Using .set(..., merge=True) will create the document if it doesn't exist
        # or update it if it does, without overwriting other fields.
        user_ref = db.collection("users").document(token)
        user_ref.set({"palmHash": vector}, merge=True)

        print(f"✅ Registered vector for {token}")
        return jsonify({"message": "Registration OK", "uid": token}), 200
    except Exception as e:
        print(f"❌ Error in registerPalm: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/scanPalm", methods=["POST"])
def scan_palm():
    """
    Handles payment scanning requests.
    Expects 'token' (a JSON string containing merchant and amount), and an 'image' file.
    Retrieves user's default account and records a transaction in Firestore.
    """
    try:
        token_raw = request.form.get("token")  # This is expected to be a JSON string
        image = request.files.get("image")

        # Validate incoming data
        if not token_raw:
            return jsonify({"error": "Missing 'token' in form data"}), 400
        if not image:
            return jsonify({"error": "Missing 'image' file"}), 400
        if image.filename == '':
            return jsonify({"error": "No selected image file"}), 400

        # Parse the JSON string from the 'token' form field
        try:
            token_data = json.loads(token_raw)
        except json.JSONDecodeError:
            return jsonify({"error": "Invalid JSON format for 'token'"}), 400

        # Extract merchant and amount from the parsed token data
        merchant = token_data.get("merchant")
        amount_str = token_data.get("amount")

        if not merchant:
            return jsonify({"error": "Missing 'merchant' in 'token' JSON"}), 400
        if not amount_str:
            return jsonify({"error": "Missing 'amount' in 'token' JSON"}), 400

        try:
            amount = float(amount_str)
            if amount <= 0:
                return jsonify({"error": "Amount must be a positive number"}), 400
        except ValueError:
            return jsonify({"error": "Invalid 'amount' format in 'token' JSON. Must be a number."}), 400

        # --- Hardcoded user ID (as per your provided code) ---
        # In a real application, this user_id would likely come from an authentication
        # mechanism (e.g., from a decoded JWT token or a session).
        user_id = "uZsYmasM5B3dVXTYjt3J" # Replace with dynamic user ID in production

        # Retrieve user document to get the default account
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404

        user_data = user_doc.to_dict()
        default_acc = user_data.get("default_acc")
        if not default_acc:
            return jsonify({"error": "No default account set for this user"}), 400

        # Add transaction to the specified linked account's transactions subcollection
        transaction_collection_ref = db.collection("users") \
            .document(user_id) \
            .collection("linkedAccounts") \
            .document(default_acc) \
            .collection("transactions")

        categories = ['Groceries', 'Food & Drink', 'Bills', 'Transport', 'Others']
        random_category = random.choice(categories)

        transaction_collection_ref.add({
            "amount": amount,
            "merchant": merchant,
            "category": random_category,
            "status": "success",
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        print(f"✅ Transaction recorded for user {user_id} in account {default_acc}: Merchant={merchant}, Amount={amount}")
        return jsonify({"message": "Payment OK"}), 200

    except Exception as e:
        print(f"❌ Error in scanPalm: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # The server will run on all available network interfaces on port 8080.
    # For local development, you can access it via http://127.0.0.1:8080/
    app.run(host="0.0.0.0", port=8080)
