// In-app notifications, polled by the frontend bell (NotificationBell.jsx).
// Ported from Neon's notifications table unchanged -- M18 §5.3. M19's
// signature-webhook handler (§6.7) creates a row here on signing complete,
// so the existing bell picks it up with zero frontend changes.
table notifications {
  auth = false

  schema {
    int id
    int user_id {
      table = "user"
    }
  
    text type filters=trim
    text title filters=trim
    text body? filters=trim
    bool read?
    timestamp created_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [
        {name: "user_id", op: "asc"}
        {name: "created_at", op: "desc"}
      ]
    }
  ]

  tags = ["m18"]
  guid = "sQWrAhTSnYpSybXW1902udsdi4M"
}