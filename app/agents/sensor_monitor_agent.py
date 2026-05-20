"""
Agent 1 — Sensor Monitor Agent

Detects and validates temperature breaches from raw sensor data.
This agent is the entry point of the pipeline: it confirms whether
a reading truly constitutes a breach and enriches the event context.
"""

import json
from loguru import logger

from app.services.gemini_service import gemini_service

SYSTEM_PROMPT = """You are the Sensor Monitor Agent in a Cold Chain Breach Detection System.

Your role:
- Validate whether a sensor reading constitutes a genuine temperature breach.
- Filter out false positives (e.g., brief spikes during door openings).
- Enrich the breach event with sensor-level context.

You will receive raw sensor data and temperature thresholds.

Respond ONLY with a JSON object in this exact format:
{
    "is_valid_breach": true/false,
    "breach_confirmed": true/false,
    "confidence": 0.0 to 1.0,
    "sensor_status": "normal" | "warning" | "critical" | "malfunction",
    "context": "Brief explanation of your assessment",
    "recommended_next_step": "proceed_to_analysis" | "continue_monitoring" | "check_sensor"
}
"""


async def run(breach_data: dict, sensor_history: dict | None = None) -> dict:
    """
    Evaluate raw sensor data to confirm or dismiss a breach.

    Args:
        breach_data: The breach event from the monitor service.
        sensor_history: Recent readings for the same sensor (optional).

    Returns:
        Structured dict with breach validation results.
    """
    user_prompt = f"""
Analyze this sensor reading for a potential cold chain breach:

BREACH EVENT:
- Breach ID: {breach_data.get('breach_id')}
- Truck ID: {breach_data.get('truck_id')}
- Sensor ID: {breach_data.get('sensor_id')}
- Temperature: {breach_data.get('temperature')}°C
- Threshold Violated: {breach_data.get('threshold_violated')}
- Detected At: {breach_data.get('detected_at')}

RECENT SENSOR HISTORY:
{json.dumps(sensor_history, indent=2) if sensor_history else "No history available"}

Determine if this is a valid breach or a false positive.
"""

    logger.info(f"🔍 Sensor Monitor Agent analyzing breach {breach_data.get('breach_id')}")

    response = await gemini_service.generate(
        system_prompt=SYSTEM_PROMPT,
        user_prompt=user_prompt,
        temperature=0.2,
    )

    try:
        result = json.loads(response)
    except json.JSONDecodeError:
        logger.error(f"Sensor Monitor Agent returned invalid JSON: {response}")
        result = {
            "is_valid_breach": True,
            "breach_confirmed": True,
            "confidence": 0.5,
            "sensor_status": "warning",
            "context": "Failed to parse AI response — defaulting to confirmed breach",
            "recommended_next_step": "proceed_to_analysis",
        }

    logger.info(
        f"Sensor Monitor Agent result: confirmed={result.get('breach_confirmed')} "
        f"confidence={result.get('confidence')}"
    )
    return result
