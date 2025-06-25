filter_fisheries_by_date <- function(fisheries_data, start, end) {
  fisheries_data |>
    dplyr::filter(
      as.Date(FechaRecepcionUnitrac) >= as.Date(start) &
        as.Date(FechaRecepcionUnitrac) <= as.Date(end)
    )
}
