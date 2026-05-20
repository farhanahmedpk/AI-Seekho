"""
reset_firebase.py
=================
Resets Firebase Realtime Database to a clean demo state.
Run this BEFORE every demo attempt to ensure fresh before/after state.

What it does:
    1. Clears /incidents completely
    2. Resets TRK-004, TRK-007, TRK-009 to breach state
    3. Resets SHP-004 status back to "in_transit"
    4. Updates /system_status timestamps and breach count

Usage:
    python data/reset_firebase.py
"""

import os
import sys
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, db
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(PROJECT_ROOT)
load_dotenv(os.path.join(PROJECT_ROOT, ".env"))

from firebase_config import initialize_firebase

CRED_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS",
    os.path.join(PROJECT_ROOT, "serviceAccountKey.json"),
)

DATABASE_URL = os.environ.get("FIREBASE_DATABASE_URL")

if not DATABASE_URL:
    print("[WARN] FIREBASE_DATABASE_URL is not set.")

if not os.path.exists(CRED_PATH):
    print(f"[WARN] Firebase credentials file not found at: {CRED_PATH}")

# ---------------------------------------------------------------------------
# Initialize Firebase
# ---------------------------------------------------------------------------

# Avoid re-initialization if already initialized (e.g. imported as module)
if not firebase_admin._apps:
    initialize_firebase(CRED_PATH, DATABASE_URL)

# ---------------------------------------------------------------------------
# Reset functions
# ---------------------------------------------------------------------------


def clear_incidents() -> None:
    """Clear all incidents — removes any alerts generated during previous demos."""
    ref = db.reference("/incidents")
    ref.set({})
    print("  [OK] Cleared /incidents")


def reset_breached_trucks() -> None:
    """Reset TRK-004, TRK-007, and TRK-009 to their breach demo states."""
    now = datetime.now(timezone.utc).isoformat()
    
    # TRK-004
    db.reference("/sensors/TRK-004").update({
        "current_temp": 12.5,
        "status": "breach",
        "threshold_temp": 8.0,
        "last_updated": now,
    })
    
    # TRK-007
    db.reference("/sensors/TRK-007").update({
        "current_temp": 11.0,
        "status": "breach",
        "threshold_temp": 8.0,
        "last_updated": now,
    })
    
    # TRK-009
    db.reference("/sensors/TRK-009").update({
        "current_temp": 9.5,
        "status": "breach",
        "threshold_temp": 8.0,
        "last_updated": now,
    })
    
    print("  [OK] Reset TRK-004, TRK-007, TRK-009 to breach state")


def reset_shipment_004() -> None:
    """Reset SHP-004 back to in_transit status."""
    ref = db.reference("/shipments/SHP-004")
    ref.update(
        {
            "status": "in_transit",
        }
    )
    print("  [OK] Reset SHP-004 -> in_transit")


def update_system_status() -> None:
    """Update system_status with reset timestamp."""
    ref = db.reference("/system_status")
    ref.update(
        {
            "last_seeded": datetime.now(timezone.utc).isoformat(),
            "active_breaches": 3,
            "demo_mode": True,
        }
    )
    print("  [OK] Updated /system_status")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 50)
    print("  ColdChain Demo Reset")
    print("=" * 50)
    print()
    print("Resetting database to demo state...")
    print()

    clear_incidents()
    reset_breached_trucks()
    reset_shipment_004()
    update_system_status()

    print()
    print("Database reset to demo state [OK]")
