#' Render Potential KBA
#'
#' Reads GPS data and configuration, computes the representative assessment and
#' potential Key Biodiversity Area (KBA), and saves the resulting map as a PNG file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the assessment.}
#'     \item{n-iterations}{Integer specifying the number of iterations for the assessment.}
#'     \item{population-size}{Integer specifying the population size for site identification.}
#'     \item{smoothing-method}{Character string specifying the smoothing method for KDE.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
render_potential_kba <- function(options) {
  config_content <- read_config(options[["config-path"]])
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  n_iterations <- options[["n-iterations"]]
  smoothing_method <- options[["smoothing-method"]]

  sf::sf_use_s2(FALSE)
  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)
  representative_assess <- wrapper$get_representative_assess(percentage_distribution, n_iterations)
  site <- wrapper$compute_potential_kba(representative_assess, percentage_distribution, population_size = options[["population-size"]])
  valid_site <- sf::st_make_valid(site)
  track2KBA::mapSite(valid_site)
  ggplot2::ggsave(filename = options[["output-path"]], device = "png")
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
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]

  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)
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
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]

  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)

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

#' Process Fisheries Data
#'
#' Filters and processes raw fisheries GPS data based on date and geographic boundaries, then writes the filtered data to a CSV file.
#'
#' This function reads fisheries GPS data from the specified input file, filters the data according to the provided date range and latitude and longitude bounds, and writes the resulting filtered data to the specified output file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{data-path}{Path to the input fisheries GPS data file (CSV).}
#'     \item{output-path}{Path where the filtered output CSV file will be saved.}
#'     \item{start}{Start date for filtering (inclusive).}
#'     \item{end}{End date for filtering (inclusive).}
#'     \item{lat-min}{Minimum latitude for filtering.}
#'     \item{lat-max}{Maximum latitude for filtering.}
#'     \item{lon-min}{Minimum longitude for filtering.}
#'     \item{lon-max}{Maximum longitude for filtering.}
#'   }
#'
#' @return None. Called for its side effect of writing filtered data to disk.
#' @export
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

#' @export
filter_data_between_dates <- function(options) {
  raw_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  filtered_data <- raw_data |>
    filter_between_dates(
      start = options[["start"]],
      end = options[["end"]],
      !!rlang::sym(options[["date-column-name"]])
    )
  filtered_data |>
    readr::write_csv(options[["output-path"]])
}
