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
  config_content <- .adapt_config(options[["config-path"]])
  data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  levelUD <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]

  kde <- compute_individual_kde(data, config_content, levelUD, smoothing_method)
  sf::st_write(kde$UDPolygons, options[["output-path"]])
}

#' Create Processed Data
#'
#' Reads GPS data and configuration, runs the full bootstrap pipeline
#' (compute_individual_kde + compute_representative_assessment) exactly once,
#' and caches the assessment_summary and assessment_detail as an RDS file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output RDS file will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for the assessment.}
#'     \item{smoothing-method}{Character string specifying the smoothing method for KDE.}
#'     \item{n-iterations}{Integer specifying the number of bootstrap iterations.}
#'   }
#'
#' @return None. Called for its side effect of writing an RDS cache file to disk.
#' @export
create_processed_data <- function(options) {
  config_content <- .adapt_config(options[["config-path"]])
  data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  levelUD <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]
  n_iterations <- options[["n-iterations"]]

  kde <- compute_individual_kde(data, config_content, levelUD, smoothing_method)
  result <- compute_representative_assessment(kde$KDE_surface, kde$tracks, levelUD, n_iterations)
  saveRDS(result, options[["output-path"]])
}

#' Create Potential KBA
#'
#' Reads a cached RDS file (assessment_summary), GPS data and configuration,
#' recomputes individual KDE (fast, no bootstrap), identifies potential Key
#' Biodiversity Areas (KBAs), and saves the result as a GeoPackage file.
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{rds-path}{Path to the cached RDS file with assessment_summary (must contain `out`).}
#'     \item{config-path}{Path to the configuration file (JSON).}
#'     \item{data-path}{Path to the input GPS data file (CSV).}
#'     \item{output-path}{Path where the output GeoPackage file will be saved.}
#'     \item{percentage-distribution}{Integer specifying the percentage distribution for KDE.}
#'     \item{smoothing-method}{Character string specifying the smoothing method for KDE.}
#'     \item{population-size}{Integer specifying the population size for KBA identification.}
#'   }
#'
#' @return None. Called for its side effect of writing a GeoPackage file to disk.
#' @export
create_potential_kba <- function(options) {
  cache <- readRDS(options[["rds-path"]])
  represent <- cache$assessment_summary$out
  config_content <- .adapt_config(options[["config-path"]])
  data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  levelUD <- options[["percentage-distribution"]]
  smoothing_method <- options[["smoothing-method"]]
  popSize <- options[["population-size"]]

  kde <- compute_individual_kde(data, config_content, levelUD, smoothing_method)
  site <- compute_potential_kba(kde$KDE_surface, represent, popSize, levelUD)
  sf::st_write(site, options[["output-path"]])
}

#' Create Representative Assessment
#'
#' Reads a cached RDS file (assessment_summary + assessment_detail) and writes
#' the assessment_detail as a CSV file alongside a datapackage.json descriptor
#' (Tabular Data Package format).
#'
#' @param options A named list containing the following elements:
#'   \describe{
#'     \item{rds-path}{Path to the cached RDS file with assessment_summary and assessment_detail.}
#'     \item{output-path}{Path where the output CSV file will be saved. The datapackage.json
#'       is written to the same directory.}
#'   }
#'
#' @return None. Called for its side effect of writing CSV and datapackage.json to disk.
#' @export
create_representative_assessment <- function(options) {
  cache <- readRDS(options[["rds-path"]])
  assessment_summary <- cache$assessment_summary
  assessment_detail <- cache$assessment_detail

  readr::write_csv(assessment_detail, options[["output-path"]])

  dpkg_path <- file.path(dirname(options[["output-path"]]), "datapackage.json")
  dpkg <- list(
    profile = "tabular-data-package",
    name = "representative-assessment",
    resources = list(
      list(
        path = basename(options[["output-path"]]),
        profile = "tabular-data-resource",
        schema = list(
          fields = list(
            list(name = "SampleSize", type = "number", description = "Number of individuals sampled"),
            list(name = "InclusionRate", type = "number", description = "Inclusion rate for this iteration"),
            list(name = "iteration", type = "integer", description = "Bootstrap iteration number"),
            list(name = "pred", type = "number", description = "Predicted asymptotic inclusion rate"),
            list(name = "rep_est", type = "number", description = "Representativeness estimate"),
            list(name = "is_rep", type = "boolean", description = "Whether this sample is representative")
          )
        )
      )
    )
  )
  writeLines(rjson::toJSON(dpkg), dpkg_path)
}
