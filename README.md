<a href="https://www.islas.org.mx"><img src="https://www.islas.org.mx/img/logo.svg" align="right" width="256" /></a>

# bycatch — seabird bycatch risk assessment
[![codecov](https://codecov.io/gh/IslasGECI/bycatch/graph/badge.svg?token=wyxnwZypMA)](https://codecov.io/gh/IslasGECI/bycatch)
![example branch
parameter](https://github.com/IslasGECI/bycatch/actions/workflows/actions.yml/badge.svg)
![licencia](https://img.shields.io/github/license/IslasGECI/bycatch)
![languages](https://img.shields.io/github/languages/top/IslasGECI/bycatch)
![commits](https://img.shields.io/github/commit-activity/y/IslasGECI/bycatch)
![R-version](https://img.shields.io/github/r-package/v/IslasGECI/bycatch)

**Assess where seabirds forage, where fishing vessels operate, and where they overlap — to prevent bycatch.**

bycatch ingests GPS tracking data from seabird colonies, computes their foraging
areas and key biodiversity areas (KBAs), and compares those areas against fishing
vessel GPS data to identify overlap hotspots.

## How it works

| Step | What happens | Status |
| :--- | :--- | :--- |
| 1. Load GPS tracks | Import raw seabird and fishing vessel positions. | Ready |
| 2. Split into trips | Separate continuous GPS streams into individual foraging trips. | Ready |
| 3. Estimate space use | Compute kernel density estimates (KDE) for each individual. | Ready |
| 4. Assess representativity | Bootstrap to determine how many individuals are needed to represent the population. | Ready |
| 5. Identify KBA candidates | Find areas used by a significant proportion of the local population. | Ready |
| 6. Overlap with fisheries | Compare seabird areas against fishing fleet GPS data. | Ready |
| 7. Visualise results | Output static figures (PNG), vector data (GeoPackage), and summary tables (CSV). | Ready |

## Before you start

You need:
- **GPS tracking data** from seabirds (CSV with longitude, latitude, date, time, and individual ID).
- **Colony location** and configuration (lon/lat, buffer distances, trip duration).
- Optionally: **fishing vessel GPS data** for overlap analysis.

All data paths in the package follow Docker conventions (`/workdir/...`). Run inside the
provided Docker container to avoid path configuration.

## Run the project

```shell
# Inside the Docker container:

# Export a filtered dataset
Rscript -e "bycatch::create_filtered_gps_between_dates(bycatch::get_domain_specific_options())" \
  --data-path /workdir/data/gps.csv \
  --output-path /workdir/data/gps_filtered.csv \
  --start 2024-01-01 --end 2024-12-31 \
  --date-column-name DateTime

# Export trip summaries
Rscript -e "bycatch::create_trips_summary(bycatch::get_domain_specific_options())" \
  --data-path /workdir/data/trips.csv \
  --config-path /workdir/config.json \
  --output-path /workdir/output/trips_summary.csv

# Render a KBA map from GPS data and configuration
Rscript -e "bycatch::render_potential_kba(bycatch::get_domain_specific_options())" \
  --data-path /workdir/data/trips.csv \
  --config-path /workdir/config.json \
  --output-path /workdir/output/kba.png

(Coming soon: cache-based pipeline where the expensive bootstrap runs once.)
```

## Core concept

If you provide seabird GPS tracks and a colony location, bycatch will:

1. Split the tracks into individual foraging trips.
2. Calculate the area each bird uses (kernel density).
3. Bootstrap across individuals to check if your sample is large enough.
4. Identify potential key biodiversity areas (KBAs).
5. Optionally overlap these areas with fishing vessel data.
6. Save the results as PNG figures, CSV tables, and GeoPackage vector files.

Results can also be fed into GIS tools (QGIS, GMT) for custom cartography.

## Coming soon

- **`create_processed_data()`** — one-step compute-and-cache command that runs the
  expensive bootstrap once and saves results for all figure pipelines.
- **`create_potential_kba()`** — GeoPackage export for KBA polygons (combines
  cached bootstrap results with fast-recomputed kernel densities).
- **`create_representative_assessment()`** — Tabular Data Package export (CSV +
  `datapackage.json` schema) of the full bootstrap iteration results.
- **Shared RDS caching** — the expensive `repAssess` bootstrap runs once per
  dataset; all downstream figures and exports read cached results.

## What's new (v0.9.0-dev)

- **Plot layer** — three new internal `plot_*` functions provide ggplot2-based
  visualizations: `plot_representative_assessment()` (scatterplot),
  `plot_potential_kba()` (sf map), `plot_individual_kde()` (sf map). These are
  Level 1 Pure functions (no I/O, no side effects) and are not exported.
  `render_*` functions (Sprint 5) will use them instead of `track2KBA` base-R
  plots.

