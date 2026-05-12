config_path <- "/workdir/tests/data/trips_config.json"

describe("filter gps data between dates", {
  output_path <- "/workdir/tests/filtered_gps.csv"
  input_path <- "/workdir/tests/data/raw_gps_albatros_guadalupe.csv"
  start <- "2014-02-01"
  end <- "2014-02-28"
  date_column <- "date"
  options <- list(
    "data-path" = input_path,
    "start" = start,
    "end" = end,
    "date-column-name" = date_column,
    "output-path" = output_path
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    filter_data_between_dates(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})

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

trips_path <- "/workdir/tests/data/trips_5_ids.csv"
describe("render potential kba", {
  output_path <- "/workdir/tests/kba.png"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "n-iterations" = 10,
    "population-size" = 10,
    "smoothing-method" = "log_median"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    withr::local_options(list(sf_use_s2 = sf::sf_use_s2()))
    render_potential_kba(options)
    expect_false(getOption("sf_use_s2"))
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})

describe("render representative assessment", {
  output_path <- "/workdir/tests/representative_assessment.png"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "n-iterations" = 10,
    "smoothing-method" = "scale_ARS"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    render_representative_assessment(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})

describe("plot map of individuals KDE", {
  output_path <- "/workdir/tests/kde_map.png"
  trips_path <- "/workdir/tests/data/trips.csv"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "smoothing-method" = "log_median"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    plot_individual_kernels(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
describe("Write trips summary", {
  it("write_trips_cummary", {
    output_path <- "/workdir/tests/trips_summary.csv"
    trips_path <- "/workdir/tests/data/trips.csv"
    options <- list("data-path" = trips_path, "config-path" = config_path, "output-path" = output_path)
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
    gps_path <- "/workdir/tests/data/raw_gps_albatros_guadalupe.csv"
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
