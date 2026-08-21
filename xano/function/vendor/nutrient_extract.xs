// M19 §6.3, §3.8: mock-mode Nutrient extraction. Looks up a vendor_fixtures
// row (vendor=nutrient, scenario=$input.scenario) and returns its
// payload.fields array. No live branch yet -- NUTRIENT_MODE env-var read
// syntax is unconfirmed in this workspace (deferred rather than guessed);
// wire the live branch here once verified, so every caller stays unchanged.
function "Vendor/nutrient_extract" {
  input {
    text scenario
  }

  stack {
    db.query vendor_fixtures {
      where = $db.vendor_fixtures.vendor == "nutrient" && $db.vendor_fixtures.scenario == $input.scenario
      return = {type: "single"}
    } as $fixture

    precondition ($fixture != null) {
      error_type = "notfound"
      error = "Unknown mock scenario."
    }
  }

  response = {fields: $fixture.payload.fields}
  tags = ["m19"]
  guid = "R3dw0FzcU1ZUIqUUu7D2L_zeF9s"
}
