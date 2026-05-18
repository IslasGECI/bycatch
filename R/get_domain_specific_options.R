#' Get Domain Specific Options
#'
#' Defines and retrieves command-line options specific to the domain for use in CLI tools.
#'
#' This function sets up options for data path, configuration path, output path, percentage distribution,
#' and number of iterations, and returns them as a named list.
#'
#' @return A named list of command-line options for use in CLI tools.
#' @export
get_domain_specific_options <- function() {
  data_path <- gecioptparse::character_option(c("-i", "--data-path"), default = "/workdir/reports/tables/input.csv", help = "File path of the desire input")
  config_path <- gecioptparse::character_option(c("-c", "--config-path"), default = "/workdir/reports/non-tabular/config_file.json", help = "File path of the configuration")
  output_path <- gecioptparse::character_option(c("-o", "--output-path"), default = "/workdir/reports/tables/result.csv", help = "File path of the desire output")
  gpkg_path <- gecioptparse::character_option(c("-g", "--gpkg-path"), default = "", help = "Path to input GeoPackage (KBA polygons or UD polygons)")
  rds_path <- gecioptparse::character_option(c("-r", "--rds-path"), default = "", help = "Path to input RDS cache file")
  percentage_distribution <- gecioptparse::integer_option(c("-d", "--percentage-distribution"), default = 50)
  n_iterations <- gecioptparse::integer_option(c("-n", "--n-iterations"), default = 10)
  start <- gecioptparse::character_option(c("-s", "--start"), default = "2014-01-01", help = "start date for filtering fisheries data")
  end <- gecioptparse::character_option(c("-e", "--end"), default = "2015-01-01", help = "End date for filtering fisheries data")
  lat_min <- gecioptparse::double_option(c("-l", "--lat-min"), default = 0, help = "Minimum latitude for filtering fisheries data")
  lat_max <- gecioptparse::double_option(c("-a", "--lat-max"), default = 0, help = "Maximum longitude for filtering fisheries data")
  lon_min <- gecioptparse::double_option(c("-m", "--lon-min"), default = 0, help = "Minimum longitude for filtering fisheries data")
  lon_max <- gecioptparse::double_option(c("-x", "--lon-max"), default = 0, help = "Maximum longitude for filtering fisheries data")
  population_size <- gecioptparse::integer_option(c("-p", "--population-size"), default = 1551)
  smoothing_method <- gecioptparse::character_option(c("-z", "--smoothing-method"), default = "log_median", help = "Method to compute the smoothing parameter h")
  column_name <- gecioptparse::character_option(c("-t", "--date-column-name"), default = "Fecha", help = "Name of date column to filter")
  option_names <- c(data_path, config_path, output_path, gpkg_path, rds_path, percentage_distribution, n_iterations, start, end, lat_min, lat_max, lon_min, lon_max, population_size, smoothing_method, column_name)
  gecioptparse::get_options_from_vec(option_names)
}
