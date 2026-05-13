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

Multiple reads are acceptable (e.g., read two files). Multiple internal pure
calls are acceptable when the function needs to compose fast recomputation with
cached results — the key constraint is that no internal call runs `repAssess`. One
write per exported function.

Internal functions (`compute_*`, `plot_*`) have **no side effects**. They never
read from or write to disk — all I/O is pushed to the exported layer.

### What changes

#### R6 class `Track2KBA_Wrapper` is removed

The class serves as a state container and workflow orchestrator. After Phase 2,
standalone `compute_*` functions replace both roles:
- `compute_space_use()` projects tracks, estimates scale, computes KDE → returns list
- `compute_representative_assessment()` wraps `repAssess(bootTable=TRUE)` → returns `list(assessment_summary, assessment_detail)`
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
| `compute_space_use` | `(data, config, levelUD, smoothing_method)` | `projectTracks` + `tripSummary` + `get_scale_parameters` + `estSpaceUse` → `list(KDE_surface, UDPolygons, tracks)` | `R/representative_assess.R` |
| `compute_representative_assessment` | `(KDE_surface, tracks, levelUD, n_iterations)` | `repAssess(bootTable=TRUE)` with null device → `list(assessment_summary, assessment_detail)` (two data.frames) | `R/representative_assess.R` |
| `compute_potential_kba` | `(KDE_surface, represent, popSize, levelUD)` | `findSite()` → sf polygons | `R/representative_assess.R` |
| `compute_cache` | `(data, config, levelUD, smoothing_method, n_iterations)` | Composes `compute_space_use` + `compute_representative_assessment` → `list(assessment_summary, assessment_detail)` | `R/representative_assess.R` |

#### What `compute_cache` returns

The cache stores ONLY the output of `repAssess` — the expensive bootstrap.
Everything else (KDE_surface, UDPolygons, tracks) is fast to recompute and
is never cached.

```
list(
  assessment_summary = <data.frame>,                # single-row: out, asym, Rep70, Rep95
  assessment_detail  = <data.frame>                 # full iteration table (bootTable=TRUE)
)
```

**Main objective achieved:** `repAssess` runs once inside `compute_cache`. Every
downstream function (`compute_potential_kba`, `render_representative_assessment`,
`export_representative_assessment`) reads `assessment_summary` or `assessment_detail`
from cache — the expensive bootstrap never runs twice. Functions that only need
fast computations (`compute_space_use` results) recompute them on demand from
raw data.

#### Plot layer

All `plot_*` functions receive already-computed objects (no computation, no I/O).
They return a ggplot2 object.

| Function | Input | Output | Replaces |
|---|---|---|---|
| `plot_representative_assessment` | Full iteration data.frame | ggplot2 scatterplot | `repAssess` inline plot |
| `plot_potential_kba` | sf polygons | ggplot2 map | `track2KBA::mapSite` |
| `plot_individual_kde` | UDPolygons | ggplot2 map | `track2KBA::mapKDE` |

All three live in `R/plot.R`.

### Exported functions in `R/cli.R`

Every exported function follows the three-line pattern.

#### Pipeline: processed data (cache)

| Function | Read | Internal call | Write |
|---|---|---|---|
| `write_processed_data` | raw CSV + config | `compute_cache(...)` → `repAssess` output | `.rds` (assessment_summary + assessment_detail) |

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

Both read ONLY the `.rds` cache (assessment_summary + assessment_detail). No
raw data needed. No computation re-run.

`export_representative_assessment` writes the full iteration results as a
[Tabular Data Package](https://specs.frictionlessdata.io/tabular-data-package/)
(CSV + `datapackage.json` with field schemas and summary metadata). This enables
external tools (Python, gnuplot) to reproduce the assessment scatterplot.

#### Pipeline: potential KBA

| Function | Read | Internal call | Write |
|---|---|---|---|
| `export_potential_kba` | `.rds` cache + raw CSV + config | `compute_space_use` (fast) → `compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)` | `.gpkg` |
| `render_potential_kba` | `.gpkg` (from export) | `plot_potential_kba(site)` | `.png` |

`export_potential_kba` reads the cache for `assessment_summary$out` (the bootstrap
result), then recomputes KDE_surface cheaply via `compute_space_use`, and passes
both to `compute_potential_kba`. The expensive `repAssess` is never re-run.

#### Pipeline: individual KDE

| Function | Read | Internal call | Write |
|---|---|---|---|
| `render_individual_kde` | raw CSV + config | `compute_space_use` (fast) → `plot_individual_kde(UDPolygons)` | `.png` |

Individual KDE is fast (no bootstrap), so it recomputes `compute_space_use` from
raw data each time. No cache read needed. No separate `export_individual_kde` —
the `.gpkg` / `.rds` export pathways handle persistence if needed.

### Data flow diagram

```                                                 
write_processed_data(data_path, config_path, rds_path, ...)                    
  ├── read_csv(data_path) + read_config(config_path)                           
  ├── compute_cache(data, config, ...)          # internal, pure: runs repAssess ONCE
  │     ├── compute_space_use(...)               # fast: projectTracks → estSpaceUse             
  │     └── compute_representative_assessment(...)   # expensive: repAssess(bootTable=TRUE)      
  │                                                                                            
  └── write_rds(                                                                               
        list(assessment_summary, assessment_detail),  # ONLY repAssess output cached            
        rds_path)                                                                               
                                                                                                
export_potential_kba(rds_path, data_path, config_path, popSize, levelUD, smoothing_method, gpkg_path)
  ├── readRDS(rds_path)                         # reads assessment_summary$out                 
  ├── read_csv(data_path) + read_config(config_path)                                           
  ├── compute_space_use(data, config, levelUD, smoothing_method)  # fast, no repAssess          
  ├── compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)              
  └── st_write(site, gpkg_path)                                                                
                                                                                                
render_potential_kba(gpkg_path, png_path)                                                      
  ├── st_read(gpkg_path)                                                                        
  ├── plot_potential_kba(site)                   # replaces mapSite (no colony)                
  └── ggsave(png_path)                                                                          
                                                                                                
render_representative_assessment(rds_path, png_path)                                           
  ├── readRDS(rds_path)                         # reads assessment_detail                      
  ├── plot_representative_assessment(assessment_detail)  # reconstructs scatterplot             
  └── ggsave(png_path)                                                                          
                                                                                                
render_individual_kde(data_path, config_path, levelUD, smoothing_method, png_path)              
  ├── read_csv(data_path) + read_config(config_path)                                            
  ├── compute_space_use(data, config, levelUD, smoothing_method)  # fast, no repAssess          
  ├── plot_individual_kde(UDPolygons)            # replaces mapKDE (no colony)                 
  └── ggsave(png_path)                                                                          
                                                                                                
export_representative_assessment(rds_path, output_dir)                                         
  ├── readRDS(rds_path)                         # reads assessment_summary + assessment_detail 
  ├── (format iteration data + summary)                                                        
  └── write_csv + write_datapackage_json                                                       
                                                                                                
export_filtered_fisheries(fisheries_csv, output_csv, ...)                                      
  ├── read_csv                                                                                  
  ├── filter_fisheries_by_date_and_lat_lon(...)  # internal pure transform                     
  └── write_csv                                                                                 
                                                                                                
export_filtered_gps_between_dates(gps_csv, output_csv, ...)                                    
  ├── read_csv                                                                                  
  ├── filter_between_dates(...)                  # internal pure transform                     
  └── write_csv                                                                                 
```

### Key design decisions

1. **`track2kba` is NOT modified** — local clone at `track2kba/` is read-only
   reference. `repAssess` plot suppressed by wrapping call in `png(tempfile())` +
   `dev.off()`. `findSite` plot handled by our `plot_potential_kba` (replaces
   `mapSite`), not by `track2kba`.

2. **No optional arguments** — every parameter is mandatory. No hidden defaults,
   no auto-detection, no magical caching. Fail gracefully on missing inputs.

3. **Explicit pipeline** — `render_*` functions that depend on `repAssess` output
   (`render_representative_assessment`, `render_potential_kba`) never call
   `compute_*`. They always read a pre-computed artifact (cache or `.gpkg`).
   `render_individual_kde` is the exception — it recomputes `compute_space_use`
   from scratch because it is fast (no `repAssess`) and there is no dedicated
   export artifact for UDPolygons. If a pre-computed artifact is missing, the
   function errors with a message telling the user which `write_*` or `export_*`
   to run first.

4. **`no side effects` is strict** — `compute_*` and `plot_*` functions never
   read or write files, never print to devices, never modify global state. All
   I/O is the responsibility of the exported `write_*` / `export_*` / `render_*`
   layer.

5. **Backwards compatibility is not a concern** — downstream `bycatch_thesis`
   will be updated separately.

6. **The `.rds` stores ONLY the `repAssess` output**: `assessment_summary`
   data.frame (single row: `out`, `asym`, `Rep70`, `Rep95`) and `assessment_detail`
   data.frame (full iteration table). KDE_surface, UDPolygons, and tracks are
   fast to recompute and are never cached. Colony is only used internally by
   `compute_space_use` to call `tripSummary`.

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
They will accept artifact paths (`.rds`, `.gpkg`) instead of raw `data-path`
and `config-path`. This will require additional updates in
`bycatch_thesis/Makefile` at that time.

---

## Phase 2 — Micro-Step Execution Plan

### Test runner reference

| Command | What it runs | When to use |
|---|---|---|
| `make tests_fast` | All tests except `test_cli_slow.R` (~22s) | Every step that does NOT touch `render_*` functions |
| `make tests` | `tests_fast` + `tests_slow` (~5min) | Every step that touches a `render_*` function or its test |

### Sprint 1 — Rename 4 CLI functions ✅

**✅ Steps 1–12 (12 commits):** `filter_data_between_dates` → `export_filtered_gps_between_dates`,
`process_fisheries_data` → `export_filtered_fisheries`,
`write_trips_summary` → `export_trips_summary`,
`write_trips` → `export_trips`.

### Sprint 2 — Add standalone compute functions (alongside R6 class)

Each function follows **test-first**: 2 sub-steps per function. The test goes in `tests/testthat/test_compute.R` (new file). Pre-computed RDS fixtures (`tracks.rds`, `kde_20percent_sample.rds`, etc.) are reused from `test_representative_assess.R`.

**✅ Steps 13a–13c (4 commits):** `compute_space_use` function created (red → green),
class assertions corrected (`estUDm`, `sf`), colony removed from return value.
Commits: `56609f5`, `d8c7d62`, `b0a4596`, `588a661`.

**Step 14a — Red: add test for `compute_representative_assessment`**
- File: `tests/testthat/test_compute.R`
- Action: Add test that loads KDE surface + tracks RDS, calls `compute_representative_assessment(...)`, asserts result is a list with two data.frames: `assessment_summary` and `assessment_detail`. Check `assessment_summary$out ≈ 59.30424`.
- Test: `make tests_fast`

**Step 14b — Green: add `compute_representative_assessment`**
- File: `R/representative_assess.R`
- Action: Add standalone function wrapping `repAssess(bootTable = TRUE)` and extracting both summary and detail elements from the returned list
- Signature: `(KDE_surface, tracks, levelUD, n_iterations)` → `list(assessment_summary, assessment_detail)`
- Test: `make tests_fast`

**Step 15a — Red: add test for `compute_potential_kba`**
- File: `tests/testthat/test_compute.R`
- Action: Add test that loads KDE surface, calls `compute_potential_kba(...)`, asserts result is sf object
- Test: `make tests_fast`

**Step 15b — Green: add `compute_potential_kba`**
- File: `R/representative_assess.R`
- Action: Add standalone function wrapping `findSite()`
- Signature: `(KDE_surface, represent, popSize, levelUD)` → `sf` object
- Test: `make tests_fast`

**Step 16a — Red: add test for `compute_cache`**
- File: `tests/testthat/test_compute.R`
- Action: Add test that calls `compute_cache(...)`, asserts returned list has expected elements (assessment_summary, assessment_detail)
- Test: `make tests_fast`

**Step 16b — Green: add `compute_cache`**
- File: `R/representative_assess.R`
- Action: Add standalone function composing `compute_space_use` + `compute_representative_assessment`. Returns only the repAssess output — the cache is purely for avoiding re-running the expensive bootstrap. KDE_surface, UDPolygons, and tracks are NOT stored in the cache.
- Returns: `list(assessment_summary, assessment_detail)`
- Test: `make tests_fast`

### Sprint 3 — Add plot layer (new file `R/plot.R`)

Each function follows **test-first**: 2 sub-steps per function. Tests go in `tests/testthat/test_plot.R` (new file). Assert the returned object is a ggplot2 object.

**Step 17a — Red: add test for `plot_representative_assessment`**
- File: `tests/testthat/test_plot.R`
- Action: Add test calling `plot_representative_assessment(...)` with a mock data.frame, asserts `expect_s3_class(result, "ggplot")`
- Test: `make tests_fast`

**Step 17b — Green: add `plot_representative_assessment`**
- File: `R/plot.R` (new)
- Action: Add function taking assessment_detail data.frame → returns ggplot2 scatterplot
- Test: `make tests_fast`

**Step 18a — Red: add test for `plot_potential_kba`**
- File: `tests/testthat/test_plot.R`
- Action: Add test calling `plot_potential_kba(...)` with mock sf polygons, asserts ggplot class
- Test: `make tests_fast`

**Step 18b — Green: add `plot_potential_kba`**
- File: `R/plot.R`
- Action: Add function taking sf polygons → returns ggplot2 map (replaces `mapSite`, no colony)
- Test: `make tests_fast`

**Step 19a — Red: add test for `plot_individual_kde`**
- File: `tests/testthat/test_plot.R`
- Action: Add test calling `plot_individual_kde(...)` with mock UDPolygons, asserts ggplot class
- Test: `make tests_fast`

**Step 19b — Green: add `plot_individual_kde`**
- File: `R/plot.R`
- Action: Add function taking UDPolygons → returns ggplot2 map (replaces `mapKDE`, no colony)
- Test: `make tests_fast`

### Sprint 4 — Add new cache-based exported functions

Each function follows **test-first**: 2 sub-steps per function. Tests go in `tests/testthat/test_cache.R` (new file). Since these perform disk I/O, test with `tempfile()` paths.

**Step 20a — Red: add test for `write_processed_data`**
- File: `tests/testthat/test_cache.R`
- Action: Add test that creates a temp RDS path, calls `write_processed_data(...)`, asserts file exists and is valid RDS
- Test: `make tests_fast`

**Step 20b — Green: add `write_processed_data`**
- File: `R/cli.R`
- Action: Add exported function: read CSV + config → `compute_cache(...)` → `saveRDS()`. The RDS stores only assessment_summary + assessment_detail (the repAssess output). This is the ONLY function that runs the expensive bootstrap.
- Test: `make tests_fast`

**Step 21a — Red: add test for `export_potential_kba`**
- File: `tests/testthat/test_cache.R`
- Action: Add test that writes a mock `.rds` cache (with `assessment_summary$out`), calls `export_potential_kba(...)` with paths to mock data + config, asserts GPKG file exists
- Test: `make tests_fast`

**Step 21b — Green: add `export_potential_kba`**
- File: `R/cli.R`
- Action: Add exported function: `readRDS()` for cache `assessment_summary$out` + `read_csv`/`read_config` + `compute_space_use` (fast, recomputes KDE_surface) → `compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)` → `st_write()`. The expensive `repAssess` is never re-run.
- Test: `make tests_fast`

**Step 22a — Red: add test for `export_representative_assessment`**
- File: `tests/testthat/test_cache.R`
- Action: Add test that writes a mock `.rds` cache, calls `export_representative_assessment(...)`, asserts CSV + datapackage.json exist
- Test: `make tests_fast`

**Step 22b — Green: add `export_representative_assessment`**
- File: `R/cli.R`
- Action: Add exported function: `readRDS()` → format → `write_csv()` + `datapackage.json`
- Test: `make tests_fast`

### Sprint 5 — Restructure render functions to skip R6 class

These steps change the 3 functions that `test_cli_slow.R` tests. **Each requires `make tests`.**

**Step 23 — Switch `render_representative_assessment` to standalone functions**
- File: `R/cli.R`
- Action: Replace `Track2KBA_Wrapper$new(...)` + `wrapper$compute_representative_assessment(...)` with `compute_space_use(...)` + `compute_representative_assessment(...)` + `plot_representative_assessment(assessment_detail)` + `ggsave()`. `compute_representative_assessment` now suppresses the `repAssess` inline base R plot, so the plot must come from `plot_representative_assessment` instead. Still accepts `options` list.
- Test: `make tests`

**Step 24 — Switch `render_potential_kba` to standalone functions**
- File: `R/cli.R`
- Action: Replace R6 class usage + `mapSite()` with `compute_space_use(...)` + `compute_representative_assessment(...)` + `compute_potential_kba(...)` + `plot_potential_kba(site)` + `ggsave()`. Still accepts `options` list.
- Test: `make tests`

**Step 25 — Switch `render_individual_kde` to standalone functions**
- File: `R/cli.R`
- Action: Replace R6 class usage + `mapKDE()` with `compute_space_use(...)` + `plot_individual_kde(UDPolygons)` + `ggsave()`. Does NOT read the cache — recomputes fast pipeline from scratch. Still accepts `options` list.
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
- Action: Change from `(options)` to `(gpkg_path, png_path)`. `plot_potential_kba` no longer takes colony. Update slow test.
- Test: `make tests`

**Step 32 — Update `render_individual_kde` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_cli_slow.R`
- Action: Change from `(options)` to `(data_path, config_path, levelUD, smoothing_method, png_path)`. Unlike the other two render functions, `render_individual_kde` does NOT read the cache — it recomputes `compute_space_use` from scratch (fast, no `repAssess`). Update slow test.
- Test: `make tests`

---

### Phase 2 summary

| Sprint | Steps | `tests_fast` cycles | `tests` cycles | Total commits |
|---|---|---|---|---|---|---|---|
| 1 — Rename 4 exports | 1–12 | ✅ done | — | 12 |
| 2 — Add compute layer | ✅ **13a–13c**, **14a–16b** | **4 done / 6 remaining** | — | **4 / 10** |
| 3 — Add plot layer | 17a–19b | 6 ahead | — | 6 |
| 4 — Add cache exports | 20a–22b | 6 ahead | — | 6 |
| **5 — Restructure renders** | **23–25** | — | **3 ahead** | **3** |
| 6 — Strangle R6 | 26–29 | 4 ahead | — | 4 |
| **7 — Signature cleanup** | **30–32** | — | **3 ahead** | **3** |
| **Total** | **1–44** | **16 done / 38 planned** | **0 done / 6 planned** | **16 done / 44 planned** |
