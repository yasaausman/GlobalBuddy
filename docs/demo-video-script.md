# GlobalBuddy — demo video voiceover script

Recorded take: `globalbuddy-demo.mp4` (1280×800, ~2:53, silent screen capture — read this over it).

**What's real vs mock in THIS take (be truthful):**
- **Live vendor calls on camera:** the **policy check is a real SerpApi call**, and the **signature is a real Foxit eSign call** (both hit the vendors' live APIs through the Xano backend).
- **Mock/fixture:** the I-20 **extraction** uses seeded fixtures (Xano `vendor_fixtures`) — Nutrient's extraction API is multipart-file-only and the pipeline has no stored file, so the flow uses fixtures that mirror the real API's shape. (Real Nutrient extraction with live confidence + citations was verified separately; evidence in `assets/nutrient-demo/`.) Doctavian generation is likewise fixture in the flow (real generate call verified separately).
- Everything else — the confidence gate, the review logic, the agent's refusal rules, the advisor queue — is **real Xano backend logic**, not staged.

Timestamps are approximate; glance at the screen and let the narration follow.

| Time | Visual | Narration |
|---|---|---|
| 0:00 | "Document Center" sign-in | "This is GlobalBuddy's document pipeline. It takes an international student from a raw I-20 to a signed SSN support packet — escalating to a human only where it matters." |
| 0:10 | Signed in; the 6-step pipeline stepper | "Six stages: upload, extract, review, generate, a live policy check, and sign — all running on a Xano backend." |
| 0:15 | Click "Upload I-20 & extract"; fields load | "We upload the I-20 and extract it. Every field comes back with a confidence score, a match label, and a citation to the exact source region." |
| 0:25 | Scrolling the extracted fields — greens and ambers | "The model auto-accepts what it's confident about — shown in green — and flags the rest in amber for a human." |
| 0:40 | Point at SEVIS ID / Program End (93%, needs review) | "Notice these: high confidence, but still flagged. SEVIS ID, program end date, and funding are always-review fields — a wrong value here is a legal-status problem, so a person always checks them. That's Nutrient's own recommendation, not our opinion." |
| 0:55 | Clicking "Confirm" down the list | "The reviewer resolves exactly the fields that needed judgment — not all twelve, just the ones the machine wasn't sure about." |
| 1:10 | Click "Generate packet"; variant appears | "With review clear, we generate the SSN support letter. The template variant resolves from the student's visa status and funding source." |
| 1:20 | Click "Run policy check" | "Now the important part. Before we finish, we check the rules against live search — because immigration policy changes." |
| 1:30 | The policy-change warning + DHS source appears | "This is a **real, live SerpApi call**. It surfaces the July 2026 DHS rule that tied a student's status to the I-20 — and the system pulls the program-end-date field **back to review**. Live data just changed the workflow." |
| 1:45 | Re-flagged field; click Confirm | "A template that was correct last month is now out of date. The human re-confirms the current value against the new rule." |
| 1:55 | Click "Send for signature"; "Signed" confirmation | "And only now does it sign — a **real Foxit eSign call** creates the signature request. Automation drafted and routed; a person reviewed and signed." |
| 2:10 | Sign out → advisor login → advisor queue | "That's the student side. Here's the staff side — the part we actually rebuilt." |
| 2:25 | "Extraction cleared X of Y… machine-cleared" bar | "The incumbent makes an advisor retype every field. Here, extraction clears most of them automatically, and the queue shows exactly what's left for a human — with the time saved, on screen." |
| 2:40 | Scrolling the grouped review queue | "Grouped by submission, every field with its confidence and citation, attributed to the reviewer. Correctness and a human in the loop — at a fraction of the retyping." |
| 2:50 | Final frame | "GlobalBuddy: extract it, escalate only what the model isn't sure about, check the rules that changed last month, and get it signed — in one pass." |

## Recording notes (how it was made)
- Web app driven headlessly with Playwright (video → `.webm` → `.mp4` via ffmpeg). Frontend on `localhost:5173`, Xano backend live.
- The policy-check and sign steps have retry logic in the capture script, since they make live vendor calls; this take completed both on the first attempt.
- For a 100%-deterministic alternate take, set `SERPAPI_MODE`/`FOXIT_MODE` to mock in Xano (the visuals are identical — the mock policy check still shows the DHS text).
