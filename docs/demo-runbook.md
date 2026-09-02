# Globalदोस्त Demo Runbook

## 1. Demo Objective
Show a polished, low-friction arrival journey where graph evidence and AI reasoning are both visible and useful.

## 2. Recommended Scenario
- Origin: India
- Home city: Bengaluru
- Destination: Illinois Institute of Technology, Chicago
- Needs: banking, housing, community
- Optional context: South Indian, Hindu, vegetarian

## 3. Pre-Demo Checklist
1. Run backend and frontend locally.
2. Verify `/health` and provider health are reachable.
3. Verify graph-source health:
   - target: `/health/graph`
   - legacy during migration: `/health/neo4j`
4. Confirm one AI provider path is configured.
5. If demoing the target architecture, run Markdown graph validation before opening the app.

## 4. Live Demo Flow (5-7 Minutes)
1. **Landing + status**
   - Show Globalदोस्त brand, hero copy, and live status pills.
2. **Step 1: Profile**
   - Walk through wizard tabs and smart starter defaults.
   - Submit profile and highlight success banner.
3. **Step 2: AI Plan**
   - Generate plan.
   - Highlight best next action, week grouping, and task completion toggle.
   - Click "Why this matters culturally" on one step.
4. **Cultural Bridge**
   - Use quick chip such as `security deposit` and show explanation drawer.
5. **Step 3: Explore Graph**
   - Switch categories: People, Events, Food, Housing, Tasks, and later Groups.
   - Open one person profile modal and show contact actions.
   - Focus a card in graph, show shortest path and node detail panel.
   - Open map link/preview for one location.

## 5. Returning-User Variant
If `new_to_us=false` during profile setup:
- show that Step 2 is intentionally skipped
- proceed directly to Step 3 exploration

## 6. Key Talking Points
- The Markdown knowledge graph is the evidence engine for the MVP: editable, versioned, and easy to validate.
- Neon Auth/Postgres handles private accounts and persistence without spreading user data into graph files.
- AI plan and term explanations are provider-backed but safely fall back when needed.
- Product minimizes overwhelm by sequencing actions and surfacing human context.
- Neo4j remains a possible later upgrade, not a dependency for the MVP direction.

## 7. Fallback Path
If provider call fails or is slow:
- show deterministic plan/bridge fallback behavior
- continue demo through Explore Graph and map-backed local recommendations

If graph validation fails:
- fix Markdown frontmatter or broken links before demo
- use the legacy Neo4j adapter only if the Markdown migration is not ready yet

## 8. Demo Close Line
"You didn't come this far to figure it out alone."

---

# Hackathon submission — video scripts (2 presenters)

Two cuts. **Presenter A = "the story"** (narrates the problem, market, and *why*). **Presenter B = "the build"** (drives the screen, does the clicks, explains the tech). Record with `SERPAPI_MODE=live` and `FOXIT_MODE=live` set in Xano.

**Pre-flight (both videos):**
- Frontend running (`cd frontend && npm run dev`), open at `http://localhost:5173`.
- Test accounts: student `m18-test@example.com` / `TestPass123`; advisor `advisor@example.com` / `TestPass123`.
- Have two browser tabs ready: `/documents` (student) and `/advisor` (advisor).
- Have `assets/nutrient-demo/extraction-result.json` and the DHS rule page (`studyinthestates.dhs.gov`) open in spare tabs for cutaways.
- Do one dry run of the flow first (extraction rows and the agent are live).

## Video 1 — Main cut (Xano · Nutrient · Doctavian · SerpApi) · target 2:30–3:30

| # | Screen / action (B drives) | A — story | B — build |
|---|---|---|---|
| 1 | DHS rule page (`studyinthestates.dhs.gov` final rule) | "On July 16 2026, DHS tied an F-1 student's legal status to one form — the I-20 — and cut the OPT grace period in half. A wrong field is now a status problem, not a typo." | — |
| 2 | Terra Dotta screenshot / describe | "Today, 700+ universities run this on Terra Dotta, where a staff member **retypes every field** by hand. We rebuilt the middle." | — |
| 3 | `/documents`, sign in as student | "Meet the student side." | "This whole pipeline runs on **Xano** — auth, tables, every gate, and the AI agent are Xano function stacks." |
| 4 | Click **Upload I-20 & extract** (scenario: mixed) | "Upload the I-20…" | "Extraction returns each field with a **confidence score and a citation to the source region**." |
| 5 | Cutaway: `extraction-result.json` field table | "This is real **Nutrient** output on a real I-20 — every field with confidence and a bounding-box citation." | "0.95 confidence, `id_match`, page 1, source box — exactly what the gate needs." |
| 6 | Back to the extracted-fields list; point at green vs amber | "The model auto-accepts what it's sure of and **escalates only what it isn't** — plus always-review fields like SEVIS ID and program end date." | "6 of 12 flagged: 3 low-confidence, 3 always-review. That's Nutrient's own recommendation, not our opinion." |
| 7 | Open `/advisor` in the other tab | "The staff side — the SaaS rebuild." | "Reviewer attribution, per-submission queue, and this bar: **89% machine-cleared, 11% escalated** — the time-saved story, numeric." |
| 8 | Confirm the flagged fields | "The human resolves exactly the fields that needed judgment." | — |
| 9 | Back on `/documents`, click **Generate** | "Now generate the packet…" | "The 4-way branch resolves on visa status × funding — this is the **Doctavian** generation step (real generate call verified against their API)." |
| 10 | Click **Run policy check** | "But templates go stale. So before we finish, we check the live rules." | "This fires a **live SerpApi** search." |
| 11 | Point at the warning + the DHS source link | "SerpApi finds the **real DHS rule** — and the system pulls `program_end_date` **back to review**. Live data changed the workflow." | "Cited straight from `studyinthestates.dhs.gov`. The field is now re-flagged; signing is blocked." |
| 12 | Resolve the re-flagged field, then **Sign** | "The human confirms the current value, and only then does it get signed." | "Correctness over speed — enforced in the backend." |
| 13 | Close on the brand | "Staff retype every field today. We escalate only the fraction that need a human, check the rules that changed last month, and sign — in one pass." | — |

## Video 2 — Foxit cut (the agent that can't self-approve) · target 1:30–2:30

| # | Screen / action (B drives) | A — story | B — build |
|---|---|---|---|
| 1 | `/documents`, scroll to **AI Agent** box | "The Foxit challenge: an agent that starts from a plain prompt and ends at a real signature — with a human in the loop." | "This is a **Xano Agent** with tools; it drives the whole pipeline." |
| 2 | Upload + extract (so fields are pending), then type into the agent: *"Process my I-20 and send it for signature."* Run. | "Watch what a naive agent would do — and what ours does instead." | — |
| 3 | Agent trace appears — it calls `agent_review_status` then **stops** | "It **refuses**. It checked, saw fields still need a human, and named them." | "`agent_generate_form` calls the same server-side gate the UI uses — it throws 403 while anything is `needs_review`. **The agent literally cannot self-approve.**" |
| 4 | Human confirms the flagged fields | "So a person reviews…" | — |
| 5 | Run the agent again: *"All reviewed — generate, check policy, and sign."* | "…and now it proceeds." | "Generate → **live SerpApi** policy check → and if that forces a field back, it refuses again. Here it's clear." |
| 6 | Agent calls `agent_sign`; show "sent for signature" | "…and it ends at a **real Foxit eSign envelope**." | "`agent_sign` calls Foxit eSign directly — a real envelope id on our sandbox account. eSign is a **direct call**, separate from PDF Services." |
| 7 | (Optional) show the Foxit eSign dashboard with the new envelope | "A person still signs. Automation drafts and routes; a human decides." | — |
| 8 | Close | "Plain prompt in, real signature request out — and it will not skip the human." | — |

**Recording tips:** keep each cut tight; if a live call is slow on the day, the pre-flight dry run warms it. A mock-mode take (unset the `*_MODE` vars) is a safe fallback — the flow is visually identical.
