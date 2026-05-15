config_path <- "/workdir/tests/data/trips_config.json"
trips_path <- "/workdir/tests/data/trips_5_ids.csv"

describe("render potential kba", {
  output_path <- "/workdir/tests/kba.png"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "n-iterations" = 10,
    "population-size" = 10,
    "smoothing-method" = "log_median"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    withr::local_options(list(sf_use_s2 = sf::sf_use_s2()))
    render_potential_kba(options)
    expect_false(getOption("sf_use_s2"))
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
