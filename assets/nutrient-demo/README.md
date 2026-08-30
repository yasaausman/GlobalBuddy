# Nutrient DWS — live extraction evidence

A real call to the **Nutrient DWS Data Extraction API** against a synthetic I-20,
proving the pipeline's core Nutrient operation with genuine per-field confidence
and source citations. **No real student data; no API keys committed.**

## Files
- `sample-i20.pdf` — a synthetic, filled Form I-20 (fake data) generated for this test.
- `extraction-schema.json` — the JSON schema of the 10 I-20 fields we ask Nutrient to extract.
- `extraction-result.json` — the **real API response** from Nutrient.

## The call
```bash
curl -X POST https://api.nutrient.io/extraction/extract \
  -H "Authorization: Bearer $NUTRIENT_DWS_API_KEY" \
  -F file=@sample-i20.pdf \
  -F "instructions=$(cat extraction-schema.json)"
```

## Result (real, verified 30 Aug 2026)
All 10 fields extracted correctly, each with **confidence 0.95**, a **match label**
(`id_match` / `id_match_multiblock`), a **page number**, and **bounding boxes**
(`source_bboxes`) citing the exact region of the source document — 1 page,
~3.4s processing.

| Field | Value | Confidence | Match | Page |
|---|---|---|---|---|
| sevis_id | N0012345678 | 0.95 | id_match | 1 |
| student_full_name | ADITI SHARMA | 0.95 | id_match_multiblock | 1 |
| date_of_birth | 14 MARCH 2001 | 0.95 | id_match | 1 |
| country_of_citizenship | INDIA | 0.95 | id_match | 1 |
| visa_status | F-1 | 0.95 | id_match | 1 |
| school_name | University of Illinois Urbana-Champaign | 0.95 | id_match | 1 |
| program_of_study | Master of Science in Computer Science | 0.95 | id_match | 1 |
| program_end_date | 15 MAY 2028 | 0.95 | id_match | 1 |
| funding_source | Personal/Family Funds and Departmental Assistantship | 0.95 | id_match | 1 |
| funding_amount | USD 62,000 | 0.95 | id_match | 1 |

## Pipeline note
The Xano pipeline runs Nutrient in **mock mode** (seeded `vendor_fixtures`) because the
Data Extraction API is **multipart file-only** (no URL input) and Xano has no stored file
to forward — real file upload to Xano is deferred. This standalone call confirms the mock
fixtures faithfully mirror the real API's shape (value + confidence + match label + bbox +
page citation), so the confidence gate operates on realistic data. To wire it live end-to-end,
route extraction through the FastAPI sidecar (plan §5.4 "Fallback B"), which handles multipart
file upload natively.
