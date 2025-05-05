get_scale_parameters <- function(trips, trips_summary) {
  complete_trips <- subset(trips, trips$Returns == "Yes")
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  hVals <- track2KBA::findScale(
    tracks = tracks,
    scaleARS = TRUE,
    sumTrips = trips_summary
  )
  return(hVals)
}
