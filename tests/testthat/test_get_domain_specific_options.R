describe("Define domain specific options", {
  obtained_options <- get_domain_specific_options()
  expected_options <- c("data-path", "config-path", "output-path", "percentage-distribution", "n-iterations", "start", "end", "lat-min", "lat-max", "lon-min", "lon-max", "population-size", "smoothing-method")
  expect_true(all(expected_options %in% names(obtained_options)))
})
