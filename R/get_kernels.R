get_kernel_density_estimates <- function(gps_data, config_content) {
  trips <- get_trips(gps_data, config_content)
  complete_trips <- subset(trips, trips$Returns == "Yes")
  colony <- config_content$colony
  sumTrips <- track2KBA::tripSummary(trips = complete_trips, colony = colony)
  scale_parameters <- get_scale_parameters(complete_trips, sumTrips)
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  tracks <- tracks[tracks$ColDist > 3, ] # remove trip start and end points near colony

  KDE <- track2KBA::estSpaceUse(
    tracks = tracks,
    scale = scale_parameters$mag,
    levelUD = 50,
    polyOut = TRUE
  )
  return(KDE)
}

get_scale_parameters <- function(trips, trips_summary) {
  complete_trips <- subset(trips, trips$Returns == "Yes")
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  complete_summary <- subset(trips_summary, trips_summary$complete == "complete trip")
  hVals <- track2KBA::findScale(
    tracks = tracks,
    scaleARS = TRUE,
    sumTrips = complete_summary
  )
  return(hVals)
}
