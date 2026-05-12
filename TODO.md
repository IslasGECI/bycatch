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
