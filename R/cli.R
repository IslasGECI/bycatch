write_trips_summary <- function(options) {
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_summary_of_trips(config_content) |>
    readr::write_csv(options[["output_path"]])
}
write_trips <- function(options) {
  options$config_path <- "/workdir/tests/data/trips_config.json"
  xxwrite_trips(options)
}

xxwrite_trips <- function(options, config_content) {
  config_content <- read_config(options[["config_path"]])
  trips <- readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_trips(config_content)
  trips@data |>
    readr::write_csv(options[["output_path"]])
}
