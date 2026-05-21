#' Render Potential KBA
#'
#' Reads a pre-computed GeoPackage file containing potential KBA polygons and
#' saves the resulting map as a PNG file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{gpkg-path}{Path to the input GeoPackage file with KBA polygons.}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
render_potential_kba <- function(options) {
  site <- sf::st_read(options[["gpkg-path"]], quiet = TRUE)
  plot <- plot_potential_kba(site)
  ggplot2::ggsave(filename = options[["output-path"]], plot = plot, device = "png")
}

#' Render Representative Assessment
#'
#' Reads a cached RDS file (assessment_detail) and saves the representative
#' assessment scatterplot as a PNG file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{rds-path}{Path to the cached RDS file with assessment_summary and assessment_detail.}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
render_representative_assessment <- function(options) {
  cache <- readRDS(options[["rds-path"]])
  assessment_detail <- cache$assessment_detail
  plot <- plot_representative_assessment(assessment_detail)
  ggplot2::ggsave(filename = options[["output-path"]], plot = plot, device = "png")
}

#' Render Individual KDE
#'
#' Reads a pre-computed GeoPackage file containing UDPolygons and saves the
#' resulting KDE map as a PNG file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{gpkg-path}{Path to the input GeoPackage file with UDPolygons.}
#'     \item{output-path}{Path where the output PNG plot will be saved.}
#'   }
#'
#' @return None. Called for its side effect of saving a plot to disk.
#' @export
render_individual_kde <- function(options) {
  ud_polygons <- sf::st_read(options[["gpkg-path"]], quiet = TRUE)
  plot <- plot_individual_kde(ud_polygons)
  ggplot2::ggsave(filename = options[["output-path"]], plot = plot, device = "png")
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
  config_content <- import_config(options[["config-path"]])
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
#'
#' @return None. Called for its effect of writing trip data to disk.
#' @export
create_trips <- function(options) {
  config_content <- import_config(options[["config-path"]])
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

#' Create Individual KDE
#'
#' Reads GPS data and configuration, computes kernel density estimates (KDEs)
#' for each tracked individual, and saves the resulting UDPolygons as a GeoPackage file.
#' Recomputes the fast pipeline from scratch (no bootstrap).
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output GeoPackage file will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for KDE.}
#'     \item{smoothing-method}{Character string specifying the smoothing method for KDE.}
#'   }
#'
#' @return None. Called for its side effect of writing a GeoPackage file to disk.
#' @export
create_individual_kde <- function(options) {
  returning_trips <- import_trips(options[["data-path"]], filter_returning = TRUE)
  tracks <- compute_project_returning_tracks(returning_trips)
  sum_trips <- import_trips_summary(options[["trips-summary-path"]])
  scale_params <- compute_scale_parameters(tracks, sum_trips)
  scale <- scale_params$mag
  levelUD <- options[["percentage-distribution"]]

  kde <- compute_individual_kde(tracks, levelUD, scale)
  saveRDS(kde, options[["output-path"]])
}

#' Create Potential KBA
#'
#' Reads a cached RDS file (assessment data with KDE_surface and
#' assessment_summary), identifies potential Key Biodiversity Areas (KBAs),
#' and saves the result as a GeoPackage file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{rds-path}{Path to the cached RDS file with KDE_surface and assessment_summary.}
#'     \item{output-path}{Path where the output GeoPackage file will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for KDE.}
#'     \item{population-size}{Integer specifying the population size for KBA identification.}
#'   }
#'
#' @return None. Called for its side effect of writing a GeoPackage file to disk.
#' @export
create_potential_kba <- function(options) {
  cache <- readRDS(options[["rds-path"]])
  KDE_surface <- cache$KDE_surface
  represent <- cache$assessment_summary$out
  popSize <- options[["population-size"]]
  levelUD <- options[["percentage-distribution"]]

  site <- compute_potential_kba(KDE_surface, represent, popSize, levelUD)
  sf::st_write(site, options[["output-path"]])
}

#' Create Representative Assessment
#'
#' Reads a cached RDS file (individual KDE), runs the bootstrap assessment,
#' and caches the assessment_summary and assessment_detail as an RDS file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{rds-path}{Path to the cached RDS file with KDE_surface and tracks.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the assessment.}
#'     \item{n-iterations}{Integer specifying the number of bootstrap iterations.}
#'     \item{output-path}{Path where the output RDS file will be saved.}
#'   }
#'
#' @return None. Called for its side effect of writing an RDS file to disk.
#' @export
create_representative_assessment <- function(options) {
  cache <- readRDS(options[["rds-path"]])
  KDE_surface <- cache$KDE_surface
  tracks <- cache$tracks
  levelUD <- options[["percentage-distribution"]]
  n_iterations <- options[["n-iterations"]]

  result <- compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)
  result$KDE_surface <- KDE_surface
  saveRDS(result, options[["output-path"]])
}
