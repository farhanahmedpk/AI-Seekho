"""
Agent 4 — Execution Agent

Simulates carrying out the recommended actions:
- Quarantining affected shipments
- Sending notifications to stakeholders
- Placing replacement orders
"""

import json
from datetime import datetime

from loguru import logger

from app.services.gemini_service import gemini_service

SYSTEM_PROMPT = """You are the Execution Agent in a Cold Chain Breach Detection System.

Your role:
- Simulate executing the recommended actions from the Decision Agent.
- For each action, generate a realistic execution result.
- Track which actions succeeded or failed.
- Generate notification messages for stakeholders.
- Create replacement order details if needed.

You will receive the breach data and recommended actions.

Respond ONLY with a JSON object in this exact format:
{
    "actions_executed": [
        {
            "action": "description",
            "type": "quarantine" | "notify" | "replace" | "inspect" | "reroute" | "discard",
            "status": "completed" | "pending" | "failed",
            "details": "execution details",
            "timestamp": "ISO timestamp"
        }
    ],
    "notifications_sent": [
        {
            "recipient": "stakeholder role",
            "channel": "email" | "sms" | "push" | "dashboard",
            "message": "notification content",
            "status": "sent" | "failed"
        }
    ],
    "replacement_order": {
        "order_id": "generated order ID",
        "items": ["list of items to replace"],
        "estimated_delivery": "ISO timestamp",
        "supplier": "supplier name",
        "priority": "express" | "standard"
    } or null,
    "quarantine_status": "active" | "not_required",
    "summary": "Brief execution summary",
    "reasoning": "Execution approach explanation"
}
"""


async def run(breach_data: dict, decision_result: dict) -> dict:
    """
    Simulate execution of recommended actions.

    Args:
        breach_data: The breach event.
        decision_result: Output from the Decision Agent.

    Returns:
        Structured execution results with simulated outcomes.
    """
    user_prompt = f"""
Execute the following recommended actions for this breach:

BREACH EVENT:
- Breach ID: {breach_data.get('breach_id')}
- Truck ID: {breach_data.get('truck_id')}
- Temperature: {breach_data.get('temperature')}°C
- Severity: {breach_data.get('severity')}

RECOMMENDED ACTIONS:
{json.dumps(decision_result.get('recommended_actions', []), indent=2)}

ADDITIONAL CONTEXT:
- Quarantine Required: {decision_result.get('quarantine_required')}
- Replacement Order Needed: {decision_result.get('replacement_order_needed')}
- Stakeholders to Notify: {decision_result.get('stakeholders_to_notify')}
- Estimated Loss: ${decision_result.get('estimated_loss_usd', 0)}

Current Timestamp: {datetime.utcnow().isoformat()}

Simulate executing each action and generate realistic results.
"""

    logger.info(f"⚡ Execution Agent executing actions for breach {breach_data.get('breach_id')}")

    response = await gemini_service.generate(
        system_prompt=SYSTEM_PROMPT,
        user_prompt=user_prompt,
        temperature=0.4,
    )

    try:
        result = json.loads(response)
    except json.JSONDecodeError:
        logger.error(f"Execution Agent returned invalid JSON: {response}")
        result = {
            "actions_executed": [
                {
                    "action": "Emergency quarantine initiated",
                    "type": "quarantine",
                    "status": "completed",
                    "details": "Fallback execution — AI response unparseable",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ],
            "notifications_sent": [
                {
                    "recipient": "operations_manager",
                    "channel": "dashboard",
                    "message": f"BREACH ALERT: {breach_data.get('breach_id')}",
                    "status": "sent",
                }
            ],
            "replacement_order": None,
            "quarantine_status": "active",
            "summary": "Fallback execution completed",
            "reasoning": "AI response could not be parsed — default actions taken",
        }

    logger.info(
        f"Execution Agent result: {len(result.get('actions_executed', []))} actions, "
        f"{len(result.get('notifications_sent', []))} notifications"
    )
    return result
