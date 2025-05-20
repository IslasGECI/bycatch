get_scale_parameters <- function(tracks, trips_summary) {
  hVals <- track2KBA::findScale(
    tracks = tracks,
    scaleARS = TRUE,
    sumTrips = trips_summary
  )
  return(hVals)
}
