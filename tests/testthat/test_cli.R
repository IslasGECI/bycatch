gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv"
config_path <- "/workdir/tests/data/trips_config.json"

describe("Write trips summary", {
  it("write_trips_cummary", {
    output_path <- "/workdir/tests/trips_summary.csv"
    options <- list("data_path" = gps_path, "config_path" = config_path, "output_path" = output_path)
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
    options <- list("data_path" = gps_path, "config_path" = config_path, "output_path" = output_path)
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
  expected_options <- c("data_path", "config_path", "output_path")
  expect_true(all(expected_options %in% names(obtained_options)))
})
