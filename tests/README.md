# Test timing

Times measured by running each test file individually via `devtools::test_active_file()`. Each run includes package loading overhead (~3-4s).

## Fast suite (21 files)

| File | Tests | Time (s) | Notes |
|------|-------|----------|-------|
| `test_compute_individual_kde.R` | 5 | 21.3 | Calls `track2KBA::estSpaceUse` |
| `test_compute_project_returning_tracks.R` | 1 | 3.7 | |
| `test_compute_representative_assessment.R` | 5 | 5.8 | |
| `test_create_individual_kde.R` | 2 | 21.6 | Calls `track2KBA::estSpaceUse` |
| `test_create_representative_assessment.R` | 2 | 22.8 | Calls `track2KBA::repAssess` |
| `test_filter_gps_between_dates.R` | 1 | 3.7 | |
| `test_fisheries_process.R` | 3 | 3.6 | |
| `test_get_domain_specific_options.R` | 1 | 3.6 | |
| `test_import_trips.R` | 2 | 3.7 | |
| `test_import_trips_summary.R` | 1 | 3.7 | |
| `test_kernels.R` | 3 | 3.9 | |
| `test_plot_individual_kde.R` | 1 | 3.9 | |
| `test_plot_potential_kba.R` | 1 | 4.0 | |
| `test_plot_representative_assessment.R` | 1 | 3.7 | |
| `test_process_fisheries.R` | 1 | 3.8 | |
| `test_render_individual_kde.R` | 1 | 4.5 | |
| `test_render_potential_kba.R` | 1 | 4.6 | |
| `test_render_representative_assessment.R` | 1 | 3.9 | |
| `test_track_example.R` | 2 | 3.8 | |
| `test_write_trips_geographic_points.R` | 2 | 3.8 | |
| `test_write_trips_summary.R` | 2 | 3.8 | |

Fast suite total (sequential): ~53.4s (excluding overhead).
Fast suite total (`make tests_fast`): ~56s.

## Slow suite (2 files)

| File | Tests | Time (s) | Notes |
|------|-------|----------|-------|
| `test_compute_potential_kba.R` | 1 | 214.7 | Calls `track2KBA::findSite` |
| `test_create_potential_kba.R` | 1 | 169.1 | Calls `track2KBA::findSite` |

Slow suite total: ~383.8s (~6.4 min).

## Total

All tests: ~440s (~7.3 min).

Bottleneck: `track2KBA::findSite` (both slow tests).
