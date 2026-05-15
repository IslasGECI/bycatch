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
      self$smoothing_method <- smoothing_method
      self$KDE <- self$estimate_space_use(percentage_distribution)
    },
    get_tracks = function() {
      track2KBA::projectTracks(dataGroup = self$complete_trips, projType = "azim", custom = TRUE)
    },
    get_scale_dictionary = function() {
      sumTrips <- track2KBA::tripSummary(trips = self$complete_trips, colony = self$colony)
      scale_parameters <- compute_scale_parameters(self$tracks, sumTrips)
      scale_dictionary <- list("log_median" = scale_parameters$mag, "reference_bandwidth" = scale_parameters$href, "scale_ARS" = scale_parameters$scaleARS)
      return(scale_dictionary)
    },
    estimate_space_use = function(percentage_distribution) {
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
    compute_representative_assessment = function(percentage_distribution, n_iterations) {
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
    compute_potential_kba = function(repr, percentage_distribution, population_size) {
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

compute_individual_kde <- function(data, config, levelUD, smoothing_method) {
  complete_trips <- data[data$Returns == "Yes", ]
  colony <- config$colony
  tracks <- track2KBA::projectTracks(dataGroup = complete_trips, projType = "azim", custom = TRUE)
  sumTrips <- track2KBA::tripSummary(trips = complete_trips, colony = colony)
  scale_parameters <- compute_scale_parameters(tracks, sumTrips)
  scale_dictionary <- list(
    "log_median" = scale_parameters$mag,
    "reference_bandwidth" = scale_parameters$href,
    "scale_ARS" = scale_parameters$scaleARS
  )
  scale <- scale_dictionary[[smoothing_method]]
  KDE <- track2KBA::estSpaceUse(
    tracks = tracks,
    scale = scale,
    levelUD = levelUD,
    polyOut = TRUE
  )
  list(
    KDE_surface = KDE$KDE.Surface,
    UDPolygons = KDE$UDPolygons,
    tracks = tracks
  )
}

compute_representative_assessment <- function(KDE_surface, tracks, levelUD, n_iterations) {
  seed <- 2
  grDevices::png(tempfile())
  result <- withr::with_seed(
    seed,
    track2KBA::repAssess(
      tracks = tracks,
      KDE = KDE_surface,
      levelUD = levelUD,
      iteration = n_iterations,
      bootTable = TRUE
    )
  )
  grDevices::dev.off()
  list(
    assessment_summary = result[[1]],
    assessment_detail = result[[2]]
  )
}

compute_potential_kba <- function(KDE_surface, represent, popSize, levelUD) {
  track2KBA::findSite(
    KDE = KDE_surface,
    represent = represent,
    levelUD = levelUD,
    popSize = popSize,
    polyOut = TRUE
  )
}

compute_cache <- function(data, config, levelUD, smoothing_method, n_iterations) {
  kde_result <- compute_individual_kde(data, config, levelUD, smoothing_method)
  compute_representative_assessment(kde_result$KDE_surface, kde_result$tracks, levelUD, n_iterations)
}
