describe("Get trips from GECI data", {
  it("Calculate trips ids", {
    gps_data <- readr::read_csv("tests/data/bl_gps_albatros_guadalupe_20percent.csv", show_col_types = FALSE)
    obtained <- get_trips(gps_data)
    expect_true("tripID" %in% colnames(obtained@data))
  })
})
