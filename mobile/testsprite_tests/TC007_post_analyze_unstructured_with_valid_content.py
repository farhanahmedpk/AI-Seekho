import requests
import time

BASE_URL = "http://localhost:8000"
TIMEOUT = 30


def test_post_analyze_unstructured_with_valid_content():
    # Step 1: Retrieve current shipments to get a valid truck_id for testing
    try:
        shipments_resp = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
        shipments_resp.raise_for_status()
        shipments_data = shipments_resp.json()
        # shipments_data is expected to be a dict containing a list of shipments
        shipments_list = []
        if isinstance(shipments_data, dict):
            # Try common keys for list of shipments
            if "shipments" in shipments_data and isinstance(shipments_data["shipments"], list):
                shipments_list = shipments_data["shipments"]
            elif "data" in shipments_data and isinstance(shipments_data["data"], list):
                shipments_list = shipments_data["data"]
            else:
                # fallback try to find first list value in dict
                for v in shipments_data.values():
                    if isinstance(v, list):
                        shipments_list = v
                        break
        elif isinstance(shipments_data, list):
            shipments_list = shipments_data
        if not shipments_list:
            raise Exception("Shipments list is empty or invalid format")

        # Assume shipment has a truck_id field, use first valid one
        valid_truck_id = None
        for shipment in shipments_list:
            truck_id = shipment.get("truck_id")
            if truck_id and isinstance(truck_id, str):
                valid_truck_id = truck_id
                break
        if not valid_truck_id:
            raise Exception("No valid truck_id found in shipments")
    except Exception as e:
        raise AssertionError(f"Failed to get valid truck_id from shipments: {e}")

    # Construct unstructured content with truck identifier and temperature statement
    test_temperature = 8.5  # Above typical cold chain threshold to trigger breach
    content = f"Driver report: Truck {valid_truck_id} is showing temperatures around {test_temperature}C near the rear door."

    # Send POST request to /analyze-unstructured
    try:
        response = requests.post(
            f"{BASE_URL}/analyze-unstructured",
            json={"content": content},
            timeout=TIMEOUT,
            headers={"Content-Type": "application/json"},
        )
    except requests.RequestException as e:
        raise AssertionError(f"Request to /analyze-unstructured failed: {e}")

    # Assert response status code 200
    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"

    result = response.json()

    # Validate UnstructuredAnalysisResult keys exist and that truck_id and temperature were extracted and match
    assert isinstance(result, dict), "Response JSON is not an object/dict"
    extracted_truck_id = result.get("truck_id") or result.get("extracted_truck_id")
    extracted_temperature = result.get("temperature") or result.get("extracted_temperature")
    assert extracted_truck_id == valid_truck_id, f"Extracted truck_id mismatch: expected {valid_truck_id}, got {extracted_truck_id}"
    # Temperature extraction may be float or int, allow close match
    assert extracted_temperature is not None, "Temperature not extracted"
    assert abs(float(extracted_temperature) - test_temperature) < 0.5, f"Extracted temperature {extracted_temperature} not close to input {test_temperature}"

    # Allow some time for breach response pipeline to update system state
    time.sleep(3)

    # Verify incident and shipment state updated accordingly by checking shipments included status/quarantine updates
    try:
        shipments_check_resp = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
        shipments_check_resp.raise_for_status()
        shipments_check_data = shipments_check_resp.json()
        shipments_check_list = []
        if isinstance(shipments_check_data, dict):
            if "shipments" in shipments_check_data and isinstance(shipments_check_data["shipments"], list):
                shipments_check_list = shipments_check_data["shipments"]
            elif "data" in shipments_check_data and isinstance(shipments_check_data["data"], list):
                shipments_check_list = shipments_check_data["data"]
            else:
                for v in shipments_check_data.values():
                    if isinstance(v, list):
                        shipments_check_list = v
                        break
        elif isinstance(shipments_check_data, list):
            shipments_check_list = shipments_check_data
        if not shipments_check_list:
            raise Exception("Shipments list is empty or invalid format")
    except Exception as e:
        raise AssertionError(f"Failed to fetch shipments for verification: {e}")

    # Find shipment with matched truck_id and check for updated incident state or quarantine status
    shipment_updated = None
    for shipment in shipments_check_list:
        if shipment.get("truck_id") == valid_truck_id:
            shipment_updated = shipment
            break
    assert shipment_updated is not None, f"No shipment found with truck_id {valid_truck_id} after analysis"

    # Check for evidence of quarantine or incident update - typical keys could be "status", "quarantine", or "incident"
    # As schema is not explicit, check at least a status that is not "normal"
    status = shipment_updated.get("status") or shipment_updated.get("shipment_status")
    incident = shipment_updated.get("incident") or shipment_updated.get("latest_incident")

    assert status and status.lower() != "normal", "Shipment status was not updated to indicate breach/quarantine"
    assert incident is not None, "Shipment incident data not present after breach pipeline triggered"


test_post_analyze_unstructured_with_valid_content()
