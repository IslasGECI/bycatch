config_path <- "/workdir/tests/data/trips_config.json"

describe("create_individual_kde", {
  it("writes an RDS file with KDE_surface, UDPolygons, and tracks", {
    output_path <- "/workdir/tests/test_individual_kde.rds"
    data_path <- "/workdir/tests/data/trips_5_ids.csv"
    options <- list(
      "data-path" = data_path,
      "config-path" = config_path,
      "output-path" = output_path,
      "percentage-distribution" = 50,
      "smoothing-method" = "log_median",
      "trips-summary-path" = "/workdir/tests/data/trips_summary.csv"
    )
    testtools::if_exist_remove(output_path)
    create_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    result <- readRDS(output_path)
    expect_true(all(c("KDE_surface", "UDPolygons", "tracks") %in% names(result)))
    testtools::if_exist_remove(output_path)
  })
})
