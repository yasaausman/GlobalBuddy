// M19 §6.4, §6.5: shared generation logic -- the server-side gate +
// resolve_form_variant + field_snapshot freeze. Called by BOTH
// documents_generate_POST.xs (with $auth.id) and the agent's
// agent_generate_form tool (with an explicit user_id). Single source of
// truth so the gate can never diverge between the two callers -- this is the
// lesson from the i20/ssn duplicate-logic bug.
//
// Throws accessdenied while any field is needs_review -- this is the literal
// "Your Agent Shouldn't Sign That" enforcement; the agent calls this same
// function, so it physically cannot self-approve.
//
// Uses the confirmed reassignment pattern (full db.add per branch, each
// `as $form`) rather than reassigning a plain `var` across conditionals,
// which has no confirmed working example in this workspace.
function "Pipeline/generate" {
  input {
    int user_id
    int upload_id
  }

  stack {
    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $input.user_id && $db.extracted_fields.review_state == "needs_review"
      return = {type: "single"}
    } as $pending

    precondition ($pending == null) {
      error_type = "accessdenied"
      error = "Cannot generate: one or more fields still need review."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $input.user_id && $db.extracted_fields.field_key == "visa_status"
      return = {type: "single"}
    } as $visa_field

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $input.user_id && $db.extracted_fields.field_key == "funding_source"
      return = {type: "single"}
    } as $funding_field

    precondition ($visa_field != null && $funding_field != null) {
      error_type = "notfound"
      error = "visa_status or funding_source field missing -- run extraction first."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $input.user_id
      return = {type: "list"}
    } as $all_fields

    var $form {
      value = null
    }

    conditional {
      if ($visa_field.value_text == "F-1-OPT") {
        function.run "Vendor/doctavian_generate" {
          input = {upload_id: $input.upload_id, template_variant: "f1_opt"}
        } as $gen
        db.add form_generations {
          data = {
            user_id           : $input.user_id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_opt"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : $gen.provider_doc_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "F-1" && $funding_field.value_text == "assistantship") {
        function.run "Vendor/doctavian_generate" {
          input = {upload_id: $input.upload_id, template_variant: "f1_assistantship"}
        } as $gen
        db.add form_generations {
          data = {
            user_id           : $input.user_id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_assistantship"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : $gen.provider_doc_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "F-1" && ($funding_field.value_text == "self" || $funding_field.value_text == "sponsor")) {
        function.run "Vendor/doctavian_generate" {
          input = {upload_id: $input.upload_id, template_variant: "f1_self_funded"}
        } as $gen
        db.add form_generations {
          data = {
            user_id           : $input.user_id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_self_funded"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : $gen.provider_doc_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "J-1") {
        function.run "Vendor/doctavian_generate" {
          input = {upload_id: $input.upload_id, template_variant: "j1_sponsor"}
        } as $gen
        db.add form_generations {
          data = {
            user_id           : $input.user_id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "j1_sponsor"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : $gen.provider_doc_id
            status            : "generated"
          }
        } as $form
      }
    }

    precondition ($form != null) {
      error_type = "inputerror"
      error = "No form variant matches this visa_status/funding_source combination."
    }

    db.add pipeline_events {
      data = {
        user_id     : $input.user_id
        subject_type: "form_generation"
        subject_id  : "" ~ $form.id
        event       : "form_generated"
        actor       : "user"
        payload     : {template_variant: $form.template_variant}
      }
    } as $event
  }

  response = {
    id               : $form.id
    upload_id        : $form.upload_id
    template_variant : $form.template_variant
    branch_inputs    : $form.branch_inputs
    status           : $form.status
  }
  tags = ["m19"]
  guid = "6Qz0Vssc1hLwggt4Hf5WVemzTyw"
}
