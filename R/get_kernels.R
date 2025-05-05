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
