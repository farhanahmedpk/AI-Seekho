import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_all_shipments_with_current_status():
    url = f"{BASE_URL}/shipments"
    try:
        response = requests.get(url, timeout=TIMEOUT)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        assert False, f"Request to GET /shipments failed: {e}"
    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"
    try:
        shipments = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    # Basic validation: shipments should be a list or dict (depending on API)
    # Assuming API returns a JSON list or an object containing a list under a known key
    # Since no schema details for the list format are given, check it's a dict or list
    assert shipments is not None, "Response JSON is empty or None"

    # Validate each shipment has a current status field
    # Assuming each shipment is a dict and status information is included.
    # If the response is a list of shipments
    if isinstance(shipments, list):
        for shipment in shipments:
            assert isinstance(shipment, dict), "Each shipment should be a dict"
            assert "current_status" in shipment or "status" in shipment, \
                "Shipment missing 'current_status' or 'status' field"
    elif isinstance(shipments, dict):
        # If the response is a dict with a key for shipment list
        # Try to find a list among values
        shipment_list = None
        for key, value in shipments.items():
            if isinstance(value, list):
                shipment_list = value
                break
        if shipment_list is not None:
            for shipment in shipment_list:
                assert isinstance(shipment, dict), "Each shipment should be a dict"
                assert "current_status" in shipment or "status" in shipment, \
                    "Shipment missing 'current_status' or 'status' field"
        else:
            assert False, "No list of shipments found in response JSON"
    else:
        assert False, f"Unexpected response JSON type: {type(shipments)}"

test_get_all_shipments_with_current_status()