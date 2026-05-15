config_path <- "/workdir/tests/data/trips_config.json"

describe("render individual kde", {
  output_path <- "/workdir/tests/individual_kde.png"
  trips_path <- "/workdir/tests/data/trips.csv"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "smoothing-method" = "log_median"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    render_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
