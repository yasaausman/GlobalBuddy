// M19 §6.2: agent tool -- attempts to generate the SSN support packet. Calls
// the SAME Pipeline/generate function the endpoint uses, so the server-side
// gate applies identically: if any field still needs review, this throws
// accessdenied and the agent must route the human to review instead. This is
// the "Your Agent Shouldn't Sign That" moment -- the agent literally cannot
// bypass the gate because it calls the same enforced code path.
tool agent_generate_form {
  instructions = "Attempts to generate the SSN support packet for an upload_id. This will FAIL with an access-denied error if any extracted field still needs human review -- if that happens, do NOT retry; instead tell the human which fields need review (use agent_review_status) and wait for them to complete the review. Only call this once agent_review_status reports zero fields needing review."

  input {
    int user_id
    int upload_id
  }

  stack {
    function.run "Pipeline/generate" {
      input = {user_id: $input.user_id, upload_id: $input.upload_id}
    } as $form
  }

  response = $form
  tags = ["m19"]
  guid = "n_W_l1paKPPiM8MRth5ldbAMsWk"
}
