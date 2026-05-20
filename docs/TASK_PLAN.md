# ColdGuard — Task Plan

> **Detailed Task Breakdown by Team Member**
> For judges, mentors, and team coordination

---

## Member 1 Tasks — Backend + AI Agents

Member 1 is responsible for the FastAPI backend, Gemini-powered agent pipeline, Firebase integration, and all server-side logic.

| Task ID | Task Name | Description | Dependencies | Est. Time | Status |
|---------|-----------|-------------|--------------|-----------|--------|
| **M1-T01** | Project Setup & Dependencies | Initialize Python project, create `requirements.txt` with FastAPI, Firebase Admin, Gemini SDK, Pydantic, and all dependencies | — | 30 min | ✅ Completed |
| **M1-T02** | Firebase Project Configuration | Create Firebase project, enable Realtime Database, generate service account key, configure security rules | — | 30 min | ✅ Completed |
| **M1-T03** | Environment Configuration | Set up `.env` file with `FIREBASE_DATABASE_URL`, `GEMINI_API_KEY`, and other secrets; create `.env.example` template | M1-T02 | 15 min | ✅ Completed |
| **M1-T04** | Firebase Service Layer | Create `firebase_service.py` — singleton Firebase client with read/write helpers for `/sensors`, `/shipments`, `/incidents` | M1-T02, M1-T03 | 1 hr | ⬜ Pending |
| **M1-T05** | Pydantic Data Models | Define request/response models: `TruckSensor`, `Shipment`, `BreachRequest`, `BreachResponse`, `AgentResult`, `IncidentReport` | — | 45 min | ⬜ Pending |
| **M1-T06** | FastAPI App Scaffold | Create `main.py` with CORS, Firebase init on startup, health check endpoint, and modular router registration | M1-T04, M1-T05 | 30 min | ⬜ Pending |
| **M1-T07** | GET /sensors Endpoint | Return all truck sensor data from Firebase `/sensors` node; support optional `?status=breach` filter | M1-T04, M1-T06 | 30 min | ⬜ Pending |
| **M1-T08** | GET /shipments Endpoint | Return all shipment data from Firebase `/shipments` node; support optional `?truck_id=TRK-004` filter | M1-T04, M1-T06 | 30 min | ⬜ Pending |
| **M1-T09** | GET /incidents Endpoint | Return all logged incidents from Firebase `/incidents` node | M1-T04, M1-T06 | 20 min | ⬜ Pending |
| **M1-T10** | Breach Detection Logic | Implement threshold comparison: if `current_temp > threshold_temp`, classify as breach; calculate severity (Warning / Critical / Emergency) | M1-T05 | 30 min | ⬜ Pending |
| **M1-T11** | POST /trigger-breach Endpoint | Accept `truck_id` and `current_temp_celsius`; run breach detection; if breach, trigger agent pipeline; return full result | M1-T06, M1-T10 | 45 min | ⬜ Pending |
| **M1-T12** | Gemini API Client Setup | Create `gemini_client.py` — configure Gemini API with key, model selection (`gemini-2.0-flash`), and structured output parsing | M1-T03 | 30 min | ⬜ Pending |
| **M1-T13** | Agent Base Class | Create `agents/base_agent.py` — abstract base with `run()` method, prompt template, structured output parsing, timing, and error handling | M1-T12 | 30 min | ⬜ Pending |
| **M1-T14** | Assessment Agent | `agents/assessment_agent.py` — Analyzes breach severity, cargo risk, financial exposure, and time criticality; outputs structured JSON | M1-T13 | 1.5 hr | ⬜ Pending |
| **M1-T15** | Decision Agent | `agents/decision_agent.py` — Receives assessment; decides action (quarantine / reroute / emergency stop / monitor); provides reasoning | M1-T13, M1-T14 | 1.5 hr | ⬜ Pending |
| **M1-T16** | Communication Agent | `agents/communication_agent.py` — Drafts notifications for driver, dispatcher, client, and insurance; generates email/SMS content | M1-T13, M1-T15 | 1.5 hr | ⬜ Pending |
| **M1-T17** | Action Agent | `agents/action_agent.py` — Executes decision: updates shipment status to QUARANTINED, logs incident to Firebase, triggers simulated actions | M1-T13, M1-T16 | 1.5 hr | ⬜ Pending |
| **M1-T18** | Pipeline Orchestrator | Create `orchestrator.py` — runs all 4 agents sequentially, passes context between agents, tracks timing, handles errors gracefully | M1-T14 – M1-T17 | 1 hr | ⬜ Pending |
| **M1-T19** | SSE Streaming Endpoint | `GET /agent-trace/stream/{truck_id}/{temperature}` — Server-Sent Events stream that pushes each agent's result as it completes | M1-T18 | 1 hr | ⬜ Pending |
| **M1-T20** | Non-Breach Handling | Ensure `POST /trigger-breach` with normal temps returns `breach_detected: false` with no agent execution | M1-T10, M1-T11 | 20 min | ⬜ Pending |
| **M1-T21** | Error Handling & Logging | Add structured logging with loguru; handle Gemini timeouts, Firebase errors, and malformed requests gracefully | M1-T06, M1-T18 | 45 min | ⬜ Pending |
| **M1-T22** | Backend Testing | Test all endpoints manually and verify agent outputs are well-structured; fix edge cases | M1-T07 – M1-T20 | 1 hr | ⬜ Pending |

**Member 1 Total Estimated Time: ~15 hours**

---

## Member 2 Tasks — Flutter Mobile App

Member 2 is responsible for the cross-platform mobile application with real-time Firebase data display, temperature visualization, and agent trace UI.

| Task ID | Task Name | Description | Dependencies | Est. Time | Status |
|---------|-----------|-------------|--------------|-----------|--------|
| **M2-T01** | Flutter Project Init | Initialize Flutter project with `flutter create`, add dependencies (firebase_database, riverpod, fl_chart, google_fonts) | — | 30 min | ⬜ Pending |
| **M2-T02** | Firebase Flutter Setup | Configure `google-services.json`, initialize Firebase in `main.dart`, verify connection to Realtime Database | M1-T02 | 30 min | ⬜ Pending |
| **M2-T03** | Design System & Theme | Create app theme with dark mode, color palette (normal=green, elevated=amber, breach=red), typography (Inter/Outfit), and reusable components | — | 1 hr | ⬜ Pending |
| **M2-T04** | Data Models (Dart) | Create Dart model classes: `Truck`, `Shipment`, `Incident`, `AgentResult` with JSON serialization | — | 45 min | ⬜ Pending |
| **M2-T05** | Riverpod Providers — Trucks | Create `StreamProvider` for `/sensors` node — real-time truck list with auto-updates | M2-T02, M2-T04 | 45 min | ⬜ Pending |
| **M2-T06** | Riverpod Providers — Shipments | Create `StreamProvider` for `/shipments` node — real-time shipment data | M2-T02, M2-T04 | 30 min | ⬜ Pending |
| **M2-T07** | Riverpod Providers — Incidents | Create `StreamProvider` for `/incidents` node — real-time incident feed | M2-T02, M2-T04 | 30 min | ⬜ Pending |
| **M2-T08** | Navigation & Routing | Set up GoRouter or Navigator 2.0 with routes for all 5 screens; bottom navigation bar | M2-T03 | 30 min | ⬜ Pending |
| **M2-T09** | Screen 1: Dashboard | Fleet overview — 10 truck cards showing status (green/amber/red), current temp, cargo type, route; tap to navigate to detail | M2-T05, M2-T08 | 2 hr | ⬜ Pending |
| **M2-T10** | Screen 2: Truck Detail | Single truck view — live temperature display, cargo info, driver details, linked shipments list, temperature history graph (fl_chart) | M2-T05, M2-T06 | 2.5 hr | ⬜ Pending |
| **M2-T11** | Temperature Graph Widget | fl_chart line graph showing temperature over time with threshold line at 8.0°C; color-coded zones (safe=green, danger=red) | M2-T10 | 1.5 hr | ⬜ Pending |
| **M2-T12** | Screen 3: Breach Alert | Full-screen breach alert with severity badge, affected cargo details, financial risk, and "View Agent Response" button | M2-T05 | 1.5 hr | ⬜ Pending |
| **M2-T13** | Screen 4: Agent Trace | Timeline UI showing all 4 agents in sequence — each with status (running/complete), duration, and expandable output summary | M2-T07 | 2.5 hr | ⬜ Pending |
| **M2-T14** | Screen 5: Incident Report | Full incident summary — breach details, agent decisions, actions taken, communications sent, financial impact, timestamp log | M2-T07 | 2 hr | ⬜ Pending |
| **M2-T15** | Demo Mode | Offline fallback using local JSON files (`mock_trucks.json`, `mock_shipments.json`); toggle in settings; works without backend or Firebase | M2-T09 – M2-T14 | 1.5 hr | ⬜ Pending |
| **M2-T16** | Animations & Polish | Add micro-animations: card entrance, temperature pulse on breach, agent trace step transitions, loading shimmer effects | M2-T09 – M2-T14 | 1.5 hr | ⬜ Pending |
| **M2-T17** | Responsive Layout | Ensure all screens work on different screen sizes; test on at least 2 device form factors | M2-T09 – M2-T14 | 1 hr | ⬜ Pending |
| **M2-T18** | APK Build & Test | Build release APK, install on physical device, verify all screens and real-time data | M2-T01 – M2-T17 | 1 hr | ⬜ Pending |

**Member 2 Total Estimated Time: ~20 hours**

---

## Member 3 Tasks — Data + Simulation + Documentation + Demo

Member 3 is responsible for mock data, Firebase seeding, testing, all project documentation, and demo preparation.

| Task ID | Task Name | Description | Dependencies | Est. Time | Status |
|---------|-----------|-------------|--------------|-----------|--------|
| **M3-T01** | Mock Trucks Data | Create `data/mock_trucks.json` — 10 trucks with Pakistani driver names, cargo types, routes, temperatures (normal/elevated/breach) | — | 30 min | ✅ Completed |
| **M3-T02** | Mock Shipments Data | Create `data/mock_shipments.json` — 20 shipments linked to trucks, with Pakistani company names, warehouses, and cargo values | M3-T01 | 45 min | ✅ Completed |
| **M3-T03** | Firebase Seeder Script | Create `data/seed_firebase.py` — reads JSON files and uploads to Firebase at `/sensors`, `/shipments`, `/incidents`, `/system_status` | M3-T01, M3-T02 | 30 min | ✅ Completed |
| **M3-T04** | Firebase Reset Script | Create `data/reset_firebase.py` — clears incidents, resets TRK-004 to breach state, resets SHP-004 to in_transit; run before every demo | M3-T03 | 30 min | ✅ Completed |
| **M3-T05** | Seed Firebase Database | Run `seed_firebase.py` to populate the live Firebase Realtime Database with all mock data | M3-T03 | 10 min | ✅ Completed |
| **M3-T06** | Integration Test Suite | Create `tests/integration_test.py` — 6 end-to-end tests covering health check, breach, agents, Firebase, streaming, non-breach | M1-T07 – M1-T19 | 1 hr | ✅ Completed |
| **M3-T07** | Project Workplan | Create `docs/WORKPLAN.md` — overview, problem statement, solution, architecture, tech stack, team roles, timeline, risks | — | 1 hr | ✅ Completed |
| **M3-T08** | Task Plan | Create `docs/TASK_PLAN.md` — detailed per-member task breakdown with IDs, dependencies, estimates, and status tracking | — | 45 min | 🔄 In Progress |
| **M3-T09** | API Documentation | Create `docs/API_DOCS.md` — document every endpoint with request/response examples, status codes, and error formats | M1-T07 – M1-T19 | 1 hr | ⬜ Pending |
| **M3-T10** | Project README | Create root `README.md` — setup instructions, architecture diagram, how to run, how to test, team credits | M3-T07, M3-T09 | 1 hr | ⬜ Pending |
| **M3-T11** | Demo Terminal Script | Create `demo/run_demo.py` — rich-formatted terminal walkthrough that triggers breach and displays agent output beautifully | M1-T18 | 1.5 hr | ⬜ Pending |
| **M3-T12** | Pre-Demo Checklist | Create `docs/DEMO_CHECKLIST.md` — step-by-step checklist to run before every demo (reset DB, start server, verify tests, open app) | M3-T04, M3-T06 | 20 min | ⬜ Pending |
| **M3-T13** | Run Integration Tests | Execute full integration test suite after Member 1 and Member 2 complete their work; document results | M1-T22, M2-T18 | 30 min | ⬜ Pending |
| **M3-T14** | Demo Video Recording | Record 3–5 minute demo video showing full breach detection → agent response → mobile app flow | M3-T13 | 1.5 hr | ⬜ Pending |
| **M3-T15** | Final Documentation Review | Review all docs for accuracy, fix broken links, ensure consistency across workplan/task plan/API docs/README | M3-T07 – M3-T10 | 30 min | ⬜ Pending |

**Member 3 Total Estimated Time: ~10 hours**

---

## Integration Milestones

These are the 5 critical checkpoints where individual work converges into a working system.

| # | Milestone | Required Tasks | Target Day | Status |
|---|-----------|---------------|------------|--------|
| **IM-1** | **Backend + Firebase Running Locally** | M1-T01 – M1-T09, M3-T05 | Day 2 | ⬜ Pending |
| | *Criteria:* FastAPI serves `/sensors` (10 trucks) and `/shipments` (20 shipments) from live Firebase. `GET http://localhost:8000/sensors` returns 200. | | | |
| **IM-2** | **Agent Pipeline Completing End-to-End** | M1-T10 – M1-T18 | Day 3 | ⬜ Pending |
| | *Criteria:* `POST /trigger-breach` with TRK-004 at 12.5°C triggers all 4 agents, returns structured result in < 30 seconds. SHP-004 status changes to QUARANTINED in Firebase. | | | |
| **IM-3** | **Flutter App Connecting to Backend** | M2-T01 – M2-T10, IM-1 | Day 5 | ⬜ Pending |
| | *Criteria:* Flutter app displays live truck data from Firebase. Tapping a truck shows detail screen with temperature graph. Data updates in real time when Firebase changes. | | | |
| **IM-4** | **Full Demo Flow on Physical Device** | M2-T12 – M2-T14, IM-2, IM-3 | Day 6 | ⬜ Pending |
| | *Criteria:* Complete flow works on a physical Android device: Dashboard → tap breach truck → see agent trace → view incident report. Demo mode toggle works offline. | | | |
| **IM-5** | **All Documentation Complete and Submitted** | M3-T07 – M3-T15 | Day 7 | ⬜ Pending |
| | *Criteria:* WORKPLAN.md, TASK_PLAN.md, API_DOCS.md, and README.md are complete, reviewed, and consistent. Demo video is recorded and under 5 minutes. | | | |

### Milestone Dependency Chain

```
  IM-1 (Backend + Firebase)
    │
    ├──── IM-2 (Agent Pipeline)
    │       │
    │       └──── IM-4 (Full Demo Flow)
    │               │
    │               └──── IM-5 (Documentation Complete)
    │
    └──── IM-3 (Flutter Connected)
            │
            └──── IM-4 (Full Demo Flow)
```

---

## Task Dependency Graph

```
Member 3 (Data)               Member 1 (Backend)              Member 2 (Flutter)
──────────────                ──────────────────              ──────────────────

M3-T01 Mock Trucks ──┐
                     ├──▶ M3-T03 Seeder ──▶ M3-T05 Seed DB
M3-T02 Mock Shipments┘         │
                               │
M3-T04 Reset Script ◀──────────┘

                              M1-T04 Firebase Service
                                      │
                              M1-T06 FastAPI Scaffold
                               │      │       │
                         M1-T07│ M1-T08│  M1-T09│
                         /sensors /shipments /incidents
                               │
                              M1-T10 Breach Logic
                               │
                              M1-T11 /trigger-breach
                               │
                    ┌──────────┴──────────┐
               M1-T12 Gemini Client   M1-T13 Base Agent
                    │                     │
               M1-T14 Assessment ────────▶│
               M1-T15 Decision ──────────▶│
               M1-T16 Communication ─────▶│
               M1-T17 Action ────────────▶│
                    │                     │
                    └──────────┬──────────┘
                              │
                         M1-T18 Orchestrator
                              │
                         M1-T19 SSE Streaming
                              │                          M2-T01 Flutter Init
                              │                               │
M3-T06 Integration Tests ◀───┤                          M2-T02 Firebase Setup
                              │                               │
                              │                     ┌────M2-T05 Truck Provider
                              │                     │    M2-T06 Shipment Provider
                              │                     │    M2-T07 Incident Provider
                              │                     │         │
                              │                     │    M2-T09 Dashboard
                              │                     │    M2-T10 Truck Detail
                              │                     │    M2-T12 Breach Alert
                              │                     │    M2-T13 Agent Trace
                              │                     │    M2-T14 Incident Report
                              │                     │         │
                              └─────────────────────┴────M2-T15 Demo Mode
                                                              │
                                                         M2-T18 APK Build
```

---

## Definition of Done

The project is considered **complete and ready for submission** when ALL of the following criteria are met:

### Functional Completeness
- [ ] All 4 AI agents produce structured, meaningful output via Gemini API
- [ ] Agent pipeline completes end-to-end in under 30 seconds
- [ ] All 6 integration tests pass: `ALL TESTS PASSED — System ready for demo`
- [ ] Firebase state updates correctly after pipeline runs (SHP-004 → QUARANTINED, incidents logged)
- [ ] SSE streaming delivers all 4 agent chunks in order

### Mobile Application
- [ ] All 5 Flutter screens are implemented and functional
- [ ] Real-time data updates work via Firebase listeners
- [ ] Temperature graph renders correctly with threshold line
- [ ] Demo mode works fully offline with local JSON data
- [ ] APK builds successfully and installs on a physical Android device

### Documentation
- [ ] `docs/WORKPLAN.md` — Project overview, architecture, timeline, risks
- [ ] `docs/TASK_PLAN.md` — Per-member task breakdown with status tracking
- [ ] `docs/API_DOCS.md` — All endpoints documented with examples
- [ ] `README.md` — Setup instructions, architecture, how to run

### Demo Readiness
- [ ] `data/reset_firebase.py` successfully resets to clean demo state
- [ ] Demo video is recorded and under 5 minutes
- [ ] Full demo flow works: breach detection → agent response → mobile UI update
- [ ] Fallback plan is tested (demo mode works if backend/API is down)
- [ ] Team has rehearsed the demo at least once end-to-end

---

## Progress Summary

| Member | Total Tasks | Completed | In Progress | Pending | Completion |
|--------|-------------|-----------|-------------|---------|------------|
| Member 1 | 22 | 3 | 0 | 19 | 14% |
| Member 2 | 18 | 0 | 0 | 18 | 0% |
| Member 3 | 15 | 7 | 1 | 7 | 47% |
| **Total** | **55** | **10** | **1** | **44** | **18%** |

---

*Last updated: May 15, 2026*
*Document owner: Member 3 (Data + Documentation)*
