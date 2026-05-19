# TODO

## Layer ownership rule

See AGENTS.md "Layer ownership rule (no redundant computation)".

Enforce:
1. Every `track2KBA::*` call → in exactly one `compute_*` (or `plot_*`)
2. Every `compute_*` call → in exactly one `create_*` (or `render_*`)
3. Every `create_*` writes its result to disk
4. No `compute_*` calls another `compute_*` — if a computation is needed, read it from disk (produced by the corresponding `create_*`)

### Current violations

| Violation | Location | Fix |
|---|---|---|
| `track2KBA::tripSummary` called in `compute_trips_summary` AND in `compute_individual_kde` | `compute.R:52` and `compute.R:69` | Remove from `compute_individual_kde`. Accept `sumTrips` as parameter instead. |
| `compute_scale_parameters` called from `compute_individual_kde` | `compute.R:70` (via `compute_individual_kde`) | Remove call. Accept `scale_parameters` as parameter instead. `create_individual_kde` passes it in. |
| Row filter `data[data$Returns == "Yes", ]` in `compute_individual_kde` instead of I/O layer | `compute.R:66` | Move to `import_returning_trips` in `R/io.R`. Filtering rows is a permitted I/O adaptation per architecture (item 7). |

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
  │  output: trips_summary.rds  (sumTrips: returning trips only, data.frame)
  │  wraps:  import_returning_trips → reads CSV + filters to returning trips (Level 1 I/O)
  │          compute_trips_summary → track2KBA::tripSummary
  │
create_individual_kde
  │  input:  data-path ← trips.csv, percentage-distribution, smoothing-method,
  │          output-path, rds-path ← trips_summary.rds
  │  output: individual_kde.rds (KDE_surface estUDm, UDPolygons sf, tracks SpatialPointsDataFrame)
  │  wraps:  import_returning_trips → reads CSV + filters to returning trips (Level 1 I/O)
  │          compute_project_returning_tracks → track2KBA::projectTracks
  │          compute_scale_parameters → track2KBA::findScale
  │          compute_individual_kde → track2KBA::estSpaceUse
  │  reads:  sumTrips from trips_summary.rds, passes to compute_scale_parameters,
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

1. **New `import_returning_trips`** — Level 1 I/O function: reads CSV and filters to returning trips:
   - Signature: `import_returning_trips(path) → data.frame`
   - Reads CSV via `readr::read_csv` (I/O operation)
   - Filters rows: `data[data$Returns == "Yes", ]` (permitted I/O adaptation, item 7)
   - Called from `create_trips_summary` and `create_individual_kde`
   - No computation — row filtering is explicitly allowed in Level 1 I/O per architecture

2. **Sibling function**: `import_config` already lives in `R/io.R`.

#### `R/compute.R`

1. **New `compute_project_returning_tracks`** — wraps `track2KBA::projectTracks`:
   - Signature: `compute_project_returning_tracks(data) → tracks` (SpatialPointsDataFrame)
   - Receives pre-filtered returning trips (filtered upstream by `import_returning_trips` in `create_individual_kde`)
   - Projects: `track2KBA::projectTracks(dataGroup = data, projType = "azim", custom = TRUE)`
   - No I/O, pure Level 1 Pure function
   - Called exclusively from `create_individual_kde` (the sole `create_*` that needs projected returning tracks)

2. **`compute_individual_kde`** — simplified to no longer call `projectTracks`, `tripSummary`, or `compute_scale_parameters`:
   - Remove: `config` parameter (only used for colony, no longer needed)
   - Remove: `smoothing_method` parameter (replaced by `scale` parameter)
   - Remove: `track2KBA::tripSummary` call (violation — owned by `compute_trips_summary`)
   - Remove: `compute_scale_parameters` call (violation — compute_* calls another compute_*)
   - Remove: `track2KBA::projectTracks` call (moved to `compute_project_returning_tracks`)
   - Remove: `data` filter (`data[data$Returns == "Yes", ]`) — moves to `import_returning_trips` in `R/io.R` (Level 1 I/O)
   - Keep: `track2KBA::estSpaceUse` — sole call site
   - New signature: `compute_individual_kde(tracks, levelUD, scale)`
     where `tracks` is the pre-projected SpatialPointsDataFrame and `scale` is the numeric smoothing value
   - Returns: `list(KDE_surface, UDPolygons, tracks)`

3. **`compute_trips_summary`** — unchanged. Receives pre-filtered returning trips from `import_returning_trips` (called by `create_trips_summary`). No filter logic inside — just calls `track2KBA::tripSummary` on whatever data it receives.
   - Sole owner of `tripSummary`.

4. **`compute_scale_parameters`** — unchanged. Still wraps `findScale`. Called from `create_individual_kde` (Level 2 calling Level 1 Pure), not from another `compute_*`.

#### `R/cli.R`

1. **Delete `create_processed_data`** (lines 202–230) — roxygen2 block, `@export`, function body.

2. **Rewrite `create_representative_assessment`** (lines 265–309):
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

3. **Update `create_trips_summary`** (lines 84–89):
   - Use `import_returning_trips` instead of `read_csv` — filtering happens in I/O layer
   - Write RDS instead of CSV:
     ```r
     create_trips_summary <- function(options) {
       config_content <- import_config(options[["config-path"]])
       returning_trips <- import_returning_trips(options[["data-path"]])
       sumTrips <- compute_trips_summary(returning_trips, config_content)
       saveRDS(sumTrips, options[["output-path"]])
     }
     ```

4. **Update `create_individual_kde`** (lines 175–200):
   - Drops `config-path` — no longer needed (colony removed from all called functions)
   - Reads trips CSV via `import_returning_trips` (I/O layer handles the returning-trips filter)
   - Reads `sumTrips` from RDS: `sumTrips <- readRDS(options[["rds-path"]])`
   - Projects returning tracks: `tracks <- compute_project_returning_tracks(returning_trips)` — Level 2 calling Level 1 Pure, OK (receives pre-filtered data, just projects)
   - Calls `compute_scale_parameters(tracks, sumTrips)` — Level 2 calling Level 1 Pure, OK
   - Extracts scale value using `smoothing_method` option:
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

7. **Create new `compute_column` helper in `cli.R`** (optional):
   - If needed, a `.extract_scale` helper to avoid duplicating the scale dictionary logic between `create_individual_kde` and any future caller.

#### `R/get_domain_specific_options.R`

- No changes needed. All required flags exist:
  - `rds-path` — `create_individual_kde` reads trips_summary.rds; `create_representative_assessment` reads individual_kde.rds; `create_potential_kba` reads assessment.rds
  - `config-path`, `data-path`, `output-path`, `percentage-distribution`, `smoothing-method`, `n-iterations`, `population-size` — all already defined
  - `gpkg-path` — still needed for `render_potential_kba`
- `rds-path` always points to an RDS file (never CSV), consistency restored.

#### `tests/testthat/test_io.R` (new file)

1. **Add `describe("import_returning_trips", ...)` block**:
   - Feed it `trips_5_ids.csv` (contains both `Returns == "Yes"` and `Returns == "No"` rows)
   - Assert all returned rows have `Returns == "Yes"`
   - Assert that non-returning rows are excluded
   - Assert the result is a data.frame

#### `tests/testthat/test_cache.R`

1. **Delete** `describe("create_representative_assessment", ...)` block (lines 70–99).

2. **Rename** `describe("create_processed_data", ...)` → `describe("create_representative_assessment", ...)` (lines 22–43).
   - Update call: `create_processed_data(options)` → `create_representative_assessment(options)`
   - Update options: drop `config-path`, `data-path`, `smoothing-method`; add `rds-path`
   - Assertions stay the same

3. **Update `create_individual_kde` test** — drop `config-path`; add `rds-path` (points to trips_summary.rds generated inline via `compute_trips_summary`). Verify RDS output contains `KDE_surface`, `UDPolygons`, `tracks`. Replace GeoPackage assertion.

4. **Update `create_potential_kba` test** — drop `config-path`, `data-path`, `smoothing-method`. Mock cache must include `KDE_surface`.

#### `tests/testthat/test_cli.R`

- Update `create_trips_summary` test: expects RDS output now, not CSV. The test still uses `import_returning_trips` internally via `create_trips_summary`.

#### `tests/testthat/test_compute_individual_kde.R`

- **Cycle 1** adds a new `describe("compute_project_returning_tracks", ...)` block that feeds pre-filtered data and asserts `SpatialPointsDataFrame`.
- **Cycle 3** updates the existing `compute_individual_kde` test to use `import_returning_trips` + `compute_project_returning_tracks` + `compute_scale_parameters` inline to build inputs, then call the new three-parameter signature.

#### `DOCS.md`, `README.md`, `CHANGELOG.md`

- Update references: `create_processed_data` → `create_representative_assessment`
- Update `create_trips_summary` section: now writes RDS with returning trips only
- Update `create_individual_kde` section: reads sumTrips from RDS, outputs RDS
- Remove CSV + `datapackage.json` export references
- Remove old `create_processed_data` section

### Resolved decisions

| Question | Decision |
|---|---|---|
| `tripSummary` duplicate (two call sites) | `compute_trips_summary` is sole owner. Removed from `compute_individual_kde`. |
| `projectTracks` duplicate (two call sites) | New `compute_project_returning_tracks` is sole owner. Removed from `compute_individual_kde`. No separate `create_*` needed — only called from `create_individual_kde`, which materializes `tracks` inside `individual_kde.rds`. |
| `compute_scale_parameters` called from another `compute_*` | Now called directly from `create_individual_kde` (Level 2 → Level 1 Pure). No longer called from `compute_individual_kde`. |
| Where does the `data[data$Returns == "Yes", ]` filter belong? | `import_returning_trips` in `R/io.R` (Level 1 I/O). Row filtering is a permitted I/O adaptation per architecture. Neither `compute_project_returning_tracks` nor `compute_trips_summary` filters — both receive pre-filtered data. |
| `compute_project_returning_tracks` filter | Removed. Function only projects — the filter is upstream in `import_returning_trips`. |
| `compute_trips_summary` filter | Not added. Function receives pre-filtered returning trips from `create_trips_summary`. |
| What filter logic does `compute_project_returning_tracks` own? | None. It projects pre-filtered data only. The `Returns == "Yes"` filter lives in `import_returning_trips`. |
| Different data subsets (all trips vs returning only) | `import_returning_trips` provides returning trips. No production consumer needs all-trips summary. |
| Data filter ownership | All row filters belong in Level 1 I/O (`import_*`, `read_*`), not in `compute_*`. |
| `config-path` in `create_individual_kde` | Dropped. Colony no longer needed — `tripSummary` moved to `compute_trips_summary`, `projectTracks` moved to `compute_project_returning_tracks`. |
| `rds-path` pointing to CSV | `create_trips_summary` writes RDS. `rds-path` always points to RDS. |

### TDD cycles

Each cycle is a Red → Green TDD sequence ending with a passing test suite.
Order respects the dependency tree:

- Cycle 0 is a prerequisite for Cycles 2 and 3.
- Cycle 1 is a prerequisite for Cycle 3.
- Cycles 2, 4, 5, 6 are independent of each other (can run in any order after Cycle 0).

---

#### Cycle 0: Add `import_returning_trips` to `R/io.R`

**Red** — create test file `tests/testthat/test_io.R`:
- Add a `describe("import_returning_trips", ...)` block
- Feed it `trips_5_ids.csv` (contains both `Returns == "Yes"` and `Returns == "No"` rows)
- Assert the result is a data.frame with only returning trips (all rows have `Returns == "Yes"`)
- Assert that non-returning rows are excluded
- **Expected failure:** `import_returning_trips` does not exist → "could not find function"

**Green** — create production function in `R/io.R`:
```r
import_returning_trips <- function(path) {
  data <- readr::read_csv(path, show_col_types = FALSE)
  data[data$Returns == "Yes", ]
}
```
- Test passes ✓

**Files changed:** `tests/testthat/test_io.R` (Red, new file), `R/io.R` (Green)

**Note:** Row filtering (`data[data$Returns == "Yes", ]`) is explicitly permitted in Level 1 I/O per the architecture ("Filtrado de filas", item 7).

---

#### Cycle 1: Add `compute_project_returning_tracks` (projection only)

**Red** — update test file `tests/testthat/test_compute_individual_kde.R`:
- Add a `describe("compute_project_returning_tracks", ...)` block
- Feed it pre-filtered returning trips (e.g., `trips_5_ids.csv` filtered through `import_returning_trips`)
- Assert the result is a `SpatialPointsDataFrame`
- **Expected failure:** `compute_project_returning_tracks` does not exist → "could not find function"

**Green** — update production file `R/compute.R`:
```r
compute_project_returning_tracks <- function(data) {
  track2KBA::projectTracks(dataGroup = data, projType = "azim", custom = TRUE)
}
```
- Test passes ✓

**Files changed:** `tests/testthat/test_compute_individual_kde.R` (Red), `R/compute.R` (Green)

**Note:** No filter inside — `data` is already pre-filtered to returning trips by `import_returning_trips` (Cycle 0). This function only projects.

---

#### Cycle 2: Update `create_trips_summary` (use `import_returning_trips` + write RDS)

**Red** — update test file `tests/testthat/test_cli.R`:
- Change `create_trips_summary` test: expect `.rds` output instead of `.csv`
- Read back with `readRDS`, verify columns of `sumTrips`
- **Expected failure:** output is still CSV → `readRDS` fails or `exist_output_file` checks wrong path

**Green** — update production file `R/cli.R`:
- Replace `read_csv` with `import_returning_trips` (filtering moves to I/O layer)
- Change output from `write_csv` to `saveRDS`:
```r
create_trips_summary <- function(options) {
  config_content <- import_config(options[["config-path"]])
  returning_trips <- import_returning_trips(options[["data-path"]])
  sumTrips <- compute_trips_summary(returning_trips, config_content)
  saveRDS(sumTrips, options[["output-path"]])
}
```
- Test passes ✓

**Files changed:** `tests/testthat/test_cli.R` (Red), `R/cli.R` (Green)

**Prerequisite:** Cycle 0 must be complete (needs `import_returning_trips`)

---

#### Cycle 3: Simplify `compute_individual_kde` + rewrite `create_individual_kde`

This cycle changes two functions that are tightly coupled (caller/callee).
Must happen together to keep the suite passing.

**Red** — update two test files:

1. `tests/testthat/test_compute_individual_kde.R`:
   - Update existing test for `compute_individual_kde` to call new signature:
     ```r
     returning_trips <- import_returning_trips(data_path)
     tracks <- compute_project_returning_tracks(returning_trips)
     result <- compute_individual_kde(tracks, levelUD = 50, scale = ...)
     ```
   - Use `compute_scale_parameters` + scale dictionary inline to produce `scale`
   - Assertions (list structure, area) stay the same
   - **Expected failure:** `compute_individual_kde(data, config, levelUD, smoothing_method)` called with wrong argument count → error

2. `tests/testthat/test_cache.R`:
   - Rewrite `create_individual_kde` test: drop `config-path`, add `rds-path` (pointing to a `trips_summary.rds` generated inline via `compute_trips_summary`)
   - Assert RDS output contains `KDE_surface`, `UDPolygons`, `tracks`
   - **Expected failure:** `create_individual_kde` still uses old signature (reads config-path, writes GeoPackage) → test expects RDS but gets GeoPackage

**Green** — update two production files:

1. `R/compute.R` — simplify `compute_individual_kde`:
   ```r
   compute_individual_kde <- function(tracks, levelUD, scale) {
     KDE <- track2KBA::estSpaceUse(tracks = tracks, scale = scale, levelUD = levelUD, polyOut = TRUE)
     list(
       KDE_surface = KDE$KDE.Surface,
       UDPolygons = KDE$UDPolygons,
       tracks = tracks
     )
   }
   ```

2. `R/cli.R` — rewrite `create_individual_kde`:
   ```r
   create_individual_kde <- function(options) {
     returning_trips <- import_returning_trips(options[["data-path"]])
     sumTrips <- readRDS(options[["rds-path"]])
     levelUD <- options[["percentage-distribution"]]
     smoothing_method <- options[["smoothing-method"]]
     tracks <- compute_project_returning_tracks(returning_trips)
     scale_parameters <- compute_scale_parameters(tracks, sumTrips)
     scale_dictionary <- list(
       "log_median" = scale_parameters$mag,
       "reference_bandwidth" = scale_parameters$href,
       "scale_ARS" = scale_parameters$scaleARS
     )
     scale <- scale_dictionary[[smoothing_method]]
     kde <- compute_individual_kde(tracks, levelUD, scale)
     saveRDS(kde, options[["output-path"]])
   }
   ```

- Both tests pass ✓

**Files changed:** `tests/testthat/test_compute_individual_kde.R` (Red), `tests/testthat/test_cache.R` (Red), `R/compute.R` (Green), `R/cli.R` (Green)

**Prerequisites:** Cycles 0 and 1 must be complete (needs `import_returning_trips` and `compute_project_returning_tracks`)

---

#### Cycle 4: Merge `create_processed_data` into `create_representative_assessment`

**Red** — update test file `tests/testthat/test_cache.R`:
1. **Delete** the old `describe("create_representative_assessment", ...)` block (lines 70–99) — test removed from suite
2. **Rename** `describe("create_processed_data", ...)` to `describe("create_representative_assessment", ...)`:
   - Change call: `create_processed_data(options)` → `create_representative_assessment(options)`
   - Change options: drop `config-path`, `data-path`, `smoothing-method`; add `rds-path`
   - Assertions stay the same (check RDS output for `assessment_summary` + `assessment_detail`)
- **Expected failure:** `create_representative_assessment` has the old CSV-export body, does not accept the new options format, and does not write the expected RDS

**Green** — update production file `R/cli.R`:
1. **Delete** the entire `create_processed_data` function (lines 202–230)
2. **Rewrite** `create_representative_assessment`:
   ```r
   create_representative_assessment <- function(options) {
     cache <- readRDS(options[["rds-path"]])
     KDE_surface <- cache$KDE_surface
     tracks <- cache$tracks
     levelUD <- options[["percentage-distribution"]]
     n_iterations <- options[["n-iterations"]]
     result <- compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)
     result$KDE_surface <- KDE_surface
     saveRDS(result, options[["output-path"]])
   }
   ```
3. Remove the old CSV/datapackage.json body (the previous `create_representative_assessment`)
- Test passes ✓

**Files changed:** `tests/testthat/test_cache.R` (Red), `R/cli.R` (Green)

**Note:** This cycle is independent of Cycles 0–3 — it works entirely from pre-computed RDS caches.

---

#### Cycle 5: Simplify `create_potential_kba` (read from assessment RDS, drop re-computation)

**Red** — update test file `tests/testthat/test_cache.R`:
- Drop `config-path`, `data-path`, `smoothing-method` from options
- Mock cache must now include `KDE_surface` alongside `assessment_summary`
- **Expected failure:** `create_potential_kba` still expects old options and re-runs `compute_individual_kde`

**Green** — update production file `R/cli.R`:
- Rewrite `create_potential_kba`:
  ```r
  create_potential_kba <- function(options) {
    cache <- readRDS(options[["rds-path"]])
    KDE_surface <- cache$KDE_surface
    represent <- cache$assessment_summary$out
    levelUD <- options[["percentage-distribution"]]
    popSize <- options[["population-size"]]
    site <- compute_potential_kba(KDE_surface, represent, popSize, levelUD)
    sf::st_write(site, options[["output-path"]])
  }
  ```
- Test passes ✓

**Files changed:** `tests/testthat/test_cache.R` (Red), `R/cli.R` (Green)

---

#### Cycle 6: `render_individual_kde` reads from RDS instead of GeoPackage

**Red** — update test file `tests/testthat/slow/test_render_individual_kde.R`:
- Change input option from `gpkg-path` to `rds-path`, pointing to individual_kde.rds
- **Expected failure:** `render_individual_kde` still reads from `gpkg-path` → reads wrong path or wrong format

**Green** — update production file `R/cli.R`:
- Rewrite `render_individual_kde`:
  ```r
  render_individual_kde <- function(options) {
    cache <- readRDS(options[["rds-path"]])
    ud_polygons <- cache$UDPolygons
    plot <- plot_individual_kde(ud_polygons)
    ggplot2::ggsave(filename = options[["output-path"]], plot = plot, device = "png")
  }
  ```
- Test passes ✓

**Files changed:** `tests/testthat/slow/test_render_individual_kde.R` (Red), `R/cli.R` (Green)

---

#### Cycle 7: Refactor — docs and cleanup

No Red/Green — structural improvements only:

1. Update `DOCS.md`:
   - `create_processed_data` → `create_representative_assessment` everywhere
   - `create_trips_summary`: now uses `import_returning_trips` + writes RDS with returning trips only
   - `create_individual_kde`: reads via `import_returning_trips` + reads sumTrips from RDS + outputs RDS
   - Remove CSV + `datapackage.json` export references
   - Remove old `create_processed_data` section
   - Document `import_returning_trips` in I/O section

2. Update `README.md` — same references

3. Update `CHANGELOG.md` — document the changes

4. Run `make format` to ensure styling consistency

5. Verify with `make tests` (fast suite) — all cycles must pass

## Gold

- `sf_use_s2(FALSE)` save/restore in every `compute_*` that calls
  `track2KBA`. Pattern: `previous <- sf::sf_use_s2(FALSE);
  on.exit(sf::sf_use_s2(previous))`. Currently handled externally by
  fixture scripts. See AGENTS.md "Spatial (S2) and Colony" section.

---

## Completed

- `get_domain_specific_options()` missing `--gpkg-path` and `--rds-path`
  flags: fixed in v0.9.1 via TDD Red/Green cycle.
