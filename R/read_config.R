read_config <- function(config_path) {
  rjson::fromJSON(file = config_path)
}
