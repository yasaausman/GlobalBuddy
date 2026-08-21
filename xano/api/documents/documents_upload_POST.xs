// M19 §6.3: creates the upload record. Takes doc_type only for now -- real
// multipart file handling is deferred (Xano's file-field syntax is
// unconfirmed in this workspace); document_uploads.file_placeholder exists
// for when that's wired up. Split from the extraction step deliberately so
// each can be tested and debugged in isolation.
query "documents/upload" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    text doc_type
  }

  stack {
    db.add document_uploads {
      data = {
        user_id       : $auth.id
        doc_type      : $input.doc_type
        upload_status : "uploaded"
      }
    } as $upload
  }

  response = {
    id            : $upload.id
    doc_type      : $upload.doc_type
    upload_status : $upload.upload_status
  }
  tags = ["m19"]
  guid = "ouehe_e7CnJzypFARf_CCQVFVvU"
}
