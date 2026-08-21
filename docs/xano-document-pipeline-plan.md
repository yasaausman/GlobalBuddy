# Hackathon Build Plan — ISSS Document Pipeline on Xano

**Event:** DevNetwork [API + Cloud + AI] Hackathon 2026 · **Deadline: Thu 3 Sep 2026, 10:00am PDT**
**Tracks:** Xano · Nutrient · Foxit · Doctavian · SerpApi — one build, five submissions
**Confirmed:** pre-existing project work is **allowed**. Rules: *"Teams can … submit to as many
challenges as they want."*

---

## Contents

- §1 Market research — the problem, the incumbents, and why now
- §2 Sponsor technology briefing — verified capabilities, corrected assumptions
- §3 Architecture
- §4 Track compliance matrix
- §5–§9 Milestones 18–22, each with **What changes** and **Technologies used and how**
- §10 Calendar · §11 Cut line · §12 Risks · §13 Open items

---

## 1. Market research

### 1.1 The regulatory timing is unusually good

**On 16 July 2026 — five weeks before this hackathon — DHS finalised a rule that eliminates
"Duration of Status" (D/S) for F-1 and J-1 nonimmigrants**, replacing it with a fixed admission
period **tied to the Form I-20**, and cutting the post-completion OPT grace period from 60 days to
**30 days**.

Read that against what else is true right now:

| Fact | Source signal | Why it matters here |
|---|---|---|
| Admission period is now pinned to the I-20 | DHS rule, Jul 2026 | The I-20 stopped being paperwork and became the document that determines legal status. Getting a field wrong on it is now a status problem. |
| OPT grace period 60 → 30 days | DHS rule, Jul 2026 | Miss the window and you fall out of status. A form returned wrong twice can consume the entire window. |
| OPT officially 90–120 days; **6–10 month delays reported**, some I-765 pending over a year | USCIS backlog reporting, 2026 | Timeline guidance printed from a static template is wrong the day it's printed. |
| I-765 fee raised $1,685 → **$1,780** | USCIS, 2026 | Static fee text in a template is now incorrect. |
| Tighter SEVIS reporting; DSOs under pressure to keep records current in real time | 2026 compliance reporting | The staff side is the bottleneck, not the student side. |

**This is the single strongest argument in the submission.** Every static template describing F-1
status, OPT timelines, or fees became wrong in July 2026. A pipeline that checks live sources before
generating is not a feature — it is the only correct way to build this now. It is also the reason
SerpApi is load-bearing rather than decorative (§8.3).

### 1.2 The incumbent — what we're actually rebuilding

**Terra Dotta ISSS** (plus **Sunapsis** / **iStart**, the Indiana University-origin equivalent used
across the Big Ten). Terra Dotta reports **700+ universities and colleges** on its platform.

What the incumbent workflow looks like:
- Student uploads a scanned I-20 to a portal
- **A staff member reads the scan and retypes fields into a form**
- The form goes back for correction, or forward for signature
- Terra Dotta already integrates **DocuSign for I-20 signatures**

Vendor-acknowledged pain, from Terra Dotta's own positioning: international education offices face
**"high student-to-staff ratios and daunting rates of turnover while compliance expectations continue
to intensify."** They launched *SEVIS Coordinator as a Service* — selling humans — to absorb it.
Evidence of churn exists too: **RPI dropped Terra Dotta in December 2025** for a competitor.

⚠️ **Honest positioning, and it matters for judging.** The incumbent *already* has document upload
and *already* has eSign via DocuSign. **eSign is not our differentiator.** Ours is the middle:
machine extraction with per-field confidence, a calibrated escalation rule that routes only genuinely
uncertain fields to a human, and a live policy check that catches the template being out of date.
Claiming to have invented document upload would be false and a judge in this space would know it.
The claim we can defend: *staff retype every field today; we escalate only the ~20% that need a human,
with a citation to the exact region of the source document.*

### 1.3 Market size

The **Student Information System market is ~$17.7B in 2026, growing ~14.6% CAGR** toward $35B by 2031,
with **higher education at 58.2% of revenue**. ISSS compliance software is a specialised segment
inside that, and its growth driver — *"heightened compliance requirements"* — is exactly §1.1.

This lands directly on the hackathon's **Feasibility** criterion (*"Could this become a startup?"*),
and it was already `PLAN.md`'s stated monetization line: *"B2B: university international student
office SaaS."* The business model was written before the hackathon; the regulation caught up to it.

### 1.4 The pitch, in one line

> **Terra Dotta makes an advisor retype your I-20. We extract it, escalate only what the model isn't
> sure about, check the rules that changed last month, and get it signed — in one pass.**

---

## 2. Sponsor technology briefing

Everything below was verified against vendor documentation during planning. **Corrections to my
earlier assumptions are marked ⚠️** — several change the design.

### 2.1 Nutrient DWS — extraction + Viewer

| Verified | Detail |
|---|---|
| Endpoint | `/extract` maps a document to **your JSON Schema** and returns the requested fields |
| Returns per field | **confidence score, match label, page reference, bounding-box coordinates, and a citation back to the source region** |
| Spatial output | typed elements (paragraphs, tables, key-value regions, handwriting) with bboxes and reading order |
| Also available | official **`nutrient-dws-client-python`** library, and a **`nutrient-dws-mcp-server`** |
| Vendor's stated use case | *"flag low-confidence fields for human review … route exceptions to a review queue"* |

⚠️ **Nutrient explicitly documents field confidence as a *relative, uncalibrated signal, not a
probability***, and advises checking the **match label** and **cited page region**, and retaining
review for high-stakes fields.

Three consequences, all of which improve the build:
1. The always-review rule (§6.4) is **the vendor's own recommendation**, not our opinion. Quote it.
2. The review UI must pair every score with its **match label and cited region**. A bare `0.72` is not
   actionable; *"0.72, partial match, page 1 top-right"* is.
3. Never present the 0.85 threshold as a probability — not in the UI, not in the video.

### 2.2 Foxit — PDF Services (MCP) and eSign (REST), two separate systems

⚠️ **This is the correction that most changes the plan.** The track copy implies one product; it is two.

| | PDF Services | eSign |
|---|---|---|
| Access | **Open-source MCP server**, `github.com/foxitsoftware/foxit-pdf-api-mcp-server` — **30+ tools** (track copy says 40) | **Independent REST service, outside the MCP server** |
| Auth | `client_id` + `client_secret` as env vars, read before the MCP host launches | **OAuth2 `client_credentials`** against `https://na1.foxitesign.foxit.com/api/oauth2/access_token` |
| Runtime | Python 3.11+ with `uv`, or Node 18+ with `pnpm` | Called from the agent's own code-execution layer |
| Operations | convert (Office/image/HTML/URL ↔ PDF), OCR, merge, split, extract, compress, flatten, linearize, watermark, compare, form data import/export, document properties | envelope creation, signer routing, status webhooks |

This **explains the track requirement**: *"your agent has to call the Foxit eSign API directly, with
its own credentials"* — because eSign is genuinely not in the MCP server. Our design must therefore
have the agent hold **two separate credential sets** and use MCP for assembly but raw REST for
signing. Saying this out loud in the write-up demonstrates we read the architecture, which the track
explicitly rewards (*"build it your way and defend the choice"*).

Foxit also ships a **DocGen API**, which overlaps Doctavian. We use Doctavian for generation — that's
a separate track and a separate prize.

### 2.3 Xano — Q2 2026 changed the development model

⚠️ **My earlier "Xano isn't diffable, two devs will collide silently" risk is obsolete.**

| Feature | Status | Impact on this build |
|---|---|---|
| **XanoScript GA** | Q2 2026 | The backend is now **text**. It diffs, it reviews, it lives in the repo. |
| **Xano CLI** | GA since April 2026 | **Push and pull an entire workspace as XanoScript**, work from your own IDE, **integrates with Git**, RBAC-enforced with dry-run previews. Explicitly supports **Claude Code**, Cursor, Copilot, Codex. |
| **Sandbox environments** | Q2 2026 | Ephemeral env; push changes, review visually, promote to a branch only after validation. |
| **Error Logs Dashboard** | **Available on every plan** | Errors grouped by signature with New/Regression/Ignored/Fixed states. Free observability for the demo. |
| **Developer MCP** | Q2 2026 | Makes Claude Code fluent in XanoScript. |
| **Xano MCP Server** | ⚠️ **"experimental and under active development"**; docs warn use with automation **"may result in data loss, corruption, or deletion"** | **Do not make it load-bearing.** Use the **CLI** for the build. |

**Two decisions follow:**
1. **The Xano backend is version-controlled in this repo as XanoScript**, pulled via the CLI into
   `xano/`. Two devs work in branches and merge normally. The collision risk is gone, and the Xano
   portion of the build becomes reviewable like any other code.
2. **Claude Code + Xano CLI + Developer MCP is literally the "build story"** the Xano track requires
   (*"what would have taken significantly longer without AI + Xano"*). We are not inventing that
   narrative — it's the actual workflow.

⚠️ **Still tier-gated (§5.4):** background tasks are capped on lower plans; the free plan carries API
rate limits paid tiers drop. Confirm on day 1.

#### Xano Agents — confirmed, and it changes the design

⚠️ **Corrected: "Xano Agent" is two different products, and both are real.** Verified on Xano's own
site:

| | **Xano Agent** (singular) | **Xano Agents** (the runtime feature) |
|---|---|---|
| What | A **dev assistant** that builds, modifies, and debugs your backend | *"LLM-powered entities that can observe, reason, and act"* |
| Where it runs | Design time, via XanoScript + Developer MCP | **Runtime**, inside any Function Stack |
| Invoked by | You, while building | The **`Call AI Agent`** function, with an arguments object |

**Xano Agents** (runtime) verified capabilities:

- *"configurable connections to Large Language Models capable of choosing the appropriate tool"*;
  once defined, an Agent is *"available in any Function Stack across your workspace"*
- Two documented shapes: **Human Interactive Agents** (natural-language interface) and
  **Workflow Embedded Agents** (backend logic, fuzzy reasoning on edge cases)
- Tools can be: **Custom Functions, internal or external APIs, Xano Database reads/writes, external
  databases, and — critically — *"invoke your remote MCP Tools"***
- LLMs: **OpenAI, Anthropic, and more**, plus **free Gemini credits** to start
- Triggered by *"APIs, webhooks, or system events"*; schedulable and chainable
- **Observability:** a dashboard tracking *"every run, step, and tool call"*, plus
  **OpenTelemetry for AI agents** exporting traces to LangSmith, Langfuse, or Braintrust

**Consequence: the document agent moves into Xano (§6.2).** MCP tool invocation means the Foxit PDF
Services MCP server is reachable from a Xano Agent, and a Custom Function can perform the Foxit eSign
OAuth2 exchange. This turns the Xano submission from *"we used Xano as a database with API endpoints"*
into *"the agent itself is a Xano Agent, with Xano's own run tracing"* — a substantially stronger
answer to *"meaningful backend."*

⚠️ **Streaming is not documented** for Xano Agents. The agent trace UI therefore **polls `agent_runs`**
rather than using SSE (§7.2). Acceptable — polling is already the proven pattern in this codebase
(`NotificationBell.jsx`). The sidecar agent stays specified as the fallback (§6.2).

### 2.4 Doctavian — generation + templating

| Verified | Detail |
|---|---|
| Positioning | *"intelligent document operating platform"* — create, sign, manage |
| Generation | *"turning templates and data into finished PDFs, DOCX, XLSX, and more"* |
| Data binding | *"Pull data from several systems at once and merge it into your templates automatically"* |
| **Conditional logic** | *"several formats using advanced templates and **conditional rules**"* — this is what our 4-variant branch binds to |
| Auth | OAuth (Postman collection ships with *"OAuth login built in"*) |
| Docs | `developers.doctavian.com/openapi/latest` + Postman collection |

⚠️ **Endpoint paths and request-body shapes could not be verified** — the reference renders
client-side. **Day-1 task:** import their Postman collection and pin the real shapes before writing
the mock fixture. This is the least-verified vendor in the plan; the mock-first design (§6.8) means it
cannot block anything, but the fixture shape is a guess until someone opens Postman.

Doctavian *also* offers signatures. We deliberately use **Foxit** for signing because it's a separate
track and prize; the write-ups should note the choice was deliberate, not accidental.

### 2.5 SerpApi

Google vertical coverage: **Search, News, Scholar, Maps, Images, Jobs, Shopping**, plus **AI Overviews
parsed with citation extraction**. Structured JSON, ~2.5s average response. A
`serpapi-search-tools` Python package exists for agent use.

**AI Overviews with citations is the right endpoint for §8.3** — policy questions are exactly what
Google surfaces an AI Overview for, and citation extraction gives us linkable sources to render, which
is mandatory for anything a student might act on.

---

## 3. Architecture

Xano is the **system of record**: auth, all pipeline state, every gate, all workflow logic. Two things
cannot become Xano function stacks and the plan is honest about it:

| Holdout | Why |
|---|---|
| `MarkdownGraphService` + `data/graph/**` | Hundreds of Markdown files traversed in-process. Porting discards the authoring workflow `PLAN.md` → *Notes & Decisions* commits to. |
| SSE chat (`/v1/chat/stream`) | Xano's External API Request is request/response; it cannot proxy a token stream to the browser. The **document agent is no longer a holdout** — it moved into Xano Agents (§2.3, §6.2). |

**FastAPI survives as a stateless sidecar** — no database handle, no user data.

```
Browser ─────────► Xano   auth · pipeline state · gates · workflow
   │                 │
   │                 ├─► Xano Agent (runtime)   the document agent, 8 tools
   │                 │      ├─► Xano Custom Functions + DB      (state, gates)
   │                 │      ├─► Foxit PDF Services   via remote MCP tools
   │                 │      └─► Foxit eSign         Custom Fn, OAuth2 client_credentials
   │                 │
   │                 ├─► Nutrient /extract · Doctavian generate · SerpApi
   │                 └─► FastAPI sidecar   graph · plan/bridge
   │
   └───────────────► FastAPI sidecar   SSE chat only
```

**The contract principle that de-risks everything:** Xano endpoints keep the existing FastAPI `/v1`
paths and response shapes byte for byte. Every model in `backend/app/models/schemas.py` is the
acceptance criterion for its Xano counterpart, so the frontend cutover is a base-URL change plus an
auth swap — not a rewrite of 10 pages and 13 components.

---

## 4. Track compliance matrix

Check before every commit. A requirement with no implementation column is a lost prize.

| Track | Requirement (verbatim) | Satisfied by |
|---|---|---|
| **Xano** $2.5k | *"must use Xano as the backend in a meaningful way"* | Auth + 9 pipeline tables + every gate and branch as XanoScript function stacks (§5, §6) — **and the agent itself is a Xano Agent** with Xano-native run tracing (§6.2) |
| **Xano** | *"Pick a business application you use today and build a better version with AI"* | Terra Dotta/Sunapsis rebuild (§1.2) + advisor queue (§7.3) |
| **Xano** | Build story: software replaced, why, AI tools used, duration, what would take longer without AI+Xano | §8.2 — and the answer is real: XanoScript + CLI + Claude Code (§2.3) |
| **Nutrient** $1.5k | *"DWS — the API, an SDK, or the Viewer — for at least one core document operation, meaningfully"* | `/extract` with a custom I-20 schema **+** DWS Viewer as the review surface — two core operations (§6.3, §7.2) |
| **Nutrient** | *"pull the data out, judge how confident you are, bring a human in exactly where it matters, keep a record of every step"* | §6.3 → §6.4 gate → `field_reviews` + `pipeline_events` |
| **Foxit** $1k | *"agent that starts from a plain prompt and ends with a signed document"* | Document agent, §6.2 |
| **Foxit** | *"open-source MCP server wraps the Foxit PDF Services API"* | Registered as **remote MCP tools on the Xano Agent**; ≥4 tools in packet assembly (§6.5) |
| **Foxit** | *"call the Foxit eSign API directly, with its own credentials, and a person has to sign it"* | Separate OAuth2 client_credentials flow (§2.2, §6.7) |
| **Foxit** | Demo video **1–3 min** (shorter than others) | §8.1 — separate cut |
| **Doctavian** $1k | *"actually call Doctavian's generation API to shape a real document"* | 4-variant branch → generation call (§6.5) |
| **SerpApi** $3k | *"demonstrate how live search data improves the AI experience"* | Live policy check that **forces fields back to human review** (§6.6) — justified by the July 2026 rule change |
| **All** | Public repo + setup instructions · 2–4 min demo · name + one-line pitch | §8 |

---

## 5. Milestone 18 — Xano foundation

**Goal:** Xano owns auth and the demo path's state, version-controlled as XanoScript. ~2 person-days.

### 5.1 What changes

**Added**
- Xano workspace with 4 ported tables + auth
- `xano/` directory in this repo — the workspace pulled as XanoScript via the CLI, committed and diffed
- `scripts/migrate_neon_to_xano.py`
- `role` field (`student` | `advisor`) on the Xano `user` table
- `X-Sidecar-Key` middleware on FastAPI

**Modified**
- `frontend/src/api/client.js` — Xano base URL, plus a second axios instance for routes still on FastAPI
- `frontend/src/contexts/AuthContext.jsx` — import swap only
- `backend/app/main.py` — `_AuthMiddleware` replaced by sidecar-secret middleware

**Removed / deferred**
- `frontend/src/auth/neonAuth.js` → replaced by `xanoAuth.js` at the same interface
- LinkedIn OAuth rebuild — **cut** (blocked on LinkedIn review since M6, zero demo value)
- 8 of 12 tables — **deferred to M22** (§9)

**Explicitly unchanged:** all 10 pages, all 13 components, `tokenStore.js`, the axios interceptor.
That is the contract principle (§3) paying for itself.

### 5.2 Technologies used and how

| Technology | How it is used here |
|---|---|
| **Xano** | Database + auth + API groups. Endpoints mirror the FastAPI `/v1` paths exactly. |
| **XanoScript + Xano CLI** | The backend is authored as text and `xano pull`ed into `xano/` in this repo. Two devs work on branches and merge; dry-run previews before push. This is what makes a no-code backend reviewable. |
| **Claude Code + Xano Developer MCP** | AI-assisted authoring of function stacks in XanoScript. Also the honest answer to the Xano track's build-story question. |
| **FastAPI** | Demoted to a stateless sidecar. Keeps `graph`, `plan`, `bridge`, `chat` routers and gains the agent. |
| **React + Vite + axios** | Two axios instances during the transition — Xano for ported routes, FastAPI for the rest. |
| **Neon Postgres** | Still serves the 8 unported tables until M22. The app is dual-backed for two weeks, not broken. |

### 5.3 Tables ported now (4 of 12)

| Neon | Xano | Note |
|---|---|---|
| `user_profiles` | built-in `user` | keep `legacy_auth_user_id` for the port; `stage` enum retained; **add `role`** |
| `user_documents` | direct | pipeline completion writes `done` here (§6.7) |
| `plan_progress` | direct | on the demo path via the dashboard |
| `notifications` | direct | signature-complete reuses the M14 bell with zero client change |

Xano has no `CREATE TRIGGER` — the `set_updated_at()` trigger from `001` becomes an explicit
`updated_at = now` step in every edit stack. Easiest thing to forget; put it on the review checklist.

### 5.4 Xano tier — blocking, resolve before writing any function stack

Background tasks are tier-gated (capped on lower plans, unlimited on Pro); the free plan has API rate
limits paid tiers drop. §6.3's async extraction assumes they exist. If unavailable:

- **Fallback A (preferred):** extraction runs **synchronously inside the upload endpoint's function
  stack**, writing `extraction_runs` + `extracted_fields` before responding. The UI already polls, so
  the client is unchanged — the first poll simply returns `succeeded`. A single I-20 takes seconds.
- **Fallback B:** the sidecar extracts via `nutrient-dws-client-python` and POSTs results to Xano.
  Slightly weakens the "Xano owns the workflow" claim; use only if A fails.

### 5.5 CONFIRMED PLATFORM CONSTRAINT: path-parameter routes don't resolve

⚠️ **Discovered building M18, at real cost — read this before writing any endpoint with a `{param}`
in its path.** Path-parameter routes (e.g. `PUT /documents/{doc_type}`) parse and push without error,
appear correctly in Swagger with full docs, and are listed as registered endpoints — but every request
to them returns a 404 (`"Unable to locate request."`) from the live API gateway.

Isolated conclusively with a **100% UI-generated, UI-saved** test endpoint (`GET /test/{id}`, never
touched by CLI or hand-written code) that reproduced the identical 404. Two independent fix attempts
failed: removing a suspected stray leading slash (cleared an unrelated editor lint warning, not the
404), and a full re-save through the dashboard UI. This is a platform-level gap on this workspace/tier,
not a XanoScript syntax mistake.

**Binding design rule for M19/M20 and every future Xano endpoint: no path parameters, ever.** Every
identifier goes in the request body (POST/PUT/PATCH) or a query string parameter (GET/DELETE) instead.
The endpoint table in §6.9 is written with this rule already applied — do not add `{param}` paths back
without re-running the `/test/{id}` reproduction first, even if a plan/tier change seems to fix it.

Concretely, in M18 this meant rewriting:

| Broken (path param) | Working (body param) |
|---|---|
| `PUT /documents/{doc_type}` | `PUT /documents` with `doc_type` in the body |
| `PUT /progress/plan/{task_id}` | `PUT /progress/plan` with `task_id` in the body |
| `POST /notifications/{notification_id}/read` | `POST /notifications/read` with `notification_id` in the body |

### 5.6 Tasks

- [x] **Day 1:** request Nutrient, Doctavian, SerpApi, Foxit (PDF Services **and** eSign — separate) credentials
- [x] **Day 1:** confirm Xano tier; decide sync vs. background extraction — Essential plan, both Agents and Background Tasks confirmed available
- [ ] **Day 1:** import the Doctavian Postman collection; pin real endpoint shapes (§2.4)
- [x] **Day 1:** determine whether "Xano Agent" is a runtime tool-calling agent (§2.3) — confirmed: it's both a dev assistant and a runtime feature
- [x] Xano workspace + env vars; `xano pull` into `xano/`, committed
- [x] Port the 4 tables; add `role`; explicit `updated_at` in every edit stack
- [x] `/v1/auth/{signup,login,me,me/stage}` at byte-for-byte parity — verified live via curl: signup, me, forward stage-advance, and backward-stage rejection all confirmed correct
- [x] Port documents, progress, notifications API groups — verified live via curl, using the body-param rewrite from §5.5
- [x] Auth requirement per `PUBLIC_V1_PREFIXES` (`backend/app/auth.py:33`) — confirmed: unauthenticated `auth/me` correctly returns 401
- [ ] `X-Sidecar-Key` middleware + 5-min Xano-minted token for SSE/agent
- [ ] `scripts/migrate_neon_to_xano.py` with row-count parity assertions

---

## 6. Milestone 19 — The pipeline

**Goal:** A plain prompt ends in a signed, correct document, with a human gate wherever the model
isn't sure. Scope: **I-20 only**, one form output.

### 6.1 What changes

**Added — Xano**
- 9 tables: `document_uploads`, `extraction_runs`, `extracted_fields`, `field_reviews`,
  `form_generations`, `policy_lookups`, `signature_requests`, `agent_runs`, `pipeline_events`
- `vendor_fixtures` table + 3 seeded Nutrient scenarios
- 4 vendor custom functions with `mock`/`live` branches
- `apply_confidence_threshold` and `resolve_form_variant` custom functions
- 12 new endpoints (§6.9)

**Added — Xano Agents**
- A runtime **Xano Agent** with 8 tools (§6.2), invoked via `Call AI Agent`
- Remote MCP tool registration for the Foxit PDF Services MCP server
- `POST /v1/agent/documents` function stack

**Added — sidecar**
- `backend/tests/test_pipeline_contract.py`
- *(fallback only)* `backend/app/agents/document_agent.py` if §6.2's fallback triggers

**Modified**
- `backend/app/config.py` — vendor keys, modes, `CONFIDENCE_THRESHOLD`
- `user_documents` gains a write path from the pipeline (§6.7)

**Unchanged:** `NotificationBell.jsx` — the signature-complete notification reuses the M14 bell with
no client change at all.

### 6.2 The document agent — Foxit's core requirement

*"An agent that starts from a plain prompt and ends with a signed document."*

**Built as a Xano Agent** (§2.3) — a *Human Interactive Agent*, invoked from the
`POST /v1/agent/documents` function stack via the **`Call AI Agent`** function. Every run is recorded
in `agent_runs` and also appears in Xano's native run/step/tool-call dashboard.

| Tool | Implemented as | Reaches |
|---|---|---|
| `list_uploads()` | Xano Custom Function | DB |
| `get_extraction(upload_id)` | Xano Custom Function | DB |
| `list_review_items(upload_id)` | Xano Custom Function | DB |
| `request_human_review(upload_id)` | Xano Custom Function | hands off; **the agent STOPS and waits** |
| `check_policy(variant)` | Xano Custom Function | SerpApi (§6.6) |
| `generate_form(upload_id)` | Xano Custom Function | Doctavian (§6.5) |
| `assemble_packet(form_id)` | **remote MCP tools** | Foxit PDF Services, ≥4 tools (§6.5) |
| `send_for_signature(form_id, email)` | Xano Custom Function | **Foxit eSign, OAuth2 `client_credentials`** (§6.7) |

**The agent cannot self-approve.** `generate_form` hard-errors while any field is `needs_review`, so
the agent must call `request_human_review` and stop. That refusal, visible in the trace, is the
literal answer to *"Your Agent Shouldn't Sign That."* **Open the Foxit video with it.**

**Technologies and how:** Xano Agents for the tool-calling loop, with the LLM chosen in agent config
(Anthropic or OpenAI supported; **free Gemini credits** cover the build). **MCP** as the protocol for
Foxit PDF Services, invoked as remote MCP tools rather than hand-rolled HTTP. A Xano Custom Function
performs the Foxit eSign OAuth2 `client_credentials` exchange, because eSign sits outside MCP (§2.2).
Xano's **OpenTelemetry for AI agents** can export traces to LangSmith/Langfuse/Braintrust — optional,
but a strong thing to show on screen.

⚠️ **The one judgement call.** Foxit requires *"your agent has to call the Foxit eSign API directly,
with its own credentials."* Here the agent's own tool call performs the OAuth2 exchange with
eSign-specific credentials, separate from PDF Services and outside MCP. We read that as satisfying the
requirement — and the track explicitly invites you to *"build it your way and defend the choice."*
**Defend it explicitly in the Foxit write-up (§8.2)** rather than hoping nobody asks.

⚠️ **Fallback, if Xano Agents are tier-gated or the trace proves unworkable:** the agent moves back to
the sidecar as `backend/app/agents/document_agent.py` using the existing `services/ai` factory, MCP
client for PDF Services, and `httpx` for the eSign OAuth2 exchange. Same 8 tools, same gate. Decide by
**27 Aug** — after that the switch costs more than it saves.

### 6.3 Nutrient DWS — extraction

`POST /v1/documents/upload` (multipart) → `document_uploads`, returns immediately. Extraction (async
or sync per §5.4) → `extraction_runs` → `vendor_nutrient_extract` → one `extracted_fields` row per
field. `GET /v1/documents/{id}/extraction` polled at 2s.

**Define the I-20 JSON Schema** — Nutrient's `/extract` maps to *your* schema:
`sevis_id`, `school_name`, `school_code`, `program_start_date`, `program_end_date`,
`program_of_study`, `funding_source`, `funding_amount`, `student_full_name`, `date_of_birth`,
`country_of_citizenship`, `visa_status`.

Store per field: `confidence`, **`match_label`**, `page`, `bbox`, **`citation`** (§2.1).

### 6.4 The confidence gate — the heart of the Nutrient track

`apply_confidence_threshold`:
- `CONFIDENCE_THRESHOLD` default **0.85**; `>=` → `auto_accepted`, `<` → `needs_review`
- **Always `needs_review` regardless of confidence:** `sevis_id`, `program_end_date`,
  `funding_amount` — because **Nutrient documents confidence as uncalibrated and recommends retaining
  review for high-stakes fields** (§2.1). Post-July-2026, `program_end_date` *is* the admission period
  (§1.1), so it is the highest-stakes field on the document.

`POST /v1/documents/fields/{id}/review` → updates the field, **always** writes `field_reviews`, emits
`pipeline_events`. **Generation is rejected server-side in Xano** while any field is `needs_review` —
not merely a hidden button.

### 6.5 Doctavian generation → Foxit packet assembly

**Form:** SSN application support packet — the I-20-derived attestation an ISSS office signs off on.
Chosen because `DocumentTracker.jsx` already lists SSN as the checklist item gated on employment
authorisation, so the output lands in a tracker the product already has.

`resolve_form_variant`:

| `visa_status` | `funding_source` | variant |
|---|---|---|
| F-1 | assistantship | `f1_assistantship` |
| F-1 | self / sponsor | `f1_self_funded` |
| F-1 (OPT) | any | `f1_opt` |
| J-1 | any | `j1_sponsor` |

School drives header/ISSS-address substitution, not a fifth branch.

Flow: assert no `needs_review` → freeze `field_snapshot` (so later corrections can't retroactively
change what was signed) → resolve variant → **Doctavian generation API**, binding the branch to their
**conditional rules** feature (§2.4) → `form_generations`.

Then **Foxit PDF Services via MCP** assembles the real packet — ≥4 tools, which is what makes it
*"not a throwaway call"*:
1. **Convert** Doctavian output → PDF
2. **Merge** with the source I-20 page the fields were cited from
3. **Add header/footer** stamping the audit reference ID and the "verified as of" line from §6.6
4. **Flatten** so the packet can't be edited before signing
5. *(optional)* **Compress** / linearize for archival

### 6.6 SerpApi — load-bearing, and §1.1 is why

Three lookups via `vendor_serpapi_lookup`, stored in `policy_lookups`:

1. **Current processing time** for the variant → written into the packet and used by the agent to tell
   the student what to expect. Static templates say 90–120 days; reality in 2026 is 6–10 months.
2. **School-specific ISSS requirements** (`"{school_name} ISSS SSN support letter requirements"`) →
   surfaces what the generic template can't know.
3. **Recent policy changes** for the visa status → **if a change is detected, the agent raises a
   warning and forces the affected field back to human review before generation.**

Lookup 3 wins the track, and §1.1 is the proof it isn't contrived: the D/S rule changed on 16 July
2026, the OPT grace period halved, and the I-765 fee moved. **Any template written before that date
generates a wrong document today.** Demo it against a real, dated change.

**Technologies and how:** SerpApi's **AI Overviews endpoint with citation extraction** — policy
questions are exactly what Google answers with an AI Overview, and the citations give us linkable
sources, which is mandatory for anything a student will act on.

⚠️ Search results are third-party content. Render them as quoted, linked sources. They may **raise a
review flag**; they must **never** write a form field value directly.

### 6.7 Foxit eSign

`send_for_signature` → **OAuth2 `client_credentials`** token from
`na1.foxitesign.foxit.com/api/oauth2/access_token` → create envelope with the assembled packet, one
signer (the authenticated student), one signature field → `signature_requests` (`created`→`sent`).
**A real person signs.**

`POST /v1/webhooks/foxit` — public Xano endpoint, **HMAC-verified** against `FOXIT_WEBHOOK_SECRET`
before touching a row. On `signed`: store the file, write `pipeline_events`, create a `notifications`
row (M14 bell picks it up unchanged), and set `user_documents.status = 'done'` — closing the loop into
the tracker that already exists.

`FOXIT_MODE=mock` exposes a gated simulate endpoint so the flow demos without a public tunnel.

### 6.8 Mock-first vendor pattern

No `factory.py` in Xano, so replicate the intent of `backend/app/services/ai/factory.py` as a
convention: `VENDOR_MODE` = `mock` | `live` with per-vendor overrides. Each `vendor_*` custom function
opens with a Conditional — `mock` reads from `vendor_fixtures` (after ~800ms `Sleep`, so loading
states are exercised honestly); `live` calls the API and normalises to the identical shape.
**No function stack ever calls a vendor URL directly.**

Seed three Nutrient scenarios: all-high-confidence, **mixed (2–3 below threshold)**, hard failure.
The mixed one is the demo.

> Mock mode protects the schedule, but **every track needs one real call.** Keys were requested day 1
> (§5.6); switch to `live` and re-record before submitting.

### 6.9 Endpoints

⚠️ **No path parameters** — every identifier is a body field (POST/PUT/PATCH) or query string param
(GET/DELETE), per the confirmed platform constraint in §5.5.

```
POST   /v1/documents/upload                            GET  /v1/forms                        ?form_id=
GET    /v1/documents                                    ?upload_id=            POST /v1/forms/policy-check          {form_id, ...}
GET    /v1/documents/extraction                         ?upload_id=            POST /v1/forms/sign                  {form_id, ...}
GET    /v1/documents/review                              ?upload_id=            GET  /v1/forms/signature              ?form_id=
POST   /v1/documents/fields/review                       {field_id, ...}        GET  /v1/documents/audit              ?upload_id=
POST   /v1/documents/generate                             {upload_id}            GET  /v1/advisor/queue                (role=advisor)
POST   /v1/webhooks/foxit   (public, HMAC, no path param)                      POST /v1/agent/documents              (sidecar, SSE)
```

---

## 7. Milestone 20 — Frontend

### 7.1 What changes

**Added:** `pages/DocumentsPage.jsx`, `pages/AdvisorQueuePage.jsx`, and components
`PipelineStepper`, `DocumentUpload`, `ExtractionResults`, `AgentConsole`, `FormPreview`,
`SignatureStatus`. Routes `/documents` and `/advisor` in `App.jsx`.

**Modified:** `client.js` (Xano base + sidecar instance), `AuthContext.jsx` (import swap),
`DocumentTracker.jsx` (links `/documents` from the SSN item).

**Unchanged:** every other page and component. `gb-*` CSS classes, `Banner.jsx`, and the
loading/error conventions from `PlanPanel.jsx` are reused rather than re-invented.

### 7.2 Technologies used and how

| Technology | How |
|---|---|
| **Nutrient DWS Viewer** | Renders the **real I-20** with each field's **cited region** highlighted. Confidence + match label shown per field — never a bare percentage (§2.1). This is Nutrient core operation #2. |
| **Polling** | Xano Agents don't document streaming (§2.3), so `AgentConsole` polls `agent_runs` at 1s and renders steps as they land. Extraction status at 2s; signature status reuses the 30s pattern from `NotificationBell.jsx`. |
| **SSE (EventSource)** | Now only `/v1/chat/stream` on the sidecar — the one genuine streaming holdout. |
| **React Router** | Two new routes; `/advisor` gated on `user.role`. |
| **axios (2 instances)** | Xano for ported routes, FastAPI for the rest, until M22. |

**Design rule:** show the branch decision explicitly — *"F-1 + assistantship → `f1_assistantship`"*.
A form that silently picks a variant looks like a template; one that shows its reasoning looks like a
system.

### 7.3 Advisor queue — the SaaS-rebuild proof

`/advisor`, gated on `role=advisor`:
- Review queue, oldest first, with fields awaiting a human
- The same review component the student sees, with reviewer attribution
- Per-submission audit trail from `pipeline_events` + `field_reviews`
- **A "time saved" counter: fields auto-accepted vs. fields escalated**

That counter is the Terra Dotta comparison made numeric (§1.2) — *staff retype every field today; we
escalate ~20%* — and it feeds **Feasibility** directly. One screen, and it's the difference between
"a student tool" and "we rebuilt their software."

---

## 8. Milestone 21 — Submission package (2 full days)

### 8.1 Videos

| Cut | Length | Story |
|---|---|---|
| **Main** (Xano · Nutrient · Doctavian · SerpApi) | **2–4 min** | The July 2026 rule change → upload → confidence + citations in the DWS Viewer → advisor reviews the 3 escalated fields → SerpApi flags the policy change → branch resolves → packet assembled → signed |
| **Foxit** | **1–3 min** | Plain prompt → agent works → **agent refuses to generate and demands human review** → human reviews → PDF Services assembles via MCP → eSign called directly → a person signs. Cut to **Xano's agent run dashboard** showing every step and tool call — it evidences the refusal instead of just asserting it |

Record in `VENDOR_MODE=live`. Keep a mock-mode take as fallback if a sandbox is down on the day.

### 8.2 `docs/hackathon-submission.md`

- **Xano build story** (required): software replaced (Terra Dotta/Sunapsis, 700+ universities), why,
  AI tools used, duration, and *"what would have taken significantly longer without AI + Xano"* — the
  real answer is XanoScript + CLI + Claude Code (§2.3).
- **Nutrient:** the required one-liner on where DWS does the heavy lifting — plus the uncalibrated-
  confidence point (§2.1), which shows we read past the marketing page.
- **Foxit:** defend the boundary. Note that eSign sits **outside** the MCP server with its own OAuth2
  flow (§2.2) — that's why the agent calls it directly — and that PDF Services is reached as **remote
  MCP tools** while eSign is not. Argue the "directly" reading (§6.2) instead of leaving it implicit.
- **Doctavian:** the branch matrix, bound to their conditional-rules feature.
- **SerpApi:** how live data **changed agent behaviour**, anchored to the 16 July 2026 rule.
- Shared: one-line pitch (§1.4), architecture diagram, market framing (§1), and **setup instructions
  verified from a clean clone** — a judge who can't run it scores Progress low.

### 8.3 Repo hygiene

Public repo, `.env.example` covering every new key, README quickstart verified from a fresh clone,
`docs/demo-runbook.md` updated, `xano/` committed. **No credentials and no real student documents.**

---

## 9. Milestone 22 — Decommission (post-deadline)

Zero judging value before 3 Sep, so deliberately deferred. Port the remaining 8 tables; delete the 9
state-owning routers, `app/db/`, `backend/migrations/`, `app/auth.py`; strip Neon/Stack/Supabase
config; collapse the two axios instances; add `test_xano_contract.py`; update `render.yaml`, README,
and `docs/{DEPLOYMENT,architecture,api-spec,data-model}.md`; drop `@neondatabase/neon-js`.

---

## 10. Calendar — 19 Aug → 3 Sep

Dev A = platform & frontend. Dev B = pipeline & vendors. **Both work in XanoScript branches** (§2.3),
so the old "don't touch the same function stack" rule is replaced by ordinary git discipline.

| Dates | Dev A | Dev B |
|---|---|---|
| **Wed 19 – Fri 21 Aug** | All four §5.5 day-1 investigations. Xano workspace, `xano pull` into git, 4 tables, auth parity, `role` | 9 pipeline tables, `vendor_fixtures` + 3 Nutrient scenarios, 4 `vendor_*` functions (mock branch), **Doctavian Postman spike** |
| **Sat 22 – Wed 26 Aug** | Port 3 API groups; `migrate_neon_to_xano.py`; frontend auth swap + dual axios | I-20 JSON Schema → extraction → `apply_confidence_threshold` → review endpoints + `field_reviews`; `resolve_form_variant` + generate |
| **▲ Wed 26 Aug** | Existing app green on Xano | Mock pipeline: upload → generate, **gate enforced** |
| **Thu 27 – Sun 30 Aug** | `DocumentsPage`, `PipelineStepper`, upload UI, **DWS Viewer review surface**, `AgentConsole` polling `agent_runs` | **Xano Agent** + 8 tools via `Call AI Agent`; Foxit PDF Services as remote MCP tools; eSign OAuth2 Custom Function + webhook + mock simulate. **27 Aug: confirm Agents are usable on our tier or fall back to the sidecar** (§6.2) |
| **▲ Sun 30 Aug** | **Full flow end-to-end in mock mode** | SerpApi all 3 lookups incl. the review-forcing one |
| **Mon 31 Aug – Tue 1 Sep** | `AdvisorQueuePage`, `FormPreview`, `SignatureStatus`, audit view | Live-mode wiring for every key that arrived; `test_pipeline_contract.py` |
| **Wed 2 Sep** | Record both videos, write all 5 submissions, verify clean-clone setup — joint day | ← |
| **Thu 3 Sep** | **Submit before 10:00am PDT.** Do not plan to build. | — |

---

## 11. Cut line

If **30 Aug** arrives and the full flow isn't running, cut in this order:

1. **Advisor view** → the student reviews their own fields. Weakens the Xano rebuild claim, keeps four
   tracks whole.
2. **SerpApi lookups 1 and 2** → keep only lookup 3, the one that forces review.
3. **Foxit PDF Services down to 2 tools** (merge + flatten). Still not a throwaway call.
4. **Audit *view*** — the endpoint stays, the UI goes. Data is captured either way.

**Never cut:** the confidence gate, the agent's refusal to self-approve, the branch resolution, or a
real eSign call. Four separate track requirements; none can be narrated over in a video.

---

## 12. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Vendor sandbox approval doesn't arrive before 2 Sep | **High** | Requested day 1. Mock mode keeps the build moving; a missing key costs one track, not the submission. |
| **Doctavian's API shape is the least-verified thing in this plan** | **High** | Day-1 Postman spike (§2.4). Mock-first means it can't block, but the fixture is a guess until someone opens it. |
| 15 days, 2 people, backend migration + 5 integrations + an agent | **High** | Migration cut to 4 tables; decommission deferred; 26 Aug and 30 Aug checkpoints; cut line pre-agreed so nobody negotiates under pressure. |
| Xano tier lacks background tasks | Medium | §5.4 fallback A — synchronous extraction, no client change. |
| Foxit needs **two** credential sets and two auth models | Medium | §2.2 is now explicit. Budget an hour for the OAuth2 exchange specifically. |
| **Xano Agents may be tier-gated, and streaming is undocumented** | Medium | Trace UI polls `agent_runs` instead of SSE (§7.2). Sidecar agent stays specified as the fallback; **decide by 27 Aug** (§6.2). |
| **Foxit "directly" is a judgement call** once eSign is a Xano Custom Function | Medium | The agent's own tool call, eSign-specific credentials, outside MCP. Defend it explicitly in the write-up (§8.2) — the track invites the argument. |
| ~~Xano isn't diffable; devs collide silently~~ | **Resolved** | XanoScript GA + CLI + git (§2.3). |
| ~~Pre-existing project work may be disallowed~~ | **Resolved** | Confirmed allowed. Still frame write-ups around 17 Aug–3 Sep work and keep commits scoped `feat(m18)`…`feat(m21)`. |
| Two videos at different lengths get conflated | Low | Storyboard both 1 Sep, record 2 Sep. |
| Sidecar retains chat + agent — reads as "not really migrated" | Low | Documented decision (§3). The sidecar holds no state, and Foxit's rules require the agent to own the eSign call anyway. |

---

## 13. Open items — first 48 hours

- **Doctavian endpoints and request bodies** — Postman collection, day 1 (§2.4)
- **Xano tier** → sync vs. background extraction (§5.4)
- ~~**Is "Xano Agent" a runtime tool-calling agent?**~~ **Resolved: it is both products.** The dev
  assistant *and* a runtime tool-calling feature. The document agent now runs as a Xano Agent (§2.3,
  §6.2). Remaining sub-question: **which plan tier includes Agents**, and are there run limits?
- **Foxit sandbox webhooks** — supported, or is mock-simulate the demo route?
- **Synthetic I-20s only.** Never commit a real student's document to `vendor_fixtures` or the repo.
