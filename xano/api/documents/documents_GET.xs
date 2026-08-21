// List the authenticated user's document statuses.
// Matches backend/app/routers/documents.py:get_documents -- {items: [...]}.
// Each item carries id/user_id alongside doc_type/status/updated_at (Xano
// returns the full row); the frontend (DocumentTracker.jsx) only reads
// doc_type and status, so the extra fields are harmless. Tighten to an exact
// field list once a confirmed array-transform primitive is found -- see the
// note in documents_PUT.xs about unverified syntax in this file set.
query documents verb=GET {
  api_group = "Documents"
  auth = "user"

  input {
  }

  stack {
    db.query user_documents {
      where = $db.user_documents.user_id == $auth.id
      return = {type: "list"}
    } as $rows
  }

  response = {items: $rows}
  tags = ["m18"]
  guid = "ivfXms2DpxHBr9p0O9TwdcBNh7o"
}