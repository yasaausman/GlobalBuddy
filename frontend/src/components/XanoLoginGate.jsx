// M20: shared Xano-session gate for the pipeline surfaces (student + advisor).
// The pipeline authenticates against Xano separately from the app's Neon-Auth
// session (see api/xanoClient.js). One gate, so the two pages can't drift.
import { useState } from "react";
import { xanoLogin, xanoSignup } from "../api/documentsApi.js";

function errText(e, fallback) {
  return e?.response?.data?.message || e?.response?.data?.detail || e?.message || fallback;
}

export default function XanoLoginGate({ title = "Document Center", blurb = "Sign in to continue.", allowSignup = true, onAuthed }) {
  const [mode, setMode] = useState("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true); setError(null);
    try {
      const fn = mode === "login" ? xanoLogin : xanoSignup;
      const data = await fn({ email, password, fullName });
      onAuthed(data.user);
    } catch (err) {
      setError(errText(err, "Authentication failed."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="gb-card" style={{ maxWidth: 420, margin: "3rem auto", padding: "2rem" }}>
      <h2 className="gb-section-title" style={{ marginTop: 0 }}>{title}</h2>
      <p style={{ color: "var(--gb-muted)", marginTop: 0 }}>{blurb}</p>
      {error && <p className="gb-auth-error" role="alert">{error}</p>}
      <form onSubmit={submit}>
        {mode === "signup" && (
          <div className="gb-field">
            <label>Full name</label>
            <input value={fullName} onChange={(e) => setFullName(e.target.value)} required />
          </div>
        )}
        <div className="gb-field">
          <label>Email</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </div>
        <div className="gb-field">
          <label>Password</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </div>
        <button type="submit" className="gb-btn gb-btn-primary gb-btn-full" disabled={busy}>
          {busy ? "…" : mode === "login" ? "Sign in" : "Create account"}
        </button>
      </form>
      {allowSignup && (
        <button
          type="button"
          className="gb-btn gb-btn-ghost gb-btn-sm"
          style={{ marginTop: "0.75rem" }}
          onClick={() => { setMode(mode === "login" ? "signup" : "login"); setError(null); }}
        >
          {mode === "login" ? "Need an account? Sign up" : "Have an account? Sign in"}
        </button>
      )}
    </div>
  );
}
