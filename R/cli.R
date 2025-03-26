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
get_domain_specific_options <- function() {
  data_path <- geci.optparse::character_option(c("-i", "--data_path"), default = "/workdir/reports/tables/input.csv", help = "File path of the desire input")
  config_path <- geci.optparse::character_option(c("-c", "--config_path"), default = "/workdir/reports/non-tabular/config_file.json", help = "File path of the configuration")
  output_path <- geci.optparse::character_option(c("-o", "--output_path"), default = "/workdir/reports/tables/result.csv", help = "File path of the desire output")
  option_names <- c(data_path, config_path, output_path)
  geci.optparse::get_options_from_vec(option_names)
}
