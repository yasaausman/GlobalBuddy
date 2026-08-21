//  List the authenticated user's notifications + unread count.
//  Matches backend/app/routers/notifications.py:list_notifications --
//  {items: [...], unread: int}.
// 
//  UNVERIFIED: the `|count` filter on $unread_rows is inferred from the
//  confirmed `|get:` filter pattern (function/quick_start/enforce_role.xs),
//  not confirmed against a working example.
query notifications verb=GET {
  api_group = "Notifications"
  auth = "user"

  input {
  }

  stack {
    db.query notifications {
      where = $db.notifications.user_id == $auth.id
      return = {type: "list"}
    } as $rows
  
    db.query notifications {
      where = $db.notifications.user_id == $auth.id && $db.notifications.read == false
      return = {type: "list"}
    } as $unread_rows
  
    var $unread_count {
      value = $unread_rows|count
    }
  }

  response = {items: $rows, unread: $unread_count}
  tags = ["m18"]
  guid = "pOtLB90afngSnbotYFwVLbROZuA"
}