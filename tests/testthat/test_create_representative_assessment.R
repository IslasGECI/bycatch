describe("create_representative_assessment", {
  it("writes an RDS file with assessment_summary, assessment_detail, and KDE_surface", {
    kde_path <- "/workdir/tests/test_individual_kde.rds"
    output_path <- "/workdir/tests/test_assessment.rds"
    returning_trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = TRUE)
    tracks <- compute_project_returning_tracks(returning_trips)
    sum_trips <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
    scale_params <- compute_scale_parameters(tracks, sum_trips)
    kde <- compute_individual_kde(tracks, levelUD = 50, scale = scale_params$mag)
    saveRDS(kde, kde_path)
    options <- list(
      "rds-path" = kde_path,
      "percentage-distribution" = 50,
      "n-iterations" = 1,
      "output-path" = output_path
    )
    testtools::if_exist_remove(output_path)
    create_representative_assessment(options)
    expect_true(testtools::exist_output_file(output_path))
    result <- readRDS(output_path)
    expect_true(all(c("assessment_summary", "assessment_detail", "KDE_surface") %in% names(result)))
    testtools::if_exist_remove(kde_path)
    testtools::if_exist_remove(output_path)
  })
})
