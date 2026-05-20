# TODO

## The Gold

A codebase where the **Layer ownership rule** is fully enforced — no redundant computation, no cross-layer violations, no `compute_*` calling another `compute_*`. Every `track2KBA` function owned by exactly one `compute_*`. Every `compute_*` called by exactly one `create_*`. Every `create_*` writes its result to disk. Downstream stages read intermediate results from disk rather than re-running computations.

---

## Layer ownership rule

See AGENTS.md "Layer ownership rule (no redundant computation)".

Enforce:
1. Every `track2KBA::*` call → in exactly one `compute_*` (or `plot_*`)
2. Every `compute_*` call → in exactly one `create_*` (or `render_*`)
3. Every `create_*` writes its result to disk
4. No `compute_*` calls another `compute_*`. If a pre-computation is needed by another compute, the caller must read the pre-computation from disk (produced by the corresponding `create_*`) and pass it to the compute as an in-memory input.

### Current violations

| Violation | Location | Fix |
|---|---|---|
| `track2KBA::tripSummary` called in `compute_trips_summary` AND in `compute_individual_kde` | `compute.R:52` and `compute.R:69` | Remove from `compute_individual_kde`. Accept `sumTrips` as parameter instead. |
| `compute_scale_parameters` called from `compute_individual_kde` | `compute.R:70` (via `compute_individual_kde`) | Remove call. Accept `scale_parameters` as parameter instead. `create_individual_kde` passes it in. |
| Row filter `data[data$Returns == "Yes", ]` in `compute_individual_kde` instead of I/O layer | `compute.R:66` | Move to `import_trips` in `R/io.R`. Filtering rows is a permitted I/O adaptation per architecture (item 7). |

---

## Merge `create_processed_data` into `create_representative_assessment`

### Goal

Delete `create_processed_data` and merge its functionality into `create_representative_assessment`. The merged function reads an individual KDE RDS (produced by `create_individual_kde`) instead of re-running `compute_individual_kde`. No CSV/datapackage.json export — the output is an RDS cache only.

### Pipeline after the change

```
create_trips
  │  input:  config-path, data-path, output-path
  │  output: trips.csv  (all trips, includes Returns column)
  │  wraps:  compute_trips → track2KBA::formatFields, track2KBA::tripSplit
  │
  ▼
create_trips_summary
  │  input:  config-path, data-path ← trips.csv, output-path
  │  output: trips_summary.csv  (sumTrips: all trips, data.frame)
  │  wraps:  import_trips(filter_returning = FALSE) → reads CSV without filtering (Level 1 I/O)
  │          compute_trips_summary → track2KBA::tripSummary
  │
create_individual_kde
  │  input:  data-path ← trips.csv, trips-summary-path ← trips_summary.csv,
  │          percentage-distribution, smoothing-method, output-path
  │  output: individual_kde.rds (KDE_surface estUDm, UDPolygons sf, tracks SpatialPointsDataFrame)
  │  wraps:  import_trips(filter_returning = TRUE) → reads CSV + filters to returning trips (Level 1 I/O)
  │          compute_project_returning_tracks → track2KBA::projectTracks
  │          import_trips_summary → reads trips_summary.csv (Level 1 I/O)
  │          compute_scale_parameters → track2KBA::findScale
  │          compute_individual_kde → track2KBA::estSpaceUse
  │  reads:  sumTrips from trips_summary.csv via import_trips_summary, passes to compute_scale_parameters,
  │          extracts scale value from result, passes to compute_individual_kde
  │
  ▼
create_representative_assessment
  │  input:  rds-path ← individual_kde.rds, percentage-distribution, n-iterations, output-path
  │  output: assessment.rds (assessment_summary, assessment_detail, KDE_surface)
  │  wraps:  compute_representative_assessment → track2KBA::repAssess
  │
  ▼
create_potential_kba
  │  input:  rds-path ← assessment.rds (reads KDE_surface + assessment_summary$out),
  │          percentage-distribution, population-size, output-path
  │  output: kba.gpkg (site polygons)
  │  wraps:  compute_potential_kba → track2KBA::findSite
  │
  ▼
render_representative_assessment
  │  input:  rds-path ← assessment.rds, output-path
  │
render_individual_kde
  │  input:  rds-path ← individual_kde.rds, output-path
  │
render_potential_kba
   input:  gpkg-path ← kba.gpkg, output-path
```

### Changes by file

#### `R/io.R`

1. **New `import_trips`** — Level 1 I/O function with parameterized filtering:
   - Signature: `import_trips(path, filter_returning = TRUE) → data.frame`
   - Reads CSV via `readr::read_csv` (I/O operation)
   - Default (`filter_returning = TRUE`): returns only `Returns == "Yes"` rows
   - With `filter_returning = FALSE`: returns all rows (no filtering)
   - Row filtering is a permitted I/O adaptation per architecture (item 7)
   - Called from `create_trips_summary(filter_returning = FALSE)` and `create_individual_kde(filter_returning = TRUE)`

2. **New `import_trips_summary`** — Level 1 I/O function:
   - Signature: `import_trips_summary(path) → data.frame`
   - Reads CSV via `readr::read_csv` (I/O operation)
   - Returns the trips_summary data.frame as-is
   - Called from `create_individual_kde` to read the pre-computed sumTrips

3. **Sibling function**: `import_config` already lives in `R/io.R`.

#### `R/compute.R`

1. **New `compute_project_returning_tracks`** — wraps `track2KBA::projectTracks`:
   - Signature: `compute_project_returning_tracks(data) → tracks` (SpatialPointsDataFrame)
   - Receives pre-filtered returning trips (filtered upstream by `import_trips(filter_returning = TRUE)` in `create_individual_kde`)
   - Projects: `track2KBA::projectTracks(dataGroup = data, projType = "azim", custom = TRUE)`
   - No I/O, pure Level 1 Pure function
   - Called exclusively from `create_individual_kde` (the sole `create_*` that needs projected returning tracks)

2. **`compute_individual_kde`** — simplified to no longer call `projectTracks`, `tripSummary`, or `compute_scale_parameters`:
   - Remove: `config` parameter (only used for colony, no longer needed)
   - Remove: `smoothing_method` parameter (replaced by `scale` parameter)
   - Remove: `track2KBA::tripSummary` call (violation — owned by `compute_trips_summary`)
   - Remove: `compute_scale_parameters` call (violation — compute_* calls another compute_*)
   - Remove: `track2KBA::projectTracks` call (moved to `compute_project_returning_tracks`)
   - Remove: `data` filter (`data[data$Returns == "Yes", ]`) — moves to `import_trips` in `R/io.R` (Level 1 I/O)
   - Keep: `track2KBA::estSpaceUse` — sole call site
   - New signature: `compute_individual_kde(tracks, levelUD, scale)`
     where `tracks` is the pre-projected SpatialPointsDataFrame and `scale` is the numeric smoothing value
   - Returns: `list(KDE_surface, UDPolygons, tracks)`

3. **`compute_trips_summary`** — unchanged. Receives pre-filtered or unfiltered trips from caller. No filter logic inside — just calls `track2KBA::tripSummary` on whatever data it receives.
   - Sole owner of `tripSummary`.

4. **`compute_scale_parameters`** — unchanged. Still wraps `findScale`. Called from `create_individual_kde` (Level 2 calling Level 1 Pure), not from another `compute_*`.

#### `R/cli.R`

1. **Delete `create_processed_data`** (lines 202–230) — roxygen2 block, `@export`, function body.

2. **Rewrite `create_trips_summary`** (lines 84–89):
   - Use `import_trips(filter_returning = FALSE)` — reads all trips, no filtering
   - Writes CSV (external contract for `bycatch_thesis`):
     ```r
     create_trips_summary <- function(options) {
       config_content <- import_config(options[["config-path"]])
       trips <- import_trips(options[["data-path"]], filter_returning = FALSE)
       sumTrips <- compute_trips_summary(trips, config_content)
       readr::write_csv(sumTrips, options[["output-path"]])
     }
     ```

3. **Rewrite `create_representative_assessment`** (lines 265–309):
   - Reads options: `rds-path` (input, individual KDE RDS), `percentage-distribution`, `n-iterations`, `output-path`
   - No longer reads: `config-path`, `data-path`, `smoothing-method`
   - No CSV or `datapackage.json` export
   - Body:
     ```r
     cache <- readRDS(options[["rds-path"]])
     KDE_surface <- cache$KDE_surface
     tracks <- cache$tracks
     levelUD <- options[["percentage-distribution"]]
     n_iterations <- options[["n-iterations"]]
     result <- compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)
     result$KDE_surface <- KDE_surface
     saveRDS(result, options[["output-path"]])
     ```

4. **Rewrite `create_individual_kde`** (lines 175–200):
   - Keeps `config-path` (needed by `compute_trips_summary` for colony)
   - Reads trips CSV via `import_trips(filter_returning = TRUE)` (I/O layer handles the returning-trips filter)
   - Reads `sumTrips` from `trips-summary-path`: `sumTrips <- import_trips_summary(options[["trips-summary-path"]])`
   - Projects returning tracks: `tracks <- compute_project_returning_tracks(returning_trips)` — Level 2 calling Level 1 Pure
   - Calls `compute_scale_parameters(tracks, sumTrips)` — Level 2 calling Level 1 Pure
   - Extracts scale value using `smoothing_method` option (inline dictionary, no helper):
     ```r
     scale_dictionary <- list(
       "log_median" = scale_parameters$mag,
       "reference_bandwidth" = scale_parameters$href,
       "scale_ARS" = scale_parameters$scaleARS
     )
     scale <- scale_dictionary[[options[["smoothing-method"]]]]
     ```
   - Calls `compute_individual_kde(tracks, levelUD, scale)` — no more `data`, `config`, or `smoothing_method`
   - Saves full result as RDS instead of GeoPackage
   - Output contains: `KDE_surface`, `UDPolygons`, `tracks`

5. **Update `create_potential_kba`** (lines 251–263):
   - Removes the re-run of `compute_individual_kde`
   - Reads `KDE_surface` from assessment RDS (`rds-path`)
   - Reads `assessment_summary$out` from the same RDS
   - No longer needs: `config-path`, `data-path`, `smoothing-method`

6. **Update `render_individual_kde`** (lines 62–66):
   - Reads from `rds-path` (individual KDE RDS) instead of `gpkg-path`
   - `cache <- readRDS(options[["rds-path"]])` → `cache$UDPolygons` → `plot_individual_kde()`

#### `R/get_domain_specific_options.R`

- **Add** `--trips-summary-path` (`-y`):
  ```r
  trips_summary_path <- gecioptparse::character_option(c("-y", "--trips-summary-path"), default = "", help = "Path to trips summary CSV")
  ```
- Add to `option_names` vector.
- All existing flags unchanged: `config-path`, `data-path`, `output-path`, `gpkg-path`, `rds-path`, `percentage-distribution`, `smoothing-method`, `n-iterations`, `population-size`, `start`, `end`, `lat-min`, `lat-max`, `lon-min`, `lon-max`, `date-column-name`.

#### `tests/testthat/test_io.R` (new file)

1. **Add `describe("import_trips", ...)` block**:
   - Feed it `trips_5_ids.csv` (contains both `Returns == "Yes"` and `Returns == "No"` rows)
   - Test `filter_returning = TRUE` (default): assert all returned rows have `Returns == "Yes"`, assert non-returning rows are excluded, assert result is a data.frame
   - Test `filter_returning = FALSE`: assert all rows are returned (both Yes and No), assert result is a data.frame

2. **Add `describe("import_trips_summary", ...)` block**:
   - Feed it `trips_summary.csv` fixture
   - Assert result is a data.frame with expected columns (`tripID`, `n_locs`, `departure`, `return`, `duration`, `total_dist`, `max_dist`, `direction`, `complete`)

#### `tests/testthat/test_create_representative_assessment.R`

1. **Delete** old file (currently tests CSV/datapackage.json export — dead feature).
2. **Rename** `test_create_processed_data.R` → `test_create_representative_assessment.R`:
   - Rename describe block → `"create_representative_assessment"`
   - Update call: `create_processed_data(options)` → `create_representative_assessment(options)`
   - Update options: drop `config-path`, `data-path`, `smoothing-method`; add `rds-path` pointing to `individual_kde.rds` fixture
   - Assertions stay the same (RDS output contains `assessment_summary` and `assessment_detail` as data.frames)

#### `tests/testthat/test_create_individual_kde.R`

1. **Update test** — keep `config-path` (still needed); add `trips-summary-path` (points to `trips_summary.csv` fixture). Verify RDS output contains `KDE_surface`, `UDPolygons`, `tracks`. Replace GeoPackage assertion.

#### `tests/testthat/slow/test_create_potential_kba.R`

1. **Update test** — drop `config-path`, `data-path`, `smoothing-method`. Mock cache must include `KDE_surface`.

#### `tests/testthat/test_write_trips_summary.R`

- Update `create_trips_summary` test: expects CSV output (unchanged). Uses `import_trips(filter_returning = FALSE)` internally. Verifies CSV columns.

#### `tests/testthat/test_compute_individual_kde.R`

- **Cycle 1** adds a new `describe("compute_project_returning_tracks", ...)` block that feeds pre-filtered data and asserts `SpatialPointsDataFrame`.
- **Cycle 3** updates the existing `compute_individual_kde` test to use `import_trips(filter_returning = TRUE)` + `compute_project_returning_tracks` + `compute_scale_parameters` inline to build inputs, then call the new three-parameter signature.

#### `tests/src/create_test_fixtures.R`

- Update to run full pipeline with new function signatures:
  1. `import_trips` + `compute_trips_summary` → save `trips_summary.csv`
  2. `import_trips(filter_returning = TRUE)` + `compute_project_returning_tracks` + `compute_scale_parameters` + `compute_individual_kde` → save `individual_kde.rds`
  3. `compute_representative_assessment` → save `assessment.rds` (with KDE_surface pass-through)
  4. `compute_potential_kba` → save `kba_polygons.rds`
- Serves as both fixture generator and smoke test for the full pipeline.

#### `DOCS.md`

- Update references: `create_processed_data` → `create_representative_assessment`
- Update `create_trips_summary` section: now uses `import_trips(filter_returning = FALSE)` + writes CSV with all trips
- Update `create_individual_kde` section: reads via `import_trips(filter_returning = TRUE)` + reads sumTrips from `trips-summary-path` + outputs RDS
- Remove CSV + `datapackage.json` export references
- Remove old `create_processed_data` section
- Document `import_trips` and `import_trips_summary` in I/O section
- Update `compute_individual_kde` compute section: new 3-parameter signature

#### `README.md`

- Same reference updates (no API details, just command descriptions)

#### `CHANGELOG.md`

- Document all changes

---

## Verification

1. Run `make format` to ensure styling consistency
2. Verify with `make tests` (fast suite) — all cycles must pass

---

# Backlog NOT related to the gold

- `sf_use_s2(FALSE)` save/restore in every `compute_*` that calls
  `track2KBA`. Pattern: `previous <- sf::sf_use_s2(FALSE);
  on.exit(sf::sf_use_s2(previous))`. Currently handled externally by
  fixture scripts. See AGENTS.md "Spatial (S2) and Colony" section.

- Update `bycatch_thesis` Makefile:
  - Replace `create_processed_data` → `create_representative_assessment`
  - Add `--trips-summary-path` to `create_individual_kde` targets
  - Change `ud_polygons_*.gpkg` → `individual_kde_*.rds` for KDE render targets
  - Add `individual_kde_*.rds` → `create_representative_assessment` → `assessment_*.rds` dependency chain
  - Update `create_potential_kba` targets: drop `--config-path`, `--data-path`, `--smoothing-method`
