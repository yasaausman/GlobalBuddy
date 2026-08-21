// M19 §6.7: send a generated form for signature (mock mode: signs instantly)
// and close the loop into the existing document tracker -- sets
// user_documents.status="done" for the upload's doc_type, matching
// frontend/src/components/DocumentTracker.jsx with zero client change.
// Also creates a notification, reusing the M14 bell unchanged.
query "documents/sign" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int form_generation_id
    text signer_email filters=trim
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

    db.query document_uploads {
      where = $db.document_uploads.id == $form.upload_id && $db.document_uploads.user_id == $auth.id
      return = {type: "single"}
    } as $upload

    precondition ($upload != null) {
      error_type = "notfound"
      error = "Source upload not found."
    }

    function.run "Vendor/foxit_send" {
      input = {
        user_id            : $auth.id
        form_generation_id : $form.id
        signer_email       : $input.signer_email
      }
    } as $signature

    db.query user_documents {
      where = $db.user_documents.user_id == $auth.id && $db.user_documents.doc_type == $upload.doc_type
      return = {type: "single"}
    } as $existing_doc

    var $doc {
      value = null
    }

    conditional {
      if ($existing_doc == null) {
        db.add user_documents {
          data = {
            user_id    : $auth.id
            doc_type   : $upload.doc_type
            status     : "done"
            updated_at : "now"
          }
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
        user_id : $auth.id
        type    : "document_signed"
        title   : "Your document has been signed"
        body    : $upload.doc_type ~ " support packet was signed and is ready to download."
      }
    } as $notif

    db.add pipeline_events {
      data = {
        user_id     : $auth.id
        subject_type: "signature_request"
        subject_id  : "" ~ $signature.id
        event       : "signed"
        actor       : "system"
        payload     : {form_generation_id: $form.id, doc_type: $upload.doc_type}
      }
    } as $event
  }

  response = {
    signature_id     : $signature.id
    status            : $signature.status
    doc_type          : $upload.doc_type
    document_status   : $doc.status
  }
  tags = ["m19"]
  guid = "vEsJwbWgJYKUmMddcg51K8tv_XM"
}
