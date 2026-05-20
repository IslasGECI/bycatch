# TODO

## The Gold

A codebase where the **Layer ownership rule** is fully enforced — no redundant computation, no cross-layer violations, no `compute_*` calling another `compute_*`. Every `track2KBA` function owned by exactly one `compute_*`. Every `compute_*` called by exactly one `create_*`. Every `create_*` writes its result to disk. Downstream stages read intermediate results from disk rather than re-running computations.

## Plan

### Cycle 1: Add `import_trips(path, filter_returning)` to I/O layer

**Red:**
- File: `tests/testthat/test_io.R` (new)
- Scenario: `describe("import_trips", ...)` with two test cases:
  1. Default behavior (`filter_returning = TRUE`): reads `trips_5_ids.csv`, asserts all returned rows have `Returns == "Yes"`, non-returning rows are excluded, result is a data.frame
  2. `filter_returning = FALSE`: reads `trips_5_ids.csv`, asserts both "Yes" and "No" rows are present (count matches raw CSV), result is a data.frame
- Expected: Tests fail because `import_trips` does not exist

**Green:**
- Implement `import_trips(path, filter_returning = TRUE)` in `R/io.R`: reads CSV via `readr::read_csv`, conditionally filters `Returns == "Yes"`, returns data.frame

### Cycle 2: Add `import_trips_summary(path)` to I/O layer

**Red:**
- File: `tests/testthat/test_io.R`
- Scenario: Add `describe("import_trips_summary", ...)` that reads `trips_summary.csv` fixture, asserts result is a data.frame with expected columns (`tripID`, `n_locs`, `departure`, `return`, `duration`, `total_dist`, `max_dist`, `direction`, `complete`)
- Expected: Test fails because `import_trips_summary` does not exist

**Green:**
- Implement `import_trips_summary(path)` in `R/io.R`: reads CSV via `readr::read_csv`, returns data.frame as-is

### Cycle 3: Add `compute_project_returning_tracks(data)` to compute layer

**Red:**
- File: `tests/testthat/test_compute_project_returning_tracks.R` (new)
- Scenario: `describe("compute_project_returning_tracks", ...)` that feeds returning-trips data (read from `trips_5_ids.csv` filtered to `Returns == "Yes"`) and asserts result inherits `SpatialPointsDataFrame`
- Expected: Test fails because `compute_project_returning_tracks` does not exist

**Green:**
- Implement `compute_project_returning_tracks(data)` in `R/compute.R`: wraps `track2KBA::projectTracks(dataGroup = data, projType = "azim", custom = TRUE)`, returns SpatialPointsDataFrame

### Cycle 4: Simplify `compute_individual_kde` to 3-param signature

**Red:**
- File: `tests/testthat/test_compute_individual_kde.R`
- Scenario: Update existing `describe("compute_individual_kde", ...)` to build inputs inline:
  1. `returning_trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = TRUE)`
  2. `tracks <- compute_project_returning_tracks(returning_trips)`
  3. `sumTrips <- readr::read_csv("/workdir/tests/data/trips_summary.csv")` (returning-trips summary)
  4. `scale_params <- compute_scale_parameters(tracks, sumTrips)` → extract `scale <- scale_params$mag`
  5. Call `compute_individual_kde(tracks, levelUD = 50, scale = scale)` with 3 params
  6. Assert same structure and area values as current test
- Expected: Test fails because function still has 4-param signature `(data, config, levelUD, smoothing_method)`

**Green:**
- Simplify `compute_individual_kde(tracks, levelUD, scale)` in `R/compute.R`: remove `config`, `smoothing_method`, `tripSummary`, `projectTracks`, row filter, and scale dictionary. Keep only `track2KBA::estSpaceUse`. Returns `list(KDE_surface, UDPolygons, tracks)`

> **Note:** After this cycle, `create_potential_kba` (cli.R) and `create_test_fixtures.R` will temporarily break because they call `compute_individual_kde` with the old signature. The fast suite still passes (slow test is not in fast suite). Fixed in Cycle 8.

### Cycle 5: Add `--trips-summary-path` CLI flag

**Red:**
- File: `tests/testthat/test_get_domain_specific_options.R`
- Scenario: Add `"trips-summary-path"` to the `expected_options` vector
- Expected: Test fails because `"trips-summary-path"` is not in `names(obtained_options)`

**Green:**
- Add `-y` / `--trips-summary-path` flag to `R/get_domain_specific_options.R` with `gecioptparse::character_option`
- Add `trips_summary_path` to the `option_names` vector

### Cycle 6: Rewrite `create_individual_kde` to use new pipeline

**Red:**
- File: `tests/testthat/test_create_individual_kde.R`
- Scenario: Update options list:
  - Keep: `data-path`, `config-path`, `percentage-distribution`, `smoothing-method`
  - Add: `trips-summary-path` (pointing to `trips_summary.csv` fixture)
  - Change assertion: expect RDS output (not GeoPackage), assert file contains `KDE_surface`, `UDPolygons`, `tracks`
- Expected: Test fails because `create_individual_kde` still writes GeoPackage and uses old internal pipeline

**Green:**
- Rewrite `create_individual_kde` in `R/cli.R`:
  1. `returning_trips <- import_trips(options[["data-path"]], filter_returning = TRUE)`
  2. `tracks <- compute_project_returning_tracks(returning_trips)`
  3. `sumTrips <- import_trips_summary(options[["trips-summary-path"]])`
  4. `scale_params <- compute_scale_parameters(tracks, sumTrips)` → inline dictionary → extract `scale`
  5. `kde <- compute_individual_kde(tracks, levelUD, scale)`
  6. `saveRDS(kde, options[["output-path"]])`

### Cycle 7: Delete `create_processed_data`, rewrite `create_representative_assessment`

**Red:**
- Files: Delete `tests/testthat/test_create_processed_data.R` (function no longer exists). Update `tests/testthat/test_create_representative_assessment.R` in place: replace the old mock-cache/CSV/datapackage test with a new `describe("create_representative_assessment", ...)` that builds `individual_kde.rds` inline using the new pipeline (same pattern as Cycle 4 + saveRDS), then calls `create_representative_assessment(options)` with `rds-path` (individual_kde.rds), `percentage-distribution`, `n-iterations`, `output-path`. Assert RDS output contains `assessment_summary`, `assessment_detail`, and `KDE_surface`
- Expected: Test fails because current `create_representative_assessment` reads `assessment_summary`/`assessment_detail` from RDS and writes CSV + `datapackage.json`

**Green:**
- Delete `create_processed_data` from `R/cli.R` (roxygen2 block + function body)
- Rewrite `create_representative_assessment` in `R/cli.R`:
  1. `cache <- readRDS(options[["rds-path"]])`
  2. `KDE_surface <- cache$KDE_surface`, `tracks <- cache$tracks`
  3. `result <- compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)`
  4. `result$KDE_surface <- KDE_surface`
  5. `saveRDS(result, options[["output-path"]])`

### Cycle 8: Rewrite `create_potential_kba` to read from assessment.rds

**Red:**
- File: `tests/testthat/slow/test_create_potential_kba.R`
- Scenario: Update options — drop `config-path`, `data-path`, `smoothing-method`. Mock cache must include `KDE_surface` (use `ud_polygons.rds`-derived structure or minimal estUDm) and `assessment_summary$out`. Assert GeoPackage output
- Expected: Test fails because current `create_potential_kba` expects `config-path`, `data-path`, `smoothing-method` and re-runs `compute_individual_kde`

**Green:**
- Rewrite `create_potential_kba` in `R/cli.R`:
  1. `cache <- readRDS(options[["rds-path"]])`
  2. `KDE_surface <- cache$KDE_surface`
  3. `represent <- cache$assessment_summary$out`
  4. `site <- compute_potential_kba(KDE_surface, represent, popSize, levelUD)`
  5. `sf::st_write(site, options[["output-path"]])`

### Cycle 9: Update `render_individual_kde` to read from RDS

**Red:**
- File: `tests/testthat/test_render_individual_kde.R`
- Scenario: Update options to use `rds-path` instead of `gpkg-path`. Build an `individual_kde.rds` file (save `ud_polygons.rds` wrapped in a list with minimal keys, or use a real KDE computation), then call `render_individual_kde(options)`. Assert PNG output
- Expected: Test fails because current `render_individual_kde` expects `gpkg-path` and calls `sf::st_read`

**Green:**
- Update `render_individual_kde` in `R/cli.R`:
  1. `cache <- readRDS(options[["rds-path"]])`
  2. `ud_polygons <- cache$UDPolygons`
  3. `plot <- plot_individual_kde(ud_polygons)`
  4. `ggplot2::ggsave(filename = options[["output-path"]], plot = plot, device = "png")`

---

## Outside the Plan

**Final step: Refactoring and documentation (no test evolution required)**
- Update `create_trips_summary` in `R/cli.R` to use `import_trips(filter_returning = FALSE)` instead of raw `readr::read_csv` — no behavioral change, existing test still passes
- Update `tests/src/create_test_fixtures.R` to use new function signatures for fixture generation (`import_trips`, `compute_project_returning_tracks`, new `compute_individual_kde`, `compute_representative_assessment` with KDE_surface pass-through)
- Update `DOCS.md` — all reference updates for renamed/deleted functions, new I/O functions, new compute signatures
- Update `README.md` — command description updates
- Update `CHANGELOG.md` — document all changes
- Update `bycatch_thesis` Makefile (separate repo): replace `create_processed_data` → `create_representative_assessment`, add `--trips-summary-path`, update KDE render targets from `.gpkg` to `.rds`, update `create_potential_kba` targets to drop `--config-path`, `--data-path`, `--smoothing-method`
