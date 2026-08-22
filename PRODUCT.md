# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **International students settling into a US city** — the core audience across the whole app: pre-arrival planning, settlement tasks, local discovery, community, and eventually mentoring the next arrivals. Often non-native English speakers doing unfamiliar, high-stakes tasks under time pressure.
- **ISSS advisors / university international-student-office staff** — the second audience for the document pipeline (the workflow this rebuilds is Terra Dotta / Sunapsis / iStart). They process many students' documents and are the bottleneck the pipeline is designed to relieve.
- **Mentors** — graduated/settled students who opt in to help newcomers; the end state of the student lifecycle (newcomer → settler → local → mentor).

For the document pipeline specifically the design is **two-sided and balanced**: a consumer-grade student flow (upload → review flagged fields → sign) and an operational staff queue, designed as one system with two front doors.

## Product Purpose

A graph-powered community platform that helps international students settle into a US city — discover local culture, make friends, complete settlement tasks, and eventually mentor future arrivals; "a lifelong companion for the immigrant journey."

Its current build focus is an **AI document pipeline**: takes a student from "I have these documents" to "I have a signed, correct form" — extraction, human correction where the model is unsure, form generation, live policy verification, and signature — with a human in the loop wherever confidence is low or the stakes are high. First document type: the **I-20 → SSN support packet**. Success = a correct, current, signed document produced with far less advisor retyping than the incumbent workflow.

## Positioning

- **Whole product:** combines graph-ranked community matching, AI-guided settlement, and a mentor lifecycle for international students — a combination neighboring products don't offer together.
- **Document pipeline:** the incumbent (Terra Dotta, 700+ universities) already has document upload and eSign. The differentiator is **the middle**: machine extraction with per-field confidence, a calibrated escalation rule that routes only genuinely uncertain fields to a human (with a citation to the exact source region), and a live policy check that catches when a template has gone out of date. The defensible claim: *staff retype every field today; we escalate only the fraction that need a human.*

## Operating Context

- The international-student journey: pre-arrival → arrival → settlement → community → mentorship.
- ISSS offices operating under high student-to-staff ratios, staff turnover, and intensifying compliance expectations.
- Regulated immigration documents (I-20, passport, SSN support letter, offer letter, transcript) where a wrong field is a legal-status problem, not a typo.
- The **16 July 2026 DHS rule** ending Duration of Status for F-1/J-1, tying the admission period to the I-20's program-end date and cutting the post-completion OPT grace period from 60 to 30 days — a real, dated policy change the pipeline's live check is built to catch.
- A vendor pipeline: Nutrient DWS (extraction + confidence), Doctavian (form generation), SerpApi (live policy/processing-time data), Foxit (PDF assembly + eSign).

## Capabilities and Constraints

- **Backend:** Xano is the system of record for auth and the document pipeline (tables, gates, workflow, the runtime AI agent). A stateless FastAPI sidecar holds the Markdown knowledge graph, AI plan/bridge generation, and SSE chat. Neon Postgres still serves the not-yet-migrated app tables during transition.
- **Knowledge graph:** public city knowledge authored as Markdown + YAML frontmatter + `[[wikilinks]]`, compiled in-process (Chicago, Boston, NYC).
- **The confidence gate:** extracted fields below a 0.85 confidence threshold, plus always-review high-stakes fields (`sevis_id`, `program_end_date`, `funding_amount`), are routed to human review. Generation is refused server-side while any field needs review. The document agent calls the same gated path and therefore **cannot self-approve**.
- **Mock-first vendors:** the whole pipeline runs end-to-end in a mock mode with no vendor keys; live mode is a per-vendor flag flip.
- **Terminology:** "I-20", "SEVIS", "OPT", "ISSS", "F-1/J-1", "SSN support packet", "needs review / auto-accepted / confirmed".
- **Platform constraint:** confidence is Nutrient's *uncalibrated* signal — it must always be shown with its match label and cited source region, never as a bare probability.

## Brand Commitments

- **Name:** Globalदोस्त (also "GlobalBuddy"). The Devanagari "दोस्त" (Hindi/Urdu for *friend*) is part of the identity and appears in the product wordmark — the "friend / companion" framing is intentional and binding.
- **Existing design system:** a hand-authored `gb-*` CSS design system already in use across ~10 pages and ~13 components; future work preserves and extends it rather than replacing it wholesale.
- **Voice:** warm, reassuring, companion-like — settling in as a journey shared with a friend, not a bureaucratic portal.

## Evidence on Hand

- A working document pipeline (mock mode), verified end to end: upload → extract → confidence gate → human review → generate → live policy check (which forces re-review on a detected change) → sign, plus a runtime AI agent that refuses to generate/sign while review is pending.
- Real, structured Markdown city knowledge for Chicago, Boston, and New York.
- The 16 July 2026 DHS Duration-of-Status rule is a real, citable policy change.
- **No** fabricated testimonials, customers, pricing, benchmarks, or university partnerships — future work must not invent them.

## Product Principles

- **Human in the loop where it matters.** Escalate exactly the fields the model isn't sure about or that are too costly to get wrong; auto-accept the rest.
- **Correctness and trust over speed.** These are regulated, status-determining documents; the design must earn trust, not just move fast.
- **The agent cannot self-approve.** Automation drafts and routes; a person reviews and signs. Enforced in the backend, not just the UI.
- **Live over stale.** Prefer current policy/processing data to templates that were true when written.
- **A lifecycle, not a transaction.** Newcomer → settler → local → mentor; the product accompanies the whole arc.

## Accessibility & Inclusion

No formal standard (e.g. WCAG level) has been committed yet — recorded as **undecided**. However, the confirmed operating reality is that primary users are often **non-native English speakers** performing an unfamiliar, legally high-stakes task, so plain language, obvious affordances, and low cognitive load are product-relevant even absent a formal target.
