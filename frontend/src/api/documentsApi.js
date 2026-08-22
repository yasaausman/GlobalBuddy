// M20: thin wrappers over the Xano document-pipeline endpoints (M19).
// One function per endpoint so components never build URLs or bodies inline.
import { xanoAuthApi, xanoDocsApi, setXanoToken, clearXanoToken } from "./xanoClient.js";

// --- auth (pipeline's own Xano session) ---
export async function xanoSignup({ email, password, fullName }) {
  const { data } = await xanoAuthApi.post("/auth/signup", { email, password, name: fullName });
  if (data?.token) setXanoToken(data.token);
  return data; // { token, user }
}

export async function xanoLogin({ email, password }) {
  const { data } = await xanoAuthApi.post("/auth/login", { email, password });
  if (data?.token) setXanoToken(data.token);
  return data; // { token, user }
}

export async function xanoMe() {
  const { data } = await xanoDocsApi.get("/auth/me", { baseURL: xanoAuthApi.defaults.baseURL });
  return data; // flat user object
}

export function xanoLogout() {
  clearXanoToken();
}

// --- pipeline ---
export async function uploadDocument(docType = "i20") {
  const { data } = await xanoDocsApi.post("/documents/upload", { doc_type: docType });
  return data; // { id, doc_type, upload_status }
}

export async function runExtraction(uploadId, scenario = "mixed") {
  const { data } = await xanoDocsApi.post("/documents/extract", { upload_id: uploadId, scenario });
  return data; // { upload_id, extraction_run_id, status }
}

export async function getExtraction(uploadId) {
  const { data } = await xanoDocsApi.get("/documents/extraction", { params: { upload_id: uploadId } });
  return data; // { upload_id, status, fields[] }
}

export async function getReviewQueue(uploadId) {
  const { data } = await xanoDocsApi.get("/documents/review", { params: { upload_id: uploadId } });
  return data; // { upload_id, fields[] }  (needs_review only)
}

export async function submitReview({ fieldId, action, newValue, note }) {
  const { data } = await xanoDocsApi.post("/documents/fields/review", {
    field_id: fieldId, action, new_value: newValue, note,
  });
  return data; // { id, field_key, value_text, review_state }
}

export async function generateForm(uploadId) {
  const { data } = await xanoDocsApi.post("/documents/generate", { upload_id: uploadId });
  return data; // { id, upload_id, template_variant, branch_inputs, status }
}

export async function policyCheck(formGenerationId, schoolName) {
  const { data } = await xanoDocsApi.post("/documents/policy-check", {
    form_generation_id: formGenerationId, school_name: schoolName,
  });
  return data; // { processing_time, school_requirements, policy_change, forced_field_review }
}

export async function signForm(formGenerationId) {
  const { data } = await xanoDocsApi.post("/documents/sign", { form_generation_id: formGenerationId });
  return data; // { signature_id, status, doc_type, document_status }
}

export async function runAgent({ prompt, uploadId }) {
  const { data } = await xanoDocsApi.post("/documents/agent", { prompt, upload_id: uploadId });
  return data; // { run_id, upload_id, result }
}
