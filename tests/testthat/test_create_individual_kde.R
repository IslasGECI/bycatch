config_path <- "/workdir/tests/data/trips_config.json"

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
    # Verify scaleARS was used by checking UD polygon areas.
    # Using scaleARS (7) gives larger areas than the old default parameter mag (5.55).
    # Thresholds are midpoints between mag and scaleARS values, rounded to nearest 1000.
    # mag: sum=78326, max=28568 | scaleARS: sum=112773, max=43801
    total_area <- sum(result$UDPolygons$area)
    expect_gt(total_area, 96000)
    max_area <- max(result$UDPolygons$area)
    expect_gt(max_area, 36000)
    testtools::if_exist_remove(output_path)
  })
})
