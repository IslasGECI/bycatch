describe("read configuration file", {
  config_path <- "/workdir/tests/data/trips_config.json"
  obtained <- read_config(config_path)
  it("Expected parameters", {
    expected_keys <- c("inner_buff", "return_buff", "duration", "colony")
    expect_true(all(expected_keys %in% names(obtained)))
  })
  it("colony structure", {
    expect_true(tibble::is_tibble(obtained$colony))
  })
})
