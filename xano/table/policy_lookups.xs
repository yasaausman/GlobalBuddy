// M19 §6.6: one row per SerpApi lookup. Load-bearing, not decorative --
// lookup 3 (recent policy changes) can force a field back to needs_review,
// so this table doubles as the audit trail for why that happened.
table policy_lookups {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    int form_generation_id? {
      table = "form_generations"
    }
  
    text query? filters=trim
    enum provider? {
      values = ["serpapi", "mock"]
    }
  
    json result?
    text source_url? filters=trim
    text source_title? filters=trim
    timestamp retrieved_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "user_id", op: "asc"}
        {name: "retrieved_at", op: "desc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "Pl3OaXFdq2R_VnbWm3tozIAGN0c"
}