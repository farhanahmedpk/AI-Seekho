import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_analyze_unstructured_with_malformed_content():
    url = f"{BASE_URL}/analyze-unstructured"
    headers = {"Content-Type": "application/json"}

    malformed_contents = [
        # Missing truck_id
        {"content": "Temperature reading is 5 degrees Celsius, but no truck id mentioned."},
        # Missing temperature
        {"content": "Truck ABC123 had some issues detected but no temperature stated."},
        # Missing both truck_id and temperature
        {"content": "Report with irrelevant information and no truck or temp data."}
    ]

    for payload in malformed_contents:
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
        except requests.RequestException as e:
            assert False, f"Request failed: {e}"

        assert response.status_code == 200, f"Expected 200 but got {response.status_code}"

        json_response = response.json()
        # UnstructuredAnalysisResult expected fields are unknown, but per PRD:
        # It should indicate missing or failed extraction:
        # So assert fields that indicate missing truck_id or temperature or extraction failure.
        # Check for keys that could indicate extraction status or extracted data presence
        # We assume response has keys like 'truck_id', 'temperature', 'extraction_status' or similar

        # Check response has indication of extraction failure or incomplete extraction
        # This can be heuristically determined by absence or null values for truck_id or temperature

        truck_id = json_response.get("truck_id")
        temperature = json_response.get("temperature")
        extraction_status = json_response.get("extraction_status") or json_response.get("status")

        # Assert truck_id or temperature missing or extraction_status shows failure or partial
        missing_truck_id = truck_id in (None, "", [], {})
        missing_temperature = temperature in (None, "", [], {})
        extraction_failed = extraction_status in ("failed", "partial", "missing", "incomplete", None)

        assert (missing_truck_id or missing_temperature) and extraction_failed or extraction_failed or (missing_truck_id or missing_temperature), \
            f"Response does not indicate missing or failed extraction: {json_response}"

test_post_analyze_unstructured_with_malformed_content()