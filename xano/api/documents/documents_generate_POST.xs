// M19 §6.4, §6.5: the server-side generation gate + resolve_form_variant,
// combined into one endpoint. This is the literal answer to "Your Agent
// Shouldn't Sign That" -- generation is rejected here, in Xano, while any
// field is needs_review; the future document agent has no way around it
// because it calls this same endpoint.
//
// Variant resolution deliberately avoids reassigning a plain string `var`
// across conditional branches (unconfirmed) -- instead, each of the 4
// mutually-exclusive branches does its own full db.add with the variant
// baked in, reusing the exact confirmed pattern from
// documents_doc_type_PUT.xs (pre-declare `var $form {value=null}`, reassign
// via `db.add ... as $form` inside each conditional, precondition $form
// afterward to catch "no branch matched").
//
// visa_status=="F-1-OPT" is how OPT status is assumed to be encoded in the
// extraction schema (a distinct exact value, not a substring of "F-1") --
// no confirmed substring/contains filter exists in this workspace, so this
// avoids guessing one.
query "documents/generate" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int upload_id
  }

  stack {
    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id && $db.extracted_fields.review_state == "needs_review"
      return = {type: "single"}
    } as $pending

    precondition ($pending == null) {
      error_type = "accessdenied"
      error = "Cannot generate: one or more fields still need review."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id && $db.extracted_fields.field_key == "visa_status"
      return = {type: "single"}
    } as $visa_field

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id && $db.extracted_fields.field_key == "funding_source"
      return = {type: "single"}
    } as $funding_field

    precondition ($visa_field != null && $funding_field != null) {
      error_type = "notfound"
      error = "visa_status or funding_source field missing -- run extraction first."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.upload_id == $input.upload_id && $db.extracted_fields.user_id == $auth.id
      return = {type: "list"}
    } as $all_fields

    var $form {
      value = null
    }

    conditional {
      if ($visa_field.value_text == "F-1-OPT") {
        db.add form_generations {
          data = {
            user_id           : $auth.id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_opt"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : "mock-doc-" ~ $input.upload_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "F-1" && $funding_field.value_text == "assistantship") {
        db.add form_generations {
          data = {
            user_id           : $auth.id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_assistantship"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : "mock-doc-" ~ $input.upload_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "F-1" && ($funding_field.value_text == "self" || $funding_field.value_text == "sponsor")) {
        db.add form_generations {
          data = {
            user_id           : $auth.id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "f1_self_funded"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : "mock-doc-" ~ $input.upload_id
            status            : "generated"
          }
        } as $form
      }
    }

    conditional {
      if ($visa_field.value_text == "J-1") {
        db.add form_generations {
          data = {
            user_id           : $auth.id
            upload_id         : $input.upload_id
            form_type         : "ssn_support_packet"
            template_variant  : "j1_sponsor"
            branch_inputs     : {visa_status: $visa_field.value_text, funding_source: $funding_field.value_text}
            field_snapshot    : $all_fields
            provider          : "mock"
            provider_doc_id   : "mock-doc-" ~ $input.upload_id
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
        user_id     : $auth.id
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
  guid = "4Rfjzq-DOL7ibixw7-u3tJzZlLc"
}
