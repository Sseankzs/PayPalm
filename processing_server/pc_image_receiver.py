import os
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
import time
import json
import random

# === Firebase Init ===
firebase_creds = json.loads(os.environ["FIREBASE_CREDS"])
cred = credentials.Certificate(firebase_creds)
firebase_admin.initialize_app(cred)
db = firestore.client()

# === Flask App Init ===
app = Flask(__name__)

# === Helper: Generate a fake vector ===
def GenerateVector():
    return [round(random.uniform(0, 1), 8) for _ in range(128)]

@app.route("/registerPalm", methods=["POST"])
def register_palm():
    token = request.form.get("token")
    image = request.files.get("image")

    if not token or not image:
        return jsonify({"error": "Missing token or image"}), 400

    try:
        vector = GenerateVector()
        db.collection("users").document(token).update({"palmHash": vector})
        print(f"✅ Registered vector for {token}")
        return jsonify({"message": "Registration OK"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/scanPalm", methods=["POST"])
def scan_palm():
    try:
        token_raw = request.form.get("token")  # This is a JSON string
        image = request.files.get("image")

        if not token_raw or not image:
            return jsonify({"error": "Missing token or image"}), 400

        # Parse the JSON string
        token = json.loads(token_raw)

        merchant = request.form.get("merchant")
        amount = request.form.get("amount")

        if not amount or not merchant:
            return jsonify({"error": "Missing amount or merchant in token"}), 400

        # Hardcoded user ID (update later)
        user_id = "uZsYmasM5B3dVXTYjt3J"

        # Retrieve user and default account
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404

        user_data = user_doc.to_dict()
        default_acc = user_data.get("default_acc")
        if not default_acc:
            return jsonify({"error": "No default account set"}), 400

        # Add transaction
        transaction_ref = db.collection("users") \
            .document(user_id) \
            .collection("linkedAccounts") \
            .document(default_acc) \
            .collection("transactions")

        transaction_ref.add({
            "amount": amount,
            "merchant": merchant,
            "category": "Food & Drinks",  # Hardcoded
            "status": "success",
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        print(f"✅ Transaction recorded for {user_id} -> {default_acc}")
        return jsonify({"message": "Payment OK"}), 200

    except Exception as e:
        print("❌ Error in scanPalm:", e)
        return jsonify({"error": str(e)}), 500
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
