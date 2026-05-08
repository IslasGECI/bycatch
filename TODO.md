# Implementation Plan: Restructuring Figure Naming Schema

This plan outlines the steps required to transition the existing figure file naming convention to a more descriptive, consistent, and logic-based schema.

## 1. Objectives
- Improve clarity of generated figure filenames.
- Align filenames with their ecological and analytical intent.
- Standardize the mapping between `track2KBA` functions, `bycatch_code` wrappers, and output filenames.

## 2. Architecture: Write / Render Separation

Each figure is produced by **three steps**:

1. **Compute** — `compute_*()` functions perform calculations in memory and return a result (no disk I/O).
2. **Export** — `export_*()` functions compute + write to disk in interoperable formats (`.gpkg`, `.csv`). These are Make build targets.
3. **Render** — `render_*()` functions read pre-computed artifacts, produce a visualization (`plot_*()`), and write PNG. Render tools are swappable (bycatch, GMT, QGIS, Python, etc.).

The style guide defines these as:
- **`compute_*()`**: in-memory calculation, no side effects. Example: `compute_area()`
- **`export_*()`**: writes from memory to disk in interoperable formats. Example: `export_area_to_gpkg()`
- **`create_*()`**: performs `compute_*()` + `export_*()`. Example: `create_area()`
- **`plot_*()`**: produces a visualization in memory (no disk I/O). Example: `plot_area()`
- **`render_*()`**: reads from disk + calls `plot_*()` + writes PNG. Example: `render_area()`

### Artifacts (export step output)

| Artifact | Producing function | Format | Consumers |
|----------|-------------------|--------|-----------|
| `representative_assess_[scope].rds` | `create_representative_assessment` | RDS | `plot_representative_assessment` |
| `usage_observed_[scope].gpkg` | `export_usage_observed` | GeoPackage | `render_usage_observed`, GMT, QGIS |
| `potential_kba_[scope].gpkg` | `export_potential_kba` | GeoPackage | `render_potential_kba`, GMT, QGIS |
| `individual_space_use_[scope].gpkg` | `export_individual_space_use` | GeoPackage | `render_individual_space_use`, GMT, QGIS |
| `trips_[scope].csv` | `write_trips` | CSV | — |
| `trips_summary_[scope].csv` | `write_trips_summary` | CSV | — |

### Figure targets (render step output)

| Figure | Export step | Render step | Output |
|--------|-----------|-------------|--------|
| `representative_assessment_[scope].png` | `create_representative_assessment` | `render_representative_assessment` | PNG |
| `usage_observed_[scope].png` | `export_usage_observed` | `render_usage_observed` | PNG |
| `potential_kba_[scope].png` | `export_potential_kba` | `render_potential_kba` | PNG |
| `individual_space_use_[scope].png` | `export_individual_space_use` | `render_individual_space_use` | PNG |

## 3. Function Naming Convention

Following the style guide:
- Verb + object: `compute_area()`, `export_to_gpkg()`, `render_map()`
- `get_*` only if complementary `set_*` exists
- `compute_*()`: no disk I/O, in-memory only
- `export_*()`: writes interoperable formats (`.gpkg`, `.csv`) to disk
- `create_*()`: performs `compute_*()` + `export_*()`
- `plot_*()`: in-memory visualization, no disk I/O
- `render_*()`: reads artifact + calls `plot_*()` + writes PNG

| Current name | New name | Role | File |
|---|---|---|---|
| `calculate_kde` | `estimate_space_use` | Compute | `R/representative_assess.R` |
| `get_representative_assess` | `compute_representative_assessment` | Compute | `R/representative_assess.R` |
| `get_site` | `compute_usage_observed` | Compute | `R/representative_assess.R` |
| `get_potential_site` | `compute_potential_kba` | Compute | `R/representative_assess.R` |
| `get_tracks` | *(internal, no rename)* | — | `R/representative_assess.R` |
| `get_scale_dictionary` | *(internal, no rename)* | — | `R/representative_assess.R` |
| `get_summary_of_trips` | *(internal, no rename)* | — | `R/track_example.R` |
| `get_trips` | *(internal, no rename)* | — | `R/track_example.R` |
| `get_kernels` | *(internal, no rename)* | — | `R/get_kernels.R` |
| `plot_usage_area_by_individual` | `render_usage_observed` | Render | `R/cli.R` |
| `plot_representative_assess` | `render_representative_assessment` | Render | `R/cli.R` |
| `plot_potential_site` | `render_potential_kba` | Render | `R/cli.R` |
| `plot_individual_kernels` | `render_individual_space_use` | Render | `R/cli.R` |
| `write_trips` | *(no rename — already clear)* | Write | `R/cli.R` |
| `write_trips_summary` | *(no rename — already clear)* | Write | `R/cli.R` |
| `process_fisheries_data` | *(no rename — fisheries pipeline)* | — | `R/cli.R` |
| `filter_data_between_dates` | *(no rename — utility)* | — | `R/cli.R` |

New functions to create:

| New name | Role | File |
|---|---|---|
| `create_representative_assessment` | compute + write `.rds` | `R/cli.R` |
| `export_usage_observed` | compute + write `.gpkg` | `R/cli.R` |
| `export_potential_kba` | compute + write `.gpkg` | `R/cli.R` |
| `export_individual_space_use` | compute + write `.gpkg` | `R/cli.R` |
| `plot_usage_observed` | in-memory visualization | `R/cli.R` |
| `plot_potential_kba` | in-memory visualization | `R/cli.R` |
| `plot_representative_assessment` | in-memory visualization | `R/cli.R` |
| `plot_individual_space_use` | in-memory visualization | `R/cli.R` |

## 4. Output Schema

### Artifacts (compute + export)

| Artifact | Function | Makefile target |
|---|---|---|
| `representative_assessment_[scope].rds` | `create_representative_assessment` | `rds_representative_assessment_[scope]` |
| `usage_observed_[scope].gpkg` | `export_usage_observed` | `gpkg_usage_observed_[scope]` |
| `potential_kba_[scope].gpkg` | `export_potential_kba` | `gpkg_potential_kba_[scope]` |
| `individual_space_use_[scope].gpkg` | `export_individual_space_use` | `gpkg_individual_space_use_[scope]` |

### Figures (render from artifact)

| Figure | Render function | Makefile variable |
|---|---|---|
| `individual_space_use_[scope].png` | `render_individual_space_use` | `png_individual_space_use_[scope]` |
| `representative_assessment_[scope].png` | `render_representative_assessment` | `png_representative_assessment_[scope]` |
| `usage_observed_[scope].png` | `render_usage_observed` | `png_usage_observed_[scope]` |
| `potential_kba_[scope].png` | `render_potential_kba` | `png_potential_kba_[scope]` |

### File naming convention

- Script files: verb prefix + snake_case (e.g. `export_usage_observed.R`, `render_potential_kba.R`)
- Makefile variables: `format_type_species_region` (e.g. `gpkg_usage_observed_guadalupe`)
- Phony targets: noun or adjective (e.g. `results_first_paper`)

The program name matches the Makefile variable name (format omitted to avoid redundancy). For example, the program called by `png_usage_observed_guadalupe` is `render_usage_observed_guadalupe`.

## 5. Implementation Steps

### Step A: Rename wrapper methods (`R/representative_assess.R`)

| Current | New | Rule |
|---|---|---|
| `calculate_kde` | `estimate_space_use` | Verb-object |
| `get_representative_assess` | `compute_representative_assessment` | get_* → compute_* |
| `get_site` | `compute_usage_observed` | get_* → compute_* |
| `get_potential_site` | `compute_potential_kba` | get_* → compute_* |

All four remain private methods of the R6 class. Update internal calls within the class.

### Step B: Create new files (verb-prefixed script names)

Each new file follows the style guide: starts with verb, snake_case, no abbreviations.

| New file | Function inside | Role |
|---|---|---|
| `export_usage_observed.R` | `export_usage_observed()` | Calls `compute_usage_observed()` + writes `.gpkg` |
| `export_potential_kba.R` | `export_potential_kba()` | Calls `compute_potential_kba()` + writes `.gpkg` |
| `export_individual_space_use.R` | `export_individual_space_use()` | Calls `estimate_space_use()` + writes `.gpkg` |
| `create_representative_assessment.R` | `create_representative_assessment()` | Calls `compute_representative_assessment()` + writes `.rds` |

Internal helpers to create:

| File | Function | Role |
|---|---|---|
| `R/plot_usage_observed.R` | `plot_usage_observed()` | In-memory visualization of GeoPackage |
| `R/plot_potential_kba.R` | `plot_potential_kba()` | In-memory visualization of GeoPackage |
| `R/plot_representative_assessment.R` | `plot_representative_assessment()` | In-memory visualization of `.rds` |
| `R/plot_individual_space_use.R` | `plot_individual_space_use()` | In-memory visualization of GeoPackage |

### Step C: Rename CLI render functions (`R/cli.R`)

| Current | New | Rule |
|---|---|---|
| `plot_usage_area_by_individual` | `render_usage_observed` | plot_* → render_* (reads artifact + writes PNG) |
| `plot_representative_assess` | `render_representative_assessment` | plot_* → render_* |
| `plot_potential_site` | `render_potential_kba` | plot_* → render_* |
| `plot_individual_kernels` | `render_individual_space_use` | plot_* → render_* |

Each `render_*()` function:
1. Reads the pre-computed artifact (`.gpkg` or `.rds`)
2. Calls the corresponding `plot_*()` function
3. Writes PNG to disk

### Step D: Add `--artifact-path` option

Add `--artifact-path` to `get_domain_specific_options()` so render functions can read pre-computed artifacts:

```r
artifact_path <- gecioptparse::character_option(
  c("", "--artifact-path"),
  default = NULL,
  help = "Path to pre-computed artifact (.gpkg or .rds) to render"
)
```

### Step E: Update `NAMESPACE`

Export all new functions:
```
export(export_usage_observed)
export(export_potential_kba)
export(export_individual_space_use)
export(create_representative_assessment)
export(render_usage_observed)
export(render_potential_kba)
export(render_individual_space_use)
export(render_representative_assessment)
export(plot_usage_observed)
export(plot_potential_kba)
export(plot_representative_assessment)
export(plot_individual_space_use)
```

### Step F: Update Makefile

1. Add Makefile variables for artifact targets (format_type_species_region):
   ```makefile
   rds_representative_assessment_guadalupe = data/processed/representative_assessment_guadalupe.rds
   gpkg_usage_observed_guadalupe = data/processed/usage_observed_guadalupe.gpkg
   gpkg_potential_kba_guadalupe = data/processed/potential_kba_guadalupe.gpkg
   ```

2. Add two-step targets for each figure:
   ```makefile
   $(gpkg_usage_observed_guadalupe): ...
       Rscript -e "bycatch::export_usage_observed(...)"

   png_usage_observed_guadalupe = reports/figures/usage_observed_guadalupe.png
   $(png_usage_observed_guadalupe): $(gpkg_usage_observed_guadalupe)
       Rscript -e "bycatch::render_usage_observed(...)"
   ```

3. Program name matches the Makefile variable name (per style guide):
   - `png_usage_observed_guadalupe` → script: `render_usage_observed`
   - `gpkg_usage_observed_guadalupe` → script: `export_usage_observed`

### Step G: Validation

1. Update tests (`test_representative_assess.R`, `test_cli.R`) to use new function names.
2. Run `make clean` then `make results_first_paper` — verify all figures build.
3. Swap a render step for a GMT command to verify tool independence.
# Plan: Extract common computation into shared RDS artifact

## Goal

Refactor `bycatch` and the thesis `Makefile` so that the expensive `repAssess()` computation runs **once per dataset** instead of three times (once per figure target). The intermediate result is cached as an `.rds` file.

## Current state

### Pipeline chain (per `Rscript` invocation)

```
read_config()
readr::read_csv()
Track2KBA_Wrapper$new()
  ├─ subset complete_trips
  ├─ get_tracks()             projectTracks()
  ├─ get_scale_dictionary()  tripSummary() + findScale()
  ├─ calculate_kde()          estSpaceUse()           ← expensive I/O
  └─ get_representative_assess()  repAssess()          ← expensive computation (bootstrapping)
      ├─ get_site()           findSite(polyOut=FALSE)
      └─ get_potential_site() findSite(polyOut=TRUE)
```

### Makefile duplication for guadalupe (as example)

| Makefile target | `repAssess()` runs? |
|---|---|
| `usage_area_guadalupe` | Yes (inside Rscript) |
| `potential_site_guadalupe` | Yes (inside Rscript) |
| `representative_assess_guadalupe` | Yes (inside Rscript) |

Each invocation independently executes the entire chain from scratch. No intermediate artifacts.

## Proposed structure

### 1. New R function in `R/cli.R`

**Name:** `compute_representative_assess()`
**Location:** new file `R/compute_representative_assess.R`
**Exported:** yes (add to NAMESPACE)

```r
compute_representative_assess <- function(options) {
  config_content <- read_config(options[["config-path"]])
  trips_data <- readr::read_csv(options[["data-path"]], show_col_types = FALSE)
  percentage_distribution <- options[["percentage-distribution"]]
  n_iterations <- options[["n-iterations"]]
  smoothing_method <- options[["smoothing-method"]]

  wrapper <- Track2KBA_Wrapper$new(trips_data, config_content, percentage_distribution, smoothing_method)
  repr <- wrapper$get_representative_assess(percentage_distribution, n_iterations)

  saveRDS(repr, options[["output-path"]])
}
```

### 2. Refactor `plot_usage_area_by_individual()` in `R/cli.R`

Accept optional `representative_assess` argument. If `NULL`, compute it (backwards-compatible). If provided, skip computation.

```r
plot_usage_area_by_individual <- function(options, representative_assess = NULL) {
  # ... same setup ...
  if (is.null(representative_assess)) {
    representative_assess <- wrapper$get_representative_assess(percentage_distribution, n_iterations)
  }
  site <- wrapper$get_site(representative_assess, percentage_distribution)
  # ... rest unchanged ...
}
```

### 3. Refactor `plot_potential_site()` in `R/cli.R`

Same pattern: accept optional `representative_assess` argument.

```r
plot_potential_site <- function(options, representative_assess = NULL) {
  # ... same setup ...
  if (is.null(representative_assess)) {
    representative_assess <- wrapper$get_representative_assess(percentage_distribution, n_iterations)
  }
  site <- wrapper$get_potential_site(representative_assess, percentage_distribution,
                                    population_size = options[["population-size"]])
  # ... rest unchanged ...
}
```

### 4. Update `NAMESPACE`

Add export for the new function:
```
export(compute_representative_assess)
```

### 5. Update thesis `Makefile`

Add new `.rds` artifact targets and update dependencies.

#### 5a. Add `--representative-assess-path` option

In `R/get_domain_specific_options.R`, add a new CLI option:

```r
representative_assess_path <- gecioptparse::character_option(
  c("", "--representative-assess-path"),
  default = NULL,
  help = "Path to pre-computed representative assessment RDS file (optional)"
)
```

Then in `plot_usage_area_by_individual()` and `plot_potential_site()`:

```r
if (!is.null(options[["representative-assess-path"]])) {
  representative_assess <- readRDS(options[["representative-assess-path"]])
} else {
  representative_assess <- wrapper$get_representative_assess(...)
}
```

#### 5b. Add representative assess RDS targets

```makefile
# Guadalupe
data/processed/representative_assess_guadalupe.rds: \
	data/processed/trips_geographic_points_guadalupe.csv \
	config_trips_guadalupe.json
	$(checkDirectories)
	Rscript -e "bycatch::compute_representative_assess(bycatch::get_domain_specific_options())" \
		--data-path data/processed/trips_geographic_points_guadalupe.csv \
		--config-path config_trips_guadalupe.json \
		--percentage-distribution 50 \
		--smoothing-method scale_ARS \
		--n-iterations 314 \
		--output-path $@

# All
data/processed/representative_assess_all.rds: \
	data/processed/trips_geographic_points_all.csv \
	config_trips_all.json
	$(checkDirectories)
	Rscript -e "bycatch::compute_representative_assess(bycatch::get_domain_specific_options())" \
		--data-path data/processed/trips_geographic_points_all.csv \
		--config-path config_trips_all.json \
		--percentage-distribution 50 \
		--smoothing-method scale_ARS \
		--n-iterations 314 \
		--output-path $@
```

#### 5c. Update existing figure targets to depend on RDS

```makefile
reports/figures/gps_albatross_50_percent_usage_area_ars_guadalupe.png: \
	data/processed/representative_assess_guadalupe.rds \
	data/processed/trips_geographic_points_guadalupe.csv \
	config_trips_guadalupe.json
	$(checkDirectories)
	Rscript -e "bycatch::plot_usage_area_by_individual(bycatch::get_domain_specific_options())" \
		--data-path data/processed/trips_geographic_points_guadalupe.csv \
		--config-path config_trips_guadalupe.json \
		--percentage-distribution 50 \
		--smoothing-method scale_ARS \
		--n-iterations 314 \
		--representative-assess-path data/processed/representative_assess_guadalupe.rds \
		--output-path $@

reports/figures/gps_albatross_50_percent_potential_site_ars_guadalupe.png: \
	data/processed/representative_assess_guadalupe.rds \
	data/processed/trips_geographic_points_guadalupe.csv \
	config_trips_guadalupe.json
	$(checkDirectories)
	Rscript -e "bycatch::plot_potential_site(bycatch::get_domain_specific_options())" \
		--data-path data/processed/trips_geographic_points_guadalupe.csv \
		--config-path config_trips_guadalupe.json \
		--percentage-distribution 50 \
		--n-iterations 314 \
		--population-size 4390 \
		--smoothing-method scale_ARS \
		--representative-assess-path data/processed/representative_assess_guadalupe.rds \
		--output-path $@
```

Do the same for the `_all` variants (with `--representative-assess-path data/processed/representative_assess_all.rds`).

#### 5d. Update result phony targets

```makefile
results_first_paper: \
	data/processed/representative_assess_guadalupe.rds \
	# ... existing deps ...

results_second_paper: \
	data/processed/representative_assess_all.rds \
	# ... existing deps ...
```

## Implementation order

1. **Add `--representative-assess-path` option** to `R/get_domain_specific_options.R`
2. **Create `R/compute_representative_assess.R`** with new exported function
3. **Refactor `plot_usage_area_by_individual()`** to accept optional pre-computed `representative_assess`
4. **Refactor `plot_potential_site()`** similarly
5. **Update `NAMESPACE`** to export `compute_representative_assess`
6. **Add RDS targets to Makefile** (guadalupe, all)
7. **Update figure targets** to depend on RDS and pass `--representative-assess-path`
8. **Update result phony targets** to include RDS dependencies
9. **Test:** Run `make clean` then `make results_first_paper` and verify all figures build correctly

## Impact summary

| Dataset | Before: `repAssess()` calls | After: `repAssess()` calls |
|---------|---------------------------|---------------------------|
| guadalupe | 3 | 1 |
| all | 3 | 1 |

Total: from 6 calls to 2 calls. Build time should drop significantly since `repAssess()` with 314 iterations is the dominant cost.

---

# Plan: Two-Step Write / Render Architecture

## Goal

Separate the **data processing** step (bycatch) from the **rendering** step (any tool). bycatch writes standardized artifacts (GeoPackages, CSVs). Any tool can render those artifacts (bycatch, GMT, QGIS, Python, etc.).

## Why

### 1. Tool-agnostic rendering
The write step produces standard open formats — GeoPackages, CSVs, RDS. The render step is just a consumer of those formats. You could render the same GeoPackage with:
- `bycatch::mapSite()` (R + track2KBA)
- GMT (`psxy`, `pspcolor`)
- QGIS
- Python + matplotlib/geopandas
- Any future tool

### 2. bycatch becomes a data pipeline, not a plotting library
`bycatch` owns **how you compute** things (KDE, repAssess, sites). It does **not** own **how you visualize** them.

### 3. Independent evolution
The write layer and the render layer evolve independently. You can update rendering without touching data processing and vice versa.

### 4. Debugging and iteration
If a figure looks wrong, you inspect the GeoPackage directly — no need to re-run expensive computations.

## What changes

Each Makefile target is split into two steps:

```
artifact.gpkg:          ← WRITE step (bycatch)
	Rscript -e "bycatch::write_*()"

artifact.png: artifact.gpkg  ← RENDER step (any tool)
	gmt psxy artifact.gpkg ...
```

### Artifacts produced by bycatch

| Artifact | Source function | Format |
|----------|----------------|--------|
| `representative_assess_[scope].rds` | `compute_representative_assess()` | RDS |
| `usage_area_[scope].gpkg` | `get_site()` (findSite polyOut=FALSE) | GeoPackage (grid cells) |
| `potential_site_[scope].gpkg` | `get_potential_site()` (findSite polyOut=TRUE) | GeoPackage (polygons) |
| `individual_kernel_[scope].gpkg` | `get_representative_assess()` / KDE | GeoPackage (polygons) |
| `trips_summary_[scope].csv` | Already exists via `write_trips_summary()` | CSV |

### New R functions for write step

Each `plot_*` function gets a corresponding `write_*` function:

```r
# New file R/write_usage_area.R
write_usage_area <- function(options) {
  # ... setup (same as plot_usage_area_by_individual) ...
  site <- wrapper$get_site(representative_assess, percentage_distribution)
  # Convert SpatialPixelsDataFrame to sf and write
  sf::st_write(site, options[["output-path"]], delete_layer = TRUE)
}

# New file R/write_potential_site.R
write_potential_site <- function(options) {
  # ... setup ...
  site <- wrapper$get_potential_site(representative_assess, percentage_distribution,
                                      population_size = options[["population-size"]])
  sf::st_write(site, options[["output-path"]], delete_layer = TRUE)
}
```

### Makefile structure

```makefile
# WRITE step: bycatch produces GeoPackage
data/processed/usage_area_guadalupe.gpkg: \
	data/processed/representative_assess_guadalupe.rds \
	data/processed/trips_geographic_points_guadalupe.csv \
	config_trips_guadalupe.json
	$(checkDirectories)
	Rscript -e "bycatch::write_usage_area(bycatch::get_domain_specific_options())" \
		--data-path data/processed/trips_geographic_points_guadalupe.csv \
		--config-path config_trips_guadalupe.json \
		--percentage-distribution 50 \
		--smoothing-method scale_ARS \
		--n-iterations 314 \
		--representative-assess-path data/processed/representative_assess_guadalupe.rds \
		--output-path $@

# RENDER step: bycatch renders PNG (or swap for GMT later)
reports/figures/gps_albatross_50_percent_usage_area_ars_guadalupe.png: \
	data/processed/usage_area_guadalupe.gpkg
	$(checkDirectories)
	Rscript -e "bycatch::render_usage_area(bycatch::get_domain_specific_options())" \
		--data-path data/processed/usage_area_guadalupe.gpkg \
		--output-path $@
```

### Separation of concerns

```
bycatch_code              bycatch_thesis
─────────────────────     ─────────────────────────────
compute_representative_assess()    WRITE → .rds, .gpkg
write_usage_area()                 WRITE → .gpkg
write_potential_site()             WRITE → .gpkg
render_usage_area()       RENDER ← reads .gpkg
render_potential_site()    RENDER ← reads .gpkg
plot_representative_assess()       RENDER ← reads .rds

GMT / QGIS / Python       RENDER ← reads .gpkg (no bycatch needed)
```

bycatch_code owns:
- All `compute_*` functions (expensive computation)
- All `write_*` functions (produces artifacts)
- Optional `render_*` / `plot_*` functions (bycatch rendering)

bycatch_thesis owns:
- Which render tool to use (bycatch, GMT, QGIS, etc.)
- Figure styling and layout

## Implementation order (Phase 2)

1. **Create `R/write_usage_area.R`** — writes `get_site()` output to GeoPackage
2. **Create `R/write_potential_site.R`** — writes `get_potential_site()` output to GeoPackage
3. **Refactor `plot_usage_area_by_individual()`** → becomes `render_usage_area()` reading from GeoPackage
4. **Refactor `plot_potential_site()`** → becomes `render_potential_site()` reading from GeoPackage
5. **Add write targets to Makefile** (guadalupe, clarion, all for usage_area and potential_site)
6. **Update figure targets** to depend on GeoPackages and use render functions
7. **Test:** Build figures with bycatch, then swap a render step for a GMT command to verify tool independence

## Open questions

1. Should `results_clarion` also get an RDS? It only generates `individuals_kernel` (which doesn't call `repAssess()`) — so no benefit, but for consistency it's optional.
2. Do you want to also cache `Track2KBA_Wrapper$new()` result (which includes KDE)? That would save even more time but requires bigger refactor. The RDS would be larger and contain `SpatialPixelsDataFrame` objects.
3. What render tools do you want to support first — GMT, QGIS, Python? This affects how the GeoPackage schema should be structured (column names, geometry types, etc.).
