// Insert one vendor fixture row. Called directly via curl to seed the 3
// Nutrient mock scenarios -- deliberately takes the full payload as input
// rather than constructing complex nested JSON literals in XanoScript,
// which is unconfirmed syntax in this workspace. No auth: this group is
// build-time tooling, never called from the frontend or the agent.
query "vendor-fixtures/add" verb=POST {
  api_group = "VendorFixtures"

  input {
    text vendor
    text scenario
    json payload
  }

  stack {
    db.add vendor_fixtures {
      data = {
        vendor  : $input.vendor
        scenario: $input.scenario
        payload : $input.payload
      }
    } as $row
  }

  response = {
    id      : $row.id
    vendor  : $row.vendor
    scenario: $row.scenario
  }
  tags = ["m19"]
  guid = "ipY0tGF83b4kJ-hOE1IlB6YFlBY"
}
