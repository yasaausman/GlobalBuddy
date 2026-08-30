// M19 §6.7, §3.8: Foxit eSign with mock + LIVE branches, gated on
// $env.FOXIT_MODE == "live".
//
// LIVE: creates a real Foxit eSign envelope (folder) via the developer-portal
// fusion gateway. Confirmed live: POST na1.fusion.foxit.com/esign/api/v1/
// folders/createfolder with the MAIN client_id/client_secret headers (the
// portal unifies PDF Services + eSign under one credential; the separate
// FOXIT_ESIGN_* OAuth creds are NOT used here). Returns a DRAFT folder with a
// real folderId, recorded as provider_envelope_id, status "sent" -- a genuine
// "call the eSign API directly" for the Foxit track. The document is the
// hosted sample PDF for now; swap fileUrls to the assembled packet URL once the
// document flow delivers a real PDF.
//
// MOCK: marks the envelope "signed" instantly (no real signer round-trip).
function "Vendor/foxit_send" {
  input {
    int user_id
    int form_generation_id
    text signer_email filters=trim
  }

  stack {
    var $mode {
      value = $env.FOXIT_MODE
    }
    var $signature {
      value = null
    }

    // ===== LIVE branch =====
    conditional {
      if ($mode == "live") {
        var $cid {
          value = $env.FOXIT_CLIENT_ID
        }
        var $csec {
          value = $env.FOXIT_CLIENT_SECRET
        }
        api.request {
          url = "https://na1.fusion.foxit.com/esign/api/v1/folders/createfolder"
          method = "POST"
          headers = ["client_id: " ~ $cid, "client_secret: " ~ $csec, "Content-Type: application/json"]
          params = {folderName: "SSN support packet #" ~ $input.form_generation_id, inputType: "url", fileUrls: ["https://app.developer-api.foxit.com/esign/foxit-esign-api-sample.pdf"], fileNames: ["ssn-support-packet.pdf"]}
        } as $resp
        db.add signature_requests {
          data = {
            user_id              : $input.user_id
            form_generation_id   : $input.form_generation_id
            provider             : "foxit"
            provider_envelope_id : "" ~ $resp.response.result.folder.folderId
            signer_email         : $input.signer_email
            status               : "sent"
            sent_at              : "now"
          }
        } as $signature
      }
    }

    // ===== MOCK branch (default) =====
    conditional {
      if ($mode != "live") {
        db.add signature_requests {
          data = {
            user_id              : $input.user_id
            form_generation_id   : $input.form_generation_id
            provider             : "mock"
            provider_envelope_id : "mock-envelope-" ~ $input.form_generation_id
            signer_email         : $input.signer_email
            status               : "signed"
            sent_at              : "now"
            completed_at         : "now"
          }
        } as $signature
      }
    }
  }

  response = $signature
  tags = ["m19"]
  guid = "QAuuD0UNKgTBWnkxczyhIq7Kq9o"
}
