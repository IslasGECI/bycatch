config_path <- "/workdir/tests/data/trips_config.json"
expected_kde_ars_hash <- "cf935c72a783c27d979961d782ea2a8a"

describe("create_individual_kde", {
  it("writes an RDS file with KDE computed using scaleARS", {
    output_path <- "/workdir/tests/test_individual_kde.rds"
    data_path <- "/workdir/tests/data/trips_5_ids.csv"
    options <- list(
      "data-path" = data_path,
      "config-path" = config_path,
      "output-path" = output_path,
      "percentage-distribution" = 50,
      "trips-summary-path" = "/workdir/tests/data/trips_summary.csv"
    )
    testtools::if_exist_remove(output_path)
    create_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    result <- readRDS(output_path)
    expect_true(all(c("KDE_surface", "UDPolygons", "tracks") %in% names(result)))
    obtained_hash <- tools::md5sum(output_path)
    expect_equal(unname(obtained_hash), expected_kde_ars_hash)
    testtools::if_exist_remove(output_path)
  })
})
