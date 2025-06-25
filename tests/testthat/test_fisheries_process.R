describe("Processes fisheries data", {
  fisheries_data <- tibble::tibble(
    Nombre = c("Test Fishery", "Sample Fishery", "Example Fishery"),
    FechaRecepcionUnitrac = c("2013-05-01T00:00:00Z", "2014-05-01T00:00:00Z", "2014-07-01T00:00:00Z"),
    Latitud = c(123.456, 123.456, 123.456),
    Longitud = c(-76.543, -76.543, -76.543)
  )
  obtained <- filter_fisheries_by_date(fisheries_data, start = "2014-01-01", end = "2014-06-30")
  expected_rows <- 1
  expect_equal(nrow(obtained), expected_rows)
})
