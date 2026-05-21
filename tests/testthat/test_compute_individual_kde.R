describe("compute_individual_kde", {
  it("returns list with KDE_surface, UDPolygons, and tracks", {
    sf::sf_use_s2(FALSE)
    returning_trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = TRUE)
    tracks <- compute_project_returning_tracks(returning_trips)
    sum_trips <- readr::read_csv("/workdir/tests/data/trips_summary.csv", show_col_types = FALSE)
    scale_params <- compute_scale_parameters(tracks, sum_trips)
    scale <- scale_params$mag

    result <- compute_individual_kde(tracks, levelUD = 50, scale = scale)

    expect_type(result, "list")
    expect_true(all(c("KDE_surface", "UDPolygons", "tracks") %in% names(result)))
    expect_true(inherits(result$KDE_surface, "estUDm"))
    expect_true(inherits(result$UDPolygons, "sf"))
    expect_true(inherits(result$tracks, "SpatialPointsDataFrame"))
  })
})
