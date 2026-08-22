// M19 §6.2: the document agent -- Foxit track centerpiece ("an agent that
// starts from a plain prompt and ends with a signed document"). Structure
// copied from the confirmed-working Xano Example Agent; only the prompt, the
// tools list, and the message arg are changed.
//
// The "cannot self-approve" guarantee is NOT enforced by the prompt -- it's
// enforced by Pipeline/generate throwing accessdenied, which agent_generate_form
// calls. Even a jailbroken agent gets a 403. The prompt just tells it how to
// respond gracefully to that refusal.
//
// SECURITY NOTE: tools take user_id as an arg, which the LLM supplies from
// context. For the hackathon demo the invocation endpoint injects the authed
// user's id into the agent context. A production version must not let the LLM
// choose user_id -- it should come from a trusted binding, not a tool arg.
agent "Document Agent" {
  tags = ["m19"]
  llm = {
    type            : "xano-free"
    system_prompt   : """
      You are an assistant that helps an international student turn their uploaded I-20 into a signed SSN support packet. You operate a document pipeline through tools. You never fabricate document data.

      The pipeline has a HARD RULE you cannot override: a form can only be generated once every low-confidence or high-stakes extracted field has been reviewed by the human. The generation tool enforces this server-side -- if you call it while fields still need review, it returns an access-denied error. When that happens, do NOT retry and do NOT try to work around it. Instead, call agent_review_status, list the specific fields that need review, and ask the human to review them.

      Your available tools:
      - agent_review_status(user_id, upload_id): returns how many fields still need human review, and which ones. Always call this first.
      - agent_generate_form(user_id, upload_id): attempts to generate the packet. Only call this after agent_review_status reports zero fields needing review.

      The user_id and upload_id you must pass to tools are given to you in the message context. Always pass them exactly as given.

      When responding:
      - Be concise and clear about the current pipeline state.
      - If review is needed, name the exact fields and their labels.
      - Never claim a document was generated or signed unless a tool confirmed it.
      """
    max_steps       : 6
    messages        : "{{ $args.messages|json_encode() }}"
    temperature     : 0
    search_grounding: false
    thinking_tokens : 0
    include_thoughts: false
    baseURL         : ""
    headers         : ""
    safety_settings : ""
    dynamic_retrival: ""
  }

  tools = [{name: "agent_review_status"}, {name: "agent_generate_form"}]
  guid = "GJYiKa2u_MChhbudsMAK7nT0BLY"
}
