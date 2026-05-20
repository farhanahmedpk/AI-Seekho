import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_trigger_breach_with_nonexistent_truck_id():
    nonexistent_truck_id = f"nonexistent-{uuid.uuid4()}"
    temperature = 10.0  # arbitrary temperature above normal threshold
    
    # Capture shipments before the test to compare later
    try:
        resp_before = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
        resp_before.raise_for_status()
        shipments_before = resp_before.json()
    except Exception:
        shipments_before = None  # if this fails, we skip consistency check
    
    payload = {
        "truck_id": nonexistent_truck_id,
        "temperature": temperature
    }
    headers = {
        "Content-Type": "application/json"
    }

    response = requests.post(f"{BASE_URL}/trigger-breach", json=payload, headers=headers, timeout=TIMEOUT)

    # Assert 404 response with expected message
    assert response.status_code == 404, f"Expected 404, got {response.status_code}"
    try:
        error_message = response.text.lower()
    except Exception:
        error_message = ""
    assert "truck not found" in error_message or "not found" in error_message, \
        "Response body does not indicate 'Truck not found' error"

    # Validate that shipments remain unchanged (no breach pipeline executed)
    if shipments_before is not None:
        try:
            resp_after = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
            resp_after.raise_for_status()
            shipments_after = resp_after.json()
            assert shipments_before == shipments_after, "Shipments data changed after triggering breach with nonexistent truck_id"
        except Exception as e:
            # If unable to validate shipments after, just raise Exception
            raise AssertionError(f"Failed to verify shipments consistency: {e}")


test_post_trigger_breach_with_nonexistent_truck_id()