// M19 §6.2: the document agent invocation endpoint -- "a plain prompt ends
// in a signed document" (Foxit track). Auth'd so $auth.id is a TRUSTED value;
// we inject it into the agent's message context rather than letting the LLM
// choose a user_id (see the security note in ai/agent/document_agent.xs).
//
// ai.agent.run syntax confirmed from the dashboard's "Connect to AI Agent"
// generator. The run is recorded in agent_runs for the M20 AgentConsole
// (which polls it, since Xano Agents don't document streaming).
query "documents/agent" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    text prompt
    int upload_id
  }

  stack {
    var $context_msg {
      value = $input.prompt ~ " [Trusted context -- pass these to tools exactly: user_id=" ~ $auth.id ~ ", upload_id=" ~ $input.upload_id ~ "]"
    }

    var $agent_args {
      value = {messages: [{role: "user", content: $context_msg}]}
    }

    ai.agent.run "Document Agent" {
      args = $agent_args
      allow_tool_execution = true
      version = "v5"
    } as $agent_response

    db.add agent_runs {
      data = {
        user_id   : $auth.id
        prompt    : $input.prompt
        transcript: $agent_response
        status    : "completed"
      }
    } as $run
  }

  response = {
    run_id   : $run.id
    upload_id: $input.upload_id
    result   : $agent_response
  }
  tags = ["m19"]
  guid = "W0REqJfBo-aX358yQEcAfWuFgEE"
}
