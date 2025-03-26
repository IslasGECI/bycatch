describe("read configuration file", {
  config_path <- "tests/data/trips_config.json"
  obtained <- read_config(config_path)
  expected_keys <- c("inner_buff", "return_buff", "duration")
  expect_true(expected_keys %in% names(obtained))
})
