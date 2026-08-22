# Handoff — GlobalBuddy / Globalदोस्त

_Last updated: 22 Aug 2026. Everything below is committed and pushed to `origin/main` (HEAD `501e6fb`); working tree clean. Durable context also lives in `PLAN.md`, `PRODUCT.md`, and `docs/xano-document-pipeline-plan.md`._

## Goal

Ship the **ISSS document pipeline** for the DevNetwork [API + Cloud + AI] Hackathon 2026 (deadline **3 Sep 2026, 10:00am PDT**) across five tracks — Xano, Nutrient, Foxit, Doctavian, SerpApi. One codebase, five submissions. Framed as an AI-assisted rebuild of the university ISSS document workflow (Terra Dotta / Sunapsis): I-20 → signed SSN support packet, with a human in the loop wherever the model is unsure.

## Current state

- **M18 (Xano foundation): done + live-verified.** Xano is the system of record for auth + the pipeline; the app auths against Xano; 4 tables ported (`user` w/ role+stage, `user_documents`, `plan_progress`, `notifications`). Backend is version-controlled as XanoScript in `xano/`.
- **M19 (pipeline): done + live-verified end to end (mock mode).** upload → Nutrient extract → confidence gate → human review → Doctavian generate → SerpApi policy check (forces re-review on a detected change) → Foxit sign. Plus a **Xano Agent** that drives it from a plain prompt and **refuses to generate/sign while review is pending** (the Foxit centerpiece). A live HTTP contract test (`backend/tests/test_pipeline_contract.py`) passes.
- **M20 (frontend): functionally done + browser-verified.** `/documents` (student pipeline UI) and `/advisor` (role-gated review queue with the machine-vs-human "time saved" bar). `DocumentTracker` links to `/documents`. Shared `XanoLoginGate`.
- **Impeccable design skill** installed globally (`~/.claude/skills/impeccable`); hooks active; `PRODUCT.md` written via `/impeccable init`.

## Files in flight

Nothing uncommitted. The next task (design pass) will touch:
- **Read-only baseline:** `frontend/src/styles/global.css` (~2,900 lines, the `gb-*` system), all `frontend/src/pages/*` and `frontend/src/components/*`.
- **Will create:** `DESIGN.md` (via `/impeccable document`).
- **Will likely edit:** pipeline screens (`DocumentsPage.jsx`, `AdvisorQueuePage.jsx`, `XanoLoginGate.jsx`) and possibly existing pages/components during polish.

## Things changed (this session)

- Xano advisor endpoints: `advisor/queue` GET + `advisor/review` POST (role-gated; advisor can review any student's field, attributed to the advisor).
- Frontend: `pages/DocumentsPage.jsx`, `pages/AdvisorQueuePage.jsx`, `components/XanoLoginGate.jsx`, `api/xanoClient.js`, `api/documentsApi.js`; `App.jsx` routes `/documents` + `/advisor`; `DocumentTracker.jsx` link.
- `PRODUCT.md`, `.claude/launch.json` (frontend dev server), this file.
- Shared `Pipeline/generate` Xano function so the endpoint and the agent's generate tool use one gated path (can't diverge).

## Failed attempts (what didn't work — don't repeat)

XanoScript has no full spec; these were learned the hard way and are the rules going forward:
- **Path-parameter routes 404 at runtime** on this Xano workspace even though they parse/deploy and show in Swagger (verified with a 100%-UI-generated test endpoint). **Rule: no path params — put identifiers in the request body/query.**
- **Invalid XanoScript that looked plausible:** `!` required-field suffix; `default=` inside `enum` (and on text fields); `else` after `if`; `foreach(list as $item){}` (real form is `foreach(list){ each as $item { ... } }`); reassigning a plain `var` across conditional branches (real pattern: `db.add ... as $x` inside each branch); `sort =` on `db.query` (no confirmed form — omit it).
- **`xano workspace pull` silently reverts local files** that map to pre-existing remote objects, and regenerates duplicate nested-folder files for any path with a `/`. After any pull: re-check edited files and sweep duplicate guids (`grep -rh "guid = " xano --include="*.xs" | sort | uniq -d`).
- **`str | None` needs Python 3.12** for the backend test venv (system 3.9 fails). Use `python3.12`; venv at `backend/.venv` (gitignored).
- Two `xano sandbox push` timeouts (`ECONNRESET`) on large batches — just retry.

## Next step

Run the **impeccable design pass** (part 3 of the M20 plan), in this order:
1. `/impeccable document` — record the incumbent `gb-*` system as `DESIGN.md` (needed as the audit baseline; without it audit/polish just churn).
2. `/impeccable audit` across the pipeline screens (`/documents`, `/advisor`) + existing pages.
3. `/impeccable polish` on what the audit surfaces. Flag any edits to *existing* (non-pipeline) pages before making them, so the pass doesn't quietly restyle the whole app.

Deferred / still open (not blocking the design pass):
- Real vendor keys (Nutrient/Doctavian/SerpApi/Foxit) → flip `VENDOR_MODE=live`; Foxit PDF Services (MCP, ≥4 tools) + real eSign; Doctavian Postman spike. (User expects keys within ~3 days.)
- M18 leftovers: `X-Sidecar-Key` Xano-side wiring; run `scripts/migrate_neon_to_xano.py`.
- Real multipart file upload (currently a text placeholder — Xano file-field syntax unconfirmed).
- M21 (submission package: 2 demo videos, 5 write-ups, clean-clone check) and M22 (decommission FastAPI state layer) — post-build.

## Test accounts (Xano, live workspace)

- Student: `m18-test@example.com` / `TestPass123`
- Advisor: `advisor@example.com` / `TestPass123` (user id 6, role manually set to `advisor`)
