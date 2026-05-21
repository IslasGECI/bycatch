describe("Define domain specific options", {
  obtained_options <- get_domain_specific_options()
  expected_options <- c(
    "config-path",
    "data-path",
    "date-column-name",
    "end",
    "gpkg-path",
    "lat-max",
    "lat-min",
    "lon-max",
    "lon-min",
    "n-iterations",
    "output-path",
    "percentage-distribution",
    "population-size",
    "rds-path",
    "smoothing-method",
    "start",
    "trips-summary-path"
  )
  expect_true(all(expected_options %in% names(obtained_options)))
})
