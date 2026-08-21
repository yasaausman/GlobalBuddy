// M19 §6.7, §3.8: mock-mode Foxit eSign. Real credentials (separate OAuth2
// client_credentials, distinct from PDF Services -- plan doc §2.2) are still
// blocked on Foxit's reply. Immediately marks the envelope "signed" since
// there's no real signer round-trip to simulate in mock mode -- this is the
// FOXIT_MODE=mock simulate path called out in the plan doc §6.7/§6.9.
function "Vendor/foxit_send" {
  input {
    int user_id
    int form_generation_id
    text signer_email filters=trim
  }

  stack {
    var $envelope_id {
      value = "mock-envelope-" ~ $input.form_generation_id
    }

    db.add signature_requests {
      data = {
        user_id             : $input.user_id
        form_generation_id  : $input.form_generation_id
        provider             : "mock"
        provider_envelope_id : $envelope_id
        signer_email          : $input.signer_email
        status                 : "signed"
        sent_at                : "now"
        completed_at            : "now"
      }
    } as $signature
  }

  response = $signature
  tags = ["m19"]
  guid = "QAuuD0UNKgTBWnkxczyhIq7Kq9o"
}
