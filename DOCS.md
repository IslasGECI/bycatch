# bycatch — Interface Reference

## Entry points (exported CLI wrappers)

### `render_potential_kba(options)`

Reads a pre-computed GeoPackage file containing potential KBA polygons and
saves the resulting map as a PNG file.

- **Parameters:**
  - `options`: named list
    - `gpkg-path` (character) — path to the input GeoPackage file with KBA polygons.
    - `output-path` (character) — path where the output PNG plot is saved.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.
- **Notes:** The input `.gpkg` file is produced by `create_potential_kba`. This function never calls `compute_*` — it reads the pre-computed artifact, plots, and saves.

### `render_representative_assessment(options)`

Reads a cached RDS file (assessment_detail) and saves the representative
assessment scatterplot as a PNG file.

- **Parameters:**
  - `options`: named list
    - `rds-path` (character) — path to the cached RDS file with `assessment_summary` and `assessment_detail`.
    - `output-path` (character) — path where the output PNG plot is saved.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.
- **Notes:** The input `.rds` file is produced by `create_processed_data`. This function never calls `compute_*` — it reads the pre-computed artifact, plots, and saves.

### `render_individual_kde(options)`

Reads a pre-computed GeoPackage file containing UDPolygons and saves the
resulting KDE map as a PNG file.

- **Parameters:**
  - `options`: named list
    - `gpkg-path` (character) — path to the input GeoPackage file with UDPolygons.
    - `output-path` (character) — path where the output PNG plot is saved.
- **Returns:** None. Side effect: writes a PNG file to `output-path`.
- **Notes:** The input `.gpkg` file is produced by `create_individual_kde`. This function never calls `compute_*` — it reads the pre-computed artifact, plots, and saves.

### `create_trips_summary(options)`

Generates a summary of trips from GPS data and configuration, and writes it to
a CSV file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output CSV summary is saved.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.
- **Notes:** The output CSV contains columns `tripID`, `n_locs`, `departure`, `return`, `duration`, `total_dist`.

### `create_trips(options)`

Extracts individual foraging trips from GPS data and writes the result to a
CSV file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output CSV file is saved.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.
- **Notes:** The output CSV contains columns `tripID`, `Latitude`, `Longitude`.

### `create_filtered_fisheries(options)`

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

### `create_filtered_gps_between_dates(options)`

Filters GPS data between two inclusive dates and writes the result to a CSV file.

- **Parameters:**
  - `options`: named list
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the filtered output CSV file is saved.
    - `start` (character) — start date for filtering (inclusive).
    - `end` (character) — end date for filtering (inclusive).
    - `date-column-name` (character) — name of the date column in the input data.
- **Returns:** None. Side effect: writes a CSV file to `output-path`.

### `create_individual_kde(options)`

Reads GPS data and configuration, computes kernel density estimates (KDEs)
for each tracked individual, and saves the resulting UDPolygons as a GeoPackage
file. Recomputes the fast pipeline from scratch (no bootstrap).

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output GeoPackage file (`*.gpkg`) is saved.
    - `percentage-distribution` (integer) — percentage contour level for KDE polygons.
    - `smoothing-method` (character) — smoothing method for KDE. One of `"log_median"`, `"reference_bandwidth"`, `"scale_ARS"`.
- **Returns:** None. Side effect: writes a GeoPackage file to `output-path`.
- **Notes:** Only the UDPolygons are written (KDE_surface and tracks are ephemeral). Colony is used internally by `compute_individual_kde` but not included in the output.

### `create_processed_data(options)`

Reads GPS data and configuration, runs the full bootstrap pipeline exactly once
(compute_individual_kde + repAssess), and caches the assessment results as an
RDS file.

- **Parameters:**
  - `options`: named list
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output RDS cache file is saved.
    - `percentage-distribution` (integer) — percentage contour level for the assessment.
    - `smoothing-method` (character) — smoothing method for KDE.
    - `n-iterations` (integer) — number of bootstrap iterations for the representative assessment.
- **Returns:** None. Side effect: writes an RDS file to `output-path` containing `assessment_summary` (data.frame: `out`, `asym`, `Rep70`, `Rep95`) and `assessment_detail` (data.frame: full iteration table).
- **Notes:** This is the only function that runs the expensive `repAssess` bootstrap. Downstream functions (`create_potential_kba`, `create_representative_assessment`, `render_representative_assessment`) read the cached output instead of re-running it.

### `create_potential_kba(options)`

Reads a cached RDS file (from `create_processed_data`), recomputes individual
KDE (fast, no bootstrap), identifies potential Key Biodiversity Areas (KBAs),
and saves the result as a GeoPackage file.

- **Parameters:**
  - `options`: named list
    - `rds-path` (character) — path to the cached RDS file with `assessment_summary` (must contain `out` column).
    - `config-path` (character) — path to the configuration file (JSON).
    - `data-path` (character) — path to the input GPS data file (CSV).
    - `output-path` (character) — path where the output GeoPackage file (`*.gpkg`) is saved.
    - `percentage-distribution` (integer) — percentage contour level for KDE.
    - `smoothing-method` (character) — smoothing method for KDE.
    - `population-size` (integer) — population size for the KBA criterion.
- **Returns:** None. Side effect: writes a GeoPackage file to `output-path`.

### `create_representative_assessment(options)`

Reads a cached RDS file (from `create_processed_data`) and writes the assessment
results as a Tabular Data Package: a CSV file with the full iteration data plus
a `datapackage.json` descriptor with field schemas.

- **Parameters:**
  - `options`: named list
    - `rds-path` (character) — path to the cached RDS file with `assessment_summary` and `assessment_detail`.
    - `output-path` (character) — path where the output CSV file is saved. The `datapackage.json` descriptor is written to the same directory.
- **Returns:** None. Side effect: writes a CSV file and `datapackage.json` to disk.
- **Notes:** The `datapackage.json` follows the [Tabular Data Package](https://specs.frictionlessdata.io/tabular-data-package/) specification.

### `get_domain_specific_options()`

Defines and returns a named list of command-line options for use in CLI tools.

- **Parameters:** None.
- **Returns:** A named list of command-line options. Names: `data-path`, `config-path`, `output-path`, `gpkg-path`, `rds-path`, `percentage-distribution`, `n-iterations`, `start`, `end`, `lat-min`, `lat-max`, `lon-min`, `lon-max`, `population-size`, `smoothing-method`, `date-column-name`.

---

## Plot layer (Level 1 Pure — internal)

### `plot_representative_assessment(assessment_detail)`

Returns a ggplot2 scatterplot of inclusion rate vs sample size from the
representative assessment bootstrap iterations.

- **Parameters:**
  - `assessment_detail` (data.frame) — full iteration table with columns `SampleSize`, `InclusionRate`, `iteration`, `pred`, `rep_est`, `is_rep`. Typically loaded from a cached `.rds` file.
- **Returns:** A ggplot2 object.
- **Notes:** Level 1 Pure — no I/O, no side effects. Called by `render_representative_assessment`.

### `plot_potential_kba(site)`

Returns a ggplot2 map of potential Key Biodiversity Area (KBA) polygons.

- **Parameters:**
  - `site` (sf) — polygons object with KBA site data, as returned by `compute_potential_kba()`. Typically loaded from a `.gpkg` file.
- **Returns:** A ggplot2 object.
- **Notes:** Level 1 Pure — no I/O, no side effects. Replaces `track2KBA::mapSite` — no colony parameter. Called by `render_potential_kba`.

### `plot_individual_kde(UDPolygons)`

Returns a ggplot2 map of individual kernel density estimate (KDE) polygons.

- **Parameters:**
  - `UDPolygons` (sf) — utilization distribution polygons, as returned by `compute_individual_kde()`. Typically loaded from a `.gpkg` file.
- **Returns:** A ggplot2 object.
- **Notes:** Level 1 Pure — no I/O, no side effects. Replaces `track2KBA::mapKDE` — no colony parameter. Called by `render_individual_kde`.

---

## Compute layer (all functions in `R/compute.R`)

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

~~`compute_cache`~~ — removed in Sprint 6. Its logic (compose `compute_individual_kde` + `compute_representative_assessment`) is now inlined directly into `create_processed_data`.

---

## Configuration

### `.adapt_config(config_path)`

Reads a JSON configuration file and returns its content as a list with a
parsed colony tibble. Private helper used by `create_*` and `render_*` functions.

- **Parameters:**
  - `config_path` (character) — path to the JSON configuration file.
- **Returns:** A list with keys: `inner_buff` (numeric), `return_buff` (numeric), `duration` (numeric), `lat_colony` (numeric), `lon_colony` (numeric), `colony` (tibble with columns `Longitude`, `Latitude`).
- **Errors:** File not found or invalid JSON (delegated to `rjson::fromJSON`).

---

## Track processing

### `compute_trips(data, config_content)`

Converts raw GPS data into a spatial data frame of individual foraging trips.

- **Parameters:**
  - `data` (data.frame) — raw GPS data with columns `name`, `date`, `time`, `longitude`, `latitude`.
  - `config_content` (list) — configuration list with elements `colony` (tibble), `inner_buff` (numeric, km), `return_buff` (numeric, km), `duration` (numeric, hours).
- **Returns:** A `SpatialPointsDataFrame` with trip assignments. Each row is a GPS fix annotated with trip ID.
- **Notes:** Filters out non-returning trips (`rmNonTrip = TRUE`). Date-time format is `ymd_HMS`.

### `compute_trips_summary(trips, config_content)`

Generates a summary table of trip characteristics from a `tripSplit` output.

- **Parameters:**
  - `trips` (data.frame) — trip data from `compute_trips`.
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

### `compute_filtered_fisheries_by_date(fisheries_data, start, end)`

Filters fisheries data rows within an inclusive date range.

- **Parameters:**
  - `fisheries_data` (data.frame) — fisheries GPS data with column `FechaRecepcionUnitrac`.
  - `start` (character) — start date (`YYYY-MM-DD`, inclusive).
  - `end` (character) — end date (`YYYY-MM-DD`, inclusive).
- **Returns:** A filtered data.frame with rows whose `FechaRecepcionUnitrac` falls within `[start, end]`.

### `compute_filtered_fisheries_by_lat_lon(fisheries_data, lat_min, lat_max, lon_min, lon_max)`

Filters fisheries data rows within a geographic bounding box.

- **Parameters:**
  - `fisheries_data` (data.frame) — fisheries GPS data with columns `Latitude`, `Longitude`.
  - `lat_min` (numeric) — minimum latitude.
  - `lat_max` (numeric) — maximum latitude.
  - `lon_min` (numeric) — minimum longitude.
  - `lon_max` (numeric) — maximum longitude.
- **Returns:** A filtered data.frame with rows whose coordinates fall within the bounding box.

### `compute_filtered_fisheries_by_date_and_lat_lon(fisheries_data, start, end, lat_min, lat_max, lon_min, lon_max)`

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

## Removed: `Track2KBA_Wrapper` (R6 class)

Removed in Sprint 6. The R6 class is replaced by standalone `compute_*` functions
in `R/compute.R`. State is passed explicitly through parameters rather than stored
in an object.
