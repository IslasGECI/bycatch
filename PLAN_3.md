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
representative_assess_path <- geci.optparse::character_option(
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
