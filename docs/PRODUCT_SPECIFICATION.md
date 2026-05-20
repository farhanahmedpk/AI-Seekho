# ColdGuard — Product Specification & Architecture Document

![ColdGuard Logo](https://img.shields.io/badge/ColdGuard-Autonomous%20Cold%20Chain-blue?style=for-the-badge)
![Status-Active](https://img.shields.io/badge/Status-Active-success?style=flat-square)
![Target-30s](https://img.shields.io/badge/Response%20Time-%3C%2030%20Seconds-orange?style=flat-square)
![Stack](https://img.shields.io/badge/Tech-FastAPI%20%7C%20Gemini%20%7C%20Firebase%20%7C%20Flutter-blueviolet?style=flat-square)

---

## 1. Executive Summary & Purpose

### The Core Problem
In modern cold chain logistics, the transportation of temperature-sensitive goods (e.g., vaccines, insulin, dairy, and meat) is highly volatile. A single cooling failure or threshold breach can compromise the entire shipment, leading to massive financial waste and, more critically, endangering public health by distributing degraded pharmaceuticals. 

Existing telemetry solutions are **purely reactive**: they capture a temperature spike and trigger an alert on a dashboard. This places the burden of containment entirely on human operators, who must manually:
1. Detect and verify the alert.
2. Cross-reference the vehicle with shipment manifests to identify the cargo.
3. Calculate physical and financial risks (e.g., spoilage rate, cargo valuation).
4. Formulate a recovery plan (e.g., quarantine, reroute, or replace).
5. Coordinate with drivers, warehouse managers, clients, and insurers.

This manual process takes **30–60 minutes** on average. In a cold chain breach, every minute counts: a 30-minute delay can mean a total cargo write-off worth **PKR 10M to 25M** ($35K to $90K USD).

### The Autonomous Solution
**ColdGuard** is a fully autonomous, real-time breach recovery pipeline. By leveraging **Google's Gemini API** and a resilient **4-agent sequential pipeline**, ColdGuard compresses the entire containment and recovery lifecycle from **30–60 minutes down to under 30 seconds**—completely eliminating the human bottleneck. 

When a refrigerated truck's temperature crosses a critical threshold (e.g., **8.0°C**), ColdGuard instantly ingests the telemetry, performs detailed risk analysis, drafts multi-party communications, updates the cloud database, quarantines spoiled batches, and triggers emergency replacement orders without requiring human intervention.

---

## 2. Product Features

ColdGuard's feature set is designed to deliver immediate, autonomous, and transparent recovery in cold chain operations:

| Feature Area | Sub-Feature | Description |
|---|---|---|
| **Autonomous AI Pipeline** | 4-Agent Chaining | A sequential flow powered by the Gemini API (`google-genai` SDK) that coordinates assessment, risk analysis, recovery decisions, and multi-system execution. |
| | Resilient Fallbacks | Robust, context-aware local fallback JSON generation if Gemini API rate limits (`429`) or network timeouts occur, guaranteeing 100% uptime. |
| **Ingestion Engine** | Telemetry Ingestion | Standard structured endpoint (`POST /trigger-breach`) to process active digital IoT sensor streams. |
| | Unstructured Ingestion | Natural Language Processing (NLP) parser (`POST /analyze-unstructured`) that extracts truck IDs and temperatures from raw driver text messages or field reports. |
| | Batch Resolution | Concurrent processing (`POST /resolve-all-breaches`) to automatically resolve all fleet vehicles currently in breach status simultaneously. |
| **Real-Time Flutter App** | Active Fleet Dashboard | Visual grid showing 10 fleet trucks with color-coded status rings (Green: Safe, Amber: Elevated, Red: Critical Breach). |
| | Telemetry Graphs | Interactive temperature timelines utilizing `fl_chart` that plot current vs. historical readings alongside a red threshold limit. |
| | Pulsing Breach Alerts | Dynamic overlay warnings displaying deviation, cargo at risk, financial exposure, and severity metrics. |
| | Real-Time Agent Trace | A live visual timeline showcasing step-by-step progress of the 4 agents, expanding to show their exact reasoning text. |
| | Containment Reports | A clean audit screen summarizing actions executed, financial losses protected, and client notifications. |
| **System Integrations** | Realtime Sync | Synchronizes state across backend, database, and mobile apps in milliseconds using Firebase Realtime Database. |
| | Notification Engine | Automated draft generator producing specific driver SMS instructions, dispatcher emails, and client notifications. |
| | Action Execution Suite | Direct database updates quarantining shipments, logging incidents, and dispatching emergency replacements. |

---

## 3. High-Level System Architecture

ColdGuard is structured as an event-driven, real-time architecture where data flows seamlessly between IoT sensors, the FastAPI backend, the Gemini multi-agent system, Firebase, and the Flutter mobile client.

```mermaid
graph TD
    %% Define System Nodes
    subgraph Sensors ["IoT Sensors & Drivers"]
        SensorSim["Structured Telemetry (Sensor Sim)"]
        DriverMsg["Unstructured Text (Driver SMS)"]
    end

    subgraph Backend ["FastAPI Application Backend (Python)"]
        FastAPI["FastAPI Web Server"]
        Orchestrator["Agent Pipeline Orchestrator"]
        
        subgraph Agents ["Resilient Multi-Agent Pipeline"]
            Agent1["Sensor Monitor Agent (Assessment)"]
            Agent2["Analysis Agent (Risk/Finance)"]
            Agent3["Decision Agent (Command)"]
            Agent4["Execution Agent (Automation)"]
        end
    end

    subgraph DB ["Cloud Storage / State"]
        Firebase["Firebase Realtime Database"]
    end

    subgraph Clients ["Cross-Platform Client Apps"]
        FlutterApp["Flutter Mobile Application"]
        SSE["SSE Realtime Stream Connection"]
    end

    %% Define Relationships and Data Flow
    SensorSim -->|HTTP POST /trigger-breach| FastAPI
    DriverMsg -->|HTTP POST /analyze-unstructured| FastAPI
    
    FastAPI -->|Extracts/Triggers| Orchestrator
    Orchestrator -->|Chains Sequentially| Agent1
    Agent1 -->|Breach Confirmed| Agent2
    Agent2 -->|Risk Analyzed| Agent3
    Agent3 -->|Decisions Approved| Agent4
    
    Agent4 -->|Write Action Payload| Firebase
    FastAPI -->|Query Live State| Firebase
    
    Firebase -.->|Real-time Sync (Listeners)| FlutterApp
    FastAPI -->|SSE Stream /agent-trace/stream| SSE
    SSE -.->|Live Trace Updates| FlutterApp
    
    %% Styles
    classDef main fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef agent fill:#efebe9,stroke:#4e342e,stroke-width:2px;
    classDef db fill:#fffde7,stroke:#fbc02d,stroke-width:2px;
    classDef client fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    
    class SensorSim,DriverMsg,FastAPI,Orchestrator main;
    class Agent1,Agent2,Agent3,Agent4 agent;
    class Firebase db;
    class FlutterApp,SSE client;
```

---

## 4. The 4-Agent Pipeline Deep-Dive

The heartbeat of ColdGuard is its 4-Agent sequential pipeline. The output of each agent feeds into the next, maintaining strict context and creating a cohesive reasoning flow:

```
[IoT Telemetry] 
      │
      ▼
┌────────────────────────────────┐
│ 1. Sensor Monitor Agent        │ -> Validates threshold deviation and severity
└────────────────────────────────┘
      │
      ▼
┌────────────────────────────────┐
│ 2. Analysis Agent              │ -> Cross-references cargo databases, calculates PKR spoilage & losses
└────────────────────────────────┘
      │
      ▼
┌────────────────────────────────┐
│ 3. Decision Agent              │ -> Evaluates tactical recovery options, chooses best 3 actions
└────────────────────────────────┘
      │
      ▼
┌────────────────────────────────┐
│ 4. Execution Agent             │ -> Writes to Firebase, drafts SMS/email alerts, triggers replacement
└────────────────────────────────┘
      │
      ▼
[Contained Incident]
```

### Agent Details

#### Agent 1: Sensor Monitor Agent (Assessment)
*   **Purpose**: Acts as the first line of defense. It ingests the raw temperature telemetry, compares it against the truck’s cargo threshold config, and determines if an active breach exists.
*   **Key Inputs**: `truck_id`, `current_temp`, `threshold_temp`, `cargo_type`, `timestamp`.
*   **Output JSON Schema**:
    ```json
    {
      "breach_detected": true,
      "severity": "CRITICAL" | "ELEVATED" | "NORMAL",
      "deviation": 4.5,
      "message": "Temperature is 12.5C, exceeding the 8.0C threshold by 4.5C."
    }
    ```
*   **Logic**: If `breach_detected` is false, the orchestrator immediately halts the pipeline, writing a `NORMAL` status code. If true, the breach is confirmed, and control transfers to Agent 2.

#### Agent 2: Analysis Agent (Risk & Financial Assessment)
*   **Purpose**: Cross-references the breaching truck with shipment databases to analyze what specific cargo is inside, calculate the cargo’s degradation timeline, and estimate the financial risk in Pakistani Rupees (PKR).
*   **Key Inputs**: Output of Agent 1 + shipment database records.
*   **Output JSON Schema**:
    ```json
    {
      "cargo_at_risk": "Insulin Vials" | "COVID-19 Vaccines" | "Fresh Dairy" | "Frozen Meat",
      "spoilage_probability": 0.85,
      "financial_loss_pkr": 24000000,
      "impact_summary": "High-value pharmaceutical cargo (Insulin) is highly sensitive to the current 12.5C temperature. Spoilage probability is 85%, resulting in a potential financial loss of PKR 24,000,000 within 45 minutes of exposure."
    }
    ```

#### Agent 3: Decision Agent (Tactical Commander)
*   **Purpose**: Formulates the optimal recovery strategy. It weighs the financial loss, geographical constraints, and safety guidelines to recommend exactly what actions must be taken.
*   **Key Inputs**: Outputs of Agent 1 and Agent 2.
*   **Output JSON Schema**:
    ```json
    {
      "quarantine_required": true,
      "reroute_required": false,
      "emergency_replacement_required": true,
      "recommended_actions": [
        "Quarantine current shipment SHP-004 due to 85% spoilage probability.",
        "Instruct the driver to pull over safely at the nearest secure location.",
        "Dispatch emergency replacement truck from Islamabad Warehouse to Peshawar."
      ]
    }
    ```

#### Agent 4: Execution Agent (Automated Executor)
*   **Purpose**: Executes the decisions. It writes the updated shipment status to Firebase, logs the full incident details, drafts tailored communications for stakeholders (SMS/Email), and initiates the logistics replacement request.
*   **Key Inputs**: Outputs of Agents 1, 2, and 3.
*   **Output JSON Schema**:
    ```json
    {
      "incident_id": "INC-A1B2C3D4",
      "actions_executed": [
        {
          "action": "SHIPMENT_QUARANTINED",
          "details": "Shipment SHP-004 status updated to QUARANTINED in Firebase."
        },
        {
          "action": "DRIVER_SMS_SENT",
          "recipient": "Muhammad Ali",
          "content": "CRITICAL BREACH! Temp is 12.5C. Pull over safely. Replacement is dispatched."
        },
        {
          "action": "CLIENT_NOTIFIED",
          "recipient": "HealthFirst Distributors",
          "content": "Proactive Alert: Shipment compromised. Quarantined under Incident INC-A1B2C3D4. Insurance claim initiated. Replacement dispatch scheduled."
        },
        {
          "action": "REPLACEMENT_DISPATCHED",
          "warehouse": "Islamabad Central Hub",
          "eta_minutes": 45
        }
      ]
    }
    ```

---

## 5. API Endpoints Specification

The backend FastAPI service exposes the following endpoints (documented via Swagger at `/docs`):

### 1. `GET /sensors`
*   **Description**: Fetches the real-time sensor readings of all 10 trucks.
*   **Response**: List of trucks with active temperatures, status, cargo types, and routes.

### 2. `GET /shipments`
*   **Description**: Fetches all current shipments and their active statuses (e.g., `IN_TRANSIT`, `QUARANTINED`, `DELIVERED`).

### 3. `POST /trigger-breach`
*   **Description**: Simulates a telemetry update. Triggers the full 4-agent pipeline synchronously and returns the complete execution trace.
*   **Request Body**:
    ```json
    {
      "truck_id": "TRK-004",
      "temperature": 12.5
    }
    ```
*   **Response**: Full JSON trace including the inputs, outputs, and reasoning logs of all 4 agents.

### 4. `POST /analyze-unstructured`
*   **Description**: Receives free-text logistics reports (e.g., driver transcripts), parses them using LLM extraction to identify the truck ID and temperature, updates Firebase, and triggers the orchestrator.
*   **Request Body**:
    ```json
    {
      "content": "Driver reports TRK-004 cooling unit failed. Temperature is 15 degrees."
    }
    ```

### 5. `GET /agent-trace/stream/{truck_id}/{temperature}`
*   **Description**: Server-Sent Events (SSE) streaming endpoint. It streams the execution of the 4 agents in real time, chunk by chunk, as they execute on the server.
*   **Stream Events**:
    - `pipeline_started`: Indicates the pipeline has initialized.
    - `agent_started`: Broadcast when an agent begins execution.
    - `agent_completed`: Delivers the individual agent’s JSON output.
    - `pipeline_completed`: Finalizes the stream and returns the cumulative incident summary.

### 6. `GET /reset-demo`
*   **Description**: Clears the `/incidents` db reference and resets all trucks and shipments to their original clean baseline configurations for demonstration.

---

## 6. Mobile Application Specification (UX/UI Flow)

The Flutter mobile application is built using **Riverpod** for reactive state management and **Firebase Realtime Database listeners** to ensure immediate, high-fidelity UI updates.

```
       ┌───────────────────────┐
       │   1. Splash Screen    │
       └───────────┬───────────┘
                   │
                   ▼
       ┌───────────────────────┐
       │   2. Login Screen     │
       └───────────┬───────────┘
                   │
                   ▼
       ┌───────────────────────┐
       │  3. Active Dashboard  │ <──────────────────────────┐
       └───────────┬───────────┘                            │
                   │                                        │
           (Tap red breach card)                            │
                   │                                        │
                   ▼                                        │
       ┌───────────────────────┐                            │
       │   4. Truck Detail     │                            │
       └───────────┬───────────┘                            │
                   │                                        │
          (Tap "Analyze with AI")                           │
                   │                                        │
                   ▼                                        │
       ┌───────────────────────┐                            │
       │  5. Agent Trace Flow  │ ──(Automatic Transition)───┘
       └───────────┬───────────┘ (Reflects QUARANTINED state)
                   │
                   ▼
       ┌───────────────────────┐
       │   6. Incident Report  │
       └───────────────────────┘
```

### 1. Active Dashboard (Fleet Overview)
*   **Grid Layout**: Displays a grid of cards for each of the 10 trucks in the fleet.
*   **Status Indicators**: Color-coded status circles that update in real time:
    *   `🟢 Safe`: Temperature is normal.
    *   `🟡 Elevated`: Temperature is within 1.0°C of the limit.
    *   `🔴 Breach`: Temperature is actively exceeding the limit.
*   **Key Info**: Lists cargo type, driver name, destination city, and real-time temperature.

### 2. Truck Detail Screen
*   **Temperature Chart**: Renders an interactive historical graph using `fl_chart`. The line turns red as it spikes above the red **8.0°C threshold line**.
*   **Shipment Card**: Shows the active shipment ID, product details, cargo valuation, loading time, and carrier routes.
*   **Breach Banner**: If in breach, a pulsing red banner slides in. It displays the severity level (`CRITICAL`), deviation, and a call-to-action button: `"Analyze with AI"`.

### 3. Agent Trace Screen
*   **Timeline Track**: A vertical timeline visualizing the progress of the 4 agents.
*   **Interactive Cards**: Each card shows an agent icon, execution status (e.g., `PENDING` -> `RUNNING` -> `COMPLETED`), and total execution time.
*   **Reasoning Expanders**: Tapping a card reveals the exact markdown text of the AI’s step-by-step reasoning.
*   **SSE Sync**: The timeline updates dynamically as backend Server-Sent Events are parsed by the Flutter client.

### 4. Incident Report / Containment Summary
*   **Success Cards**: Shows immediate containment results (e.g., "Cargo successfully quarantined at Peshawar Warehouse").
*   **Action List**: Lists the 6 executed actions, each turning from grey to green with a checkmark as they write to Firebase.
*   **Metrics Grid**: Displays key metrics with animated counters:
    *   Response Time: `8.4 seconds`
    *   Protected Value: `PKR 24,000,000`
    *   Stakeholders Notified: `4`
    *   Replacement ETA: `45 mins`

### 5. Settings Screen
*   **Backend URL**: Allows developers or judges to change the FastAPI server URL (e.g., for local network testing).
*   **Demo Mode Toggle**: A local-first toggle that allows the application to simulate the entire dashboard, breach details, and agent trace workflows offline using local JSON fixtures, guaranteeing a zero-crash demonstration even without network connectivity.

---

## 7. Pakistani Logistics Domain Context

To ensure immediate, local relevance during hackathon presentations, ColdGuard operates within a localized Pakistani logistics context:

### Key Cities & Fleet Hubs
Refrigerated trucks are routed across critical regional transit networks:
*   **North Hub**: Islamabad, Rawalpindi, Peshawar, Abbottabad.
*   **Central Hub**: Lahore, Gujranwala, Faisalabad, Multan.
*   **South Hub**: Karachi, Hyderabad, Sukkur.

### Cargo Types and Financial Exposure
The system utilizes realistic cargo types, safety thresholds, and valuations based on standard Pakistani supply chain metrics:

*   **Insulin Vials (Compromised > 8°C)**: High-sensitivity pharmaceutical. High valuation (~PKR 24,000,000 per shipment).
*   **COVID-19 Vaccines (Compromised > 8°C)**: Critical pharmaceutical. Very high valuation (~PKR 18,500,000 per shipment).
*   **Fresh Dairy (Compromised > 8°C)**: Medium-sensitivity food cargo. Valuation (~PKR 3,500,000 per shipment).
*   **Frozen Meat (Compromised > -18°C)**: Cold-storage food cargo. Valuation (~PKR 4,800,000 per shipment).

---

## 8. Resiliency & Fallback Architecture

To guarantee high reliability during live demonstrations and real-world execution, ColdGuard incorporates a multi-tier fallback architecture:

```
                  ┌───────────────────────────────┐
                  │   Temperature Breach Detected  │
                  └───────────────┬───────────────┘
                                  │
                                  ▼
                ┌───────────────────────────────────┐
                │   Attempt API Request to Gemini   │
                └─────────────────┬─────────────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  │                               │
        [API Key Valid / Online]         [Gemini Rate Limit (429) / Offline]
                  │                               │
                  ▼                               ▼
    ┌───────────────────────────┐   ┌───────────────────────────┐
    │  Execute Gemini Reasoning │   │  Inject Professional      │
    │  & Output Structured JSON │   │  Contextual Fallback JSON │
    └─────────────┬─────────────┘   └─────────────┬─────────────┘
                  │                               │
                  └───────────────┬───────────────┘
                                  │
                                  ▼
                  ┌───────────────────────────────┐
                  │    Write Output to Firebase   │
                  │   & Real-time Update Client   │
                  └───────────────────────────────┘
```

1.  **Rate-Limit Shielding (`429` Handling)**:
    If the Gemini API reaches its rate limit or is blocked, the backend catches the exception and immediately invokes a dynamic local generator. This generator returns highly-professional, contextually-accurate fallback JSON strings that are tailored to the truck's cargo, driver, and destination. The pipeline completes seamlessly without showing error states.
2.  **Flutter Demo Mode (Offline-First)**:
    In settings, enabling "Demo Mode" tells Riverpod to ignore Firebase/API listeners and read from static JSON mocks in Dart. If Wi-Fi fails on the presentation stage, the app continues to display normal dashboards, trigger breach animations, and step through the 4-agent trace perfectly.
3.  **SSE Connection Resilience**:
    If the SSE connection drops mid-trace, the mobile application falls back to querying the FastAPI `/agent-trace/{incident_id}` REST endpoint directly to load the partial or fully-completed trace from Firebase.

---

*Document Author: Google Antigravity Coding Assistant*  
*Project Role: Principal System Architect & Developer*  
*Last Updated: May 18, 2026*  
