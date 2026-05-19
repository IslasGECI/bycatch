describe("process fisheries data", {
  output_path <- "/workdir/tests/filtered_fisheries_data.csv"
  fisheries_path <- "/workdir/tests/data/fisheries_data.csv"
  start <- "2014-01-01"
  end <- "2014-06-30"
  lat_min <- 11.87329
  lat_max <- 32.62694
  lon_min <- -122.174
  lon_max <- -92.21958
  options <- list("data-path" = fisheries_path, "start" = start, "end" = end, "lat-min" = lat_min, "lat-max" = lat_max, "lon-min" = lon_min, "lon-max" = lon_max, "output-path" = output_path)
  it("write figure", {
    testtools::if_exist_remove(output_path)
    create_filtered_fisheries(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
