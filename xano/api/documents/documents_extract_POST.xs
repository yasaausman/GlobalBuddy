// M19 §6.3, §6.4: runs (mock) extraction against an upload and applies the
// confidence gate per field. Looks up a vendor_fixtures row (vendor=nutrient,
// scenario=$input.scenario) and creates one extracted_fields row per item in
// its payload.fields array.
//
// Confidence gate logic is inlined here rather than a separate reusable
// function, deliberately -- avoids needing to reassign a `var` across
// conditional branches (no confirmed example of that in this workspace).
// Two mutually exclusive conditionals, each doing its own real db.add with
// the correct review_state baked in, mirrors the confirmed upsert pattern
// from documents_doc_type_PUT.xs. The OR'd/AND'd comparison inside each
// if(...) is the exact confirmed pattern from that same file's precondition.
//
// UNCONFIRMED: dot-notation access into a JSON column's nested array
// ($fixture.payload.fields) and foreach over that array (vs. a db.query
// result list, which is the only confirmed foreach target so far). If push
// or a live call fails here, this is the first thing to isolate.
query "documents/extract" verb=POST {
  api_group = "Documents"
  auth = "user"

  input {
    int upload_id
    text scenario
  }

  stack {
    db.query vendor_fixtures {
      where = $db.vendor_fixtures.vendor == "nutrient" && $db.vendor_fixtures.scenario == $input.scenario
      return = {type: "single"}
    } as $fixture

    precondition ($fixture != null) {
      error_type = "notfound"
      error = "Unknown mock scenario."
    }

    db.add extraction_runs {
      data = {
        upload_id : $input.upload_id
        user_id   : $auth.id
        provider  : "mock"
        status    : "running"
      }
    } as $run

    foreach ($fixture.payload.fields) {
      each as $f {
        conditional {
          if ($f.confidence < 0.85 || $f.field_key == "sevis_id" || $f.field_key == "program_end_date" || $f.field_key == "funding_amount") {
            db.add extracted_fields {
              data = {
                extraction_run_id : $run.id
                upload_id         : $input.upload_id
                user_id           : $auth.id
                field_key         : $f.field_key
                field_label       : $f.field_label
                value_text        : $f.value_text
                confidence        : $f.confidence
                match_label       : $f.match_label
                page              : $f.page
                bbox              : $f.bbox
                citation          : $f.citation
                review_state      : "needs_review"
              }
            } as $ef
          }
        }

        conditional {
          if ($f.confidence >= 0.85 && $f.field_key != "sevis_id" && $f.field_key != "program_end_date" && $f.field_key != "funding_amount") {
            db.add extracted_fields {
              data = {
                extraction_run_id : $run.id
                upload_id         : $input.upload_id
                user_id           : $auth.id
                field_key         : $f.field_key
                field_label       : $f.field_label
                value_text        : $f.value_text
                confidence        : $f.confidence
                match_label       : $f.match_label
                page              : $f.page
                bbox              : $f.bbox
                citation          : $f.citation
                review_state      : "auto_accepted"
              }
            } as $ef
          }
        }
      }
    }

    db.edit extraction_runs {
      field_name  = "id"
      field_value = $run.id
      data = {status: "succeeded", finished_at: "now"}
    } as $run
  }

  response = {
    upload_id         : $input.upload_id
    extraction_run_id : $run.id
    status            : $run.status
  }
  tags = ["m19"]
  guid = "ZhjuWLB6Q7QXHWnantGp_SX0-co"
}
