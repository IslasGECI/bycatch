# TODO

## The Gold

- **Geometry validity guard in `plot_potential_kba`**: `track2KBA::mapSite()` internally calls `st_union()` via `dplyr::summarise()`, which fails with a GEOS `TopologyException` when KBA polygons have self-intersections.
  `findSite` can produce invalid geometries on real data (e.g., Clarion+Guadalupe combined albatross dataset — self-intersection at `-148, 50.24`).
  The test fixture `kba_polygons.rds` is clean, so the test passes.
  The error message was doubly confusing because `sf`'s `.stop_geos()` handler fires a `scan()` parse failure *before* the real `TopologyException` (upstream `sf` bug, tracked in `ISSUE.md`).
  **Fix**: call `sf::st_make_valid(site)` in `plot_potential_kba` before passing to `mapSite`.
  Also validates through to test fixture or adds a test with known-bad geometry.


## Future work

- **Slow test bottleneck**: `slow/test_compute_potential_kba.R` (1 test, calls `track2KBA::findSite`) and `slow/test_create_potential_kba.R` (1 test, calls `track2KBA::findSite`) together take ~6.5 min. Consider mocking `track2KBA::findSite` to bring them into the fast suite.
- **Dead flag cleanup**: `--smoothing-method` (`-z`) is defined in `get_domain_specific_options()` but no Level 2 function consumes it anymore. Either remove it (breaking backward compatibility) or leave it for a future major version.
- **Orphan test file**: `tests/testthat/test_kernels.R` tests `compute_scale_parameters` with inline `track2KBA::projectTracks` — should be refactored to use `compute_project_returning_tracks`.
- **Overlap analysis**: seabird KBA polygons vs fishing vessel tracks.
- **Multi-colony comparisons**.
- **Customizable map projections**.

