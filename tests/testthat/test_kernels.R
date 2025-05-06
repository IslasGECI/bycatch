describe("Calculate space use", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  trips <- get_trips(gps_data, config_content)
  trips_summary <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
  complete_trips <- subset(trips, trips$Returns == "Yes")
  it("calculates candidate smoothing parameter values ", {
    obtained <- get_scale_parameters(complete_trips, trips_summary)
    expected_ncol <- 5
    expect_equal(ncol(obtained), expected_ncol)
    expected_magnitud <- 5.45
    expect_equal(obtained$mag, expected_magnitud)
  })
  it("Calculate Kernel Density Estimates", {
    obtained <- get_kernel_density_estimates(gps_data, config_content)
    number_of_individuals <- 10
    expect_equal(nrow(obtained$UDPolygons), number_of_individuals)
    obtained_area <- sum(obtained$UDPolygons$area)
    expected_area <- 113856.8
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)

    config_content$inner_buff <- 60
    percentage_distribution <- 75
    obtained <- get_kernel_density_estimates(gps_data, config_content, percentage_distribution)
    obtained_area <- sum(obtained$UDPolygons$area)
    expected_area <- 119119
    expect_true(obtained_area > expected_area)
  })
})
