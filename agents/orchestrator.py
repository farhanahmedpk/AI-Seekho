"""
Orchestrator for the Cold Chain Breach Detection System.

Connects the 4 specialized AI agents into a single sequential pipeline:
1. Sensor Monitor -> 2. Analysis -> 3. Decision -> 4. Execution

Usage:
    from agents.orchestrator import run_pipeline
    trace = await run_pipeline("TRK-004", 12.5)
"""

import time
import uuid
from datetime import datetime, timezone

from loguru import logger
from firebase_admin import db

from firebase_config import initialize_firebase, get_truck_data

# Import the 4 agents
from agents.sensor_monitor import sensor_monitor_agent
from agents.analysis_agent import analysis_agent
from agents.decision_agent import decision_agent
from agents.execution_agent import execution_agent


async def run_pipeline(truck_id: str, temperature: float) -> dict:
    """
    Run the full 4-agent AI pipeline for a given temperature reading.
    
    Args:
        truck_id: The ID of the truck (e.g., "TRK-004")
        temperature: The newly recorded temperature reading
        
    Returns:
        A comprehensive JSON trace of the entire agent workflow.
    """
    logger.info(f"🚀 [PIPELINE START] Truck: {truck_id} | Temp: {temperature}C")
    
    start_time = time.time()
    pipeline_start_iso = datetime.now(timezone.utc).isoformat()
    incident_id = f"INC-{uuid.uuid4().hex[:8].upper()}"

    # Ensure Firebase connection
    initialize_firebase()

    # ---------------------------------------------------------
    # 0. Prep Input Data
    # ---------------------------------------------------------
    truck_data = get_truck_data(truck_id)
    if not truck_data:
        raise ValueError(f"Truck ID '{truck_id}' not found in Firebase.")
    
    threshold_temp = truck_data.get("threshold_temp", 8.0)
    cargo_type = truck_data.get("cargo_type", "unknown")

    sensor_payload = {
        "truck_id": truck_id,
        "current_temp": temperature,
        "threshold_temp": threshold_temp,
        "cargo_type": cargo_type,
        "timestamp": pipeline_start_iso,
    }

    # Initialize the trace
    trace = {
        "incident_id": incident_id,
        "truck_id": truck_id,
        "temperature": temperature,
        "threshold_temp": threshold_temp,
        "pipeline_start": pipeline_start_iso,
        "steps": [],
        "final_outcome": {}
    }

    # ---------------------------------------------------------
    # 1. Sensor Monitor Agent
    # ---------------------------------------------------------
    logger.info(f"🔍 [Step 1/4] Running Sensor Monitor Agent...")
    sensor_result = await sensor_monitor_agent.analyze(sensor_payload)
    
    trace["steps"].append({
        "step": 1,
        "agent": "SensorMonitorAgent",
        "output": sensor_result
    })

    breach_detected = sensor_result.get("breach_detected", False)

    if not breach_detected:
        logger.info(f"✅ [PIPELINE STOP] No breach detected. Pipeline ending.")
        trace["final_outcome"] = {
            "status": "NORMAL",
            "breach_contained": True,
            "message": "Temperature is within safe limits. No action required."
        }
        return _finalize_pipeline(trace, start_time, incident_id)

    # ---------------------------------------------------------
    # 2. Analysis Agent
    # ---------------------------------------------------------
    logger.info(f"📊 [Step 2/4] Breach confirmed. Running Analysis Agent...")
    analysis_result = await analysis_agent.analyze(sensor_result)
    
    trace["steps"].append({
        "step": 2,
        "agent": "AnalysisAgent",
        "output": analysis_result
    })

    # ---------------------------------------------------------
    # 3. Decision Agent
    # ---------------------------------------------------------
    logger.info(f"🧠 [Step 3/4] Running Decision Agent...")
    decision_result = await decision_agent.analyze(sensor_result, analysis_result)
    
    trace["steps"].append({
        "step": 3,
        "agent": "DecisionAgent",
        "output": decision_result
    })

    # ---------------------------------------------------------
    # 4. Execution Agent
    # ---------------------------------------------------------
    logger.info(f"⚡ [Step 4/4] Executing recommended actions...")
    execution_result = await execution_agent.execute(
        decision_result, 
        analysis_result, 
        sensor_result, 
        incident_id
    )
    
    trace["steps"].append({
        "step": 4,
        "agent": "ExecutionAgent",
        "output": execution_result
    })

    # ---------------------------------------------------------
    # 5. Extract Final Outcome
    # ---------------------------------------------------------
    quarantined = False
    notified = False
    replaced = False

    for action in execution_result.get("actions_executed", []):
        act_name = action.get("action", "")
        if "QUARANTINE" in act_name: quarantined = True
        if "NOTIFY" in act_name: notified = True
        if "REPLACE" in act_name: replaced = True

    trace["final_outcome"] = {
        "shipment_status": "QUARANTINED" if quarantined else "IN_TRANSIT",
        "client_notified": notified,
        "replacement_ordered": replaced,
        "breach_contained": quarantined
    }

    return _finalize_pipeline(trace, start_time, incident_id)


def _finalize_pipeline(trace: dict, start_time: float, incident_id: str) -> dict:
    """Helper to add timing, save to Firebase, and return the trace."""
    end_time = time.time()
    trace["pipeline_end"] = datetime.now(timezone.utc).isoformat()
    trace["total_duration_seconds"] = round(end_time - start_time, 2)
    
    try:
        # Save trace directly to /incidents/{incident_id}
        db.reference(f"/incidents/{incident_id}").set(trace)
        logger.info(f"💾 [PIPELINE SAVED] Trace written to Firebase at /incidents/{incident_id}")
    except Exception as e:
        logger.error(f"Failed to save incident trace to Firebase: {e}")

    logger.info(f"🏁 [PIPELINE COMPLETE] Time: {trace['total_duration_seconds']}s")
    
    return trace


# ---------------------------------------------------------------------------
#  Self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio
    import json

    async def _test():
        print("=== Orchestrator Pipeline Test ===")
        # Test with TRK-004 which should trigger a breach
        trace = await run_pipeline("TRK-004", 16.5)
        
        # Save output to local file for review
        with open("test_trace_output.json", "w") as f:
            json.dump(trace, f, indent=2)
            
        print(f"Pipeline complete in {trace.get('total_duration_seconds')}s.")
        print(f"Incident ID: {trace.get('incident_id')}")
        print("Full trace saved to 'test_trace_output.json'")
        print("\nFinal Outcome:")
        print(json.dumps(trace.get("final_outcome"), indent=2))

    asyncio.run(_test())
