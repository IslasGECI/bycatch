# Implementation Plan: Function Renaming and Architecture Restructuring

## Objectives

- Align function names with the project style guide
  (verb prefix convention: `compute_*`, `plot_*`, `write_*`, `export_*`, `render_*`, etc.)
- Replace ambiguous or outdated terminology:
  `potential_site` → `potential_kba` (Key Biodiversity Area),
  `assess` → `assessment`,
  `individual_kernels` → `individual_kde`
- Clearly separate the rename phase from the later write/render restructuring phase
- Only exported functions are Disk I/O functions (`write_*`, `export_*`, `render_*`)
- Internal pure functions (`compute_*`, `plot_*`) are never exposed in `R/cli.R`
- The expensive bootstrap (`repAssess`) runs once; downstream functions consume cached results

## Style Guide: Function Naming Convention

Reference: https://islas.dev/guia_de_estilo/STYLEGUIDE

| Prefix | Role | Side effects | Scope |
|--------|------|-------------|-------|
| `compute_*` | In-memory calculation | None | Internal |
| `plot_*` | In-memory visualization | None | Internal |
| `export_*` | Write interoperable format (`.csv`, `.gpkg`) | Disk I/O | Exported (`R/cli.R`) |
| `write_*` | Write native format (`.rds`) | Disk I/O | Exported (`R/cli.R`) |
| `render_*` | Read artifact → `plot_*` → write image | Disk I/O | Exported (`R/cli.R`) |
| `get_*` | Only if a complementary `set_*` exists | — | Internal |
| `read_*` / `import_*` | Read from disk | Disk I/O | Internal |

Controlled exceptions:
- `get_domain_specific_options()` — exported despite being a pure function (CLI helper).

---

## Phase 1 — Rename ✅

All three renames committed (see CHANGELOG for details). The R6 wrapper
methods, exported CLI functions, and tests were updated atomically.

---

## Phase 2 — Write / Render Separation

### Core principle: only Disk I/O is exported

`R/cli.R` exposes **only** functions that perform Disk I/O: `write_*`, `export_*`, and
`render_*`. Every exported function follows the **three-line pattern**:

```
exported_function <- function(options) {
  input  <- read_from_disk(...)        # 1. Read
  result <- internal_function(input)   # 2. Internal pure call (one or zero)
  write_to_disk(result, ...)           # 3. Write
}
```

Multiple reads are acceptable (e.g., read two files) as long as there is exactly
one internal pure call and one write.

Internal functions (`compute_*`, `plot_*`) have **no side effects**. They never
read from or write to disk — all I/O is pushed to the exported layer.

### What changes

#### R6 class `Track2KBA_Wrapper` is removed

The class serves as a state container and workflow orchestrator. After Phase 2,
standalone `compute_*` functions replace both roles:
- `compute_space_use()` projects tracks, estimates scale, computes KDE → returns list
- `compute_representative_assessment()` wraps `repAssess(bootTable=TRUE)` → returns data.frame
- `compute_potential_kba()` wraps `findSite()` → returns sf object

These are internal functions. The state is passed explicitly as parameters instead
of being stored in an object. The R6 class file (`R/representative_assess.R`) is
replaced by standalone functions.

#### Existing function renames

| Current name | New name | Reason |
|---|---|---|
| `write_trips` | `export_trips` | Writes CSV (interoperable) |
| `write_trips_summary` | `export_trips_summary` | Writes CSV (interoperable) |
| `process_fisheries_data` | `export_filtered_fisheries` | Writes CSV (interoperable) |
| `filter_data_between_dates` | `export_filtered_gps_between_dates` | Writes CSV (interoperable) |

The pure transform logic inside `process_fisheries_data` and
`filter_data_between_dates` is extracted into internal `compute_*` functions so
the exported layer follows the three-line pattern.

#### `create_*` prefix is not used

The style guide defines `create_*` as "compute + write". This project does not
use `create_*`. `compute_cache` is internal and pure (no Disk I/O). The exported
function that serialises it is `write_processed_data`.

### Internal functions (not exported)

All live in `R/` files outside `R/cli.R`.

#### Compute layer

| Function | Signature | Role | Location |
|---|---|---|---|
| `compute_space_use` | `(data, config, levelUD, smoothing_method)` | `projectTracks` + `tripSummary` + `get_scale_parameters` + `estSpaceUse` → `list(KDE_surface, UDPolygons, colony, tracks)` | `R/representative_assess.R` |
| `compute_representative_assessment` | `(KDE_surface, tracks, levelUD, n_iterations)` | `repAssess(bootTable=TRUE)` with null device → full iteration data.frame | `R/representative_assess.R` |
| `compute_potential_kba` | `(KDE_surface, represent, popSize, levelUD)` | `findSite()` → sf polygons | `R/representative_assess.R` |
| `compute_cache` | `(data, config, levelUD, smoothing_method, n_iterations)` | Composes `compute_space_use` + `compute_representative_assessment` → full result list | `R/representative_assess.R` |

#### What `compute_cache` returns

```
list(
  KDE_surface       = <RasterLayer>,               # from estSpaceUse
  UDPolygons        = <SpatialPolygonsDataFrame>,   # from estSpaceUse
  colony            = <tibble>,                     # from config
  assessment_summary = <data.frame>,                # single-row: out, asym, Rep70, Rep95
  assessment_detail  = <data.frame>                 # full iteration table (bootTable=TRUE)
)
```

**Main objective achieved:** `repAssess` runs once inside `compute_cache`. Every
downstream function (`export_potential_kba`, `render_representative_assessment`,
`render_individual_kde`) reads cached results — the expensive bootstrap never
runs twice.

#### Plot layer

All `plot_*` functions receive already-computed objects (no computation, no I/O).
They return a ggplot2 object.

| Function | Input | Output | Replaces |
|---|---|---|---|
| `plot_representative_assessment` | Full iteration data.frame | ggplot2 scatterplot | `repAssess` inline plot |
| `plot_potential_kba` | sf polygons + colony | ggplot2 map | `track2KBA::mapSite` |
| `plot_individual_kde` | UDPolygons + colony | ggplot2 map | `track2KBA::mapKDE` |

All three live in `R/plot.R`.

### Exported functions in `R/cli.R`

Every exported function follows the three-line pattern.

#### Pipeline: processed data

| Function | Read | Internal call | Write |
|---|---|---|---|
| `write_processed_data` | raw CSV + config | `compute_cache(...)` | `.rds` |

#### Pipeline: trips

| Function | Read | Internal call | Write |
|---|---|---|---|
| `export_trips` | raw CSV + config | `get_trips(...)` | `.csv` |
| `export_trips_summary` | raw CSV + config | `get_summary_of_trips(...)` | `.csv` |

#### Pipeline: fisheries filtering

| Function | Read | Internal call | Write |
|---|---|---|---|
| `export_filtered_fisheries` | fisheries CSV | `filter_fisheries_by_date_and_lat_lon(...)` | `.csv` |
| `export_filtered_gps_between_dates` | GPS CSV | `filter_between_dates(...)` | `.csv` |

#### Pipeline: representative assessment

| Function | Read | Internal call | Write |
|---|---|---|---|
| `export_representative_assessment` | `.rds` cache | extract + format | `.csv` + `datapackage.json` |
| `render_representative_assessment` | `.rds` cache | `plot_representative_assessment(assessment_detail)` | `.png` |

`export_representative_assessment` writes the full iteration results as a
[Tabular Data Package](https://specs.frictionlessdata.io/tabular-data-package/)
(CSV + `datapackage.json` with field schemas and summary metadata). This enables
external tools (Python, gnuplot) to reproduce the assessment scatterplot.

#### Pipeline: potential KBA

| Function | Read | Internal call | Write |
|---|---|---|---|
| `export_potential_kba` | `.rds` cache | `compute_potential_kba(KDE_surface, out, popSize, levelUD)` | `.gpkg` |
| `render_potential_kba` | `.gpkg` (from export) + colony file | `plot_potential_kba(site, colony)` | `.png` |

`export_potential_kba` writes the KBA polygons to `.gpkg`. Colony location is
read from a separate file (JSON, GeoJSON, or GeoPackage) passed as an option.

#### Pipeline: individual KDE

| Function | Read | Internal call | Write |
|---|---|---|---|
| `render_individual_kde` | `.rds` cache | `plot_individual_kde(UDPolygons, colony)` | `.png` |

Individual KDE is fast (no bootstrap), so the three-line pattern applies directly
from the cache. No separate `export_individual_kde` — the `.rds` already holds
the KDE polygons.

### Data flow diagram

```
write_processed_data(data, config, ...)
  │
  ├── compute_cache(data, config, ...)         # internal, pure
  │     ├── compute_space_use(...)              # fast: projectTracks → estSpaceUse
  │     └── compute_representative_assessment(...)  # expensive: repAssess(bootTable=TRUE)
  │
  └── write_rds(list(KDE_surface, UDPolygons, colony, assessment_summary, assessment_detail), rds_path)

export_potential_kba(rds_path, popSize, gpkg_path)
  ├── readRDS(rds_path)
  ├── compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)  # no repAssess re-run
  └── st_write(site, gpkg_path)

render_potential_kba(gpkg_path, colony_path, png_path)
  ├── st_read(gpkg_path) + read_colony(colony_path)
  ├── plot_potential_kba(site, colony)          # replaces mapSite
  └── ggsave(png_path)

render_representative_assessment(rds_path, png_path)
  ├── readRDS(rds_path)
  ├── plot_representative_assessment(assessment_detail)  # reconstructs scatterplot
  └── ggsave(png_path)

render_individual_kde(rds_path, png_path)
  ├── readRDS(rds_path)
  ├── plot_individual_kde(UDPolygons, colony)   # replaces mapKDE
  └── ggsave(png_path)

export_representative_assessment(rds_path, output_dir)
  ├── readRDS(rds_path)
  ├── (format iteration data + summary)
  └── write_csv + write_datapackage_json

export_filtered_fisheries(fisheries_csv, output_csv, ...)
  ├── read_csv
  ├── filter_fisheries_by_date_and_lat_lon(...) # internal pure transform
  └── write_csv

export_filtered_gps_between_dates(gps_csv, output_csv, ...)
  ├── read_csv
  ├── filter_between_dates(...)                 # internal pure transform
  └── write_csv
```

### Key design decisions

1. **`track2kba` is NOT modified** — local clone at `track2kba/` is read-only
   reference. `repAssess` plot suppressed by wrapping call in `png(tempfile())` +
   `dev.off()`. `findSite` plot handled by our `plot_potential_kba` (replaces
   `mapSite`), not by `track2kba`.

2. **No optional arguments** — every parameter is mandatory. No hidden defaults,
   no auto-detection, no magical caching. Fail gracefully on missing inputs.

3. **Explicit pipeline** — `render_*` never calls `compute_*`. It always reads a
   pre-computed artifact. If the artifact is missing, the function errors with a
   message telling the user which `write_*` or `export_*` to run first.

4. **`no side effects` is strict** — `compute_*` and `plot_*` functions never
   read or write files, never print to devices, never modify global state. All
   I/O is the responsibility of the exported `write_*` / `export_*` / `render_*`
   layer.

5. **Backwards compatibility is not a concern** — downstream `bycatch_thesis`
   will be updated separately.

6. **The `.rds` stores everything downstream needs**: `KDE_surface` raster,
   `UDPolygons` spatial polygons, `colony` tibble, `assessment_summary`
   data.frame (single row), and `assessment_detail` data.frame (full iteration
   results).

7. **`plot_*` functions receive already-computed objects** — no computation, no
   I/O. They are called by `render_*` functions which read artifacts from disk.

---

## Downstream Impact (for `bycatch_thesis`)

The following `bycatch_thesis/Makefile` targets and function calls
will break after Phase 1 and must be updated (not part of this plan):

| Current call | After Phase 1 | Affected Makefile target(s) |
|---|---|---|
| `bycatch::plot_potential_site(...)` | `bycatch::render_potential_kba(...)` | `gps_albatross_50_percent_potential_site_ars_*.png` |
| `bycatch::plot_representative_assess(...)` | `bycatch::render_representative_assessment(...)` | `gps_albatross_50_percent_representative_assess_ars_*.png` |
| `bycatch::plot_individual_kernels(...)` | `bycatch::render_individual_kde(...)` | `gps_albatross_50_percent_individuals_kernel_ars_*.png` |

After Phase 2, the `render_*` and `export_*` function signatures change further.
They will accept artifact paths (`.rds`, `.gpkg`, colony file) instead of raw
`data-path` and `config-path`. This will require additional updates in
`bycatch_thesis/Makefile` at that time.

---

## Phase 2 — Micro-Step Execution Plan

### Test runner reference

| Command | What it runs | When to use |
|---|---|---|
| `make tests_fast` | All tests except `test_cli_slow.R` (~22s) | Every step that does NOT touch `render_*` functions |
| `make tests` | `tests_fast` + `tests_slow` (~5min) | Every step that touches a `render_*` function or its test |

### Sprint 1 — Rename 4 CLI functions (one at a time)

Each rename is 3 micro-steps: Add new → Switch caller → Delete old. 12 commits total.

**✅ Step 1 — Add `export_filtered_gps_between_dates`**
- File: `R/cli.R`
- Action: Add new function with same body as `filter_data_between_dates`
- Test: `make tests_fast`

**✅ Step 2 — Switch test to `export_filtered_gps_between_dates`**
- File: `tests/testthat/test_cli.R`
- Action: Change test caller from `filter_data_between_dates` to `export_filtered_gps_between_dates`
- Test: `make tests_fast`

**✅ Step 3 — Delete `filter_data_between_dates`**
- File: `R/cli.R`
- Action: Remove old function definition
- Test: `make tests_fast`

**✅ Step 4 — Add `export_filtered_fisheries`**
- File: `R/cli.R`
- Action: Add new function with same body as `process_fisheries_data`
- Test: `make tests_fast`

**✅ Step 5 — Switch test to `export_filtered_fisheries`**
- File: `tests/testthat/test_cli.R`
- Action: Change test caller from `process_fisheries_data` to `export_filtered_fisheries`
- Test: `make tests_fast`

**✅ Step 6 — Delete `process_fisheries_data`**
- File: `R/cli.R`
- Action: Remove old function definition
- Test: `make tests_fast`

**✅ Step 7 — Add `export_trips_summary`**
- File: `R/cli.R`
- Action: Add new function with same body as `write_trips_summary`
- Test: `make tests_fast`

**✅ Step 8 — Switch test to `export_trips_summary`**
- File: `tests/testthat/test_cli.R`
- Action: Change test caller from `write_trips_summary` to `export_trips_summary`
- Test: `make tests_fast`

**✅ Step 9 — Delete `write_trips_summary`**
- File: `R/cli.R`
- Action: Remove old function definition
- Test: `make tests_fast`

**✅ Step 10 — Add `export_trips`**
- File: `R/cli.R`
- Action: Add new function with same body as `write_trips`
- Test: `make tests_fast`

**✅ Step 11 — Switch test to `export_trips`**
- File: `tests/testthat/test_cli.R`
- Action: Change test caller from `write_trips` to `export_trips`
- Test: `make tests_fast`

**✅ Step 12 — Delete `write_trips`**
- File: `R/cli.R`
- Action: Remove old function definition
- Test: `make tests_fast`

### Sprint 2 — Add standalone compute functions (alongside R6 class)

All added to `R/representative_assess.R`. Nothing calls them yet. R6 class unchanged.

**Step 13 — Add `compute_space_use`**
- File: `R/representative_assess.R`
- Action: Add standalone function extracting the full `projectTracks` + `tripSummary` + `get_scale_parameters` + `estSpaceUse` pipeline
- Signature: `(data, config, levelUD, smoothing_method)` → `list(KDE_surface, UDPolygons, colony, tracks)`
- Test: `make tests_fast`

**Step 14 — Add `compute_representative_assessment`**
- File: `R/representative_assess.R`
- Action: Add standalone function wrapping `repAssess(bootTable = FALSE)`
- Signature: `(KDE_surface, tracks, levelUD, n_iterations)` → `data.frame`
- Test: `make tests_fast`

**Step 15 — Add `compute_potential_kba`**
- File: `R/representative_assess.R`
- Action: Add standalone function wrapping `findSite()`
- Signature: `(KDE_surface, represent, popSize, levelUD)` → `sf` object
- Test: `make tests_fast`

**Step 16 — Add `compute_cache`**
- File: `R/representative_assess.R`
- Action: Add standalone function composing `compute_space_use` + `compute_representative_assessment`
- Returns: full result list (KDE_surface, UDPolygons, colony, assessment_detail)
- Test: `make tests_fast`

### Sprint 3 — Add plot layer (new file `R/plot.R`)

Pure ggplot2 functions. No I/O. No callers yet.

**Step 17 — Add `plot_representative_assessment`**
- File: `R/plot.R` (new)
- Action: Add function taking assessment_detail data.frame → returns ggplot2 scatterplot
- Test: `make tests_fast`

**Step 18 — Add `plot_potential_kba`**
- File: `R/plot.R`
- Action: Add function taking sf polygons + colony → returns ggplot2 map
- Test: `make tests_fast`

**Step 19 — Add `plot_individual_kde`**
- File: `R/plot.R`
- Action: Add function taking UDPolygons + colony → returns ggplot2 map
- Test: `make tests_fast`

### Sprint 4 — Add new cache-based exported functions

New exports added to `R/cli.R` alongside existing functions. No callers yet.

**Step 20 — Add `write_processed_data`**
- File: `R/cli.R`
- Action: Add exported function: read CSV + config → `compute_cache(...)` → `saveRDS()`
- Test: `make tests_fast`

**Step 21 — Add `export_potential_kba`**
- File: `R/cli.R`
- Action: Add exported function: `readRDS()` → `compute_potential_kba(...)` → `st_write()`
- Test: `make tests_fast`

**Step 22 — Add `export_representative_assessment`**
- File: `R/cli.R`
- Action: Add exported function: `readRDS()` → format → `write_csv()` + `datapackage.json`
- Test: `make tests_fast`

### Sprint 5 — Restructure render functions to skip R6 class

These steps change the 3 functions that `test_cli_slow.R` tests. **Each requires `make tests`.**

**Step 23 — Switch `render_representative_assessment` to standalone functions**
- File: `R/cli.R`
- Action: Replace `Track2KBA_Wrapper$new(...)` + `wrapper$compute_representative_assessment(...)` with `compute_space_use(...)` + `compute_representative_assessment(...)`. Still accepts `options` list. Still writes PNG via `png()`/`dev.off()`.
- Test: `make tests`

**Step 24 — Switch `render_potential_kba` to standalone functions**
- File: `R/cli.R`
- Action: Replace R6 class usage with `compute_space_use(...)` + `compute_representative_assessment(...)` + `compute_potential_kba(...)` + `mapSite()`. Still accepts `options` list.
- Test: `make tests`

**Step 25 — Switch `render_individual_kde` to standalone functions**
- File: `R/cli.R`
- Action: Replace R6 class usage with `compute_space_use(...)` + `mapKDE()`. Still accepts `options` list.
- Test: `make tests`

### Sprint 6 — Strangle R6 class

R6 class is no longer used by CLI (Sprint 5 removed those callers). Only `test_representative_assess.R` (fast) exercises R6 methods directly via `Wrapper_Tester`.

**Step 26 — Make R6 `initialize` delegate to `compute_space_use`**
- File: `R/representative_assess.R`
- Action: Change R6 `initialize` to call `compute_space_use()` internally. Individual methods (`get_tracks`, `get_scale_dictionary`, `estimate_space_use`) remain unchanged.
- Test: `make tests_fast`

**Step 27 — Make R6 `compute_representative_assessment` delegate to standalone**
- File: `R/representative_assess.R`
- Action: Change R6 method body to call standalone `compute_representative_assessment()`
- Test: `make tests_fast`

**Step 28 — Make R6 `compute_potential_kba` delegate to standalone**
- File: `R/representative_assess.R`
- Action: Change R6 method body to call standalone `compute_potential_kba()`
- Test: `make tests_fast`

**Step 29 — Remove R6 class, update tests**
- File: `R/representative_assess.R`, `tests/testthat/test_representative_assess.R`
- Action: Delete `Track2KBA_Wrapper` definition. Update `test_representative_assess.R` to call standalone functions directly instead of through `Wrapper_Tester`.
- Test: `make tests_fast`

### Sprint 7 — Signature cleanup

Change function signatures from `(options)` to explicit artifact paths. **Each requires `make tests` because slow tests exercise these functions.**

**Step 30 — Update `render_representative_assessment` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_cli_slow.R`
- Action: Change from `(options)` to `(rds_path, png_path)`. Update slow test.
- Test: `make tests`

**Step 31 — Update `render_potential_kba` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_cli_slow.R`
- Action: Change from `(options)` to `(gpkg_path, colony_path, png_path)`. Update slow test.
- Test: `make tests`

**Step 32 — Update `render_individual_kde` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_cli_slow.R`
- Action: Change from `(options)` to `(rds_path, png_path)`. Update slow test.
- Test: `make tests`

---

### Phase 2 summary

| Sprint | Steps | `tests_fast` cycles | `tests` cycles | Total commits |
|---|---|---|---|---|---|
| 1 — Rename 4 exports | 1–12 | ✅ 12 done | 0 | 12 |
| 2 — Add compute layer | 13–16 | 4 | 0 | 4 |
| 3 — Add plot layer | 17–19 | 3 | 0 | 3 |
| 4 — Add cache exports | 20–22 | 3 | 0 | 3 |
| **5 — Restructure renders** | **23–25** | **0** | **3** | **3** |
| 6 — Strangle R6 | 26–29 | 4 | 0 | 4 |
| **7 — Signature cleanup** | **30–32** | **0** | **3** | **3** |
| **Total** | **1–32** | **26 fast** | **6 full** | **32 commits** |
