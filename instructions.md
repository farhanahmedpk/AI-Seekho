# ColdGuard AI — Setup & Local Execution Guide

This document provides step-by-step instructions on how to install, configure, seed, run, and test both the Python FastAPI backend and the Flutter mobile application locally on a Windows platform.

---

## 📋 Prerequisites

Before proceeding, ensure you have the following installed on your system:
- **Python 3.10+** (with `pip` and virtual environment support)
- **Flutter SDK 3.19+** (configured for Android/iOS development or Chrome Web execution)
- **Node.js / npm** (Optional, only if using third-party mock proxies)
- **A Firebase Project** (specifically Firebase Realtime Database)

---

## 🐍 1. Backend Setup (FastAPI & Agents)

Navigate to the project root directory (`F:\AI Seekho Project`):

### 1.1 Create and Activate a Virtual Environment
Run the following commands in PowerShell or CMD to isolate your Python dependencies:
```powershell
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On Windows PowerShell:
.venv\Scripts\Activate.ps1
# On Windows CMD:
.venv\Scripts\activate.bat
```

### 1.2 Install Python Dependencies
Install the required packages listed in `requirements.txt`:
```bash
pip install -r requirements.txt
```
*(Note: Pillow was installed successfully to resolve Android resource packaging formats).*

### 1.3 Configure Environment Variables (`.env`)
Create a `.env` file in the root directory and populate it with your specific credentials:
```env
# ── Firebase Configurations ───────────────────────────────────────────────────
FIREBASE_DATABASE_URL=https://your-firebase-database-id.firebaseio.com/
FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json

# ── OpenRouter / LLM Configurations ───────────────────────────────────────────
# Rotation Keys (Primary, Secondary, and Tertiary fallback)
OPENROUTER_API_KEY=your_primary_openrouter_api_key
OPENROUTER_API_KEY_2=your_secondary_openrouter_api_key
OPENROUTER_API_KEY_3=your_tertiary_openrouter_api_key

# Enable mock LLM parsing for offline/no-token scenarios (true/false)
MOCK_LLM=false
```

### 1.4 Seed the Firebase Realtime Database
Before running the backend, seed initial telemetry data (representing 15 Pakistani regional transit trucks, sensor paths, and loaded active cargo shipments):
```bash
python -m scripts.seed_data
```
**Expected Output:**
```text
-- Seeding data (Pakistan Region) -----------------
[TRUCK] Seeded 15 trucks at /sensors
   [BREACH] TRK-004 -> 12.5C (status set to breach)
   [BREACH] TRK-007 -> 11.0C (status set to breach)
   [BREACH] TRK-009 -> 9.5C (status set to breach)
[SHIPMENT] Seeded 15 shipments at /shipments
[SENSOR] Seeded 15 sensor configs at /sensor_config

[OK] All seed data loaded successfully!
```

### 1.5 Run the FastAPI Server
Start the backend application using the runner script:
```bash
python run.py
```
By default, the server runs at **`http://localhost:8000`**. You can verify that it is online by navigating to the interactive API docs at [http://localhost:8000/docs](http://localhost:8000/docs).

---

## 💙 2. Mobile App Setup (Flutter)

Navigate to the `mobile` sub-folder:
```bash
cd mobile
```

### 2.1 Fetch Flutter Dependencies
Get all packages required by the application:
```bash
flutter pub get
```

### 2.2 Configure Local Backend Endpoint
Ensure the mobile application points to your local FastAPI server:
1. Open the Flutter app and navigate to **Settings** (gear icon on the top right).
2. Set the **Server URL** to `http://localhost:8000` (or `http://10.0.2.2:8000` if running on an Android Emulator).
3. Tap **Save**.

### 2.3 Run the Application
Launch the application on your target platform or emulator:
```bash
# To run on connected Android/iOS device/emulator:
flutter run

# To run on Chrome browser:
flutter run -d chrome
```

---

## 🧪 3. Local Verification & Testing

Once both systems are active, execute the following testing procedures to verify system features:

### 3.1 Test 1: Simulating a Structured Temperature Breach
Execute a simulated temperature breach for `TRK-004` (COVID-19 Vaccines, critical threshold: 8°C):
1. **Trigger via Mobile**: Navigate to the **Simulate** tab in the app and tap **"Trigger Breach (TRK-004)"**.
2. **Trigger via curl**: Alternatively, send a POST request directly to the backend:
   ```bash
   curl -X POST "http://localhost:8000/trigger-breach" -H "Content-Type: application/json" -d "{\"truck_id\": \"TRK-004\", \"temperature\": 12.5}"
   ```
3. **Observation**: Watch the live streaming agent trace on the Flutter UI. The status will transition from `idle` ➔ `confirmed` ➔ `quarantined` within seconds.

### 3.2 Test 2: Ingesting Unstructured Telemetry Logs
Feed a raw, conversational text log to verify natural language parsing and downstream execution:
1. Send a POST request containing unstructured driver text:
   ```bash
   curl -X POST "http://localhost:8000/analyze-unstructured" -H "Content-Type: application/json" -d "{\"text\": \"Driver on TRK-009 reports that the meat container refrigeration unit failed near Multan. Current temperature inside is reading 9.5 degrees C.\"}"
   ```
2. **Observation**: The backend parses the truck identifier (`TRK-009`), recognizes the temperature breach (+9.5°C), extracts the context, and launches the entire 4-Agent orchestrator pipeline.

### 3.3 Test 3: Running a Bulk Autonomous Resolution
Validate the synchronous background execution server stability:
1. Tap the **"Resolve All Breaches"** button on the Mobile dashboard header.
2. The FastAPI backend triggers all active pipelines simultaneously via `asyncio.create_task()` (preventing API event-loop blocks).
3. The dashboard polls the sensors endpoint continuously until all 3 breaches are resolved, showing a premium animated modal detailing saved PKR valuation and exact elapsed seconds.
