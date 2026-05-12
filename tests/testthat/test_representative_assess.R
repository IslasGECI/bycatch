Wrapper_Tester <- R6::R6Class(
  "Wrapper_Tester",
  inherit = Track2KBA_Wrapper,
  public = list(
    initialize = function() {}
  )
)
describe("Check representativity", {
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  percentage_distribution <- 50
  it("get scale dictionary", {
    obtained <- Wrapper_Tester$new()
    obtained$complete_trips <- readRDS("/workdir/tests/data/completed_trips.rds")
    obtained$colony <- colony_df
    obtained$tracks <- readRDS("/workdir/tests/data/tracks.rds")
    obtained_scale_dictionary <- obtained$get_scale_dictionary()
    expected_names <- c("log_median", "reference_bandwidth", "scale_ARS")
    expect_true(all(names(obtained_scale_dictionary) %in% expected_names))
  })
  it("Get tracks", {
    obtained <- Wrapper_Tester$new()
    obtained$complete_trips <- readRDS("/workdir/tests/data/completed_trips.rds")
    obtained_tracks <- obtained$get_tracks()
    expect_true(inherits(obtained_tracks, "SpatialPointsDataFrame"))
  })
  it("Get KDE", {
    obtained <- Wrapper_Tester$new()
    obtained$complete_trips <- readRDS("/workdir/tests/data/completed_trips.rds")
    obtained$colony <- colony_df
    obtained$tracks <- readRDS("/workdir/tests/data/tracks.rds")
    obtained$smoothing_method <- "log_median"
    percentage_distribution <- 50
    obtained_kde <- obtained$estimate_space_use(percentage_distribution)
    expect_true(all(c("KDE.Surface", "UDPolygons") %in% names(obtained_kde)))
    number_of_individuals <- 3
    expect_equal(nrow(obtained_kde$UDPolygons), number_of_individuals)
    obtained_area <- sum(obtained_kde$UDPolygons$area)
    expected_area <- 17929
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)

    percentage_distribution <- 75
    obtained_kde <- obtained$estimate_space_use(percentage_distribution)
    obtained_area <- sum(obtained_kde$UDPolygons$area)
    expected_area <- 44250
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)
  })
})
describe("Get representative assess", {
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  percentage_distribution <- 50
  obtained <- Wrapper_Tester$new()
  obtained$colony <- colony_df
  obtained$tracks <- readRDS("/workdir/tests/data/tracks_20percent_sample.rds")
  obtained$KDE <- readRDS("/workdir/tests/data/kde_20percent_sample.rds")
  n_iterations <- 1
  obtained_repr <- obtained$compute_representative_assessment(percentage_distribution, n_iterations)
  it("get representative assess with percentage distribution", {
    expect_true(inherits(obtained_repr, "data.frame"))
    expected_rep_out <- 59.30424
    expect_equal(obtained_repr$out, expected_rep_out, tolerance = 1e-3)
  })
})
