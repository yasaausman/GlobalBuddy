// M19 §6.4, §6.5: thin endpoint wrapper over the shared Pipeline/generate
// function. All the gate + variant + snapshot logic lives in that function
// so the agent's agent_generate_form tool and this endpoint can never
// diverge (the lesson from the i20/ssn duplicate-logic bug).
query "documents/generate" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int upload_id
  }

  stack {
    function.run "Pipeline/generate" {
      input = {user_id: $auth.id, upload_id: $input.upload_id}
    } as $form
  }

  response = $form
  tags = ["m19"]
  guid = "4Rfjzq-DOL7ibixw7-u3tJzZlLc"
}
