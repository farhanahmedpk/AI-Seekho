# ColdGuard — Demo Video Script

> **Duration:** 3:30 (target) | **Max:** 5:00
> **Format:** Split-screen — phone (right) + laptop terminal (left)
> **Resolution:** 1080p minimum | **Export:** MP4, under 500MB

---

## Pre-Recording Checklist

Run through this **every time** before hitting record:

- [ ] Run `python data/reset_firebase.py` — reset database to clean demo state
- [ ] Verify output: `Database reset to demo state ✓`
- [ ] Start FastAPI backend: `uvicorn main:app --reload`
- [ ] Verify: `http://127.0.0.1:8000/sensors` returns 10 trucks in browser
- [ ] Open Flutter app on physical Android device
- [ ] Enable **Demo Mode** in app settings (gear icon)
- [ ] Verify dashboard shows 10 trucks — 8 green, 1 amber, 1 red
- [ ] Have `simulation/demo_controller.py` ready in terminal (don't run yet)
- [ ] Start screen recording on **both** phone and laptop
- [ ] Close all notifications / Do Not Disturb on both devices
- [ ] Test microphone if recording narration live

> **IMPORTANT:** If any step fails, run `reset_firebase.py` again and restart.

---

## Shot 1 — Problem Introduction

| | |
|---|---|
| **Time** | 0:00 – 0:20 (20 seconds) |
| **Screen** | App splash / logo animation on phone |
| **Laptop** | Black screen or title card |

### Narration

> *"Every year, cold chain failures cost Pakistan's pharmaceutical and food industry billions of rupees. A single temperature breach can destroy an entire shipment of vaccines or insulin.*
>
> *Current systems detect the problem and alert a human. But by the time someone responds — 30 to 60 minutes later — the cargo is already lost.*
>
> *ColdGuard changes that."*

### Visual Notes
- Phone shows the ColdGuard splash screen / logo animation
- If no splash animation exists, show a static title card with the ColdGuard logo
- Keep this shot clean and simple — the narration carries it

---

## Shot 2 — Normal Dashboard

| | |
|---|---|
| **Time** | 0:20 – 0:50 (30 seconds) |
| **Screen** | Dashboard — fleet overview with 10 truck cards |
| **Laptop** | Terminal showing backend running (optional) |

### Narration

> *"ColdGuard monitors your entire refrigerated fleet in real time. Here's our dashboard — 10 trucks, carrying vaccines, dairy, meat, and pharmaceuticals across Pakistan.*
>
> *Each card shows the truck's current temperature, cargo type, and route. Green means safe. Amber means elevated. And red..."*
>
> *(pause — let the viewer's eye find TRK-004)*
>
> *"...red means we have a problem."*

### Visual Notes
- **Slowly scroll** through the dashboard — don't rush
- Pan across the green cards first to establish normalcy
- Pause briefly on **TRK-008** (amber, 7.6°C) — acknowledge it with the "amber" mention
- End the scroll on **TRK-004** (red, 12.5°C) — hold for 2 seconds
- The red card should visually pop against the green ones

### Key Data Visible
| Truck | Temp | Status | Cargo |
|-------|------|--------|-------|
| TRK-001 | 4.2°C | 🟢 Normal | Vaccines |
| TRK-008 | 7.6°C | 🟡 Elevated | Meat |
| TRK-004 | 12.5°C | 🔴 Breach | Vaccines |

---

## Shot 3 — Breach Alert

| | |
|---|---|
| **Time** | 0:50 – 1:20 (30 seconds) |
| **Screen** | Truck detail → Breach alert screen |
| **Laptop** | Optional — backend logs showing breach detection |

### Narration

> *"TRK-004 is carrying insulin vials from Islamabad to Peshawar. The temperature has hit 12.5 degrees — that's 56% above the safe threshold of 8 degrees.*
>
> *In a normal system, an operator would get a notification, check their phone, call the driver, figure out what to do, and maybe act in 30 minutes.*
>
> *With ColdGuard, the AI responds in seconds."*

### Actions (what to tap/show)
1. **Tap TRK-004** on the dashboard
2. Truck detail screen loads — show the temperature graph with the spike above the red 8°C threshold line
3. **Breach alert banner** appears — pulsing red, showing:
   - Temperature: **12.5°C** (flashing)
   - Deviation: **+4.5°C above threshold**
   - Cargo at risk: **Insulin Vials — PKR 24,000,000**
   - Severity: **CRITICAL**
4. Hold on this screen for 3–4 seconds to let the severity sink in

### Visual Notes
- The temperature graph is the money shot — make sure it's clearly visible
- The red threshold line at 8°C should be obvious
- If the graph animates, let it complete before narrating

---

## Shot 4 — Agent Pipeline (The Hero Shot)

| | |
|---|---|
| **Time** | 1:20 – 2:10 (50 seconds) |
| **Screen** | Agent Trace screen — all 4 agents running |
| **Laptop** | Terminal showing agent logs (optional but impressive) |

### Narration

> *"Watch this. I tap 'Analyze with AI' — and four autonomous agents powered by Google Antigravity and Gemini take over."*
>
> *(Agent 1 appears)*
> *"Agent one — the Assessment Agent — analyzes the breach. Severity: Critical. Financial exposure: 24 million rupees. Cargo viability: at risk."*
>
> *(Agent 2 appears)*
> *"Agent two — the Decision Agent — decides the response. Quarantine the shipment. Don't reroute — the cargo is already compromised. Dispatch a replacement."*
>
> *(Agent 3 appears)*
> *"Agent three — Communication. It drafts an SMS to the driver: pull over immediately. An email to the dispatcher. A professional notification to the client. And an insurance claim — all automatically."*
>
> *(Agent 4 appears)*
> *"Agent four — Action. It executes everything. Shipment quarantined in the system. Driver notified. Client informed. Insurance claim filed. Replacement truck dispatched."*
>
> *"Four agents, six actions, all in under 30 seconds."*

### Actions (what to tap/show)
1. Tap **"Analyze with AI"** button on the breach alert screen
2. Agent Trace screen opens — timeline view
3. **Agent 1** card animates in — show RUNNING → COMPLETED (green check)
4. **Agent 2** card animates in — RUNNING → COMPLETED
5. **Agent 3** card animates in — RUNNING → COMPLETED
6. **Agent 4** card animates in — RUNNING → COMPLETED
7. Each card expands briefly to show the reasoning text

### Visual Notes
- This is the **most important shot** — take your time, 50 seconds
- If agents complete too fast, slow down the narration and let the viewer read
- Expand at least 1–2 agent cards to show the reasoning text
- The laptop can show the terminal with `rich` formatted agent logs running simultaneously — very impressive for judges
- If the pipeline fails, use Demo Mode which shows pre-recorded data

### Timing Target
- The real pipeline should complete in **8–15 seconds**
- Use the remaining time to narrate over the results
- Don't rush through this — judges need to see the AI reasoning

---

## Shot 5 — Actions Executing

| | |
|---|---|
| **Time** | 2:10 – 2:40 (30 seconds) |
| **Screen** | Actions/execution screen |
| **Laptop** | Firebase console showing live updates (optional) |

### Narration

> *"Let's look at what ColdGuard actually did.*
>
> *Shipment SHP-004 — status changed from 'In Transit' to 'Quarantined.' No one can deliver compromised insulin.*
>
> *The client, HealthFirst Distributors, received a professional notification with an insurance reference number.*
>
> *And a replacement truck is already on the way — ETA 45 minutes."*

### Actions (what to show)
1. Show the **actions list** — each action card transitioning:
   - `SHIPMENT_QUARANTINED` → ✅ Done
   - `DRIVER_SMS_SENT` → ✅ Done
   - `CLIENT_NOTIFIED` → ✅ Done
   - `INSURANCE_CLAIM_FILED` → ✅ Done
   - `REPLACEMENT_DISPATCHED` → ✅ Done
2. If Flutter has animation, show cards flipping from PENDING → EXECUTING → DONE
3. Optionally switch to laptop and show Firebase Console with `/incidents` populated

### Visual Notes
- Each action completing gives a sense of the system doing real work
- If possible, show the Firebase Realtime Database updating live — very convincing for judges
- Quick shot of the notification text (SMS to driver) adds realism

---

## Shot 6 — Before/After Outcome

| | |
|---|---|
| **Time** | 2:40 – 3:10 (30 seconds) |
| **Screen** | Incident report / outcome screen |
| **Laptop** | Agent trace HTML report (optional) |

### Narration

> *"Here's the outcome.*
>
> *Before ColdGuard: a critical breach with no automated response. The cargo degrades, the client finds out when the delivery arrives damaged, and there's no insurance documentation.*
>
> *After ColdGuard: breach contained in under 30 seconds. Cargo quarantined before delivery. Client informed proactively. Insurance claim filed automatically. Replacement en route.*
>
> *That's the difference between losing 24 million rupees — and saving it."*

### Actions (what to show)
1. **Incident Report screen** — full summary of the breach and response
2. Before/After comparison cards:
   | | Before | After |
   |---|---|---|
   | Response time | 30-60 minutes | < 30 seconds |
   | Cargo status | Delivered damaged | Quarantined safely |
   | Client notification | After complaint | Proactive + insurance |
   | Financial recovery | Manual claim (weeks) | Auto-filed (instant) |
3. Metric cards with animated counters:
   - **Response time:** 8.4 seconds
   - **Actions executed:** 6
   - **Stakeholders notified:** 4
   - **Financial exposure protected:** PKR 24,000,000

### Visual Notes
- The before/after contrast is your persuasion moment — make it clear
- If the app has animated counters, let them complete
- This is where judges should think "wow, this actually solves a real problem"

---

## Shot 7 — Closing

| | |
|---|---|
| **Time** | 3:10 – 3:30 (20 seconds) |
| **Screen** | Dashboard — updated state |
| **Laptop** | Black/title card |

### Narration

> *"ColdGuard — autonomous cold chain protection, powered by Google Antigravity and Gemini.*
>
> *Built in 7 days. Ready for the real world."*

### Actions (what to show)
1. Navigate back to the **dashboard**
2. Show TRK-004 now displaying **QUARANTINED** status (orange/grey card instead of red)
3. All other trucks still green — fleet is healthy
4. Hold for 3 seconds on the dashboard
5. Fade to black or team credits screen

### Visual Notes
- End on a calm, resolved dashboard — the system handled it
- If possible, show a subtle animation (like TRK-004 card fading from red to grey)
- Don't add any new information — just let the resolution speak

---

## Total Runtime Breakdown

```
Shot 1:  Problem Intro      0:00 - 0:20    (20s)
Shot 2:  Normal Dashboard    0:20 - 0:50    (30s)
Shot 3:  Breach Alert        0:50 - 1:20    (30s)
Shot 4:  Agent Pipeline      1:20 - 2:10    (50s)  ← Hero shot
Shot 5:  Actions Executing   2:10 - 2:40    (30s)
Shot 6:  Before/After        2:40 - 3:10    (30s)
Shot 7:  Closing             3:10 - 3:30    (20s)
─────────────────────────────────────────────────
TOTAL                                       3:30
```

---

## Recording Tips

### Equipment
- **Phone recording:** Use a tripod or gimbal — no shaky footage
- **Laptop recording:** OBS Studio (free) or built-in screen recorder
- **Microphone:** Any decent mic — even earphone mic is fine if the room is quiet
- **Lighting:** Face a window or use a desk lamp — avoid backlight

### Recording Strategy
1. **Record screen and narration separately** if possible
   - Screen record the demo flow silently
   - Record narration as a voiceover track
   - Combine in editing — much easier to fix mistakes
2. **Do 2-3 full runs** before the final recording
3. **Keep a backup of the screen recording** before editing

### Editing
- **DaVinci Resolve** (free, professional) or **CapCut** (free, easier)
- Add **captions/subtitles** for each shot — judges may watch without sound
- Add a **lower-third** showing "Agent 1: Assessment" etc. during Shot 4
- Use **fade transitions** between shots — no fancy effects
- Add **background music** (subtle, tech/ambient) — YouTube Audio Library has free options

### Export Settings
- **Format:** MP4 (H.264)
- **Resolution:** 1920x1080 (1080p)
- **Frame rate:** 30fps
- **File size:** Under 500MB
- **Filename:** `ColdGuard_Demo_Video_Final.mp4`

---

## Fallback Plan

If something breaks during recording:

| Problem | Fallback |
|---|---|
| Backend won't start | Use **Demo Mode** in Flutter app — works fully offline |
| Agent pipeline fails | Demo Mode shows pre-recorded agent trace data |
| Firebase is down | Local JSON fallback in the app |
| Phone dies | Use Android emulator on laptop with screen recording |
| Narration is bad | Record a clean voiceover separately and sync in editing |
| Time exceeds 5 min | Cut Shot 5 (actions) shorter — Shot 4 is the priority |

---

## Key Phrases for Judges

Work these into the narration naturally:

- **"Powered by Google Antigravity"** — mention at least twice (Shot 4, Shot 7)
- **"Gemini API"** — mention once during agent explanation
- **"Autonomous — no human in the loop"** — the key differentiator
- **"Under 30 seconds"** — the speed metric that impresses
- **"4 agents, 6 actions"** — concrete numbers
- **"24 million rupees protected"** — financial impact

---

*Last updated: May 15, 2026*
*Document owner: Member 3 (Demo + Documentation)*
