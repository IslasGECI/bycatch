compute_filtered_between_dates <- function(data, start, end, date_column = `Fecha`) {
  data |>
    dplyr::filter(
      as.Date({{ date_column }}) >= as.Date(start) &
        as.Date({{ date_column }}) <= as.Date(end)
    )
}

compute_filtered_fisheries_by_date <- function(fisheries_data, start, end) {
  fisheries_data |>
    compute_filtered_between_dates(start, end, FechaRecepcionUnitrac)
}

compute_filtered_fisheries_by_lat_lon <- function(fisheries_data, lat_min, lat_max, lon_min, lon_max) {
  fisheries_data |>
    dplyr::filter(
      Latitude >= lat_min & Latitude <= lat_max &
        Longitude >= lon_min & Longitude <= lon_max
    )
}

compute_filtered_fisheries_by_date_and_lat_lon <- function(fisheries_data, start, end, lat_min, lat_max, lon_min, lon_max) {
  fisheries_data |>
    compute_filtered_fisheries_by_date(start, end) |>
    compute_filtered_fisheries_by_lat_lon(lat_min, lat_max, lon_min, lon_max)
}

compute_trips <- function(data, config_content) {
  dataGroup <- track2KBA::formatFields(
    dataGroup = data,
    fieldID = "name",
    fieldDate = "date",
    fieldTime = "time",
    fieldLon = "longitude",
    fieldLat = "latitude",
    formatDT = "ymd_HMS"
  )
  colony <- config_content$colony
  trips <- track2KBA::tripSplit(
    dataGroup  = dataGroup,
    colony     = colony,
    innerBuff  = config_content$inner_buff, # kilometers
    returnBuff = config_content$return_buff,
    duration   = config_content$duration, # hours
    rmNonTrip  = TRUE
  )
  return(trips)
}

compute_trips_summary <- function(trips, config_content) {
  colony <- config_content$colony
  sumTrips <- track2KBA::tripSummary(trips = trips, colony = colony)
  return(sumTrips)
}

compute_scale_parameters <- function(tracks, trips_summary) {
  hVals <- track2KBA::findScale(
    tracks = tracks,
    scaleARS = TRUE,
    sumTrips = trips_summary
  )
  return(hVals)
}

compute_project_returning_tracks <- function(data) {
  track2KBA::projectTracks(dataGroup = data, projType = "azim", custom = TRUE)
}

compute_individual_kde <- function(data, config, levelUD, smoothing_method) {
  complete_trips <- data[data$Returns == "Yes", ]
  colony <- config$colony
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  sumTrips <- track2KBA::tripSummary(trips = complete_trips, colony = colony)
  scale_parameters <- compute_scale_parameters(tracks, sumTrips)
  scale_dictionary <- list(
    "log_median" = scale_parameters$mag,
    "reference_bandwidth" = scale_parameters$href,
    "scale_ARS" = scale_parameters$scaleARS
  )
  scale <- scale_dictionary[[smoothing_method]]
  KDE <- track2KBA::estSpaceUse(
    tracks = tracks,
    scale = scale,
    levelUD = levelUD,
    polyOut = TRUE
  )
  list(
    KDE_surface = KDE$KDE.Surface,
    UDPolygons = KDE$UDPolygons,
    tracks = tracks
  )
}

compute_representative_assessment <- function(KDE_surface, tracks, levelUD, n_iterations) {
  seed <- 2
  grDevices::png(tempfile())
  result <- withr::with_seed(
    seed,
    track2KBA::repAssess(
      tracks = tracks,
      KDE = KDE_surface,
      levelUD = levelUD,
      iteration = n_iterations,
      bootTable = TRUE
    )
  )
  grDevices::dev.off()
  list(
    assessment_summary = result[[1]],
    assessment_detail = result[[2]]
  )
}

compute_potential_kba <- function(KDE_surface, represent, popSize, levelUD) {
  track2KBA::findSite(
    KDE = KDE_surface,
    represent = represent,
    levelUD = levelUD,
    popSize = popSize,
    polyOut = TRUE
  )
}
