describe("Calculate space use", {
  gps_data <- readr::read_csv("/workdir/tests/data/raw_gps_albatros_guadalupe.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  trips <- compute_trips(gps_data, config_content)
  trips_summary <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
  complete_trips <- subset(trips, trips$Returns == "Yes")
  it("calculates candidate smoothing parameter values ", {
    tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
    obtained <- compute_scale_parameters(tracks, trips_summary)
    expected_ncol <- 5
    expect_equal(ncol(obtained), expected_ncol)
    expected_magnitud <- 5.55
    expect_equal(obtained$mag, expected_magnitud)
    expected_names <- c("log_median", "reference_bandwidth", "scale_ARS")
    obtained_scale_dictionary <- list(
      "log_median" = obtained$mag,
      "reference_bandwidth" = obtained$href,
      "scale_ARS" = obtained$scaleARS
    )
    expect_true(all(names(obtained_scale_dictionary) %in% expected_names))
  })
})
