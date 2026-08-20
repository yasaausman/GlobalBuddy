// Xano built-in auth client (M18) -- matches neonAuth.js's shape exactly, so the
// swap in AuthContext.jsx is one import line once Xano's /v1/auth/* group is live
// at parity with backend/app/routers/auth.py (see docs/xano-document-pipeline-plan.md §5).
//
// NOT wired into AuthContext.jsx yet. Xano's auth endpoints don't exist until the
// M18 workspace is built; swapping the import before then would break every
// signed-in session. Swap only after `/v1/auth/{signup,login,me,me/stage}` are
// confirmed at byte-for-byte parity with the FastAPI routes they replace.

import { getAuthToken } from "./tokenStore.js";

const XANO_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "";
export const xanoAuthConfigured = Boolean(XANO_BASE_URL.trim());

async function xanoRequest(path, { method = "GET", body, token } = {}) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;

  let response;
  try {
    response = await fetch(`${XANO_BASE_URL}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (networkError) {
    return { error: { message: networkError.message || "Network error." } };
  }

  let data = null;
  try {
    data = await response.json();
  } catch {
    // Empty body is fine for some endpoints.
  }

  if (!response.ok) {
    return { error: { message: data?.detail || data?.message || `Request failed (${response.status}).` } };
  }
  return { data };
}

export const xanoAuthClient = {
  async getSession() {
    const token = getAuthToken();
    if (!token) return { data: { user: null }, session: null };
    const result = await xanoRequest("/v1/auth/me", { token });
    if (result.error) return result;
    return { data: { user: result.data, session: { token } } };
  },

  signUp: {
    async email({ email, password, name }) {
      const result = await xanoRequest("/v1/auth/signup", {
        method: "POST",
        body: { email, password, full_name: name },
      });
      if (result.error) return result;
      return { data: result.data };
    },
  },

  signIn: {
    async email({ email, password }) {
      const result = await xanoRequest("/v1/auth/login", {
        method: "POST",
        body: { email, password },
      });
      if (result.error) return result;
      return { data: result.data };
    },

    // LinkedIn OAuth rebuild is cut for the hackathon (PLAN.md M18) -- already
    // blocked on LinkedIn app review since M6, zero demo value. Kept as a named
    // stub so AuthContext's signInWithLinkedIn keeps working (returns an error
    // banner) instead of throwing.
    async social({ provider }) {
      return { error: { message: `${provider} sign-in is not available in this build.` } };
    },
  },

  async signOut() {
    // Xano auth is stateless-JWT; there is no server-side session to revoke.
    // AuthContext already clears the local token after calling this.
    return { error: null };
  },
};
