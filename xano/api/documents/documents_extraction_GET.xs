// M19 §6.3: list extraction results for an upload -- what
// ExtractionResults.jsx (M20) polls, and what this session's curl testing
// verifies against. Query-string param, not a path param (M18 SS5.5).
query "documents/extraction" verb=GET {
  api_group = "Documents"
  auth = "user"

  input {
    int upload_id
  }

  stack {
    db.query extraction_runs {
      where = $db.extraction_runs.upload_id == $input.upload_id && $db.extraction_runs.user_id == $auth.id
      return = {type: "single"}
    } as $run

    precondition ($run != null) {
      error_type = "notfound"
      error = "No extraction run for this upload."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id
      return = {type: "list"}
    } as $fields
  }

  response = {
    upload_id : $input.upload_id
    status    : $run.status
    fields    : $fields
  }
  tags = ["m19"]
  guid = "TU03tDhzeuJP4Y0A-IKhlTl_ViY"
}
