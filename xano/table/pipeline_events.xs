// M19: unified append-only audit log across the whole pipeline (uploads,
// reviews, generation, signing). Merged with field_reviews for the M20
// advisor-queue audit trail (plan doc §7.3).
table pipeline_events {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text subject_type? filters=trim
    text subject_id? filters=trim
    text event? filters=trim
    enum actor? {
      values = ["system", "user", "advisor", "agent"]
    }
  
    json payload?
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
    {
      type : "btree"
      field: [
        {name: "subject_type", op: "asc"}
        {name: "subject_id", op: "asc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "QWBHNSi-Re0op7gl938ZSPaufos"
}