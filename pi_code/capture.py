import cv2
import numpy as np
import requests
import time
from picamera2 import Picamera2
import onnxruntime as ort

# === CONFIG ===
MODEL_PATH = 'palm_detection_mediapipe_2023feb.onnx'
SERVER_URL = 'http://172.20.10.3:5001/upload'
INPUT_SIZE = 192
CONF_THRESHOLD = 1
SEND_INTERVAL = 2.0  # seconds between uploads
TRACKING_THRESHOLD = 30  # pixels movement to be considered "different"
STEADY_TIME_REQUIRED = 0 # seconds the hand must stay still before upload

# === INIT MODEL ===
print("[INFO] Loading ONNX palm detection model...")
ort_session = ort.InferenceSession(MODEL_PATH)

# === INIT CAMERA ===
picam2 = Picamera2()
picam2.configure(picam2.create_preview_configuration(main={"format": "RGB888", "size": (640, 480)}))
picam2.start()
last_sent_time = 0

# === TRACKING STATE ===
prev_box = None
steady_start_time = None

print("[INFO] Starting palm detection...")

# === MAIN LOOP ===
while True:
    frame = picam2.capture_array()
    orig_h, orig_w = frame.shape[:2]

    # Preprocess input
    resized = cv2.resize(frame, (INPUT_SIZE, INPUT_SIZE)).astype(np.float32)
    input_tensor = ((resized - 128) / 128).astype(np.float32)
    input_tensor = np.expand_dims(input_tensor, axis=0)  # Shape: [1, 192, 192, 3]

    # Run inference
    outputs = ort_session.run(None, {ort_session.get_inputs()[0].name: input_tensor})
    detections = outputs[0][0]  # Shape: [N, 18]

    palm_detected = False

    for det in detections:
        score = det[2]
        if score < CONF_THRESHOLD:
            continue

        palm_detected = True
        x_center, y_center, w, h = det[0], det[1], det[3], det[4]
        x0 = int((x_center - w / 2) * orig_w)
        y0 = int((y_center - h / 2) * orig_h)
        x1 = int((x_center + w / 2) * orig_w)
        y1 = int((y_center + h / 2) * orig_h)

        # Clamp
        x0 = max(0, x0)
        y0 = max(0, y0)
        x1 = min(orig_w, x1)
        y1 = min(orig_h, y1)

        # Draw bounding box
        cv2.rectangle(frame, (x0, y0), (x1, y1), (0, 255, 0), 2)

        # Track movement
        new_box = (x0, y0, x1, y1)
        now = time.time()

        # If no previous box or it moved significantly
        if prev_box is None:
            steady_start_time = now
            prev_box = new_box
        else:
            dx = abs(prev_box[0] - new_box[0]) + abs(prev_box[2] - new_box[2])
            dy = abs(prev_box[1] - new_box[1]) + abs(prev_box[3] - new_box[3])
            movement = dx + dy

            if movement > 30:  # less strict
                steady_start_time = now
                prev_box = new_box

        # Allow upload if steady for 1 sec and time gap passed
        if steady_start_time and now - steady_start_time > STEADY_TIME_REQUIRED and now - last_sent_time > SEND_INTERVAL:
            palm_crop = frame[y0:y1, x0:x1]
            if palm_crop.size > 0:
                _, img_encoded = cv2.imencode('.jpg', palm_crop)
                files = {'file': ('palm.jpg', img_encoded.tobytes(), 'image/jpeg')}
                try:
                    res = requests.post(SERVER_URL, files=files, timeout=3)
                    print(f"[{res.status_code}] Palm sent at {time.strftime('%X')}")
                    last_sent_time = now
                except Exception as e:
                    print("❌ Upload failed:", e)

        break  # only first valid detection

    # Display
    cv2.imshow("Palm Detection", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

# Cleanup
picam2.stop()
cv2.destroyAllWindows()
