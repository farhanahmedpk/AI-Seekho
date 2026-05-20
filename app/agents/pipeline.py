"""
Agent Pipeline Orchestrator

Chains the 4 agents sequentially:
  Sensor Monitor → Analysis → Decision → Execution

Each agent's output feeds into the next.  All results are saved
to Firebase under the breach record for real-time frontend updates.
"""

from datetime import datetime

from loguru import logger

from app.agents import (
    sensor_monitor_agent,
    analysis_agent,
    decision_agent,
    execution_agent,
)
from app.models.schemas import BreachStatus
from app.services.firebase_service import FirebaseService


async def run_agent_pipeline(
    breach_id: str,
    breach_data: dict,
    firebase: FirebaseService,
):
    """
    Execute the full agent pipeline for a detected breach.

    Flow:
        1. Sensor Monitor Agent — validates the breach
        2. Analysis Agent — assesses severity and affected shipments
        3. Decision Agent — recommends actions
        4. Execution Agent — simulates carrying out actions

    Each step updates Firebase so the Flutter frontend can display
    real-time progress.
    """
    logger.info(f"{'='*60}")
    logger.info(f"🚀 STARTING AGENT PIPELINE — Breach: {breach_id}")
    logger.info(f"{'='*60}")

    try:
        # ── Step 1: Sensor Monitor Agent ───────────────────────
        logger.info("── Step 1/4: Sensor Monitor Agent ──")
        firebase.update_breach(breach_id, {"status": BreachStatus.DETECTED.value})

        sensor_history = firebase.get_latest_readings(breach_data.get("truck_id", ""))
        monitor_result = await sensor_monitor_agent.run(breach_data, sensor_history)

        firebase.save_agent_response(breach_id, "sensor_monitor", {
            "result": monitor_result,
            "timestamp": datetime.utcnow().isoformat(),
        })

        # If the monitor agent says it's not a real breach, stop here
        if not monitor_result.get("breach_confirmed", True):
            logger.info(f"✅ Breach {breach_id} dismissed as false positive")
            firebase.update_breach(breach_id, {
                "status": BreachStatus.RESOLVED.value,
                "resolved_at": datetime.utcnow().isoformat(),
                "resolution": "dismissed_false_positive",
            })
            return

        # ── Step 2: Analysis Agent ─────────────────────────────
        logger.info("── Step 2/4: Analysis Agent ──")
        firebase.update_breach(breach_id, {"status": BreachStatus.ANALYZING.value})

        shipment_data = firebase.get_shipments_by_truck(breach_data.get("truck_id", ""))
        analysis_result = await analysis_agent.run(breach_data, shipment_data)

        firebase.save_agent_response(breach_id, "analysis", {
            "result": analysis_result,
            "timestamp": datetime.utcnow().isoformat(),
        })

        # Update breach severity based on analysis
        firebase.update_breach(breach_id, {
            "severity": analysis_result.get("severity", breach_data.get("severity")),
            "analysis": analysis_result,
        })

        # ── Step 3: Decision Agent ─────────────────────────────
        logger.info("── Step 3/4: Decision Agent ──")
        firebase.update_breach(breach_id, {
            "status": BreachStatus.ACTION_RECOMMENDED.value,
        })

        decision_result = await decision_agent.run(breach_data, analysis_result)

        firebase.save_agent_response(breach_id, "decision", {
            "result": decision_result,
            "timestamp": datetime.utcnow().isoformat(),
        })

        firebase.update_breach(breach_id, {
            "recommended_actions": decision_result,
        })

        # ── Step 4: Execution Agent ────────────────────────────
        logger.info("── Step 4/4: Execution Agent ──")
        firebase.update_breach(breach_id, {
            "status": BreachStatus.EXECUTING.value,
        })

        execution_result = await execution_agent.run(breach_data, decision_result)

        firebase.save_agent_response(breach_id, "execution", {
            "result": execution_result,
            "timestamp": datetime.utcnow().isoformat(),
        })

        # ── Finalize ──────────────────────────────────────────
        firebase.update_breach(breach_id, {
            "status": BreachStatus.RESOLVED.value,
            "resolved_at": datetime.utcnow().isoformat(),
            "execution_log": execution_result,
        })

        # Push a notification for the Flutter frontend
        firebase.push_notification({
            "type": "breach_resolved",
            "breach_id": breach_id,
            "truck_id": breach_data.get("truck_id"),
            "severity": analysis_result.get("severity"),
            "summary": execution_result.get("summary", "Breach handled"),
            "timestamp": datetime.utcnow().isoformat(),
        })

        logger.info(f"{'='*60}")
        logger.info(f"✅ PIPELINE COMPLETE — Breach: {breach_id}")
        logger.info(f"{'='*60}")

    except Exception as e:
        logger.error(f"❌ Pipeline failed for breach {breach_id}: {e}")
        firebase.update_breach(breach_id, {
            "status": "error",
            "error": str(e),
            "error_at": datetime.utcnow().isoformat(),
        })
        raise
