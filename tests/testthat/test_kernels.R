describe("Calculate space use", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  trips <- get_trips(gps_data, config_content)
  it("calculates candidate smoothing parameter values ", {
    trips_summary <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
    obtained <- get_scale_parameters(trips, trips_summary)
    print(obtained)
    expected_ncol <- 5
    expect_equal(ncol(obtained), expected_ncol)
    expected_magnitud <- 5.45
    expect_equal(obtained$mag, expected_magnitud)
  })
})
