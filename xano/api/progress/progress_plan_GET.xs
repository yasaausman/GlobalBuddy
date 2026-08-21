// List the authenticated user's plan task completion state.
// Matches backend/app/routers/progress.py:get_plan_progress -- {items: [...]}.
// Same "extra fields on each item" note as documents_GET.xs.
query "progress/plan" verb=GET {
  api_group = "Progress"
  auth = "user"

  input {
  }

  stack {
    db.query plan_progress {
      where = $db.plan_progress.user_id == $auth.id
      return = {type: "list"}
    } as $rows
  }

  response = {items: $rows}
  tags = ["m18"]
  guid = "MnMtdTpPQ_KH-9STKklmZeFGMZ4"
}
