// Upsert a plan task's completion state. Matches backend/app/routers/
// progress.py:update_plan_progress -- {task_id, completed, updated_at}.
//
// Same path-param-to-body deviation as documents_doc_type_PUT.xs; see that
// file's header comment for the full reasoning.
query "progress/plan" verb=PUT {
  api_group = "Progress"
  auth = "user"

  input {
    text task_id
    bool completed
  }

  stack {
    db.query plan_progress {
      where = $db.plan_progress.user_id == $auth.id && $db.plan_progress.task_id == $input.task_id
      return = {type: "single"}
    } as $existing

    var $row {
      value = null
    }

    conditional {
      if ($existing == null) {
        db.add plan_progress {
          data = {
            user_id    : $auth.id
            task_id    : $input.task_id
            completed  : $input.completed
            updated_at : "now"
          }
        } as $row
      }
    }

    conditional {
      if ($existing != null) {
        db.edit plan_progress {
          field_name  = "id"
          field_value = $existing.id
          data = {completed: $input.completed, updated_at: "now"}
        } as $row
      }
    }
  }

  response = {
    task_id    : $row.task_id
    completed  : $row.completed
    updated_at : $row.updated_at
  }
  tags = ["m18"]
  guid = "U0NsQ1ifaw-LfsQKYMgMEyVPx1s"
}
