# ColdGuard — Project Workplan

> **Autonomous Cold Chain Breach Response System**
> Powered by Google Antigravity & Gemini AI

---

## Project Overview

| Field             | Detail                                              |
|-------------------|------------------------------------------------------|
| **Project Name**  | ColdGuard — Agentic AI for Cold Chain Logistics      |
| **Hackathon**     | AI Seekho Hackathon 2026                             |
| **Date**          | May 2026                                             |
| **Team Size**     | 3 Members                                            |
| **Duration**      | 7 Days                                               |

---

## Problem Statement

Cold chain logistics — the transportation of temperature-sensitive goods like vaccines, pharmaceuticals, dairy, and meat — is a critical yet fragile process. A single temperature breach can destroy millions of rupees worth of cargo and, in the case of vaccines, endanger lives.

### The Current Problem

- **Reactive, not proactive.** Existing monitoring systems detect breaches and alert a human operator. The operator must then manually investigate, decide what to do, contact stakeholders, and execute corrective actions. This process takes **30–60 minutes** on average.

- **Costly delays.** In the pharmaceutical cold chain, every minute above threshold degrades product efficacy. A 30-minute delay in response can mean a complete cargo write-off worth **PKR 10–25 million**.

- **Human bottleneck.** Operators handle multiple trucks simultaneously. During night shifts or peak hours, breaches can go unnoticed for extended periods, compounding losses.

- **No autonomous action.** No existing system can independently assess a breach, make a decision, notify all affected parties, and execute corrective actions — all without human intervention.

### The Opportunity

What if the entire breach response — from detection to resolution — could happen **autonomously in under 30 seconds**?

---

## Proposed Solution

**ColdGuard** is an autonomous AI system that detects cold chain breaches and responds to them in real time using a **4-agent pipeline** powered by Google's Gemini API.

### How It Works

When a refrigerated truck's temperature crosses the threshold:

1. **Assessment Agent** — Analyzes the breach: severity, cargo at risk, financial exposure, time sensitivity
2. **Decision Agent** — Determines the optimal response: reroute, quarantine, emergency stop, or continue monitoring
3. **Communication Agent** — Drafts and sends notifications to all stakeholders: driver, dispatcher, client, insurance
4. **Action Agent** — Executes the decision: updates shipment status, logs the incident, triggers insurance claims, adjusts routing

All four agents run sequentially in a single pipeline, completing the entire response in **under 30 seconds** — compared to the industry average of **30–60 minutes**.

### Key Differentiators

- **Fully autonomous** — No human in the loop for standard breach responses
- **Agentic AI** — Not just alerts, but intelligent reasoning and action
- **Real-time mobile monitoring** — Flutter app with live temperature tracking
- **Simulated execution** — Demonstrates the full pipeline without real-world side effects
- **Pakistani logistics context** — Built with local companies, routes, and cargo types

---

## Architecture Overview

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│   Sensors   │────▶│   FastAPI    │────▶│   Orchestrator   │
│ (Simulated) │     │   Backend    │     │                  │
└─────────────┘     └──────────────┘     └────────┬─────────┘
                                                  │
                           ┌──────────────────────┼──────────────────────┐
                           ▼                      ▼                      ▼
                    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
                    │  Agent 1:    │     │  Agent 2:    │     │  Agent 3:    │
                    │  Assessment  │────▶│  Decision    │────▶│ Communication│
                    └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                     │
                                                                     ▼
                                                              ┌──────────────┐
                                                              │  Agent 4:    │
                                                              │   Action     │
                                                              └──────┬───────┘
                                                                     │
                                         ┌───────────────────────────┼────────┐
                                         ▼                                    ▼
                                  ┌──────────────┐                  ┌──────────────┐
                                  │   Firebase   │                  │  Flutter App │
                                  │ Realtime DB  │◀────────────────▶│   (Mobile)   │
                                  └──────────────┘                  └──────────────┘
```

### Data Flow

1. **Sensor data** (simulated) is stored in Firebase at `/sensors`
2. **Breach detected** — temperature exceeds 8.0°C threshold
3. **FastAPI orchestrator** triggers the 4-agent pipeline via Gemini API
4. **Each agent** receives context from the previous agent and produces structured output
5. **Firebase is updated** — shipment quarantined, incident logged, status changed
6. **Flutter app** reflects all changes in real time via Firebase listeners
7. **SSE stream** provides live agent trace to the frontend for visualization

---

## Technology Stack

| Technology | Purpose | Used By |
|---|---|---|
| **Google Antigravity** | Agent orchestration, code generation, and development assistance | All Members |
| **Gemini API** (`google-genai`) | LLM reasoning for all 4 agents — assessment, decision, communication, action | Member 1 |
| **Firebase Realtime DB** | Live data storage for sensors, shipments, incidents, and system status | Member 1 |
| **Firebase Admin SDK** | Server-side Firebase access from Python backend | Member 1 |
| **FastAPI** (Python) | REST API backend with SSE streaming for agent trace | Member 1 |
| **Uvicorn** | ASGI server for FastAPI | Member 1 |
| **Flutter** | Cross-platform mobile application | Member 2 |
| **Riverpod** | Reactive state management for Flutter | Member 2 |
| **fl_chart** | Temperature graph visualization in the mobile app | Member 2 |
| **firebase_database** | Flutter plugin for real-time Firebase data sync | Member 2 |
| **rich** (Python) | Beautiful terminal output for demo presentations | Member 3 |
| **Pydantic** | Data validation and serialization for API models | Member 1 |
| **httpx** | HTTP client for integration testing | Member 3 |
| **pytest** | Test framework for automated testing | Member 3 |

---

## Team Roles

### Member 1 — Backend + AI Agents

**Responsibilities:**
- FastAPI backend with all API endpoints (`/sensors`, `/shipments`, `/trigger-breach`, `/agent-trace/stream`)
- Gemini API integration for all 4 agents
- Agent orchestrator — sequential pipeline with context passing
- Firebase read/write operations from the backend
- SSE streaming endpoint for real-time agent trace
- Breach detection logic and threshold evaluation

**Key Deliverables:**
- `main.py` — FastAPI application entry point
- `agents/` — All 4 agent modules
- `orchestrator.py` — Pipeline controller
- `firebase_service.py` — Firebase operations layer

---

### Member 2 — Flutter Mobile App

**Responsibilities:**
- Mobile application with 5 main screens
- Real-time Firebase data binding using Riverpod
- Temperature visualization with fl_chart
- Agent trace timeline UI
- Demo mode with local fallback data

**Key Deliverables:**
- Screen 1: **Dashboard** — Fleet overview with truck status cards
- Screen 2: **Truck Detail** — Live temperature graph + shipment info
- Screen 3: **Breach Alert** — Real-time breach notification with severity
- Screen 4: **Agent Trace** — Step-by-step visualization of agent pipeline
- Screen 5: **Incident Report** — Full incident summary with actions taken

---

### Member 3 — Data + Simulation + Documentation + Demo

**Responsibilities:**
- Mock data generation (trucks, shipments, companies)
- Firebase seeding and reset scripts
- Integration test suite
- Project documentation (workplan, API docs, README)
- Demo preparation and presentation
- Demo mode simulation scripts

**Key Deliverables:**
- `data/mock_trucks.json` — 10 refrigerated trucks with Pakistani logistics data
- `data/mock_shipments.json` — 20 shipment records linked to trucks
- `data/seed_firebase.py` — Database seeder
- `data/reset_firebase.py` — Demo state reset script
- `tests/integration_test.py` — End-to-end test suite
- `docs/WORKPLAN.md` — This document

---

## 7-Day Timeline

```
Day 1 ░░░░░░░░░░░░░░░░░░░░ Setup + Firebase + Mock Data
Day 2 ░░░░░░░░░░░░░░░░░░░░ FastAPI Backend + Agent Scaffolding
Day 3 ░░░░░░░░░░░░░░░░░░░░ All 4 Agents + Orchestrator
Day 4 ░░░░░░░░░░░░░░░░░░░░ Flutter Screens 1–3
Day 5 ░░░░░░░░░░░░░░░░░░░░ Flutter Screens 4–5 + Integration
Day 6 ░░░░░░░░░░░░░░░░░░░░ Testing + Polish + Demo Mode
Day 7 ░░░░░░░░░░░░░░░░░░░░ Documentation + Demo Video + Final Review
```

### Day 1 — Foundation

| Task | Owner | Status |
|---|---|---|
| Set up project repository and folder structure | Member 3 | ✅ Done |
| Create Firebase project and Realtime Database | Member 1 | ✅ Done |
| Generate `mock_trucks.json` (10 trucks) | Member 3 | ✅ Done |
| Generate `mock_shipments.json` (20 shipments) | Member 3 | ✅ Done |
| Create `seed_firebase.py` and seed database | Member 3 | ✅ Done |
| Create `reset_firebase.py` for demo resets | Member 3 | ✅ Done |
| Set up `requirements.txt` with all dependencies | Member 1 | ✅ Done |
| Create `.env` with Firebase configuration | Member 3 | ✅ Done |

### Day 2 — Backend API

| Task | Owner | Status |
|---|---|---|
| FastAPI app with `/sensors` and `/shipments` endpoints | Member 1 | ⬜ Pending |
| `POST /trigger-breach` endpoint with threshold logic | Member 1 | ⬜ Pending |
| Firebase service layer for read/write operations | Member 1 | ⬜ Pending |
| Agent scaffold — base class and prompt templates | Member 1 | ⬜ Pending |
| SSE streaming endpoint `/agent-trace/stream` | Member 1 | ⬜ Pending |
| Flutter project initialization | Member 2 | ⬜ Pending |

### Day 3 — AI Agent Pipeline

| Task | Owner | Status |
|---|---|---|
| Assessment Agent — breach analysis + severity scoring | Member 1 | ⬜ Pending |
| Decision Agent — action recommendation logic | Member 1 | ⬜ Pending |
| Communication Agent — stakeholder notification drafts | Member 1 | ⬜ Pending |
| Action Agent — execute decisions + update Firebase | Member 1 | ⬜ Pending |
| Orchestrator — sequential pipeline with context passing | Member 1 | ⬜ Pending |
| Flutter theme and design system setup | Member 2 | ⬜ Pending |

### Day 4 — Flutter App (Part 1)

| Task | Owner | Status |
|---|---|---|
| Screen 1: Dashboard — fleet overview with status cards | Member 2 | ⬜ Pending |
| Screen 2: Truck Detail — temperature graph + shipment info | Member 2 | ⬜ Pending |
| Screen 3: Breach Alert — real-time notification UI | Member 2 | ⬜ Pending |
| Firebase data providers with Riverpod | Member 2 | ⬜ Pending |
| Navigation and routing setup | Member 2 | ⬜ Pending |

### Day 5 — Flutter App (Part 2) + Integration

| Task | Owner | Status |
|---|---|---|
| Screen 4: Agent Trace — pipeline visualization | Member 2 | ⬜ Pending |
| Screen 5: Incident Report — full summary | Member 2 | ⬜ Pending |
| Connect Flutter app to live Firebase data | Member 2 | ⬜ Pending |
| End-to-end integration testing | Member 3 | ⬜ Pending |
| Demo mode with local fallback data | Member 2 | ⬜ Pending |

### Day 6 — Testing + Polish

| Task | Owner | Status |
|---|---|---|
| Run full integration test suite | Member 3 | ⬜ Pending |
| Fix bugs found during testing | All | ⬜ Pending |
| UI polish — animations, transitions, error states | Member 2 | ⬜ Pending |
| Terminal demo script with rich formatting | Member 3 | ⬜ Pending |
| Performance optimization (pipeline < 30s) | Member 1 | ⬜ Pending |

### Day 7 — Documentation + Demo

| Task | Owner | Status |
|---|---|---|
| Final documentation review | Member 3 | ⬜ Pending |
| Record demo video | Member 3 | ⬜ Pending |
| Prepare presentation slides | Member 3 | ⬜ Pending |
| Final rehearsal — end-to-end demo run | All | ⬜ Pending |
| Submit project | All | ⬜ Pending |

---

## Assumptions

1. **Fixed temperature threshold.** The breach threshold is set at **8.0°C** for all cargo types. In production, different cargo types (vaccines vs. dairy vs. seafood) would have different thresholds.

2. **Simulated sensor data.** We use pre-generated mock data stored in Firebase rather than real IoT hardware. The system architecture supports real sensors — only the data source would change.

3. **Estimated financial figures.** Cargo values and financial impact calculations are based on industry averages for Pakistani pharmaceutical and food logistics. They are realistic but not sourced from a specific client.

4. **Pakistani logistics context.** All driver names, company names, cities, routes, and warehouse locations are specific to Pakistan for local relevance in the hackathon demo.

5. **Simulated action execution.** The Action Agent logs what it *would* do (reroute truck, file insurance claim, dispatch replacement) but does not execute real-world actions. In production, these would integrate with actual logistics APIs.

6. **Gemini API availability.** We assume the Gemini API is available and responsive during the demo. A fallback mechanism (pre-recorded agent trace) is prepared in case of API issues.

7. **Single-tenant system.** The demo system manages a single fleet of 10 trucks. Multi-tenant support is a production consideration, not a hackathon scope item.

---

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Backend offline during demo** | Critical — app shows no data | Low | Flutter app has **Demo Mode** with local JSON fallback data. Dashboard works fully offline. |
| **Gemini API slow or unavailable** | High — agent pipeline fails | Medium | Pre-recorded agent trace JSON stored locally. Pipeline can replay cached results for demo. |
| **Firebase connectivity issues** | High — no real-time updates | Low | Local JSON fallback in Flutter. Backend can operate with in-memory data if Firebase is down. |
| **Agent produces poor output** | Medium — demo looks unprofessional | Medium | Extensive prompt engineering + output validation. Fallback to pre-crafted responses if quality is low. |
| **Pipeline exceeds 30s timeout** | Medium — demo feels slow | Low | Each agent has individual timeouts. Pipeline can short-circuit and return partial results. |
| **Flutter build issues on demo day** | Critical — no mobile app | Low | Pre-built APK prepared day before. Screen recordings as ultimate fallback. |
| **Integration test failures** | Medium — undetected bugs | Medium | Run `reset_firebase.py` + full test suite before every demo attempt. |

---

## Demo Script (Quick Reference)

```bash
# Step 1: Reset database to clean demo state
python data/reset_firebase.py

# Step 2: Start the backend server
uvicorn main:app --reload

# Step 3: Verify everything works
python tests/integration_test.py

# Step 4: Open Flutter app on device/emulator
# → Show dashboard with 10 trucks
# → Tap TRK-004 (breach truck) to trigger the agent pipeline
# → Watch all 4 agents respond in real time
# → Show the incident report and quarantined shipment
```

---

## Success Criteria

- [ ] All 4 agents complete the pipeline in under 30 seconds
- [ ] Flutter app displays real-time breach alerts with temperature graphs
- [ ] Agent trace shows step-by-step reasoning in the mobile UI
- [ ] Integration tests pass: `ALL TESTS PASSED — System ready for demo`
- [ ] Demo runs smoothly end-to-end without manual intervention
- [ ] Judges understand the autonomous response concept within 60 seconds

---

*Last updated: May 15, 2026*
*Document owner: Member 3 (Data + Documentation)*
