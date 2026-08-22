// M20: Xano API client for the document pipeline. The pipeline lives in Xano
// (M18/M19), separate from the existing app's Neon-Auth/FastAPI backend, so it
// gets its own axios instance and its own token store. This keeps the pipeline
// a self-contained surface -- building/demoing it touches none of the 10
// existing pages. The clean auth unification is M22.
//
// Xano groups each have their own canonical id in the URL. Defaults are the
// current workspace's; override via Vite env for a different workspace.
import axios from "axios";

const XANO_ORIGIN = import.meta.env.VITE_XANO_BASE_URL ?? "https://xgnh-6ozi-vxez.n7e.xano.io";
const AUTH_CANON = import.meta.env.VITE_XANO_AUTH_CANON ?? "_WAlCa0m";
const DOCS_CANON = import.meta.env.VITE_XANO_DOCS_CANON ?? "PyL7dgs4";

export const XANO_AUTH_BASE = `${XANO_ORIGIN}/api:${AUTH_CANON}`;
export const XANO_DOCS_BASE = `${XANO_ORIGIN}/api:${DOCS_CANON}`;

const XANO_TOKEN_KEY = "gb_xano_token";

export function getXanoToken() {
  try {
    return localStorage.getItem(XANO_TOKEN_KEY) || "";
  } catch {
    return "";
  }
}

export function setXanoToken(token) {
  try {
    if (token) localStorage.setItem(XANO_TOKEN_KEY, token);
    else localStorage.removeItem(XANO_TOKEN_KEY);
  } catch {
    // ignore storage failures; token still works in-memory for the session
  }
}

export function clearXanoToken() {
  setXanoToken("");
}

// Auth group (signup/login/me) -- no bearer needed for signup/login.
export const xanoAuthApi = axios.create({ baseURL: XANO_AUTH_BASE, timeout: 30_000 });

// Documents group -- every call carries the Xano bearer token.
export const xanoDocsApi = axios.create({ baseURL: XANO_DOCS_BASE, timeout: 130_000 });

xanoDocsApi.interceptors.request.use((config) => {
  const token = getXanoToken();
  if (token) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
