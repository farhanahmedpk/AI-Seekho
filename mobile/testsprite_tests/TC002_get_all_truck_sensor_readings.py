import requests

def test_get_all_truck_sensor_readings():
    base_url = "http://localhost:8000"
    endpoint = "/sensors"
    url = base_url + endpoint
    headers = {
        "Accept": "application/json"
    }
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        assert False, f"Request to {url} failed: {e}"

    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"
    try:
        data = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    # Assert that the response is a dict containing a list of sensors
    assert isinstance(data, dict), f"Expected response to be a dict, got {type(data)}"
    assert "sensors" in data, "Response JSON does not contain 'sensors' key"
    sensors = data["sensors"]
    assert isinstance(sensors, list), f"Expected 'sensors' to be a list, got {type(sensors)}"

    # For each sensor reading, validate presence of expected keys: at least temperature and status
    for sensor in sensors:
        assert isinstance(sensor, dict), f"Each sensor reading should be a dict, got {type(sensor)}"
        assert "temperature" in sensor, "Sensor reading missing 'temperature' field"
        assert "status" in sensor, "Sensor reading missing 'status' field"

test_get_all_truck_sensor_readings()
