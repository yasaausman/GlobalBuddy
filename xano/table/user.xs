// Stores user information and allows the user to authenticate against.
// M18 (docs/xano-document-pipeline-plan.md §5.3): merges Neon's user_profiles
// into Xano's built-in user table. `name` stays the column name (referenced by
// the quick-start signup/login/me stacks and event_log metadata already built
// on top of it) but is exposed as `full_name` in every API response to match
// the app's existing contract. `legacy_auth_user_id` exists only to let
// scripts/migrate_neon_to_xano.py look up rows it has already ported -- it is
// never read by product code.
table user {
  auth = true

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    email? email filters=trim|lower
    password? password filters=min:8|minAlpha:1|minDigit:1
  
    // student: default for every signup. advisor: gates the M20 advisor queue
    // (/v1/advisor/queue) -- never set by signup; granted out of band.
    enum role? {
      values = ["student", "advisor"]
    }
  
    // Journey stage. Mirrors backend/app/utils/stages.py VALID_STAGES exactly.
    // PATCH /v1/auth/me/stage can only move this forward and can never set
    // "mentor" directly -- see me_stage_PATCH.xs.
    enum stage? {
      values = ["newcomer", "settler", "local", "mentor"]
    }
  
    text country_of_origin? filters=trim
    text target_university? filters=trim
    text target_city? filters=trim
  
    // Neon user_profiles.auth_user_id, preserved only for the one-shot data
    // port's id lookup (scripts/migrate_neon_to_xano.py). Not unique-indexed:
    // most rows created after the port will never set it.
    text legacy_auth_user_id? filters=trim
  
    object password_reset? {
      schema {
        password token?
        timestamp? expiration?
        bool used?
      }
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree|unique", field: [{name: "email", op: "asc"}]}
  ]

  tags = ["xano:quick-start"]
  guid = "4G8cMshyCdUX74czqMsXlII-iiY"
}