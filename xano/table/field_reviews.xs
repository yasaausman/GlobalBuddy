// M19 §6.4: audit trail row, written on every review action, never edited
// or deleted -- this is what makes the human-in-loop claim demonstrable
// rather than decorative (Nutrient track: "keep a record of every step").
table field_reviews {
  auth = false

  schema {
    int id
    int extracted_field_id {
      table = "extracted_fields"
    }
  
    int reviewer_user_id {
      table = "user"
    }
  
    enum action? {
      values = ["confirmed", "corrected", "rejected"]
    }
  
    text previous_value? filters=trim
    text new_value? filters=trim
    decimal previous_confidence?
    text note? filters=trim
    timestamp created_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "extracted_field_id", op: "asc"}
        {name: "created_at", op: "desc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "ecERn2WYPgmprS76fkZAI131f6I"
}