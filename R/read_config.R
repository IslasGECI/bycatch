read_config <- function(config_path) {
  json_content <- rjson::fromJSON(file = config_path)
  json_content$colony <- ""
  return(json_content)
}
