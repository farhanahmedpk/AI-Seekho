"""
Cold Chain Breach Detection System — FastAPI Backend

Endpoints:
    GET  /sensors                                    — All truck sensor readings
    GET  /shipments                                  — All shipments with current status
    POST /trigger-breach                             — Simulate a breach and run the 4-agent pipeline
    GET  /incidents                                  — All logged incidents
    GET  /agent-trace/{incident_id}                  — Full agent reasoning trace for an incident
    GET  /agent-trace/stream/{truck_id}/{temperature} — SSE stream of agent pipeline in real time
    GET  /reset-demo                                 — Re-seed Firebase data and clear incidents
"""

import json
import uuid
import asyncio
from datetime import datetime, timezone
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from loguru import logger
from firebase_admin import db

from firebase_config import (
    initialize_firebase,
    read_sensor_data,
    get_truck_data,
    get_all_incidents,
)

from agents.orchestrator import run_pipeline
from agents.sensor_monitor import sensor_monitor_agent
from agents.analysis_agent import analysis_agent
from agents.decision_agent import decision_agent
from agents.execution_agent import execution_agent


# ── Lifespan ───────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize Firebase on startup."""
    logger.info("[STARTUP] Cold Chain Breach Detection System starting up...")
    initialize_firebase()
    logger.info("[FIREBASE] Firebase connected")
    yield
    logger.info("[SHUTDOWN] Shutting down")


# ── App Factory ────────────────────────────────────────────────

app = FastAPI(
    title="Cold Chain Breach Detection System",
    description="Real-time temperature monitoring with AI-driven multi-agent breach response.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow Flutter frontend and any dev origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ══════════════════════════════════════════════════════════════
#  Request / Response Models
# ══════════════════════════════════════════════════════════════

class BreachRequest(BaseModel):
    """POST body for /trigger-breach."""
    truck_id: str = Field(..., example="TRK-004")
    temperature: float = Field(..., example=12.5)

class UnstructuredRequest(BaseModel):
    """POST body for /analyze-unstructured."""
    content: str = Field(..., example="Driver reports TRK-004 cooling unit failed. Temperature is 15 degrees.")


# ══════════════════════════════════════════════════════════════
#  Endpoints
# ══════════════════════════════════════════════════════════════

@app.get("/", tags=["Health"])
async def health_check():
    """System health check."""
    return {
        "status": "operational",
        "system": "Cold Chain Breach Detection System",
        "version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


# ── GET /sensors ───────────────────────────────────────────────

@app.get("/sensors", tags=["Sensors"])
async def get_sensors():
    """Returns all truck sensor readings from Firebase."""
    try:
        data = read_sensor_data()

        if not data:
            return {"sensors": [], "count": 0}

        sensors = []
        for truck_id, truck in data.items():
            sensors.append({
                "truck_id": truck.get("truck_id", truck_id),
                "current_temp": truck.get("current_temp"),
                "threshold_temp": truck.get("threshold_temp", 8.0),
                "status": truck.get("status", "unknown"),
                "cargo_type": truck.get("cargo_type", "unknown"),
                "driver_name": truck.get("driver_name", "N/A"),
                "origin": truck.get("origin"),
                "destination": truck.get("destination"),
                "last_updated": truck.get("last_updated"),
            })

        sensors.sort(key=lambda s: s["truck_id"])
        return {"sensors": sensors, "count": len(sensors)}

    except Exception as e:
        logger.error(f"Failed to read sensors: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to read sensor data: {str(e)}")


# ── GET /shipments ─────────────────────────────────────────────

@app.get("/shipments", tags=["Shipments"])
async def get_shipments():
    """Returns all shipments from Firebase with their current status."""
    try:
        ref = db.reference("/shipments")
        data = ref.get()

        if not data:
            return {"shipments": [], "count": 0}

        shipments = []
        for ship_id, ship in data.items():
            shipments.append({
                "shipment_id": ship.get("shipment_id", ship_id),
                "truck_id": ship.get("truck_id"),
                "product_type": ship.get("product_type"),
                "quantity": ship.get("quantity"),
                "origin": ship.get("origin"),
                "destination": ship.get("destination"),
                "required_temp_min": ship.get("required_temp_min"),
                "required_temp_max": ship.get("required_temp_max"),
                "status": ship.get("status"),
                "value_usd": ship.get("value_usd"),
                "loaded_at": ship.get("loaded_at"),
                "estimated_arrival": ship.get("estimated_arrival"),
            })

        shipments.sort(key=lambda s: s["shipment_id"])
        return {"shipments": shipments, "count": len(shipments)}

    except Exception as e:
        logger.error(f"Failed to read shipments: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to read shipments: {str(e)}")


# ── POST /trigger-breach ───────────────────────────────────────

@app.post("/trigger-breach", tags=["Trigger"])
async def trigger_breach(request: BreachRequest):
    """
    Simulate a sensor reading a temperature breach.
    This triggers the full 4-agent pipeline and returns the complete trace.
    """
    truck_id = request.truck_id
    temperature = request.temperature

    # Ensure the truck exists
    truck_data = get_truck_data(truck_id)
    if not truck_data:
        raise HTTPException(status_code=404, detail=f"Truck {truck_id} not found.")

    # 1. Update the sensor data in Firebase
    try:
        ref = db.reference(f"/sensors/{truck_id}")
        ref.update({
            "current_temp": temperature,
            "status": "breach",
            "last_updated": datetime.now(timezone.utc).isoformat()
        })
        logger.info(f"[TRIGGER] Truck {truck_id} temperature set to {temperature}C")
    except Exception as e:
        logger.error(f"Failed to update sensor data: {e}")
        raise HTTPException(status_code=500, detail="Database update failed.")

    # 2. Run the agent pipeline
    trace = await run_pipeline(truck_id, temperature)

    return trace


@app.post("/analyze-unstructured", tags=["Trigger"])
async def analyze_unstructured(request: UnstructuredRequest):
    """
    Analyzes unstructured text report to extract truck_id and temperature.
    If a breach is detected, it automatically runs the pipeline.
    """
    content = request.content
    
    prompt = (
        f"Analyze this unstructured logistics report: '{content}'\n"
        f"Does it describe a temperature issue or breach for a specific truck?\n"
        f"If yes, extract the truck_id (e.g. TRK-004) and the temperature (as a float).\n"
        f"Respond ONLY with a JSON object in this format:\n"
        f"{{\n"
        f"  \"breach_found\": true/false,\n"
        f"  \"truck_id\": \"TRK-XXX\",\n"
        f"  \"temperature\": 15.5\n"
        f"}}\n"
        f"If no actionable breach is found, return {{\"breach_found\": false}}."
    )
    
    try:
        from agents.llm_helper import query_llm_async
        content = await query_llm_async(prompt, temperature=0.1, timeout=15.0)
        
        # Extract JSON from response if LLM adds markdown or fluff
        if "{" in content and "}" in content:
            content = content[content.find("{"):content.rfind("}")+1]
            
        parsed = json.loads(content)
    except Exception as e:
        logger.warning(f"Failed to parse unstructured text with OpenRouter, applying mock: {e}")
        # Mock extraction if API fails
        if "TRK-004" in content:
            parsed = {
                "breach_found": True,
                "truck_id": "TRK-004",
                "temperature": 12.0
            }
        else:
            parsed = {
                "breach_found": False
            }
            
    if not parsed.get("breach_found"):
        return {"summary": "No actionable breach found in report."}
        
    truck_id = parsed.get("truck_id")
    temperature = float(parsed.get("temperature", 0.0))
    
    logger.info(f"[TRIGGER] Unstructured text detected breach for {truck_id} at {temperature}C")
    
    # 1. Update the sensor data in Firebase
    truck_data = get_truck_data(truck_id)
    if truck_data:
        try:
            ref = db.reference(f"/sensors/{truck_id}")
            ref.update({
                "current_temp": temperature,
                "status": "breach",
                "last_updated": datetime.now(timezone.utc).isoformat()
            })
        except Exception as e:
            logger.error(f"Failed to update sensor data: {e}")
            
    # 2. Run the pipeline
    trace = await run_pipeline(truck_id, temperature)
    
    return {
        "summary": f"Detected breach for {truck_id} at {temperature}C. Pipeline triggered.",
        "trace": trace
    }


# ── POST /resolve-all-breaches ─────────────────────────────────

async def _run_pipeline_background(truck_id: str, temperature: float):
    try:
        await run_pipeline(truck_id, temperature)
    except Exception as e:
        logger.error(f"Background pipeline execution failed for {truck_id}: {e}")


@app.post("/resolve-all-breaches", tags=["Trigger"])
async def resolve_all_breaches():
    """
    Finds all trucks currently in breach and runs the full agent pipeline
    for each one in the background. Returns immediately.
    """
    # 1. Read all trucks from Firebase
    try:
        data = read_sensor_data()
    except Exception as e:
        logger.error(f"Failed to read sensors: {e}")
        raise HTTPException(status_code=500, detail="Failed to read sensor data")
        
    if not data:
        return {
            "status": "pipelines_started",
            "total_breaches_found": 0,
            "pipelines_triggered": 0
        }
        
    # 2. Find breached trucks
    breached_trucks = []
    for truck_id, truck in data.items():
        status = truck.get("status", "")
        current_temp = float(truck.get("current_temp", 0.0))
        threshold_temp = float(truck.get("threshold_temp", 8.0))
        
        if status == "breach" and current_temp > threshold_temp:
            breached_trucks.append({
                "truck_id": truck.get("truck_id", truck_id),
                "temperature": current_temp
            })
            
    total_breaches = len(breached_trucks)
    
    if total_breaches == 0:
        return {
            "status": "pipelines_started",
            "total_breaches_found": 0,
            "pipelines_triggered": 0
        }
        
    logger.info(f"[BATCH] Found {total_breaches} breached trucks. Spawning background tasks...")
    
    # 3. Spawn background tasks
    for bt in breached_trucks:
        asyncio.create_task(_run_pipeline_background(bt["truck_id"], bt["temperature"]))
        
    return {
        "status": "pipelines_started",
        "total_breaches_found": total_breaches,
        "pipelines_triggered": total_breaches
    }


# ── GET /incidents ─────────────────────────────────────────────

@app.get("/incidents", tags=["Incidents"])
async def get_incidents():
    """Returns all logged incidents from Firebase."""
    try:
        data = get_all_incidents()

        if not data:
            return {"incidents": [], "count": 0}

        incidents = []
        for key, incident in data.items():
            incident_id = incident.get("incident_id")
            # 1. Deduplicate: only keep records where key == incident_id
            if key != incident_id:
                continue

            # 2. Extract nested data from trace
            steps = incident.get("steps", [])
            final_outcome = incident.get("final_outcome", {})
            
            # severity from steps[0].output.severity
            severity = incident.get("severity", "unknown")
            if steps and len(steps) > 0:
                output = steps[0].get("output")
                if isinstance(output, dict):
                    severity = output.get("severity", severity)
                    
            # status from final_outcome.breach_contained
            contained = final_outcome.get("breach_contained")
            status = "contained" if contained is True else "unresolved"
            
            # cargo_type from steps[1].output.cargo_at_risk
            cargo_type = incident.get("cargo_type")
            if len(steps) > 1:
                output1 = steps[1].get("output")
                if isinstance(output1, dict):
                    cargo_type = output1.get("cargo_at_risk", cargo_type)

            incidents.append({
                "firebase_key": key,
                "incident_id": incident_id,
                "truck_id": incident.get("truck_id"),
                "temperature": incident.get("temperature"),
                "severity": severity,
                "cargo_type": cargo_type,
                "status": status,
                "detected_at": incident.get("detected_at", incident.get("pipeline_start")),
                "resolved_at": incident.get("resolved_at", incident.get("pipeline_end")),
                "total_duration": incident.get("total_duration") or (
                    (datetime.fromisoformat(incident.get("resolved_at", incident.get("pipeline_end")).replace('Z', '+00:00')) - 
                     datetime.fromisoformat(incident.get("detected_at", incident.get("pipeline_start")).replace('Z', '+00:00'))
                    ).total_seconds() if incident.get("detected_at", incident.get("pipeline_start")) and incident.get("resolved_at", incident.get("pipeline_end")) else 0.0
                ),
                "logged_at": incident.get("logged_at"),
            })

        incidents.sort(key=lambda i: i.get("logged_at") or "", reverse=True)
        return {"incidents": incidents, "count": len(incidents)}

    except Exception as e:
        logger.error(f"Failed to read incidents: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to read incidents: {str(e)}")


# ── GET /agent-trace/{incident_id} ─────────────────────────────

@app.get("/agent-trace/{incident_id}", tags=["Agents"])
async def get_agent_trace(incident_id: str):
    """Returns the full step-by-step agent reasoning trace for a specific incident."""
    try:
        data = get_all_incidents()

        if not data:
            raise HTTPException(status_code=404, detail="No incidents found")

        # 1. Try direct lookup first (most reliable for new orchestrator traces)
        direct_match = data.get(incident_id)
        if direct_match and isinstance(direct_match, dict):
            trace = direct_match.get("steps") or direct_match.get("agent_trace")
            if trace:
                return direct_match

        # 2. Search all records for a match that HAS steps
        best_match = None
        for key, incident in data.items():
            if not isinstance(incident, dict):
                continue
                
            if incident.get("incident_id") == incident_id or key == incident_id:
                trace = incident.get("steps") or incident.get("agent_trace")
                if trace:
                    return incident
                best_match = incident # Store partial match if no full trace found yet

        if best_match:
            logger.warning(f"Incident '{incident_id}' found but has no agent trace. Keys: {list(best_match.keys())}")
            raise HTTPException(
                status_code=404,
                detail=f"Incident '{incident_id}' found but has no agent trace. Keys available: {list(best_match.keys())}",
            )

        raise HTTPException(
            status_code=404,
            detail=f"Incident '{incident_id}' not found. Use GET /incidents to see all IDs.",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to read agent trace: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to read agent trace: {str(e)}")


# -- GET /agent-trace/stream/{truck_id}/{temperature} -------------------

@app.get("/agent-trace/stream/{truck_id}/{temperature}", tags=["Agents"])
async def stream_agent_trace(truck_id: str, temperature: float):
    """
    Server-Sent Events (SSE) stream of the 4-agent pipeline running in real time.
    """
    truck_data = get_truck_data(truck_id)
    if not truck_data:
        raise HTTPException(
            status_code=404,
            detail=f"Truck '{truck_id}' not found. Valid IDs: TRK-001 to TRK-010",
        )

    threshold = truck_data.get("threshold_temp", 8.0)

    async def event_generator():
        incident_id = f"INC-{uuid.uuid4().hex[:8].upper()}"
        now = datetime.now(timezone.utc).isoformat()

        # Update truck temp in Firebase
        ref = db.reference(f"/sensors/{truck_id}")
        ref.update({
            "current_temp": temperature,
            "status": "breach" if temperature > threshold else "normal",
            "last_updated": now,
        })

        # Send start event
        yield f"data: {json.dumps({'event': 'pipeline_started', 'incident_id': incident_id, 'truck_id': truck_id, 'temperature': temperature})}\n\n"
        await asyncio.sleep(0.3)

        sensor_payload = {
            "truck_id": truck_id,
            "current_temp": temperature,
            "threshold_temp": threshold,
            "cargo_type": truck_data.get("cargo_type", "unknown"),
            "timestamp": now,
        }

        # --- Agent 1: Sensor Monitor ---
        yield f"data: {json.dumps({'event': 'agent_started', 'step': 1, 'agent': 'Sensor Monitor Agent'})}\n\n"
        monitor_result = await sensor_monitor_agent.analyze(sensor_payload)
        yield f"data: {json.dumps({'event': 'agent_completed', 'step': 1, 'agent': 'Sensor Monitor Agent', 'result': monitor_result})}\n\n"
        await asyncio.sleep(0.3)

        if not monitor_result.get("breach_detected", True):
            yield f"data: {json.dumps({'event': 'pipeline_completed', 'status': 'dismissed', 'summary': 'False positive'})}\n\n"
            return

        # --- Agent 2: Analysis ---
        yield f"data: {json.dumps({'event': 'agent_started', 'step': 2, 'agent': 'Analysis Agent'})}\n\n"
        analysis_result = await analysis_agent.analyze(monitor_result)
        yield f"data: {json.dumps({'event': 'agent_completed', 'step': 2, 'agent': 'Analysis Agent', 'result': analysis_result})}\n\n"
        await asyncio.sleep(0.3)

        # --- Agent 3: Decision ---
        yield f"data: {json.dumps({'event': 'agent_started', 'step': 3, 'agent': 'Decision Agent'})}\n\n"
        decision_result = await decision_agent.analyze(monitor_result, analysis_result)
        yield f"data: {json.dumps({'event': 'agent_completed', 'step': 3, 'agent': 'Decision Agent', 'result': decision_result})}\n\n"
        await asyncio.sleep(0.3)

        # --- Agent 4: Execution ---
        yield f"data: {json.dumps({'event': 'agent_started', 'step': 4, 'agent': 'Execution Agent'})}\n\n"
        execution_result = await execution_agent.execute(decision_result, analysis_result, monitor_result, incident_id)
        yield f"data: {json.dumps({'event': 'agent_completed', 'step': 4, 'agent': 'Execution Agent', 'result': execution_result})}\n\n"

        # Compile and save the final trace exactly like the orchestrator
        quarantined = False
        notified = False
        replaced = False

        for action in execution_result.get("actions_executed", []):
            act_name = action.get("action", "")
            if "QUARANTINE" in act_name: quarantined = True
            if "NOTIFY" in act_name: notified = True
            if "REPLACE" in act_name: replaced = True

        trace = {
            "incident_id": incident_id,
            "truck_id": truck_id,
            "temperature": temperature,
            "threshold_temp": threshold,
            "pipeline_start": now,
            "pipeline_end": datetime.now(timezone.utc).isoformat(),
            "steps": [
                {"step": 1, "agent": "SensorMonitorAgent", "output": monitor_result},
                {"step": 2, "agent": "AnalysisAgent", "output": analysis_result},
                {"step": 3, "agent": "DecisionAgent", "output": decision_result},
                {"step": 4, "agent": "ExecutionAgent", "output": execution_result},
            ],
            "final_outcome": {
                "shipment_status": "QUARANTINED" if quarantined else "IN_TRANSIT",
                "client_notified": notified,
                "replacement_ordered": replaced,
                "breach_contained": quarantined
            }
        }
        
        try:
            db.reference(f"/incidents/{incident_id}").set(trace)
        except Exception as e:
            logger.error(f"Failed to save stream trace to Firebase: {e}")

        yield f"data: {json.dumps({'event': 'pipeline_completed', 'status': 'resolved', 'incident_id': incident_id, 'summary': 'Pipeline execution completed'})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


# -- GET /reset-demo ----------------------------------------------------

@app.get("/reset-demo", tags=["Demo"])
async def reset_demo():
    """
    Re-seed Firebase with original truck/shipment data and clear all incidents.
    Useful for resetting the demo to a clean state.
    """
    try:
        from scripts.seed_data import seed_sensors, seed_shipments, seed_sensor_config

        db.reference("/incidents").delete()
        logger.info("[RESET] Cleared /incidents")

        seed_sensors()
        seed_shipments()
        seed_sensor_config()
        logger.info("[RESET] Re-seeded trucks, shipments, sensor config")

        return {
            "status": "reset_complete",
            "message": "Firebase data re-seeded and incidents cleared",
            "trucks": 10,
            "shipments": 10,
            "incidents_cleared": True,
        }
    except Exception as e:
        logger.error(f"Reset failed: {e}")
        raise HTTPException(status_code=500, detail=f"Reset failed: {str(e)}")


# ======================================================================
#  Run
# ======================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
