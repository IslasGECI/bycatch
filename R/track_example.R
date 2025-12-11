get_summary_of_trips <- function(gps_data, config_content) {
  trips <- get_trips(gps_data, config_content)
  colony <- config_content$colony
  sumTrips <- track2KBA::tripSummary(trips = trips, colony = colony)
  return(sumTrips)
}

xxget_trips <- function(data, config_content) {
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
get_trips <- function(data, config_content) {
  dataGroup <- track2KBA::formatFields(
    dataGroup = data,
    fieldID = "track_id",
    fieldDate = "date_gmt",
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
