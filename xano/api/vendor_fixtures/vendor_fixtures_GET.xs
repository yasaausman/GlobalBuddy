// List all seeded vendor fixtures -- debugging/verification only.
query "vendor-fixtures" verb=GET {
  api_group = "VendorFixtures"

  input {
  }

  stack {
    db.query vendor_fixtures {
      return = {type: "list"}
    } as $rows
  }

  response = {items: $rows}
  tags = ["m19"]
  guid = "B34kCm9PMldioFLlW6-bMUs96N0"
}