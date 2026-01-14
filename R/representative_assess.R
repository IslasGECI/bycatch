Track2KBA_Wrapper <- R6::R6Class(
  "Track2KBA_Wrapper",
  public = list(
    complete_trips = NULL,
    colony = NULL,
    KDE = NULL,
    trips = NULL,
    tracks = NULL,
    smoothing_method = NULL,
    percentage_distribution = NULL,
    initialize = function(trips_data, config_content, percentage_distribution, smoothing_method = "log_median") {
      self$trips <- trips_data
      self$complete_trips <- subset(self$trips, self$trips$Returns == "Yes")
      self$colony <- config_content$colony
      self$tracks <- self$get_tracks()
      self$percentage_distribution <- percentage_distribution
      self$KDE <- self$calculate_kde(percentage_distribution)
      self$smoothing_method <- smoothing_method
    },
    get_tracks = function() {
      track2KBA::projectTracks(dataGroup = self$complete_trips, projType = "azim", custom = TRUE)
    },
    get_scale_dictionary = function() {
      sumTrips <- track2KBA::tripSummary(trips = self$complete_trips, colony = self$colony)
      scale_parameters <- get_scale_parameters(self$tracks, sumTrips)
      scale_dictionary <- list("log_median" = scale_parameters$mag, "reference_bandwith" = scale_parameters$href, "scale_ARS" = scale_parameters$scaleARS)
      return(scale_dictionary)
    },
    calculate_kde = function(percentage_distribution) {
      scale_dictionary <- self$get_scale_dictionary()
      print("scale parameter:")
      print(scale_dictionary[[self$smoothing_method]])
      KDE <- track2KBA::estSpaceUse(
        tracks = self$tracks,
        scale = scale_dictionary[[self$smoothing_method]],
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
    },
    get_potential_site = function(repr, percentage_distribution, population_size) {
      Site <- track2KBA::findSite(
        KDE = self$KDE$KDE.Surface,
        represent = repr$out,
        levelUD = percentage_distribution,
        popSize = population_size,
        polyOut = TRUE
      )
      return(Site)
    }
  )
)
