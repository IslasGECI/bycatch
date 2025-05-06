gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv"
config_path <- "/workdir/tests/data/trips_config.json"

describe("plot map of individuals KDE", {
  output_path <- "/workdir/tests/kde_map.png"
  gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_10percent_sample.csv"
  options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path, "percentage-distribution" = 50)
  it("write figure", {
    plot_individual_kernels(options)
    expect_true(testtools::exist_output_file(output_path))
  })
})
describe("Write trips summary", {
  it("write_trips_cummary", {
    output_path <- "/workdir/tests/trips_summary.csv"
    options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path)
    testtools::if_exist_remove(output_path)
    write_trips_summary(options)
    expect_true(testtools::exist_output_file(output_path))
    obtained <- readr::read_csv(output_path, show_col_types = FALSE)
    expected_columns <- c("tripID", "n_locs", "departure", "return", "duration", "total_dist")
    expect_true(all(expected_columns %in% colnames(obtained)))
    testtools::if_exist_remove(output_path)
  })
})

describe("Write trips geographic points", {
  it("write_trips", {
    output_path <- "/workdir/tests/trips_geographic_points.csv"
    options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path)
    testtools::if_exist_remove(output_path)
    write_trips(options)
    expect_true(testtools::exist_output_file(output_path))
    obtained <- readr::read_csv(output_path, show_col_types = FALSE)
    expected_columns <- c("tripID", "Latitude", "Longitude")
    expect_true(all(expected_columns %in% colnames(obtained)))
    testtools::if_exist_remove(output_path)
  })
})
describe("Define domain specific options", {
  obtained_options <- get_domain_specific_options()
  expected_options <- c("data-path", "config-path", "output-path")
  expect_true(all(expected_options %in% names(obtained_options)))
})
