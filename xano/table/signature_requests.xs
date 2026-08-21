// M19 §6.7: one row per Foxit eSign envelope. Status advances via the
// webhook (POST /v1/webhooks/foxit) on real signature events, or via the
// mock-simulate endpoint when FOXIT_MODE=mock.
table signature_requests {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    int form_generation_id {
      table = "form_generations"
    }
  
    enum provider? {
      values = ["foxit", "mock"]
    }
  
    text provider_envelope_id? filters=trim
    text signer_email? filters=trim
    enum status? {
      values = ["created", "sent", "viewed", "signed", "declined", "expired"]
    }
  
    text signed_file_placeholder? filters=trim
    timestamp sent_at?
    timestamp completed_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "user_id", op: "asc"}]}
    {
      type : "btree"
      field: [{name: "provider_envelope_id", op: "asc"}]
    }
  ]

  tags = ["m19"]
  guid = "ksj2PzUei6gfkCfGj7N0C2X94gc"
}