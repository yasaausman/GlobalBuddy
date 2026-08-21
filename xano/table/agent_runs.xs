// M19 §6.2: one row per document-agent invocation, mirrors what Xano's own
// Agent dashboard tracks natively. AgentConsole.jsx polls this table (no
// confirmed streaming for Xano Agents, per the plan doc §2.3).
table agent_runs {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text prompt? filters=trim
    json transcript?
    json tool_calls?
    enum status? {
      values = ["running", "completed", "failed"]
    }
  
    timestamp started_at?=now
    timestamp finished_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "user_id", op: "asc"}
        {name: "started_at", op: "desc"}
      ]
    }
  ]

  tags = ["m19"]
  guid = "HW6uKFAfzVG-tJTzX4B57wyuUuM"
}