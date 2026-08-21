//  M19 (docs/xano-document-pipeline-plan.md §6.1, §6.3): one row per uploaded
//  document. `POST /v1/documents/upload` creates this immediately; extraction
//  runs afterward, tracked separately in extraction_runs.
// 
//  `file` field is a placeholder (text, storing a filename for now) --
//  Xano's real file-upload field type/syntax is unconfirmed and deliberately
//  deferred rather than guessed; see PLAN.md M19 for the follow-up.
table document_uploads {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text doc_type filters=trim
    text file_placeholder? filters=trim
    text original_filename? filters=trim
    text mime_type? filters=trim
    int byte_size?
    enum upload_status? {
      values = ["uploaded", "processing", "processed", "failed"]
    }
  
    timestamp created_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "user_id", op: "asc"}
        {name: "created_at", op: "desc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "DAdi8ZriLiDUQm9VSHN2Bs1VEMw"
}