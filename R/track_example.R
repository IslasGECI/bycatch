get_trips <- function(data) {
  dataGroup <- track2KBA::formatFields(
    dataGroup = data,
    fieldID   = "track_id",
    fieldDate = "date_gmt",
    fieldTime = "time",
    fieldLon  = "longitude",
    fieldLat  = "latitude"
  )
  colony <- dataGroup |>
    dplyr::summarise(
      Longitude = dplyr::first(lon_colony),
      Latitude  = dplyr::first(lat_colony)
    )
  trips <- track2KBA::tripSplit(
    dataGroup  = dataGroup,
    colony     = colony,
    innerBuff  = 3, # kilometers
    returnBuff = 10,
    duration   = 1, # hours
    rmNonTrip  = TRUE
  )
  return(trips)
}
