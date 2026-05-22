describe("compute_representative_assessment", {
  it("returns list with assessment_summary and assessment_detail", {
    kde_data <- readRDS("/workdir/tests/data/kde_20percent_sample.rds")
    tracks <- readRDS("/workdir/tests/data/tracks_20percent_sample.rds")

    result <- compute_representative_assessment(
      KDE_surface = kde_data$KDE.Surface,
      tracks = tracks,
      levelUD = 50,
      n_iterations = 1
    )

    expect_type(result, "list")
    expect_true(all(c("assessment_summary", "assessment_detail") %in% names(result)))
    expect_true(inherits(result$assessment_summary, "data.frame"))
    expect_true(inherits(result$assessment_detail, "data.frame"))
    expected_out <- 59.30424
    expect_equal(result$assessment_summary$out, expected_out, tolerance = 1e-3)
  })
})
