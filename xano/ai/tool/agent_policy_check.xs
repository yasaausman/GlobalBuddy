// M19 §6.2: agent tool -- runs the live policy/processing-time check on a
// generated form. Calls the shared Pipeline/policy_check. IMPORTANT: this can
// force a field (program_end_date) BACK to needs_review if a policy change is
// detected -- if that happens, the agent must NOT sign; it must tell the human
// the field needs re-review. This is the SerpApi-track moment.
tool agent_policy_check {
  instructions = "Runs live policy and processing-time checks on a generated form (pass form_generation_id). Returns processing time, school requirements, and any recent policy change. If a policy change is detected it will force a field back to human review -- check the 'forced_field_review' in the result: if it is not null, do NOT proceed to signing; tell the human that field needs re-review because of the policy change."

  input {
    int user_id
    int form_generation_id
    text school_name?
  }

  stack {
    function.run "Pipeline/policy_check" {
      input = {user_id: $input.user_id, form_generation_id: $input.form_generation_id, school_name: $input.school_name}
    } as $result
  }

  response = $result
  tags = ["m19"]
  guid = "lvOgPDeVV4qKD_zSI1VP67Bmoiw"
}
