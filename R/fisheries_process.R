filter_fisheries_by_date_and_lat_lon <- function(fisheries_data, start, end, lat_min, lat_max, lon_min, lon_max) {
  fisheries_data |>
    filter_fisheries_by_date(start, end) |>
    filter_fisheries_by_lat_lon(lat_min, lat_max, lon_min, lon_max)
}
filter_fisheries_by_date <- function(fisheries_data, start, end) {
  fisheries_data |>
    filter_between_dates(start, end, FechaRecepcionUnitrac)
}

filter_between_dates <- function(data, start, end, date_column = `Fecha`) {
  data |>
    dplyr::filter(
      as.Date({{ date_column }}) >= as.Date(start) &
        as.Date({{ date_column }}) <= as.Date(end)
    )
}


filter_fisheries_by_lat_lon <- function(fisheries_data, lat_min, lat_max, lon_min, lon_max) {
  fisheries_data |>
    dplyr::filter(
      Latitude >= lat_min & Latitude <= lat_max &
        Longitude >= lon_min & Longitude <= lon_max
    )
}
