// Login and retrieve an authentication token. M18: output list extended with
// the new user fields; response reshaped to {token, user} to match
// frontend/src/auth/xanoAuth.js -- same reasoning as signup_POST.xs.
query "auth/login" verb=POST {
  api_group = "Authentication"

  input {
    email email? filters=trim|lower
    text password?
  }

  stack {
    db.get user {
      field_name = "email"
      field_value = $input.email
      output = [
        "id"
        "created_at"
        "name"
        "email"
        "password"
        "role"
        "stage"
        "country_of_origin"
        "target_university"
        "target_city"
      ]
    } as $user
  
    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid Credentials."
    }
  
    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $pass_result
  
    precondition ($pass_result) {
      error_type = "accessdenied"
      error = "Invalid Credentials."
    }
  
    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  
    function.run "Quick Start/log_event" {
      input = {user_id: $user.id, action: "login", metadata: $user}
    } as $event_log
  }

  response = {
    token: $authToken
    user : ```
      {
        id                : $user.id
        email             : $user.email
        full_name         : $user.name
        stage             : $user.stage
        role              : $user.role
        country_of_origin : $user.country_of_origin
        target_university : $user.target_university
        target_city       : $user.target_city
        created_at        : $user.created_at
      }
      ```
  }

  tags = ["xano:quick-start", "m18"]
  guid = "sTyZNQmrnECEnu5hNxRnjOWPQMM"
}