// Advance the authenticated user's journey stage. New in M18 -- FastAPI never
// had this wired to Xano; mirrors backend/app/db/repositories.py's
// advance_user_stage() exactly: stage only ever moves forward (rank compare,
// keep the higher one) and "mentor" can never be set here -- that stage is
// opt-in only via the M13 mentor flow (PLAN.md: "Mentor opt-in only. Never
// auto-graduate a user to mentor.").
//
// NOTE: db.edit's parameter shape below (field_name/field_value/data,
// mirroring db.get + db.add) is inferred from this workspace's other db.*
// calls, not confirmed against a working example -- if `xano workspace push`
// rejects this file's syntax, paste the error back and it'll be corrected.
query "auth/me/stage" verb=PATCH {
  api_group = "Authentication"
  auth = "user"

  input {
    text stage
  }

  stack {
    precondition ($input.stage == "newcomer" || $input.stage == "settler" || $input.stage == "local") {
      error_type = "inputerror"
      error = "Stage must be newcomer, settler, or local."
    }

    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "stage"]
    } as $user

    // Rank map mirrors backend/app/utils/stages.py's VALID_STAGES ordering.
    var $stage_rank {
      value = {newcomer: 0, settler: 1, local: 2, mentor: 3}
    }

    var $current_rank {
      value = $stage_rank|get:$user.stage
    }

    var $target_rank {
      value = $stage_rank|get:$input.stage
    }

    conditional {
      if ($target_rank > $current_rank) {
        db.edit user {
          field_name = "id"
          field_value = $auth.id
          data = {stage: $input.stage}
        } as $user
      }
    }

    function.run "Quick Start/log_event" {
      input = {user_id: $user.id, action: "advance_stage", metadata: {stage: $user.stage}}
    } as $event_log
  }

  response = {
    id    : $user.id
    stage : $user.stage
  }
  tags = ["m18"]
  guid = "tz6N4b6pAcrw76_L5n8ve_WUawg"
}
