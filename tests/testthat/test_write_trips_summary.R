config_path <- "/workdir/tests/data/trips_config.json"

describe("Write trips summary", {
  it("write_trips_cummary", {
    output_path <- "/workdir/tests/trips_summary.csv"
    trips_path <- "/workdir/tests/data/trips.csv"
    options <- list("data-path" = trips_path, "config-path" = config_path, "output-path" = output_path)
    testtools::if_exist_remove(output_path)
    create_trips_summary(options)
    expect_true(testtools::exist_output_file(output_path))
    obtained <- readr::read_csv(output_path, show_col_types = FALSE)
    expected_columns <- c("tripID", "n_locs", "departure", "return", "duration", "total_dist")
    expect_true(all(expected_columns %in% colnames(obtained)))
    testtools::if_exist_remove(output_path)
  })
})
