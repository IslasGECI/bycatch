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
artifact_path <- geci.optparse::character_option(
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
