write_trips_summary <- function(options) {
  readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_summary_of_trips() |>
    readr::write_csv(options[["output_path"]])
}
write_trips <- function(options) {
  trips <- readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    get_trips()
  trips@data |>
    readr::write_csv(options[["output_path"]])
}
