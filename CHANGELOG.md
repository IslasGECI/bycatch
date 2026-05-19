# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `import_config(config_path)` — exported Level 1 I/O function that reads a JSON configuration file and returns its content as a parsed list with a colony tibble. Previously the private `.adapt_config` helper in `R/cli.R`.

## [0.9.1] - 2026-05-17

### Fixed
- `get_domain_specific_options()` now defines `--gpkg-path` (`-g`) and `--rds-path` (`-r`) flags for `render_individual_kde`, `render_potential_kba`, `render_representative_assessment`, `create_potential_kba`, and `create_representative_assessment`. Previously, passing these flags via `get_domain_specific_options()` failed with "long flag is invalid".

## [0.9.0] - 2026-05-16

### Added
- `create_individual_kde(options)` — reads GPS data and configuration, computes individual kernel density estimates, and saves UDPolygons as a GeoPackage file.
- `create_processed_data(options)` — runs the full bootstrap pipeline (individual KDE + `repAssess`) exactly once and caches the assessment results as an RDS file. This is the only exported function that runs the expensive bootstrap.
- `create_potential_kba(options)` — reads a cached RDS file, recomputes individual KDE from raw data, identifies potential KBAs, and saves the result as a GeoPackage file. Requires a pre-computed RDS cache (from `create_processed_data`).
- `create_representative_assessment(options)` — reads a cached RDS file and writes the full iteration data as a Tabular Data Package (CSV + `datapackage.json` with field schemas).

### Changed
- `filter_data_between_dates()` renamed to `create_filtered_gps_between_dates()`.
- `process_fisheries_data()` renamed to `create_filtered_fisheries()`.
- `write_trips_summary()` renamed to `create_trips_summary()`.
- `write_trips()` renamed to `create_trips()`.
- `render_representative_assessment()` no longer runs the R6 compute pipeline. It now takes `rds-path` and `output-path` only — reads a pre-computed cache instead of raw data.
- `render_potential_kba()` no longer runs the R6 compute pipeline or calls `track2KBA::mapSite`. It now takes `gpkg-path` and `output-path` only — reads a pre-computed GeoPackage instead of raw data.
- `render_individual_kde()` no longer runs the R6 compute pipeline or calls `track2KBA::mapKDE`. It now takes `gpkg-path` and `output-path` only — reads a pre-computed GeoPackage instead of raw data.

### Removed
- No exported functions were removed.

## [0.8.0] - 2026-05-11
### Changed
- Exported function `render_potential_kba()` replaces internal `plot_potential_site()`; internal method `get_site()` renamed to `compute_potential_kba()`.
- `plot_representative_assess()` renamed to `render_representative_assessment()`; internal method `get_assessment()` renamed to `compute_representative_assessment()`.
- `plot_individual_kernels()` renamed to `render_individual_kde()`; internal method `calculate_space_use()` renamed to `estimate_space_use()`.

### Removed
- Command `plot_usage_area_by_individual()` no longer available.
- Internal method `get_site()` removed from `Track2KBA_Wrapper`.

## [0.7.0] - 2026-01-30
### Added
- Command `filter_data_between_dates()` filters GPS data between two dates. The dates given are included in the output file.

## [0.6.0] - 2026-01-14
### Added
- New argument `smoothing-method` to select the method used to compute the smoothing parameter `h` in the following CLI commands:
  - `plot_representative_assess()`
  - `plot_usage_area_by_individual()`
  - `plot_individual_kernels()`

### Fixed
- Added `population-size` option in `get_domain_specific_options()`.

## [0.5.0] - 2025-12-19
### Changed
- Function `write_trips_summary()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_individual_kernels()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_representative_assess()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.

## [0.4.0] - 2025-12-11

### Added
- `formatDT = "ymd_HMS"` in order to remove the parse date-time warning.

## [0.3.0] - 2025-06-25

### Added
- Command `process_fisheries_data()` filters raw fisheries GPS data based on date and geographic boundaries.

## [0.2.0] - 2025-05-28

### Added
- New command `plot_usage_area_by_individual()` to write a usage area map for tracked individuals.

## [0.1.0] - 2024-10-03


[unreleased]: https://github.com/IslasGECI/bycatch/compare/v0.9.1...HEAD
[0.9.1]: https://github.com/IslasGECI/bycatch/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/IslasGECI/bycatch/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/IslasGECI/bycatch/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/IslasGECI/bycatch/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/IslasGECI/bycatch/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/IslasGECI/bycatch/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/IslasGECI/bycatch/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/IslasGECI/bycatch/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/IslasGECI/bycatch/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/IslasGECI/bycatch/releases/tag/v0.1.0
