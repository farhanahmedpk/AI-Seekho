"""
Firebase Realtime Database Configuration & Helper Functions

Standalone module for Firebase integration. Can be imported by any part
of the system — agents, scripts, or the FastAPI app.

Usage:
    from firebase_config import read_sensor_data, update_shipment_status, log_incident
"""

import os
import sys
import json
import random
import copy
from datetime import datetime, timezone, timedelta

import firebase_admin
from firebase_admin import credentials, db

# ══════════════════════════════════════════════════════════════
#  Mock Firebase Realtime Database
# ══════════════════════════════════════════════════════════════

class MockDatabase:
    def __init__(self, filename="firebase_mock_db.json"):
        # Make the path relative to the file's directory
        self.filename = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
        self.data = {}
        self.load()
        if not self.data:
            self.seed_default_data()

    def load(self):
        if os.path.exists(self.filename):
            try:
                with open(self.filename, "r", encoding="utf-8") as f:
                    self.data = json.load(f)
            except Exception as e:
                print(f"[WARN] Failed to load mock db: {e}")
                self.data = {}

    def save(self):
        try:
            with open(self.filename, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2)
        except Exception as e:
            print(f"[WARN] Failed to save mock db: {e}")

    def _normalize_sensors(self, data):
        if isinstance(data, dict):
            if "truck_id" in data:
                if "current_temp" not in data and "current_temp_celsius" in data:
                    data["current_temp"] = data["current_temp_celsius"]
                elif "current_temp_celsius" not in data and "current_temp" in data:
                    data["current_temp_celsius"] = data["current_temp"]
            for k, v in list(data.items()):
                self._normalize_sensors(v)
        elif isinstance(data, list):
            for item in data:
                self._normalize_sensors(item)

    def seed_default_data(self):
        mock_trucks_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "mock_trucks.json")
        mock_shipments_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "mock_shipments.json")
        
        now = datetime.now(timezone.utc)
        
        if os.path.exists(mock_trucks_path) and os.path.exists(mock_shipments_path):
            try:
                with open(mock_trucks_path, "r", encoding="utf-8") as f:
                    trucks_list = json.load(f)
                with open(mock_shipments_path, "r", encoding="utf-8") as f:
                    shipments_list = json.load(f)
                
                self._normalize_sensors(trucks_list)
                
                sensors = {t["truck_id"]: t for t in trucks_list}
                shipments = {s["shipment_id"]: s for s in shipments_list}
                
                # Seed sensor configs dynamically
                sensor_config = {}
                positions = ["front", "center", "rear"]
                for t in trucks_list:
                    tid = t["truck_id"]
                    num = tid.split("-")[1]
                    sensor_id = f"SENSOR-{num}A"
                    sensor_config[sensor_id] = {
                        "truck_id": tid,
                        "position": random.choice(positions),
                        "type": "temperature_humidity",
                        "model": "ThermoProbe X200",
                        "installed_at": "2026-01-15T00:00:00",
                    }
                
                self.data = {
                    "sensors": sensors,
                    "shipments": shipments,
                    "sensor_config": sensor_config,
                    "incidents": {},
                    "system_status": {
                        "last_seeded": now.isoformat(),
                        "total_trucks": len(trucks_list),
                        "active_breaches": sum(1 for t in trucks_list if t.get("status") == "breach"),
                        "system_version": "1.0.0",
                        "demo_mode": True
                    }
                }
                self.save()
                return
            except Exception as e:
                print(f"[WARN] Failed to seed mock db from JSON files: {e}")

        # Basic hardcoded fallback if files aren't found
        self.data = {
            "sensors": {},
            "shipments": {},
            "sensor_config": {},
            "incidents": {},
            "system_status": {
                "last_seeded": now.isoformat(),
                "total_trucks": 0,
                "active_breaches": 0,
                "system_version": "1.0.0",
                "demo_mode": True
            }
        }
        self.save()

    def _get_path(self, path):
        path = path.strip("/")
        if not path:
            return self.data
        parts = path.split("/")
        curr = self.data
        for p in parts:
            if isinstance(curr, dict):
                curr = curr.get(p)
            else:
                return None
        return copy.deepcopy(curr)

    def _set_path(self, path, value):
        path = path.strip("/")
        self._normalize_sensors(value)
        if not path:
            self.data = value
            self.save()
            return
        parts = path.split("/")
        curr = self.data
        for p in parts[:-1]:
            if p not in curr or not isinstance(curr[p], dict):
                curr[p] = {}
            curr = curr[p]
        curr[parts[-1]] = value
        self.save()

    def _update_path(self, path, value):
        path = path.strip("/")
        self._normalize_sensors(value)
        if not path:
            if isinstance(self.data, dict) and isinstance(value, dict):
                self.data.update(value)
            else:
                self.data = value
            self.save()
            return
        parts = path.split("/")
        curr = self.data
        for p in parts[:-1]:
            if p not in curr or not isinstance(curr[p], dict):
                curr[p] = {}
            curr = curr[p]
        last = parts[-1]
        if last not in curr or not isinstance(curr[last], dict):
            curr[last] = {}
        curr[last].update(value)
        self.save()

    def _delete_path(self, path):
        path = path.strip("/")
        if not path:
            self.data = {}
            self.save()
            return
        parts = path.split("/")
        curr = self.data
        for p in parts[:-1]:
            if isinstance(curr, dict):
                curr = curr.get(p)
            else:
                return
        if isinstance(curr, dict) and parts[-1] in curr:
            del curr[parts[-1]]
            self.save()

class MockReference:
    def __init__(self, path, db_instance):
        self.path = path.strip("/")
        self.db_instance = db_instance

    def get(self):
        return self.db_instance._get_path(self.path)

    def set(self, value):
        self.db_instance._set_path(self.path, value)

    def update(self, value):
        self.db_instance._update_path(self.path, value)

    def push(self, value=None):
        import uuid
        key = f"-MOCK-{uuid.uuid4().hex[:8].upper()}"
        child_path = f"{self.path}/{key}" if self.path else key
        if value is not None:
            self.db_instance._set_path(child_path, value)
        ref = MockReference(child_path, self.db_instance)
        ref.key = key
        return ref

    def delete(self):
        self.db_instance._delete_path(self.path)

    def order_by_child(self, child_key):
        self.order_by = child_key
        return self

    def equal_to(self, value):
        self.equal_val = value
        return self

class MockDbModule:
    def __init__(self, db_instance):
        self.db_instance = db_instance

    def reference(self, path=""):
        ref = MockReference(path, self.db_instance)
        return ref

class MockCertificate:
    def __init__(self, cert_path):
        pass

class MockCredentialsModule:
    @staticmethod
    def Certificate(cert_path):
        return MockCertificate(cert_path)

# ══════════════════════════════════════════════════════════════
#  Initialization
# ══════════════════════════════════════════════════════════════

def initialize_firebase(
    service_account_path: str = "serviceAccountKey.json",
    database_url: str | None = None,
):
    """
    Initialize the Firebase Admin SDK or local offline Mock database if missing credentials.
    """
    import firebase_admin
    global credentials, db

    # Already initialized — nothing to do
    if firebase_admin._apps:
        return

    # Check if we should use local mock DB mode
    if database_url is None:
        database_url = os.getenv("FIREBASE_DATABASE_URL")

    use_mock = False
    if not os.path.exists(service_account_path):
        print(f"[WARN] Firebase credentials file '{service_account_path}' not found.")
        use_mock = True
    elif not database_url:
        print("[WARN] FIREBASE_DATABASE_URL is not set.")
        use_mock = True

    if use_mock:
        print("[INFO] Switching to Local Offline Mock DB mode...")
        mock_db = MockDatabase()
        mock_db_mod = MockDbModule(mock_db)
        
        # Monkeypatch the submodules directly in case they are already imported
        import firebase_admin.db
        import firebase_admin.credentials
        
        firebase_admin.db.reference = mock_db_mod.reference
        firebase_admin.credentials.Certificate = MockCredentialsModule.Certificate
        
        # Also override module attributes and sys.modules
        firebase_admin.db = mock_db_mod
        firebase_admin.credentials = MockCredentialsModule
        sys.modules['firebase_admin.db'] = mock_db_mod
        sys.modules['firebase_admin.credentials'] = MockCredentialsModule
        
        # Override the imports in this module
        db = mock_db_mod
        credentials = MockCredentialsModule
        
        def mock_initialize_app(cred, config_dict=None):
            firebase_admin._apps = [True]
            print("[OK] Local Offline Mock DB initialized successfully.")
            
        firebase_admin.initialize_app = mock_initialize_app
        firebase_admin._apps = [True]
        return

    # Real initialization
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred, {
        "databaseURL": database_url,
    })
    print("[OK] Firebase initialized successfully")


# ══════════════════════════════════════════════════════════════
#  Read Operations
# ══════════════════════════════════════════════════════════════

def read_sensor_data() -> dict:
    """
    Read all truck temperature / sensor readings from Firebase.

    Returns:
        A dict keyed by truck ID, where each value contains that truck's
        sensor data (temperature, humidity, status, etc.).
        Returns an empty dict if no data exists.

    Example return:
        {
            "TRK-001": {
                "truck_id": "TRK-001",
                "current_temp": 4.2,
                "status": "normal",
                ...
            },
            ...
        }
    """
    ref = db.reference("/sensors")
    data = ref.get()
    return data if data else {}


# ══════════════════════════════════════════════════════════════
#  Update Operations
# ══════════════════════════════════════════════════════════════

def update_shipment_status(shipment_id: str, new_status: str) -> dict:
    """
    Update the status of a shipment in Firebase.

    Args:
        shipment_id: The shipment identifier (e.g. "SHIP-001").
        new_status: New status string — one of:
                    "in_transit", "delivered", "quarantined", "rejected",
                    "under_inspection".

    Returns:
        A dict confirming the update with the shipment_id, new status,
        and timestamp.

    Raises:
        ValueError: If the shipment does not exist in Firebase.
    """
    ref = db.reference(f"/shipments/{shipment_id}")
    existing = ref.get()

    if existing is None:
        raise ValueError(f"Shipment '{shipment_id}' not found in Firebase")

    update_payload = {
        "status": new_status,
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }
    ref.update(update_payload)

    print(f"[SHIPMENT] {shipment_id} -> status updated to '{new_status}'")
    return {
        "shipment_id": shipment_id,
        "new_status": new_status,
        "updated_at": update_payload["last_updated"],
    }


# ══════════════════════════════════════════════════════════════
#  Write Operations
# ══════════════════════════════════════════════════════════════

def log_incident(incident_data: dict) -> str:
    """
    Write an incident report to Firebase under /incidents.

    Automatically adds a timestamp and generates a unique key.

    Args:
        incident_data: Dict containing incident details. Expected fields:
            - truck_id (str): Which truck is involved
            - breach_type (str): e.g. "temperature_high", "temperature_low"
            - temperature (float): Recorded temperature at time of incident
            - severity (str): "low" | "medium" | "high" | "critical"
            - description (str): Human-readable summary
            Additional fields are preserved as-is.

    Returns:
        The Firebase-generated unique key for the incident.

    Example:
        key = log_incident({
            "truck_id": "TRK-004",
            "breach_type": "temperature_high",
            "temperature": 12.3,
            "severity": "high",
            "description": "Vaccine shipment temp exceeded safe range"
        })
    """
    ref = db.reference("/incidents")

    # Enrich with metadata
    incident_data["logged_at"] = datetime.now(timezone.utc).isoformat()
    incident_data.setdefault("resolved", False)

    new_ref = ref.push(incident_data)
    print(f"[INCIDENT] Incident logged -> key: {new_ref.key}")
    return new_ref.key


# ══════════════════════════════════════════════════════════════
#  Convenience Helpers
# ══════════════════════════════════════════════════════════════

def get_truck_data(truck_id: str) -> dict | None:
    """Get data for a single truck from /sensors/{truck_id}."""
    ref = db.reference(f"/sensors/{truck_id}")
    return ref.get()


def get_all_incidents() -> dict:
    """Retrieve all logged incidents from /incidents."""
    ref = db.reference("/incidents")
    data = ref.get()
    return data if data else {}


def get_shipment(shipment_id: str) -> dict | None:
    """Retrieve a single shipment from /shipments/{shipment_id}."""
    ref = db.reference(f"/shipments/{shipment_id}")
    return ref.get()


# ── Quick self-test ────────────────────────────────────────────

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    initialize_firebase()

    print("\n── Reading sensor data ──")
    sensors = read_sensor_data()
    print(json.dumps(sensors, indent=2) if sensors else "No sensor data found")

    print(f"\n✅ Firebase config module is working — {len(sensors)} truck(s) found")
