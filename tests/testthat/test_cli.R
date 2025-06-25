config_path <- "/workdir/tests/data/trips_config.json"

describe("process fisheries data", {
  output_path <- "/workdir/tests/filtered_fisheries_data.csv"
  fisheries_path <- "/workdir/tests/data/fisheries_data.csv"
  start <- "2014-01-01"
  end <- "2014-06-30"
  lat_min <- 11.87329
  lat_max <- 32.62694
  lon_min <- -122.174
  lon_max <- -92.21958
  options <- list("data-path" = fisheries_path, "start" = start, "end" = end, "lat-min" = lat_min, "lat-max" = lat_max, "lon-min" = lon_min, "lon-max" = lon_max, "output-path" = output_path)
  it("write figure", {
    testtools::if_exist_remove(output_path)
    process_fisheries_data(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})

describe("plot ussage area by a proportion of the total birds", {
  output_path <- "/workdir/tests/usage_area.png"
  gps_path <- "/workdir/tests/data/bl_sample_10_percent_5_ids.csv"
  options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path, "percentage-distribution" = 50, "n-iterations" = 10)
  it("write figure", {
    testtools::if_exist_remove(output_path)
    plot_usage_area_by_individual(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
describe("plot representative assess", {
  output_path <- "/workdir/tests/representative_assess.png"
  gps_path <- "/workdir/tests/data/bl_sample_10_percent_5_ids.csv"
  options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path, "percentage-distribution" = 50, "n-iterations" = 10)
  it("write figure", {
    testtools::if_exist_remove(output_path)
    plot_representative_assess(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
describe("plot map of individuals KDE", {
  output_path <- "/workdir/tests/kde_map.png"
  gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_10percent_sample.csv"
  options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path, "percentage-distribution" = 50)
  it("write figure", {
    testtools::if_exist_remove(output_path)
    plot_individual_kernels(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv"
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
  expected_options <- c("data-path", "config-path", "output-path", "percentage-distribution", "n-iterations")
  expect_true(all(expected_options %in% names(obtained_options)))
})
