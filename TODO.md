# TODO

## Gold

- `sf_use_s2(FALSE)` save/restore in every `compute_*` that calls
  `track2KBA`. Pattern: `previous <- sf::sf_use_s2(FALSE);
  on.exit(sf::sf_use_s2(previous))`. Currently handled externally by
  fixture scripts. See AGENTS.md "Spatial (S2) and Colony" section.

---

## Completed

- `get_domain_specific_options()` missing `--gpkg-path` and `--rds-path`
  flags: fixed in v0.9.1 via TDD Red/Green cycle.
