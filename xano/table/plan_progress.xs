// Per-task completion state for the 30-day plan. Ported from Neon's
// plan_progress (backend/migrations/001_neon_persistence.sql) unchanged --
// M18 §5.3. One row per (user_id, task_id); task_id is a plan task id, not a
// foreign key into any table (plans are generated, not stored).
table plan_progress {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text task_id filters=trim
    bool completed?
    timestamp updated_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree|unique"
      field: [{name: "user_id", op: "asc"}, {name: "task_id", op: "asc"}]
    }
  ]

  tags = ["m18"]
  guid = "Sfspa7cEQaKfXY8gYeiW7IybJhY"
}