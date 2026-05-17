describe("compute_individual_kde", {
  it("returns list with KDE_surface, UDPolygons, and tracks", {
    sf::sf_use_s2(FALSE)
    data <- readRDS("/workdir/tests/data/completed_trips.rds")
    colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
    config <- list(colony = colony_df)

    result <- compute_individual_kde(data, config, levelUD = 50, smoothing_method = "log_median")

    expect_type(result, "list")
    expect_true(all(c("KDE_surface", "UDPolygons", "tracks") %in% names(result)))
    expect_true(inherits(result$KDE_surface, "estUDm"))
    expect_true(inherits(result$UDPolygons, "sf"))
    expect_true(inherits(result$tracks, "SpatialPointsDataFrame"))
    number_of_individuals <- 3
    expect_equal(nrow(result$UDPolygons), number_of_individuals)
    obtained_area <- sum(result$UDPolygons$area)
    expected_area <- 17929
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)

    result_75 <- compute_individual_kde(data, config, levelUD = 75, smoothing_method = "log_median")
    obtained_area_75 <- sum(result_75$UDPolygons$area)
    expected_area_75 <- 44250
    expect_equal(obtained_area_75, expected_area_75, tolerance = 1e-3)
  })
})
