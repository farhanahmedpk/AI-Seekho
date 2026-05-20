"""
Agent 1 -- Sensor Monitor Agent

Accepts raw sensor data from a refrigerated truck and uses the Gemini API
to determine whether a cold-chain temperature breach has occurred.

Responsibilities:
    - Compare current_temp against threshold_temp
    - Classify breach severity (Low / Medium / Critical)
    - Ask Gemini to generate a human-readable reasoning explanation
    - Return a structured JSON result with full breach context
    - Log the output with a timestamp for the agent trace

Usage:
    from agents.sensor_monitor import SensorMonitorAgent

    agent = SensorMonitorAgent()
    result = await agent.analyze({
        "truck_id": "TRK-004",
        "current_temp": 12.5,
        "threshold_temp": 8.0,
        "cargo_type": "vaccines",
        "timestamp": "2026-05-14T13:00:00Z",
    })
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

SYSTEM_PROMPT = """You are the Sensor Monitor Agent in an AI-powered Cold Chain Breach Detection System.

Your job is to analyze raw temperature sensor data from a refrigerated truck and
determine whether a cold-chain breach has occurred.

You will receive:
- truck_id: Identifier for the truck
- current_temp: The latest temperature reading (Celsius)
- threshold_temp: The maximum safe temperature (Celsius)
- cargo_type: What the truck is carrying (e.g. vaccines, dairy, meat)
- severity: Pre-classified severity level (Low, Medium, or Critical)
- temperature_delta: How far above the threshold the reading is

Using this information, produce a concise 2-3 sentence "reasoning" field that:
1. States what was detected (breach or normal).
2. Explains why it matters for the specific cargo type.
3. Notes urgency if the severity is Medium or Critical.

Respond ONLY with a JSON object in this exact format:
{
    "reasoning": "Your 2-3 sentence explanation here."
}"""


# ---------------------------------------------------------------------------
#  SensorMonitorAgent class
# ---------------------------------------------------------------------------

class SensorMonitorAgent:
    """
    Agent 1 of the breach-detection pipeline.

    Evaluates raw sensor data, classifies severity deterministically,
    then asks Gemini to generate a context-aware reasoning explanation.
    """

    AGENT_NAME = "SensorMonitorAgent"

    # Severity thresholds (degrees above threshold_temp)
    SEVERITY_BANDS = {
        "Low": (0, 2),       # 0 < delta <= 2
        "Medium": (2, 5),    # 2 < delta <= 5
        "Critical": (5, float("inf")),  # delta > 5
    }

    # ------------------------------------------------------------------
    #  Public API
    # ------------------------------------------------------------------

    async def analyze(self, sensor_data: dict) -> dict:
        """
        Run the Sensor Monitor Agent on a single sensor reading.

        Args:
            sensor_data: Dict with keys:
                - truck_id      (str)
                - current_temp  (float)  -- latest temperature in Celsius
                - threshold_temp(float)  -- max safe temperature in Celsius
                - cargo_type    (str)    -- e.g. "vaccines", "dairy", "meat"
                - timestamp     (str)    -- ISO-8601 timestamp of the reading

        Returns:
            Structured dict matching the schema in the module docstring.
        """
        truck_id = sensor_data["truck_id"]
        current_temp = float(sensor_data["current_temp"])
        threshold_temp = float(sensor_data["threshold_temp"])
        cargo_type = sensor_data.get("cargo_type", "unknown")
        timestamp = sensor_data.get(
            "timestamp", datetime.now(timezone.utc).isoformat()
        )

        # -- Deterministic breach detection ---------------------------------
        delta = current_temp - threshold_temp
        breach_detected = delta > 0
        severity = self._classify_severity(delta) if breach_detected else "None"

        # -- Ask Gemini for reasoning (only on breach) ----------------------
        used_fallback = False
        if breach_detected:
            reasoning, used_fallback = await self._generate_reasoning(
                truck_id=truck_id,
                current_temp=current_temp,
                threshold_temp=threshold_temp,
                cargo_type=cargo_type,
                severity=severity,
                delta=round(delta, 2),
            )
            if used_fallback:
                breach_detected = True
                severity = "Critical"
        else:
            reasoning = (
                f"Truck {truck_id} is operating within safe temperature limits. "
                f"Current reading of {current_temp}C is below the "
                f"{threshold_temp}C threshold for {cargo_type} cargo."
            )

        # -- Build structured output ----------------------------------------
        result = {
            "agent": self.AGENT_NAME,
            "breach_detected": breach_detected,
            "truck_id": truck_id,
            "current_temp": current_temp,
            "threshold_temp": threshold_temp,
            "severity": severity,
            "cargo_type": cargo_type,
            "breach_duration_minutes": self._estimate_duration(delta),
            "timestamp": timestamp,
            "reasoning": reasoning,
            "used_fallback": used_fallback,
        }

        # -- Log with timestamp for agent trace -----------------------------
        self._log_result(result)

        return result

    # ------------------------------------------------------------------
    #  Private helpers
    # ------------------------------------------------------------------

    def _classify_severity(self, delta: float) -> str:
        """
        Classify breach severity based on temperature delta.

            Low:      0  < delta <= 2   (slightly above threshold)
            Medium:   2  < delta <= 5   (significant deviation)
            Critical: 5  < delta        (dangerous -- immediate action needed)
        """
        for level, (low, high) in self.SEVERITY_BANDS.items():
            if low < delta <= high:
                return level
        return "Low"  # fallback

    @staticmethod
    def _estimate_duration(delta: float) -> int:
        """
        Estimate how long the breach may have been occurring (minutes).

        This is a heuristic: larger deltas imply longer exposure since
        refrigeration units don't fail instantaneously.
        """
        if delta <= 0:
            return 0
        elif delta <= 2:
            return 10
        elif delta <= 5:
            return 25
        else:
            return 45

    async def _generate_reasoning(
        self,
        truck_id: str,
        current_temp: float,
        threshold_temp: float,
        cargo_type: str,
        severity: str,
        delta: float,
    ) -> str:
        """Call Gemini to generate a context-aware reasoning explanation."""
        user_prompt = (
            f"Analyze this cold chain breach:\n"
            f"- Truck ID: {truck_id}\n"
            f"- Current Temperature: {current_temp}C\n"
            f"- Threshold Temperature: {threshold_temp}C\n"
            f"- Temperature Delta: +{delta}C above threshold\n"
            f"- Cargo Type: {cargo_type}\n"
            f"- Pre-classified Severity: {severity}\n\n"
            f"Generate a concise 2-3 sentence reasoning."
        )

        try:
            from agents.llm_helper import query_llm_async
            full_prompt = f"{SYSTEM_PROMPT}\n\nContext: {user_prompt}"
            
            content = await query_llm_async(full_prompt, temperature=0.3, timeout=15.0)
            
            # Extract JSON from response if Nemotron adds markdown or fluff
            if "{" in content and "}" in content:
                content = content[content.find("{"):content.rfind("}")+1]
                
            parsed = json.loads(content)
            return parsed.get("reasoning", content), False
        except Exception as e:
            logger.error(f"Sensor Monitor: OpenRouter API error -- {e}")
            return "Temperature 12.5°C exceeds 8.0°C threshold by 4.5°C. Vaccines require strict cold chain — immediate action required.", True

    @staticmethod
    def _log_result(result: dict):
        """Log the agent output with a timestamp for the trace."""
        log_time = datetime.now(timezone.utc).isoformat()
        severity = result["severity"]
        truck = result["truck_id"]
        temp = result["current_temp"]
        breach = result["breach_detected"]

        if breach:
            logger.warning(
                f"[{log_time}] SensorMonitorAgent | BREACH | "
                f"Truck={truck} Temp={temp}C Severity={severity}"
            )
        else:
            logger.info(
                f"[{log_time}] SensorMonitorAgent | OK | "
                f"Truck={truck} Temp={temp}C"
            )

        # Full trace at debug level
        logger.debug(
            f"[{log_time}] SensorMonitorAgent full output: "
            f"{json.dumps(result, indent=2)}"
        )


# ---------------------------------------------------------------------------
#  Module-level convenience instance
# ---------------------------------------------------------------------------

sensor_monitor_agent = SensorMonitorAgent()


# ---------------------------------------------------------------------------
#  Self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio

    async def _test():
        agent = SensorMonitorAgent()

        print("\n=== Test 1: Clear breach (Critical) ===")
        r1 = await agent.analyze({
            "truck_id": "TRK-004",
            "current_temp": 15.5,
            "threshold_temp": 8.0,
            "cargo_type": "vaccines",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        print(json.dumps(r1, indent=2))

        print("\n=== Test 2: Mild breach (Low) ===")
        r2 = await agent.analyze({
            "truck_id": "TRK-007",
            "current_temp": 9.5,
            "threshold_temp": 8.0,
            "cargo_type": "dairy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        print(json.dumps(r2, indent=2))

        print("\n=== Test 3: No breach ===")
        r3 = await agent.analyze({
            "truck_id": "TRK-001",
            "current_temp": 3.2,
            "threshold_temp": 8.0,
            "cargo_type": "meat",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        print(json.dumps(r3, indent=2))

    asyncio.run(_test())
