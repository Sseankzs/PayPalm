from flask import Flask, request
import os
import time

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return '❌ No file part in request', 400

    file = request.files['file']
    if file.filename == '':
        return '❌ No selected file', 400

    # Create a timestamped filename
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    extension = os.path.splitext(file.filename)[1] or '.jpg'
    filename = f"palm_{timestamp}{extension}"

    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)
    print(f"✅ File saved to {filepath}")
    return '✅ Upload successful', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
