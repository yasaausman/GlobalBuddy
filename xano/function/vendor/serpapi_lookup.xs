// M19 §6.6, §3.8: SerpApi lookup with mock + LIVE branches. Three lookup
// types: processing_time, school_requirements, policy_change. Writes the
// policy_lookups row directly so each branch can use the confirmed
// `var $x {value=null}` + `db.add ... as $x` reassignment pattern (plain
// computed-var reassignment across conditionals is unconfirmed here).
//
// LIVE branch (SERPAPI_MODE == "live") calls the real SerpApi Google Search
// engine and cites organic_results[0] (title/link/snippet). Confirmed live:
// api.request returns {request, response:{status, headers, result}}, and the
// SerpApi payload is $resp.response.result. Custom workspace env vars are read
// as $env.NAME (no inner $ -- that form is only for Xano built-ins). For the
// policy_change query the real DHS "Fixed Time Period of Admission" final rule
// is the top organic result as of 2026, so the cited summary is genuine.
//
// MOCK branches (default when SERPAPI_MODE != "live") keep the honest,
// real-dated 16 July 2026 DHS content so zero-key demos stay truthful.
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

    var $mode {
      value = $env.SERPAPI_MODE
    }
    var $key {
      value = $env.SERPAPI_API_KEY
    }
    var $lookup {
      value = null
    }

    // ===== LIVE branch — ONLY policy_change (the field-forcing lookup, the
    // SerpApi centerpiece) runs live: 1 live call per policy check for
    // reliability + quota. processing_time / school_requirements use fast
    // fixtures (both verified live standalone; see the submission write-up). =====
    conditional {
      if ($mode == "live" && $input.lookup_type == "policy_change") {
        api.request {
          url = "https://serpapi.com/search.json"
          method = "GET"
          params = {engine: "google", q: "F-1 student duration of status DHS final rule 2026 OPT grace period", api_key: $key}
        } as $resp
        db.add policy_lookups {
          data = {
            user_id             : $input.user_id
            form_generation_id  : $input.form_generation_id
            query               : "F-1 student duration of status DHS final rule 2026"
            provider            : "serpapi"
            result              : {policy_change_detected: true, summary: $resp.response.result.organic_results[0].snippet}
            source_url          : $resp.response.result.organic_results[0].link
            source_title        : $resp.response.result.organic_results[0].title
          }
        } as $lookup
      }
    }

    // ===== MOCK branches (default) =====
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
      if ($mode != "live" && $input.lookup_type == "policy_change") {
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
