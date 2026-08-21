// Mark one notification read. Matches backend/app/routers/notifications.py:
// mark_read -- 204, no body. Ownership check (user_id == $auth.id) happens
// via the compound `where` lookup rather than trusting the id directly, same
// intent as FastAPI's user_id-scoped repositories.mark_notification_read.
//
// Same path-param-to-body deviation as documents_doc_type_PUT.xs; see that
// file's header comment for the full reasoning. Distinct path from the
// existing "notifications/read-all" endpoint -- no collision.
query "notifications/read" verb=POST {
  api_group = "Notifications"
  auth = "user"

  input {
    int notification_id
  }

  stack {
    db.query notifications {
      where = $db.notifications.id == $input.notification_id && $db.notifications.user_id == $auth.id
      return = {type: "single"}
    } as $existing

    precondition ($existing != null) {
      error_type = "notfound"
      error = "Notification not found."
    }

    db.edit notifications {
      field_name  = "id"
      field_value = $existing.id
      data = {read: true}
    } as $row
  }

  response = null
  tags = ["m18"]
  guid = "eUd2qRMq4bBUKdH5lzAEXlUYXvg"
}
