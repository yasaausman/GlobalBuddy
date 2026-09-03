## Inspiration

On **July 16, 2026** — five weeks before this hackathon — DHS finalized a rule that quietly rewired the life of every international student in the US. It ended "Duration of Status" for F-1 and J-1 visas, tied your legal status directly to one document, the **Form I-20**, and cut the post-graduation OPT grace period from 60 days to 30.

Translation: the I-20 stopped being paperwork. A single wrong field on it is now a *status* problem, not a typo — and every template, timeline, and fee sheet describing F-1 status became **wrong overnight**.

Then we looked at how universities actually handle these. The incumbent, **Terra Dotta**, is used at 700+ schools: a student uploads a scanned I-20, and a staff member **retypes every single field by hand**. In 2026. For a document where one mistake can cost someone their legal status.

The upload isn't the hard part. The signature isn't the hard part. **The middle is.** So we rebuilt the middle.

## What it does

GlobalBuddy takes an international student from *"here's my I-20"* to *"here's a signed, correct SSN support packet"* — and puts a human in the loop **only where it actually matters.**

1. **Extract** the I-20 into typed fields, each with a confidence score and a citation to the exact source region.
2. **Escalate only the uncertain fields** — the model auto-accepts what it's confident about and flags the rest for a person. High-stakes fields like SEVIS ID, program end date, and funding are *always* reviewed by a human, no matter how confident the model is.
3. **Generate** the support letter from the right branch-resolved template.
4. **Check the rules against live search** — and this is the moment that matters: a live SerpApi call finds the real July 2026 DHS rule and **pulls a field back to human review**, so the agent **refuses to sign**. Live data changed the machine's behavior in real time.
5. **Sign** it with a real Foxit eSignature.

It has two front doors: a consumer-grade student flow, and an operational **advisor queue** that shows — numerically, on screen — how much of the retyping the machine just eliminated. And the AI agent that drives the whole thing? From a plain prompt, it checks the review state, sees pending fields, and **refuses to generate or sign** until a human clears them. It literally cannot self-approve — enforced on the server, not just in the UI.

## How we built it

- **Xano** is the system of record — auth, tables, every confidence gate and branch, and the **runtime AI agent** — all authored as XanoScript, version-controlled in git, and deployed via the CLI. A no-code backend you can actually diff and review.
- **Nutrient DWS** does the extraction: real per-field confidence and bounding-box citations from the I-20.
- **SerpApi** powers the live policy check that catches the DHS rule change.
- **Foxit eSign** creates the real signature request.
- **Doctavian** shapes the generated document from a 4-way template branch.
- A stateless **FastAPI** sidecar handles the knowledge graph and chat; the front end is **React + Vite**.

## Challenges we ran into

- **XanoScript has no public spec.** We reverse-engineered the syntax for outbound HTTP (`api.request`) and environment variables (`$env.NAME`) by pushing to the live workspace and reading the errors — and discovered that path-parameter routes silently return 404 at runtime, so every identifier had to move into the request body.
- **Every vendor authenticated differently — each a small detective story.** SerpApi took a query param; Foxit unified eSign and PDF Services under one header credential (not the OAuth flow the docs implied); and Doctavian only delivered its generated file after we switched to a Microsoft-identity login that had proper cloud storage.
- **Reliability vs. reality.** Our live policy check originally fired three SerpApi calls and occasionally flaked inside the agent's tool timeout. We cut it to the one call that actually matters, and the full agent run went green every time.
- **Files are hard in a no-code backend.** Nutrient's extraction is file-upload-only, and moving binary files through Xano turned out to be the one genuinely deep gap — so extraction runs on fixtures that mirror the real API in the live flow, while the real call is proven separately.

## Accomplishments that we're proud of

- **Two live vendor calls, on camera:** the SerpApi policy check and the Foxit eSign signature are real API calls in the working agent flow — and the agent visibly **refuses to sign** when the live policy check flags a change.
- **The agent that can't self-approve.** The generation gate throws a 403 on the server while any field needs review, so automation drafts and routes but a person always reviews and signs.
- **We verified the hard vendors for real.** Nutrient returned every field of a real I-20 at 0.95 confidence with source citations; Doctavian generated from an uploaded template — both proven against their live APIs.
- **We didn't overclaim.** Every part of the submission is marked live, proven, or fixture — because in a status-determining product, honesty *is* the feature.
- **A reviewable, agent-driven backend built entirely as text in git.** Auth, gates, branches, and a tool-calling agent — no black-box no-code.

## What we learned

You can build a genuinely reviewable, no-code backend — auth, gates, branches, *and* a tool-calling AI agent — as text you commit and diff like any other code. But the biggest lesson is about the product itself: the hardest and most valuable part of an AI document tool isn't the model's accuracy. It's the **calibrated decision of when to trust the machine and when to hand it to a human** — and making that decision auditable, with a citation, every single time.

## What's next for GlobalBuddy

Real per-user file upload so Nutrient extraction and Foxit packet assembly run live *inside* the pipeline; the Nutrient DWS Viewer as the review surface so a reviewer sees confidence overlaid on the actual I-20; support for more document types beyond the I-20 → SSN packet; and the mentor lifecycle that turns yesterday's newcomers into the guides for tomorrow's arrivals. A lifelong companion for the immigrant journey — starting with the paperwork that decides whether you get to stay.
