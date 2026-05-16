# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New internal function `compute_representative_assessment()` wraps `track2KBA::repAssess` with `bootTable=TRUE` and returns both `assessment_summary` and `assessment_detail` as separate data frames.
- New internal function `compute_potential_kba()` wraps `track2KBA::findSite` with `polyOut=TRUE` and returns KBA polygons as an sf object.
- New internal function `compute_cache()` composes `compute_individual_kde` and `compute_representative_assessment` into a single pipeline that runs `repAssess` exactly once, returning only the bootstrap output for downstream caching.
- New internal function `plot_representative_assessment()` returns a ggplot2 scatterplot (InclusionRate vs SampleSize) from an `assessment_detail` data.frame. Level 1 Pure — no I/O, no side effects.
- New internal function `plot_potential_kba()` returns a ggplot2 map from an sf polygons object. Replaces `track2KBA::mapSite` — no colony parameter. Level 1 Pure — no I/O, no side effects.
- New internal function `plot_individual_kde()` returns a ggplot2 map from UDPolygons sf object. Replaces `track2KBA::mapKDE` — no colony parameter. Level 1 Pure — no I/O, no side effects.

### Changed
- `filter_data_between_dates()` renamed to `create_filtered_gps_between_dates()` (was `export_filtered_gps_between_dates()`).
- `process_fisheries_data()` renamed to `create_filtered_fisheries()` (was `export_filtered_fisheries()`).
- `write_trips_summary()` renamed to `create_trips_summary()` (was `export_trips_summary()`).
- `write_trips()` renamed to `create_trips()` (was `export_trips()`).
- `compute_space_use()` renamed to `compute_individual_kde()`.
- `get_scale_parameters()` renamed to `compute_scale_parameters()`.
- `get_trips()` renamed to `compute_trips()`.
- `get_summary_of_trips()` renamed to `compute_trips_summary()`.
- `filter_fisheries_by_date_and_lat_lon()` renamed to `compute_filtered_fisheries_by_date_and_lat_lon()`.
- `filter_fisheries_by_date()` renamed to `compute_filtered_fisheries_by_date()`.
- `filter_fisheries_by_lat_lon()` renamed to `compute_filtered_fisheries_by_lat_lon()`.
- `filter_between_dates()` renamed to `compute_filtered_between_dates()`.
- `read_config()` replaced by private helper `.adapt_config()` for Level 2 functions.
- Colony removed from `render_individual_kde()` — presentation layers no longer receive colony.
- `sf_use_s2(FALSE)` now self-managed by `compute_*` functions with save/restore pattern.
- New internal function `compute_space_use()` was added and then renamed to `compute_individual_kde()` in the same release cycle.

## [0.8.0] - 2026-05-11
### Changed
- `plot_potential_site()` renamed to `render_potential_kba()`; internal method `get_site()` renamed to `compute_potential_kba()`.
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
  - `plot_potential_site()`
  - `plot_representative_assess()`
  - `plot_usage_area_by_individual()`
  - `plot_individual_kernels()`

### Fixed
- Added `population-size` option in `get_domain_specific_options()`.

## [0.5.0] - 2025-12-19
### Added
- Command `plot_potential_site()` saves to disk a plot of the areas used by a significant proportion of the local population.

### Changed
- Function `write_trips_summary()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_individual_kernels()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_representative_assess()` now receives a CSV file from `write_trips()` output. Before, we calculated the trips twice.

## [0.4.0] - 2025-12-11

### Added
- `formatDT = "ymd_HMS"` in order to remove the parse date-time warning.

### Changed
- Function `get_trips()` now accepts columns `time` and `name` from raw GPS files.

## [0.3.0] - 2025-06-25

### Added
- Command `process_fisheries_data()` filters raw fisheries GPS data based on date and geographic boundaries.

## [0.2.0] - 2025-05-28

### Added
- New command `plot_usage_area_by_individual()` to write a usage area map for tracked individuals.

## [0.1.0] - 2024-10-03


[unreleased]: https://github.com/IslasGECI/bycatch/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/IslasGECI/bycatch/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/IslasGECI/bycatch/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/IslasGECI/bycatch/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/IslasGECI/bycatch/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/IslasGECI/bycatch/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/IslasGECI/bycatch/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/IslasGECI/bycatch/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/IslasGECI/bycatch/releases/tag/v0.1.0
