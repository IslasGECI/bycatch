xxget_summary_of_trips <- function(gps_data, config_content) {
  trips <- get_trips(gps_data, config_content)
  colony <- config_content$colony
  sumTrips <- track2KBA::tripSummary(trips = trips, colony = colony)
  return(sumTrips)
}
get_summary_of_trips <- function(gps_data) {
  colony_df <- tibble::tibble(Longitude = -118.29162, Latitude = 28.88421)
  config_content <- list(inner_buff = 3, return_buff = 10, duration = 1, colony = colony_df)
  xxget_summary_of_trips(gps_data, config_content)
}

get_trips <- function(data, config_content) {
  dataGroup <- track2KBA::formatFields(
    dataGroup = data,
    fieldID   = "track_id",
    fieldDate = "date_gmt",
    fieldTime = "time",
    fieldLon  = "longitude",
    fieldLat  = "latitude"
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
