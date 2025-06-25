describe("Processes fisheries data", {
  fisheries_data <- tibble::tibble(
    Nombre = c("Test Fishery", "Sample Fishery", "Example Fishery"),
    FechaRecepcionUnitrac = c("2013-05-01T00:00:00Z", "2014-05-01T00:00:00Z", "2014-07-01T00:00:00Z"),
    Latitude = c(123.456, 122.456, 125.456),
    Longitude = c(-76.543, -74.543, -78.543)
  )
  it("filters fisheries data by date range", {
    obtained <- filter_fisheries_by_date(fisheries_data, start = "2014-01-01", end = "2014-06-30")
    expected_rows <- 1
    expect_equal(nrow(obtained), expected_rows)
  })
  it("filter rows between latitude and longitude", {
    obtained <- filter_fisheries_by_lat_lon(fisheries_data, lat_min = 123.0, lat_max = 124.0, lon_min = -77.0, lon_max = -76.0)
    expected_rows <- 1
    expect_equal(nrow(obtained), expected_rows)
  })
  it("filters fisheries data by date range and latitude/longitude", {
    obtained <- filter_fisheries_by_date_and_lat_lon(fisheries_data, start = "2013-01-01", end = "2013-06-30", lat_min = 123.0, lat_max = 124.0, lon_min = -77.0, lon_max = -76.0)
    expected_rows <- 1
    expect_equal(nrow(obtained), expected_rows)
    fisheries_data <- readr::read_csv("/workdir/fisheries_gps_points_2014.csv")
    obtained <- filter_fisheries_by_date_and_lat_lon(fisheries_data, start = "2014-01-01", end = "2014-06-30", lat_min = 11.87329, lat_max = 32.62694, lon_min = -122.174, lon_max = -92.21958)
    obtained |> readr::write_csv("/workdir/eez_fisheries_gps_points_2014.csv")
  })
})
