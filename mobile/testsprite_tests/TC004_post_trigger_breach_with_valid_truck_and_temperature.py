import requests
import time

BASE_URL = "http://localhost:8000"
TIMEOUT = 30


def test_post_trigger_breach_with_valid_truck_and_temperature():
    # First, get the list of shipments to find a valid truck_id
    try:
        response_shipments = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
        assert response_shipments.status_code == 200, "Failed to fetch shipments"
        shipments_resp = response_shipments.json()
        assert isinstance(shipments_resp, dict), "Shipments response is not a dict"
        assert "shipments" in shipments_resp, "'shipments' key not found in response"
        shipments = shipments_resp["shipments"]
        assert isinstance(shipments, list), "'shipments' value is not a list"

        # Find a shipment with valid truck_id
        valid_truck_id = None
        for shipment in shipments:
            if "truck_id" in shipment:
                valid_truck_id = shipment["truck_id"]
                break

        assert valid_truck_id is not None, "No valid truck_id found in shipments"

        # Also confirm the threshold temperature is crossed
        # Since threshold is not specified in PRD, assume a high temperature e.g. 30.0
        breach_temperature = 30.0

        payload = {
            "truck_id": valid_truck_id,
            "temperature": breach_temperature
        }

        response_breach = requests.post(
            f"{BASE_URL}/trigger-breach",
            json=payload,
            timeout=TIMEOUT
        )
        assert response_breach.status_code == 200, f"Expected 200, got {response_breach.status_code}"

        agent_pipeline_trace = response_breach.json()
        # Validate response contains expected keys from AgentPipelineTrace
        assert isinstance(agent_pipeline_trace, dict), "AgentPipelineTrace is not a dict"
        # Check presence of key phases or agents execution trace
        assert "sensor_assessment" in agent_pipeline_trace or "pipeline" in agent_pipeline_trace, \
            "AgentPipelineTrace missing expected keys"

        # Wait briefly to allow Firebase update (assuming eventual consistency)
        time.sleep(1)

        # Confirm shipment status and incident data updated in Firebase
        response_shipments_after = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
        assert response_shipments_after.status_code == 200, "Failed to fetch shipments after breach"
        shipments_after_resp = response_shipments_after.json()
        assert isinstance(shipments_after_resp, dict), "Shipments response after breach is not a dict"
        assert "shipments" in shipments_after_resp, "'shipments' key not found in response after breach"
        shipments_after = shipments_after_resp["shipments"]
        assert isinstance(shipments_after, list), "'shipments' value after breach is not a list"

        # Find the shipment updated
        updated_shipment = None
        for shipment in shipments_after:
            if shipment.get("truck_id") == valid_truck_id:
                updated_shipment = shipment
                break

        assert updated_shipment is not None, "Updated shipment record not found"

        # Check shipment status is updated indicating breach/quarantine
        status = updated_shipment.get("status", "").lower()
        assert status in ["quarantined", "breached", "incident", "alert"], \
            f"Shipment status '{status}' does not indicate breach"

    except requests.RequestException as e:
        assert False, f"Request failed: {e}"


test_post_trigger_breach_with_valid_truck_and_temperature()
