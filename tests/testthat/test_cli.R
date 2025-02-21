describe("Write trips summary", {
  it("write_trips_cummary", {
    gps_path <- "/workdir/tests/data/bl_gps_albatros_guadalupe_20percent_sample.csv"
    output_path <- "/workdir/tests/trips_summary.csv"
    options <- list("data_path" = gps_path, "output_path" = output_path)
    testtools::if_exist_remove(output_path)
    write_trips_summary(options)
    expect_true(testtools::exist_output_file(output_path))
  })
})
