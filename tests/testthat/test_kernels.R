describe("Calculate space use", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_10percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  trips <- get_trips(gps_data, config_content)
  trips_summary <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
  complete_trips <- subset(trips, trips$Returns == "Yes")
  it("calculates candidate smoothing parameter values ", {
    tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
    obtained <- xxget_scale_parameters(tracks, trips_summary)
    expected_ncol <- 5
    expect_equal(ncol(obtained), expected_ncol)
    expected_magnitud <- 5.55
    expect_equal(obtained$mag, expected_magnitud)
  })
  it("Calculate Kernel Density Estimates", {
    obtained <- get_kernel_density_estimates(gps_data, config_content)
    number_of_individuals <- 3
    expect_equal(nrow(obtained$UDPolygons), number_of_individuals)
    obtained_area <- sum(obtained$UDPolygons$area)
    expected_area <- 17929
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)

    config_content$inner_buff <- 60
    percentage_distribution <- 75
    obtained <- get_kernel_density_estimates(gps_data, config_content, percentage_distribution)
    obtained_area <- sum(obtained$UDPolygons$area)
    expected_area <- 42489.8
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)
  })
})
