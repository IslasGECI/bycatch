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

describe("import_trips_summary", {
  it("reads a trips summary CSV as a data.frame with expected columns", {
    summary <- import_trips_summary("/workdir/tests/data/trips_summary.csv")

    expect_s3_class(summary, "data.frame")
    expected_columns <- c("tripID", "n_locs", "departure", "return", "duration", "total_dist", "max_dist", "direction", "complete")
    expect_true(all(expected_columns %in% names(summary)))
  })
})
