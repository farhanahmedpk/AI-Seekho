"""
Agent 3 -- Decision Agent

Receives outputs from both the Sensor Monitor Agent and the Analysis Agent.
Uses the Gemini API to reason about the best course of action based on the
breach severity and shipment risk.

Generates exactly 3 recommended actions ranked by priority.

Returns a structured JSON result with the recommendations and logs it for the trace.

Usage:
    from agents.decision_agent import DecisionAgent

    agent = DecisionAgent()
    result = await agent.analyze(sensor_monitor_result, analysis_result)
"""

import os
import json
from datetime import datetime, timezone

from dotenv import load_dotenv
import requests
from loguru import logger

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

SYSTEM_PROMPT = """You are the Decision Agent in an AI-powered Cold Chain Breach Detection System.

Your job is to receive both the Sensor Monitor Report and the Risk Analysis Report
for a temperature breach, and determine the best course of action.

Generate EXACTLY 3 recommended actions ranked by priority (1 being highest).
Each action must be specific, realistic, and domain-relevant to logistics and cold chain management.
Examples of actions include QUARANTINE_SHIPMENT, NOTIFY_CLIENT, TRIGGER_REPLACEMENT, REROUTE_TRUCK, INITIATE_INSPECTION.

Provide an overall reasoning (2-3 sentences) summarizing why these 3 actions were chosen.

Respond ONLY with a JSON object in this exact format:
{
  "recommended_actions": [
    {
      "priority": 1,
      "action": "ACTION_NAME_IN_CAPS",
      "description": "Specific description of what to do",
      "reasoning": "Why this specific action is needed",
      "urgency": "e.g., Immediate, Within 15 minutes, Within 1 hour"
    },
    ... (must have exactly 3 actions)
  ],
  "overall_reasoning": "Your 2-3 sentence summary of why these actions were chosen."
}"""


# ---------------------------------------------------------------------------
#  DecisionAgent class
# ---------------------------------------------------------------------------

class DecisionAgent:
    """
    Agent 3 of the breach-detection pipeline.

    Decides on the 3 most critical actions to take based on the breach and analysis.
    """

    AGENT_NAME = "DecisionAgent"

    # ------------------------------------------------------------------
    #  Public API
    # ------------------------------------------------------------------

    async def analyze(self, sensor_monitor_result: dict, analysis_result: dict) -> dict:
        """
        Run the Decision Agent using outputs from previous agents.

        Args:
            sensor_monitor_result: Dict output from SensorMonitorAgent
            analysis_result: Dict output from AnalysisAgent

        Returns:
            Structured dict containing recommended actions.
        """
        breach_detected = sensor_monitor_result.get("breach_detected", False)
        timestamp = datetime.now(timezone.utc).isoformat()

        # If no breach, no actions needed.
        if not breach_detected:
            result = {
                "agent": self.AGENT_NAME,
                "recommended_actions": [],
                "overall_reasoning": "No breach detected. Standard operating procedures apply.",
                "timestamp": timestamp,
            }
            self._log_result(result)
            return result

        # -- Ask Gemini for recommended actions -----------------------------
        decision_output, used_fallback = await self._generate_decisions(
            sensor_result=sensor_monitor_result,
            analysis_result=analysis_result,
        )

        # -- Build structured output ----------------------------------------
        result = {
            "agent": self.AGENT_NAME,
            "recommended_actions": decision_output.get("recommended_actions", self._get_fallback_actions()),
            "overall_reasoning": decision_output.get("overall_reasoning", "Generated fallback actions due to processing error."),
            "timestamp": timestamp,
            "used_fallback": used_fallback,
        }

        # -- Log with timestamp for agent trace -----------------------------
        self._log_result(result)

        return result

    # ------------------------------------------------------------------
    #  Private helpers
    # ------------------------------------------------------------------

    async def _generate_decisions(self, sensor_result: dict, analysis_result: dict) -> dict:
        """Call Gemini to generate recommended actions."""
        user_prompt = (
            f"Please determine the 3 best actions for this incident:\n\n"
            f"SENSOR MONITOR REPORT:\n"
            f"{json.dumps(sensor_result, indent=2)}\n\n"
            f"RISK ANALYSIS REPORT:\n"
            f"{json.dumps(analysis_result, indent=2)}\n\n"
            f"Generate exactly 3 ranked actions following the requested JSON structure."
        )

        try:
            from agents.llm_helper import query_llm_async
            full_prompt = f"{SYSTEM_PROMPT}\n\nContext: {user_prompt}"
            
            content = await query_llm_async(full_prompt, temperature=0.2, timeout=15.0)
            
            # Extract JSON from response if Nemotron adds markdown or fluff
            if "{" in content and "}" in content:
                content = content[content.find("{"):content.rfind("}")+1]
                
            return json.loads(content), False
        except Exception as e:
            logger.error(f"Decision Agent: OpenRouter API error -- {e}")
            return {
                "recommended_actions": self._get_fallback_actions(),
                "overall_reasoning": "Three priority actions identified based on breach severity and cargo type. Quarantine prevents further damage, client notification ensures transparency, and inspection verifies cargo integrity.",
            }, True

    def _get_fallback_actions(self) -> list:
        """Provide safe fallback actions if the AI fails or rate limits."""
        return [
            {
                "priority": 1,
                "action": "QUARANTINE_SHIPMENT",
                "description": "Immediately halt and quarantine affected shipment at nearest depot",
                "reasoning": "Standard operating procedure for unhandled temperature breaches to ensure safety.",
                "urgency": "Immediate"
            },
            {
                "priority": 2,
                "action": "NOTIFY_STAKEHOLDERS",
                "description": "Send automated breach notifications to logistics and quality control teams",
                "reasoning": "Required to trigger manual intervention since AI analysis failed.",
                "urgency": "Within 15 minutes"
            },
            {
                "priority": 3,
                "action": "TRIGGER_REPLACEMENT",
                "description": "Create replacement order from nearest cold storage facility",
                "reasoning": "Replacement order ensures client receives goods on time despite the breach.",
                "urgency": "Within 1 hour"
            }
        ]

    @staticmethod
    def _log_result(result: dict):
        """Log the agent output with a timestamp for the trace."""
        log_time = result["timestamp"]
        actions_count = len(result.get("recommended_actions", []))

        logger.info(
            f"[{log_time}] DecisionAgent | Generated {actions_count} recommended actions"
        )

        # Full trace at debug level
        logger.debug(
            f"[{log_time}] DecisionAgent full output: "
            f"{json.dumps(result, indent=2)}"
        )


# ---------------------------------------------------------------------------
#  Module-level convenience instance
# ---------------------------------------------------------------------------

decision_agent = DecisionAgent()


# ---------------------------------------------------------------------------
#  Self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio

    async def _test():
        from agents.sensor_monitor import SensorMonitorAgent
        from agents.analysis_agent import AnalysisAgent
        from firebase_config import initialize_firebase
        
        print("Initializing Firebase...")
        initialize_firebase()
        
        sensor_agent = SensorMonitorAgent()
        analysis_agent = AnalysisAgent()
        agent = DecisionAgent()

        print("\n=== Test 1: Full pipeline to Decision Agent (Critical breach) ===")
        # 1. Sensor Monitor
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
        dc_result = await agent.analyze(sm_result, an_result)
        
        print(json.dumps(dc_result, indent=2))

    asyncio.run(_test())
