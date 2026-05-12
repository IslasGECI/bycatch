# Implementation Plan: Function Renaming and Architecture Restructuring

## Objectives

- Align function names with the project style guide
  (verb prefix convention: `compute_*`, `render_*`, `export_*`, etc.)
- Replace ambiguous or outdated terminology:
  `potential_site` → `potential_kba` (Key Biodiversity Area),
  `assess` → `assessment`,
  `individual_kernels` → `individual_kde`
- Clearly separate the rename phase from the later write/render restructuring phase

## Style Guide: Function Naming Convention

| Prefix | Role | Side effects |
|--------|------|-------------|
| `compute_*` | In-memory calculation | None |
| `plot_*` | In-memory visualization | None |
| `export_*` | Write interoperable formats (`.gpkg`, `.csv`) | Disk I/O |
| `write_*` | Write native format (`.rds`) | Disk I/O |
| `create_*` | Compute + write (`compute_*` + `write_*` or `export_*`) | Disk I/O |
| `render_*` | Read artifact + plot + write image | Disk I/O |
| `get_*` | Only if a complementary `set_*` exists | — |

---

## Phase 1 — Rename ✅

All three renames committed (see CHANGELOG for details). The R6 wrapper
methods, exported CLI functions, and tests were updated atomically.

## Phase 2 — Write / Render Separation

After all renames are done, the current CLI functions still mix
computation and rendering in a single step. Phase 2 splits each
pipeline into three independent layers.

### Architecture

```
compute_*           in-memory calculation, no side effects
plot_*              in-memory visualization (no disk I/O)
write_*             write native format (.rds)
export_*            write interoperable format (.gpkg, .csv)
create_*            compute_* + write_* (one-step convenience, controlled exception)
render_*            read artifact + plot_* + write image (controlled exception)
```

### Data flow

```
create_cache(data_path, config_path, levelUD, n_iterations, smoothing_method, rds_path)
  │
  ├── compute_space_use(data_path, config_path, levelUD, smoothing_method)
  │     → list(KDE_surface, colony, tracks)    ← fast (~seconds)
  │
  └── compute_representative_assessment(KDE_surface, tracks, levelUD, n_iterations)
        → data.frame (full iteration results)  ← expensive (~minutes)
        → repAssess plot suppressed via null device
        → bootTable = TRUE retains per-iteration data for plot reconstruction
        → pure compute, no side effects

write_*_rds(list(KDE_surface, colony, tracks, assessment), rds_path)  → .rds
```

### Consumers of the .rds cache

| Function | Input | Output | Notes |
|----------|-------|--------|-------|
| `render_representative_assessment(rds_path, output_path)` | .rds path | PNG | Reconstructs repAssess scatterplot from cached iteration data |
| `render_potential_kba(rds_path, popSize, output_path)` | .rds path | PNG | Reads KDE_surface + repr$out from cache, runs findSite, maps |
| `export_potential_kba(rds_path, popSize, gpkg_path)` | .rds path | .gpkg | Reads KDE_surface + repr$out from cache, runs findSite |

### Unchanged pipeline

`render_individual_kde(data_path, config_path, levelUD, smoothing_method, output_path)`
— no caching benefit (KDE computation is fast), stays monolithic.

### New functions to create

| Function | Role |
|----------|------|
| `compute_space_use` | Standalone: projectTracks + tripSummary + get_scale_parameters + estSpaceUse. Returns `list(KDE_surface, UDPolygons, tracks)`. |
| `compute_representative_assessment` | Standalone (extracted from R6 method): calls repAssess with bootTable=TRUE + null device. Returns full iteration data.frame. |
| `create_cache` | Composes `compute_space_use` + `compute_representative_assessment`, writes `.rds`. Takes `rds_path` as last arg. |
| `export_potential_kba` | Reads `.rds`, runs `findSite`, writes `.gpkg`. |
| `plot_representative_assessment` | In-memory visualization, called by the render function. |
| `plot_potential_kba` | In-memory visualization, called by the render function. |
| `plot_individual_kde` | In-memory visualization, called by the render function. |

### Key design decisions

1. **track2kba is NOT modified** — local clone at `track2kba/` is read-only reference. repAssess plot suppressed by wrapping call in `png(tempfile())` + `dev.off()`.
2. **No optional arguments** — every parameter is mandatory. No `--artifact-path` in `get_domain_specific_options()`.
3. **Backwards compatibility is not a concern** — downstream `bycatch_thesis` will be updated separately.
4. **The `.rds` stores everything downstream needs**: KDE_surface raster, colony tibble, tracks SpatialPointsDataFrame, and full assessment data.frame.

---

## Downstream Impact (for `bycatch_thesis`)

The following `bycatch_thesis/Makefile` targets and function calls
will break after Phase 1 and must be updated (not part of this plan):

| Current call | After Phase 1 | Affected Makefile target(s) |
|---|---|---|
| `bycatch::plot_potential_site(...)` | `bycatch::render_potential_kba(...)` | `gps_albatross_50_percent_potential_site_ars_*.png` |
| `bycatch::plot_representative_assess(...)` | `bycatch::render_representative_assessment(...)` | `gps_albatross_50_percent_representative_assess_ars_*.png` |
| `bycatch::plot_individual_kernels(...)` | `bycatch::render_individual_kde(...)` | `gps_albatross_50_percent_individuals_kernel_ars_*.png` |

After Phase 2, the `render_*` function signatures will change further
(they will accept `--artifact-path` instead of `--data-path` and
`--config-path`). This will require additional updates in
`bycatch_thesis/Makefile` at that time.
