"""
Agent 2 -- Analysis Agent

Receives the output JSON from the Sensor Monitor Agent, looks up affected
shipments in Firebase, and uses the Gemini API to assess spoilage risk,
financial impact (in PKR), and downstream consequences.

Returns a structured JSON result with the full analysis and logs it for the trace.

Usage:
    from agents.analysis_agent import AnalysisAgent

    agent = AnalysisAgent()
    result = await agent.analyze(sensor_monitor_result)
"""

import os
import json
from datetime import datetime, timezone

from dotenv import load_dotenv
import requests
from loguru import logger
from firebase_admin import db

from firebase_config import initialize_firebase

load_dotenv()

# ---------------------------------------------------------------------------
#  Gemini client (shared across calls for this agent)
# ---------------------------------------------------------------------------

# ── OpenRouter ─────────────────────────────────────────────────────────────
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = "openrouter/free"

# ---------------------------------------------------------------------------
#  System prompt -- tells Gemini *who* it is and what to return
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You are the Analysis Agent in an AI-powered Cold Chain Breach Detection System.

Your job is to receive a confirmed temperature breach event and cross-reference
it with shipment data to determine the full impact.

You will receive:
- Sensor Monitor Agent's output (breach severity, duration, truck ID, etc.)
- Affected Shipment Data (cargo type, value, origin, destination, quantity)

Using this information, identify:
1. What cargo is at risk and why (vaccines, dairy, meat have different spoilage risks).
2. Estimated spoilage probability (High, Medium, or Low) based on the temperature delta and duration.
3. Financial impact estimate (a rough range in PKR). Convert any USD values using a rough rate of 1 USD = 280 PKR.
4. Which downstream parties are affected (e.g., Hospital, Retailer, Warehouse, End Customer).

Produce a concise 3-4 sentence "impact_summary" that explains the full impact.

Respond ONLY with a JSON object in this exact format:
{
    "cargo_at_risk": "Short description of cargo and specific risk",
    "spoilage_probability": "High" | "Medium" | "Low",
    "estimated_loss_pkr": "e.g., 500,000 - 1,000,000 PKR",
    "affected_parties": ["Party 1", "Party 2"],
    "impact_summary": "Your 3-4 sentence explanation here."
}"""


# ---------------------------------------------------------------------------
#  AnalysisAgent class
# ---------------------------------------------------------------------------

class AnalysisAgent:
    """
    Agent 2 of the breach-detection pipeline.

    Looks up shipment details and uses Gemini to analyze business and safety impacts.
    """

    AGENT_NAME = "AnalysisAgent"

    # ------------------------------------------------------------------
    #  Public API
    # ------------------------------------------------------------------

    async def analyze(self, sensor_monitor_result: dict) -> dict:
        """
        Run the Analysis Agent using the output from the Sensor Monitor Agent.

        Args:
            sensor_monitor_result: Dict output from SensorMonitorAgent.analyze()

        Returns:
            Structured dict containing risk and impact analysis.
        """
        truck_id = sensor_monitor_result.get("truck_id")
        breach_detected = sensor_monitor_result.get("breach_detected", False)
        timestamp = datetime.now(timezone.utc).isoformat()

        # If no breach, there's no analysis needed.
        if not breach_detected:
            result = {
                "agent": self.AGENT_NAME,
                "shipment_id": None,
                "cargo_at_risk": "None",
                "spoilage_probability": "Low",
                "estimated_loss_pkr": "0 PKR",
                "affected_parties": [],
                "impact_summary": "No breach detected. Cargo is safe.",
                "timestamp": timestamp,
            }
            self._log_result(result)
            return result

        # Ensure Firebase is initialized
        initialize_firebase()

        # -- Fetch shipment data for this truck -----------------------------
        truck_shipments = self._get_shipments_by_truck(truck_id)
        
        # Determine a primary shipment ID for the output
        shipment_id = list(truck_shipments.keys())[0] if truck_shipments else "Unknown"

        # -- Ask Gemini for deeper analysis ---------------------------------
        analysis_output, used_fallback = await self._generate_analysis(
            sensor_result=sensor_monitor_result,
            shipments=truck_shipments,
        )

        # -- Build structured output ----------------------------------------
        result = {
            "agent": self.AGENT_NAME,
            "shipment_id": shipment_id,
            "cargo_at_risk": analysis_output.get("cargo_at_risk", "Unknown risk"),
            "spoilage_probability": analysis_output.get("spoilage_probability", "Medium"),
            "estimated_loss_pkr": analysis_output.get("estimated_loss_pkr", "Unknown"),
            "affected_parties": analysis_output.get("affected_parties", []),
            "impact_summary": analysis_output.get("impact_summary", "Unable to generate summary."),
            "timestamp": timestamp,
            "used_fallback": used_fallback,
        }

        # -- Log with timestamp for agent trace -----------------------------
        self._log_result(result)

        return result

    # ------------------------------------------------------------------
    #  Private helpers
    # ------------------------------------------------------------------

    def _get_shipments_by_truck(self, truck_id: str) -> dict:
        """Fetch all shipments assigned to a given truck from Firebase."""
        try:
            ref = db.reference("/shipments")
            all_shipments = ref.get() or {}
            
            # Filter shipments matching the truck_id
            truck_shipments = {
                sid: s for sid, s in all_shipments.items()
                if isinstance(s, dict) and s.get("truck_id") == truck_id
            }
            return truck_shipments
        except Exception as e:
            logger.error(f"Analysis Agent: Failed to fetch shipments from Firebase - {e}")
            return {}

    async def _generate_analysis(
        self,
        sensor_result: dict,
        shipments: dict,
    ) -> dict:
        """Call Gemini to analyze the breach impact."""
        user_prompt = (
            f"Please analyze this temperature breach impact:\n\n"
            f"SENSOR MONITOR REPORT:\n"
            f"{json.dumps(sensor_result, indent=2)}\n\n"
            f"AFFECTED SHIPMENTS:\n"
            f"{json.dumps(shipments, indent=2)}\n\n"
            f"Provide your analysis following the exact JSON structure requested."
        )

        try:
            from agents.llm_helper import query_llm_async
            full_prompt = f"{SYSTEM_PROMPT}\n\nContext: {user_prompt}"
            
            content = await query_llm_async(full_prompt, temperature=0.3, timeout=15.0)
            
            # Extract JSON from response if Nemotron adds markdown or fluff
            if "{" in content and "}" in content:
                content = content[content.find("{"):content.rfind("}")+1]
                
            return json.loads(content), False
        except Exception as e:
            logger.error(f"Analysis Agent: OpenRouter API error -- {e}")
            
            
            truck_id = sensor_result.get("truck_id", "Unknown")
            
            # Extract cargo from shipment data if available, fallback to sensor result
            cargo = "Unknown"
            if shipments:
                first_shipment = list(shipments.values())[0]
                cargo = (
                    first_shipment.get("cargo_description") or
                    first_shipment.get("product_type") or
                    first_shipment.get("cargo") or
                    first_shipment.get("cargo_type") or
                    "Unknown"
                )
            if cargo == "Unknown":
                cargo = sensor_result.get("cargo_type", "Unknown")
                
            severity = sensor_result.get("severity", "High")
            current_temp = sensor_result.get("current_temp", "Unknown")
            threshold = sensor_result.get("threshold_temp", "Unknown")
            
            delta = "Unknown"
            if isinstance(current_temp, (int, float)) and isinstance(threshold, (int, float)):
                delta = round(current_temp - threshold, 1)

            fallback_summary = (
                f"{str(cargo).capitalize()} cargo on {truck_id} is at {str(severity).lower()} risk. "
                f"Temperature of {current_temp}°C exceeds safe limit by {delta}°C. "
                f"Downstream supply chain is directly affected. Immediate containment required."
            )

            # Determine realistic loss and parties based on cargo type
            is_vaccines = "vaccine" in str(cargo).lower() or "insulin" in str(cargo).lower()
            is_meat = "meat" in str(cargo).lower() or "fish" in str(cargo).lower() or "shrimp" in str(cargo).lower()
            
            if is_vaccines:
                est_loss = "PKR 12,000,000 - 24,000,000"
                parties = ["Lady Reading Hospital Pharmacy", "End Patients"]
            elif is_meat:
                est_loss = "PKR 2,400,000 - 5,600,000"
                parties = ["Metro Cash & Carry", "GrillHouse Restaurants"]
            else:
                est_loss = "PKR 700,000 - 1,800,000"
                parties = ["DairyCo Distribution", "Retailers"]

            return {
                "cargo_at_risk": cargo,
                "spoilage_probability": "High",
                "estimated_loss_pkr": est_loss,
                "affected_parties": parties,
                "impact_summary": fallback_summary,
            }, True

    @staticmethod
    def _log_result(result: dict):
        """Log the agent output with a timestamp for the trace."""
        log_time = result["timestamp"]
        prob = result["spoilage_probability"]
        shipment = result["shipment_id"]

        logger.info(
            f"[{log_time}] AnalysisAgent | SpoilageProb={prob} | "
            f"Shipment={shipment} | Loss={result['estimated_loss_pkr']}"
        )

        # Full trace at debug level
        logger.debug(
            f"[{log_time}] AnalysisAgent full output: "
            f"{json.dumps(result, indent=2)}"
        )


# ---------------------------------------------------------------------------
#  Module-level convenience instance
# ---------------------------------------------------------------------------

analysis_agent = AnalysisAgent()


# ---------------------------------------------------------------------------
#  Self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio

    async def _test():
        from agents.sensor_monitor import SensorMonitorAgent
        
        print("Initializing Firebase...")
        initialize_firebase()
        
        sensor_agent = SensorMonitorAgent()
        agent = AnalysisAgent()

        print("\n=== Test 1: Critical breach analysis ===")
        # First, run the sensor monitor to get realistic input
        sm_result = await sensor_agent.analyze({
            "truck_id": "TRK-004",
            "current_temp": 15.5,
            "threshold_temp": 8.0,
            "cargo_type": "vaccines",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        
        # Then, pass it to analysis
        r1 = await agent.analyze(sm_result)
        print(json.dumps(r1, indent=2))
        
        print("\n=== Test 2: Mild breach analysis ===")
        sm_result_mild = await sensor_agent.analyze({
            "truck_id": "TRK-007",
            "current_temp": 9.5,
            "threshold_temp": 8.0,
            "cargo_type": "vaccines",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        r2 = await agent.analyze(sm_result_mild)
        print(json.dumps(r2, indent=2))

    asyncio.run(_test())
