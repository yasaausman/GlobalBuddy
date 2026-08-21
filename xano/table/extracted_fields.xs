//  M19 §6.3, §6.4: one row per extracted I-20 field. `confidence` is Nutrient's
//  own uncalibrated score; `match_label` and `citation` are stored alongside
//  it deliberately -- a bare percentage is not actionable on its own (see the
//  plan doc §2.1). `review_state` is set by apply_confidence_threshold and
//  updated by the review endpoint; never trust a client-supplied review_state.
// 
//  `confidence` type is unconfirmed (`decimal` -- no confirmed real example
//  in this workspace) -- if push rejects it, this is the one field to fix.
table extracted_fields {
  auth = false

  schema {
    int id
    int extraction_run_id {
      table = "extraction_runs"
    }
  
    int upload_id {
      table = "document_uploads"
    }
  
    int user_id {
      table = "user"
    }
  
    text field_key filters=trim
    text field_label? filters=trim
    text value_text? filters=trim
    text value_normalized? filters=trim
    decimal confidence?
    text match_label? filters=trim
    int page?
    json bbox?
    json citation?
    enum review_state? {
      values = ["auto_accepted", "needs_review", "corrected", "confirmed"]
    }
  
    timestamp created_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "upload_id", op: "asc"}
        {name: "field_key", op: "asc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "Vuskw72rjrIRNu033iz8BcBuIE4"
}