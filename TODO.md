# Implementation Plan: Function Renaming and Architecture Restructuring

**Gold:** Complete Sprint 5 — restructure render functions to skip the R6 class (`Track2KBA_Wrapper`) and use pre-computed artifacts.

## Architecture Reference

These three references define the architecture:

- [Arquitectura en niveles y capas](https://islas.dev/2026/05/15/arquitectura)
- [Guía de estilo](https://islas.dev/guia_de_estilo/STYLEGUIDE)
- [Desacoplamiento de análisis y visualización](https://islas.dev/2026/03/20/desacoplamiento)

### Levels

| Level | Layer | Prefixes | Rules |
|-------|-------|----------|-------|
| **Level 1** | **Pure** (in-memory) | `compute_*`, `plot_*` | No I/O, no side effects. Cannot call Level 1 I/O. |
| **Level 1** | **I/O** (disk) | `read_*`, `write_*`, `import_*`, `export_*` | Only I/O, no calculation. Cannot call Level 1 pure. |
| **Level 2** | **Artifact** | `create_*`, `render_*` | Read → pure → write. Can call Level 1. Cannot call other Level 2. |

Level 1 pure and Level 1 I/O are completely independent — they never call each other.

Level 2 functions (`create_*`, `render_*`) compose Level 1 functions. Only Make orchestrates Level 2 calls.

## Style Guide: Function Naming Convention

| Prefix | Role | Side effects | Scope | Level |
|--------|------|-------------|-------|-------|
| `compute_*` | In-memory calculation | None | Internal | 1 — Pure |
| `plot_*` | In-memory visualization | None | Internal | 1 — Pure |
| `create_*` | Read → compute → write | Disk I/O | Exported (`R/cli.R`) | 2 — Artifact |
| `render_*` | Read → `plot_*` → write image | Disk I/O | Exported (`R/cli.R`) | 2 — Artifact |
| `.*` | Private helper (dot prefix) | Varies | Internal, called only by Level 2 | 2 — Helper |

Level 1 I/O prefixes (`read_*`, `write_*`, `import_*`, `export_*`) are used by third-party packages directly — this project does not add new wrappers around them.

Controlled exceptions:
- `get_domain_specific_options()` — exported despite being a pure function (CLI helper).

### `sf_use_s2(FALSE)` rule

Only `compute_*` functions that call `track2KBA` operations get:
```r
previous_s2_setting <- sf::sf_use_s2(FALSE)
on.exit(sf::sf_use_s2(previous_s2_setting))
```

`plot_*` functions never set `sf_use_s2` (they only use ggplot2).

`create_*` / `render_*` are completely unaware of S2 state — `compute_*` self-manages.

### Colony rule

Colony is kept only inside `compute_*` functions that call `track2KBA` algorithms
(`tripSplit`, `tripSummary`). Colony is removed from all presentation layers:
`plot_*` and `render_*` functions never receive or use colony.

---

## Sprint Progress

### Phase 1 — Rename ✅

All three renames committed (see CHANGELOG for details). The R6 wrapper
methods, exported CLI functions, and tests were updated atomically.

### Phase 2 — Write / Render Separation (Sprints 5–8)

| Sprint | Status |
|--------|--------|
| Sprint 5 — Restructure render functions to skip R6 class | ⬜ Next |
| Sprint 6 — Remove R6 class, consolidate to `R/compute.R` | ⬜ |
| Sprint 7 — Signature cleanup and fixture finalization | ⬜ |
| Sprint 8 (potential) — Inline `compute_cache` into `create_processed_data` | ⬜ Maybe |

---

## Core Architecture

### Core principle: only Level 2 (create/render) is exported

`R/cli.R` exposes **only** Level 2 functions: `create_*` and `render_*`.
Every exported function follows the **three-line pattern**:

```
exported_function <- function(options) {
  input  <- read_from_disk(...)        # 1. Read (3rd-party I/O call)
  result <- internal_function(input)   # 2. Internal pure call (one or zero)
  write_to_disk(result, ...)           # 3. Write (3rd-party I/O call)
}
```

Multiple reads are acceptable (e.g., read two files). Multiple internal pure
calls are acceptable when the function needs to compose fast recomputation with
cached results — the key constraint is that no internal call runs `repAssess`. One
write per exported function.

Internal functions (`compute_*`, `plot_*`) have **no side effects**. They never
read from or write to disk — all I/O is pushed to the Level 2 layer.

### What changes

#### R6 class `Track2KBA_Wrapper` is removed

The class serves as a state container and workflow orchestrator. After Phase 2,
standalone `compute_*` functions replace both roles:
- `compute_individual_kde()` projects tracks, estimates scale, computes KDE → returns list
- `compute_representative_assessment()` wraps `repAssess(bootTable=TRUE)` → returns `list(assessment_summary, assessment_detail)`
- `compute_potential_kba()` wraps `findSite()` → returns sf object

These are internal functions. The state is passed explicitly as parameters instead
of being stored in an object. The R6 class is removed in Sprint 6.

#### All `compute_*` functions consolidate to `R/compute.R`

After Sprint 6, all Level 1 pure compute functions live in a single file.

### Internal functions (not exported, Level 1 — Pure)

All live in `R/compute.R` (after Sprint 6 consolidation).

#### Compute layer

| Function | Signature | Role |
|---|---|---|
| `compute_individual_kde` | `(data, config, levelUD, smoothing_method)` | `projectTracks` + `tripSummary` + `compute_scale_parameters` + `estSpaceUse` → `list(KDE_surface, UDPolygons, tracks)` |
| `compute_representative_assessment` | `(KDE_surface, tracks, levelUD, n_iterations)` | `repAssess(bootTable=TRUE)` with null device → `list(assessment_summary, assessment_detail)` |
| `compute_potential_kba` | `(KDE_surface, represent, popSize, levelUD)` | `findSite()` → sf polygons |
| `compute_cache` | `(data, config, levelUD, smoothing_method, n_iterations)` | Composes `compute_individual_kde` + `compute_representative_assessment` → `list(assessment_summary, assessment_detail)` |
| `compute_trips` | `(data, config_content)` | `formatFields` + `tripSplit` → SpatialPointsDataFrame |
| `compute_trips_summary` | `(trips, config_content)` | `tripSummary` → data.frame |
| `compute_scale_parameters` | `(tracks, trips_summary)` | `findScale` → list(mag, href, scaleARS) |
| `compute_filtered_fisheries_by_date_and_lat_lon` | `(fisheries_data, start, end, lat_min, lat_max, lon_min, lon_max)` | Date + lat/lon filtering pipeline |
| `compute_filtered_fisheries_by_date` | `(fisheries_data, start, end)` | Date filter wrapper |
| `compute_filtered_fisheries_by_lat_lon` | `(fisheries_data, lat_min, lat_max, lon_min, lon_max)` | Lat/lon filter |
| `compute_filtered_between_dates` | `(data, start, end, date_column)` | Generic date filter |

#### Plot layer

| Function | Input | Output | Replaces |
|---|---|---|---|
| `plot_representative_assessment` | Full iteration data.frame | ggplot2 scatterplot | `repAssess` inline plot |
| `plot_potential_kba` | sf polygons | ggplot2 map | `track2KBA::mapSite` (no colony) |
| `plot_individual_kde` | UDPolygons | ggplot2 map | `track2KBA::mapKDE` (no colony) |

All three live in `R/plot.R`.

### What `compute_cache` returns

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
`create_representative_assessment`) reads `assessment_summary` or `assessment_detail`
from cache — the expensive bootstrap never runs twice. Functions that only need
fast computations (`compute_individual_kde` results) recompute them on demand from
raw data.

### Exported functions in `R/cli.R` (Level 2)

Every exported function follows the three-line pattern.

#### Private helper

| Function | Purpose | Calls |
|---|---|---|
| `.adapt_config` | Read raw JSON config + build colony tibble | `rjson::fromJSON` + `tibble::tibble` |

#### Pipeline: processed data (cache)

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_processed_data` | raw CSV + config | `compute_cache(...)` → `repAssess` output | `.rds` (assessment_summary + assessment_detail) |

#### Pipeline: trips

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_trips` | raw CSV + config | `compute_trips(...)` | `.csv` |
| `create_trips_summary` | raw CSV + config | `compute_trips_summary(...)` | `.csv` |

#### Pipeline: fisheries filtering

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_filtered_fisheries` | fisheries CSV | `compute_filtered_fisheries_by_date_and_lat_lon(...)` | `.csv` |
| `create_filtered_gps_between_dates` | GPS CSV | `compute_filtered_between_dates(...)` | `.csv` |

#### Pipeline: representative assessment

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_representative_assessment` | `.rds` cache | extract + format | `.csv` + `datapackage.json` |
| `render_representative_assessment` | `.rds` cache | `plot_representative_assessment(assessment_detail)` | `.png` |

Both read ONLY the `.rds` cache (assessment_summary + assessment_detail). No
raw data needed. No computation re-run.

`create_representative_assessment` writes the full iteration results as a
[Tabular Data Package](https://specs.frictionlessdata.io/tabular-data-package/)
(CSV + `datapackage.json` with field schemas and summary metadata). This enables
external tools (Python, gnuplot) to reproduce the assessment scatterplot.

#### Pipeline: potential KBA

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_potential_kba` | `.rds` cache + raw CSV + config | `compute_individual_kde` (fast) → `compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)` | `.gpkg` |
| `render_potential_kba` | `.gpkg` (from create) | `plot_potential_kba(site)` | `.png` |

`create_potential_kba` reads the cache for `assessment_summary$out` (the bootstrap
result), then recomputes KDE_surface cheaply via `compute_individual_kde`, and passes
both to `compute_potential_kba`. The expensive `repAssess` is never re-run.

#### Pipeline: individual KDE

| Function | Read | Internal call | Write |
|---|---|---|---|
| `create_individual_kde` | raw CSV + config | `compute_individual_kde` (fast, no bootstrap) | `.gpkg` (UDPolygons) |
| `render_individual_kde` | `.gpkg` (from create) | `plot_individual_kde(UDPolygons)` | `.png` |

`create_individual_kde` recomputes `compute_individual_kde` from raw data each
time because the pipeline is fast (no `repAssess`). `render_individual_kde` reads
the pre-computed artifact — it never calls `compute_*`.

### Data flow diagram

```
create_processed_data(data_path, config_path, rds_path, ...)                    
  ├── rjson::fromJSON(config_path) + tibble::tibble   (via .adapt_config)
  ├── readr::read_csv(data_path)                           
  ├── compute_cache(data, config, ...)          # internal, pure: runs repAssess ONCE
  │     ├── compute_individual_kde(...)               # fast: projectTracks → estSpaceUse             
  │     └── compute_representative_assessment(...)   # expensive: repAssess(bootTable=TRUE)      
  │                                                                                            
  └── saveRDS(                                                                               
        list(assessment_summary, assessment_detail),  # ONLY repAssess output cached            
        rds_path)                                                                               
                                                                                                 
create_potential_kba(rds_path, data_path, config_path, popSize, levelUD, smoothing_method, gpkg_path)
  ├── readRDS(rds_path)                         # reads assessment_summary$out                 
  ├── rjson::fromJSON + tibble::tibble          # via .adapt_config
  ├── readr::read_csv(data_path)                                           
  ├── compute_individual_kde(data, config, levelUD, smoothing_method)  # fast, no repAssess          
  ├── compute_potential_kba(KDE_surface, assessment_summary$out, popSize, levelUD)              
  └── sf::st_write(site, gpkg_path)                                                                
                                                                                                 
render_potential_kba(gpkg_path, png_path)                                                      
  ├── sf::st_read(gpkg_path)                                                                        
  ├── plot_potential_kba(site)                   # replaces mapSite (no colony)                
  └── ggplot2::ggsave(png_path)                                                                          
                                                                                                 
render_representative_assessment(rds_path, png_path)                                           
  ├── readRDS(rds_path)                         # reads assessment_detail                      
  ├── plot_representative_assessment(assessment_detail)  # reconstructs scatterplot             
  └── ggplot2::ggsave(png_path)                                                                          
                                                                                                 
create_individual_kde(data_path, config_path, levelUD, smoothing_method, gpkg_path)              
  ├── rjson::fromJSON + tibble::tibble          # via .adapt_config
  ├── readr::read_csv(data_path)                                            
  ├── compute_individual_kde(data, config, levelUD, smoothing_method)  # fast, no repAssess          
  └── sf::st_write(UDPolygons, gpkg_path)                                                           

render_individual_kde(gpkg_path, png_path)                                                      
  ├── sf::st_read(gpkg_path)                                                                        
  ├── plot_individual_kde(UDPolygons)            # replaces mapKDE (no colony)                 
  └── ggplot2::ggsave(png_path)                                                                          
                                                                                                 
create_representative_assessment(rds_path, output_dir)                                         
  ├── readRDS(rds_path)                         # reads assessment_summary + assessment_detail 
  ├── (format iteration data + summary)                                                        
  └── readr::write_csv + write_datapackage_json                                                       
                                                                                                 
create_filtered_fisheries(fisheries_csv, output_csv, ...)                                      
  ├── readr::read_csv                                                                                  
  ├── compute_filtered_fisheries_by_date_and_lat_lon(...)  # internal pure transform                     
  └── readr::write_csv                                                                                 
                                                                                                 
create_filtered_gps_between_dates(gps_csv, output_csv, ...)                                    
  ├── readr::read_csv                                                                                  
  ├── compute_filtered_between_dates(...)                  # internal pure transform                     
  └── readr::write_csv                                                                                 
```

### Final file layout (after Sprint 7)

```
R/
  compute.R              # ALL compute_* functions (Level 1 pure)
  plot.R                 # ALL plot_* functions (Level 1 pure)
  cli.R                  # ALL create_* + render_* + .adapt_config (Level 2)
  get_domain_specific_options.R   # exported exception
```

Files removed during Phase 2:
- `R/read_config.R` → replaced by `.adapt_config` in `R/cli.R` (pre-work)
- `R/representative_assess.R` → folded into `R/compute.R` (Sprint 6)
- `R/track_example.R` → folded into `R/compute.R` (Sprint 6)
- `R/fisheries_process.R` → folded into `R/compute.R` (Sprint 6)
- `R/get_kernels.R` → folded into `R/compute.R` (Sprint 6)

### Key design decisions

1. **`track2kba` is NOT modified** — local clone at `track2kba/` is read-only
   reference. `repAssess` plot suppressed by wrapping call in `png(tempfile())` +
   `dev.off()`. `findSite` plot handled by our `plot_potential_kba` (replaces
   `mapSite`), not by `track2kba`.

2. **No optional arguments** — every parameter is mandatory. No hidden defaults,
   no auto-detection, no magical caching. Fail gracefully on missing inputs.

3. **No `render_*` computes** — Every `render_*` function reads a pre-computed
   artifact and never calls `compute_*`. The
   create phase (`create_*`) produces the artifact; the render phase
   (`render_*`) consumes it. `render_*` never resolves its own dependencies — an
   orchestrator (Make in `bycatch_thesis`) runs the create phase before the render
   phase. If a pre-computed artifact is missing, the function errors with a message
   telling the user which `create_*` to run first.

4. **`no side effects` is strict** — `compute_*` and `plot_*` functions never
   read or write files, never print to devices, never modify global state. All
   I/O is the responsibility of the Level 2 `create_*` / `render_*` layer.

5. **`sf_use_s2(FALSE)` is self-managed by `compute_*` functions** — Each
   `compute_*` that calls `track2KBA` saves the previous setting, disables S2,
   and restores on exit. `plot_*` and `create_*`/`render_*` are completely
   unaware of S2 state.

6. **Colony removed from presentation** — Colony is kept only inside `compute_*`
   calls to `track2KBA` algorithms (`tripSplit`, `tripSummary`). `plot_*` and
   `render_*` never receive or use colony.

7. **Backwards compatibility is not a concern** — downstream `bycatch_thesis`
   will be updated separately.

8. **The `.rds` stores ONLY the `repAssess` output and ALL the `repAssess` output**: `assessment_summary`
   data.frame (single row: `out`, `asym`, `Rep70`, `Rep95`) and `assessment_detail`
   data.frame (full iteration table). KDE_surface, UDPolygons, and tracks are
   fast to recompute and are never cached. Colony is only used internally by
   `compute_individual_kde` to call `tripSummary`.

9. **`plot_*` functions receive already-computed objects** — no computation, no
   I/O. They are called by `render_*` functions which read artifacts from disk.

10. **Tests use real fixture files, not mocks** — plot tests read pre-computed
    `.rds` fixtures from `tests/data/`. The one-time script
    `tests/src/create_test_fixtures.R` generates them from real `compute_*` calls.

---

## Downstream Impact (for `bycatch_thesis`)

The following `bycatch_thesis/Makefile` targets and function calls
will break after Phase 1 and must be updated (not part of this plan):

| Current call | After Phase 1 | Affected Makefile target(s) |
|---|---|---|
| `bycatch::plot_potential_site(...)` | `bycatch::render_potential_kba(...)` | `gps_albatross_50_percent_potential_site_ars_*.png` |
| `bycatch::plot_representative_assess(...)` | `bycatch::render_representative_assessment(...)` | `gps_albatross_50_percent_representative_assess_ars_*.png` |
| `bycatch::plot_individual_kernels(...)` | `bycatch::render_individual_kde(...)` | `gps_albatross_50_percent_individuals_kernel_ars_*.png` |

After Phase 2, the `render_*` and `create_*` function signatures change further.
They will accept artifact paths (`.rds`, `.gpkg`) instead of raw `data-path`
and `config-path`. This will require additional updates in
`bycatch_thesis/Makefile` at that time.

---

## Phase 2 — Micro-Step Execution Plan

### Test runner reference

| Command | What it runs | When to use |
|---|---|---|
| `make tests_fast` | All tests except `slow/` (~37s) | Every step that does NOT touch `render_*` functions |
| `make tests` | `tests_fast` + `tests_slow` (~12min) | Every step that touches a `render_*` function or its test |

### Pre-Work — Naming alignment

Before Sprint 3, rename all functions to match the architecture references.
No behavioral changes, no new functionality. Run `make tests_fast` after each step.

**Step P1 — Rename `export_*` to `create_*` (current functions)**
- File: `R/cli.R`, `tests/testthat/test_cli.R`
- Changes:
  - `export_filtered_fisheries` → `create_filtered_fisheries`
  - `export_filtered_gps_between_dates` → `create_filtered_gps_between_dates`
  - `export_trips` → `create_trips`
  - `export_trips_summary` → `create_trips_summary`
- Test: `make tests_fast`

**Step P2 — Rename `get_*` to `compute_*`**
- File: `R/track_example.R`, `R/cli.R`, `tests/testthat/test_track_example.R`
- Changes:
  - `get_trips` → `compute_trips` (update callers in `create_trips`)
  - `get_summary_of_trips` → `compute_trips_summary` (update callers in `create_trips_summary`)
- Test: `make tests_fast`

**Step P3 — Rename `filter_*` to `compute_filtered_*`**
- File: `R/fisheries_process.R`, `R/cli.R`, `tests/testthat/test_fisheries_process.R`
- Changes:
  - `filter_fisheries_by_date_and_lat_lon` → `compute_filtered_fisheries_by_date_and_lat_lon`
  - `filter_fisheries_by_date` → `compute_filtered_fisheries_by_date`
  - `filter_fisheries_by_lat_lon` → `compute_filtered_fisheries_by_lat_lon`
  - `filter_between_dates` → `compute_filtered_between_dates`
- Update callers in `create_filtered_fisheries` and `create_filtered_gps_between_dates`
- Test: `make tests_fast`

**Step P4 — Replace `read_config` with `.adapt_config`**
- File: Create `.adapt_config` in `R/cli.R`, delete `R/read_config.R`, delete `tests/testthat/test_config.R`
- Action: `.adapt_config` does the same JSON read + colony tibble build as `read_config`, but lives in `R/cli.R` as a private Level 2 helper (dot prefix)
- Update all callers in `R/cli.R` to use `.adapt_config`
- Test: `make tests_fast`

**Step P5 — Add `sf_use_s2` save/restore to `compute_*` functions calling `track2KBA`**
- File: `R/representative_assess.R`, `R/track_example.R`, `R/get_kernels.R`
- Action: At the top of each `compute_*` that calls a `track2KBA` function, add:
  ```r
  previous_s2_setting <- sf::sf_use_s2(FALSE)
  on.exit(sf::sf_use_s2(previous_s2_setting))
  ```
- Affected functions: `compute_individual_kde`, `compute_representative_assessment`, `compute_potential_kba`, `compute_trips`, `compute_trips_summary`, `compute_scale_parameters`
- Note: `compute_cache` delegates to other `compute_*` functions and does NOT need its own save/restore
- Test: `make tests_fast`

**Step P6 — Remove colony from `render_individual_kde`** 🗑️ Skipped
- File: `R/cli.R`
- Action: Dropped from plan. The colony-in-presentation problem is solved structurally
  when Sprint 5 replaces `track2KBA::mapKDE` with `plot_individual_kde` (which has no
  colony parameter). No separate intermediate step needed.
- Test: N/A

**Step P7 — Create test fixture generation script** ✅ Done
- File: `tests/src/create_test_fixtures.R` (new)
- Action: One-time script that runs the real `compute_*` functions once and saves outputs:
  - `tests/data/assessment_detail.rds` — from `compute_representative_assessment`
  - `tests/data/kba_polygons.rds` — from `compute_potential_kba`
  - `tests/data/ud_polygons.rds` — UDPolygons extracted from KDE output
- This script is not part of the test suite — run once, commit fixtures
- Test: N/A

**Step P8 — Bycatch thesis note** ✅ Done
- File: `../bycatch_thesis/TODO.md`
- Action: Add a note listing all renamed exported functions so `bycatch_thesis` can update its calls later
- Test: N/A



### Sprint 5 — Restructure render functions to skip R6 class

Runs **after Sprint 4** (serial dependency). The create-phase functions from
Sprint 4 produce the artifacts that these render functions consume.

**Testing note:** Slow tests use end-to-end artifact creation during migration
(call the Sprint 4 `create_*` inside the test preamble to produce
temp artifacts). After Sprint 7, swap to pre-computed fixture files in
`tests/data/`.

**Step 24 — Switch `render_representative_assessment` to artifact-reading**
- File: `R/cli.R`
- Action: Replace `Track2KBA_Wrapper$new(...)` + `wrapper$compute_representative_assessment(...)`
  with `readRDS(rds_path)` → `plot_representative_assessment(assessment_detail)` + `ggsave()`.
  Still accepts `options` list (which now must contain `rds-path` in addition to `output-path`).
  Internal logic is pure artifact-reading.
- Test: `make tests`

**Step 25 — Switch `render_potential_kba` to artifact-reading**
- File: `R/cli.R`
- Action: Replace R6 class usage + `mapSite()` with `sf::st_read(gpkg_path)` →
  `plot_potential_kba(site)` + `ggsave()`. Still accepts `options` list (which now must contain
  `gpkg-path` in addition to `output-path`). Internal logic is pure artifact-reading.
- Test: `make tests`

**Step 26a — Switch `render_individual_kde` to artifact-reading**
- File: `R/cli.R`
- Action: Replace R6 class usage + `mapKDE()` with `sf::st_read(gpkg_path)` →
  `plot_individual_kde(UDPolygons)` + `ggsave()`. Still accepts `options` list (which now must
  contain `gpkg-path` in addition to `output-path`). Internal logic is pure artifact-reading.
- Test: `make tests`

**Step 26b — Update `bycatch_thesis` to-do list**
- File: `../bycatch_thesis/TODO.md`
- Action: Add note: Sprint 5 restructures `render_*` functions to read pre-computed artifacts instead of running the R6 class. The options list now requires `rds-path` or `gpkg-path` in addition to `output-path`. The `data-path` and `config-path` arguments are no longer needed for render calls.
- Test: N/A

Stop before Sprint 6 and ask for confirmation before proceeding.

### Sprint 6 — Remove R6 class and consolidate to `R/compute.R`

R6 class is no longer used by CLI (Sprint 5 removed those callers). Only
`test_representative_assess.R` (fast) exercises R6 methods via `Wrapper_Tester`.

**Step 27 — Delete R6 class and consolidate compute functions**
- File: `R/representative_assess.R`, `R/track_example.R`, `R/fisheries_process.R`,
  `R/get_kernels.R`, `tests/testthat/test_representative_assess.R`
- Action:
  - Delete the `Track2KBA_Wrapper` definition and `Wrapper_Tester`
  - Delete `test_representative_assess.R`
  - Create `R/compute.R` containing ALL `compute_*` functions (moved from the four deleted files):
    - `compute_individual_kde`, `compute_representative_assessment`, `compute_potential_kba`,
      `compute_cache` (from `representative_assess.R`)
    - `compute_trips`, `compute_trips_summary` (from `track_example.R`)
    - `compute_filtered_fisheries_by_date_and_lat_lon`, `compute_filtered_fisheries_by_date`,
      `compute_filtered_fisheries_by_lat_lon`, `compute_filtered_between_dates`
      (from `fisheries_process.R`)
    - `compute_scale_parameters` (from `get_kernels.R`)
  - Move unique assertions from `test_representative_assess.R` into the per-function
    `test_compute_*.R` files:
    - Area checks from "Get KDE" (`expected_area = 17929`, `expected_area = 44250`)
      → into the `compute_individual_kde` test block.
    - `out ≈ 59.30424` check → into the `compute_representative_assessment` test block.
    - Scale dictionary name check (`"log_median"`, `"reference_bandwidth"`, `"scale_ARS"`)
      → into the `compute_scale_parameters` test block in `test_kernels.R`.
  - No loss of coverage, no duplication.
- Test: `make tests_fast`

**Note:** Test files stay in their current locations (`test_track_example.R`,
`test_fisheries_process.R`, `test_kernels.R`) — only the function locations under
test change. Renaming test files is optional and not required.

**Step 27b — Update `bycatch_thesis` to-do list**
- File: `../bycatch_thesis/TODO.md`
- Action: Add note: Sprint 6 removes the R6 class `Track2KBA_Wrapper` and consolidates all `compute_*` functions into `R/compute.R`. No direct impact on exported function signatures.
- Test: N/A

Stop before Sprint 7 and ask for confirmation before proceeding.

### Sprint 7 — Signature cleanup and fixture finalization

Change function signatures from `(options)` to explicit artifact paths (input
first, output last). **Steps 28–30 require `make tests` because slow tests
exercise these functions.**

**Step 28 — Update `render_representative_assessment` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_render_representative_assessment.R`
- Action: Change from `(options)` to `(rds_path, png_path)`. Update slow test.
- Test: `make tests`

**Step 29 — Update `render_potential_kba` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_render_potential_kba.R`
- Action: Change from `(options)` to `(gpkg_path, png_path)`. Update slow test.
- Test: `make tests`

**Step 30 — Update `render_individual_kde` signature**
- File: `R/cli.R`, `tests/testthat/slow/test_render_individual_kde.R`
- Action: Change from `(options)` to `(gpkg_path, png_path)`. Update slow test.
- Test: `make tests`

**Step 31 — Replace end-to-end test artifacts with pre-computed fixtures**
- File: `tests/testthat/slow/test_render_*.R`, new files in `tests/data/`
- Action: Create fixture `.rds` (assessment_detail) and fixture `.gpkg` files
  (KBA polygons, UDPolygons) in `tests/data/`. Replace the Sprint 5 end-to-end
  artifact-creation preamble in each slow test with a direct path to the fixture.
  The slow test now only tests the render pipeline: fixture → plot → PNG.
- Test: `make tests`

**Step 32 — Update `bycatch_thesis` to-do list**
- File: `../bycatch_thesis/TODO.md`
- Action: Add note: Sprint 7 changes `render_*` signatures from `(options)` to explicit parameters: `render_potential_kba(gpkg_path, png_path)`, `render_representative_assessment(rds_path, png_path)`, `render_individual_kde(gpkg_path, png_path)`. The Makefile `Rscript -e` calls must be updated to pass artifact paths directly instead of the options list. Also, the slow render tests now read pre-computed fixture files instead of calling `create_*` in the preamble.
- Test: N/A


---

### Phase 2 summary

| Sprint | Steps | `tests_fast` cycles | `tests` cycles | Total commits |
|---|---|---|---|---|---|
| **5 — Restructure renders** | **24–26** | — | **3 ahead** | **3** |
| 6 — Remove R6 + consolidate | 27 | 1 ahead | — | 1 |
| **7 — Signature cleanup + fixtures** | **28–31** | — | **4 ahead** | **4** |
| **Remaining** | **S5–S7** | **1 ahead** | **7 ahead** | **8 total** |

- Sprint 7 depends on Sprint 5 (slow test files refer to render functions).
