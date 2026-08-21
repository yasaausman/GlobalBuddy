// M19 §6.4: list only the fields awaiting human review for an upload -- what
// ExtractionReview.jsx (M20) polls. Query-string param, not a path param
// (M18 §5.5). Triple-AND where clause extends the confirmed double-AND
// pattern from documents_extraction_GET.xs.
query "documents/review" verb=GET {
  api_group = "Documents"
  auth = "user"

  input {
    int upload_id
  }

  stack {
    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id && $db.extracted_fields.review_state == "needs_review"
      return = {type: "list"}
    } as $fields
  }

  response = {
    upload_id : $input.upload_id
    fields    : $fields
  }
  tags = ["m19"]
  guid = "PoSQZsj0OhCWC4U7lsbihfse954"
}
