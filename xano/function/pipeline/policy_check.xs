// M19 §6.6: shared policy-check logic. Called by BOTH
// documents_policy_check_POST.xs and the agent's agent_policy_check tool.
// Runs the 3 SerpApi (mock) lookups and unconditionally forces
// program_end_date back to needs_review (the mock policy_change scenario
// always detects a change; see the endpoint's original note). This is the
// SerpApi-track behaviour: live data changing pipeline state.
function "Pipeline/policy_check" {
  input {
    int user_id
    int form_generation_id
    text school_name?
  }

  stack {
    db.query form_generations {
      where = $db.form_generations.id == $input.form_generation_id && $db.form_generations.user_id == $input.user_id
      return = {type: "single"}
    } as $form

    precondition ($form != null) {
      error_type = "notfound"
      error = "Form generation not found."
    }

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $input.user_id, form_generation_id: $form.id, lookup_type: "processing_time"}
    } as $processing_time

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $input.user_id, form_generation_id: $form.id, lookup_type: "school_requirements", context: $input.school_name}
    } as $school_requirements

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $input.user_id, form_generation_id: $form.id, lookup_type: "policy_change"}
    } as $policy_change

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $form.upload_id && $db.extracted_fields.user_id == $input.user_id && $db.extracted_fields.field_key == "program_end_date"
      return = {type: "single"}
    } as $flagged_field

    // A policy change forces re-review ONCE. Once the human has been notified
    // (this event exists), re-running the check must not undo their re-review
    // -- otherwise signing is unreachable (the field gets re-flagged forever).
    db.query pipeline_events {
      where = $db.pipeline_events.subject_type == "extracted_field" && $db.pipeline_events.subject_id == ("" ~ $flagged_field.id) && $db.pipeline_events.event == "policy_change_forced_review"
      return = {type: "single"}
    } as $prior_force

    // Null unless we actually force a re-review on THIS run. The agent keys
    // off this: non-null => stop and ask for re-review; null => safe to sign.
    var $forced_field {
      value = null
    }

    conditional {
      if ($flagged_field != null && $prior_force == null) {
        db.edit extracted_fields {
          field_name  = "id"
          field_value = $flagged_field.id
          data = {review_state: "needs_review"}
        } as $forced_field

        db.add pipeline_events {
          data = {
            user_id     : $input.user_id
            subject_type: "extracted_field"
            subject_id  : "" ~ $flagged_field.id
            event       : "policy_change_forced_review"
            actor       : "system"
            payload     : {field_key: "program_end_date", reason: "16 July 2026 DHS Duration of Status rule change"}
          }
        } as $event
      }
    }
  }

  response = {
    processing_time     : $processing_time
    school_requirements : $school_requirements
    policy_change       : $policy_change
    forced_field_review : $forced_field
  }
  tags = ["m19"]
  guid = "2sOMOpPllU7E9nrNFk4iLUGylSs"
}
