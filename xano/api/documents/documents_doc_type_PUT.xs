// Upsert a document's status. Matches backend/app/routers/documents.py:
// update_document -- same VALID_STATUSES, same {doc_type, status, updated_at}
// response shape.
//
// DEVIATION from the original path-param shape (PUT /documents/{doc_type}):
// path-parameter routes are confirmed broken on this workspace/branch --
// verified with a 100% UI-generated, UI-saved test endpoint (/test/{id}) that
// also 404s despite being correctly registered and shown in Swagger. Not a
// syntax issue on our side; worked around by moving doc_type into the body
// instead of the URL path, using only the plain-endpoint pattern that has
// been reliable in every test so far.
query "documents" verb=PUT {
  api_group = "Documents"
  auth = "user"

  input {
    text doc_type
    text status
  }

  stack {
    precondition ($input.status == "pending" || $input.status == "in_progress" || $input.status == "done") {
      error_type = "inputerror"
      error = "Invalid document status."
    }

    db.query user_documents {
      where = $db.user_documents.user_id == $auth.id && $db.user_documents.doc_type == $input.doc_type
      return = {type: "single"}
    } as $existing

    var $row {
      value = null
    }

    conditional {
      if ($existing == null) {
        db.add user_documents {
          data = {
            user_id    : $auth.id
            doc_type   : $input.doc_type
            status     : $input.status
            updated_at : "now"
          }
        } as $row
      }
    }

    conditional {
      if ($existing != null) {
        db.edit user_documents {
          field_name  = "id"
          field_value = $existing.id
          data = {status: $input.status, updated_at: "now"}
        } as $row
      }
    }
  }

  response = {
    doc_type   : $row.doc_type
    status     : $row.status
    updated_at : $row.updated_at
  }
  tags = ["m18"]
  guid = "k9mZLxe7sYEVq90OM7CPF9qjTTo"
}
