# GlobalBuddy — demo video narration script (timed, per screen)

Matches the take `globalbuddy-demo.mp4` — **1280×800, total ~2:51.** Segment times come from the real
scene-change timestamps in this video (verified against frames). Narration is sized to each screen's
on-screen duration at a natural pace (~2.5 words/sec) — read each block while that screen is up. Small
±1–2s drift is fine; watch the screen and let your voice follow it.

**Truthful about what the video proves (say nothing more than this):**
- **Live vendor calls on camera:** the **policy check is a real SerpApi call**; the **signature is a real Foxit eSign call**.
- **Fixtures in the flow:** the I-20 **extraction** (Nutrient) and **generation** (Doctavian) run on seeded data that mirrors the real APIs — both were verified live *separately* (Nutrient evidence in `assets/nutrient-demo/`). Don't claim the on-camera extraction is a live Nutrient call.
- Everything else — the confidence gate, review logic, the advisor queue — is real Xano backend logic.

---

### 1 · 0:00 – 0:10 — Sign-in gate  *(~10s, ~24 words)*
**On screen:** the "Document Center" login card.
> "This is GlobalBuddy — an AI pipeline that takes an international student from a raw I-20 to a signed SSN support packet, with a human in the loop wherever it matters."

### 2 · 0:10 – 0:17 — Pipeline loaded  *(~7s, ~17 words)*
**On screen:** the six-step stepper (Upload · Extract · Review · Generate · Policy check · Sign) and the Upload card.
> "Six stages, all running on a Xano backend: upload, extract, review, generate, a live policy check, and sign."

### 3 · 0:17 – 0:47 — Extraction & the confidence gate  *(~30s, ~72 words)*
**On screen:** "Extracted fields (6 of 12 need review)"; scrolling the fields — greens and ambers, confidence %, match labels, "source: p.1 body".
> "We upload the I-20 and extract it. Every field comes back with three things: a confidence score, a match label, and a citation to the exact region of the source document. The model auto-accepts what it's confident about — these greens — and flags the rest in amber. Notice we never show a bare percentage; confidence is an uncalibrated signal, so it's always paired with its match label and its citation."

### 4 · 0:47 – 1:26 — Review: escalate only the uncertain  *(~39s, ~95 words)*
**On screen:** confirming the flagged fields one by one (Confirm buttons; some 62% low-confidence, some 93% but always-review).
> "This is the whole idea. The incumbent — Terra Dotta, used at seven hundred–plus universities — makes a staff member retype every single field by hand. We escalate only the fraction the machine wasn't sure about. Some of these are low-confidence, sixty-two percent. Others are high-confidence but flagged anyway — SEVIS ID, program end date, funding — because after the July 2026 rule, a wrong value there is a legal-status problem, not a typo. So a human always confirms those. The reviewer resolves exactly what needed judgment, and nothing else."

### 5 · 1:26 – 1:38 — Generate the packet  *(~12s, ~29 words)*
**On screen:** "Generated"; "Variant f1_assistantship — resolved from F-1 + assistantship".
> "With review clear, we generate the SSN support letter. The template variant resolves automatically from the student's visa status and funding source — here, F-1 with an assistantship."

### 6 · 1:38 – 1:47 — Live policy check (SerpApi)  *(~9s, ~24 words)*
**On screen:** clicking "Run policy check"; the amber warning box appears with the DHS text and a "source" link.
> "Now the important part. Before we finish, we check the rules against live search — a real SerpApi call — because immigration policy actually changed this year."

### 7 · 1:47 – 1:53 — Live data forces re-review  *(~6s, ~15 words)*
**On screen:** the warning — "the final rule takes effect Sept 15, 2026…" + "A field was sent back to review."
> "It surfaces the real July 2026 DHS rule, and pulls the program-end-date field back to review."

### 8 · 1:53 – 2:11 — Sign (Foxit eSign)  *(~18s, ~44 words)*
**On screen:** resolving the re-flagged field, then "Send for signature" → "Signed — i20 tracker marked done."
> "A template that was correct last month is now out of date — so the human re-confirms the value against the new rule. And only now does it sign: a real Foxit eSign call creates the signature request. Automation drafted and routed; a person reviewed and signed."

### 9 · 2:11 – 2:20 — Switch to the advisor side  *(~9s, ~22 words)*
**On screen:** signing out → the advisor sign-in → the advisor dashboard loading.
> "That was the student's view. Now the staff side — the part we actually rebuilt, and where the value is."

### 10 · 2:20 – 2:51 — Advisor queue & time saved  *(~31s, ~74 words)*
**On screen:** the advisor queue — "Extraction cleared X of Y… machine-cleared" bar, then the grouped review list.
> "Here's the advisor's queue. The bar tells the story: extraction cleared most fields automatically, and only a fraction are escalated for a human — the time saved, right on screen. Everything's grouped by submission, every field carries its confidence and its citation, and each review is attributed to the advisor. Same product, two front doors: correctness and a human in the loop, at a fraction of the retyping. GlobalBuddy — extract it, escalate only what's uncertain, check the rules that changed last month, and get it signed, in one pass."

---

**Total narration ≈ 420 words over ~2:51.** If you run long on a block, the confidence-gate (3) and review (4) segments have the most slack to trim; the live-vendor beats (6–8) are the moments to slow down and emphasize.
