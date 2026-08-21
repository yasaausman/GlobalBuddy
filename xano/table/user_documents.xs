// Document checklist status (SSN, bank account, health insurance, etc. --
// frontend/src/components/DocumentTracker.jsx). Ported from Neon's
// user_documents unchanged -- M18 §5.3. One row per (user_id, doc_type).
// M19's pipeline writes doc_type="ssn" status="done" here on signature
// completion (§6.7), closing the loop into this same tracker.
table user_documents {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text doc_type filters=trim
    enum status? {
      values = ["pending", "in_progress", "done"]
    }
  
    timestamp updated_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree|unique"
      field: [{name: "user_id", op: "asc"}, {name: "doc_type", op: "asc"}]
    }
  ]

  tags = ["m18"]
  guid = "aFQWVeyJ0u_f9vbOZJXu98gC5OM"
}