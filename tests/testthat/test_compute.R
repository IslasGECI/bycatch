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
  })
})

describe("compute_representative_assessment", {
  it("returns list with assessment_summary and assessment_detail", {
    sf::sf_use_s2(FALSE)
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

describe("compute_potential_kba", {
  it("returns sf object with potential KBA polygons", {
    sf::sf_use_s2(FALSE)
    kde_data <- readRDS("/workdir/tests/data/kde_20percent_sample.rds")

    result <- compute_potential_kba(
      KDE_surface = kde_data$KDE.Surface,
      represent = 59.30424,
      popSize = 10,
      levelUD = 50
    )

    expect_true(inherits(result, "sf"))
    expect_true(all(c("N_IND", "N_animals", "potentialSite") %in% colnames(result)))
  })
})
