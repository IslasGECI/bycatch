# TODO

- **P5 — Implement `sf_use_s2(FALSE)` save/restore** in every `compute_*` that calls `track2KBA`. Pattern: `previous <- sf::sf_use_s2(FALSE); on.exit(sf::sf_use_s2(previous))`. Currently handled externally by fixture scripts. See AGENTS.md "Spatial (S2) and Colony" section for the required pattern.
