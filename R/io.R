import_config <- function(config_path) {
  json_content <- rjson::fromJSON(file = config_path)
  json_content$colony <- tibble::tibble(
    Longitude = json_content$lon_colony,
    Latitude  = json_content$lat_colony
  )
  json_content
}

import_trips <- function(path, filter_returning = TRUE) {
  trips <- readr::read_csv(path, show_col_types = FALSE)
  if (filter_returning) {
    trips <- trips[trips$Returns == "Yes", ]
  }
  trips
}
