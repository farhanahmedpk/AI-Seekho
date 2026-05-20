import asyncio
import json
import time
from loguru import logger
from firebase_admin import db
from datetime import datetime, timezone

# Ensure we're running from the root of the project
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from firebase_config import initialize_firebase
from agents.orchestrator import run_pipeline

def print_section(title):
    print(f"\n{'=' * 60}")
    print(f" {title}")
    print(f"{'=' * 60}")

async def test_breach_scenario():
    print_section("SCENARIO 1: TEMPERATURE BREACH (TRK-004 @ 12.5C)")
    
    truck_id = "TRK-004"
    breach_temp = 12.5
    
    # 1. Update the truck's sensor reading in Firebase (simulate the real-world trigger)
    print("-> Simulating sensor payload hitting Firebase...")
    ref = db.reference(f"/sensors/{truck_id}")
    truck_data = ref.get()
    threshold = truck_data.get("threshold_temp", 8.0)
    
    ref.update({
        "current_temp": breach_temp,
        "status": "breach",
        "last_updated": datetime.now(timezone.utc).isoformat()
    })
    
    # Reset the shipment to in_transit to ensure a clean test
    shipments_ref = db.reference("/shipments")
    all_shipments = shipments_ref.get() or {}
    shipment_id = None
    for sid, s in all_shipments.items():
        if s.get("truck_id") == truck_id:
            shipment_id = sid
            db.reference(f"/shipments/{sid}").update({"status": "in_transit"})
            break

    # 2. Run the pipeline
    print("-> Triggering AI Agent Pipeline...")
    trace = await run_pipeline(truck_id, breach_temp)
    
    # 3. Print the results clearly
    print("\n--- Pipeline Execution Trace ---")
    
    for step in trace.get("steps", []):
        agent_name = step.get("agent")
        output = step.get("output", {})
        
        print(f"\n[AGENT] {agent_name} (Step {step.get('step')}):")
        
        if agent_name == "SensorMonitorAgent":
            print(f"  Breach Detected: {output.get('breach_detected')}")
            print(f"  Severity: {output.get('severity')}")
            print(f"  Reasoning: {output.get('reasoning')}")
            
        elif agent_name == "AnalysisAgent":
            print(f"  Cargo at Risk: {output.get('cargo_at_risk')}")
            print(f"  Spoilage Probability: {output.get('spoilage_probability')}")
            print(f"  Estimated Loss: {output.get('estimated_loss_pkr')}")
            print(f"  Impact Summary: {output.get('impact_summary')}")
            
        elif agent_name == "DecisionAgent":
            print(f"  Overall Reasoning: {output.get('overall_reasoning')}")
            print("  Recommended Actions:")
            for action in output.get("recommended_actions", []):
                print(f"    [{action.get('priority')}] {action.get('action')}: {action.get('urgency')}")
                
        elif agent_name == "ExecutionAgent":
            print(f"  Actions Executed: {len(output.get('actions_executed', []))}")
            for act in output.get('actions_executed', []):
                print(f"    - {act.get('action')} -> Status: {act.get('status')}")

    print(f"\n[TIME] Total Pipeline Duration: {trace.get('total_duration_seconds')} seconds")
    print(f"[ID] Incident ID: {trace.get('incident_id')}")
    
    # 4. Confirm Firebase Updates
    print("\n--- Verifying Firebase Updates ---")
    
    # Check if incident was logged
    incident = db.reference(f"/incidents/{trace.get('incident_id')}").get()
    if incident:
        print("[OK] Incident Trace successfully saved to /incidents")
    else:
        print("[FAIL] Incident Trace MISSING from /incidents")
        
    # Check if shipment was quarantined
    if shipment_id:
        shipment = db.reference(f"/shipments/{shipment_id}").get()
        if shipment and shipment.get("status") == "QUARANTINED":
            print(f"[OK] Shipment {shipment_id} successfully marked as QUARANTINED in database")
        else:
            print(f"[FAIL] Shipment {shipment_id} status is '{shipment.get('status')}' (Expected: QUARANTINED)")


async def test_normal_scenario():
    print_section("SCENARIO 2: NORMAL TEMPERATURE (TRK-004 @ 7.2C)")
    
    truck_id = "TRK-004"
    normal_temp = 7.2
    
    # 1. Update the truck's sensor reading
    print("-> Simulating sensor payload hitting Firebase...")
    ref = db.reference(f"/sensors/{truck_id}")
    ref.update({
        "current_temp": normal_temp,
        "status": "normal",
        "last_updated": datetime.now(timezone.utc).isoformat()
    })
    
    # 2. Run the pipeline
    print("-> Triggering AI Agent Pipeline...")
    trace = await run_pipeline(truck_id, normal_temp)
    
    # 3. Print the results
    print("\n--- Pipeline Execution Trace ---")
    for step in trace.get("steps", []):
        agent_name = step.get("agent")
        output = step.get("output", {})
        print(f"\n[AGENT] {agent_name} (Step {step.get('step')}):")
        if agent_name == "SensorMonitorAgent":
            print(f"  Breach Detected: {output.get('breach_detected')}")
            print(f"  Reasoning: {output.get('reasoning')}")
            
    print(f"\n[DONE] Final Outcome:")
    print(json.dumps(trace.get("final_outcome"), indent=2))
    
    print(f"\n[TIME] Total Pipeline Duration: {trace.get('total_duration_seconds')} seconds")

    # 4. Confirm it was still logged
    incident = db.reference(f"/incidents/{trace.get('incident_id')}").get()
    if incident:
        print("\n[OK] Normal reading trace successfully saved to /incidents")


async def main():
    print("Initializing Firebase...")
    initialize_firebase()
    
    # Disable loguru spam for a cleaner test output
    logger.remove()
    
    await test_breach_scenario()
    await asyncio.sleep(2)  # small pause between tests
    await test_normal_scenario()

if __name__ == "__main__":
    asyncio.run(main())
