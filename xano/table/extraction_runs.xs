// M19 §6.3: one row per extraction attempt against an upload. mock/live
// branch lives in vendor_nutrient_extract, not here -- this table just
// tracks run status regardless of which branch produced it.
table extraction_runs {
  auth = false

  schema {
    int id
    int upload_id {
      table = "document_uploads"
    }
  
    int user_id {
      table = "user"
    }
  
    enum provider? {
      values = ["nutrient", "mock"]
    }
  
    text provider_job_id? filters=trim
    enum status? {
      values = ["queued", "running", "succeeded", "failed"]
    }
  
    json raw_response?
    timestamp started_at?=now
    timestamp finished_at?
    text error? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "upload_id", op: "asc"}
        {name: "started_at", op: "desc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "J_tGN5y5ek5rWSFNTvX06DJL-wE"
}