// M19 §6.6, §3.8: mock-mode SerpApi lookup. Three lookup types per the plan
// doc: processing_time, school_requirements, policy_change. Directly writes
// the policy_lookups row (rather than returning a computed value) so this
// function can reuse the confirmed `var $x {value=null}` + `db.add ... as $x`
// reassignment pattern across conditional branches, instead of reassigning a
// plain computed var (unconfirmed -- see documents_generate_POST.xs's header
// comment for why that's avoided).
//
// Mock content for policy_change deliberately cites the real 16 July 2026
// DHS rule (plan doc §1.1) rather than placeholder text -- a true, dated
// fact, so the mock response is honest, not fabricated. Live branch (real
// SerpApi AI Overviews call) deferred until SERPAPI_MODE env-var read syntax
// is confirmed.
function "Vendor/serpapi_lookup" {
  input {
    int user_id
    int form_generation_id?
    text lookup_type
    text context? filters=trim
  }

  stack {
    precondition ($input.lookup_type == "processing_time" || $input.lookup_type == "school_requirements" || $input.lookup_type == "policy_change") {
      error_type = "inputerror"
      error = "lookup_type must be processing_time, school_requirements, or policy_change."
    }

    var $lookup {
      value = null
    }

    conditional {
      if ($input.lookup_type == "processing_time") {
        db.add policy_lookups {
          data = {
            user_id             : $input.user_id
            form_generation_id  : $input.form_generation_id
            query               : "SSA/USCIS SSN processing time 2026"
            provider            : "mock"
            result              : {policy_change_detected: false}
            source_url          : "https://www.uscis.gov/i-765"
            source_title        : "USCIS Form I-765 processing time"
          }
        } as $lookup
      }
    }

    conditional {
      if ($input.lookup_type == "school_requirements") {
        db.add policy_lookups {
          data = {
            user_id             : $input.user_id
            form_generation_id  : $input.form_generation_id
            query               : $input.context ~ " ISSS SSN support letter requirements"
            provider            : "mock"
            result              : {policy_change_detected: false, summary: $input.context ~ " ISSS requires a signed SSN support letter on official letterhead, submitted alongside the SEVIS-verified I-20."}
            source_url          : "https://www.google.com/search?q=" ~ $input.context ~ "+ISSS+SSN+support+letter"
            source_title        : $input.context ~ " ISSS SSN support letter requirements"
          }
        } as $lookup
      }
    }

    conditional {
      if ($input.lookup_type == "policy_change") {
        db.add policy_lookups {
          data = {
            user_id             : $input.user_id
            form_generation_id  : $input.form_generation_id
            query               : "F-1 J-1 visa status policy changes 2026"
            provider            : "mock"
            result              : {policy_change_detected: true, summary: "On 16 July 2026, DHS finalized a rule ending Duration of Status for F-1/J-1, tying the admission period to the I-20's program end date and cutting the post-completion OPT grace period from 60 to 30 days. Any document generated before this date is out of date."}
            source_url          : "https://www.dhs.gov/"
            source_title        : "DHS: Duration of Status rule change, July 2026"
          }
        } as $lookup
      }
    }
  }

  response = $lookup
  tags = ["m19"]
  guid = "iY75xmdLcrcW2pFO_xaxGaT4rjM"
}
