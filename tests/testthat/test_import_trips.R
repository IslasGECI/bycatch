describe("import_trips", {
  it("filters returning trips by default", {
    trips <- import_trips("/workdir/tests/data/trips_5_ids.csv")

    expect_s3_class(trips, "data.frame")
    expect_true(all(trips$Returns == "Yes"))
  })

  it("keeps all trips when filter_returning is FALSE", {
    trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = FALSE)

    expect_s3_class(trips, "data.frame")
    expect_true(any(trips$Returns == "No"))
    expect_true(any(trips$Returns == "Yes"))
    expect_equal(nrow(trips), 3194)
  })
})
