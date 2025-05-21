Track2KBA_Wrapper <- R6::R6Class(
  "Track2KBA_Wrapper",
  public = list(
    complete_trips = NULL,
    colony = NULL,
    KDE = NULL,
    trips = NULL,
    tracks = NULL,
    initialize = function(gps_data, config_content) {
      self$trips <- get_trips(gps_data, config_content)
      self$complete_trips <- subset(self$trips, self$trips$Returns == "Yes")
      self$colony <- config_content$colony
      self$tracks <- self$get_tracks()
    },
    get_tracks = function() {
      track2KBA::projectTracks(dataGroup = self$complete_trips, projType = "azim", custom = TRUE)
    },
    get_kde = function(percentage_distribution = 50) {
      sumTrips <- track2KBA::tripSummary(trips = self$complete_trips, colony = self$colony)
      scale_parameters <- get_scale_parameters(self$tracks, sumTrips)
      KDE <- track2KBA::estSpaceUse(
        tracks = self$tracks,
        scale = scale_parameters$mag,
        levelUD = percentage_distribution,
        polyOut = TRUE
      )
      return(KDE)
    },
    get_representative_assess = function(percentage_distribution) {
      self$KDE <- self$get_kde(percentage_distribution)
      repr <- track2KBA::repAssess(
        tracks    = self$tracks,
        KDE       = self$KDE$KDE.Surface,
        levelUD   = percentage_distribution,
        iteration = 1,
        bootTable = FALSE
      )
    }
  )
)
