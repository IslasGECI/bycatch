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

# 1. Cache individual KDE for a colony (fast, no bootstrap)
Rscript -e "bycatch::create_individual_kde(bycatch::get_domain_specific_options())" \
  --config-path /workdir/config.json \
  --data-path /workdir/data/trips.csv \
  --output-path /workdir/output/individual_kde.rds \
  --percentage-distribution 50 \
  --trips-summary-path /workdir/data/trips_summary.csv

# 2. Run the expensive bootstrap assessment (repAssess) once
Rscript -e "bycatch::create_representative_assessment(bycatch::get_domain_specific_options())" \
  --rds-path /workdir/output/individual_kde.rds \
  --output-path /workdir/output/assessment.rds \
  --percentage-distribution 50 \
  --n-iterations 100

# 3. Render the assessment diagnostic plot
Rscript -e "bycatch::render_representative_assessment(bycatch::get_domain_specific_options())" \
  --rds-path /workdir/output/assessment.rds \
  --output-path /workdir/output/assessment.png

# 4. Identify potential KBAs from the cached assessment
Rscript -e "bycatch::create_potential_kba(bycatch::get_domain_specific_options())" \
  --rds-path /workdir/output/assessment.rds \
  --output-path /workdir/output/kba.gpkg \
  --percentage-distribution 50 \
  --population-size 10

# 5. Render a KBA map from the pre-computed GeoPackage
Rscript -e "bycatch::render_potential_kba(bycatch::get_domain_specific_options())" \
  --gpkg-path /workdir/output/kba.gpkg \
  --output-path /workdir/output/kba.png

# 6. Render an individual KDE map from the cached RDS
Rscript -e "bycatch::render_individual_kde(bycatch::get_domain_specific_options())" \
  --rds-path /workdir/output/individual_kde.rds \
  --output-path /workdir/output/individual_kde.png
```

For a complete reference of all commands and parameters, see [`DOCS.md`](DOCS.md).

## Outputs

| Format | What | Example |
|--------|------|---------|
| PNG | Static maps and figures | KBA map, individual KDE map |
| GeoPackage (`.gpkg`) | Vector polygons for GIS | KBA boundaries |
| CSV | Tabular data | Trip summaries, filtered data |
| RDS | Cached computation results | Individual KDE cache, assessment cache |

## Coming soon

- Overlap analysis between seabird KBA polygons and fishing vessel tracks.
- Multi-colony comparisons.
- Customizable map projections.

