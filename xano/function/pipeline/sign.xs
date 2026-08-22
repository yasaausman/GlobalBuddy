// M19 §6.7: shared signing logic. Called by BOTH documents_sign_POST.xs and
// the agent's agent_sign tool. Derives the signer email from the user record
// (via user_id) rather than taking it as a param -- the agent never has to
// know or supply an email, and it fixes the earlier signer_email-required
// 400 on the endpoint. Mock mode signs instantly (Vendor/foxit_send) and
// closes the loop into user_documents (status=done) + a notification, so the
// M14 bell picks it up unchanged.
function "Pipeline/sign" {
  input {
    int user_id
    int form_generation_id
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

    db.get user {
      field_name = "id"
      field_value = $input.user_id
      output = ["id", "email"]
    } as $signer

    db.query document_uploads {
      where = $db.document_uploads.id == $form.upload_id && $db.document_uploads.user_id == $input.user_id
      return = {type: "single"}
    } as $upload

    precondition ($upload != null) {
      error_type = "notfound"
      error = "Source upload not found."
    }

    function.run "Vendor/foxit_send" {
      input = {
        user_id            : $input.user_id
        form_generation_id : $form.id
        signer_email       : $signer.email
      }
    } as $signature

    db.query user_documents {
      where = $db.user_documents.user_id == $input.user_id && $db.user_documents.doc_type == $upload.doc_type
      return = {type: "single"}
    } as $existing_doc

    var $doc {
      value = null
    }

    conditional {
      if ($existing_doc == null) {
        db.add user_documents {
          data = {user_id: $input.user_id, doc_type: $upload.doc_type, status: "done", updated_at: "now"}
        } as $doc
      }
    }

    conditional {
      if ($existing_doc != null) {
        db.edit user_documents {
          field_name  = "id"
          field_value = $existing_doc.id
          data = {status: "done", updated_at: "now"}
        } as $doc
      }
    }

    db.add notifications {
      data = {
        user_id : $input.user_id
        type    : "document_signed"
        title   : "Your document has been signed"
        body    : $upload.doc_type ~ " support packet was signed and is ready to download."
      }
    } as $notif

    db.add pipeline_events {
      data = {
        user_id     : $input.user_id
        subject_type: "signature_request"
        subject_id  : "" ~ $signature.id
        event       : "signed"
        actor       : "system"
        payload     : {form_generation_id: $form.id, doc_type: $upload.doc_type}
      }
    } as $event
  }

  response = {
    signature_id    : $signature.id
    status          : $signature.status
    doc_type        : $upload.doc_type
    document_status : $doc.status
  }
  tags = ["m19"]
  guid = "F2UQLY-TCyRlumONm_cOLv4NGws"
}
