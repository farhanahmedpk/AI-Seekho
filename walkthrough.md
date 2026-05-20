# ColdGuard AI — Developer & Code Walkthrough

Welcome to the ColdGuard AI Developer Walkthrough. This document provides a deep architectural and file-by-file breakdown of the system, describing how the multi-agent pipeline, backend web server, and cross-platform mobile client work together to achieve fully autonomous cold chain recovery.

---

## 📂 1. Directory Structure Overview

The codebase is organized into two primary pillars: a Python FastAPI backend and a Flutter mobile client.

```text
F:\AI Seekho Project\
│
├── app/                         # FastAPI Web Server Core
│   ├── agents/                  # Production Multi-Agent Implementations
│   │   ├── sensor_monitor_agent.py  # Agent 1: Threshold & Severity Monitor
│   │   ├── analysis_agent.py        # Agent 2: Spoilage & Financial Auditor
│   │   ├── decision_agent.py        # Agent 3: Action & Recovery Commander
│   │   └── execution_agent.py       # Agent 4: Firebase Committer & SMS Drafter
│   │
│   ├── models/                  # Pydantic schemas for request validation
│   ├── routes/                  # API Controllers
│   │   ├── agent_routes.py      # /trigger-breach, /analyze-unstructured, /agent-trace
│   │   ├── sensor_routes.py     # /sensors updates
│   │   └── breach_routes.py     # /resolve-all-breaches
│   │
│   ├── services/                # Singleton Services & Integrations
│   │   ├── firebase_service.py  # Realtime Database CRUD
│   │   ├── gemini_service.py    # OpenRouter API & Key Rotation
│   │   └── monitor_service.py   # Telemetry & Polling logic
│   │
│   ├── config.py                # Pydantic BaseSettings config loading
│   └── main.py                  # FastAPI Application Startup
│
├── agents/                      # Shared helper files
│   └── llm_helper.py            # Key rotation & offline fallback mocks
│
├── scripts/                     # Seed and Simulation Tools
│   ├── seed_data.py             # Firebase regional seeder (Pakistan context)
│   └── simulator.py             # Active telemetry simulator loop
│
├── mobile/                      # Flutter Application Core
│   ├── lib/
│   │   ├── core/                # App themes, constants, API base urls
│   │   ├── models/              # Dart Data classes (Truck, Shipment, AgentTrace)
│   │   ├── providers/           # Riverpod state managers (sensors_provider, trace_provider)
│   │   ├── screens/             # Flutter screen layouts
│   │   └── widgets/             # Reusable UI elements (Glassmorphism card, FlChart)
│   │
│   └── pubspec.yaml             # Flutter dependencies (Riverpod, fl_chart, flutter_animate)
```

---

## 🧠 2. Backend Execution Flow (The FastAPI Core)

The backend exposes REST endpoints and a Server-Sent Events (SSE) stream to orchestrate the multi-agent pipeline and push real-time execution states to connected mobile clients.

### 2.1 The Agent Orchestrator Pipeline
When a temperature breach is triggered, the `Orchestrator` sequentially activates the 4-agent pipeline. 

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  SensorMonitor  │ ➔➔➔   │  AnalysisAgent  │ ➔➔➔   │  DecisionAgent  │ ➔➔➔   │  ExecutionAgent │
│  (Validate &    │       │ (Spoilage & PKR │       │ (Quarantine vs  │       │ (Firebase Write │
│  Assess Severity)│      │  Exposure)      │       │  Reroute choice)│       │  & Alert Draft) │
└─────────────────┘       └─────────────────┘       └─────────────────┘       └─────────────────┘
```

Each agent represents a specialized Large Language Model context configured to output strictly formatted JSON payloads:
1. **`sensor_monitor_agent.py`**:
   Checks raw temperatures against safe ranges. If it's an transient spike (e.g., short door opening), it filters it out. Valid breaches are confirmed and given a severity label (`Low`, `Medium`, or `Critical`).
2. **`analysis_agent.py`**:
   Cross-references active shipment IDs inside Firebase to determine cargo types (e.g., Insulin, Fresh Seafood). It calculates physical spoilage risk percentages and computes total financial exposure in PKR.
3. **`decision_agent.py`**:
   Acts as the operational commander. Depending on location, distance to destination, and severity, it recommends specific operational procedures (e.g., `QUARANTINE_SHIPMENT`, `REROUTE_TO_NEAREST_FACILITY`, `ORDER_EMERGENCY_REPLACEMENT`).
4. **`execution_agent.py`**:
   Commits the changes directly to Firebase Realtime Database (marking shipment statuses as quarantined and sensor statuses as resolved), creates an incident audit record, and drafts custom, localized communication payloads (SMS templates for drivers, email templates for clients).

### 2.2 Resilient API Key Rotation & Fallbacks (`llm_helper.py`)
To prevent system failures during internet outages or OpenRouter `429 Too Many Requests` rate-limiting:
- **Automatic Rotation**: The `gemini_service` and `llm_helper` maintain an array of up to three keys. If a primary key fails, the service rotates to the next key and retries within milliseconds.
- **High-Fidelity Offline Mocking**: If all keys fail, the pipeline falls back to `_get_fallback_mock()`, a local, context-aware rule-based parsing engine that returns fully schema-compliant, cargo-specific mock JSONs instantly.

### 2.3 Non-Blocking Background Operations (`/resolve-all-breaches`)
To prevent FastAPI event-loop blocks during intensive multi-truck pipeline executions:
- **`asyncio.create_task()`**: When calling bulk resolution, the API launches the AI pipeline workers as concurrent background tasks.
- **Immediate Response**: The server instantly responds with `{"status": "pipelines_started"}` so the client remains perfectly responsive.
- **Firebase Synchronization**: The pipelines write their results to Firebase as they finish, syncing automatically to clients.

---

## 📱 3. Frontend Architecture (The Flutter Client)

The mobile dashboard utilizes reactive state management and high-end animations to create a premium, state-of-the-art developer demonstration.

### 3.1 Reactive Providers (Riverpod)
The application leverages **Riverpod** to bind backend states to the UI:
- **`sensorsProvider`**: Maintains a continuous, active listener to `/sensors` and `/shipments` in Firebase. If a backend request times out or is offline, it preserves the last known valid dataset (avoiding sudden jumps to demo mode).
- **`traceProvider`**: Manages real-time Server-Sent Events (SSE) streams (`/agent-trace/stream/{id}`). As each agent completes execution, the stream pushes logs, updates, and JSON schemas, rebuilding the trace screen step-by-step.

### 3.2 Premium UI/UX Details & Micro-Animations
To create a "wow" factor for operators:
- **Glassmorphism Design**: Standard grids are built using blurred backing shapes, subtle color gradients, and glowing outer boundaries tailored to status conditions.
- **Liquid Card Expansion (`AnimatedSize`)**: Tap cards inside the trace screen expand and collapse using `AnimatedSize` (500ms duration, `easeInOutCubic` curves) to display complex JSON inputs and outputs smoothly without jarring page jumps.
- **`flutter_animate` Integration**: Agent step cards slide and fade into view sequentially (`Float-In Solution`) when the SSE stream signals a step transition.
- **Interactive Telemetry (`fl_chart`)**: Historical temperature records are plotted on an elegant line graph inside the `TruckDetailScreen`.
- **Containment Success Portal**: When a bulk autonomous resolution completes, a full-screen overlay animates into view, detailing exact physical containment timelines (e.g. "3 breaches resolved autonomously in 14s") and direct paths to the Incident History Audit Portal.
