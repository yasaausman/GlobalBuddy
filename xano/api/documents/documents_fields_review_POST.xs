// M19 §6.4: submit one review action (confirm/correct/reject) on an
// extracted field. Always writes a field_reviews audit row and a
// pipeline_events row -- no correction is possible without an audit trail.
// "rejected" deliberately leaves review_state at "needs_review" (unresolved,
// still blocks generation) rather than clearing it -- a rejection without a
// replacement value isn't a resolution.
//
// Query-string/body param, not a path param (M18 §5.5).
query "documents/fields/review" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int field_id
    text action
    text new_value?
    text note?
  }

  stack {
    precondition ($input.action == "confirmed" || $input.action == "corrected" || $input.action == "rejected") {
      error_type = "inputerror"
      error = "action must be confirmed, corrected, or rejected."
    }

    db.query extracted_fields {
      where = $db.extracted_fields.id == $input.field_id && $db.extracted_fields.user_id == $auth.id
      return = {type: "single"}
    } as $field

    precondition ($field != null) {
      error_type = "notfound"
      error = "Field not found."
    }

    conditional {
      if ($input.action == "confirmed") {
        db.edit extracted_fields {
          field_name  = "id"
          field_value = $field.id
          data = {review_state: "confirmed"}
        } as $field
      }
    }

    conditional {
      if ($input.action == "corrected") {
        db.edit extracted_fields {
          field_name  = "id"
          field_value = $field.id
          data = {review_state: "corrected", value_text: $input.new_value}
        } as $field
      }
    }

    conditional {
      if ($input.action == "rejected") {
        db.edit extracted_fields {
          field_name  = "id"
          field_value = $field.id
          data = {review_state: "needs_review"}
        } as $field
      }
    }

    db.add field_reviews {
      data = {
        extracted_field_id : $field.id
        reviewer_user_id   : $auth.id
        action             : $input.action
        previous_value     : $field.value_text
        new_value          : $input.new_value
        previous_confidence: $field.confidence
        note               : $input.note
      }
    } as $review

    db.add pipeline_events {
      data = {
        user_id     : $auth.id
        subject_type: "extracted_field"
        subject_id  : "" ~ $field.id
        event       : "field_review_" ~ $input.action
        actor       : "user"
        payload     : {field_key: $field.field_key, note: $input.note}
      }
    } as $event
  }

  response = {
    id           : $field.id
    field_key    : $field.field_key
    value_text   : $field.value_text
    review_state : $field.review_state
  }
  tags = ["m19"]
  guid = "rO9aTO_GBPLAXV17RUFfqnTQM20"
}
