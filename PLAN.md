# Globalदोस्त (GlobalBuddy)

> A graph-powered community platform that helps international students settle into a US city, discover local culture, make friends, and eventually mentor future arrivals — a lifelong companion for the immigrant journey.

---

## Viability Summary

| | |
|---|---|
| **Market** | Clear gap — no platform combines graph-ranked community matching with AI-guided settlement and a mentor lifecycle for international students |
| **Feasibility** | Medium — graph intelligence and AI synthesis are built; next work is simplifying the data layer around Neon + Markdown |
| **Free to build** | Yes for MVP — Neon handles auth/Postgres, graph knowledge lives in Git-backed Markdown, and R2 is optional only when uploads are needed |
| **Monetization** | B2B: university international student office SaaS; B2C: freemium with premium mentor access |

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Frontend | React 18 + Vite + React Router | Already built; React Router adds multi-page routing without full Next.js migration |
| Backend | **Xano** | System of record from M18: auth, pipeline state, gates, and workflow logic (hackathon Xano track requirement) |
| Compute sidecar | FastAPI (Python), stateless | Holds no user data. Markdown graph traversal, AI plan/bridge, SSE chat, and the document agent — none of which fit a Xano function stack |
| Knowledge Graph | Markdown + YAML frontmatter + `[[wikilinks]]` | Obsidian-style graph stored in Git; free, editable, easy to validate and demo |
| Relational DB | Xano (Neon during migration) | M18 ports auth + the demo-path tables; the remaining 8 stay on Neon until M22 (post-deadline) |
| Auth | Xano built-in auth | Replaces Neon Auth in M18 at byte-for-byte endpoint parity; adds a `student`/`advisor` role |
| Realtime | Deferred; SSE/WebSocket when needed | Avoids provider-specific realtime dependency during MVP |
| Storage | Cloudflare R2, optional later | Profile photos and uploads only when product needs them |
| Cache | Upstash Redis | Session cache, rate limiting; free tier sufficient for dev |
| AI (primary) | Gemini 2.5 Flash | 1,500 req/day + 1M tokens/min free — 166× more generous than alternatives |
| AI (fast fallback) | Groq (Llama 3) | Sub-200ms responses; free tier for lightweight queries (cultural bridge, chat) |
| Maps | Leaflet + OpenStreetMap | 100% free, no API key, replaces Google Maps links with real embedded maps |
| Email | Resend | 3k free emails/month; intro requests, welcome emails, notifications |
| Document extraction | Nutrient DWS (API + Viewer) | I-20 field extraction with confidence scores; Viewer renders the source doc with confidence overlays |
| Document generation | Doctavian | Branch-resolved form generation via their generation API |
| PDF assembly + eSign | Foxit PDF Services (MCP) + eSign | Packet assembly (convert/merge/stamp/flatten) and the human signature handoff |
| Live web data | SerpApi | Processing times, school ISSS requirements, and policy changes that force fields back to review |
| Hosting (frontend) | Vercel | Free tier; zero-config React/Vite deploy |
| Hosting (backend) | Railway | $5 free credit/month for FastAPI; simple env var management |

> **Data-layer decision:** Neo4j remains a useful future upgrade if the graph becomes highly dynamic or query-heavy. For the MVP, public city knowledge moves to Markdown so the app is cheaper, easier to edit, and not constrained by managed graph database limits. Supabase is no longer the default because project slots are the bottleneck across multiple active projects.

---

## Environment Variables

```
# Backend (.env)
DATABASE_URL=               # Neon pooled Postgres connection string
DATABASE_URL_UNPOOLED=      # Neon direct connection string, useful for migrations

# Neon Auth
NEON_AUTH_URL=              # Neon Auth service URL
NEON_AUTH_JWKS_URL=         # JWKS endpoint for backend JWT verification
NEON_AUTH_ISSUER=           # Optional expected JWT issuer
NEON_AUTH_AUDIENCE=         # Optional expected JWT audience
AUTH_REQUIRED=false         # Set true to require JWTs on protected /v1 routes

GEMINI_API_KEY=             # https://aistudio.google.com/app/apikey
GROQ_API_KEY=               # https://console.groq.com (free, no card)
ANTHROPIC_API_KEY=          # Optional paid fallback

UPSTASH_REDIS_URL=          # Upstash console → Redis → REST URL
UPSTASH_REDIS_TOKEN=        # Upstash console → Redis → REST token

RESEND_API_KEY=             # https://resend.com/api-keys (free)

# LinkedIn OAuth
LINKEDIN_CLIENT_ID=         # https://developer.linkedin.com
LINKEDIN_CLIENT_SECRET=     # LinkedIn Developer App secret
LINKEDIN_REDIRECT_URI=      # e.g. http://localhost:8000/v1/auth/linkedin/callback

# Xano (M18+) — becomes the system of record
XANO_BASE_URL=              # Xano API group base URL
SIDECAR_SHARED_SECRET=      # X-Sidecar-Key; Xano -> FastAPI sidecar auth

# Hackathon vendor APIs (M19). Mock-first: unset keys still run the full pipeline.
VENDOR_MODE=mock            # mock | live (global default)
NUTRIENT_MODE=              # per-vendor override of VENDOR_MODE
DOCTAVIAN_MODE=
SERPAPI_MODE=
FOXIT_MODE=
CONFIDENCE_THRESHOLD=0.85   # below this, an extracted field goes to human review
NUTRIENT_DWS_API_KEY=       # https://nutrient.io  (extraction + Viewer)
DOCTAVIAN_API_KEY=          # document generation API
SERPAPI_API_KEY=            # https://serpapi.com
FOXIT_PDF_SERVICES_KEY=     # PDF Services API (via their open-source MCP server)
FOXIT_ESIGN_API_KEY=        # eSign — separate credentials, called directly by the agent
FOXIT_WEBHOOK_SECRET=       # HMAC verification for POST /v1/webhooks/foxit

# Frontend (.env.local)
VITE_API_BASE_URL=          # Xano API group base URL
VITE_SIDECAR_BASE_URL=      # FastAPI sidecar — SSE chat + document agent
VITE_XANO_AUTH_URL=         # Xano auth endpoint for the Vite client
VITE_NUTRIENT_VIEWER_KEY=   # DWS Viewer client key for the review surface
```

> **Hackathon context:** this project is being submitted to the DevNetwork [API + Cloud + AI]
> Hackathon 2026 (deadline **3 Sep 2026, 10:00am PDT**) across five tracks — Xano, Nutrient, Foxit,
> Doctavian, and SerpApi. Milestones 18–21 are the submission; M22 finishes the migration afterwards.
> Full plan and track compliance matrix: `docs/xano-document-pipeline-plan.md`.

---

## Milestones

### Milestone 1: Scaffold ✅
**Goal:** Repo runs locally, folder structure in place, all dependencies installed.

Tasks:
- [x] Initialize React + Vite frontend — Done when: `npm run dev` starts on port 5173
- [x] Initialize FastAPI backend — Done when: `uvicorn app.main:app` starts on port 8000
- [x] Set up folder structure (routers, agents, services/ai, db, utils) — Done when: all dirs exist
- [x] Configure `.env.example` with required variables — Done when: file committed

---

### Milestone 2: Core Onboarding Feature ✅
**Goal:** Profile → Plan → Explore flow works end-to-end with deterministic fallback.

Tasks:
- [x] `POST /v1/profile/match` — graph matching with mentor/peer/local entity scoring (currently Neo4j-backed; Markdown graph migration planned)
- [x] `POST /v1/plan/generate` — AI plan with topological task ordering and week grouping
- [x] `POST /v1/bridge/explain` — Cultural term explanation with home-country analogy
- [x] `GET /v1/graph/subgraph` — session-scoped subgraph for vis-network
- [x] Deterministic fallback for plan and bridge when AI unavailable

---

### Milestone 3: Core UI/UX ✅
**Goal:** A real user can complete all 3 onboarding steps without confusion.

Tasks:
- [x] Step 1: 3-section profile wizard (personal, origin, destination)
- [x] Step 2: 30-day plan timeline with week grouping and task completion tracking
- [x] Step 3: Explore workspace with category filter chips and vis-network graph canvas
- [x] Cultural Bridge drawer with quick chips and term lookup
- [x] Person profile modal with contact links (email, LinkedIn, Instagram, phone)
- [x] Node detail card with Maps handoff
- [x] Health status panel (API + graph source)

---

### Milestone 4: Markdown Knowledge Graph Engine
**Goal:** Replace Neo4j as an MVP requirement with an Obsidian-style Markdown graph compiled into typed nodes, edges, evidence bundles, and subgraphs.

Tasks:
- [x] Define Markdown node schema: YAML frontmatter + body + `[[wikilinks]]` — Done when: docs describe required fields for `Mentor`, `Peer`, `University`, `Task`, `LocalEntity`, `Event`, `CommunityGroup`, and `Guide`
- [x] Create `data/graph/{city}/...` folder structure — Done when: Chicago has at least one validated node of each required type
- [x] Build parser for frontmatter, wikilinks, explicit relationships, and task dependencies — Done when: parser emits normalized `{nodes, edges}` without Neo4j
- [x] Add `MarkdownGraphService` with in-memory index and city/profile filtering — Done when: service can return mentors, peers, places, tasks, events, and groups for Chicago
- [x] Replace Neo4j reads in `profile_match_agent.py` and `graph_service.py` behind a graph adapter interface — Done when: `/v1/profile/match` works without `NEO4J_*` env vars
- [x] Update `/v1/graph/subgraph` and health UI for Markdown graph status — Done when: `/health/graph` returns node/edge counts and source=`markdown`
- [x] Add graph validation tests for duplicate IDs, broken wikilinks, missing required fields, and invalid task dependency cycles — Done when: validation fails clearly for bad fixtures
- [x] Keep Neo4j/Cypher files as optional legacy seed assets until migration is proven — Done when: README calls Neo4j optional, not required

---

### Milestone 5: Neon Auth & Persistent Accounts
**Goal:** Users have real accounts; profile, plan progress, documents, chat, and connections persist across sessions and devices in Neon Postgres.

Tasks:
- [x] Add Postgres migration tooling and driver (`asyncpg`/SQLAlchemy or equivalent) - Done when: `python -m app.db.migrate` can apply SQL migrations against Neon
- [x] Configure Neon project/Auth env contract - Done when: `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `NEON_AUTH_URL`, and `NEON_AUTH_JWKS_URL` are documented in env examples; console values are supplied per deployment
- [x] Add Neon Auth frontend integration at `/auth` - Done when: email signup/login uses the Neon Auth SDK when `VITE_NEON_AUTH_URL` is set and redirects signup to onboarding
- [x] Add JWT verification middleware to FastAPI - Done when: protected `/v1/*` routes require a valid Neon Auth token when `AUTH_REQUIRED=true` and a JWKS URL is configured
- [x] Create Neon Postgres tables: `user_profiles`, `plan_progress`, `user_documents`, `chat_messages`, `connections`, `content_items`, `saved_content`, `mentor_profiles`, `mentor_ratings`, `notifications` - Done when: `backend/migrations/001_neon_persistence.sql` defines the schema
- [x] Link `user_profiles.auth_user_id` to Neon Auth's synced user row - Done when: `/v1/auth/me` and persistence routes resolve the app user profile from token claims
- [x] Add routes: `/` (onboarding), `/auth`, `/dashboard`, `/profile/:id`, `/chat`, `/pre-arrival` - Done when: each path renders without 404
- [x] Migrate plan task completion from localStorage to `plan_progress` - Done when: authenticated users sync progress through `/v1/progress/plan`, with localStorage fallback for no-auth demos

---

### Milestone 6: LinkedIn OAuth
**Goal:** Users can sign in and pre-fill their profile with LinkedIn data, using Neon Auth as the auth layer.

Tasks:
- [x] Register LinkedIn Developer App with scopes `openid`, `profile`, `email` — Done when: setup docs/env contract identify the required LinkedIn Client ID and Secret; actual console values are supplied per deployment
- [x] Configure LinkedIn as an OAuth provider in Neon Auth — Done when: `/auth` calls Neon Auth `signIn.social({ provider: "linkedin" })`; actual provider enablement happens in Neon console
- [x] Add "Continue with LinkedIn" button to `/auth` — Done when: clicking starts the Neon Auth LinkedIn OAuth redirect when `VITE_NEON_AUTH_URL` is configured
- [x] Add `GET /v1/auth/linkedin/profile` endpoint or token-claim mapper — Done when: backend returns `{source, full_name, email, linkedin_url, country_of_origin, target_university}` when available
- [x] Update `ProfileForm.jsx` to pre-fill empty fields for LinkedIn-authenticated users — Done when: imported account/LinkedIn fields are visually marked and never overwrite user-entered values

---

### Milestone 7: Reliability Hardening
**Goal:** Logs, error telemetry, graph validation, and tests make failure visible and recoverable in production.

Tasks:
- [x] Add structured JSON logging to AI agents — `ai_event=` log lines with provider name, latency_ms, and fallback flag in `judge_agent.py` and `cultural_bridge_agent.py`
- [x] Add request-level timeout middleware to `/v1/plan` and `/v1/bridge` — `_RequestTelemetryMiddleware` in `main.py` logs elapsed_ms; AI calls wrapped with `asyncio.wait_for(timeout=AI_TIMEOUT_SECONDS)` with explicit `asyncio.TimeoutError` handling and fallback
- [x] Add `GET /health/providers` endpoint that pings Gemini, Groq, and Anthropic — returns `{status, latency_ms}` per provider; `not_configured` when key absent
- [x] Write regression tests for `new_to_us=False` skip behavior — `tests/test_new_to_us.py` (5 tests, all passing)
- [x] Write smoke tests for the full 3-step flow using mock graph responses — `tests/test_smoke.py` covers profile→plan→bridge→graph + AI timeout fallback paths
- [x] Replace in-memory session store with Neon Postgres or Upstash Redis-backed store, TTL 24h — Done when: profile evidence/subgraph sessions persist in Neon `app_sessions` and rehydrate after process restart
- [x] Add Markdown graph validation to CI — Done when: `.github/workflows/ci.yml` runs `python -m app.db.validate_graph` before backend tests

---

### Milestone 8: User Lifecycle & Journey Stages
**Goal:** Users progress through defined stages (Newcomer → Settler → Local → Mentor); the platform surfaces different content and connections at each stage.

Tasks:
- [x] Define `stage` enum in Neon `user_profiles`: `newcomer` (0–3 months), `settler` (3–12 months), `local` (1–2 years), `mentor` (opted in) — Done when: migration applied and `stage` column exists
- [x] Add stage detection logic in `profile_match_agent.py` — infer stage from `arrival_date` if provided, default to `newcomer` — Done when: profile match response includes `user_stage` field
- [x] Update Markdown graph matching weights per stage — newcomers get more mentor/task matches; settlers get more peer/social matches; locals get more community/event matches
- [x] Add stage progress indicator to the frontend dashboard — Done when: dashboard shows "You're a Settler — 3 more months to Local" style progress
- [x] Add "Upgrade my stage" prompt — after 90 days as newcomer, show a banner inviting the user to mark themselves as settled

---

### Milestone 9: Pre-Arrival Checklist & Document Tracker
**Goal:** Students can prepare before landing and track critical first-month documents.

Tasks:
- [x] Add pre-arrival checklist content to existing graph seed data with ~15 items
- [x] Add `/pre-arrival` route and `PreArrivalPanel.jsx` component — a checklist page accessible before Step 1 (no auth required)
- [x] Add `DocumentTracker` component to the dashboard — tracks SSN, bank account, student ID, health insurance, I-20 copy, lease with status and links to how-to guides
- [x] Convert pre-arrival checklist and document tasks to Markdown graph nodes — Done when: plan generation uses Markdown task dependencies
- [x] Persist document tracker state to Neon `user_documents` table — Done when: authenticated document status syncs through `/v1/documents`
- [x] Add `Task` graph nodes for each document (SSN, bank, health insurance) linked to the plan's topological order

---

### Milestone 10: Persistent AI Chat
**Goal:** The Cultural Bridge becomes a full persistent chat assistant — students can ask anything about US life, their city, or their situation.

Tasks:
- [x] Add `chat_messages` table to Neon Postgres: `{id, user_id, session_id, role (user/assistant), content, created_at}` — Done when: authenticated chat messages persist through `/v1/chat`
- [x] Add `POST /v1/chat/message` FastAPI endpoint — accepts `{message, session_id}`, loads last 10 messages for context, calls Gemini/Groq, stores both user message and response, returns assistant reply
- [x] Create `ChatPage.jsx` at `/chat` — persistent chat interface with message history, typing indicator, and quick-chip suggestions
- [x] Replace the existing `CulturalBridgeDrawer.jsx` one-off term lookup with a link that opens `/chat` pre-seeded with the term as the first message
- [x] Add SSE/WebSocket response streaming when needed — Done when: assistant reply appears incrementally without relying on provider-specific realtime

---

### Milestone 11: Social Layer — Connections & Buddy System
**Goal:** Users can connect with each other, request mentor introductions, and build a real social graph on the platform.

Tasks:
- [x] Add `connections` table to Neon Postgres: `{id, requester_id, recipient_id, status (pending/accepted/declined), created_at}` — defined in `001_neon_persistence.sql`; `003_social_requests.sql` adds `social_requests` for the MVP (requests target seed graph entities, see note below)
- [x] Add `POST /v1/social/connect` endpoint — sends a connection request; stores dynamic user connections in Neon
- [x] Update person profile modal — add "Request Connection" button for peers and "Request Intro" button for mentors; both disabled until the user is logged in
- [x] Add `POST /v1/social/intro-request` endpoint — sends a templated intro email via Resend without exposing mentor email
- [x] Add `/connections` dashboard page listing accepted connections with stage, university, and country
- [x] Add WhatsApp/Telegram group links as Markdown `CommunityGroup` nodes — surface them in Explore under a new "Groups" filter chip

---

### Milestone 12: Cultural & City Discovery Feed
**Goal:** Logged-in users see an ongoing feed of culturally relevant events, guides, and local tips — not tied to the 30-day clock.

Tasks:
- [x] Add `content_items` table to Neon Postgres for dynamic/published content — defined in `001`; `/v1/feed` merges published `content_items` with Markdown items
- [x] Seed static Chicago guides, tips, and restaurant spotlights as Markdown `Guide` / `Event` / `LocalEntity` nodes — added winter-survival and CTA/Ventra tip guides alongside existing events/restaurants
- [x] Add `GET /v1/feed` FastAPI endpoint — returns Markdown graph items + Neon content filtered by city and cultural tags
- [x] Add `FeedPage.jsx` at `/feed` route — card-based feed with category tabs and Load-more pagination
- [x] Replace Google Maps link-outs with OpenStreetMap in `NodeDetailCard.jsx`, `MapPreviewPanel.jsx`, `ExploreWorkspace.jsx`, `CommunityFitPanel.jsx`, and backend `_maps_url` — see deviation note below
- [x] Add "Save" button to feed items — saved items stored in Neon `saved_content` table and accessible at `/saved`

---

### Milestone 13: Mentor System
**Goal:** Settled users can opt in as mentors; newcomers get matched to them; mentors build a reputation over time.

Tasks:
- [x] Add `mentor_profiles` table to Neon Postgres: `{user_id, expertise[], availability, bio, response_rate, intro_count, rating, opted_in_at}` — defined in `001`; `mentor_ratings` too
- [x] Add `/become-mentor` page and flow — requires `stage` = `settler`, `local`, or `mentor`; opt-in sets stage → `mentor` and supports pause/resume via availability
- [~] Merge opted-in Neon mentor profiles with Markdown seed mentors — merged in the **`GET /v1/mentors` directory** (seed + Neon). Deferred merging into the per-session profile-match *ranking*: the Markdown graph service has no Neon handle, so injecting live mentors into `profile_match` ranking is a follow-up (see note below)
- [~] Add mentor rating flow — `POST /v1/mentors/{id}/rate` upserts a rating and recomputes `mentor_profiles.rating`. Surfaced as a rating action on the directory rather than the 7-day accepted-connection prompt (seed mentors can't "accept"; see note)
- [x] Add `/mentors` public directory page — lists seed + opted-in mentors filterable by city, university, country of origin, expertise

---

### Milestone 14: Notifications
**Goal:** Users receive timely, useful notifications — in-app and via email — without being spammed.

Tasks:
- [x] Add `notifications` table to Neon Postgres: `{id, user_id, type, title, body, read, created_at}` — defined in `001`
- [~] Add notification triggers — wired requester-side triggers (`connection_sent`, `intro_sent`) in the social router. Recipient-side triggers (connection request *received*, intro *accepted*, new message) need the real social graph; stage-upgrade and document reminders need a scheduler (see note)
- [x] Add notification bell icon to the frontend nav — `NotificationBell` polls `GET /v1/notifications` every 30s, shows an unread badge and a dropdown with mark-read / mark-all-read
- [~] Add Resend email integration — intro-request email ships in M11. Connection-accepted and weekly-digest emails need the real social graph + a scheduler (see note)
- [~] Add browser push notification opt-in — `NotificationBell` offers an "Enable browser alerts" prompt and raises a local `Notification` for new items when permission is granted. True server-sent Web Push (VAPID keys + service worker + subscription store) is deferred (see note)

---

### Milestone 15: Multi-City Markdown Graph Expansion
**Goal:** At least 3 cities have complete, verified Markdown graph data — Chicago, Boston, and NYC.

Tasks:
- [x] Existing Cypher seed packs cover Chicago, Boston, and NYC
- [x] Add city selector to `ProfileForm.jsx` Step 1 — dropdown of supported cities with "More cities coming soon" for unsupported entries
- [x] Convert Chicago seed data to Markdown graph nodes — done in M4; validation passes and Chicago profile matching returns expected coverage
- [x] Convert Boston seed data to Markdown graph nodes — `scripts/gen_city_seed.py` emits 32 Boston nodes (5 mentors, 11 local places); `test_multicity.py` asserts city-scoped match
- [x] Convert NYC seed data to Markdown graph nodes — generator emits 32 New York nodes (5 mentors, 11 local places)
- [x] Add metadata quality checks for Markdown graph — `python -m app.db.validate_graph` now prints per-city coverage (mentors, local places, type breakdown) for all 3 cities

---

### Milestone 16: Deploy
**Goal:** Platform is live at a public URL; Neon, Markdown graph data, AI providers, and optional email/storage services are connected in production.

Tasks:
- [x] Add deploy config to the repo for reproducible deploys — `backend/Procfile`, `backend/railway.toml`, `backend/runtime.txt`, `render.yaml` (both services), `frontend/vercel.json` (SPA rewrites), and `docs/DEPLOYMENT.md` with step-by-step instructions
- [ ] Build frontend with `npm run build` and deploy `frontend/dist` to Vercel — **blocked on user's Vercel account**; build verified locally and `vercel.json` ready
- [ ] Deploy FastAPI backend to Railway/Render/Fly with all env vars set via platform secrets — **blocked on user's Railway/Render account**; config ready, `GET /health|/health/graph|/health/providers` exist
- [ ] Configure Neon production database, migrations, and Neon Auth keys — **blocked on user's Neon account**; `python -m app.db.migrate` applies `001`–`003` (see DEPLOYMENT.md)
- [ ] Set `VITE_API_BASE_URL` and Neon Auth client env vars in Vercel — **blocked on deploy**
- [ ] Configure custom domain (if available) on Vercel — **blocked on deploy**
- [ ] Smoke-test the full platform flow on production: signup → onboarding → plan → explore → chat → connection request → feed — **blocked on deploy**

---

### Milestone 17: Polish
**Goal:** No obvious errors; loading states present; edge cases handled; branding consistent.

Tasks:
- [x] Audit all UI copy for Globalदोस्त branding — zero product-facing "GlobalBuddy" strings in `frontend/src` — Done when: grep finds no product-facing instances
- [x] PlanPanel already has loading skeletons; FeedPage is persistence-backed work for a later milestone; ExploreWorkspace is prop-driven (no async loading state needed)
- [x] Add React error boundary in `App.jsx` — catches unhandled errors and shows "Something went wrong, please refresh" — Done when: throwing inside any panel renders the fallback
- [x] API error states: ProfileForm, PlanPanel, PreArrivalPage, ChatPage all surface errors via Banner or inline error div; graph-source errors surface through plan/profile API error paths
- [x] Add verification disclaimer to all entity cards (NodeDetailCard) and PlanPanel timeline — Done when: disclaimer text is visible on every card
- [ ] Accessibility deep audit — tab-key navigation through 3-step form and dashboard (ARIA labels added; full keyboard flow test pending manual verification)

---

### Milestone 18: Xano Foundation — Auth & Demo-Path State
**Goal:** Xano owns auth and the state the hackathon demo path touches. Deliberately reduced scope — the other 8 tables stay on Neon until after the deadline.

Full spec: `docs/xano-document-pipeline-plan.md` §2. **Deadline: 3 Sep 2026, 10:00am PDT.**

Tasks:
- [x] Confirm pre-existing project work is permitted — **allowed**; still frame write-ups around 17 Aug–3 Sep work and keep commits scoped `feat(m18)`…`feat(m21)`
- [x] **Day 1:** request credentials — Nutrient DWS, Doctavian, SerpApi confirmed working; Foxit (both PDF Services and eSign) and Doctavian company-account access still pending vendor email replies
- [ ] **Day 1 spike:** import the Doctavian Postman collection and pin real endpoint paths + request bodies — Done when: the mock fixture matches the real shape (this is the least-verified vendor in the plan)
- [x] Determine whether "Xano Agent" is a runtime agent or a dev assistant — **it is both.** The dev assistant builds your backend; **Xano Agents** are runtime LLM entities invoked via `Call AI Agent`, with Custom Functions / APIs / DB / **remote MCP tools** as tools, OpenAI + Anthropic + free Gemini credits, and a run/step/tool-call dashboard. The document agent now runs *in Xano* (§2.3, §6.2)
- [x] **Day 1 spike:** confirm which Xano plan tier includes Agents and whether run limits apply — **Essential plan confirmed**: both Agents and Background Tasks are available; no fallback needed
- [x] **Day 1, blocking:** confirm the Xano tier — **Essential**, background tasks available, synchronous-extraction fallback not needed
- [x] Create Xano workspace + env vars (`VENDOR_MODE`, `CONFIDENCE_THRESHOLD`, per-vendor mode + key vars) — Done when: `GET /v1/auth/me` returns 401 unauthenticated — **verified live via curl: 401 confirmed**
- [x] `xano pull` the workspace as **XanoScript** into `xano/` and commit it — Done when: the backend diffs in PRs like any other code
- [x] Port 4 tables only — `user_profiles`→`user`, `user_documents`, `plan_progress`, `notifications` — schema verified live in the Xano dashboard, all fields present and correctly typed
- [x] Add `role` (`student`|`advisor`) to `user` — Done when: the advisor queue in M20 can gate on it
- [x] Rebuild `/v1/auth/{signup,login,me,me/stage}` on Xano auth — **verified live via curl**: signup returns `{token, user}` matching `xanoAuth.js`'s contract exactly; `auth/me` returns the flat profile; stage-advance (newcomer→settler) succeeds; stage-regression attempt (settler→newcomer) correctly no-ops, matching `advance_user_stage`'s forward-only guard
- [x] Port the documents, progress, and notifications API groups — **verified live via curl**, with one required deviation: see "Path parameters don't work" below
- [x] Apply auth requirement per `PUBLIC_V1_PREFIXES` in `backend/app/auth.py:33` — **verified live**: unauthenticated `auth/me` call correctly returns 401
- [ ] `X-Sidecar-Key` shared-secret middleware on FastAPI + 5-min Xano-minted token for SSE/agent — FastAPI side already built (`backend/app/sidecar_auth.py`); Xano side not yet wired
- [ ] `scripts/migrate_neon_to_xano.py` — idempotent, FK-ordered, row-count parity assertions — script written, not yet run (no Neon data to migrate yet)
- [x] **Cut:** LinkedIn OAuth rebuild — already blocked on LinkedIn review (M6), zero demo value
- [x] **Discovered and fixed:** path-parameter routes (`/documents/{doc_type}` etc.) are confirmed broken on this Xano workspace/tier — every path-param endpoint 404s at request time despite parsing, pushing, and appearing correctly in Swagger, even for a 100%-UI-generated test case. Worked around by moving all identifiers into the request body instead of the URL path. **Binding rule for M19/M20: no path parameters, ever** — see `docs/xano-document-pipeline-plan.md` §5.5 for the full writeup and the endpoint rewrite table

---

### Milestone 19: Document Pipeline — Agent, Extraction, Gate, Generation, Signature
**Goal:** A plain prompt ends in a signed, correct document, with a human gate wherever the model isn't sure. This is the hackathon submission.

Full spec: `docs/xano-document-pipeline-plan.md` §3. Scope: I-20 only, one form output. Track compliance matrix: §1.

Tasks:
- [ ] Create the 9 pipeline tables + `vendor_fixtures` — Done when: `document_uploads` … `pipeline_events` and `agent_runs` exist with FKs to `user`
- [ ] Seed 3 Nutrient fixtures: all-high-confidence, mixed (2–3 below threshold), hard failure — Done when: mock mode returns each on demand
- [ ] `vendor_nutrient_extract` / `vendor_doctavian_generate` / `vendor_serpapi_lookup` / `vendor_foxit_send` with `mock`/`live` branch — Done when: no function stack calls a vendor URL directly
- [ ] Define the I-20 JSON Schema for Nutrient `/extract` — Done when: 12 fields come back with confidence, match label, page, bbox, and source citation
- [ ] `POST /v1/documents/upload` + extraction writing `extracted_fields` — Done when: 12 I-20 fields land with confidences (**Nutrient track: core operation 1**)
- [ ] `apply_confidence_threshold` — below 0.85 **and** always-review keys (`sevis_id`, `program_end_date`, `funding_amount`) → `needs_review` — Done when: the mixed fixture yields ≥2 review items. Nutrient documents its confidence as *uncalibrated*, so the always-review rule is their recommendation, not our opinion — quote that in the write-up and never present the threshold as a probability. Post-July-2026 `program_end_date` *is* the admission period, making it the highest-stakes field on the I-20
- [ ] Review endpoints writing a `field_reviews` row on every action — Done when: no correction is possible without an audit row
- [ ] Server-side gate: generation rejected while any field is `needs_review` — Done when: the contract test asserts the rejection
- [ ] `resolve_form_variant` — 4 variants on visa status × funding source; school drives header substitution — Done when: each branch returns its variant
- [ ] `POST /v1/documents/{id}/generate` freezing `field_snapshot`, calling the **Doctavian generation API** — Done when: later corrections don't alter a generated form (**Doctavian track**)
- [ ] Foxit **PDF Services** packet assembly — register their open-source MCP server as **remote MCP tools on the Xano Agent**; convert, merge with the source I-20 page, stamp audit ID + "verified as of", flatten — Done when: ≥4 tools are used and the packet can't be edited before signing (**Foxit track, req 2**)
- [ ] Build the document agent as a **Xano Agent** — 8 tools (6 Custom Functions + Foxit PDF Services as remote MCP tools + an eSign Custom Function), invoked from `POST /v1/agent/documents` via `Call AI Agent`, runs recorded in `agent_runs` — Done when: a plain prompt drives the pipeline end to end (**Foxit track req 1**, and it upgrades the **Xano** claim from "database with endpoints" to "the agent is a Xano Agent")
- [ ] **27 Aug decision point:** Xano Agents usable on our tier, or fall back to `backend/app/agents/document_agent.py` in the sidecar — Done when: decided; after this date the switch costs more than it saves
- [ ] Agent **cannot self-approve** — `generate_form` hard-errors while fields are `needs_review`, so the agent calls `request_human_review` and stops — Done when: the refusal is visible in the agent trace (this is the Foxit demo's opening shot)
- [ ] SerpApi: 3 lookups via the **AI Overviews endpoint with citation extraction** — processing time, school ISSS requirements, and **recent policy changes that force a field back to review** — Done when: live search data measurably changes agent behaviour, not just page copy (**SerpApi track**). Anchor the demo to the **16 July 2026 DHS rule** that ended Duration of Status and halved the OPT grace period: every template written before that date generates a wrong document today
- [ ] `send_for_signature` calling **Foxit eSign directly** — OAuth2 `client_credentials` against `na1.foxitesign.foxit.com/api/oauth2/access_token`, credentials separate from PDF Services — Done when: a real person signs (**Foxit track, req 3**). eSign sits *outside* the MCP server, which is exactly why the track requires the agent to call it directly — say so in the write-up
- [ ] HMAC-verified `POST /v1/webhooks/foxit` + `FOXIT_MODE=mock` simulate endpoint — Done when: `signed` flips `user_documents.status` to `done` and creates a notification
- [ ] `backend/tests/test_pipeline_contract.py` driving the full mock flow incl. the rejected generate — Done when: it passes with zero vendor keys set
- [ ] Switch every vendor to `live` and re-run — Done when: each track has at least one real API call in the recording

---

### Milestone 20: Frontend — Student Pipeline & Advisor Queue
**Goal:** The pipeline is usable, the confidence step is visible, and the advisor side proves this is a SaaS rebuild rather than a student toy.

Full spec: `docs/xano-document-pipeline-plan.md` §4.

Tasks:
- [ ] Point `client.js` at Xano; second axios instance for routes still on FastAPI; `VITE_SIDECAR_BASE_URL` for SSE/agent — Done when: all 10 existing pages work untouched
- [ ] `frontend/src/auth/xanoAuth.js` replacing `neonAuth.js` at the same interface — Done when: `AuthContext.jsx` changes only its import
- [ ] `DocumentsPage.jsx` + `/documents` route + `PipelineStepper.jsx` — Done when: the five stages render with the current one lit
- [ ] `DocumentUpload.jsx` with progress and doc-type select — Done when: an upload creates a `document_uploads` row
- [ ] `ExtractionResults.jsx` using the **Nutrient DWS Viewer** to render the real I-20 with confidence overlays; show confidence for accepted fields too — Done when: the trust layer is visible at a glance (**Nutrient track: core operation 2**)
- [ ] `AgentConsole.jsx` — plain-prompt box + agent trace naming each tool call, **polling `agent_runs` at 1s** (Xano Agents don't document streaming; polling is the proven pattern here) — Done when: the refusal-to-sign moment is legible on screen
- [ ] `FormPreview.jsx` showing the resolved variant, its branch inputs, and SerpApi sources — Done when: the branch decision is legible without explanation
- [ ] `SignatureStatus.jsx` with status polling and signed-packet download — Done when: the signed file downloads
- [ ] `AdvisorQueuePage.jsx` at `/advisor` — review queue, reviewer attribution, per-submission audit trail, and an auto-accepted vs. escalated "time saved" counter — Done when: the Terra Dotta comparison is numeric on screen
- [ ] Link `/documents` from `DocumentTracker.jsx` on the SSN item — Done when: it offers "Start document flow →"

---

### Milestone 21: Submission Package
**Goal:** Five submissions, two videos, a repo a judge can actually run. Budget two full days — this is the most under-budgeted work in any hackathon.

Full spec: `docs/xano-document-pipeline-plan.md` §5. **Submit before 3 Sep, 10:00am PDT.**

Tasks:
- [ ] Storyboard both videos (1 Sep) — Done when: shot lists exist for each
- [ ] Main demo video, **2–4 min**, recorded in `live` mode — ISSS problem → upload → confidence in the Viewer → advisor reviews 3 escalated fields → SerpApi flags a policy change → branch resolves → packet assembled → signed
- [ ] Foxit demo video, **1–3 min** (shorter than the others) — plain prompt → agent refuses to generate → human reviews → PDF Services assembles → eSign → person signs
- [ ] `docs/hackathon-submission.md` with per-track write-ups — Done when: each track's specific ask is answered
- [ ] Xano **build story**: software replaced (Terra Dotta/Sunapsis, 700+ universities), why, AI tools used, build duration, what would have taken significantly longer without AI + Xano — Done when: explicitly written, it's a stated requirement. The honest answer is XanoScript + Xano CLI + Claude Code
- [ ] Lead every write-up with the market case — the 16 July 2026 D/S rule, OPT grace 60→30 days, 6–10 month I-765 delays, and a $17.7B SIS market growing 14.6% — Done when: **Concept** and **Feasibility** are argued with dates and numbers, not adjectives
- [ ] Nutrient's required one-liner on where DWS does the heavy lifting and why — Done when: written
- [ ] Foxit: defend the agent/human boundary and the Xano-vs-"agent calls eSign directly" tension — Done when: the choice is argued, not glossed
- [ ] SerpApi: show how live data changed agent behaviour, not just page content — Done when: lookup 3 is the centrepiece
- [ ] Public repo, `.env.example` for every new key, README quickstart **verified from a clean clone** — Done when: a fresh clone runs in mock mode with no vendor keys
- [ ] Update `docs/demo-runbook.md`; confirm no credentials or real student documents are committed

---

### Milestone 22: Decommission the FastAPI State Layer (post-deadline)
**Goal:** Finish the migration properly once the submission is in. Zero judging value before 3 Sep — deliberately deferred.

Full spec: `docs/xano-document-pipeline-plan.md` §0.2, §0.3.

Tasks:
- [ ] Port the remaining 8 tables — `chat_messages`, `connections`, `content_items`, `saved_content`, `mentor_profiles`, `mentor_ratings`, `social_requests`, `app_sessions`
- [ ] Delete routers `auth, documents, progress, social, mentor, notifications, feed, profile, pre_arrival`; keep `graph, plan, bridge, chat` and the agent — Done when: `main.py` includes only those
- [ ] Delete `app/db/{postgres,repositories,migrate}.py`, `backend/migrations/`, `app/auth.py` — Done when: no `asyncpg` import remains
- [ ] Strip `database_url*`, `neon_auth_*`, `stack_*`, `supabase_*`, `auth_required` from `config.py`; add `sidecar_shared_secret`, `xano_base_url` — Done when: the app boots with neither Neon nor auth vars
- [ ] Collapse the frontend's two axios instances back to one — Done when: only `VITE_API_BASE_URL` + `VITE_SIDECAR_BASE_URL` remain
- [ ] `backend/tests/test_xano_contract.py`, skipped without `XANO_TEST_BASE_URL` — Done when: CI is green with no secrets
- [ ] Update `render.yaml`, `README.md`, `docs/{DEPLOYMENT,architecture,api-spec,data-model}.md`, and Notes & Decisions — Done when: no doc still describes Neon as the system of record
- [ ] Remove `@neondatabase/neon-js` from `frontend/package.json` — Done when: the build passes without it

---

## Claude Code Commands

**Start at the first incomplete milestone:**
```
claude "Read PLAN.md and complete the first milestone that has unchecked tasks. Mark tasks done as you go. Stop after that milestone and commit."
```

**Resume from any point:**
```
claude "Read PLAN.md, find the first incomplete task, and continue. Mark tasks done as you go. Commit when a milestone is complete."
```

**Run a specific milestone:**
```
claude "Read PLAN.md and complete Milestone 4 (Markdown Knowledge Graph Engine). Mark tasks done as you go. Stop after Milestone 4 and commit."
```

**Test current state:**
```
claude "Read PLAN.md. Without building anything new, test everything marked done. Run pytest for backend, check the platform flow in the browser. Report what works and what's broken."
```

---

## Notes & Decisions

- **Markdown graph + Neon split:** Markdown owns public/static knowledge (cities, universities, tasks, local places, seed mentors, guides, groups). Neon Postgres owns private/dynamic user data (profiles, progress, chat, connections, notifications). Never store private user data in Markdown.
- **Auth token flow:** Neon Auth issues a JWT on login. The frontend sends it as `Authorization: Bearer <token>` on protected API calls. FastAPI verifies against the configured Neon Auth JWKS.
- **Gemini vs Groq routing:** Use Gemini 2.5 Flash for plan generation and multi-turn chat (needs high token count). Use Groq for cultural bridge one-off lookups (needs low latency). The existing provider factory handles this — add a `prefer_speed` flag to the AI call.
- **Stage progression:** Stage is set by the backend based on `arrival_date`. Users can also manually advance their stage. Never let stage go backward automatically.
- **Mentor opt-in only:** Never auto-graduate a user to mentor. It must be an explicit opt-in action. Mentors can pause or deactivate their availability without losing their history. (M13: `POST /v1/mentors/opt-in` sets stage → `mentor`; `PATCH /v1/mentors/me/availability` toggles `available`/`paused`.)
- **Mentor merge & rating scope (M13):** Seed and opted-in mentors are merged in the `/v1/mentors` directory only. Two deferrals, both rooted in the seed-vs-real-user split: (1) the per-session `profile_match` ranking still uses only Markdown seed mentors because the graph service has no Neon connection — injecting live mentors needs a db handle in the graph layer or a post-rank merge step in the profile router; (2) rating is a direct directory action gated to real (Neon) mentors instead of the planned "7-day-old accepted connection" prompt, because seed-mentor intro requests have no real counterpart to accept. Both become natural once intro recipients resolve to real users.
- **LinkedIn OAuth scope:** Basic OIDC (`openid profile email`) works without app review. Education history endpoint requires LinkedIn review (1–4 weeks). Build pre-fill to work without education data and treat university pre-fill as a bonus.
- **Neo4j optionality:** Keep the existing Neo4j/Cypher implementation only as a legacy adapter or future upgrade path. The MVP should run without graph database credentials.
- **Branding:** Product-facing name is **Globalदोस्त**. Code identifiers use `globaldost` or `globalbuddy`. Only update UI copy strings, never rename code symbols.
- **Maps migration:** All Google Maps link-outs are replaced with OpenStreetMap (`openstreetmap.org/search?query=` link-outs + an OSM `export/embed.html` iframe in `MapPreviewPanel`). **Deviation from original plan:** did not add `leaflet`/`react-leaflet`. OSM's embed needs a lat/lon bbox and does not geocode free text, while most graph nodes (mentors, tasks, events, and subgraph `GraphNode`s) carry no coordinates — so an interactive Leaflet marker map can't be placed for them without geocoding. The embed renders a real OSM map when a card has `latitude`/`longitude` (local places do) and falls back to an OSM search link otherwise. Adding react-leaflet later only pays off once lat/lon coverage is added to the seed data and `GraphNode`.
- **Email privacy:** Intro request emails are sent by the backend via Resend — the requester never sees the mentor's raw email address. The mentor's email is only in the backend environment.
- **Notifications scope (M14):** In-app notifications are fully working: server-side triggers create rows, the bell polls every 30s, and items mark read. Three pieces are deferred and share root causes: (1) recipient-side triggers (connection/intro *received* or *accepted*, new message) need real user↔user relationships, not seed targets; (2) weekly digest + "stage upgrade available" + "document reminder" need a scheduled job (no cron/worker yet — could be a Railway cron or `pg_cron`); (3) true Web Push needs VAPID keys, a service worker with a `push` handler, and a `push_subscriptions` table — only the client permission prompt + local `Notification` is implemented. Polling was chosen over SSE for the bell to keep it simple and proxy-friendly.
- **Social requests target seed graph entities (M11):** The people surfaced in Explore are Markdown seed mentors/peers, not Neon `user_profiles` rows, so connection/intro requests are recorded in `social_requests` (`requester_id` → user, `target_node_id` → graph node id). The user↔user `connections` table from `001` is reserved for the future real social graph once a user directory exists (M13 mentor system). When opted-in Neon mentors merge with seed mentors in M13, intro targets that resolve to a real user should also write a `connections` row. Resend is optional — without `RESEND_API_KEY` the intro still records and `email_sent` is `false`.
