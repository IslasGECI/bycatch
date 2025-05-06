get_kernel_density_estimates <- function(gps_data, config_content, percentage_distribution = 50) {
  trips <- get_trips(gps_data, config_content)
  complete_trips <- subset(trips, trips$Returns == "Yes")
  colony <- config_content$colony
  sumTrips <- track2KBA::tripSummary(trips = complete_trips, colony = colony)
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  scale_parameters <- get_scale_parameters(complete_trips, sumTrips)
  KDE <- track2KBA::estSpaceUse(
    tracks = tracks,
    scale = scale_parameters$mag,
    levelUD = percentage_distribution,
    polyOut = TRUE
  )
  return(KDE)
}

get_scale_parameters <- function(complete_trips, trips_summary) {
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  xxget_scale_parameters(tracks, trips_summary)
}

xxget_scale_parameters <- function(tracks, trips_summary) {
  hVals <- track2KBA::findScale(
    tracks = tracks,
    scaleARS = TRUE,
    sumTrips = trips_summary
  )
  return(hVals)
}
