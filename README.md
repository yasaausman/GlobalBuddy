# Globalदोस्त

Globalदोस्त is a graph-powered support platform for international students arriving in US cities. The target MVP experience is a guided 3-step journey that turns profile context plus an Obsidian-style Markdown knowledge graph into practical next actions.

The repo still contains a legacy Neo4j adapter and Cypher seed packs. The active roadmap moves public city knowledge to Markdown files with YAML frontmatter and `[[wikilinks]]`, while private/dynamic user data moves to Neon Auth + Neon Postgres.

Motto: *You didn't come this far to figure it out alone.*

---

## 🏆 Hackathon build: the ISSS document pipeline

The current build focus (DevNetwork [API + Cloud + AI] Hackathon 2026) is an **AI document pipeline** that rebuilds the university ISSS workflow: **I-20 → signed SSN support packet**, with a human in the loop wherever the model is unsure. Full write-up: [`docs/hackathon-submission.md`](./docs/hackathon-submission.md).

**Backend of record is [Xano](https://xano.com)** (auth, tables, gates, branch logic, and the runtime AI agent); the FastAPI service below is a stateless sidecar. The pipeline runs **end-to-end in mock mode with zero vendor keys.**

### Run it (mock mode, no keys)
```bash
cd frontend && npm install && npm run dev      # http://localhost:5173
```
No `.env` needed — the Xano workspace defaults are baked in (see `frontend/.env.example`). The backend sidecar is only needed for the older plan/chat/graph features, not the pipeline.

- **Student pipeline:** open **`/documents`** → sign in → upload I-20 → review flagged fields → generate → policy check → sign.
- **Advisor queue:** open **`/advisor`** → the role-gated review queue with the machine-vs-human "time saved" bar.
- **Test accounts (Xano):** student `m18-test@example.com` / `TestPass123` · advisor `advisor@example.com` / `TestPass123`.

### Live vs mock
Everything runs on seeded fixtures by default. Two vendors are wired live in the flow (**SerpApi** policy check, **Foxit eSign**); **Nutrient** extraction and **Doctavian** generation are verified against their real APIs (see `assets/nutrient-demo/` and the write-up). Vendor keys live in **Xano environment variables**; a per-vendor `*_MODE=live` flag flips each on.

---

## What is live now

- **Step 1 - Profile setup wizard**
  - 3 sections: Personal Info, Origin and Context, Destination.
  - Smart starter defaults for a faster demo path.
  - Supports optional cultural context fields (`cultural_background`, `religion_or_observance`, `diet`) and social handles.
  - `new_to_us=false` is used to skip the plan step in the UI.

- **Step 2 - AI Plan (first 30 days)**
  - Calls `POST /v1/plan/generate` with session-backed evidence.
  - Week-grouped timeline, best next action, warning surface, and provider/fallback metadata.
  - Task completion syncs to Neon `plan_progress` for logged-in users, with browser local storage as the no-auth fallback.
  - Each plan step can focus related graph nodes.

- **Step 3 - Explore Knowledge Graph**
  - Category views: People, Events, Food, Housing, Tasks.
  - Person profile modal with one-click contact links (email/LinkedIn/Instagram/phone when available).
  - vis-network graph with filter chips, path highlighting, shortest-path breadcrumb, and fit/expand controls.
  - Node detail panel supports direct Maps open plus embedded map preview.

- **Cultural Bridge drawer**
  - Calls `POST /v1/bridge/explain` from custom term input or quick chips (`security deposit`, `credit score`, `SSN`).
  - Returns plain explanation, home-context analogy, common mistakes, and next actions.

- **System status checks**
  - UI probes `GET /health` and, after the Markdown migration, `GET /health/graph`.
  - Shows API live/offline state and graph-source health with retry.
  - Backend exposes `GET /health/db` for Neon Postgres connectivity.

## Backend stack

- FastAPI (`backend/app`)
- Markdown knowledge graph target: YAML frontmatter + `[[wikilinks]]` compiled into typed nodes/edges
- Neon Auth + Neon Postgres target for accounts, plan progress, chat, connections, content, and notifications
- Legacy Neo4j support remains optional until the Markdown graph engine replaces it
- AI provider abstraction:
  - `gemini` (default-recommended)
  - `rocketride_sdk`
  - `rocketride_http` (legacy compatibility)
  - `anthropic`
  - deterministic fallback when generation fails

## API surface

- `POST /v1/profile/match`
- `POST /v1/plan/generate`
- `POST /v1/bridge/explain`
- `GET /v1/graph/subgraph?session_id=...`
- `PATCH /v1/auth/me/stage` advances a logged-in user's journey stage (`newcomer` -> `settler` -> `local`)
- `GET /v1/auth/config`
- `GET /v1/auth/me`
- `GET /v1/progress/plan`
- `PUT /v1/progress/plan/{task_id}`
- `GET /v1/documents`
- `PUT /v1/documents/{doc_type}`
- `GET /health`
- `GET /health/graph` (target)
- `GET /health/db`
- `GET /health/neo4j` (legacy during migration)

## Environment variables

Copy `backend/.env.example` to `backend/.env`.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Neon pooled Postgres connection string |
| `DATABASE_URL_UNPOOLED` | Neon direct connection string for migrations |
| `NEON_AUTH_URL` | Neon Auth service URL |
| `NEON_AUTH_JWKS_URL` | JWKS URL for backend JWT verification |
| `NEON_AUTH_ISSUER` | Optional expected JWT issuer |
| `NEON_AUTH_AUDIENCE` | Optional expected JWT audience |
| `AUTH_REQUIRED` | Set `true` to enforce JWT auth on protected API routes |
| `SESSION_TTL_HOURS` | Profile/evidence session TTL for Neon `app_sessions` |
| `AI_PROVIDER` | `auto`, `gemini`, `rocketride_sdk`, `rocketride_http`, `anthropic` |
| `GEMINI_API_KEY` | Gemini key (recommended path) |
| `GEMINI_MODEL` | Gemini model id (default `gemini-2.0-flash`) |
| `ROCKETRIDE_URI` | RocketRide base URI |
| `ROCKETRIDE_APIKEY` | RocketRide API key |
| `ROCKETRIDE_GEMINI_KEY` | Gemini key passed to RocketRide pipelines |
| `ROCKETRIDE_PLAN_PIPELINE` | Plan pipeline path |
| `ROCKETRIDE_BRIDGE_PIPELINE` | Bridge pipeline path |
| `ROCKETRIDE_HTTP_COMPLETION_URL` | Legacy RocketRide HTTP completion URL |
| `ANTHROPIC_API_KEY` | Anthropic key |
| `LINKEDIN_CLIENT_ID` | LinkedIn Developer App client id for Neon Auth provider setup |
| `LINKEDIN_CLIENT_SECRET` | LinkedIn Developer App secret for Neon Auth provider setup |
| `LINKEDIN_REDIRECT_URI` | OAuth redirect URI registered with LinkedIn/Neon |
| `CORS_ORIGINS` | Comma-separated allowed origins |

Legacy Neo4j variables may still be used by the optional adapter. The default graph source is Markdown.

Validation rule: at least one provider path must be configured (`GEMINI_API_KEY`, RocketRide SDK pair, RocketRide HTTP pair, or `ANTHROPIC_API_KEY`).

## Local setup

### 1) Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Run Neon migrations after adding `DATABASE_URL_UNPOOLED` or `DATABASE_URL`:

```bash
cd backend
source .venv/bin/activate
python -m app.db.migrate
```

Run API:

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2) Graph data

Target graph data lives under `data/graph/{city}/...` as Markdown files. Each file has YAML frontmatter for typed properties and `[[wikilinks]]` for graph edges.

The legacy Neo4j seed command remains available only for optional adapter work:

```bash
cd backend
source .venv/bin/activate
python -m app.db.seed_data
```

### 3) Frontend

```bash
cd frontend
npm install
npm run dev
```

No env file is required — the document pipeline works out of the box (Xano defaults are baked in). To override anything, copy `frontend/.env.example` to `.env.local`; every var there is optional. The FastAPI-backed features (plan/chat/graph) use `VITE_API_BASE_URL` (default `http://127.0.0.1:8000`).

## Demo flow

1. Open app and verify status pills show API and graph-source health.
2. Complete Step 1 profile wizard and submit.
3. If `new_to_us=true`, generate plan in Step 2; if false, Step 2 is skipped and Step 3 opens directly.
4. Use "Explain term" to open Cultural Bridge.
5. In Step 3, switch categories, focus cards into graph, and inspect node details with Maps.

## Documentation index

- [BRD](./docs/BRD.md)
- [SRS](./docs/SRS.md)
- [Architecture](./docs/architecture.md)
- [Data model](./docs/data-model.md)
- [API spec](./docs/api-spec.md)
- [Agents spec](./docs/agents-spec.md)
- [Prompt spec](./docs/prompt-spec.md)
- [Demo runbook](./docs/demo-runbook.md)
- [Hackathon build plan — ISSS document pipeline on Xano](./docs/xano-document-pipeline-plan.md)
