import os
import sys
import firebase_admin
from firebase_admin import credentials, db
from dotenv import load_dotenv

load_dotenv()

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
CRED_PATH = os.environ.get("FIREBASE_CREDENTIALS", os.path.join(PROJECT_ROOT, "serviceAccountKey.json"))
DATABASE_URL = os.environ.get("FIREBASE_DATABASE_URL")

if not firebase_admin._apps:
    cred = credentials.Certificate(CRED_PATH)
    firebase_admin.initialize_app(cred, {"databaseURL": DATABASE_URL})

incident_id = "INC-2948C02F"
ref = db.reference(f"/incidents/{incident_id}")
data = ref.get()

with open("scratch/keys_output.txt", "w") as f:
    if data:
        f.write(f"Keys for {incident_id}:\n")
        f.write("\n".join(data.keys()))
        if "steps" in data:
            f.write(f"\n\nSteps found: {len(data['steps'])}")
    else:
        f.write(f"No data at /incidents/{incident_id}")

    # Check sibling
    all_inc = db.reference("/incidents").get()
    f.write("\n\nChecking siblings:\n")
    for k, v in all_inc.items():
        if isinstance(v, dict) and v.get("incident_id") == incident_id and k != incident_id:
            f.write(f"Found sibling key: {k}\n")
            f.write(f"Sibling keys: {list(v.keys())}\n")
