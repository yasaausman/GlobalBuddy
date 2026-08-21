//  M19 §6.5: one row per generated SSN support packet. `field_snapshot`
//  freezes the field values at generation time so a later correction can't
//  retroactively change what was already generated/signed.
// 
//  `output_file` is a placeholder (text) for the same reason as
//  document_uploads.file_placeholder -- Xano's file field type is unconfirmed.
table form_generations {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    int upload_id {
      table = "document_uploads"
    }
  
    text form_type? filters=trim
    text template_variant? filters=trim
    json branch_inputs?
    json field_snapshot?
    enum provider? {
      values = ["doctavian", "mock"]
    }
  
    text provider_doc_id? filters=trim
    text output_file_placeholder? filters=trim
    enum status? {
      values = ["pending", "generated", "failed"]
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
  guid = "Bd0OkzV8uGsvgWuehWwPp0q51Vo"
}