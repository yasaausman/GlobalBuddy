// Mark all of the authenticated user's notifications read.
// Matches backend/app/routers/notifications.py:mark_all_read -- 204, no body.
//
// `foreach` syntax confirmed directly from the Xano dashboard's XanoScript
// tab, twice: first pass showed the empty header (`each as $item` alone) and
// still failed to push, because `each as $item` is a BLOCK with its own
// braces, not a plain statement -- the loop body must be nested inside it
// (`each as $item { ...steps... }`), not written directly under `foreach {}`.
query "notifications/read-all" verb=POST {
  api_group = "Notifications"
  auth = "user"

  input {
  }

  stack {
    db.query notifications {
      where = $db.notifications.user_id == $auth.id && $db.notifications.read == false
      return = {type: "list"}
    } as $unread_rows

    foreach ($unread_rows) {
      each as $item {
        db.edit notifications {
          field_name  = "id"
          field_value = $item.id
          data = {read: true}
        } as $edited
      }
    }
  }

  response = null
  tags = ["m18"]
  guid = "nLJI3AOIMucfl2NDzXI0TCmSDwM"
}
