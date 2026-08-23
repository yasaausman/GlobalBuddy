# Handoff — GlobalBuddy / Globalदोस्त

_Last updated: 22 Aug 2026. Base is committed + pushed to `origin/main` (HEAD `e40be9a`); the impeccable design pass (below) is applied to the working tree but **not yet committed**. Durable context also lives in `PLAN.md`, `PRODUCT.md`, and `docs/xano-document-pipeline-plan.md`._

## Goal

Ship the **ISSS document pipeline** for the DevNetwork [API + Cloud + AI] Hackathon 2026 (deadline **3 Sep 2026, 10:00am PDT**) across five tracks — Xano, Nutrient, Foxit, Doctavian, SerpApi. One codebase, five submissions. Framed as an AI-assisted rebuild of the university ISSS document workflow (Terra Dotta / Sunapsis): I-20 → signed SSN support packet, with a human in the loop wherever the model is unsure.

## Current state

- **M18 (Xano foundation): done + live-verified.** Xano is the system of record for auth + the pipeline; the app auths against Xano; 4 tables ported (`user` w/ role+stage, `user_documents`, `plan_progress`, `notifications`). Backend is version-controlled as XanoScript in `xano/`.
- **M19 (pipeline): done + live-verified end to end (mock mode).** upload → Nutrient extract → confidence gate → human review → Doctavian generate → SerpApi policy check (forces re-review on a detected change) → Foxit sign. Plus a **Xano Agent** that drives it from a plain prompt and **refuses to generate/sign while review is pending** (the Foxit centerpiece). A live HTTP contract test (`backend/tests/test_pipeline_contract.py`) passes.
- **M20 (frontend): functionally done + browser-verified.** `/documents` (student pipeline UI) and `/advisor` (role-gated review queue with the machine-vs-human "time saved" bar). `DocumentTracker` links to `/documents`. Shared `XanoLoginGate`.
- **Impeccable design skill** installed globally (`~/.claude/skills/impeccable`); hooks active; `PRODUCT.md` written via `/impeccable init`.

## Files in flight

Uncommitted (the design pass): `DESIGN.md` + `.impeccable/design.json` (new); `frontend/src/styles/global.css` (M20 block appended at end); `frontend/src/pages/DocumentsPage.jsx`, `frontend/src/pages/AdvisorQueuePage.jsx`, `frontend/src/components/XanoLoginGate.jsx`; this file. No existing CSS rules or non-pipeline pages were changed. Ready to commit as e.g. `feat(m20): impeccable design pass — DESIGN.md + pipeline polish`.

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

The **impeccable design pass** is DONE (not yet committed — working tree dirty):
1. `/impeccable document` → wrote `DESIGN.md` (North Star **"Clear Water"**, airy/floating) + `.impeccable/design.json` sidecar, capturing the incumbent `gb-*` system.
2. `/impeccable audit` of `/documents` + `/advisor` + login gate → **13/20** (Acceptable). Drivers: off-palette hard-coded state colors, unlabeled inputs, and inline-first styling on the two new pages.
3. `/impeccable polish` (scope confirmed with user: **pipeline files + additive shared CSS only** — no existing rules changed, other 10 pages untouched). Applied:
   - Appended an M20 pipeline block to `global.css` (state tokens `--gb-success/info/warn`, `.gb-doc-stepper`, `.gb-input/textarea/select`, `.gb-conf-bar`, `.gb-notice-warn`, `.gb-split-bar`, `.gb-collapse-toggle`, `prefers-reduced-motion` guard).
   - `DocumentsPage.jsx`: real gradient stepper w/ done/current/upcoming states; state colors → tokens; bare select/textarea/correction-input styled + labeled; inline SVG icons (check/alert/clock) replacing emoji; blocked/policy notices → `.gb-notice-warn`.
   - `AdvisorQueuePage.jsx`: split bar → teal/ochre tokens; collapsible group header → focus-ring + `aria-expanded` + rotating chevron SVG.
   - `XanoLoginGate.jsx`: inputs now wrapped in `<label>` (a11y association) + `autoComplete` + form gap.
   - **Verified live** in the preview against real Xano test accounts: advisor split bar (89%/11%), student field rows (auto-accepted=teal, needs-review=ochre) + confidence bars, blocked-generation notice, collapse/chevron, desktop + mobile reflow. Clean console, no build errors.

**Old-page cleanup (user later widened scope to "also clean up old pages"):** triaged the 6 detector findings in the incumbent CSS —
- **Fixed:** `.gb-plan-disclaimer` side-accent `border-left:3px` → 1px full hairline; chat typing indicator `gb-typing-bounce` → `gb-typing-pulse` (smoother ease-out, gentler bob).
- **Suppressed as sanctioned exceptions** (honest reasons in `frontend/.impeccable/config.json`, `layout-transition` ignoreValues): the 3 determinate progress-bar `transition:width` fills and the `.gb-journey-content` accordion `transition:max-height`. These are correct standard techniques; the detector fires generically.
- **Tried & reverted:** converting the accordion to `grid-template-rows:0fr↔1fr` — verified in-browser it left closed panels un-collapsed (29px sliver), and real content (~1263px) sits well under the existing 2800px cap, so the max-height version is correct. Reverted.

Still deferred (separate P3, untouched): dedupe the duplicate/conflicting `.gb-field` / `.gb-badge` / `.gb-doc-item` blocks in `global.css`.

Nothing committed yet.

Deferred / still open (not blocking the design pass):
- Real vendor keys (Nutrient/Doctavian/SerpApi/Foxit) → flip `VENDOR_MODE=live`; Foxit PDF Services (MCP, ≥4 tools) + real eSign; Doctavian Postman spike. (User expects keys within ~3 days.)
- M18 leftovers: `X-Sidecar-Key` Xano-side wiring; run `scripts/migrate_neon_to_xano.py`.
- Real multipart file upload (currently a text placeholder — Xano file-field syntax unconfirmed).
- M21 (submission package: 2 demo videos, 5 write-ups, clean-clone check) and M22 (decommission FastAPI state layer) — post-build.

## Test accounts (Xano, live workspace)

- Student: `m18-test@example.com` / `TestPass123`
- Advisor: `advisor@example.com` / `TestPass123` (user id 6, role manually set to `advisor`)
