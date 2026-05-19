config_path <- "/workdir/tests/data/trips_config.json"

describe("create_potential_kba", {
  it("writes a valid GeoPackage file from cached assessment_summary and raw data", {
    cache_path <- "/workdir/tests/test_potential_kba_cache.rds"
    output_path <- "/workdir/tests/test_potential_kba.gpkg"
    data_path <- "/workdir/tests/data/trips_5_ids.csv"
    mock_cache <- list(assessment_summary = data.frame(out = 50))
    saveRDS(mock_cache, cache_path)
    options <- list(
      "data-path" = data_path,
      "config-path" = config_path,
      "output-path" = output_path,
      "rds-path" = cache_path,
      "percentage-distribution" = 50,
      "smoothing-method" = "log_median",
      "population-size" = 10
    )
    testtools::if_exist_remove(output_path)
    create_potential_kba(options)
    expect_true(testtools::exist_output_file(output_path))
    expect_gt(file.info(output_path)$size, 0)
    testtools::if_exist_remove(output_path)
    testtools::if_exist_remove(cache_path)
  })
})
