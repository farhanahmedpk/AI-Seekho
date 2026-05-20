"""
Agent 4 -- Execution Agent

Receives the recommended actions from the Decision Agent and simulates executing
each one by one with a delay. Performs actual database updates for quarantine,
and uses Gemini to generate notification emails and replacement orders.

Writes all execution results to Firebase under /incidents/{incident_id}.

Usage:
    from agents.execution_agent import ExecutionAgent

    agent = ExecutionAgent()
    result = await agent.execute(decision_result, analysis_result, sensor_result, incident_id)
"""

import os
import json
import uuid
import asyncio
import time
from datetime import datetime, timezone, timedelta

from dotenv import load_dotenv
import requests
from loguru import logger
from firebase_admin import db

from firebase_config import initialize_firebase, update_shipment_status

load_dotenv()

# ---------------------------------------------------------------------------
#  Gemini client
# ---------------------------------------------------------------------------

# ── OpenRouter ─────────────────────────────────────────────────────────────
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = "openrouter/free"


# ---------------------------------------------------------------------------
#  ExecutionAgent class
# ---------------------------------------------------------------------------

class ExecutionAgent:
    """
    Agent 4 of the breach-detection pipeline.

    Executes recommended actions and finalizes the incident in Firebase.
    """

    AGENT_NAME = "ExecutionAgent"

    # ------------------------------------------------------------------
    #  Public API
    # ------------------------------------------------------------------

    async def execute(
        self,
        decision_result: dict,
        analysis_result: dict,
        sensor_result: dict,
        incident_id: str,
    ) -> dict:
        """
        Run the Execution Agent.

        Args:
            decision_result: Dict output from DecisionAgent
            analysis_result: Dict output from AnalysisAgent
            sensor_result: Dict output from SensorMonitorAgent
            incident_id: ID of the current incident (e.g., "INC-12345")

        Returns:
            Structured dict containing execution status.
        """
        start_time = time.time()
        timestamp = datetime.now(timezone.utc).isoformat()
        
        actions = decision_result.get("recommended_actions", [])
        executed_actions = []

        # Ensure Firebase is initialized
        initialize_firebase()

        # Gather context for Gemini generation tasks
        shipment_id = analysis_result.get("shipment_id", "Unknown")
        cargo_type = analysis_result.get("cargo_at_risk", "Unknown Cargo")
        truck_id = sensor_result.get("truck_id", "Unknown")
        current_temp = sensor_result.get("current_temp", "Unknown")
        threshold = sensor_result.get("threshold_temp", "Unknown")

        # Execute actions sequentially
        used_fallback_any = False
        for act in actions:
            action_type = act.get("action", "").upper()
            logger.info(f"Execution Agent: Processing action '{action_type}'")
            
            # Simulate a small delay for execution
            await asyncio.sleep(1.0)
            
            action_timestamp = datetime.now(timezone.utc).isoformat()
            result_payload = {}

            if "QUARANTINE" in action_type:
                # Actual DB update
                if shipment_id != "Unknown" and shipment_id is not None:
                    try:
                        update_shipment_status(shipment_id, "QUARANTINED")
                        
                        # Reset truck status in demo
                        if truck_id:
                            try:
                                truck_ref = db.reference(f"/sensors/{truck_id}")
                                truck_ref.update({
                                    "status": "normal",
                                    "current_temp": 4.5 # Fixed temp
                                })
                                logger.info(f"Execution Agent: Reset truck {truck_id} status to normal")
                            except Exception as te:
                                logger.warning(f"Execution Agent: Could not reset truck status - {te}")

                        result_payload = {
                            "shipment_id": shipment_id,
                            "new_status": "QUARANTINED",
                            "updated_at": action_timestamp
                        }
                        logger.info(f"Execution Agent: Quarantined shipment {shipment_id}")
                    except Exception as e:
                        logger.error(f"Execution Agent: Failed to quarantine {shipment_id} - {e}")
                        result_payload = {"error": str(e), "shipment_id": shipment_id}
                else:
                    result_payload = {"error": "No specific shipment_id identified for quarantine."}

            elif "NOTIFY" in action_type:
                # Use Gemini to draft an email
                email_content, uf = await self._draft_notification(
                    incident_id=incident_id,
                    shipment_id=shipment_id,
                    cargo=cargo_type,
                    current_temp=current_temp,
                    threshold=threshold
                )
                if uf: used_fallback_any = True
                result_payload = {
                    "notification_type": "EMAIL",
                    "recipient": "medlife@pharma.pk",
                    "message": email_content,
                    "sent_at": action_timestamp
                }
                logger.info("Execution Agent: Generated notification email")

            elif "REPLACEMENT" in action_type or "REPLACE" in action_type:
                # Use Gemini to generate a replacement order
                order_details, uf = await self._generate_replacement_order(
                    cargo=cargo_type,
                    shipment_id=shipment_id
                )
                if uf: used_fallback_any = True
                result_payload = {
                    "order_id": order_details.get("order_id", f"REP-{uuid.uuid4().hex[:6].upper()}"),
                    "cargo": order_details.get("cargo", cargo_type),
                    "quantity": order_details.get("quantity", "Standard Batch"),
                    "origin_warehouse": order_details.get("origin_warehouse", "Nearest Cold Storage Depot"),
                    "destination": order_details.get("destination", "Original Client Destination"),
                    "priority": "URGENT",
                    "eta": (datetime.now(timezone.utc) + timedelta(hours=4)).isoformat(),
                    "created_at": action_timestamp
                }
                logger.info("Execution Agent: Generated replacement order")

            else:
                # Generic fallback for other actions (like SCHEDULE_INSPECTION)
                result_payload = {
                    "details": act.get("description", "Action executed"),
                    "completed_at": action_timestamp
                }
                logger.info(f"Execution Agent: Completed generic action '{action_type}'")

            # Append to results
            executed_actions.append({
                "action": action_type,
                "status": "COMPLETED",
                "result": result_payload,
                "timestamp": action_timestamp
            })

        response_time = round(time.time() - start_time, 2)

        # -- Build structured output ----------------------------------------
        final_result = {
            "agent": self.AGENT_NAME,
            "actions_executed": executed_actions,
            "total_response_time_seconds": response_time,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "used_fallback": used_fallback_any,
        }

        # -- Save to Firebase -----------------------------------------------
        self._write_to_firebase(incident_id, final_result)

        # -- Log trace ------------------------------------------------------
        self._log_result(final_result, incident_id)

        return final_result

    # ------------------------------------------------------------------
    #  Private helpers
    # ------------------------------------------------------------------

    async def _draft_notification(self, incident_id, shipment_id, cargo, current_temp, threshold) -> str:
        """Call Gemini to draft a professional client notification."""
        prompt = (
            f"Draft a professional email notification to a client about a cold chain breach.\n"
            f"Incident ID: {incident_id}\n"
            f"Shipment ID: {shipment_id}\n"
            f"Cargo: {cargo}\n"
            f"Details: Temperature reached {current_temp}C (Threshold was {threshold}C).\n"
            f"Include: Incident summary, affected shipment, cargo details, breach details, "
            f"a sincere apology, and next steps (e.g., quarantine and replacement).\n"
            f"Keep it professional, concise (3 paragraphs), and reassuring."
        )
        try:
            from agents.llm_helper import query_llm_async
            content = await query_llm_async(prompt, temperature=0.4, timeout=15.0)
            return content.strip(), False
        except Exception as e:
            logger.warning(f"Execution Agent: OpenRouter failed to draft email - {e}")
            fallback_email = (
                f"Subject: URGENT: Cold Chain Breach Notification - {shipment_id}\n\n"
                f"Dear Client,\n\n"
                f"We are writing to inform you of a temperature breach (Incident {incident_id}) "
                f"involving your shipment {shipment_id} containing {cargo}. "
                f"Sensors recorded a temperature of {current_temp}C, exceeding the safe limit of {threshold}C.\n\n"
                f"We apologize for this disruption. The shipment has been quarantined immediately "
                f"to prevent compromised goods from reaching you. We are automatically expediting "
                f"a replacement order to minimize delays.\n\n"
                f"Thank you for your understanding. We will provide tracking details for the replacement shortly."
            )
            return fallback_email, True

    async def _generate_replacement_order(self, cargo, shipment_id) -> dict:
        """Call Gemini to structure a replacement order JSON."""
        prompt = (
            f"Generate a JSON object for a replacement order for compromised cargo.\n"
            f"Original Shipment ID: {shipment_id}\n"
            f"Cargo: {cargo}\n"
            f"Respond ONLY with a JSON object containing these keys:\n"
            f"- order_id (string, e.g. REP-XXXXXX)\n"
            f"- cargo (string)\n"
            f"- quantity (string, realistic estimate based on typical cargo)\n"
            f"- origin_warehouse (string, realistic depot name)\n"
            f"- destination (string, e.g. 'Original Route Destination')"
        )
        try:
            from agents.llm_helper import query_llm_async
            content = await query_llm_async(prompt, temperature=0.3, timeout=15.0)
            
            # Extract JSON from response if Nemotron adds markdown or fluff
            if "{" in content and "}" in content:
                content = content[content.find("{"):content.rfind("}")+1]
                
            return json.loads(content), False
        except Exception as e:
            logger.warning(f"Execution Agent: OpenRouter failed to generate replacement order - {e}")
            return {}, True

    def _write_to_firebase(self, incident_id: str, final_result: dict):
        """Write the execution results to the specific incident in Firebase."""
        try:
            # We assume /incidents is a dictionary where keys might be Firebase push keys
            # or custom incident_id. We'll search for the incident by 'incident_id' field
            # and update it. If not found, we push a new record.
            ref = db.reference("/incidents")
            all_incidents = ref.get() or {}
            
            target_key = None
            for key, inc in all_incidents.items():
                if isinstance(inc, dict) and inc.get("incident_id") == incident_id:
                    target_key = key
                    break
            
            if target_key:
                # Update existing incident with execution details
                db.reference(f"/incidents/{target_key}/execution_result").set(final_result)
                logger.info(f"Execution Agent: Appended execution results to /incidents/{target_key}")
            else:
                # Incident not found, create a new record
                logger.warning(f"Execution Agent: Incident {incident_id} not found in Firebase. Creating new record.")
                ref.push({
                    "incident_id": incident_id,
                    "execution_result": final_result,
                    "logged_at": datetime.now(timezone.utc).isoformat()
                })
        except Exception as e:
            logger.error(f"Execution Agent: Failed to write to Firebase - {e}")

    @staticmethod
    def _log_result(result: dict, incident_id: str):
        """Log the agent output with a timestamp for the trace."""
        log_time = result["timestamp"]
        count = len(result["actions_executed"])
        duration = result["total_response_time_seconds"]

        logger.info(
            f"[{log_time}] ExecutionAgent | Incident={incident_id} | "
            f"Executed {count} actions in {duration}s"
        )

        # Full trace at debug level
        logger.debug(
            f"[{log_time}] ExecutionAgent full output: "
            f"{json.dumps(result, indent=2)}"
        )


# ---------------------------------------------------------------------------
#  Module-level convenience instance
# ---------------------------------------------------------------------------

execution_agent = ExecutionAgent()


# ---------------------------------------------------------------------------
#  Self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio

    async def _test():
        from agents.sensor_monitor import SensorMonitorAgent
        from agents.analysis_agent import AnalysisAgent
        from agents.decision_agent import DecisionAgent
        from firebase_config import initialize_firebase
        
        print("Initializing Firebase...")
        initialize_firebase()
        
        sensor_agent = SensorMonitorAgent()
        analysis_agent = AnalysisAgent()
        decision_agent = DecisionAgent()
        exec_agent = ExecutionAgent()

        incident_id = f"INC-TEST-{uuid.uuid4().hex[:4].upper()}"
        print(f"\n=== Test: Full pipeline Execution (Incident: {incident_id}) ===")
        
        # 1. Sensor
        sm_result = await sensor_agent.analyze({
            "truck_id": "TRK-004",
            "current_temp": 15.5,
            "threshold_temp": 8.0,
            "cargo_type": "vaccines",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        
        # 2. Analysis
        an_result = await analysis_agent.analyze(sm_result)
        
        # 3. Decision
        dc_result = await decision_agent.analyze(sm_result, an_result)
        
        # 4. Execution
        ex_result = await exec_agent.execute(dc_result, an_result, sm_result, incident_id)
        
        print(json.dumps(ex_result, indent=2))

    asyncio.run(_test())
