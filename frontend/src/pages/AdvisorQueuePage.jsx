// M20 §7.3: the ISSS advisor queue. Operate-mode staff surface -- scanability
// and throughput over expression. Shows the machine-vs-human split (the
// "time saved" story) as one honest statement + a proportion bar, then the
// review queue grouped by student submission, oldest first. Role-gated
// server-side; a signed-in non-advisor sees a clear "not an advisor" state.
import { useCallback, useEffect, useMemo, useState } from "react";
import { advisorQueue, advisorReview, xanoLogout } from "../api/documentsApi.js";
import { getXanoToken } from "../api/xanoClient.js";
import XanoLoginGate from "../components/XanoLoginGate.jsx";

function errText(e, fallback) {
  return e?.response?.data?.message || e?.response?.data?.detail || e?.message || fallback;
}

function SubmissionGroup({ uploadId, fields, onReview }) {
  const [open, setOpen] = useState(true);
  return (
    <div style={{ borderTop: "1px solid var(--gb-border,#e5e5e5)", padding: "0.9rem 0" }}>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        style={{ all: "unset", cursor: "pointer", display: "flex", justifyContent: "space-between", width: "100%", alignItems: "baseline" }}
      >
        <span style={{ fontWeight: 600 }}>Student #{fields[0]?.user_id} · upload {uploadId}</span>
        <span style={{ fontSize: "0.82rem", color: "#b45309" }}>{fields.length} field{fields.length !== 1 ? "s" : ""} to review {open ? "▲" : "▼"}</span>
      </button>
      {open && (
        <ul style={{ listStyle: "none", padding: 0, margin: "0.6rem 0 0" }}>
          {fields.map((f) => (
            <li key={f.id} style={{ padding: "0.5rem 0", borderTop: "1px dashed var(--gb-border,#eee)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", alignItems: "baseline" }}>
                <span style={{ fontWeight: 600 }}>{f.field_label || f.field_key}</span>
                <span style={{ fontSize: "0.75rem", color: "#b45309" }}>
                  {Math.round((f.confidence ?? 0) * 100)}% · {f.match_label || "—"}
                  {f.citation?.page ? ` · src p.${f.citation.page} ${f.citation.region}` : ""}
                </span>
              </div>
              <div style={{ color: "var(--gb-muted)", margin: "0.15rem 0 0.4rem" }}>{f.value_text}</div>
              <div style={{ display: "flex", gap: "0.4rem", flexWrap: "wrap" }}>
                <button className="gb-btn gb-btn-sm gb-btn-secondary" onClick={() => onReview(f, "confirmed")}>Confirm</button>
                <button className="gb-btn gb-btn-sm gb-btn-ghost" onClick={() => onReview(f, "rejected")}>Reject</button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default function AdvisorQueuePage() {
  const [authed, setAuthed] = useState(() => Boolean(getXanoToken()));
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [notAdvisor, setNotAdvisor] = useState(false);

  const load = useCallback(async () => {
    setLoading(true); setError(null); setNotAdvisor(false);
    try {
      setData(await advisorQueue());
    } catch (e) {
      if (e?.response?.status === 403) setNotAdvisor(true);
      else setError(errText(e, "Could not load the queue."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { if (authed) load(); }, [authed, load]);

  const grouped = useMemo(() => {
    const map = new Map();
    (data?.pending || []).forEach((f) => {
      if (!map.has(f.upload_id)) map.set(f.upload_id, []);
      map.get(f.upload_id).push(f);
    });
    // oldest submission first (lowest upload id)
    return [...map.entries()].sort((a, b) => a[0] - b[0]);
  }, [data]);

  const doReview = async (field, action) => {
    try {
      await advisorReview({ fieldId: field.id, action });
      await load();
    } catch (e) { setError(errText(e, "Review failed.")); }
  };

  if (!authed) {
    return (
      <div className="gb-app">
        <XanoLoginGate
          title="ISSS advisor sign-in"
          blurb="Sign in with your advisor account to review escalated fields."
          allowSignup={false}
          onAuthed={() => setAuthed(true)}
        />
      </div>
    );
  }

  const s = data?.stats;
  const machine = s ? s.auto_accepted + s.confirmed + s.corrected : 0;
  const human = s ? s.needs_review : 0;
  const total = machine + human;
  const machinePct = total ? Math.round((machine / total) * 100) : 0;

  return (
    <div className="gb-app" style={{ maxWidth: 820, margin: "0 auto", padding: "1.5rem" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1 className="gb-section-title" style={{ margin: 0 }}>Advisor review queue</h1>
        <button className="gb-btn gb-btn-ghost gb-btn-sm" onClick={() => { xanoLogout(); setAuthed(false); }}>Sign out</button>
      </div>

      {notAdvisor && (
        <div className="gb-card" style={{ padding: "1.5rem", marginTop: "1rem" }}>
          <p style={{ margin: 0 }}>This account isn't an advisor. Ask an administrator to grant the advisor role, then reload.</p>
        </div>
      )}
      {error && <p className="gb-auth-error" role="alert" style={{ marginTop: "1rem" }}>{error}</p>}

      {!notAdvisor && s && (
        <>
          {/* time-saved story: one honest statement + a proportion bar */}
          <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
            <p style={{ margin: "0 0 0.6rem" }}>
              Extraction cleared <strong>{machine}</strong> of <strong>{total}</strong> fields automatically —
              you review the <strong>{human}</strong> that need human judgment.
            </p>
            <div style={{ display: "flex", height: 10, borderRadius: 5, overflow: "hidden", background: "var(--gb-border,#eee)" }}>
              <div style={{ width: `${machinePct}%`, background: "#1a7f4b" }} title={`${machinePct}% machine-cleared`} />
              <div style={{ width: `${100 - machinePct}%`, background: "#b45309" }} title={`${100 - machinePct}% escalated`} />
            </div>
            <p style={{ margin: "0.5rem 0 0", fontSize: "0.8rem", color: "var(--gb-muted)" }}>
              {machinePct}% machine-cleared · {100 - machinePct}% escalated to you
            </p>
          </div>

          <div className="gb-card" style={{ padding: "1.25rem", marginTop: "1rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h2 className="gb-section-title" style={{ margin: 0 }}>Waiting for review</h2>
              <button className="gb-btn gb-btn-ghost gb-btn-sm" onClick={load} disabled={loading}>
                {loading ? "Refreshing…" : "Refresh"}
              </button>
            </div>
            {grouped.length === 0
              ? <p style={{ color: "var(--gb-muted)", marginBottom: 0 }}>Queue is clear — no fields are waiting for review.</p>
              : grouped.map(([uploadId, fields]) => (
                  <SubmissionGroup key={uploadId} uploadId={uploadId} fields={fields} onReview={doReview} />
                ))}
          </div>
        </>
      )}
    </div>
  );
}
