describe("import_trips_summary", {
  it("reads a trips summary CSV as a data.frame with expected columns", {
    summary <- import_trips_summary("/workdir/tests/data/trips_summary.csv")

    expect_s3_class(summary, "data.frame")
    expected_columns <- c("tripID", "n_locs", "departure", "return", "duration", "total_dist", "max_dist", "direction", "complete")
    expect_true(all(expected_columns %in% names(summary)))
  })
})
