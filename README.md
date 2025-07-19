# PayPalm – Device-Free Payments

A palm biometric payment system that works without phones, cards, or wallets — just your hand.  
Built during **PayNet 2025** by **Team 3 Peas**.

## Table of Contents

- [Features](#features)
- [Setup Instructions](#setup-instructions)
- [How It Works](#how-it-works)
- [Tech Stack](#tech-stack)
- [License](#license)

---

## Features

- Real-time palm image capture with Picamera2
- QR code scanning with OpenCV
- Palm detection using ONNX model (MediaPipe or YOLOv4)
- Server communication via Flask API
- Simple merchant interface for registering and payment

---

## Setup Instructions

```bash
# Clone the repo
git clone https://github.com/Sseankzs/palmpay.git
cd palmpay

# Run the server
python3 server.py
Install dependencies

# Run the pi code
python server.py
Install dependencies

# Run the merchant checkout app
checkout.html

# Clone and run the mobile app
```
## 📖 Learn More
- [Financial Projections & Charts](./Paypalm_Financial_Projections/README.md)
- [User App Screens & Features](./paypalm_mobile/README.md)

## How It Works
1. Merchant app sends a request to the Pi server (/register or /scanPalm).

2. Pi opens the camera and runs capture.py to scan a QR and/or palm.

3. The image is processed using an ONNX model (e.g. MediaPipe or YOLOv4).

4. Data is sent to the main Flask cloud server for registration or payment verification.

5. Server sends back result (success/failure).

## Tech Stack
- Raspberry Pi 5
- Python 3.10
- Flask
- Picamera2
- OpenCV
- ONNX Runtime 
- HTML/CSS (merchant interface)

## 👥 Team 3 Peas

- [@Sseankzs](https://github.com/Sseankzs)  
- [@MclarenFrankl1n](https://github.com/MclarenFrankl1n)  
- [@huiying888](https://github.com/huiying888)



## License
MIT License — free to use and modify.
