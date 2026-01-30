# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Command `filter_data_between_dates()` filter GPS data between two dates. The dates given are included on the output file.

### Fixed

### Changed

### Removed

## [0.7.0] - 2026-01-30
### Added
- Command `filter_data_between_dates()` filter GPS data between two dates. The dates given are included on the output file.

## [0.6.0] - 2026-01-14
### Added
- New argument `smoothing-method` to select the method used to compute the smoothing parameter `h` in the following CLI commands:
  - `plot_potential_site()`
  - `plot_representative_assess()`
  - `plot_usage_area_by_individual()`
  - `plot_individual_kernels()`

### Fixed
- Add `population-size` option in `get_domain_specific_options()`.


## [0.5.0] - 2025-12-19
### Added
- Command `plot_potential_site()` saves on disk plot of the areas used by a significant proportion of the local population.

### Changed
- Function `write_trips_summary()` now receives a csv file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_individual_kernels()` now receives a csv file from `write_trips()` output. Before, we calculated the trips twice.
- Function `plot_representative_assess()` now receives a csv file from `write_trips()` output. Before, we calculated the trips twice.

## [0.4.0] - 2025-12-11

### Added
- `formatDT = "ymd_HMS"` in order to remove parse date time warning.

### Changed
- Function `get_trips()` now accept columns `time` and `name` from raw GPS files.

## [0.3.0] - 2025-06-25

### Added
- Command `process_fisheries_data()` filter raw fisheries GPS data based on date and geographic boundaries.

## [0.2.0] - 2025-05-28

### Added
- New command `plot_usage_area_by_individual()` to write map usage area for tracked individuals.

## [0.1.0] - 2024-10-03


[unreleased]: https://github.com/IslasGECI/bycatch/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/IslasGECI/bycatch/releases/tag/v0.1.0
