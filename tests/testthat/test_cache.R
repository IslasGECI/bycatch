config_path <- "/workdir/tests/data/trips_config.json"

describe("create_individual_kde", {
  it("writes a valid GeoPackage file", {
    output_path <- "/workdir/tests/test_individual_kde.gpkg"
    data_path <- "/workdir/tests/data/trips_5_ids.csv"
    options <- list(
      "data-path" = data_path,
      "config-path" = config_path,
      "output-path" = output_path,
      "percentage-distribution" = 50,
      "smoothing-method" = "log_median"
    )
    testtools::if_exist_remove(output_path)
    create_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    expect_gt(file.info(output_path)$size, 0)
    testtools::if_exist_remove(output_path)
  })
})

describe("create_processed_data", {
  it("writes a valid RDS file with assessment_summary and assessment_detail", {
    output_path <- "/workdir/tests/test_processed_data.rds"
    data_path <- "/workdir/tests/data/trips_5_ids.csv"
    options <- list(
      "data-path" = data_path,
      "config-path" = config_path,
      "output-path" = output_path,
      "percentage-distribution" = 50,
      "smoothing-method" = "log_median",
      "n-iterations" = 1
    )
    testtools::if_exist_remove(output_path)
    create_processed_data(options)
    expect_true(testtools::exist_output_file(output_path))
    result <- readRDS(output_path)
    expect_true(all(c("assessment_summary", "assessment_detail") %in% names(result)))
    expect_true(inherits(result$assessment_summary, "data.frame"))
    expect_true(inherits(result$assessment_detail, "data.frame"))
    testtools::if_exist_remove(output_path)
  })
})

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
