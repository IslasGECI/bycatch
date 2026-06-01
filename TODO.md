# The Gold

- **Slow test bottleneck**: `slow/test_compute_potential_kba.R` and `slow/test_create_potential_kba.R` together take ~6.5 min because both call `track2KBA::findSite`. Mocking `findSite` would bring them into the fast suite.

---

# Backlog not part of the current Gold

The items listed below are not part of the current Gold. They are backlog items kept for future cycles.

- **Orphan test file**: `tests/testthat/test_kernels.R` tests `compute_scale_parameters` with inline `track2KBA::projectTracks` — should be refactored to use `compute_project_returning_tracks`.
- **Overlap analysis**: seabird KBA polygons vs fishing vessel tracks.
- **Multi-colony comparisons**.
- **Customizable map projections**.

