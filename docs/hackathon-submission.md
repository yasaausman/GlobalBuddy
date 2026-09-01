# Globalदोस्त — ISSS Document Pipeline

**DevNetwork [API + Cloud + AI] Hackathon 2026 · submission write-up**
Tracks entered: **Xano · Nutrient · Foxit · Doctavian · SerpApi** (one codebase, five submissions)

> **Status (1 Sep 2026).** The pipeline runs end-to-end in mock mode with zero keys. **Two vendors are
> wired live in the working agent flow — SerpApi (policy check) and Foxit (eSign).** **Two more are
> verified against their real APIs standalone — Nutrient (extraction) and Doctavian (generation).**
> Every claim below is marked **LIVE**, **PROVEN** (real API call verified, not yet wired into the Xano
> flow), or **MOCK/DEFERRED**. Nothing is fabricated. Video links are added after recording (§Videos).

---

## One-line pitch

> **Terra Dotta makes an advisor retype your I-20. We extract it, escalate only what the model isn't
> sure about, check the rules that changed last month, and get it signed — in one pass.**

---

## Why now — the market case

Lead with dates and numbers, not adjectives.

- **16 July 2026 — five weeks before this hackathon — DHS finalized a rule that eliminates "Duration
  of Status" (D/S) for F-1 and J-1 nonimmigrants**, replacing it with a fixed admission period **tied
  to the Form I-20**, and cutting the post-completion OPT grace period from **60 days to 30 days**.
- Consequence: the I-20 stopped being paperwork and became **the document that determines legal
  status**. A wrong field on it is now a status problem, not a typo.
- Related, all current as of 2026: OPT is officially 90–120 days but **6–10 month I-765 delays** are
  reported; the I-765 fee rose to **$1,780**; SEVIS reporting tightened. **Every static template
  describing F-1 status, OPT timelines, or fees became wrong in July 2026.**

This is why a live policy check is not a feature but the only correct way to build this now — and why
**SerpApi is load-bearing, not decorative**.

### The incumbent we rebuild

**Terra Dotta ISSS** (plus **Sunapsis / iStart**), reported on **700+ universities and colleges**. Its
workflow: a student uploads a scanned I-20, **a staff member reads the scan and retypes every field**,
then it goes back for correction or forward for signature (Terra Dotta already integrates DocuSign).

**Honest positioning:** the incumbent already has upload and already has eSign. **eSign is not our
differentiator.** Ours is **the middle** — machine extraction with per-field confidence, a calibrated
escalation rule that routes only genuinely uncertain fields to a human (with a citation to the exact
source region), and a live policy check that catches an out-of-date template. The defensible claim:
_staff retype every field today; we escalate only the fraction that need a human._

### Market size (Feasibility)

The **Student Information System market is ~$17.7B in 2026, ~14.6% CAGR** toward ~$35B by 2031, higher
education at ~58% of revenue. ISSS compliance software is a specialized segment whose growth driver —
heightened compliance requirements — is exactly the July 2026 rule above.

---

## Architecture (one system, two front doors)

```
                          ┌───────────────────────────────────────────────┐
   Student  ────upload───▶│  XANO  (system of record: auth, tables,        │
   /documents             │  gates, branch logic, the runtime AI Agent)    │
                          │                                                │
   Advisor  ───review────▶│  extract → confidence gate → human review →    │
   /advisor               │  generate → SerpApi policy check → eSign        │
                          └───────────────┬────────────────────────────────┘
                                          │ (SSE chat, Markdown graph only)
                          ┌───────────────▼───────────────┐
                          │  FastAPI sidecar (stateless)   │
                          └────────────────────────────────┘
```

- **Xano** owns auth, the pipeline tables + `vendor_fixtures`, every confidence gate and form branch as
  XanoScript function stacks, and **the document agent runs as a Xano Agent** (`ai.agent.run`) with
  native run/step/tool-call tracing.
- **FastAPI** is a stateless sidecar (Markdown knowledge graph, AI plan/bridge, SSE chat).
- **Frontend** React + Vite; pipeline surfaces are `/documents` (student) and `/advisor` (staff).
- **Mock-first:** the entire flow runs with zero vendor keys. Vendor keys live in **Xano environment
  variables**; a per-vendor `*_MODE=live` flag (`SERPAPI_MODE`, `FOXIT_MODE`, …) flips each on.

---

## Track write-ups

### Xano — _"build a better version of a business app you use today, with AI"_ · **LIVE**

**Software replaced:** Terra Dotta ISSS / Sunapsis (700+ universities). **Why:** the incumbent makes a
human retype every field of a status-determining document; we escalate only the uncertain fraction.

**How Xano is used, meaningfully:** Xano is the backend, not a database bolted onto something else.
Auth, the pipeline tables, and **every gate and branch are XanoScript function stacks** — the
confidence threshold, the server-side generation gate, the 4-way form-variant resolution, the signature
step. **The document agent itself is a Xano Agent** invoked via `ai.agent.run`, runs recorded in
`agent_runs`. The advisor queue (`/advisor`) is the SaaS-rebuild proof: reviewer attribution, a
per-submission audit trail, and a machine-vs-human "time saved" bar.

**Build story (required):**
- **Replaced:** the Terra Dotta / Sunapsis manual-retype ISSS document workflow.
- **AI tools used:** **XanoScript + the Xano CLI + Claude Code** (with the Xano Developer MCP). The
  backend is authored as text, `xano pull`ed into `xano/` in the repo, and reviewed/diffed like any
  code — which is what makes a no-code backend actually reviewable. Every live vendor call in this
  submission is an `api.request` function-stack block deployed via the CLI and verified against the
  live workspace.
- **What would have taken significantly longer without AI + Xano:** authoring the full function-stack
  backend (auth parity + 10 tables + gates + branches + a runtime agent + four external API
  integrations) by hand. AI-assisted XanoScript authoring plus Xano's managed auth/agent runtime
  compressed that dramatically.
- **A real constraint we hit and documented:** path-parameter routes 404 at runtime on this
  workspace/tier despite parsing and appearing in Swagger; we moved every identifier into the request
  body. Documented so it isn't rediscovered at cost.

### SerpApi — live data that changes agent behavior · **LIVE**

Three lookups run against SerpApi's live Google engine: processing time, school ISSS requirements, and
**policy changes that force a field back to human review**. The third is the point: for the policy-change
query the **real DHS "Establishing a Fixed Time Period of Admission" final rule** is the top organic
result (`studyinthestates.dhs.gov`), and we cite its title/link/snippet. A detected change **forces
`program_end_date` back to `needs_review` once** (guarded by an audit event so re-checks don't loop),
and the agent then **correctly refuses to sign**.

**Verified live, end to end:** the full agent run — plain prompt → refuse to generate (fields need
review) → human confirms → generate → **live SerpApi** catches the DHS rule → force re-review → **agent
refuses to sign** → human resolves → sign. The other two lookups return real government sources too
(USCIS `egov.uscis.gov`; the actual University of Illinois ISSS SSN page). This is live search data
changing agent _behavior_, not just page content — every template written before 16 July 2026 generates
a wrong document today, and the live check is what catches it. (`Vendor/serpapi_lookup`, gated on
`SERPAPI_MODE=live`.)

### Foxit — the agent boundary · **LIVE (eSign + agent)**

**Requirement 1 — _"an agent that starts from a plain prompt and ends with a signed document"_ — LIVE.**
The Xano Agent drives review → generate → policy-check → sign from a plain instruction, and at the end
it makes a **real Foxit eSign call**.

**The centerpiece — the agent cannot self-approve — VERIFIED LIVE.** `agent_generate_form` calls the
shared `Pipeline/generate`, which throws `accessdenied` (403) while any field is `needs_review`. From a
plain prompt the agent calls `agent_review_status`, sees pending fields, **refuses to generate, and
names every pending field** — captured in the agent trace. Automation drafts and routes; a person
reviews and signs, enforced in the backend, not just the UI.

**Requirement 3 — call eSign directly — LIVE.** `Vendor/foxit_send` (gated on `FOXIT_MODE=live`) creates
a **real Foxit eSign envelope** via `POST https://na1.fusion.foxit.com/esign/api/v1/folders/createfolder`
and records the real folder id — verified through the full agent flow. **A correction we earned the hard
way:** the Foxit *developer portal* (developer-api.foxit.com) **unifies PDF Services and eSign under one
credential** — eSign authenticates with the **same `client_id`/`client_secret` headers** as PDF
Services, *not* the classic standalone `na1.foxitesign.foxit.com` OAuth2 `client_credentials` flow (that
endpoint returns `invalid_client` for these creds). We say this explicitly because it's the kind of
"read past the docs" detail the track rewards.

**Requirement 2 — PDF Services for packet assembly — auth confirmed, assembly deferred.** PDF Services
authenticates from the pipeline (header auth against `na1.fusion.foxit.com/pdf-services/api/…`,
past-auth verified). The ≥4-tool assembly (convert, merge with the source I-20 page, stamp audit ID +
"verified as of", flatten) is not yet built — it needs real input PDFs flowing through the pipeline (see
Honest limitations). The eSign call currently signs a hosted sample PDF; swapping in the assembled
packet URL is a one-line change once that document flow exists.

### Nutrient — extraction + the confidence gate · **PROVEN (real API), pipeline runs mock**

**Verified against the real API (30 Aug 2026).** `POST https://api.nutrient.io/extraction/extract`
(Bearer auth; multipart `file` + `instructions={"schema":…}`) on a synthetic filled I-20 returned **all
10 requested fields correctly, each with confidence 0.95, a match label (`id_match`), a page number,
and bounding-box citations** (`source_bboxes`) pointing at the exact source region — 1 page, ~3.4s.
Evidence committed in [`assets/nutrient-demo/`](../assets/nutrient-demo/) (the synthetic I-20, the JSON
schema, and the real response).

**Required one-liner:** _DWS does the heavy lifting at the extraction boundary — it turns a scanned I-20
into typed, per-field data with a confidence signal and a citation back to the exact source region,
which is what makes selective human escalation possible instead of retyping everything._

**We read past the marketing page:** Nutrient documents its field confidence as a **relative,
uncalibrated signal, not a probability**, and recommends checking the match label and cited region and
retaining review for high-stakes fields. So our **always-review rule** (`sevis_id`, `program_end_date`,
`funding_amount` always go to a human regardless of confidence) is **the vendor's own recommendation,
not our opinion** — the UI never shows a bare confidence percentage without its match label and cited
region. On the mixed fixture the gate produces exactly 6/12 fields to review (3 always-review + 3 low
confidence) and 6/12 auto-accepted; every review action writes a `field_reviews` row plus a
`pipeline_events` row.

**Why the pipeline still runs mock:** the extraction API is **multipart file-only** (no URL input), and
Xano has no stored file to forward (real file upload to Xano is deferred). The mock fixtures faithfully
mirror the real API's shape — confirmed by the standalone call above — so the gate operates on realistic
data. Wiring it live needs the FastAPI sidecar (which handles multipart natively) or Xano file storage.

### Doctavian — branch-resolved generation · **PROVEN (real API), delivery pending**

`resolve_form_variant` picks one of **4 mutually-exclusive variants on visa status × funding source**,
each baking its variant into the generated document, and freezes a `field_snapshot` at generation time
so the output is reproducible — bound to Doctavian's conditional-rules/templating feature.

**Against the real demo API (`demo.api.doctavian.com`) we verified:** OAuth auth (Microsoft-identity,
Bearer), **template upload**, **data-source upload**, and the **`document/generate`** call processing the
template + data. The remaining gap is delivery: the demo account's cloud-storage target
(Google Drive under Google auth; standard storage under Microsoft auth) plus Doctavian's full
solution/template registration workflow — vendor-side setup that isn't a code issue on our end. The
pipeline uses the mock `doctavian_generate` for the end-to-end flow; the real generation call is
demonstrated directly.

---

## Setup — verified from a clean clone (mock mode, no vendor keys)

```bash
git clone https://github.com/yasaausman/GlobalBuddy.git
cd GlobalBuddy

# Frontend (this alone runs the whole document pipeline in mock mode)
cd frontend && npm install && npm run dev      # http://localhost:5173

# Optional backend sidecar (only for plan/chat/graph, not the pipeline) — Python 3.12
cd ../backend && python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && uvicorn app.main:app --reload   # :8000
```

- **No env file required** — the Xano workspace defaults are baked into the frontend, so
  `/documents` and `/advisor` work out of the box in mock mode. `frontend/.env.example` and
  `backend/.env.example` document every optional/vendor variable.
- **Test accounts (Xano, live workspace):** student `m18-test@example.com` / `TestPass123`;
  advisor `advisor@example.com` / `TestPass123`.
- **No secrets in the repo** — verified across the working tree and full git history; all vendor keys
  live in Xano environment variables, never committed.

---

## Videos

| Cut | Length | Status | Link |
|---|---|---|---|
| **Main** (Xano · Nutrient · Doctavian · SerpApi) | 2–4 min | _not recorded_ | _[pending]_ |
| **Foxit** | 1–3 min | _not recorded_ | _[pending]_ |

Storyboards / shot lists: see `docs/demo-runbook.md`. The main cut leads with the July 2026 DHS rule,
runs a document through review, and shows the **live SerpApi** check forcing re-review. The Foxit cut
shows the plain prompt → the agent **refusing to generate** → human review → the **real eSign envelope**.

---

## Honest limitations (stated on purpose)

- **The "files in Xano" gap.** Real multipart file upload to Xano is deferred, so the two vendors that
  need a document *file* in the pipeline — Nutrient extraction and Foxit PDF Services assembly — run on
  fixtures in the live flow, even though both are proven against their real APIs standalone.
- **Doctavian delivery** is pending vendor-side storage/workflow setup.
- **The Nutrient DWS Viewer** (confidence overlays on the rendered I-20) is not wired into the frontend;
  fields render as text with confidence bars + citations today.

## Honesty commitments

No fabricated testimonials, customers, pricing, benchmarks, or university partnerships. LIVE vs. PROVEN
vs. MOCK/DEFERRED is marked per track. The market facts (July 2026 DHS rule, OPT 60→30, I-765
fee/backlog, Terra Dotta 700+, SIS market size) are real and dated; the RPI-dropped-Terra-Dotta and
market-size figures should each carry a source link before final submission.
