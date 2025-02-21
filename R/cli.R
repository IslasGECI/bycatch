write_trips_summary <- function(options) {
  readr::read_csv(options[["data_path"]], show_col_types = TRUE) |>
    readr::write_csv(options[["output_path"]])
}
