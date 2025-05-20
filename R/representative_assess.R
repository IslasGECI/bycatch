Track2KBA_Wrapper <- R6::R6Class(
  "Track2KBA_Wrapper",
  public = list(
    complete_trips = NULL,
    colony = NULL,
    trips = NULL,
    initialize = function(gps_data, config_content) {
      self$trips <- get_trips(gps_data, config_content)
      self$complete_trips <- subset(self$trips, self$trips$Returns == "Yes")
      self$colony <- config_content$colony
    },
    get_tracks = function() {
      track2KBA::projectTracks(dataGroup = self$complete_trips, projType = "azim", custom = TRUE)
    }
  )
)
