#' Plot Usage Area by Individual
#'
#' Generates and saves a usage area plot for all individuals based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, creates a `Track2KBA_Wrapper` object,
#' computes a representative assessment for the specified percentage distribution and number of iterations,
#' derives the site usage area, and saves the resulting plot as a PNG file to the specified output path.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the assessment.}
#'     \item{n-iterations}{Integer specifying the number of iterations for the assessment.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
plot_usage_area_by_individual <- function(options) {
  config_content <- read_config(options[["config-path"]])
  gps_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  n_iterations <- options[["n-iterations"]]

  wrapper <- Track2KBA_Wrapper$new(gps_data, config_content, percentage_distribution)
  representative_assess <- wrapper$get_representative_assess(percentage_distribution, n_iterations)
  site <- wrapper$get_site(representative_assess, percentage_distribution)
  grDevices::png(options[["output-path"]])
  track2KBA::mapSite(site)
  grDevices::dev.off()
}


#' Plot Representative Assessment
#'
#' Generates and saves a representative assessment plot based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, creates a `Track2KBA_Wrapper` object,
#' and generates a representative assessment plot for the specified percentage distribution and number of iterations.
#' The plot is saved as a PNG file to the specified output path.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the assessment.}
#'     \item{n-iterations}{Integer specifying the number of iterations for the assessment.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
plot_representative_assess <- function(options) {
  config_content <- read_config(options[["config-path"]])
  gps_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]

  wrapper <- Track2KBA_Wrapper$new(gps_data, config_content, percentage_distribution)
  grDevices::png(options[["output-path"]])
  wrapper$get_representative_assess(percentage_distribution, options[["n-iterations"]])
  grDevices::dev.off()
}

#' Plot Individual Kernels
#'
#' Generates and saves a plot of individual kernel density estimates (KDEs) for GPS data based on configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, creates a `Track2KBA_Wrapper` object,
#' computes the KDEs for the specified percentage distribution, and saves the resulting plot as a PNG file to the specified output path.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the KDE.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
plot_individual_kernels <- function(options) {
  config_content <- read_config(options[["config-path"]])
  gps_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]

  wrapper <- Track2KBA_Wrapper$new(gps_data, config_content, percentage_distribution)

  track2KBA::mapKDE(KDE = wrapper$KDE$UDPolygons, colony = config_content$colony)
  ggplot2::ggsave(filename = options[["output-path"]], device = "png")
}

#' Write Trips Summary
#'
#' Generates and writes a summary of trips based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, summarizes the trips using `get_summary_of_trips`,
#' and writes the summary to the specified output CSV file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output CSV summary will be saved.}
#'   }
#'
#' @return None. Called for its side effect of writing a summary to disk.
#' @export
write_trips_summary <- function(options) {
  config_content <- read_config(options[["config-path"]])
  readr::read_csv(options[["data-path"]], show_col_types = FALSE) |>
    get_summary_of_trips(config_content) |>
    readr::write_csv(options[["output-path"]])
}

#' Write Trips
#'
#' Extracts and writes trip data based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, extracts trip data using `get_trips`,
#' and writes the resulting data to the specified output CSV file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output CSV file will be saved.}
#'   }
#' @param config_content The configuration content as a list (optional, will be overwritten by reading from config-path).
#'
#' @return None. Called for its side effect of writing trip data to disk.
#' @export
write_trips <- function(options, config_content) {
  config_content <- read_config(options[["config-path"]])
  trips <- readr::read_csv(options[["data-path"]], show_col_types = FALSE) |>
    get_trips(config_content)
  trips@data |>
    readr::write_csv(options[["output-path"]])
}
process_fisheries_data <- function(options) {
  fisheries_raw_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  fisheries_data <- fisheries_raw_data |>
    filter_fisheries_by_date_and_lat_lon(
      start = options[["start"]],
      end = options[["end"]],
      lat_min = options[["lat-min"]],
      lat_max = options[["lat-max"]],
      lon_min = options[["lon-min"]],
      lon_max = options[["lon-max"]]
    )
  fisheries_data |>
    readr::write_csv(options[["output-path"]])
}

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
  data_path <- geci.optparse::character_option(c("-i", "--data-path"), default = "/workdir/reports/tables/input.csv", help = "File path of the desire input")
  config_path <- geci.optparse::character_option(c("-c", "--config-path"), default = "/workdir/reports/non-tabular/config_file.json", help = "File path of the configuration")
  output_path <- geci.optparse::character_option(c("-o", "--output-path"), default = "/workdir/reports/tables/result.csv", help = "File path of the desire output")
  percentage_distribution <- geci.optparse::integer_option(c("-p", "--percentage-distribution"), default = 50)
  n_iterations <- geci.optparse::integer_option(c("-n", "--n-iterations"), default = 10)
  option_names <- c(data_path, config_path, output_path, percentage_distribution, n_iterations)
  geci.optparse::get_options_from_vec(option_names)
}
