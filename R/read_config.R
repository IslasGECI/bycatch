read_config <- function(config_path) {
  json_content <- rjson::fromJSON(file = config_path)
  json_content$colony <- tibble::tibble(Longitude = json_content$lon_colony, Latitude = json_content$lat_colony)
  return(json_content)
}
