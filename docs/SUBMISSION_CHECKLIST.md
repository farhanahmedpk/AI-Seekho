# ColdGuard — Final Submission Checklist

> **Use this checklist on Day 7 before submitting.**
> Every item must be checked. No exceptions.

---

## Code Repository

- [ ] All code pushed to GitHub repository
- [ ] Repository is public (or shared with judges)
- [ ] `.env.example` present with placeholder values (no real API keys in repo)
- [ ] `.gitignore` excludes: `.env`, `serviceAccountKey.json`, `__pycache__/`, `.dart_tool/`, `build/`
- [ ] `README.md` complete with setup instructions
- [ ] `ANTIGRAVITY.md` complete with usage explanation
- [ ] `requirements.txt` up to date with all Python dependencies
- [ ] Flutter `pubspec.yaml` up to date with all Dart dependencies

### Verify

```bash
# Clone fresh and confirm everything works
git clone <repo-url> coldguard-test
cd coldguard-test
pip install -r requirements.txt     # Should install without errors
```

---

## Documents

| Document | Path | Status |
|----------|------|--------|
| Project Workplan | `docs/WORKPLAN.md` | [ ] Complete |
| Task Plan | `docs/TASK_PLAN.md` | [ ] Complete |
| Agent Trace Report | `docs/agent_trace_report.html` | [ ] Generated and professional |
| Demo Script | `docs/DEMO_SCRIPT.md` | [ ] Complete |
| Submission Checklist | `docs/SUBMISSION_CHECKLIST.md` | [ ] Complete (this file) |
| API Documentation | `docs/API_DOCS.md` | [ ] Complete |
| README | `README.md` | [ ] Complete |
| Antigravity Usage | `ANTIGRAVITY.md` | [ ] Complete |

### Verify

- [ ] Open `agent_trace_report.html` in browser — dark theme, all 4 agents visible, JSON highlighted
- [ ] Read through `WORKPLAN.md` — no placeholder text remaining
- [ ] Read through `TASK_PLAN.md` — all task statuses updated to final state

---

## Flutter Application

### Build

- [ ] APK builds successfully:
  ```bash
  flutter build apk --release
  ```
- [ ] APK file exists at `build/app/outputs/flutter-apk/app-release.apk`
- [ ] APK installs on physical Android device without errors
- [ ] App name shows as **"ColdGuard"** on device home screen
- [ ] App icon is custom (not default Flutter icon)

### Screens

- [ ] **Screen 1 — Dashboard:** Shows 10 trucks with correct status colors (green/amber/red)
- [ ] **Screen 2 — Truck Detail:** Temperature graph renders, shipment info visible
- [ ] **Screen 3 — Breach Alert:** Red banner, severity badge, financial exposure shown
- [ ] **Screen 4 — Agent Trace:** All 4 agents displayed in timeline with reasoning
- [ ] **Screen 5 — Incident Report:** Full summary with actions taken
- [ ] **Incident History:** Past incidents listed
- [ ] **Settings:** Connection URL configurable, Demo Mode toggle works

### Demo Mode

- [ ] Toggle Demo Mode ON in settings
- [ ] Turn off WiFi / mobile data on the phone
- [ ] Dashboard still loads with all 10 trucks
- [ ] Tapping TRK-004 still shows breach data
- [ ] Agent trace still displays with pre-recorded data
- [ ] **No crashes or blank screens when offline**

---

## Backend + Agents

### Endpoints

- [ ] `GET /sensors` — returns 10 trucks, status 200
- [ ] `GET /shipments` — returns 20 shipments, status 200
- [ ] `GET /incidents` — returns incidents list, status 200
- [ ] `POST /trigger-breach` — breach detection works for TRK-004 at 12.5°C
- [ ] `POST /trigger-breach` — non-breach returns `breach_detected: false` for 5.0°C
- [ ] `GET /agent-trace/stream/{truck_id}/{temp}` — SSE stream delivers 4 chunks

### Agent Pipeline

- [ ] Assessment Agent produces structured severity analysis
- [ ] Decision Agent outputs quarantine/reroute/monitor decision
- [ ] Communication Agent drafts 4 stakeholder notifications
- [ ] Action Agent executes 6 actions and updates Firebase
- [ ] Full pipeline completes in under 30 seconds
- [ ] Pipeline output is valid JSON

---

## Demo Video

### Content

- [ ] Video duration: between **3:00 and 5:00**
- [ ] **Shot 1:** Problem introduction with context
- [ ] **Shot 2:** Normal dashboard — fleet overview
- [ ] **Shot 3:** Breach alert — TRK-004 at 12.5°C
- [ ] **Shot 4:** Agent pipeline running live (hero shot)
- [ ] **Shot 5:** Actions executing — quarantine, notify, replace
- [ ] **Shot 6:** Before/after outcome comparison
- [ ] **Shot 7:** Closing with resolved dashboard
- [ ] Mentions **"Google Antigravity"** at least twice
- [ ] Mentions **"Gemini API"** at least once
- [ ] Agent trace reasoning text is clearly readable on screen

### Technical

- [ ] Resolution: 1080p (1920x1080) minimum
- [ ] Format: MP4 (H.264)
- [ ] File size: under 500MB
- [ ] Audio is clear — no background noise
- [ ] Captions/subtitles added for key moments
- [ ] No copyrighted music (use YouTube Audio Library)

### Distribution

- [ ] Video uploaded to **Google Drive** (shared with judges) or **YouTube** (unlisted)
- [ ] Sharing link tested — opens without sign-in required
- [ ] Link added to README.md and submission form

---

## Agent Trace for Judges

- [ ] Run `python docs/generate_trace_report.py` — HTML report generated
- [ ] Open `docs/agent_trace_report.html` in browser — verify all sections render
- [ ] Screenshot the following sections for submission form:
  - [ ] Breach Input card
  - [ ] Assessment Agent output + reasoning
  - [ ] Decision Agent output + reasoning
  - [ ] Pipeline summary with timing
  - [ ] Decision flow chart
- [ ] Export full JSON trace as `docs/agent_trace.json` (if required by submission form)

---

## Firebase

- [ ] Firebase Realtime Database has data at `/sensors` (10 trucks)
- [ ] Firebase Realtime Database has data at `/shipments` (20 shipments)
- [ ] Firebase security rules allow read access for the app
- [ ] Firebase project is on the free Spark plan (no billing surprises)

---

## Final Checks (Day 7 Morning)

Do this **in order**, checking each step:

```
Step 1:  python data/reset_firebase.py
         → "Database reset to demo state ✓"

Step 2:  uvicorn main:app --reload
         → Server running on http://127.0.0.1:8000

Step 3:  python tests/integration_test.py
         → "ALL TESTS PASSED — System ready for demo"

Step 4:  python docs/generate_trace_report.py
         → HTML report generated

Step 5:  Open Flutter app → Dashboard → 10 trucks visible

Step 6:  Tap TRK-004 → Breach alert → Tap "Analyze with AI"
         → All 4 agents complete

Step 7:  Full dry run of demo video script (3:30 target)
         → No crashes, no errors, smooth flow

Step 8:  All team members have APK installed on their phones
```

- [ ] Step 1 passed
- [ ] Step 2 passed
- [ ] Step 3 passed
- [ ] Step 4 passed
- [ ] Step 5 passed
- [ ] Step 6 passed
- [ ] Step 7 passed
- [ ] Step 8 passed

---

## Submission Form Fields

Have these ready to paste:

| Field | Value |
|-------|-------|
| **Project Name** | ColdGuard |
| **Team Name** | *(your team name)* |
| **GitHub URL** | *(repo link)* |
| **Demo Video URL** | *(Google Drive or YouTube link)* |
| **APK Download** | *(Google Drive link to APK)* |
| **Tech Stack** | FastAPI, Gemini API, Firebase, Flutter, Google Antigravity |
| **One-line Description** | Autonomous AI system that detects cold chain breaches and responds in under 30 seconds using a 4-agent pipeline |

---

> **Remember:** Run `reset_firebase.py` one final time right before the judges test your app. Fresh state = clean demo.

---

*Last updated: May 15, 2026*
*Document owner: Member 3 (Documentation)*
