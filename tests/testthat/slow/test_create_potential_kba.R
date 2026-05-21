describe("create_potential_kba", {
  it("writes a valid GeoPackage file from cached assessment data", {
    sf::sf_use_s2(FALSE)
    kde_path <- "/workdir/tests/test_individual_kde.rds"
    cache_path <- "/workdir/tests/test_potential_kba_cache.rds"
    output_path <- "/workdir/tests/test_potential_kba.gpkg"
    returning_trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = TRUE)
    tracks <- compute_project_returning_tracks(returning_trips)
    sum_trips <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
    scale_params <- compute_scale_parameters(tracks, sum_trips)
    kde <- compute_individual_kde(tracks, levelUD = 50, scale = scale_params$mag)
    saveRDS(kde, kde_path)
    cache <- list(
      KDE_surface = kde$KDE_surface,
      assessment_summary = data.frame(out = 50)
    )
    saveRDS(cache, cache_path)
    options <- list(
      "rds-path" = cache_path,
      "output-path" = output_path,
      "percentage-distribution" = 50,
      "population-size" = 10
    )
    testtools::if_exist_remove(output_path)
    create_potential_kba(options)
    expect_true(testtools::exist_output_file(output_path))
    expect_gt(file.info(output_path)$size, 0)
    testtools::if_exist_remove(kde_path)
    testtools::if_exist_remove(cache_path)
    testtools::if_exist_remove(output_path)
  })
})
