write_trips_summary <- function(options) {
  config_content <- read_config(options[["config_path"]])
  readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_summary_of_trips(config_content) |>
    readr::write_csv(options[["output_path"]])
}
write_trips <- function(options, config_content) {
  config_content <- read_config(options[["config_path"]])
  trips <- readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_trips(config_content)
  trips@data |>
    readr::write_csv(options[["output_path"]])
}
