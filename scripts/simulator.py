"""
Sensor Data Simulator

Generates realistic sensor readings and pushes them to Firebase.
Periodically injects temperature breaches for demo/testing purposes.

Usage:
    python -m scripts.simulator
"""

import random
import time
import json
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, db

# ── Configuration ──────────────────────────────────────────────

FIREBASE_SERVICE_ACCOUNT = "serviceAccountKey.json"
FIREBASE_DATABASE_URL = "https://your-project-id.firebaseio.com"  # Update this

# Simulated trucks and their sensors
TRUCKS = {
    "TRUCK-001": {
        "sensors": ["SENSOR-001A", "SENSOR-001B"],
        "route": "Chicago → New York",
        "cargo": "Vaccines",
    },
    "TRUCK-002": {
        "sensors": ["SENSOR-002A"],
        "route": "Los Angeles → San Francisco",
        "cargo": "Dairy Products",
    },
    "TRUCK-003": {
        "sensors": ["SENSOR-003A", "SENSOR-003B"],
        "route": "Houston → Miami",
        "cargo": "Seafood",
    },
}

# Normal temperature range (°C) for cold chain
NORMAL_TEMP_MIN = 2.0
NORMAL_TEMP_MAX = 6.0

# Breach probability per reading (10% chance for demo purposes)
BREACH_PROBABILITY = 0.10


def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_DATABASE_URL})
        print("✅ Firebase initialized")
    except ValueError:
        # Already initialized
        print("ℹ️  Firebase already initialized")


def generate_normal_reading(truck_id: str, sensor_id: str) -> dict:
    """Generate a normal temperature reading within safe bounds."""
    return {
        "sensor_id": sensor_id,
        "truck_id": truck_id,
        "temperature": round(random.uniform(NORMAL_TEMP_MIN, NORMAL_TEMP_MAX), 1),
        "humidity": round(random.uniform(40.0, 60.0), 1),
        "timestamp": datetime.utcnow().isoformat(),
        "location": {
            "lat": round(random.uniform(25.0, 48.0), 4),
            "lng": round(random.uniform(-122.0, -74.0), 4),
        },
    }


def generate_breach_reading(truck_id: str, sensor_id: str) -> dict:
    """Generate a temperature reading that violates thresholds."""
    # Randomly choose between high and low breach
    if random.random() > 0.5:
        # High temperature breach
        temp = round(random.uniform(10.0, 25.0), 1)
    else:
        # Low temperature breach (freezer malfunction)
        temp = round(random.uniform(-35.0, -26.0), 1)

    return {
        "sensor_id": sensor_id,
        "truck_id": truck_id,
        "temperature": temp,
        "humidity": round(random.uniform(30.0, 80.0), 1),
        "timestamp": datetime.utcnow().isoformat(),
        "location": {
            "lat": round(random.uniform(25.0, 48.0), 4),
            "lng": round(random.uniform(-122.0, -74.0), 4),
        },
    }


def seed_shipments():
    """Seed sample shipment data into Firebase."""
    shipments = {
        "SHIP-001": {
            "shipment_id": "SHIP-001",
            "truck_id": "TRUCK-001",
            "product_type": "Vaccines",
            "quantity": 500,
            "origin": "Chicago",
            "destination": "New York",
            "required_temp_min": 2.0,
            "required_temp_max": 8.0,
            "status": "in_transit",
            "loaded_at": "2026-05-13T08:00:00",
            "estimated_arrival": "2026-05-14T18:00:00",
        },
        "SHIP-002": {
            "shipment_id": "SHIP-002",
            "truck_id": "TRUCK-002",
            "product_type": "Dairy Products",
            "quantity": 200,
            "origin": "Los Angeles",
            "destination": "San Francisco",
            "required_temp_min": 1.0,
            "required_temp_max": 5.0,
            "status": "in_transit",
            "loaded_at": "2026-05-13T06:00:00",
            "estimated_arrival": "2026-05-13T14:00:00",
        },
        "SHIP-003": {
            "shipment_id": "SHIP-003",
            "truck_id": "TRUCK-003",
            "product_type": "Seafood",
            "quantity": 150,
            "origin": "Houston",
            "destination": "Miami",
            "required_temp_min": -2.0,
            "required_temp_max": 2.0,
            "status": "in_transit",
            "loaded_at": "2026-05-13T05:00:00",
            "estimated_arrival": "2026-05-14T08:00:00",
        },
    }

    ref = db.reference("/shipments")
    ref.set(shipments)
    print(f"📦 Seeded {len(shipments)} shipments")


def push_reading(reading: dict):
    """Push a sensor reading to Firebase."""
    truck_id = reading["truck_id"]
    ref = db.reference(f"/sensor_readings/{truck_id}")
    key = ref.push(reading).key
    status = "🔴 BREACH" if reading["temperature"] > 8 or reading["temperature"] < -25 else "🟢 Normal"
    print(
        f"  {status} | {reading['sensor_id']} → {reading['temperature']}°C "
        f"| Key: {key}"
    )


def run_simulator(duration_seconds: int = 120, interval: int = 5):
    """
    Run the simulator for a given duration.

    Args:
        duration_seconds: How long to run the simulation.
        interval: Seconds between reading batches.
    """
    initialize_firebase()
    seed_shipments()

    print(f"\n🚛 Starting sensor simulation ({duration_seconds}s, every {interval}s)")
    print("=" * 60)

    start_time = time.time()
    reading_count = 0

    while time.time() - start_time < duration_seconds:
        print(f"\n⏱  Batch at {datetime.utcnow().isoformat()}")

        for truck_id, info in TRUCKS.items():
            for sensor_id in info["sensors"]:
                # Decide whether to generate a breach
                if random.random() < BREACH_PROBABILITY:
                    reading = generate_breach_reading(truck_id, sensor_id)
                else:
                    reading = generate_normal_reading(truck_id, sensor_id)

                push_reading(reading)
                reading_count += 1

        time.sleep(interval)

    print(f"\n{'='*60}")
    print(f"✅ Simulation complete — {reading_count} readings generated")


if __name__ == "__main__":
    run_simulator()
