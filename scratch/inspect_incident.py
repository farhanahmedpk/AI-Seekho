import os
import sys
import firebase_admin
from firebase_admin import credentials, db
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
CRED_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS",
    os.path.join(PROJECT_ROOT, "serviceAccountKey.json"),
)
DATABASE_URL = os.environ.get("FIREBASE_DATABASE_URL")

if not DATABASE_URL:
    print("ERROR: FIREBASE_DATABASE_URL is not set.")
    sys.exit(1)

if not os.path.exists(CRED_PATH):
    print(f"ERROR: Firebase credentials file not found at: {CRED_PATH}")
    sys.exit(1)

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(CRED_PATH)
    firebase_admin.initialize_app(cred, {"databaseURL": DATABASE_URL})

def inspect_incident(incident_id):
    print(f"Inspecting incident: {incident_id}")
    ref = db.reference(f"/incidents/{incident_id}")
    data = ref.get()
    
    if data is None:
        print(f"No data found at /incidents/{incident_id}")
        return

    print(f"\nKeys found in /incidents/{incident_id}:")
    for key in data.keys():
        print(f" - {key}")
        
    if "steps" in data:
        print(f"\n'steps' found! Count: {len(data['steps'])}")
    else:
        print("\n'steps' NOT found.")
        
    # Also check the whole /incidents to see if there's another node
    print("\nChecking sibling nodes in /incidents...")
    all_incidents = db.reference("/incidents").get()
    for key, value in all_incidents.items():
        if isinstance(value, dict) and value.get("incident_id") == incident_id:
            print(f"Found match at key: {key}")
            print(f"Keys in this node: {list(value.keys())}")

if __name__ == "__main__":
    inspect_incident("INC-2948C02F")
