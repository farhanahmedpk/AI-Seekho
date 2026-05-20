import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30


def test_post_trigger_breach_database_update_failure():
    # Step 1: Get a valid truck_id by fetching current sensors
    try:
        sensors_resp = requests.get(f"{BASE_URL}/sensors", timeout=TIMEOUT)
        sensors_resp.raise_for_status()
        sensors = sensors_resp.json()
        assert isinstance(sensors, list) or isinstance(sensors, dict)

        # Determine a valid truck_id from sensors data
        truck_id = None
        if isinstance(sensors, list):
            for sensor in sensors:
                if isinstance(sensor, dict):
                    tid = sensor.get("truck_id")
                    if tid:
                        truck_id = tid
                        break
        elif isinstance(sensors, dict):
            for sensor in sensors.values():
                if isinstance(sensor, dict):
                    tid = sensor.get("truck_id")
                    if tid:
                        truck_id = tid
                        break
        
        if not truck_id:
            assert False, "No valid truck_id found to run the test."

        temperature = 50.0

        payload = {
            "truck_id": truck_id,
            "temperature": temperature
        }
        headers = {
            "Content-Type": "application/json"
        }

        resp = requests.post(f"{BASE_URL}/trigger-breach", json=payload, headers=headers, timeout=TIMEOUT)

        assert resp.status_code == 500, f"Expected status code 500, got {resp.status_code}"
        try:
            resp_json = resp.json()
        except Exception:
            resp_json = None

        expected_error_msg = "Database update failed"
        if resp_json and isinstance(resp_json, dict):
            error_msg = resp_json.get("detail") or resp_json.get("message") or resp_json.get("error") or ""
            assert expected_error_msg.lower() in error_msg.lower(), f"Expected error message containing '{expected_error_msg}', got '{error_msg}'"
        else:
            text = resp.text or ""
            assert expected_error_msg.lower() in text.lower(), f"Expected error message containing '{expected_error_msg}', got response text '{text}'"

        if resp_json and "pipeline_trace" in resp_json:
            pipeline_trace = resp_json["pipeline_trace"]
            partial_failure_found = False

            if isinstance(pipeline_trace, dict):
                partial_failure_found = (
                    pipeline_trace.get("status", "").lower() == "partial_failure" or
                    pipeline_trace.get("result", "").lower() == "partial_failure" or
                    "partial failure" in str(pipeline_trace).lower()
                )
                if not partial_failure_found:
                    for v in pipeline_trace.values():
                        if isinstance(v, str) and "partial failure" in v.lower():
                            partial_failure_found = True
                            break
                        elif isinstance(v, list):
                            for item in v:
                                if isinstance(item, str) and "partial failure" in item.lower():
                                    partial_failure_found = True
                                    break
                            if partial_failure_found:
                                break

            assert partial_failure_found, "Pipeline trace does not indicate partial failure as expected."

    except requests.RequestException as e:
        assert False, f"RequestException during test: {e}"


test_post_trigger_breach_database_update_failure()
