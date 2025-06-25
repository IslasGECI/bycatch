filter_fisheries_by_date <- function(fisheries_data, start, end) {
  fisheries_data |>
    dplyr::filter(
      as.Date(FechaRecepcionUnitrac) >= as.Date(start) &
        as.Date(FechaRecepcionUnitrac) <= as.Date(end)
    )
}

filter_fisheries_by_lat_long <- function(fisheries_data, lat_min, lat_max, long_min, long_max) {
  fisheries_data |>
    dplyr::filter(
      Latitud >= lat_min & Latitud <= lat_max &
        Longitud >= long_min & Longitud <= long_max
    )
}
