from flask import Flask, request, jsonify
import time

app = Flask(__name__)

@app.route("/registerPalm", methods=["POST"])
def register_palm():
    token = request.form.get("token")
    image = request.files.get("image")

    if not token or not image:
        return jsonify({"error": "Missing token or image"}), 400

    print("✅ Registering palm for token:", token)
    print("Image size (bytes):", len(image.read()))
    time.sleep(1)
    return jsonify({"message": "Registration OK"}), 200

@app.route("/scanPalm", methods=["POST"])
def scan_palm():
    token = request.form.get("token")
    image = request.files.get("image")

    if not token or not image:
        return jsonify({"error": "Missing token or image"}), 400

    print("✅ Scanning palm for transaction:", token)
    print("Image size (bytes):", len(image.read()))
    time.sleep(1)
    return jsonify({"message": "Payment OK"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
