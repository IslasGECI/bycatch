describe("Get trips from GECI data", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  it("Calculate trips ids", {
    obtained <- get_trips(gps_data, config_content)
    expect_true("tripID" %in% colnames(obtained@data))
  })
  it("Calculate foraging trips list", {
    obtained <- get_summary_of_trips(gps_data, config_content)
    obtained |> readr::write_csv("/workdir/tests/data/trips_summary.csv")
    expected_rows <- 121
    expect_equal(nrow(obtained), expected_rows)
    expected_complete_trips <- 116
    obtained_complete_trips <- sum(obtained$complete == "complete trip")
    expect_equal(obtained_complete_trips, expected_complete_trips)
  })
})
