"""
Agent 2 — Analysis Agent

Identifies affected shipments, assesses product risk, and determines
breach severity based on product type, exposure duration, and temperature delta.
"""

import json
from loguru import logger

from app.services.gemini_service import gemini_service

SYSTEM_PROMPT = """You are the Analysis Agent in a Cold Chain Breach Detection System.

Your role:
- Identify which shipments are affected by a temperature breach.
- Assess the severity of the breach based on product type, temperature deviation, and exposure time.
- Evaluate the risk to product quality and safety.

You will receive breach details and shipment information.

Respond ONLY with a JSON object in this exact format:
{
    "affected_shipments": ["shipment_id_1", "shipment_id_2"],
    "severity": "low" | "medium" | "high" | "critical",
    "exposure_duration_minutes": <estimated minutes>,
    "temperature_deviation": <degrees above/below safe range>,
    "product_risk_assessment": "Description of risk to products",
    "product_safety_compromised": true/false,
    "estimated_financial_impact": <estimated USD loss>,
    "reasoning": "Step-by-step analysis"
}
"""


async def run(breach_data: dict, shipment_data: dict | None = None) -> dict:
    """
    Analyze a confirmed breach to determine severity and affected shipments.

    Args:
        breach_data: The enriched breach event.
        shipment_data: Shipments on the affected truck.

    Returns:
        Structured analysis with severity, risk, and affected shipments.
    """
    user_prompt = f"""
Analyze this confirmed temperature breach:

BREACH EVENT:
- Breach ID: {breach_data.get('breach_id')}
- Truck ID: {breach_data.get('truck_id')}
- Temperature Recorded: {breach_data.get('temperature')}°C
- Threshold Violated: {breach_data.get('threshold_violated')}
- Current Severity: {breach_data.get('severity')}
- Detected At: {breach_data.get('detected_at')}

SHIPMENTS ON THIS TRUCK:
{json.dumps(shipment_data, indent=2) if shipment_data else "No shipment data available — assume generic perishable goods"}

Analyze the impact, determine severity, and assess product safety.
"""

    logger.info(f"📊 Analysis Agent evaluating breach {breach_data.get('breach_id')}")

    response = await gemini_service.generate(
        system_prompt=SYSTEM_PROMPT,
        user_prompt=user_prompt,
        temperature=0.3,
    )

    try:
        result = json.loads(response)
    except json.JSONDecodeError:
        logger.error(f"Analysis Agent returned invalid JSON: {response}")
        result = {
            "affected_shipments": [],
            "severity": breach_data.get("severity", "high"),
            "exposure_duration_minutes": 0,
            "temperature_deviation": 0,
            "product_risk_assessment": "Unable to parse AI analysis",
            "product_safety_compromised": True,
            "estimated_financial_impact": 0,
            "reasoning": "Fallback — AI response could not be parsed",
        }

    logger.info(
        f"Analysis Agent result: severity={result.get('severity')} "
        f"affected_shipments={result.get('affected_shipments')}"
    )
    return result
