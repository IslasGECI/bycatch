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

bycatch converts GPS tracking data from seabird colonies into maps of foraging
areas, identifies potential key biodiversity areas (KBAs), and overlays them
with fishing vessel GPS data to pinpoint high-risk overlap zones.

## What you need

- **Seabird GPS data** (CSV with dates, positions, and individual IDs).
- **Colony location** and configuration (coordinates, buffer distances, trip duration).
- **Fishing vessel GPS data** (optional, for overlap analysis).

Run inside the provided Docker container — all paths use `/workdir/...`.

## Quick start

```shell
# Inside the Docker container:

# 1. Cache the expensive bootstrap (runs repAssess once, enables fast downstream steps)
Rscript -e "bycatch::create_processed_data(bycatch::get_domain_specific_options())" \
  --config-path /workdir/config.json \
  --data-path /workdir/data/trips.csv \
  --output-path /workdir/output/cache.rds \
  --percentage-distribution 50 \
  --smoothing-method log_median \
  --n-iterations 100

# 2. Generate a KBA map from the cached results
Rscript -e "bycatch::render_potential_kba(bycatch::get_domain_specific_options())" \
  --config-path /workdir/config.json \
  --data-path /workdir/data/trips.csv \
  --output-path /workdir/output/kba.png \
  --percentage-distribution 50 \
  --n-iterations 100 \
  --population-size 10 \
  --smoothing-method log_median

# 3. Export the full assessment as CSV with metadata (Tabular Data Package)
Rscript -e "bycatch::create_representative_assessment(bycatch::get_domain_specific_options())" \
  --rds-path /workdir/output/cache.rds \
  --output-path /workdir/output/assessment.csv
```

For a complete reference of all commands and parameters, see [`DOCS.md`](DOCS.md).

## Outputs

| Format | What | Example |
|--------|------|---------|
| PNG | Static maps and figures | KBA map, representativity plot |
| GeoPackage (`.gpkg`) | Vector polygons for GIS | KBA boundaries, individual KDE contours |
| CSV | Tabular data | Trip summaries, filtered data, assessment iterations |
| RDS | Cached bootstrap results | Single-file cache for fast reprocessing |
| `datapackage.json` | Field schemas alongside CSV | Tabular Data Package metadata |

## Coming soon

- Overlap analysis between seabird KBA polygons and fishing vessel tracks.
- Multi-colony comparisons.
- Customizable map projections.

