// M19 §6.6: runs all 3 SerpApi lookups for a generated form and, since the
// mock's policy_change scenario always detects a change (there's only one
// fixture scenario so far, and it's always "changed"), unconditionally
// forces program_end_date back to needs_review afterward -- the
// highest-stakes field on the I-20 post-16-July-2026 (plan doc §1.1). This
// sidesteps a bool-comparison on a JSON column's nested value (unconfirmed
// syntax); once live SerpApi wiring exists and policy_change_detected can
// genuinely vary, this needs a real conditional instead of being unconditional.
query "documents/policy-check" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int form_generation_id
    text school_name? filters=trim
  }

  stack {
    db.query form_generations {
      where = $db.form_generations.id == $input.form_generation_id && $db.form_generations.user_id == $auth.id
      return = {type: "single"}
    } as $form

    precondition ($form != null) {
      error_type = "notfound"
      error = "Form generation not found."
    }

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $auth.id, form_generation_id: $form.id, lookup_type: "processing_time"}
    } as $processing_time

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $auth.id, form_generation_id: $form.id, lookup_type: "school_requirements", context: $input.school_name}
    } as $school_requirements

    function.run "Vendor/serpapi_lookup" {
      input = {user_id: $auth.id, form_generation_id: $form.id, lookup_type: "policy_change"}
    } as $policy_change

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $form.upload_id && $db.extracted_fields.user_id == $auth.id && $db.extracted_fields.field_key == "program_end_date"
      return = {type: "single"}
    } as $flagged_field

    conditional {
      if ($flagged_field != null) {
        db.edit extracted_fields {
          field_name  = "id"
          field_value = $flagged_field.id
          data = {review_state: "needs_review"}
        } as $flagged_field

        db.add pipeline_events {
          data = {
            user_id     : $auth.id
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
    processing_time      : $processing_time
    school_requirements   : $school_requirements
    policy_change          : $policy_change
    forced_field_review    : $flagged_field
  }
  tags = ["m19"]
  guid = "-WvC8VsxtXId0oLoDPb_e0kLpDQ"
}
