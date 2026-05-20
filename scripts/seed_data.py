"""
Firebase Data Seeder

Populates Firebase Realtime Database with:
- 10 trucks (TRK-001 to TRK-010) at /sensors
- Matching shipments at /shipments

TRK-004, TRK-007 and TRK-009 are set to breach temperatures
(12.5°C, 11.0°C, 9.5°C respectively) for demo purposes.

Usage:
    python -m scripts.seed_data
"""

import os
import random
import sys
from datetime import datetime, timezone, timedelta

import firebase_admin
from firebase_admin import credentials, db
from dotenv import load_dotenv

# Add project root to sys.path for module imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# ── Load env ───────────────────────────────────────────────────
load_dotenv()

FIREBASE_SERVICE_ACCOUNT = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT_PATH", "serviceAccountKey.json"
)
FIREBASE_DATABASE_URL = os.getenv("FIREBASE_DATABASE_URL")


def initialize_firebase():
    """Initialize Firebase Admin SDK (idempotent)."""
    if firebase_admin._apps:
        print("[INFO] Firebase already initialized")
        return

    if not FIREBASE_DATABASE_URL:
        print("[ERROR] FIREBASE_DATABASE_URL is not set.")
        print("Please ensure it is in your .env file.")
        sys.exit(1)

    if not os.path.exists(FIREBASE_SERVICE_ACCOUNT):
        print(f"[ERROR] Service account file not found: {FIREBASE_SERVICE_ACCOUNT}")
        sys.exit(1)

    try:
        cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_DATABASE_URL})
        print("[OK] Firebase initialized")
    except Exception as e:
        print(f"[ERROR] Failed to initialize Firebase: {e}")
        sys.exit(1)


# ==============================================================================
#  Truck / Sensor Seed Data
# ==============================================================================

TRUCKS = [
    {
        "truck_id": "TRK-001",
        "driver_name": "Ahmed Raza",
        "cargo_type": "vaccines",
        "origin": "Karachi",
        "destination": "Lahore",
        "current_temp": 3.2,
    },
    {
        "truck_id": "TRK-002",
        "driver_name": "Bilal Hassan",
        "cargo_type": "dairy",
        "origin": "Lahore",
        "destination": "Islamabad",
        "current_temp": 4.1,
    },
    {
        "truck_id": "TRK-003",
        "driver_name": "Usman Khan",
        "cargo_type": "meat",
        "origin": "Islamabad",
        "destination": "Peshawar",
        "current_temp": 2.8,
    },
    {
        "truck_id": "TRK-004",
        "driver_name": "Tariq Mahmood",
        "cargo_type": "vaccines",
        "origin": "Peshawar",
        "destination": "Quetta",
        "current_temp": 12.5,
    },
    {
        "truck_id": "TRK-005",
        "driver_name": "Fatima Malik",
        "cargo_type": "dairy",
        "origin": "Quetta",
        "destination": "Multan",
        "current_temp": 3.9,
    },
    {
        "truck_id": "TRK-006",
        "driver_name": "Omar Sheikh",
        "cargo_type": "meat",
        "origin": "Multan",
        "destination": "Faisalabad",
        "current_temp": 4.5,
    },
    {
        "truck_id": "TRK-007",
        "driver_name": "Zara Ahmed",
        "cargo_type": "vaccines",
        "origin": "Faisalabad",
        "destination": "Karachi",
        "current_temp": 11.0,
    },
    {
        "truck_id": "TRK-008",
        "driver_name": "Hassan Ali",
        "cargo_type": "dairy",
        "origin": "Lahore",
        "destination": "Multan",
        "current_temp": 3.6,
    },
    {
        "truck_id": "TRK-009",
        "driver_name": "Sana Mirza",
        "cargo_type": "meat",
        "origin": "Karachi",
        "destination": "Islamabad",
        "current_temp": 9.5,
    },
    {
        "truck_id": "TRK-010",
        "driver_name": "Imran Qureshi",
        "cargo_type": "vaccines",
        "origin": "Islamabad",
        "destination": "Lahore",
        "current_temp": 4.0,
    },
    {
        "truck_id": "TRK-011",
        "driver_name": "Sajid Khan",
        "cargo_type": "seafood",
        "origin": "Gwadar",
        "destination": "Karachi",
        "current_temp": -15.0,
    },
    {
        "truck_id": "TRK-012",
        "driver_name": "Mariam Yousaf",
        "cargo_type": "blood samples",
        "origin": "Peshawar",
        "destination": "Islamabad",
        "current_temp": 4.5,
    },
    {
        "truck_id": "TRK-013",
        "driver_name": "Fahad Mustafa",
        "cargo_type": "frozen food",
        "origin": "Lahore",
        "destination": "Faisalabad",
        "current_temp": -18.2,
    },
    {
        "truck_id": "TRK-014",
        "driver_name": "Ayesha Rehman",
        "cargo_type": "dairy products",
        "origin": "Sahiwal",
        "destination": "Lahore",
        "current_temp": 3.0,
    },
    {
        "truck_id": "TRK-015",
        "driver_name": "Zubair Qureshi",
        "cargo_type": "insulin",
        "origin": "Karachi",
        "destination": "Multan",
        "current_temp": 5.2,
    },
]


def seed_sensors():
    """Seed 10 trucks with sensor data into /sensors."""
    now = datetime.now(timezone.utc)
    sensors = {}

    for truck in TRUCKS:
        truck_id = truck["truck_id"]
        sensors[truck_id] = {
            "truck_id": truck_id,
            "driver_name": truck["driver_name"],
            "cargo_type": truck["cargo_type"],
            "origin": truck["origin"],
            "destination": truck["destination"],
            "current_temp": truck["current_temp"],
            "threshold_temp": 8.0,
            "status": "breach" if truck_id in ("TRK-004", "TRK-007", "TRK-009") else "normal",
            "last_updated": (
                now - timedelta(minutes=random.randint(1, 30))
            ).isoformat(),
        }

    ref = db.reference("/sensors")
    ref.set(sensors)
    print(f"[TRUCK] Seeded {len(sensors)} trucks at /sensors")

    for tid in ("TRK-004", "TRK-007", "TRK-009"):
        temp = sensors[tid]["current_temp"]
        print(f"   [BREACH] {tid} -> {temp}C (status set to breach)")


CARGO_CONFIG = {
    "vaccines": {"required_temp_min": 2.0, "required_temp_max": 8.0, "base_value": 100000},
    "dairy":    {"required_temp_min": 1.0, "required_temp_max": 5.0, "base_value": 8000},
    "meat":     {"required_temp_min": -2.0, "required_temp_max": 4.0, "base_value": 25000},
    "seafood":        {"required_temp_min": -18.0, "required_temp_max": -10.0, "base_value": 35000},
    "blood samples":  {"required_temp_min": 2.0, "required_temp_max": 6.0, "base_value": 75000},
    "frozen food":    {"required_temp_min": -20.0, "required_temp_max": -12.0, "base_value": 15000},
    "dairy products": {"required_temp_min": 1.0, "required_temp_max": 5.0, "base_value": 9000},
    "insulin":        {"required_temp_min": 2.0, "required_temp_max": 8.0, "base_value": 120000},
}


def seed_shipments():
    """Seed one shipment per truck into /shipments."""
    now = datetime.now(timezone.utc)
    shipments = {}

    for i, truck in enumerate(TRUCKS, start=1):
        ship_id = f"SHIP-{i:03d}"
        cargo = truck["cargo_type"]
        cfg = CARGO_CONFIG[cargo]

        shipments[ship_id] = {
            "shipment_id": ship_id,
            "truck_id": truck["truck_id"],
            "product_type": cargo.capitalize(),
            "quantity": random.randint(100, 600),
            "origin": truck["origin"],
            "destination": truck["destination"],
            "required_temp_min": cfg["required_temp_min"],
            "required_temp_max": cfg["required_temp_max"],
            "status": "in_transit",
            "loaded_at": (now - timedelta(hours=random.randint(4, 24))).isoformat(),
            "estimated_arrival": (now + timedelta(hours=random.randint(6, 36))).isoformat(),
            "value_usd": cfg["base_value"] + random.randint(0, 20000),
        }

    ref = db.reference("/shipments")
    ref.set(shipments)
    print(f"[SHIPMENT] Seeded {len(shipments)} shipments at /shipments")


def seed_sensor_config():
    """Seed sensor hardware metadata at /sensor_config."""
    sensor_config = {}
    positions = ["front", "center", "rear"]

    for truck in TRUCKS:
        tid = truck["truck_id"]
        num = tid.split("-")[1]
        sensor_id = f"SENSOR-{num}A"
        sensor_config[sensor_id] = {
            "truck_id": tid,
            "position": random.choice(positions),
            "type": "temperature_humidity",
            "model": "ThermoProbe X200",
            "installed_at": "2026-01-15T00:00:00",
        }

    ref = db.reference("/sensor_config")
    ref.set(sensor_config)
    print(f"[SENSOR] Seeded {len(sensor_config)} sensor configs at /sensor_config")


if __name__ == "__main__":
    initialize_firebase()

    print("\n-- Seeding data (Pakistan Region) -----------------")
    seed_sensors()
    seed_shipments()
    seed_sensor_config()

    print("\n[OK] All seed data loaded successfully!")
    print("   * /sensors      - 15 trucks (TRK-001 -> TRK-015)")
    print("   * /shipments    - 15 shipments (SHIP-001 -> SHIP-015)")
    print("   * /sensor_config - 15 sensor hardware records")
    print("   * TRK-004, TRK-007 & TRK-009 are in BREACH state")
