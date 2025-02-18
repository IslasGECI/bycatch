describe("Get trips from GECI data", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  it("Calculate trips ids", {
    obtained <- get_trips(gps_data)
    expect_true("tripID" %in% colnames(obtained@data))
  })
  it("Calculate foraging trips list", {
    obtained <- get_summary_of_trips(gps_data)
    expected_columns <- c("tripID", "n_locs", "departure", "return", "duration", "total_dist")
    expect_true(all(expected_columns %in% colnames(obtained)))
  })
})
