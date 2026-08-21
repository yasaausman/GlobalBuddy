// M19 §6.5, §3.8: mock-mode Doctavian document generation. Real endpoint
// shapes are unverified (Doctavian Postman spike still blocked on their
// company-account signup, PLAN.md M18) -- this returns a deterministic
// placeholder doc id so the rest of the pipeline (packet assembly, signing)
// can be built and tested now. Swap the mock branch for a real
// External API Request once credentials + endpoint shapes are confirmed.
function "Vendor/doctavian_generate" {
  input {
    int upload_id
    text template_variant
  }

  stack {
    var $doc_id {
      value = "mock-doctavian-" ~ $input.template_variant ~ "-" ~ $input.upload_id
    }
  }

  response = {provider_doc_id: $doc_id, status: "generated"}
  tags = ["m19"]
  guid = "3z9KYwDbaPFdMNzftBSt0Yf-zvw"
}
