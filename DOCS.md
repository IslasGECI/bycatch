# bycatch — Interface Reference

## Entry points (exported CLI wrappers)

### `render_potential_kba(options)`

Reads GPS data and configuration, computes representative assessment and
potential Key Biodiversity Area (KBA), and saves the resulting map as a PNG file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output PNG plot is saved.
    - `percentage-distribution` (integer) — percentage distribution for the assessment.
    - `n-iterations` (integer) — number of bootstrap iterations for the assessment.
    - `population-size` (integer) — population size for KBA site identification.
    - `smoothing-method` (character) — smoothing method for kernel density estimation.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.
- **Notes:** Disables S2 spherical geometry (`sf_use_s2`) for compatibility with `track2KBA`.

### `render_representative_assessment(options)`

Reads GPS data and configuration, computes the representative assessment,
and saves the resulting plot as a PNG file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output PNG plot is saved.
    - `percentage-distribution` (integer) — percentage distribution for the assessment.
    - `n-iterations` (integer) — number of bootstrap iterations for the assessment.
    - `smoothing-method` (character) — smoothing method for kernel density estimation.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.

### `render_individual_kde(options)`

Reads GPS data and configuration, computes kernel density estimates (KDE)
for each tracked individual, and saves the resulting map as a PNG file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output PNG plot is saved.
    - `percentage-distribution` (integer) — percentage distribution for the KDE.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.

### `export_trips_summary(options)`

Generates a summary of trips from GPS data and configuration, and writes it to
a CSV file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output CSV summary is saved.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.
- **Notes:** The output CSV contains columns `tripID`, `n_locs`, `departure`, `return`, `duration`, `total_dist`.

### `export_trips(options, config_content)`

Extracts individual foraging trips from GPS data and writes the result to a
CSV file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output CSV file is saved.
  - `config_content` (list) — configuration content (optional; overwritten by reading from `config-path`).
- **Returns:** None. Side effect: writes a CSV file to `output-path`.
- **Notes:** The output CSV contains columns `tripID`, `Latitude`, `Longitude`.

### `export_filtered_fisheries(options)`

Filters raw fisheries GPS data by date range and geographic bounding box, then
writes the filtered data to a CSV file.

- **Parameters:**
  - `options`: named list
    - `data-path` (character) — path to the input fisheries GPS data file (CSV).
    - `output-path` (character) — path where the filtered output CSV file is saved.
    - `start` (character) — start date for filtering (inclusive, format `YYYY-MM-DD`).
    - `end` (character) — end date for filtering (inclusive, format `YYYY-MM-DD`).
    - `lat-min` (numeric) — minimum latitude for filtering.
    - `lat-max` (numeric) — maximum latitude for filtering.
    - `lon-min` (numeric) — minimum longitude for filtering.
    - `lon-max` (numeric) — maximum longitude for filtering.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.

### `export_filtered_gps_between_dates(options)`

Filters GPS data between two inclusive dates and writes the result to a CSV file.

- **Parameters:**
  - `options`: named list
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the filtered output CSV file is saved.
    - `start` (character) — start date for filtering (inclusive).
    - `end` (character) — end date for filtering (inclusive).
    - `date-column-name` (character) — name of the date column in the input data.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.

### `get_domain_specific_options()`

Defines and returns a named list of command-line options for use in CLI tools.

- **Parameters:** None.
- **Returns:** A named list of command-line options. Names: `data-path`, `config-path`, `output-path`, `percentage-distribution`, `n-iterations`, `start`, `end`, `lat-min`, `lat-max`, `lon-min`, `lon-max`, `population-size`, `smoothing-method`, `date-column-name`.

---

## Compute layer (standalone)

### `compute_individual_kde(data, config, levelUD, smoothing_method)`

Projects tracks, estimates smoothing scale, and computes kernel density estimates
(KDE) for each tracked individual.

- **Parameters:**
  - `data` (data.frame) — GPS tracking data with a `Returns` column.
  - `config` (list) — configuration with `colony` (tibble of `Longitude`, `Latitude`).
  - `levelUD` (numeric) — percentage contour level for KDE polygons.
  - `smoothing_method` (character) — smoothing method for KDE. One of `"log_median"`, `"reference_bandwidth"`, `"scale_ARS"`.
- **Returns:** A list with elements `KDE_surface` (estUDm), `UDPolygons` (sf), and `tracks` (SpatialPointsDataFrame).

### `compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)`

Bootstraps across individuals to assess how representative the sample is.
Wraps `track2KBA::repAssess` with `bootTable=TRUE`. Suppresses the inline base R
plot.

- **Parameters:**
  - `KDE_surface` (estUDm) — kernel density estimates from `compute_individual_kde`.
  - `tracks` (SpatialPointsDataFrame) — projected tracking data.
  - `levelUD` (numeric) — percentage contour level.
  - `n_iterations` (integer) — number of bootstrap iterations.
- **Returns:** A list with elements `assessment_summary` (data.frame, single row with columns `out`, `asym`, `Rep70`, `Rep95`) and `assessment_detail` (data.frame, full iteration table).

### `compute_potential_kba(KDE_surface, represent, popSize, levelUD)`

Identifies potential Key Biodiversity Areas (KBAs) based on the representative
assessment. Wraps `track2KBA::findSite`.

- **Parameters:**
  - `KDE_surface` (estUDm) — kernel density estimates.
  - `represent` (numeric) — representativity value (from `assessment_summary$out`).
  - `popSize` (numeric) — population size for the KBA criterion.
  - `levelUD` (numeric) — percentage contour level.
- **Returns:** An sf object with polygon data (columns `N_IND`, `N_animals`, `potentialSite`).

### `compute_cache(data, config, levelUD, smoothing_method, n_iterations)`

Composes `compute_individual_kde` + `compute_representative_assessment`. Calls
`repAssess` exactly once. Returns only the bootstrap output for caching.

- **Parameters:**
  - `data` (data.frame) — GPS tracking data with a `Returns` column.
  - `config` (list) — configuration with `colony` (tibble).
  - `levelUD` (numeric) — percentage contour level.
  - `smoothing_method` (character) — smoothing method for KDE.
  - `n_iterations` (integer) — number of bootstrap iterations.
- **Returns:** A list with elements `assessment_summary` and `assessment_detail` (same as `compute_representative_assessment`).

---

## Configuration

### `read_config(config_path)`

Reads a JSON configuration file and returns its content as a list with a
parsed colony tibble.

- **Parameters:**
  - `config_path` (character) — path to the JSON configuration file.
- **Returns:** A list with keys: `inner_buff` (numeric), `return_buff` (numeric), `duration` (numeric), `colony` (tibble with columns `Longitude`, `Latitude`).
- **Errors:** File not found or invalid JSON (delegated to `rjson::fromJSON`).

---

## Track processing

### `get_trips(data, config_content)`

Converts raw GPS data into a spatial data frame of individual foraging trips.

- **Parameters:**
  - `data` (data.frame) — raw GPS data with columns `name`, `date`, `time`, `longitude`, `latitude`.
  - `config_content` (list) — configuration list with elements `colony` (tibble), `inner_buff` (numeric, km), `return_buff` (numeric, km), `duration` (numeric, hours).
- **Returns:** A `SpatialPointsDataFrame` with trip assignments. Each row is a GPS fix annotated with trip ID.
- **Notes:** Filters out non-returning trips (`rmNonTrip = TRUE`). Date-time format is `ymd_HMS`.

### `get_summary_of_trips(trips, config_content)`

Generates a summary table of trip characteristics from a `tripSplit` output.

- **Parameters:**
  - `trips` (data.frame) — trip data from `get_trips`.
  - `config_content` (list) — configuration list with element `colony` (tibble).
- **Returns:** A data.frame with one row per trip and columns including trip ID, completeness status, and derived metrics.

### `compute_scale_parameters(tracks, trips_summary)`

Computes candidate smoothing parameter values for kernel density estimation.
Wraps `track2KBA::findScale`.

- **Parameters:**
  - `tracks` (SpatialPointsDataFrame) — projected tracking data.
  - `trips_summary` (data.frame) — trip summary from `tripSummary`.
- **Returns:** A data.frame with 5 columns of scale parameters. Column `mag` contains the log-median scale estimate.

---

## Fisheries data processing

### `filter_fisheries_by_date(fisheries_data, start, end)`

Filters fisheries data rows within an inclusive date range.

- **Parameters:**
  - `fisheries_data` (data.frame) — fisheries GPS data with column `FechaRecepcionUnitrac`.
  - `start` (character) — start date (`YYYY-MM-DD`, inclusive).
  - `end` (character) — end date (`YYYY-MM-DD`, inclusive).
- **Returns:** A filtered data.frame with rows whose `FechaRecepcionUnitrac` falls within `[start, end]`.

### `filter_fisheries_by_lat_lon(fisheries_data, lat_min, lat_max, lon_min, lon_max)`

Filters fisheries data rows within a geographic bounding box.

- **Parameters:**
  - `fisheries_data` (data.frame) — fisheries GPS data with columns `Latitude`, `Longitude`.
  - `lat_min` (numeric) — minimum latitude.
  - `lat_max` (numeric) — maximum latitude.
  - `lon_min` (numeric) — minimum longitude.
  - `lon_max` (numeric) — maximum longitude.
- **Returns:** A filtered data.frame with rows whose coordinates fall within the bounding box.

### `filter_fisheries_by_date_and_lat_lon(fisheries_data, start, end, lat_min, lat_max, lon_min, lon_max)`

Composes date-range and bounding-box filters on fisheries data.

- **Parameters:**
  - `fisheries_data` (data.frame) — fisheries GPS data.
  - `start` (character) — start date (`YYYY-MM-DD`, inclusive).
  - `end` (character) — end date (`YYYY-MM-DD`, inclusive).
  - `lat_min` (numeric) — minimum latitude.
  - `lat_max` (numeric) — maximum latitude.
  - `lon_min` (numeric) — minimum longitude.
  - `lon_max` (numeric) — maximum longitude.
- **Returns:** A filtered data.frame satisfying all criteria.

---

## R6 class: `Track2KBA_Wrapper`

Orchestrates the track2KBA workflow: projection, scale estimation, kernel density estimation, representativity assessment, and KBA identification.

### `Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)`

- **Parameters:**
  - `trips_data` (data.frame) — GPS tracking data with a `Returns` column.
  - `config_content` (list) — configuration with `colony` (tibble of `Longitude`, `Latitude`).
  - `percentage_distribution` (numeric) — percentage distribution for KDE.
  - `smoothing_method` (character, default `"log_median"`) — smoothing method for KDE. One of `"log_median"`, `"reference_bandwidth"`, `"scale_ARS"`.
- **Side effects:** Stores `complete_trips`, `colony`, `tracks`, `percentage_distribution`, `smoothing_method`, and `KDE` as public fields.

### `get_tracks()`

Projects complete trips to an azimuthal equidistant projection.

- **Parameters:** None (uses `self$complete_trips`).
- **Returns:** A `SpatialPointsDataFrame` of projected tracking data.

### `get_scale_dictionary()`

Computes a dictionary of candidate smoothing parameters for KDE.

- **Parameters:** None (uses `self$complete_trips`, `self$colony`, `self$tracks`).
- **Returns:** A named list with keys `log_median`, `reference_bandwidth`, `scale_ARS`.

### `estimate_space_use(percentage_distribution)`

Computes kernel density estimates (KDE) for each individual.

- **Parameters:**
  - `percentage_distribution` (numeric) — percentage contour level for the KDE polygons.
- **Returns:** A list with elements `KDE.Surface` (raster) and `UDPolygons` (SpatialPolygonsDataFrame with area column).
- **Notes:** The number of output polygons equals the number of tracked individuals. Area output depends on the projection and contour level.

### `compute_representative_assessment(percentage_distribution, n_iterations)`

Bootstraps across individuals to assess how representative the sample is.

- **Parameters:**
  - `percentage_distribution` (numeric) — percentage distribution for the assessment.
  - `n_iterations` (integer) — number of bootstrap iterations.
- **Returns:** A data.frame with column `out` containing the representativity percentage.

### `compute_potential_kba(repr, percentage_distribution, population_size)`

Identifies potential Key Biodiversity Areas (KBAs) based on the representative assessment.

- **Parameters:**
  - `repr` (data.frame) — result from `compute_representative_assessment`, must contain an `out` column.
  - `percentage_distribution` (numeric) — percentage distribution for site identification.
  - `population_size` (integer) — population size for the KBA criterion.
- **Returns:** A spatial object (polygons) of identified potential KBA sites.
