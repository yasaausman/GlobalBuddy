// M19 §6.8: mock-mode payloads for the 4 vendor custom functions. Each
// vendor_* function reads a row here by (vendor, scenario) when its mode is
// "mock" -- no function stack ever calls a vendor URL directly, per the
// plan doc's mock-first design. Seeded via POST /vendor-fixtures/seed
// (xano/api/vendor_fixtures/vendor_fixtures_seed_POST.xs), not by hand.
table vendor_fixtures {
  auth = false

  schema {
    int id
    enum vendor? {
      values = ["nutrient", "doctavian", "serpapi", "foxit"]
    }
  
    text scenario? filters=trim
    json payload?
    timestamp created_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {
      type : "btree"
      field: [{name: "vendor", op: "asc"}, {name: "scenario", op: "asc"}]
    }
  ]

  tags = ["m19"]
  guid = "E9a5ABlCZJrUBtftgXtRAdErGB8"
}