"""
integration_test.py
====================
End-to-end integration tests for the ColdChain AI system.

Run this AFTER Member 1 (backend) and Member 2 (agents) have finished.
Make sure the FastAPI server is running before executing.

Usage:
    python -m pytest tests/integration_test.py -v
    OR
    python tests/integration_test.py

Prerequisites:
    1. Run: python data/reset_firebase.py   (reset to demo state)
    2. Run: uvicorn main:app --reload        (start the server)
    3. Run this test file
"""

import sys
import os
import json
import time
import asyncio
from datetime import datetime

import httpx

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BASE_URL = os.environ.get("TEST_BASE_URL", "http://127.0.0.1:8000")
TIMEOUT = 30  # seconds — max allowed for agent pipeline

# Track results
test_results: list[dict] = []


def record(name: str, passed: bool, detail: str = "") -> None:
    """Record a test result."""
    test_results.append({"name": name, "passed": passed, "detail": detail})
    status = "PASS" if passed else "FAIL"
    icon = "[PASS]" if passed else "[FAIL]"
    print(f"  {icon} {name}")
    if detail and not passed:
        print(f"        -> {detail}")


# =========================================================================
# Test 1 — Backend Health Check
# =========================================================================

def test_1_backend_health_check() -> None:
    """
    Verify the backend is running and returns expected data:
    - GET /sensors returns 200 with exactly 10 trucks
    - GET /shipments returns 200 with at least 1 shipment
    """
    print()
    print("=" * 60)
    print("  Test 1: Backend Health Check")
    print("=" * 60)

    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            # --- Check /sensors ---
            resp = client.get("/sensors")
            if resp.status_code != 200:
                record(
                    "GET /sensors returns 200",
                    False,
                    f"Got status {resp.status_code}",
                )
                return

            sensors = resp.json()

            # Handle our backend format
            if isinstance(sensors, dict) and "sensors" in sensors:
                truck_count = len(sensors["sensors"])
            elif isinstance(sensors, dict):
                truck_count = len(sensors)
            elif isinstance(sensors, list):
                truck_count = len(sensors)
            else:
                record("GET /sensors returns 200", False, f"Unexpected type: {type(sensors)}")
                return

            if truck_count != 10:
                record(
                    "Exactly 10 trucks returned",
                    False,
                    f"Got {truck_count} trucks",
                )
            else:
                record("GET /sensors returns 200 with 10 trucks", True)

            # --- Check /shipments ---
            resp = client.get("/shipments")
            if resp.status_code != 200:
                record(
                    "GET /shipments returns 200",
                    False,
                    f"Got status {resp.status_code}",
                )
                return

            shipments = resp.json()

            if isinstance(shipments, dict) and "shipments" in shipments:
                shipment_count = len(shipments["shipments"])
            elif isinstance(shipments, dict):
                shipment_count = len(shipments)
            elif isinstance(shipments, list):
                shipment_count = len(shipments)
            else:
                record("GET /shipments returns 200", False, f"Unexpected type: {type(shipments)}")
                return

            if shipment_count < 1:
                record("At least 1 shipment returned", False, "Got 0 shipments")
            else:
                record(f"GET /shipments returns 200 with {shipment_count} shipments", True)

        print()
        print("  -> Backend is running and reachable")

    except httpx.ConnectError:
        record(
            "Backend reachable",
            False,
            f"Cannot connect to {BASE_URL}. Is the server running?",
        )
    except Exception as e:
        record("Backend health check", False, str(e))


# =========================================================================
# Test 2 — Breach Detection
# =========================================================================

def test_2_breach_detection() -> None:
    """
    POST /trigger-breach with TRK-004 at 12.5 C.
    Verify breach_detected: true and severity: Critical.
    """
    print()
    print("=" * 60)
    print("  Test 2: Breach Detection")
    print("=" * 60)

    try:
        with httpx.Client(base_url=BASE_URL, timeout=TIMEOUT) as client:
            payload = {
                "truck_id": "TRK-004",
                "temperature": 12.5,
            }

            resp = client.post("/trigger-breach", json=payload)

            if resp.status_code != 200:
                record(
                    "POST /trigger-breach returns 200",
                    False,
                    f"Got status {resp.status_code}: {resp.text[:200]}",
                )
                return

            data = resp.json()

            # Try to get it from root or steps
            breach_detected = data.get("breach_detected", False)
            if not breach_detected and "steps" in data and len(data["steps"]) > 0:
                breach_detected = data["steps"][0].get("output", {}).get("breach_detected", False)

            if not breach_detected:
                record(
                    "breach_detected is true",
                    False,
                    f"Got breach_detected={breach_detected}",
                )
            else:
                record("breach_detected is true", True)

            # Check severity
            severity = data.get("severity", "")
            if not severity and "steps" in data and len(data["steps"]) > 0:
                severity = data["steps"][0].get("output", {}).get("severity", "")
            if severity != "Critical":
                record(
                    'severity is "Critical"',
                    False,
                    f'Got severity="{severity}"',
                )
            else:
                record('severity is "Critical"', True)

        print()
        print("  -> Breach detection working")

    except httpx.ConnectError:
        record("Breach detection", False, f"Cannot connect to {BASE_URL}")
    except Exception as e:
        record("Breach detection", False, str(e))


# =========================================================================
# Test 3 — Agent Pipeline
# =========================================================================

def test_3_agent_pipeline() -> None:
    """
    Verify all 4 agents run in sequence, each returns required fields,
    and the total pipeline completes in under 30 seconds.
    """
    print()
    print("=" * 60)
    print("  Test 3: Agent Pipeline")
    print("=" * 60)

    EXPECTED_AGENTS = [
        "SensorMonitorAgent",
        "AnalysisAgent",
        "DecisionAgent",
        "ExecutionAgent",
    ]

    try:
        with httpx.Client(base_url=BASE_URL, timeout=TIMEOUT) as client:
            payload = {
                "truck_id": "TRK-004",
                "temperature": 12.5,
            }

            start = time.time()
            resp = client.post("/trigger-breach", json=payload)
            elapsed = time.time() - start

            if resp.status_code != 200:
                record(
                    "Pipeline endpoint returns 200",
                    False,
                    f"Got status {resp.status_code}",
                )
                return

            data = resp.json()

            # Check each agent produced output
            agents_output = data.get("steps", data.get("agents", data.get("agent_results", data)))
            all_agents_found = True

            for agent_name in EXPECTED_AGENTS:
                agent_data = None
                if isinstance(agents_output, list):
                    agent_data = next((s for s in agents_output if s.get("agent") == agent_name), None)
                elif isinstance(agents_output, dict):
                    agent_data = agents_output.get(agent_name)

                if agent_data is None:
                    # Try checking top-level keys
                    agent_data = data.get(agent_name)

                if agent_data is not None:
                    record(f"{agent_name} returned output", True)
                else:
                    record(
                        f"{agent_name} returned output",
                        False,
                        "Agent output not found in response",
                    )
                    all_agents_found = False

            # Check timing
            if elapsed > TIMEOUT:
                record(
                    f"Pipeline under {TIMEOUT}s",
                    False,
                    f"Took {elapsed:.1f}s",
                )
            else:
                record(f"Pipeline completed in {elapsed:.1f}s (limit: {TIMEOUT}s)", True)

            if all_agents_found:
                print()
                print("  -> All 4 agents completed successfully")
            else:
                print()
                print("  -> WARNING: Some agents missing from response")

    except httpx.ConnectError:
        record("Agent pipeline", False, f"Cannot connect to {BASE_URL}")
    except httpx.ReadTimeout:
        record("Agent pipeline", False, f"Timed out after {TIMEOUT}s")
    except Exception as e:
        record("Agent pipeline", False, str(e))


# =========================================================================
# Test 4 — Firebase Updates
# =========================================================================

def test_4_firebase_updates() -> None:
    """
    After pipeline runs, verify:
    - /shipments/SHIP-004/status == "QUARANTINED"
    - /incidents has at least 1 entry
    """
    print()
    print("=" * 60)
    print("  Test 4: Firebase State Updates")
    print("=" * 60)

    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            # --- Check shipment status ---
            resp = client.get("/shipments")
            if resp.status_code == 200:
                shipments = resp.json()

                # Handle dict or list or wrapper dict
                shp_004 = None
                if isinstance(shipments, dict) and "shipments" in shipments:
                    shp_004 = next(
                        (s for s in shipments["shipments"] if s.get("shipment_id") == "SHIP-004"),
                        None,
                    )
                elif isinstance(shipments, dict):
                    shp_004 = shipments.get("SHIP-004", {})
                elif isinstance(shipments, list):
                    shp_004 = next(
                        (s for s in shipments if s.get("shipment_id") == "SHIP-004"),
                        None,
                    )

                if shp_004:
                    status = shp_004.get("status", "")
                    if status == "QUARANTINED":
                        record("SHIP-004 status is QUARANTINED", True)
                    else:
                        record(
                            "SHIP-004 status is QUARANTINED",
                            False,
                            f'Got status="{status}"',
                        )
                else:
                    record("SHIP-004 found", False, "SHIP-004 not in response")
            else:
                record("GET /shipments", False, f"Got status {resp.status_code}")

            # --- Check incidents ---
            resp = client.get("/incidents")
            if resp.status_code == 200:
                incidents = resp.json()

                if isinstance(incidents, dict):
                    incident_count = len(incidents)
                elif isinstance(incidents, list):
                    incident_count = len(incidents)
                else:
                    incident_count = 0

                if incident_count >= 1:
                    record(f"At least 1 incident recorded ({incident_count} found)", True)
                else:
                    record(
                        "At least 1 incident recorded",
                        False,
                        "No incidents found after breach",
                    )
            else:
                record("GET /incidents", False, f"Got status {resp.status_code}")

        print()
        print("  -> Firebase state updated correctly")

    except httpx.ConnectError:
        record("Firebase updates", False, f"Cannot connect to {BASE_URL}")
    except Exception as e:
        record("Firebase updates", False, str(e))


# =========================================================================
# Test 5 — Streaming Endpoint
# =========================================================================

def test_5_streaming_endpoint() -> None:
    """
    Connect to /agent-trace/stream/TRK-004/12.5 and verify:
    - All 4 chunks arrive in order
    - Stream closes with pipeline_complete status
    """
    print()
    print("=" * 60)
    print("  Test 5: Streaming Endpoint")
    print("=" * 60)

    EXPECTED_CHUNK_ORDER = [
        "Sensor Monitor Agent",
        "Analysis Agent",
        "Decision Agent",
        "Execution Agent",
    ]

    try:
        chunks_received: list[dict] = []

        with httpx.Client(base_url=BASE_URL, timeout=TIMEOUT) as client:
            url = "/agent-trace/stream/TRK-004/12.5"

            with client.stream("GET", url) as resp:
                if resp.status_code != 200:
                    record(
                        "Stream endpoint returns 200",
                        False,
                        f"Got status {resp.status_code}",
                    )
                    return

                buffer = ""
                for raw_chunk in resp.iter_text():
                    buffer += raw_chunk

                    # Parse SSE-style events (data: {...}\n\n)
                    while "\n\n" in buffer:
                        event_text, buffer = buffer.split("\n\n", 1)
                        for line in event_text.strip().split("\n"):
                            if line.startswith("data: "):
                                try:
                                    data = json.loads(line[6:])
                                    chunks_received.append(data)
                                except json.JSONDecodeError:
                                    pass
                            elif line.strip().startswith("{"):
                                # Some implementations send raw JSON
                                try:
                                    data = json.loads(line.strip())
                                    chunks_received.append(data)
                                except json.JSONDecodeError:
                                    pass

        # Verify chunk count
        if len(chunks_received) < 4:
            record(
                "At least 4 chunks received",
                False,
                f"Got {len(chunks_received)} chunks",
            )
        else:
            record(f"Received {len(chunks_received)} chunks", True)

        # Verify agent order in chunks
        agent_names_in_order = []
        for chunk in chunks_received:
            if chunk.get("event") == "agent_started":
                continue
            agent = chunk.get("agent", chunk.get("agent_name", chunk.get("type", "")))
            if agent in EXPECTED_CHUNK_ORDER:
                agent_names_in_order.append(agent)

        order_correct = True
        for i, expected in enumerate(EXPECTED_CHUNK_ORDER):
            if i < len(agent_names_in_order):
                if agent_names_in_order[i] != expected:
                    order_correct = False
                    break
            else:
                order_correct = False
                break

        if order_correct:
            record("Chunks arrived in correct agent order", True)
        else:
            record(
                "Chunks arrived in correct agent order",
                False,
                f"Got order: {agent_names_in_order}",
            )

        # Verify pipeline_complete
        last_chunk = chunks_received[-1] if chunks_received else {}
        complete_status = last_chunk.get("event", last_chunk.get("type", ""))
        if complete_status == "pipeline_completed":
            record("Stream closed with pipeline_completed", True)
        else:
            record(
                "Stream closed with pipeline_completed",
                False,
                f'Last chunk status: "{complete_status}"',
            )

        print()
        print("  -> Streaming endpoint working")

    except httpx.ConnectError:
        record("Streaming endpoint", False, f"Cannot connect to {BASE_URL}")
    except httpx.ReadTimeout:
        record("Streaming endpoint", False, f"Timed out after {TIMEOUT}s")
    except Exception as e:
        record("Streaming endpoint", False, str(e))


# =========================================================================
# Test 6 — Non-Breach Scenario
# =========================================================================

def test_6_non_breach_scenario() -> None:
    """
    POST /trigger-breach with TRK-001 at 5.0 C (normal temp).
    Verify breach_detected: false and no agents triggered.
    """
    print()
    print("=" * 60)
    print("  Test 6: Non-Breach Scenario")
    print("=" * 60)

    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            payload = {
                "truck_id": "TRK-001",
                "temperature": 5.0,
            }

            resp = client.post("/trigger-breach", json=payload)

            if resp.status_code != 200:
                record(
                    "POST /trigger-breach (non-breach) returns 200",
                    False,
                    f"Got status {resp.status_code}: {resp.text[:200]}",
                )
                return

            data = resp.json()

            # Check breach_detected is false
            breach_detected = data.get("breach_detected", True)
            if "steps" in data and len(data["steps"]) > 0:
                breach_detected = data["steps"][0].get("output", {}).get("breach_detected", True)
                
            if breach_detected:
                record(
                    "breach_detected is false",
                    False,
                    f"Got breach_detected={breach_detected} (should be false for 5.0C)",
                )
            else:
                record("breach_detected is false for normal temp", True)

            # Check no agents were triggered except the first one
            agents_output = data.get("steps", data.get("agents", data.get("agent_results", None)))
            if agents_output is None or agents_output == {} or agents_output == []:
                record("No agents triggered for non-breach", True)
            elif isinstance(agents_output, list) and len(agents_output) == 1 and agents_output[0].get("agent") == "SensorMonitorAgent":
                record("No agents triggered for non-breach", True)
            else:
                extra = list(agents_output.keys()) if isinstance(agents_output, dict) else len(agents_output)
                record(
                    "No agents triggered for non-breach",
                    False,
                    f"Agents were triggered: {extra}",
                )

        print()
        print("  -> Non-breach correctly ignored")

    except httpx.ConnectError:
        record("Non-breach scenario", False, f"Cannot connect to {BASE_URL}")
    except Exception as e:
        record("Non-breach scenario", False, str(e))


# =========================================================================
# Summary
# =========================================================================

def print_summary() -> None:
    """Print final summary of all test results."""
    print()
    print()
    print("=" * 60)
    print("  INTEGRATION TEST SUMMARY")
    print("=" * 60)
    print()

    passed = [t for t in test_results if t["passed"]]
    failed = [t for t in test_results if not t["passed"]]

    print(f"  Total:  {len(test_results)}")
    print(f"  Passed: {len(passed)}")
    print(f"  Failed: {len(failed)}")
    print()

    if failed:
        print("  FAILED TESTS:")
        print("  " + "-" * 56)
        for t in failed:
            print(f"  [FAIL] {t['name']}")
            if t["detail"]:
                print(f"         {t['detail']}")
        print()
        print("  RESULT: SOME TESTS FAILED -- Review errors above")
        return False
    else:
        print("  ALL TESTS PASSED -- System ready for demo")
        return True


# =========================================================================
# Main
# =========================================================================

if __name__ == "__main__":
    print()
    print("*" * 60)
    print("  ColdChain AI — End-to-End Integration Tests")
    print(f"  Target: {BASE_URL}")
    print(f"  Time:   {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("*" * 60)

    test_1_backend_health_check()
    test_2_breach_detection()
    test_3_agent_pipeline()
    test_4_firebase_updates()
    test_5_streaming_endpoint()
    test_6_non_breach_scenario()

    all_passed = print_summary()
    sys.exit(0 if all_passed else 1)
