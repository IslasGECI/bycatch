# TODO

## The Gold

A codebase where the **Layer ownership rule** is fully enforced — no redundant computation, no cross-layer violations, no `compute_*` calling another `compute_*`. Every `track2KBA` function owned by exactly one `compute_*`. Every `compute_*` called by exactly one `create_*`. Every `create_*` writes its result to disk. Downstream stages read intermediate results from disk rather than re-running computations.

## Next steps

### v0.9.2 cleanup

All 9 TDD cycles and "Outside the Plan" refactoring are complete. The changes have been documented, the version bumped, and a release tag is pending.

### Future work

- **Slow test bottleneck**: `slow/test_compute_potential_kba.R` (1 test, calls `track2KBA::findSite`) and `slow/test_create_potential_kba.R` (1 test, calls `track2KBA::findSite`) together take ~6.5 min. Consider mocking `track2KBA::findSite` to bring them into the fast suite.
- **Dead flag cleanup**: `--smoothing-method` (`-z`) is defined in `get_domain_specific_options()` but no Level 2 function consumes it anymore. Either remove it (breaking backward compatibility) or leave it for a future major version.
- **`sf_use_s2(FALSE)`**: The save/restore pattern should live in `compute_*` functions rather than being handled externally by fixture scripts.
- **Orphan test file**: `tests/testthat/test_kernels.R` tests `compute_scale_parameters` with inline `track2KBA::projectTracks` — should be refactored to use `compute_project_returning_tracks`.
- **Overlap analysis**: seabird KBA polygons vs fishing vessel tracks.
- **Multi-colony comparisons**.
- **Customizable map projections**.
