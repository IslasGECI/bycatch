#' Plot representative assessment
#'
#' @param assessment_detail A data.frame with columns SampleSize, InclusionRate,
#'   iteration, pred, rep_est, and is_rep, as returned by
#'   `compute_representative_assessment()`.
#'
#' @return A ggplot object showing the inclusion rate vs sample size scatterplot.
#' @noRd
plot_representative_assessment <- function(assessment_detail) {
  ggplot2::ggplot(assessment_detail, ggplot2::aes(x = SampleSize, y = InclusionRate)) +
    ggplot2::geom_point() +
    ggplot2::labs(x = "Sample size", y = "Inclusion rate")
}

#' Plot potential KBA
#'
#' @param site An sf polygons object as returned by `compute_potential_kba()`.
#'
#' @return A ggplot object mapping the potential KBA polygons.
#' @noRd
plot_potential_kba <- function(site) {
  ggplot2::ggplot(site) +
    ggplot2::geom_sf() +
    ggplot2::labs(x = "Longitude", y = "Latitude")
}
