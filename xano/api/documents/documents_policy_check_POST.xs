// M19 §6.6: thin endpoint wrapper over the shared Pipeline/policy_check
// function. All lookup + force-review logic lives in the function so the
// agent's agent_policy_check tool and this endpoint can't diverge.
query "documents/policy-check" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int form_generation_id
    text school_name? filters=trim
  }

  stack {
    function.run "Pipeline/policy_check" {
      input = {user_id: $auth.id, form_generation_id: $input.form_generation_id, school_name: $input.school_name}
    } as $result
  }

  response = $result
  tags = ["m19"]
  guid = "-WvC8VsxtXId0oLoDPb_e0kLpDQ"
}
