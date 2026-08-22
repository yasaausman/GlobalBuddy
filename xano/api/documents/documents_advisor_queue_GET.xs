// M20 §7.3: the ISSS advisor queue -- the "this is a SaaS rebuild, not a
// student toy" surface (Xano track). Role-gated: only a user whose role is
// "advisor" may call it. Reads needs_review fields ACROSS ALL students
// (drops the per-user filter the student endpoints use), plus aggregate
// counts that power the "time saved" story (machine-accepted vs escalated).
//
// The frontend groups the pending fields by upload_id into per-submission
// rows; grouping in XanoScript would need GROUP BY, which has no confirmed
// form here, so we return the flat list and group client-side.
query "advisor/queue" verb=GET {
  api_group = "Documents"
  auth = "user"

  input {
  }

  stack {
    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "role"]
    } as $me

    precondition ($me.role == "advisor") {
      error_type = "accessdenied"
      error = "Advisor role required."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.review_state == "needs_review"
      return = {type: "list"}
    } as $pending

    db.query extracted_fields {
      where = $db.extracted_fields.review_state == "auto_accepted"
      return = {type: "list"}
    } as $auto

    db.query extracted_fields {
      where = $db.extracted_fields.review_state == "confirmed"
      return = {type: "list"}
    } as $confirmed

    db.query extracted_fields {
      where = $db.extracted_fields.review_state == "corrected"
      return = {type: "list"}
    } as $corrected
  }

  response = {
    pending          : $pending
    stats            : {
      needs_review   : $pending|count
      auto_accepted  : $auto|count
      confirmed      : $confirmed|count
      corrected      : $corrected|count
    }
  }
  tags = ["m20"]
  guid = "DwWI3N9dOFWCnbeUeu4AcDZnnwQ"
}
