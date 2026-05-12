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
export_*            compute + write interoperable format (.gpkg, .csv)
plot_*              in-memory visualization (no disk I/O)
render_*            read artifact + plot_* + write PNG
create_*            compute_* + export_* (one-step convenience)
```

### Pipelines to restructure

| Pipeline | New `compute_*` | New `export_*` | New `plot_*` | Existing `render_*` |
|----------|----------------|----------------|-------------|-------------------|
| Representativity | `compute_representative_assessment` | `write_representative_assessment` (.rds) | `plot_representative_assessment` | `render_representative_assessment` |
| KBA | — (uses `compute_representative_assessment` output) | `export_potential_kba` (.gpkg) | `plot_potential_kba` | `render_potential_kba` |
| Individual KDE | `estimate_space_use` (already done) | `export_individual_kde` (.gpkg) | `plot_individual_kde` | `render_individual_kde` |

### New functions to create

| Function | Role |
|----------|------|
| `create_representative_assessment` | `compute_representative_assessment` + `write_representative_assessment` (`.rds`) |
| `export_potential_kba` | Calls `compute_potential_kba` + writes `.gpkg` |
| `export_individual_kde` | Calls `estimate_space_use` + writes `.gpkg` |
| `plot_representative_assessment` | In-memory visualization of `.rds` |
| `plot_potential_kba` | In-memory visualization of GeoPackage |
| `plot_individual_kde` | In-memory visualization of GeoPackage |

### Infrastructure

- Add `--artifact-path` CLI option to `get_domain_specific_options()` so
  `render_*` functions can read pre-computed artifacts (`.gpkg` or `.rds`).
- Shared RDS caching: `compute_representative_assessment` writes an `.rds`
  once per dataset; both `render_representative_assessment` and
  `render_potential_kba` can reuse it, avoiding duplicate bootstrapping.
- After Phase 2, `render_*` functions no longer accept `--data-path` or
  `--config-path` — they read artifacts instead of raw data.

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
