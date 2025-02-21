describe("Get trips from GECI data", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  it("Calculate trips ids", {
    obtained <- get_trips(gps_data)
    expect_true("tripID" %in% colnames(obtained@data))
  })
  it("Calculate foraging trips list", {
    obtained <- get_summary_of_trips(gps_data)
    expected_rows <- 121
    expect_equal(nrow(obtained), expected_rows)
    expected_complete_trips <- 116
    obtained_complete_trips <- sum(obtained$complete == "complete trip")
    expect_equal(obtained_complete_trips, expected_complete_trips)
  })
})
