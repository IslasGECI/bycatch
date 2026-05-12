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

## Phase 1 — Rename (3 commits)

Each commit renames one pipeline end to end: the R6 wrapper method,
the exported CLI function, and the corresponding test. The full test
suite must pass after every commit. No changes to `bycatch_thesis`.

### Commit 1: Rename potential_site to potential_kba

**What changes**

| File | Symbol | Change |
|------|--------|--------|
| `R/cli.R` | `plot_potential_site` | Rename to `render_potential_kba`. Add roxygen2 block with `@export`. |
| `R/representative_assess.R` | `get_potential_site` | Rename to `compute_potential_kba`. |
| `tests/testthat/test_cli.R` | Test block "plot potential site" | Rename describe/it strings. Update call from `plot_potential_site(options)` to `render_potential_kba(options)`. Update output path from `potential_site.png` to `kba.png`. |

**Test suite status**: passes (internal call to `get_representative_assess` unchanged).

**Downstream breakage** (for `bycatch_thesis`, not fixed here):
- Target `reports/figures/gps_albatross_50_percent_potential_site_ars_guadalupe.png`
  calls `bycatch::plot_potential_site()` → must become `bycatch::render_potential_kba()`.
- Same for the `_all` variant.

---

### Commit 2: Rename representative_assess to representative_assessment

**What changes**

| File | Symbol | Change |
|------|--------|--------|
| `R/cli.R` | `plot_representative_assess` | Rename to `render_representative_assessment`. Update roxygen2 `@export`. |
| `R/cli.R` | `render_potential_kba` body | Update internal call from `wrapper$get_representative_assess(...)` to `wrapper$compute_representative_assessment(...)`. |
| `R/representative_assess.R` | `get_representative_assess` | Rename to `compute_representative_assessment`. |
| `tests/testthat/test_cli.R` | Test block "plot representative assess" | Rename describe/it strings. Update call to `render_representative_assessment(options)`. |
| `tests/testthat/test_representative_assess.R` | `obtained$get_representative_assess` | Update to `obtained$compute_representative_assessment`. |

**Test suite status**: passes. `render_potential_kba` (Commit 1) and `render_representative_assessment` both call the renamed method.

**Downstream breakage** (for `bycatch_thesis`, not fixed here):
- Target `reports/figures/gps_albatross_50_percent_representative_assess_ars_guadalupe.png`
  calls `bycatch::plot_representative_assess()` → must become `bycatch::render_representative_assessment()`.
- Same for `_all` variant.

---

### Commit 3: Rename individuals_kernel to individual_kde

**What changes**

| File | Symbol | Change |
|------|--------|--------|
| `R/cli.R` | `plot_individual_kernels` | Rename to `render_individual_kde`. Update roxygen2 `@export`. |
| `R/representative_assess.R` | `calculate_kde` | Rename to `estimate_space_use`. |
| `R/representative_assess.R` | `initialize` body | Update `self$calculate_kde(...)` to `self$estimate_space_use(...)`. |
| `tests/testthat/test_cli.R` | Test block "plot map of individuals KDE" | Rename describe/it strings. Update call to `render_individual_kde(options)`. |
| `tests/testthat/test_representative_assess.R` | `obtained$calculate_kde` | Update to `obtained$estimate_space_use`. |

**Test suite status**: passes. All three CLI functions create a `Track2KBA_Wrapper` via `$new()`, which calls `initialize` — now pointing at `estimate_space_use`.

**Downstream breakage** (for `bycatch_thesis`, not fixed here):
- Targets `reports/figures/gps_albatross_50_percent_individuals_kernel_ars_guadalupe.png`,
  `_clarion.png`, and `_all.png` call `bycatch::plot_individual_kernels()`
  → must become `bycatch::render_individual_kde()`.

---

## Phase 2 — Write / Render Separation (future)

After all renames are done, the current CLI functions still mix
computation and rendering in a single step. Phase 2 splits each
pipeline into three independent layers:

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
