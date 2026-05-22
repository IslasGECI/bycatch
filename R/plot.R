#' Plot representative assessment
#'
#' @param assessment_detail A data.frame with columns SampleSize, InclusionRate,
#'   iteration, pred, rep_est, and is_rep, as returned by
#'   `compute_representative_assessment()`.
#' @param assessment_summary A data.frame with columns out (representativeness %),
#'   est_asym (estimated asymptote), as returned by
#'   `compute_representative_assessment()`.
#'
#' @return A ggplot object showing the inclusion rate vs sample size scatterplot
#'   with confidence bands and fitted curve.
#' @noRd
plot_representative_assessment <- function(assessment_detail, assessment_summary) {
  # Calculate summary statistics by sample size (equivalent to track2KBA's P2)
  P2 <- assessment_detail %>%
    dplyr::group_by(.data$SampleSize) %>%
    dplyr::summarise(
      meanPred = mean(.data$pred, na.rm = TRUE),
      sdInclude = sd(.data$InclusionRate, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      upper_band = .data$meanPred + assessment_summary$est_asym * .data$sdInclude,
      lower_band = .data$meanPred - assessment_summary$est_asym * .data$sdInclude
    )

  # Create ggplot with confidence band, scatter points, fitted line, and label
  ggplot2::ggplot(assessment_detail, ggplot2::aes(x = .data$SampleSize, y = .data$InclusionRate)) +
    ggplot2::geom_ribbon(
      data = P2,
      ggplot2::aes(x = .data$SampleSize, ymin = .data$lower_band, ymax = .data$upper_band, fill = "Confidence band"),
      fill = "gray93", alpha = 0.8, inherit.aes = FALSE
    ) +
    ggplot2::geom_point(color = "darkgray", size = 1, alpha = 0.6) +
    ggplot2::geom_line(data = P2, ggplot2::aes(x = .data$SampleSize, y = .data$meanPred), color = "black", linewidth = 0.8) +
    ggplot2::annotate(
      "text",
      x = 0, y = 0.99,
      label = paste(round(assessment_summary$out, 1), "%", sep = ""),
      hjust = 0, vjust = 1,
      size = 8, color = "gray45"
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 1), name = "Inclusion Rate") +
    ggplot2::scale_x_continuous(name = "Sample Size") +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_line(color = "white", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank()
    )
}

#' Plot potential KBA
#'
#' @param site An sf polygons object as returned by `compute_potential_kba()`.
#'
#' @return A ggplot object mapping the potential KBA polygons.
#' @noRd
plot_potential_kba <- function(site) {
  s2_was_true <- sf::sf_use_s2(FALSE)
  on.exit(sf::sf_use_s2(s2_was_true))
  track2KBA::mapSite(Site = site, show = FALSE)
}

#' Plot individual KDE
#'
#' @param UDPolygons An sf polygons object as returned by
#'   `compute_individual_kde()`.
#'
#' @return A ggplot object mapping the individual KDE polygons.
#' @noRd
plot_individual_kde <- function(UDPolygons) {
  s2_was_true <- sf::sf_use_s2(FALSE)
  on.exit(sf::sf_use_s2(s2_was_true))
  track2KBA::mapKDE(KDE = UDPolygons, colony = NULL, show = FALSE)
}
