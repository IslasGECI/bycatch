describe("Get trips from GECI data", {
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  it("Calculate foraging trips list", {
    trips <- readr::read_csv("/workdir/tests/data/trips.csv")
    obtained <- xxget_summary_of_trips(trips, config_content)
    expected_rows <- 26
    expect_equal(nrow(obtained), expected_rows)
    expected_complete_trips <- 23
    obtained_complete_trips <- sum(obtained$complete == "complete trip")
    expect_equal(obtained_complete_trips, expected_complete_trips)
  })
})
