// M19 §6.2: agent tool -- lists forms already generated for an upload, newest
// first. Lets the agent REUSE an existing form_generation_id (for policy-check
// / sign) instead of blindly regenerating a duplicate. Fixes the observed
// quirk where, asked only to sign, the agent re-ran generate and created a
// second form_generations row.
tool agent_list_forms {
  instructions = "Lists the forms already generated for an upload_id (the one with the highest id is the most recent). Call this before agent_generate_form when the user asks to sign, re-check, or continue an existing document -- if a form already exists, reuse its id for agent_policy_check and agent_sign instead of generating a new one. Only generate a new form if this returns none."

  input {
    int user_id
    int upload_id
  }

  stack {
    db.query form_generations {
      where = $db.form_generations.upload_id == $input.upload_id && $db.form_generations.user_id == $input.user_id
      return = {type: "list"}
    } as $forms
  }

  response = {
    upload_id : $input.upload_id
    count     : $forms|count
    forms     : $forms
  }
  tags = ["m19"]
  guid = "vU5LCiGECG3opUqVeZFbBI7VkKg"
}
