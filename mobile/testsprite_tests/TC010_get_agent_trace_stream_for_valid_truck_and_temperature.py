import requests
import json
import time

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_agent_trace_stream_for_valid_truck_and_temperature():
    # First, get a valid truck_id from /sensors or /shipments
    try:
        sensors_resp = requests.get(f"{BASE_URL}/sensors", timeout=TIMEOUT)
        sensors_resp.raise_for_status()
        sensors = sensors_resp.json()
        # Find a truck with a valid temperature sensor reading
        truck_id = None
        temperature = None
        if isinstance(sensors, list):
            for sensor in sensors:
                if isinstance(sensor, dict):
                    tid = sensor.get("truck_id") or sensor.get("id") or sensor.get("truckId")
                    temp = sensor.get("temperature")
                    if tid and isinstance(temp, (int,float)):
                        truck_id = tid
                        temperature = temp
                        break
        if not truck_id or temperature is None:
            # fallback: get from shipments and pick temperature from shipment state if available
            shipments_resp = requests.get(f"{BASE_URL}/shipments", timeout=TIMEOUT)
            shipments_resp.raise_for_status()
            shipments = shipments_resp.json()
            if isinstance(shipments, list):
                for shipment in shipments:
                    tid = shipment.get("truck_id") or shipment.get("id") or shipment.get("truckId")
                    temp = shipment.get("temperature")
                    if tid and isinstance(temp, (int,float)):
                        truck_id = tid
                        temperature = temp
                        break
        assert truck_id is not None and temperature is not None, "No valid truck_id and temperature found"
        
        # Trigger a breach to ensure there is a pipeline trace for this truck and temperature
        breach_payload = {
            "truck_id": truck_id,
            "temperature": temperature + 5  # ensure breach temperature above normal threshold
        }
        breach_resp = requests.post(f"{BASE_URL}/trigger-breach", json=breach_payload, timeout=TIMEOUT)
        breach_resp.raise_for_status()
        breach_data = breach_resp.json()

        # Validate breach response contains pipeline trace keys
        assert isinstance(breach_data, dict)
        assert "sensor_assessment" in breach_data or "pipeline" in breach_data or "trace" in breach_data
        
        # Now request the agent trace stream for this truck and temperature
        url = f"{BASE_URL}/agent-trace/stream/{truck_id}/{breach_payload['temperature']}"
        with requests.get(url, stream=True, timeout=TIMEOUT) as resp:
            resp.raise_for_status()
            # The response is a stream, so iterate over lines
            events = []
            for line in resp.iter_lines(decode_unicode=True):
                if line:
                    try:
                        event = json.loads(line)
                        events.append(event)
                    except json.JSONDecodeError:
                        continue  # ignore malformed lines
            
            # Validate event sequence
            event_types = [e.get("event") for e in events if isinstance(e, dict) and "event" in e]
            assert event_types, "No events found in stream"
            assert event_types[0] == "pipeline_started", "First event should be pipeline_started"
            assert "pipeline_completed" in event_types, "pipeline_completed event not found in stream"
            
            # Verify for each agent there is agent_started and agent_completed in event_types
            # Extract agent names from events (agent_started events)
            agent_names = []
            for e in events:
                if e.get("event") == "agent_started" and "agent_name" in e:
                    agent_names.append(e["agent_name"])
            assert agent_names, "No agent_started events found"
            for agent in set(agent_names):
                started = any(e.get("event")=="agent_started" and e.get("agent_name")==agent for e in events)
                completed = any(e.get("event")=="agent_completed" and e.get("agent_name")==agent for e in events)
                assert started, f"agent_started event missing for agent {agent}"
                assert completed, f"agent_completed event missing for agent {agent}"
            
            # Verify pipeline_completed event includes incident summary
            completed_events = [e for e in events if e.get("event") == "pipeline_completed"]
            assert len(completed_events) == 1, "There should be exactly one pipeline_completed event"
            incident_summary = completed_events[0].get("incident_summary")
            assert incident_summary is not None, "pipeline_completed event must contain incident_summary"

    except requests.RequestException as e:
        assert False, f"Request failed: {str(e)}"

test_get_agent_trace_stream_for_valid_truck_and_temperature()