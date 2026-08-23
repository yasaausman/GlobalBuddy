// M20: the document-pipeline surface. Self-contained Xano session (its own
// login), then the full flow: upload -> extract -> review -> generate ->
// policy check -> sign. Plus an agent console that drives the same pipeline
// from a plain prompt. Reuses the existing gb-* design system.
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  xanoLogin, xanoSignup, xanoLogout,
  uploadDocument, runExtraction, getExtraction, getReviewQueue,
  submitReview, generateForm, policyCheck, signForm, runAgent,
} from "../api/documentsApi.js";
import { getXanoToken } from "../api/xanoClient.js";
import XanoLoginGate from "../components/XanoLoginGate.jsx";

const STAGES = ["Upload", "Extract", "Review", "Generate", "Policy check", "Sign"];

function errText(e, fallback) {
  return e?.response?.data?.message || e?.response?.data?.detail || e?.message || fallback;
}

// Maps a field's review state to a palette state class (never color-only:
// every use is paired with the state's label text).
function stateClass(state) {
  if (state === "auto_accepted" || state === "confirmed") return "gb-state-ok";
  if (state === "corrected") return "gb-state-info";
  return "gb-state-warn"; // needs_review
}
// Resolved token color for the confidence-bar fill.
function stateVar(state) {
  if (state === "auto_accepted" || state === "confirmed") return "var(--gb-success)";
  if (state === "corrected") return "var(--gb-info)";
  return "var(--gb-warn)";
}

// --- Icons (16px, 1.5 stroke, currentColor) ---------------------------------
const iconProps = { width: 16, height: 16, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 1.75, strokeLinecap: "round", strokeLinejoin: "round", "aria-hidden": true };
const CheckIcon = () => (<svg {...iconProps}><path d="M20 6 9 17l-5-5" /></svg>);
const AlertIcon = () => (<svg {...iconProps}><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" /><path d="M12 9v4" /><path d="M12 17h.01" /></svg>);
const ClockIcon = () => (<svg {...iconProps}><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></svg>);

// --- Stepper -----------------------------------------------------------------
function Stepper({ current }) {
  return (
    <ol className="gb-doc-stepper" aria-label="Document pipeline progress">
      {STAGES.map((s, i) => {
        const state = i < current ? "done" : i === current ? "current" : "upcoming";
        return (
          <li key={s} data-state={state} aria-current={state === "current" ? "step" : undefined}>
            <span className="gb-doc-stepper__num">{i + 1}</span>{s}
          </li>
        );
      })}
    </ol>
  );
}

// --- Extraction results + inline review -------------------------------------
function FieldRow({ field, onReview }) {
  const [editing, setEditing] = useState(false);
  const [val, setVal] = useState(field.value_text || "");
  const pct = Math.round((field.confidence ?? 0) * 100);
  const needs = field.review_state === "needs_review";
  const label = field.field_label || field.field_key;

  return (
    <li className="gb-doc-item" style={{ display: "block", padding: "0.6rem 0", borderBottom: "1px solid var(--gb-border)" }}>
      <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", alignItems: "baseline" }}>
        <span className="gb-doc-label" style={{ fontWeight: 600 }}>{label}</span>
        <span className={stateClass(field.review_state)} style={{ fontSize: "0.75rem", fontWeight: 700 }}>
          {pct}% · {field.match_label || "—"} · {field.review_state.replace("_", " ")}
        </span>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", marginTop: "0.3rem" }}>
        {editing
          ? <input className="gb-input" aria-label={`Correct ${label}`} value={val} onChange={(e) => setVal(e.target.value)} style={{ flex: 1 }} />
          : <span style={{ flex: 1, color: "var(--gb-muted)" }}>{field.value_text}</span>}
        {/* confidence meter */}
        <div className="gb-conf-bar" role="img" aria-label={`${pct}% confidence`}>
          <span style={{ width: `${pct}%`, background: stateVar(field.review_state) }} />
        </div>
      </div>
      {needs && (
        <div style={{ display: "flex", gap: "0.4rem", marginTop: "0.5rem", flexWrap: "wrap" }}>
          {!editing && <button className="gb-btn gb-btn-sm gb-btn-secondary" onClick={() => onReview(field, "confirmed")}>Confirm</button>}
          {!editing && <button className="gb-btn gb-btn-sm gb-btn-ghost" onClick={() => setEditing(true)}>Correct</button>}
          {editing && <button className="gb-btn gb-btn-sm gb-btn-primary" onClick={() => onReview(field, "corrected", val)}>Save</button>}
          {editing && <button className="gb-btn gb-btn-sm gb-btn-ghost" onClick={() => { setEditing(false); setVal(field.value_text || ""); }}>Cancel</button>}
          <button className="gb-btn gb-btn-sm gb-btn-ghost" onClick={() => onReview(field, "rejected")}>Reject</button>
          {field.citation?.page && (
            <span style={{ fontSize: "0.72rem", color: "var(--gb-muted)", alignSelf: "center" }}>
              source: p.{field.citation.page} {field.citation.region}
            </span>
          )}
        </div>
      )}
    </li>
  );
}

// --- Agent console -----------------------------------------------------------
function AgentConsole({ uploadId }) {
  const [prompt, setPrompt] = useState("Process my I-20 and generate the SSN support packet.");
  const [busy, setBusy] = useState(false);
  const [trace, setTrace] = useState([]);
  const [finalMsg, setFinalMsg] = useState("");
  const [error, setError] = useState(null);

  const send = async () => {
    if (!uploadId) { setError("Upload a document first."); return; }
    setBusy(true); setError(null); setTrace([]); setFinalMsg("");
    try {
      const data = await runAgent({ prompt, uploadId });
      const steps = data?.result?.steps || [];
      const calls = [];
      steps.forEach((s) => (s.content || []).forEach((c) => {
        if (c.type === "tool-call") calls.push(c.toolName);
      }));
      setTrace(calls);
      setFinalMsg(data?.result?.result || "(no message)");
    } catch (err) {
      setError(errText(err, "Agent run failed."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1.5rem" }}>
      <h3 className="gb-section-title" style={{ marginTop: 0 }}>AI Agent</h3>
      <p style={{ color: "var(--gb-muted)", marginTop: 0, fontSize: "0.85rem" }}>
        Drive the whole pipeline from a plain instruction. The agent will refuse to generate or sign while fields need review.
      </p>
      <label className="gb-field" style={{ marginTop: "0.25rem" }}>
        <span>Instruction</span>
        <textarea className="gb-textarea" value={prompt} onChange={(e) => setPrompt(e.target.value)} rows={2} />
      </label>
      <button className="gb-btn gb-btn-primary gb-btn-sm" style={{ marginTop: "0.6rem" }} onClick={send} disabled={busy}>
        {busy ? "Agent working…" : "Run agent"}
      </button>
      {error && <p className="gb-auth-error" role="alert">{error}</p>}
      {trace.length > 0 && (
        <div style={{ marginTop: "0.75rem", fontSize: "0.8rem" }}>
          <strong>Tool calls:</strong>
          <ol style={{ margin: "0.3rem 0" }}>{trace.map((t, i) => <li key={i}><code>{t}</code></li>)}</ol>
        </div>
      )}
      {finalMsg && (
        <div style={{ marginTop: "0.5rem", padding: "0.75rem", background: "var(--gb-surface)", border: "1px solid var(--gb-border)", borderRadius: "var(--gb-radius-sm)", whiteSpace: "pre-wrap", fontSize: "0.88rem" }}>
          {finalMsg}
        </div>
      )}
    </div>
  );
}

// --- Main page ---------------------------------------------------------------
export default function DocumentsPage() {
  const [authed, setAuthed] = useState(() => Boolean(getXanoToken()));
  const [scenario, setScenario] = useState("mixed");
  const [uploadId, setUploadId] = useState(null);
  const [fields, setFields] = useState([]);
  const [form, setForm] = useState(null);
  const [policy, setPolicy] = useState(null);
  const [signature, setSignature] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const pending = useMemo(() => fields.filter((f) => f.review_state === "needs_review"), [fields]);

  const refreshFields = useCallback(async (id) => {
    const data = await getExtraction(id);
    setFields(data.fields || []);
  }, []);

  const stage = useMemo(() => {
    if (signature) return 5;
    if (policy) return 4;
    if (form) return 3;
    if (fields.length && pending.length === 0) return 3;
    if (fields.length) return 2;
    if (uploadId) return 1;
    return 0;
  }, [uploadId, fields, pending, form, policy, signature]);

  const doUpload = async () => {
    setBusy(true); setError(null);
    setFields([]); setForm(null); setPolicy(null); setSignature(null);
    try {
      const up = await uploadDocument("i20");
      setUploadId(up.id);
      await runExtraction(up.id, scenario);
      await refreshFields(up.id);
    } catch (e) { setError(errText(e, "Upload/extraction failed.")); }
    finally { setBusy(false); }
  };

  const doReview = async (field, action, newValue) => {
    try {
      await submitReview({ fieldId: field.id, action, newValue });
      await refreshFields(uploadId);
    } catch (e) { setError(errText(e, "Review failed.")); }
  };

  const doGenerate = async () => {
    setBusy(true); setError(null);
    try { setForm(await generateForm(uploadId)); }
    catch (e) { setError(errText(e, "Generation refused.")); }
    finally { setBusy(false); }
  };

  const doPolicy = async () => {
    setBusy(true); setError(null);
    try {
      const p = await policyCheck(form.id);
      setPolicy(p);
      if (p.forced_field_review) await refreshFields(uploadId); // a field bounced back to review
    } catch (e) { setError(errText(e, "Policy check failed.")); }
    finally { setBusy(false); }
  };

  const doSign = async () => {
    setBusy(true); setError(null);
    try { setSignature(await signForm(form.id)); }
    catch (e) { setError(errText(e, "Signing failed.")); }
    finally { setBusy(false); }
  };

  if (!authed) return <div className="gb-app"><XanoLoginGate title="Document Center" blurb="Sign in to upload and process your I-20." onAuthed={() => setAuthed(true)} /></div>;

  return (
    <div className="gb-app" style={{ maxWidth: 860, margin: "0 auto", padding: "1.5rem" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1 className="gb-section-title" style={{ margin: 0 }}>I-20 → SSN Support Packet</h1>
        <button className="gb-btn gb-btn-ghost gb-btn-sm" onClick={() => { xanoLogout(); setAuthed(false); }}>Sign out</button>
      </div>

      <div style={{ margin: "1rem 0" }}><Stepper current={stage} /></div>
      {error && <p className="gb-auth-error" role="alert">{error}</p>}

      {/* Upload */}
      <div className="gb-card" style={{ padding: "1.25rem" }}>
        <h3 className="gb-section-title" style={{ marginTop: 0 }}>1. Upload</h3>
        <label className="gb-field" style={{ maxWidth: 320 }}>
          <span>Mock scenario</span>
          <select className="gb-select" value={scenario} onChange={(e) => setScenario(e.target.value)}>
            <option value="mixed">Mixed (some low-confidence)</option>
            <option value="high_confidence">High confidence</option>
          </select>
        </label>
        <div>
          <button className="gb-btn gb-btn-primary" style={{ marginTop: "0.6rem" }} onClick={doUpload} disabled={busy}>
            {busy ? "Processing…" : "Upload I-20 & extract"}
          </button>
        </div>
      </div>

      {/* Extraction + review */}
      {fields.length > 0 && (
        <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
          <h3 className="gb-section-title" style={{ marginTop: 0 }}>
            2. Extracted fields <span style={{ fontWeight: 400, color: "var(--gb-muted)", fontSize: "0.85rem" }}>
              ({pending.length} of {fields.length} need review)
            </span>
          </h3>
          <p style={{ fontSize: "0.8rem", color: "var(--gb-muted)", marginTop: 0 }}>
            Confidence is Nutrient's uncalibrated signal — pair it with the match label and cited region, never a bare percentage.
          </p>
          <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
            {fields.map((f) => <FieldRow key={f.id} field={f} onReview={doReview} />)}
          </ul>
        </div>
      )}

      {/* Generate */}
      {fields.length > 0 && (
        <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
          <h3 className="gb-section-title" style={{ marginTop: 0 }}>3. Generate</h3>
          {pending.length > 0
            ? <p className="gb-notice-warn"><AlertIcon /> Generation is blocked until all {pending.length} flagged field{pending.length !== 1 ? "s are" : " is"} reviewed.</p>
            : <button className="gb-btn gb-btn-primary" onClick={doGenerate} disabled={busy || Boolean(form)}>
                {form ? "Generated" : "Generate packet"}
              </button>}
          {form && (
            <p style={{ marginTop: "0.6rem", fontSize: "0.88rem" }}>
              Variant <strong>{form.template_variant}</strong> — resolved from{" "}
              {form.branch_inputs?.visa_status} + {form.branch_inputs?.funding_source}
            </p>
          )}
        </div>
      )}

      {/* Policy check */}
      {form && (
        <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
          <h3 className="gb-section-title" style={{ marginTop: 0 }}>4. Live policy check</h3>
          <button className="gb-btn gb-btn-secondary" onClick={doPolicy} disabled={busy}>Run policy check</button>
          {policy && (
            <div style={{ marginTop: "0.75rem", fontSize: "0.85rem", display: "grid", gap: "0.5rem" }}>
              <p style={{ margin: 0, display: "flex", alignItems: "center", gap: "0.4rem", color: "var(--gb-muted)" }}>
                <ClockIcon /> {policy.processing_time?.result?.summary || policy.processing_time?.source_title}
              </p>
              {policy.policy_change?.result?.policy_change_detected && (
                <p className="gb-notice-warn">
                  <AlertIcon />
                  <span>{policy.policy_change.result.summary}{" "}
                    <a href={policy.policy_change.source_url} target="_blank" rel="noopener noreferrer">source</a>
                  </span>
                </p>
              )}
              {policy.forced_field_review && (
                <p className="gb-state-warn" style={{ margin: 0, fontWeight: 700 }}>
                  A field was sent back to review — resolve it above before signing.
                </p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Sign */}
      {form && (
        <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
          <h3 className="gb-section-title" style={{ marginTop: 0 }}>5. Sign</h3>
          {pending.length > 0
            ? <p className="gb-notice-warn"><AlertIcon /> Resolve the flagged field{pending.length !== 1 ? "s" : ""} before signing.</p>
            : <button className="gb-btn gb-btn-primary" onClick={doSign} disabled={busy || Boolean(signature)}>
                {signature ? "Signed" : "Send for signature"}
              </button>}
          {signature && (
            <p className="gb-state-ok" style={{ marginTop: "0.6rem", display: "flex", alignItems: "center", gap: "0.4rem", fontWeight: 700 }}>
              <CheckIcon /> Signed — {signature.doc_type} tracker marked {signature.document_status}.
            </p>
          )}
        </div>
      )}

      <AgentConsole uploadId={uploadId} />
    </div>
  );
}
