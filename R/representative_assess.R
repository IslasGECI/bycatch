Track2KBA_Wrapper <- R6::R6Class(
  "Track2KBA_Wrapper",
  public = list(
    complete_trips = NULL,
    colony = NULL,
    KDE = NULL,
    trips = NULL,
    tracks = NULL,
    percentage_distribution = NULL,
    initialize = function(gps_data, config_content, percentage_distribution) {
      self$trips <- get_trips(gps_data, config_content)
      self$complete_trips <- subset(self$trips, self$trips$Returns == "Yes")
      self$colony <- config_content$colony
      self$tracks <- self$get_tracks()
      self$percentage_distribution <- percentage_distribution
      self$KDE <- self$calculate_kde(percentage_distribution)
    },
    get_tracks = function() {
      track2KBA::projectTracks(dataGroup = self$complete_trips, projType = "azim", custom = TRUE)
    },
    calculate_kde = function(percentage_distribution) {
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
    get_representative_assess = function(percentage_distribution, n_iterations) {
      seed <- 2
      withr::with_seed(
        seed,
        track2KBA::repAssess(
          tracks    = self$tracks,
          KDE       = self$KDE$KDE.Surface,
          levelUD   = percentage_distribution,
          iteration = n_iterations,
          bootTable = FALSE
        )
      )
    },
    get_site = function(repr, percentage_distribution) {
      Site <- track2KBA::findSite(
        KDE = self$KDE$KDE.Surface,
        represent = repr$out,
        levelUD = percentage_distribution,
        polyOut = FALSE
      )
      return(Site)
    }
  )
)
