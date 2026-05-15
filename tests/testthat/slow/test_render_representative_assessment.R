config_path <- "/workdir/tests/data/trips_config.json"
trips_path <- "/workdir/tests/data/trips_5_ids.csv"

describe("render representative assessment", {
  output_path <- "/workdir/tests/representative_assessment.png"
  options <- list(
    "data-path" = trips_path,
    "config-path" = config_path,
    "output-path" = output_path,
    "percentage-distribution" = 50,
    "n-iterations" = 10,
    "smoothing-method" = "scale_ARS"
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    render_representative_assessment(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
