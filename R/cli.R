.adapt_config <- function(config_path) {
  json_content <- rjson::fromJSON(file = config_path)
  json_content$colony <- tibble::tibble(
    Longitude = json_content$lon_colony,
    Latitude  = json_content$lat_colony
  )
  json_content
}

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
  config_content <- .adapt_config(options[["config-path"]])
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  n_iterations <- options[["n-iterations"]]
  smoothing_method <- options[["smoothing-method"]]

  sf::sf_use_s2(FALSE)
  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)
  representative_assess <- wrapper$compute_representative_assessment(percentage_distribution, n_iterations)
  site <- wrapper$compute_potential_kba(representative_assess, percentage_distribution, population_size = options[["population-size"]])
  valid_site <- sf::st_make_valid(site)
  track2KBA::mapSite(valid_site)
  ggplot2::ggsave(filename = options[["output-path"]], device = "png")
}

#' Render Representative Assessment
#'
#' Reads GPS data and configuration, computes the representative assessment,
#' and saves the resulting plot as a PNG file.
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
render_representative_assessment <- function(options) {
  config_content <- .adapt_config(options[["config-path"]])
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]

  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)
  grDevices::png(options[["output-path"]])
  wrapper$compute_representative_assessment(percentage_distribution, options[["n-iterations"]])
  grDevices::dev.off()
}

#' Render Individual KDE
#'
#' Reads GPS data and configuration, computes kernel density estimates (KDEs)
#' for each tracked individual, and saves the resulting map as a PNG file.
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
render_individual_kde <- function(options) {
  config_content <- .adapt_config(options[["config-path"]])
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]

  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)

  track2KBA::mapKDE(KDE = wrapper$KDE$UDPolygons, colony = config_content$colony)
  ggplot2::ggsave(filename = options[["output-path"]], device = "png")
}

#' Create Trips Summary
#'
#' Generates and writes a summary of trips based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths, summarizes the trips using `compute_trips_summary`,
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
create_trips_summary <- function(options) {
  config_content <- .adapt_config(options[["config-path"]])
  readr::read_csv(options[["data-path"]], show_col_types = FALSE) |>
    compute_trips_summary(config_content) |>
    readr::write_csv(options[["output-path"]])
}

#' Create Trips
#'
#' Extracts and writes trip data based on GPS data and configuration settings.
#'
#' This function reads configuration and GPS data from the provided file paths,
#' extracts trip data using `compute_trips`, and writes the resulting data to the
#' specified output CSV file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output CSV file will be saved.}
#'   }
#' @param config_content The configuration content as a list (optional, will be overwritten by reading from config-path).
#'
#' @return None. Called for its effect of writing trip data to disk.
#' @export
create_trips <- function(options, config_content) {
  config_content <- .adapt_config(options[["config-path"]])
  trips <- readr::read_csv(options[["data-path"]], show_col_types = FALSE) |>
    compute_trips(config_content)
  trips@data |>
    readr::write_csv(options[["output-path"]])
}

#' Create Filtered Fisheries Data
#'
#' Reads fisheries GPS data, filters by date and geographic boundaries,
#' and writes the result to a CSV file.
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
#' @return None. Called for its side effect of writing filtered data to disk.
#' @export
create_filtered_fisheries <- function(options) {
  fisheries_raw_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  fisheries_data <- fisheries_raw_data |>
     compute_filtered_fisheries_by_date_and_lat_lon(
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

#' Create Filtered GPS Data Between Dates
#'
#' Reads GPS data, filters it between two dates, and writes the result to a CSV file.
#'
#' @param options A named list with elements:
#'   \describe{
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{start}{Start date (inclusive).}
#'     \item{end}{End date (inclusive).}
#'     \item{date-column-name}{Name of the date column.}
#'     \item{output-path}{Path for the output CSV file.}
#'   }
#' @return None. Called for its side effect of writing filtered data to disk.
#' @export
create_filtered_gps_between_dates <- function(options) {
  raw_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  filtered_data <- raw_data |>
    compute_filtered_between_dates(
      start = options[["start"]],
      end = options[["end"]],
      !!rlang::sym(options[["date-column-name"]])
    )
  filtered_data |>
    readr::write_csv(options[["output-path"]])
}
