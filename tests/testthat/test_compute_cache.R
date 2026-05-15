describe("compute_cache", {
  it("returns list with assessment_summary and assessment_detail", {
    sf::sf_use_s2(FALSE)
    data <- readRDS("/workdir/tests/data/completed_trips.rds")
    colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
    config <- list(colony = colony_df)

    result <- compute_cache(data, config, levelUD = 50, smoothing_method = "log_median", n_iterations = 1)

    expect_type(result, "list")
    expect_true(all(c("assessment_summary", "assessment_detail") %in% names(result)))
    expect_true(inherits(result$assessment_summary, "data.frame"))
    expect_true(inherits(result$assessment_detail, "data.frame"))
  })
})
