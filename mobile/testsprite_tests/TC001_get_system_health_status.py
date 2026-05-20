import requests

def test_get_system_health_status():
    base_url = "http://localhost:8000"
    url = f"{base_url}/"

    try:
        response = requests.get(url, timeout=30)
    except requests.RequestException as e:
        assert False, f"Request to {url} failed with exception: {e}"

    assert response.status_code == 200, f"Expected status code 200 but got {response.status_code}"
    try:
        json_data = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    # Basic health status expected keys can be checked if known.
    # Since the schema is HealthStatus, but fields unknown, we check json is not empty.
    assert isinstance(json_data, dict) and len(json_data) > 0, "HealthStatus response should be a non-empty JSON object"

test_get_system_health_status()