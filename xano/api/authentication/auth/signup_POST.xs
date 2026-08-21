// Signup and retrieve an authentication token. M18
// (docs/xano-document-pipeline-plan.md §5.3, §6.2): extended with M18's new
// user fields (role/stage/country_of_origin/target_university/target_city);
// response reshaped to {token, user} so it matches
// frontend/src/auth/xanoAuth.js's extractToken/extractUser expectations
// (data.token, data.user) with zero change needed to AuthContext.jsx.
query "auth/signup" verb=POST {
  api_group = "Authentication"

  input {
    text name?
    email email? filters=trim|lower
    text password?
    text country_of_origin?
    text target_university?
    text target_city?
  }

  stack {
    db.get user {
      field_name = "email"
      field_value = $input.email
    } as $user
  
    precondition ($user == null) {
      error_type = "accessdenied"
      error = "An account with this email already exists."
    }
  
    db.add user {
      data = {
        created_at       : "now"
        name             : $input.name
        email            : $input.email
        password         : $input.password
        role             : "student"
        stage            : "newcomer"
        country_of_origin: $input.country_of_origin
        target_university: $input.target_university
        target_city      : $input.target_city
      }
    } as $user
  
    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  
    function.run "Quick Start/log_event" {
      input = {user_id: $user.id, action: "signup", metadata: $user}
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
  guid = "EdSOxq4yBXRxUPnqLLStuT4Pc1k"
}