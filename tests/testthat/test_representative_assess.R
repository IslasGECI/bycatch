describe("Check representativity", {
  gps_data <- readr::read_csv("/workdir/tests/data/bl_gps_albatros_guadalupe_10percent_sample.csv", show_col_types = FALSE)
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  it("repAsses", {
    obtained <- Track2KBA_Wrapper$new(gps_data, config_content)
  })
})
