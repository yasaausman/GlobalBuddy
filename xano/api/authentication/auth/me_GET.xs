// Get the user record belonging to the authentication token. M18: output
// list extended; response exposes `full_name` (not the raw `name` column) so
// this endpoint's raw body is directly the flat user object
// frontend/src/auth/xanoAuth.js's getSession() expects.
query "auth/me" verb=GET {
  api_group = "Authentication"
  auth = "user"

  input {
  }

  stack {
    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = [
        "id"
        "created_at"
        "name"
        "email"
        "role"
        "stage"
        "country_of_origin"
        "target_university"
        "target_city"
      ]
    } as $user
  
    function.run "Quick Start/log_event" {
      input = {
        user_id : $user.id
        action  : "get_auth_user"
        metadata: $user
      }
    } as $event_log
  }

  response = {
    id               : $user.id
    email            : $user.email
    full_name        : $user.name
    stage            : $user.stage
    role             : $user.role
    country_of_origin: $user.country_of_origin
    target_university: $user.target_university
    target_city      : $user.target_city
    created_at       : $user.created_at
  }

  tags = ["xano:quick-start", "m18"]
  guid = "PcpkgUjUBA7GUy2kqLvV9JMyikM"
}