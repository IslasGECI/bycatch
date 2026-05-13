describe("compute_space_use", {
  it("returns list with KDE_surface, UDPolygons, colony, and tracks", {
    sf::sf_use_s2(FALSE)
    data <- readRDS("/workdir/tests/data/completed_trips.rds")
    colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
    config <- list(colony = colony_df)

    result <- compute_space_use(data, config, levelUD = 50, smoothing_method = "log_median")

    expect_type(result, "list")
    expect_true(all(c("KDE_surface", "UDPolygons", "colony", "tracks") %in% names(result)))
    expect_true(inherits(result$KDE_surface, "estUDm"))
    expect_true(inherits(result$UDPolygons, "sf"))
    expect_true(inherits(result$tracks, "SpatialPointsDataFrame"))
    expect_s3_class(result$colony, "tbl_df")
    number_of_individuals <- 3
    expect_equal(nrow(result$UDPolygons), number_of_individuals)
  })
})
