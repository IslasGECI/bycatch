describe("filter gps data between dates", {
  output_path <- "/workdir/tests/filtered_gps.csv"
  input_path <- "/workdir/tests/data/raw_gps_albatros_guadalupe.csv"
  start <- "2014-02-01"
  end <- "2014-02-28"
  date_column <- "date"
  options <- list(
    "data-path" = input_path,
    "start" = start,
    "end" = end,
    "date-column-name" = date_column,
    "output-path" = output_path
  )
  it("write figure", {
    testtools::if_exist_remove(output_path)
    create_filtered_gps_between_dates(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
  })
})
