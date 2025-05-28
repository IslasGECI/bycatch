Wrapper_Tester <- R6::R6Class(
  "Wrapper_Tester",
  inherit = Track2KBA_Wrapper,
  public = list(
    initialize = function() {
    }
  )
)
describe("Check representativity", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_10percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  percentage_distribution <- 50
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
    obtained_kde <- obtained$calculate_kde()
    expect_true(all(c("KDE.Surface", "UDPolygons") %in% names(obtained_kde)))
    number_of_individuals <- 3
    expect_equal(nrow(obtained_kde$UDPolygons), number_of_individuals)
    obtained_area <- sum(obtained_kde$UDPolygons$area)
    expected_area <- 17929
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)

    percentage_distribution <- 75
    obtained_kde <- obtained$calculate_kde(percentage_distribution)
    obtained_area <- sum(obtained_kde$UDPolygons$area)
    expected_area <- 44250
    expect_equal(obtained_area, expected_area, tolerance = 1e-3)
  })
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv", show_col_types = FALSE)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  obtained <- Track2KBA_Wrapper$new(gps_data, config_content, percentage_distribution)
  obtained_repr <- obtained$get_representative_assess(percentage_distribution)
  it("get representative assess with percentage distribution", {
    expect_true(inherits(obtained_repr, "data.frame"))
  })
  it("Get potential site", {
    obtained_site <- obtained$get_site()
    expect_true(inherits(obtained_site, "SpatialPixelsDataFrame"))
  })
})
