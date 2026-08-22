// M19 §6.2: agent tool -- sends the generated packet for signature (mock mode
// signs instantly). Calls the shared Pipeline/sign, which derives the signer
// email from the user record, so the agent never handles an email address.
// Only call this after a successful policy check with no forced re-review.
tool agent_sign {
  instructions = "Sends a generated form (pass form_generation_id) for signature. Only call this AFTER agent_policy_check returned with forced_field_review = null (no policy change forced a field back to review). In mock mode the document is signed immediately and the user's document tracker is marked done. Do not call this if any field needs review."

  input {
    int user_id
    int form_generation_id
  }

  stack {
    function.run "Pipeline/sign" {
      input = {user_id: $input.user_id, form_generation_id: $input.form_generation_id}
    } as $result
  }

  response = $result
  tags = ["m19"]
  guid = "TdUEThFcM6diODJ_jCEkw89Kvtw"
}
