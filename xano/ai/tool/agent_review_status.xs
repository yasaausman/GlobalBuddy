// M19 §6.2: agent tool -- reports how many extracted fields still need human
// review for an upload. This is how the document agent discovers it CANNOT
// proceed to generation on its own (the generate gate enforces it server-side
// regardless, but this lets the agent explain the refusal instead of just
// hitting a 403). Takes user_id explicitly because agents run server-side
// with no $auth context.
tool agent_review_status {
  instructions = "Returns the count and list of extracted document fields that still need human review for a given upload_id. Use this before attempting to generate a form -- if any fields need review, generation will be refused and you must ask the human to review them first."

  input {
    int user_id
    int upload_id
  }

  stack {
    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $input.user_id && $db.extracted_fields.review_state == "needs_review"
      return = {type: "list"}
    } as $pending
  }

  response = {
    upload_id           : $input.upload_id
    needs_review_count  : $pending|count
    fields              : $pending
  }
  tags = ["m19"]
  guid = "dkYarT0DuTadNxiiwJaVH8NDLk0"
}
