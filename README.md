<a href="https://www.islas.org.mx"><img src="https://www.islas.org.mx/img/logo.svg" align="right" width="256" /></a>

# bycatch — seabird bycatch risk assessment
[![codecov](https://codecov.io/gh/IslasGECI/bycatch/graph/badge.svg?token=wyxnwZypMA)](https://codecov.io/gh/IslasGECI/bycatch)
![example branch
parameter](https://github.com/IslasGECI/bycatch/actions/workflows/actions.yml/badge.svg)
![licencia](https://img.shields.io/github/license/IslasGECI/bycatch)
![languages](https://img.shields.io/github/languages/top/IslasGECI/bycatch)
![commits](https://img.shields.io/github/commit-activity/y/IslasGECI/bycatch)
![R-version](https://img.shields.io/github/r-package/v/IslasGECI/bycatch)

**Assess the risk that seabirds foraging near fishing vessels will get caught as bycatch.**

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
Rscript -e "bycatch::plot_potential_site(bycatch::get_domain_specific_options())" \
  --data-path /workdir/data/trips.csv \
  --config-path /workdir/config.json \
  --output-path /workdir/output/figure.png
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

- Full write/render separation: bycatch will produce interoperable GeoPackage
  files; visualisation becomes tool-agnostic (bycatch, GMT, QGIS, Python).
- Shared RDS caching: expensive bootstrapping runs once per dataset instead of
  three times, cutting build time significantly.
- `create_representative_assessment()`: one-step compute-and-export command.
- `export_potential_kba()` and `export_individual_space_use()`: direct
  GeoPackage output for the two remaining figure pipelines.

