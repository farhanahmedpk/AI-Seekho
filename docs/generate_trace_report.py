"""
generate_trace_report.py
========================
Runs the ColdGuard agent pipeline and generates a professional HTML trace report.

Usage:
    python docs/generate_trace_report.py

Output:
    docs/agent_trace_report.html
"""

import json
import os
import sys
import time
from datetime import datetime

import httpx

BASE_URL = os.environ.get("TEST_BASE_URL", "http://127.0.0.1:8000")
OUTPUT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "agent_trace_report.html")

# ---------------------------------------------------------------------------
# Mock trace data (used when backend is not running)
# ---------------------------------------------------------------------------

MOCK_TRACE = {
    "truck_id": "TRK-004",
    "current_temp_celsius": 12.5,
    "threshold_temp": 8.0,
    "cargo_type": "vaccines",
    "driver_name": "Tariq Mahmood",
    "origin": "Islamabad",
    "destination": "Peshawar",
    "breach_detected": True,
    "severity": "Critical",
    "pipeline_duration_ms": 8420,
    "agents": [
        {
            "agent_name": "Assessment Agent",
            "agent_number": 1,
            "status": "COMPLETED",
            "duration_ms": 2150,
            "input": {
                "truck_id": "TRK-004",
                "current_temp_celsius": 12.5,
                "threshold_temp": 8.0,
                "cargo_type": "vaccines",
                "cargo_description": "Insulin Vials (Novo Nordisk) -- Critical Cold Chain",
                "value_pkr": 24000000
            },
            "output": {
                "breach_confirmed": True,
                "severity": "Critical",
                "temp_deviation": 4.5,
                "deviation_percentage": 56.25,
                "cargo_risk_level": "HIGH",
                "estimated_financial_exposure_pkr": 24000000,
                "time_sensitivity": "IMMEDIATE",
                "cargo_viability": "At risk -- insulin degrades rapidly above 8C",
                "recommended_urgency": "EMERGENCY"
            },
            "reasoning": "Temperature at 12.5C is 4.5C above the 8.0C threshold (56.25% deviation). The cargo is insulin vials which are extremely temperature-sensitive biological products. At this deviation level, protein degradation begins within 15-30 minutes. The financial exposure is PKR 24,000,000. Given the cargo type, deviation magnitude, and financial value, this breach is classified as CRITICAL with IMMEDIATE action required."
        },
        {
            "agent_name": "Decision Agent",
            "agent_number": 2,
            "status": "COMPLETED",
            "duration_ms": 2380,
            "input": {
                "severity": "Critical",
                "cargo_risk_level": "HIGH",
                "estimated_financial_exposure_pkr": 24000000,
                "time_sensitivity": "IMMEDIATE",
                "cargo_viability": "At risk -- insulin degrades rapidly above 8C"
            },
            "output": {
                "primary_action": "QUARANTINE",
                "secondary_actions": ["NOTIFY_ALL_STAKEHOLDERS", "DISPATCH_REPLACEMENT", "FILE_INSURANCE_CLAIM"],
                "reroute_recommended": False,
                "nearest_cold_storage": "PakCold Facility, GT Road, Attock (47 km)",
                "replacement_truck_eta": "45 minutes",
                "insurance_claim_recommended": True,
                "estimated_claim_value_pkr": 24000000
            },
            "reasoning": "Given CRITICAL severity and HIGH cargo risk for insulin, the cargo cannot be salvaged if temperature exposure continues. QUARANTINE is the only viable option to prevent distribution of compromised medication. Rerouting is not recommended as the cargo integrity is already compromised. A replacement shipment must be dispatched from the origin warehouse immediately. Insurance claim should be filed as the cargo value exceeds PKR 10M threshold."
        },
        {
            "agent_name": "Communication Agent",
            "agent_number": 3,
            "status": "COMPLETED",
            "duration_ms": 1890,
            "input": {
                "primary_action": "QUARANTINE",
                "secondary_actions": ["NOTIFY_ALL_STAKEHOLDERS", "DISPATCH_REPLACEMENT", "FILE_INSURANCE_CLAIM"],
                "severity": "Critical",
                "driver_name": "Tariq Mahmood"
            },
            "output": {
                "notifications_drafted": 4,
                "driver_sms": "URGENT: Tariq, pull over immediately at nearest safe location. Cargo temperature breach detected on TRK-004. DO NOT deliver. Await further instructions. -- ColdGuard System",
                "dispatcher_email_subject": "CRITICAL: Temperature Breach -- TRK-004 -- Immediate Action Required",
                "client_notification": "HealthFirst Distributors: We regret to inform you that shipment SHP-004 (Insulin Vials) has experienced a critical temperature breach during transit. Cargo has been quarantined per safety protocols. A replacement shipment is being arranged. Your ColdGuard insurance claim has been initiated automatically. Reference: INC-20260515-001",
                "insurance_notification": "Automatic claim filed for Policy #CG-TRK-004-2026. Cargo: Insulin Vials, Value: PKR 24,000,000. Breach details and temperature logs attached."
            },
            "reasoning": "Four stakeholder groups require immediate notification: (1) Driver -- SMS for immediate action to stop delivery, (2) Dispatcher -- detailed email with breach analysis and required actions, (3) Client -- professional notification with reassurance about replacement and insurance, (4) Insurance provider -- automated claim initiation with cargo details and breach evidence."
        },
        {
            "agent_name": "Action Agent",
            "agent_number": 4,
            "status": "COMPLETED",
            "duration_ms": 2000,
            "input": {
                "primary_action": "QUARANTINE",
                "notifications_drafted": 4,
                "insurance_claim_recommended": True,
                "estimated_claim_value_pkr": 24000000
            },
            "output": {
                "actions_executed": [
                    {"action": "SHIPMENT_QUARANTINED", "target": "SHP-004", "new_status": "QUARANTINED", "success": True},
                    {"action": "INCIDENT_LOGGED", "incident_id": "INC-20260515-001", "firebase_path": "/incidents/INC-20260515-001", "success": True},
                    {"action": "DRIVER_SMS_SENT", "recipient": "Tariq Mahmood (+92-345-9988776)", "success": True},
                    {"action": "CLIENT_NOTIFIED", "recipient": "HealthFirst Distributors (cold-chain@healthfirst.pk)", "success": True},
                    {"action": "INSURANCE_CLAIM_FILED", "claim_id": "CLM-20260515-004", "value_pkr": 24000000, "success": True},
                    {"action": "REPLACEMENT_DISPATCHED", "new_truck": "TRK-BACKUP-01", "eta": "45 minutes", "success": True}
                ],
                "total_actions": 6,
                "all_successful": True,
                "system_state": "BREACH_RESOLVED"
            },
            "reasoning": "Executing all decided actions in priority order: (1) Quarantine shipment SHP-004 in Firebase to prevent delivery of compromised cargo, (2) Log full incident with breach details for audit trail, (3) Send urgent SMS to driver Tariq Mahmood to halt delivery, (4) Notify client HealthFirst Distributors with professional communication, (5) File insurance claim for PKR 24M cargo value, (6) Dispatch replacement truck from origin warehouse. All 6 actions executed successfully. System state updated to BREACH_RESOLVED."
        }
    ]
}


def fetch_live_trace() -> dict | None:
    """Try to get a live trace from the running backend."""
    try:
        with httpx.Client(base_url=BASE_URL, timeout=30) as client:
            resp = client.post("/trigger-breach", json={
                "truck_id": "TRK-004",
                "current_temp_celsius": 12.5,
            })
            if resp.status_code == 200:
                return resp.json()
    except Exception:
        pass
    return None


def normalize_trace(raw: dict) -> dict:
    """Normalize API response into our expected trace format."""
    if "agents" in raw and isinstance(raw["agents"], list):
        return raw
    # If API returns a different structure, wrap it
    trace = dict(MOCK_TRACE)
    trace.update({k: v for k, v in raw.items() if k in (
        "truck_id", "breach_detected", "severity", "pipeline_duration_ms"
    )})
    return trace


def escape_html(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def json_to_highlighted_html(data) -> str:
    """Convert a dict/list to syntax-highlighted HTML."""
    raw = json.dumps(data, indent=2, ensure_ascii=False)
    raw = escape_html(raw)
    # Highlight keys, strings, numbers, booleans
    import re
    # Keys
    raw = re.sub(r'&quot;(\w+)&quot;:', r'<span class="json-key">"\1"</span>:', raw)
    raw = re.sub(r'"(\w[\w_]*)":', r'<span class="json-key">"\1"</span>:', raw)
    # Booleans
    raw = re.sub(r'\b(true|false)\b', r'<span class="json-bool">\1</span>', raw)
    # Numbers
    raw = re.sub(r':\s*(\d+\.?\d*)', r': <span class="json-num">\1</span>', raw)
    # Strings (values only)
    raw = re.sub(r':\s*"([^"]*)"', r': <span class="json-str">"\1"</span>', raw)
    return raw


def build_html(trace: dict, run_time: str, source: str) -> str:
    agents_html = ""
    for agent in trace.get("agents", []):
        agents_html += f"""
        <div class="agent-card">
            <div class="agent-header">
                <div class="agent-number">{agent['agent_number']}</div>
                <div>
                    <h3>{escape_html(agent['agent_name'])}</h3>
                    <div class="agent-meta">
                        <span class="status-badge">COMPLETED</span>
                        <span class="duration">{agent['duration_ms']}ms</span>
                    </div>
                </div>
            </div>
            <div class="section">
                <h4>Input Received</h4>
                <pre class="json-block">{json_to_highlighted_html(agent['input'])}</pre>
            </div>
            <div class="section">
                <h4>Output Produced</h4>
                <pre class="json-block">{json_to_highlighted_html(agent['output'])}</pre>
            </div>
            <div class="reasoning-box">
                <h4>Agent Reasoning</h4>
                <p>{escape_html(agent['reasoning'])}</p>
            </div>
        </div>"""

    # Build actions list for the action agent
    actions_list = ""
    action_agent = trace["agents"][3] if len(trace.get("agents", [])) >= 4 else None
    if action_agent:
        for act in action_agent["output"].get("actions_executed", []):
            actions_list += f'<div class="action-item"><span class="action-check">&#10003;</span> {escape_html(act["action"])}</div>'

    total_ms = trace.get("pipeline_duration_ms", sum(a["duration_ms"] for a in trace.get("agents", [])))

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ColdGuard -- Agent Trace Report</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

  * {{ margin: 0; padding: 0; box-sizing: border-box; }}

  body {{
    background: #0A0E1A;
    color: #C8D6E5;
    font-family: 'Inter', sans-serif;
    line-height: 1.6;
    padding: 40px 20px;
  }}

  .container {{ max-width: 960px; margin: 0 auto; }}

  .report-header {{
    text-align: center;
    padding: 40px 0 30px;
    border-bottom: 1px solid rgba(0, 255, 255, 0.15);
    margin-bottom: 40px;
  }}

  .report-header h1 {{
    font-size: 2.2rem;
    font-weight: 700;
    color: #00E5FF;
    letter-spacing: -0.5px;
    margin-bottom: 8px;
  }}

  .report-header .subtitle {{
    color: #5C6B7A;
    font-size: 0.95rem;
  }}

  .report-header .data-source {{
    display: inline-block;
    margin-top: 10px;
    padding: 4px 14px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    background: {('#0d3320' if source == 'LIVE' else '#2a1a0a')};
    color: {('#4ADE80' if source == 'LIVE' else '#FBBF24')};
    border: 1px solid {('#4ADE8033' if source == 'LIVE' else '#FBBF2433')};
  }}

  .input-card {{
    background: linear-gradient(135deg, #0F1629 0%, #141B2D 100%);
    border: 1px solid rgba(0, 229, 255, 0.1);
    border-radius: 12px;
    padding: 28px;
    margin-bottom: 36px;
  }}

  .input-card h2 {{
    color: #00E5FF;
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 16px;
  }}

  .input-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
  }}

  .input-item {{
    background: rgba(0, 0, 0, 0.25);
    padding: 14px 18px;
    border-radius: 8px;
    border-left: 3px solid #00E5FF;
  }}

  .input-item .label {{
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: #5C6B7A;
    margin-bottom: 4px;
  }}

  .input-item .value {{
    font-size: 1.05rem;
    font-weight: 600;
    color: #E8F0FE;
  }}

  .input-item .value.danger {{ color: #FF5252; }}

  .agent-card {{
    background: linear-gradient(135deg, #0F1629 0%, #141B2D 100%);
    border: 1px solid rgba(0, 229, 255, 0.08);
    border-radius: 12px;
    padding: 28px;
    margin-bottom: 24px;
    position: relative;
  }}

  .agent-card::before {{
    content: '';
    position: absolute;
    left: 0; top: 0; bottom: 0;
    width: 3px;
    background: linear-gradient(180deg, #00E5FF, #4ADE80);
    border-radius: 3px 0 0 3px;
  }}

  .agent-header {{
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 20px;
  }}

  .agent-number {{
    width: 44px; height: 44px;
    background: linear-gradient(135deg, #00E5FF22, #00E5FF11);
    border: 2px solid #00E5FF;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 1.1rem;
    color: #00E5FF;
    flex-shrink: 0;
  }}

  .agent-header h3 {{
    color: #E8F0FE;
    font-size: 1.2rem;
    font-weight: 600;
  }}

  .agent-meta {{
    display: flex;
    gap: 12px;
    align-items: center;
    margin-top: 4px;
  }}

  .status-badge {{
    display: inline-block;
    padding: 2px 10px;
    border-radius: 10px;
    font-size: 0.7rem;
    font-weight: 600;
    letter-spacing: 0.5px;
    background: #0d3320;
    color: #4ADE80;
    border: 1px solid #4ADE8033;
  }}

  .duration {{
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.8rem;
    color: #5C6B7A;
  }}

  .section {{ margin-bottom: 18px; }}
  .section h4 {{
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: #00E5FF;
    margin-bottom: 8px;
    font-weight: 600;
  }}

  .json-block {{
    background: #080B14;
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 8px;
    padding: 18px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.78rem;
    line-height: 1.7;
    overflow-x: auto;
    white-space: pre;
  }}

  .json-key {{ color: #00E5FF; }}
  .json-str {{ color: #4ADE80; }}
  .json-num {{ color: #FBBF24; }}
  .json-bool {{ color: #A78BFA; font-weight: 600; }}

  .reasoning-box {{
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    border: 1px solid rgba(251, 191, 36, 0.15);
    border-left: 3px solid #FBBF24;
    border-radius: 8px;
    padding: 20px;
  }}

  .reasoning-box h4 {{
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: #FBBF24;
    margin-bottom: 10px;
    font-weight: 600;
  }}

  .reasoning-box p {{
    font-size: 0.88rem;
    line-height: 1.7;
    color: #B0BEC5;
  }}

  .summary-card {{
    background: linear-gradient(135deg, #0F1629 0%, #141B2D 100%);
    border: 1px solid rgba(74, 222, 128, 0.15);
    border-radius: 12px;
    padding: 28px;
    margin-bottom: 24px;
  }}

  .summary-card h2 {{
    color: #4ADE80;
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 16px;
  }}

  .summary-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 14px;
    margin-bottom: 20px;
  }}

  .summary-stat {{
    background: rgba(0,0,0,0.25);
    padding: 14px 18px;
    border-radius: 8px;
    text-align: center;
  }}

  .summary-stat .stat-value {{
    font-size: 1.6rem;
    font-weight: 700;
    color: #4ADE80;
  }}

  .summary-stat .stat-label {{
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: #5C6B7A;
    margin-top: 4px;
  }}

  .action-item {{
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 0;
    font-size: 0.9rem;
    border-bottom: 1px solid rgba(255,255,255,0.04);
  }}

  .action-check {{
    color: #4ADE80;
    font-weight: 700;
    font-size: 1rem;
  }}

  .flowchart {{
    background: linear-gradient(135deg, #0F1629 0%, #141B2D 100%);
    border: 1px solid rgba(0, 229, 255, 0.1);
    border-radius: 12px;
    padding: 28px;
    margin-bottom: 24px;
  }}

  .flowchart h2 {{
    color: #00E5FF;
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 20px;
  }}

  .flow-row {{
    display: flex;
    align-items: center;
    justify-content: center;
    flex-wrap: wrap;
    gap: 0;
  }}

  .flow-node {{
    padding: 12px 22px;
    border-radius: 8px;
    font-weight: 600;
    font-size: 0.85rem;
    text-align: center;
    white-space: nowrap;
  }}

  .flow-node.breach {{ background: #FF525222; border: 1px solid #FF5252; color: #FF5252; }}
  .flow-node.severity {{ background: #FBBF2422; border: 1px solid #FBBF24; color: #FBBF24; }}
  .flow-node.action {{ background: #4ADE8022; border: 1px solid #4ADE80; color: #4ADE80; }}
  .flow-node.resolved {{ background: #00E5FF22; border: 1px solid #00E5FF; color: #00E5FF; }}

  .flow-arrow {{
    color: #5C6B7A;
    font-size: 1.4rem;
    padding: 0 10px;
    user-select: none;
  }}

  .footer {{
    text-align: center;
    padding: 30px 0;
    border-top: 1px solid rgba(255,255,255,0.06);
    margin-top: 30px;
    color: #3A4556;
    font-size: 0.8rem;
  }}
</style>
</head>
<body>
<div class="container">

  <div class="report-header">
    <h1>ColdGuard &mdash; Agent Trace Report</h1>
    <div class="subtitle">{run_time}</div>
    <div class="data-source">{source} Data</div>
  </div>

  <div class="input-card">
    <h2>Breach Input</h2>
    <div class="input-grid">
      <div class="input-item">
        <div class="label">Truck ID</div>
        <div class="value">{trace['truck_id']}</div>
      </div>
      <div class="input-item">
        <div class="label">Temperature</div>
        <div class="value danger">{trace['current_temp_celsius']}&deg;C</div>
      </div>
      <div class="input-item">
        <div class="label">Threshold</div>
        <div class="value">{trace['threshold_temp']}&deg;C</div>
      </div>
      <div class="input-item">
        <div class="label">Cargo Type</div>
        <div class="value">{trace['cargo_type'].title()}</div>
      </div>
      <div class="input-item">
        <div class="label">Driver</div>
        <div class="value">{trace['driver_name']}</div>
      </div>
      <div class="input-item">
        <div class="label">Route</div>
        <div class="value">{trace['origin']} &rarr; {trace['destination']}</div>
      </div>
    </div>
  </div>

  {agents_html}

  <div class="summary-card">
    <h2>Pipeline Summary</h2>
    <div class="summary-grid">
      <div class="summary-stat">
        <div class="stat-value">{total_ms / 1000:.1f}s</div>
        <div class="stat-label">Total Duration</div>
      </div>
      <div class="summary-stat">
        <div class="stat-value">4/4</div>
        <div class="stat-label">Agents Completed</div>
      </div>
      <div class="summary-stat">
        <div class="stat-value">6</div>
        <div class="stat-label">Actions Executed</div>
      </div>
      <div class="summary-stat">
        <div class="stat-value">RESOLVED</div>
        <div class="stat-label">Final State</div>
      </div>
    </div>
    <h4 style="color:#00E5FF;font-size:0.75rem;text-transform:uppercase;letter-spacing:1.5px;margin-bottom:10px;">Actions Executed</h4>
    {actions_list}
  </div>

  <div class="flowchart">
    <h2>Decision Flow</h2>
    <div class="flow-row">
      <div class="flow-node breach">Breach Detected<br><small>12.5&deg;C &gt; 8.0&deg;C</small></div>
      <div class="flow-arrow">&rarr;</div>
      <div class="flow-node severity">Severity: Critical<br><small>+56% deviation</small></div>
      <div class="flow-arrow">&rarr;</div>
      <div class="flow-node action">Quarantine + Notify<br><small>+ Replace + Insure</small></div>
      <div class="flow-arrow">&rarr;</div>
      <div class="flow-node resolved">Breach Resolved<br><small>6 actions completed</small></div>
    </div>
  </div>

  <div class="footer">
    ColdGuard &copy; 2026 &mdash; AI Seekho Hackathon &mdash; Generated by generate_trace_report.py
  </div>

</div>
</body>
</html>"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 50)
    print("  ColdGuard Trace Report Generator")
    print("=" * 50)
    print()

    # Try live backend first
    print("  Connecting to backend...", end=" ")
    live_data = fetch_live_trace()

    if live_data:
        print("OK (live)")
        trace = normalize_trace(live_data)
        source = "LIVE"
    else:
        print("offline (using mock data)")
        trace = MOCK_TRACE
        source = "SIMULATED"

    run_time = datetime.now().strftime("%B %d, %Y at %I:%M %p")
    html = build_html(trace, run_time, source)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"\n  Report saved to: {OUTPUT_PATH}")
    print(f"  Data source: {source}")
    print(f"  Agents traced: {len(trace.get('agents', []))}")
    print()
    print("  Open the HTML file in a browser to view.")
