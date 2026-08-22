// M19 §6.7: thin endpoint wrapper over the shared Pipeline/sign function.
// signer_email is no longer required -- Pipeline/sign derives it from the
// authed user's record. All sign logic lives in the function so the agent's
// agent_sign tool and this endpoint can't diverge.
query "documents/sign" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int form_generation_id
  }

  stack {
    function.run "Pipeline/sign" {
      input = {user_id: $auth.id, form_generation_id: $input.form_generation_id}
    } as $result
  }

  response = $result
  tags = ["m19"]
  guid = "vEsJwbWgJYKUmMddcg51K8tv_XM"
}
