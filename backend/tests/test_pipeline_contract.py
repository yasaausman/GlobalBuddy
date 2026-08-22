"""M19 pipeline contract test -- drives the full mock flow against the live
Xano workspace and asserts the gate, branch resolution, policy re-review, and
signing all behave as designed.

This is an HTTP contract test, not a FastAPI TestClient test: the M19 pipeline
lives in Xano (docs/xano-document-pipeline-plan.md §6), so there is nothing to
mock in-process. It runs ONLY when XANO_TEST_BASE_URL is set, so CI stays green
without secrets -- and it needs zero *vendor* keys because the whole pipeline
runs in mock mode (VENDOR_MODE=mock).

Run:
    XANO_TEST_BASE_URL=https://xgnh-6ozi-vxez.n7e.xano.io \
      pytest backend/tests/test_pipeline_contract.py -v

Preconditions: the workspace has the M19 tables/endpoints deployed and the
"mixed" Nutrient fixture seeded (the test seeds it defensively at start).
Canonical API-group ids default to the current workspace's; override via env
if the groups are recreated.
"""

from __future__ import annotations

import os
import uuid

import httpx
import pytest

BASE = os.environ.get("XANO_TEST_BASE_URL", "").rstrip("/")
AUTH = os.environ.get("XANO_AUTH_CANONICAL", "_WAlCa0m")
DOCS = os.environ.get("XANO_DOCS_CANONICAL", "PyL7dgs4")
FIXT = os.environ.get("XANO_FIXTURES_CANONICAL", "H-EynE3L")

pytestmark = pytest.mark.skipif(
    not BASE, reason="XANO_TEST_BASE_URL not set -- live Xano contract test skipped"
)

# The 3 always-review keys plus the 3 low-confidence keys => 6 needs_review.
_LOW_CONF = {"program_of_study", "student_full_name", "date_of_birth"}
_ALWAYS_REVIEW = {"sevis_id", "program_end_date", "funding_amount"}
_I20 = [
    ("sevis_id", "SEVIS ID", "N0012345678"),
    ("school_name", "School Name", "Northeastern University"),
    ("school_code", "School Code", "BOS214F00123000"),
    ("program_start_date", "Program Start", "2026-09-01"),
    ("program_end_date", "Program End", "2028-05-15"),
    ("program_of_study", "Program of Study", "Computer Science"),
    ("funding_source", "Funding Source", "assistantship"),
    ("funding_amount", "Funding Amount", "42000"),
    ("student_full_name", "Student Name", "Contract Test User"),
    ("date_of_birth", "Date of Birth", "2001-03-14"),
    ("country_of_citizenship", "Country of Citizenship", "India"),
    ("visa_status", "Visa Status", "F-1"),
]


def _mixed_fixture() -> dict:
    fields = []
    for key, label, value in _I20:
        conf = 0.62 if key in _LOW_CONF else 0.93
        fields.append({
            "field_key": key, "field_label": label, "value_text": value,
            "confidence": conf, "match_label": "partial" if key in _LOW_CONF else "exact",
            "page": 1, "bbox": {"x": 10, "y": 20, "w": 100, "h": 15},
            "citation": {"page": 1, "region": "body"},
        })
    return {"fields": fields}


@pytest.fixture(scope="module")
def client() -> httpx.Client:
    with httpx.Client(timeout=120.0) as c:
        yield c


@pytest.fixture(scope="module")
def token(client: httpx.Client) -> str:
    # Fresh throwaway user each run -> idempotent (no "email exists" collision).
    email = f"contract-{uuid.uuid4().hex[:12]}@example.com"
    r = client.post(f"{BASE}/api:{AUTH}/auth/signup",
                    json={"name": "Contract Test User", "email": email, "password": "TestPass123"})
    assert r.status_code == 200, f"signup failed: {r.text}"
    body = r.json()
    assert "token" in body and body["user"]["role"] == "student"
    return body["token"]


@pytest.fixture(scope="module", autouse=True)
def seed_fixture(client: httpx.Client) -> None:
    # Defensive: ensure the "mixed" scenario exists. Duplicates are harmless --
    # extraction reads it with return=single.
    client.post(f"{BASE}/api:{FIXT}/vendor-fixtures/add",
                json={"vendor": "nutrient", "scenario": "mixed", "payload": _mixed_fixture()})


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_full_pipeline_contract(client: httpx.Client, token: str) -> None:
    h = _h(token)

    # 1. upload
    r = client.post(f"{BASE}/api:{DOCS}/documents/upload", headers=h, json={"doc_type": "i20"})
    assert r.status_code == 200, r.text
    upload_id = r.json()["id"]

    # 2. extract (mixed) -> succeeded
    r = client.post(f"{BASE}/api:{DOCS}/documents/extract", headers=h,
                    json={"upload_id": upload_id, "scenario": "mixed"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "succeeded"

    # 3. confidence gate: exactly the 3 low-conf + 3 always-review = 6 need review
    r = client.get(f"{BASE}/api:{DOCS}/documents/review", headers=h, params={"upload_id": upload_id})
    assert r.status_code == 200, r.text
    review_fields = r.json()["fields"]
    flagged_keys = {f["field_key"] for f in review_fields}
    assert flagged_keys == _LOW_CONF | _ALWAYS_REVIEW, flagged_keys
    assert len(review_fields) == 6

    # 4. THE GATE: generation refused while fields need review
    r = client.post(f"{BASE}/api:{DOCS}/documents/generate", headers=h, json={"upload_id": upload_id})
    assert r.status_code == 403, f"gate should reject, got {r.status_code}: {r.text}"

    # 5. review all 6
    for f in review_fields:
        rr = client.post(f"{BASE}/api:{DOCS}/documents/fields/review", headers=h,
                         json={"field_id": f["id"], "action": "confirmed"})
        assert rr.status_code == 200, rr.text

    # 6. review queue now empty
    r = client.get(f"{BASE}/api:{DOCS}/documents/review", headers=h, params={"upload_id": upload_id})
    assert len(r.json()["fields"]) == 0

    # 7. generate now succeeds, correct branch (F-1 + assistantship)
    r = client.post(f"{BASE}/api:{DOCS}/documents/generate", headers=h, json={"upload_id": upload_id})
    assert r.status_code == 200, r.text
    form = r.json()
    assert form["template_variant"] == "f1_assistantship", form
    form_id = form["id"]

    # 8. policy check forces program_end_date back to review (once)
    r = client.post(f"{BASE}/api:{DOCS}/documents/policy-check", headers=h,
                    json={"form_generation_id": form_id})
    assert r.status_code == 200, r.text
    assert r.json()["forced_field_review"] is not None, "policy change should force re-review"

    r = client.get(f"{BASE}/api:{DOCS}/documents/review", headers=h, params={"upload_id": upload_id})
    forced = r.json()["fields"]
    assert len(forced) == 1 and forced[0]["field_key"] == "program_end_date", forced

    # 9. re-review the forced field
    rr = client.post(f"{BASE}/api:{DOCS}/documents/fields/review", headers=h,
                     json={"field_id": forced[0]["id"], "action": "confirmed"})
    assert rr.status_code == 200, rr.text

    # 10. policy check again does NOT re-flag (once-only guard) -> signing reachable
    r = client.post(f"{BASE}/api:{DOCS}/documents/policy-check", headers=h,
                    json={"form_generation_id": form_id})
    assert r.json()["forced_field_review"] is None, "re-check must not re-flag after re-review"

    # 11. sign -> signed, and the loop closes into user_documents
    r = client.post(f"{BASE}/api:{DOCS}/documents/sign", headers=h,
                    json={"form_generation_id": form_id})
    assert r.status_code == 200, r.text
    signed = r.json()
    assert signed["status"] == "signed"
    assert signed["document_status"] == "done"


def test_agent_refuses_then_completes(client: httpx.Client, token: str) -> None:
    """The Foxit-track centerpiece: a plain prompt, agent refuses to generate
    while review is pending, then completes after review."""
    h = _h(token)

    r = client.post(f"{BASE}/api:{DOCS}/documents/upload", headers=h, json={"doc_type": "i20"})
    upload_id = r.json()["id"]
    client.post(f"{BASE}/api:{DOCS}/documents/extract", headers=h,
                json={"upload_id": upload_id, "scenario": "mixed"})

    # Agent, plain prompt, with fields pending -> must NOT generate/sign
    r = client.post(f"{BASE}/api:{DOCS}/documents/agent", headers=h,
                    json={"prompt": "Process my I-20 and sign the packet.", "upload_id": upload_id})
    assert r.status_code == 200, r.text
    steps = r.json()["result"]["steps"]
    tools_called = [c["toolName"] for s in steps for c in s.get("content", []) if c.get("type") == "tool-call"]
    assert "agent_review_status" in tools_called
    # The agent must not have signed anything while review was pending.
    assert "agent_sign" not in tools_called, f"agent should not sign with pending review: {tools_called}"
