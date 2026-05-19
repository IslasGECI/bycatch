config_path <- "/workdir/tests/data/trips_config.json"

describe("Write trips geographic points", {
  it("write_trips", {
    output_path <- "/workdir/tests/trips_geographic_points.csv"
    gps_path <- "/workdir/tests/data/raw_gps_albatros_guadalupe.csv"
    options <- list("data-path" = gps_path, "config-path" = config_path, "output-path" = output_path)
    testtools::if_exist_remove(output_path)
    create_trips(options)
    expect_true(testtools::exist_output_file(output_path))
    obtained <- readr::read_csv(output_path, show_col_types = FALSE)
    expected_columns <- c("tripID", "Latitude", "Longitude")
    expect_true(all(expected_columns %in% colnames(obtained)))
    testtools::if_exist_remove(output_path)
  })
})
