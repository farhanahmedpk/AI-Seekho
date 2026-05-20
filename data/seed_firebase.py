"""
seed_firebase.py
================
Seeds Firebase Realtime Database with mock truck and shipment data.
Run this once to populate the database for demo purposes.

Usage:
    python data/seed_firebase.py

Prerequisites:
    - Place your Firebase service account key JSON file in the project root
      and set the FIREBASE_CREDENTIALS env var, OR name it 'serviceAccountKey.json'
    - Set FIREBASE_DATABASE_URL env var or update the default below
"""

import json
import os
import sys
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, db
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Load .env from project root
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(PROJECT_ROOT)
load_dotenv(os.path.join(PROJECT_ROOT, ".env"))

from firebase_config import initialize_firebase

# Firebase credentials path (service account JSON)
CRED_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS",
    os.path.join(PROJECT_ROOT, "serviceAccountKey.json"),
)

# Firebase Realtime Database URL
DATABASE_URL = os.environ.get("FIREBASE_DATABASE_URL")

if not DATABASE_URL:
    print("[WARN] FIREBASE_DATABASE_URL is not set.")

if not os.path.exists(CRED_PATH):
    print(f"[WARN] Firebase credentials file not found at: {CRED_PATH}")

# ---------------------------------------------------------------------------
# Initialize Firebase
# ---------------------------------------------------------------------------

initialize_firebase(CRED_PATH, DATABASE_URL)

# ---------------------------------------------------------------------------
# Load mock data
# ---------------------------------------------------------------------------

DATA_DIR = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(DATA_DIR, "mock_trucks.json"), "r", encoding="utf-8") as f:
    trucks = json.load(f)

with open(os.path.join(DATA_DIR, "mock_shipments.json"), "r", encoding="utf-8") as f:
    shipments = json.load(f)

# ---------------------------------------------------------------------------
# Seed functions
# ---------------------------------------------------------------------------


def seed_sensors(trucks_data: list) -> None:
    """Upload truck/sensor data to /sensors, keyed by truck_id."""
    ref = db.reference("/sensors")
    sensors_dict = {truck["truck_id"]: truck for truck in trucks_data}
    ref.set(sensors_dict)
    print(f"Uploaded {len(trucks_data)} trucks to /sensors [OK]")


def seed_shipments(shipments_data: list) -> None:
    """Upload shipment data to /shipments, keyed by shipment_id."""
    ref = db.reference("/shipments")
    shipments_dict = {s["shipment_id"]: s for s in shipments_data}
    ref.set(shipments_dict)
    print(f"Uploaded {len(shipments_data)} shipments to /shipments [OK]")


def seed_incidents() -> None:
    """Create an empty /incidents node."""
    ref = db.reference("/incidents")
    ref.set({})
    print("Created empty /incidents node [OK]")


def seed_system_status(total_trucks: int, active_breaches: int) -> None:
    """Create /system_status node with metadata."""
    ref = db.reference("/system_status")
    ref.set(
        {
            "last_seeded": datetime.now(timezone.utc).isoformat(),
            "total_trucks": total_trucks,
            "active_breaches": active_breaches,
            "system_version": "1.0.0",
            "demo_mode": True,
        }
    )
    print("System status initialized [OK]")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 50)
    print("  ColdChain Firebase Seeder")
    print("=" * 50)
    print()

    # Count breaches from the data
    breach_count = sum(1 for t in trucks if t.get("status") == "breach")

    seed_sensors(trucks)
    seed_shipments(shipments)
    seed_incidents()
    seed_system_status(total_trucks=len(trucks), active_breaches=breach_count)

    print()
    print("Database seeded successfully. Ready for demo.")
