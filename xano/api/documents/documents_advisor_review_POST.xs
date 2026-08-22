// M20 §7.3: advisor reviews a student's field. Role-gated (advisor only) and,
// unlike documents/fields/review, does NOT require field.user_id == $auth.id
// -- an advisor acts on students' fields. The review is attributed to the
// advisor: field_reviews.reviewer_user_id and pipeline_events.actor="advisor"
// record who resolved it. Otherwise mirrors the student review logic exactly.
query "advisor/review" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int field_id
    text action
    text new_value?
    text note?
  }

  stack {
    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "role"]
    } as $me

    precondition ($me.role == "advisor") {
      error_type = "accessdenied"
      error = "Advisor role required."
    }

    precondition ($input.action == "confirmed" || $input.action == "corrected" || $input.action == "rejected") {
      error_type = "inputerror"
      error = "action must be confirmed, corrected, or rejected."
    }

    db.get extracted_fields {
      field_name = "id"
      field_value = $input.field_id
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
        user_id     : $field.user_id
        subject_type: "extracted_field"
        subject_id  : "" ~ $field.id
        event       : "advisor_review_" ~ $input.action
        actor       : "advisor"
        payload     : {field_key: $field.field_key, reviewer_id: $auth.id, note: $input.note}
      }
    } as $event
  }

  response = {
    id           : $field.id
    field_key    : $field.field_key
    value_text   : $field.value_text
    review_state : $field.review_state
  }
  tags = ["m20"]
  guid = "CGdIEYccBUwCtmKti4m6JyfcCd0"
}
