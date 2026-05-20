"""
Firebase Realtime Database Service

Handles initialization and CRUD operations for the Firebase Realtime Database.
All sensor readings, breaches, and shipment data flow through here.
"""

import firebase_admin
from firebase_admin import credentials, db
from loguru import logger

from app.config import settings


class FirebaseService:
    """Manages the Firebase Realtime Database connection and operations."""

    def __init__(self):
        self._initialized = False

    def initialize(self):
        """Initialize Firebase Admin SDK with service account credentials."""
        if self._initialized:
            return

        try:
            cred = credentials.Certificate(settings.firebase_service_account_path)
            firebase_admin.initialize_app(cred, {
                "databaseURL": settings.firebase_database_url,
            })
            self._initialized = True
            logger.info("Firebase Admin SDK initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {e}")
            raise

    # ── Read Operations ────────────────────────────────────────

    def get_ref(self, path: str) -> db.Reference:
        """Get a Firebase database reference for the given path."""
        return db.reference(path)

    def get_data(self, path: str) -> dict | None:
        """Read data from a Firebase path."""
        ref = self.get_ref(path)
        return ref.get()

    def get_latest_readings(self, truck_id: str) -> dict | None:
        """Get the most recent sensor readings for a truck."""
        return self.get_data(f"/sensor_readings/{truck_id}")

    def get_all_trucks(self) -> dict | None:
        """Get sensor data for all trucks."""
        return self.get_data("/sensor_readings")

    def get_shipment(self, shipment_id: str) -> dict | None:
        """Get shipment details by ID."""
        return self.get_data(f"/shipments/{shipment_id}")

    def get_shipments_by_truck(self, truck_id: str) -> dict | None:
        """Get all shipments assigned to a truck."""
        ref = db.reference("/shipments")
        # Firebase query: orderByChild + equalTo
        results = ref.order_by_child("truck_id").equal_to(truck_id).get()
        return results

    # ── Write Operations ───────────────────────────────────────

    def push_sensor_reading(self, truck_id: str, reading: dict) -> str:
        """Push a new sensor reading and return the generated key."""
        ref = self.get_ref(f"/sensor_readings/{truck_id}")
        new_ref = ref.push(reading)
        return new_ref.key

    def save_breach(self, breach_id: str, breach_data: dict):
        """Save or update a breach event."""
        ref = self.get_ref(f"/breaches/{breach_id}")
        ref.set(breach_data)
        logger.info(f"Breach {breach_id} saved to Firebase")

    def update_breach(self, breach_id: str, updates: dict):
        """Partially update a breach event."""
        ref = self.get_ref(f"/breaches/{breach_id}")
        ref.update(updates)

    def save_shipment(self, shipment_id: str, shipment_data: dict):
        """Save or update a shipment."""
        ref = self.get_ref(f"/shipments/{shipment_id}")
        ref.set(shipment_data)

    def update_shipment_status(self, shipment_id: str, status: str):
        """Update the status field of a shipment."""
        ref = self.get_ref(f"/shipments/{shipment_id}")
        ref.update({"status": status})

    def save_agent_response(self, breach_id: str, agent_name: str, response: dict):
        """Save an agent's response under the breach record."""
        ref = self.get_ref(f"/breaches/{breach_id}/agent_responses/{agent_name}")
        ref.set(response)

    def push_notification(self, notification: dict) -> str:
        """Push a notification to the notifications queue."""
        ref = self.get_ref("/notifications")
        new_ref = ref.push(notification)
        return new_ref.key

    # ── Listener ───────────────────────────────────────────────

    def listen(self, path: str, callback):
        """
        Attach a real-time listener to a Firebase path.
        The callback receives the event object with `data` and `path` fields.
        """
        ref = self.get_ref(path)
        ref.listen(callback)
        logger.info(f"Listening on Firebase path: {path}")
