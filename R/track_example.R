get_summary_of_trips <- function(gps_data) {
  trips <- get_trips(gps_data)
  colony <- get_colony(gps_data)
  sumTrips <- track2KBA::tripSummary(trips = trips, colony = colony)
  return(sumTrips)
}

get_trips <- function(data) {
  dataGroup <- track2KBA::formatFields(
    dataGroup = data,
    fieldID   = "track_id",
    fieldDate = "date_gmt",
    fieldTime = "time",
    fieldLon  = "longitude",
    fieldLat  = "latitude"
  )
  colony <- get_colony(data)
  trips <- track2KBA::tripSplit(
    dataGroup  = dataGroup,
    colony     = colony,
    innerBuff  = 3, # kilometers
    returnBuff = 11,
    duration   = 1, # hours
    rmNonTrip  = TRUE
  )
  return(trips)
}
get_colony <- function(gps_data) {
  gps_data |>
    dplyr::summarise(
      Longitude = dplyr::first(lon_colony),
      Latitude  = dplyr::first(lat_colony)
    )
}
