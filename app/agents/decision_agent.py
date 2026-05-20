"""
Agent 3 — Decision Agent

Based on the analysis, recommends specific actions: quarantine, reroute,
notify stakeholders, order replacements, etc.
"""

import json
from loguru import logger

from app.services.gemini_service import gemini_service

SYSTEM_PROMPT = """You are the Decision Agent in a Cold Chain Breach Detection System.

Your role:
- Based on the breach analysis, recommend specific, actionable steps.
- Prioritize actions by urgency.
- Consider regulatory compliance (FDA, WHO cold chain guidelines).
- Balance product safety against financial loss.

You will receive breach data and the Analysis Agent's output.

Respond ONLY with a JSON object in this exact format:
{
    "recommended_actions": [
        {
            "action": "description of action",
            "priority": "immediate" | "high" | "medium" | "low",
            "type": "quarantine" | "reroute" | "notify" | "replace" | "inspect" | "discard"
        }
    ],
    "overall_priority": "immediate" | "high" | "medium" | "low",
    "quarantine_required": true/false,
    "replacement_order_needed": true/false,
    "stakeholders_to_notify": ["list of stakeholder roles"],
    "estimated_loss_usd": <number>,
    "regulatory_flags": ["any compliance concerns"],
    "reasoning": "Step-by-step decision rationale"
}
"""


async def run(breach_data: dict, analysis_result: dict) -> dict:
    """
    Decide on actions based on breach analysis.

    Args:
        breach_data: The breach event.
        analysis_result: Output from the Analysis Agent.

    Returns:
        Structured action recommendations.
    """
    user_prompt = f"""
Based on the following breach analysis, recommend the best course of action:

BREACH EVENT:
- Breach ID: {breach_data.get('breach_id')}
- Truck ID: {breach_data.get('truck_id')}
- Temperature: {breach_data.get('temperature')}°C
- Severity: {analysis_result.get('severity')}

ANALYSIS RESULTS:
- Affected Shipments: {analysis_result.get('affected_shipments')}
- Exposure Duration: {analysis_result.get('exposure_duration_minutes')} minutes
- Product Risk: {analysis_result.get('product_risk_assessment')}
- Product Safety Compromised: {analysis_result.get('product_safety_compromised')}
- Estimated Financial Impact: ${analysis_result.get('estimated_financial_impact', 0)}

Recommend actions, prioritize them, and identify stakeholders to notify.
"""

    logger.info(f"🧠 Decision Agent processing breach {breach_data.get('breach_id')}")

    response = await gemini_service.generate(
        system_prompt=SYSTEM_PROMPT,
        user_prompt=user_prompt,
        temperature=0.3,
    )

    try:
        result = json.loads(response)
    except json.JSONDecodeError:
        logger.error(f"Decision Agent returned invalid JSON: {response}")
        result = {
            "recommended_actions": [
                {
                    "action": "Quarantine affected shipments immediately",
                    "priority": "immediate",
                    "type": "quarantine",
                }
            ],
            "overall_priority": "immediate",
            "quarantine_required": True,
            "replacement_order_needed": True,
            "stakeholders_to_notify": ["operations_manager", "quality_control"],
            "estimated_loss_usd": 0,
            "regulatory_flags": [],
            "reasoning": "Fallback — AI response could not be parsed",
        }

    logger.info(
        f"Decision Agent result: priority={result.get('overall_priority')} "
        f"actions={len(result.get('recommended_actions', []))}"
    )
    return result
