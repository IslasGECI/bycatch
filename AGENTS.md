# AGENTS.md — bycatch

R package `bycatch` (v0.9.1) — seabird bycatch risk assessment.
Maintainer: [IslasGECI](https://github.com/IslasGECI/bycatch).

## Commands

| Command | What it does |
|---|---|
| `make tests` | Run all tests (`devtools::test`) |
| `make coverage` | Run tests + generate HTML coverage report (sends to codecov) |
| `make format` | Auto-format `R/` and `tests/` with `styler` |
| `make check` | Check formatting only (no auto-fix) — CI fails if unformatted |
| `make setup` | `make clean` → `devtools::install` → `check` → `build` → `document` |
| `make clean` | Remove `*.tar.gz`, `tests/testthat/_snaps`, `NAMESPACE` |
| `make install` | Install deps, run checks, build package, update docs (`devtools::install` → `check` → `build` → `document`) |
| `make tests_file file=<path>` | Run a single test file (no commit/restore) |
| `make mutants` | Placeholder (not yet implemented) |

> **Note:** `devtools` is only available inside Docker. Run tests via `docker exec bycatch_code_ci make tests`. The suite takes ~12 minutes.
> Each test file contains exactly one `describe()` block.
> Fast tests can be run with `make tests_fast`, which skips the slow tests
> in `tests/testthat/slow/`. Slow tests require `make tests` (or `make tests_slow`).
> `make tests_file` does **not** work for files in `slow/`; use `testthat::test_file()` directly instead.
>
> Test timing (individual files):
>
> | Test file | describe | Tests | Time |
> |---|---|---|---|
> | `test_compute_individual_kde.R` | compute_individual_kde | 8 | 17.6s |
> | `test_compute_representative_assessment.R` | compute_representative_assessment | 5 | 5.7s |
> | `test_create_individual_kde.R` | create_individual_kde | 2 | 21.4s |
> | `test_create_potential_kba.R` | create_potential_kba | 2 | 166.1s |
> | `test_create_processed_data.R` | create_processed_data | 4 | 22.0s |
> | `test_create_representative_assessment.R` | create_representative_assessment | 2 | 3.6s |
> | `test_filter_gps_between_dates.R` | filter gps data between dates | 1 | 3.6s |
> | `test_fisheries_process.R` | Processes fisheries data | 3 | 3.6s |
> | `test_get_domain_specific_options.R` | Define domain specific options | 1 | 3.6s |
> | `test_kernels.R` | Calculate space use | 3 | 3.9s |
> | `test_plot_individual_kde.R` | plot_individual_kde | 1 | 3.6s |
> | `test_plot_potential_kba.R` | plot_potential_kba | 1 | 3.6s |
> | `test_plot_representative_assessment.R` | plot_representative_assessment | 1 | 3.6s |
> | `test_process_fisheries.R` | process fisheries data | 1 | 3.7s |
> | `test_track_example.R` | Get trips from GECI data | 2 | 3.8s |
> | `test_write_trips_geographic_points.R` | Write trips geographic points | 2 | 3.8s |
> | `test_write_trips_summary.R` | Write trips summary | 2 | 3.8s |
> | `slow/test_compute_potential_kba.R` | compute_potential_kba | 2 | 222.3s |
> | `slow/test_render_individual_kde.R` | render individual kde | 1 | 5.0s |
> | `slow/test_render_potential_kba.R` | render potential kba | 1 | 4.1s |
> | `slow/test_render_representative_assessment.R` | render representative assessment | 1 | 4.1s |
>
> The bottleneck is `test_create_potential_kba.R` (166s) and `slow/test_compute_potential_kba.R`
> (222s), both calling `findSite` internally.
> All three `render_*` slow tests read pre-computed fixtures instead
> of running the full compute pipeline, keeping them well under 10s each.

## Testing tip: source loading

`devtools::test()` loads package code from the `R/` source directory, not from
the installed library. Changes to `R/*.R` files are picked up without rebuilding
the package. Only run `make install` when you need to regenerate `NAMESPACE`,
documentation, or check for CMD check warnings.

## TDD workflow (built into Makefile)

- **`make red`** — format tests, run them. If they fail → stage `tests/testthat/*.R` → commit. If they pass → `git restore .`
- **`make green`** — format R/, run tests. If they pass → stage `R/*.R` → commit. If they fail → `git restore .`
- **`make refactor`** — format both, run tests. If pass → stage all → commit. If fail → `git restore .`
- **`make red_file file=path`** etc. — single-file TDD cycle.

All three always run `format` first (via `styler`).

### Manual TDD workflow (alternative)

When the Makefile targets are too rigid, phases can be managed manually:

1. Make changes (test or production code).
2. Stage relevant files with `git add`.
3. Run tests via `docker exec bycatch_code_ci make tests`.
4. If tests fail, adjust and repeat. If tests pass, commit.

This gives explicit control over staging boundaries and commit messages.

### Rename-only workflow

When renaming a function (no behavioral change):

1. Update the test to call the new name.
2. Run tests — they should fail (cannot find new name in production).
3. Rename the production code.
4. Run tests — they should pass.
5. Commit both changes together.

This is test-first for renames: the test drives the rename by calling a name
that does not exist yet. Every rename follows this Red → Green cycle.

### Dead-code removal workflow (inverted TDD)

When removing a feature that is no longer needed:

1. Remove dead production code.
2. Run tests — they should fail (Red-like state).
3. Remove the corresponding test(s).
4. Run tests — they should pass (Green-like state).
5. Commit both changes together.

This is the inverse of test-first: production code is removed first, then the test is removed to restore Green. It is a cleanup cycle distinct from the three standard phases.

## Architecture references

Three documents define the architecture:
- [Arquitectura en niveles y capas](https://islas.dev/2026/05/15/arquitectura) — 3 levels (Level 1 Pure, Level 1 I/O, Level 2 Artifact).
- [Guía de estilo](https://islas.dev/guia_de_estilo/STYLEGUIDE) — naming conventions for each level.
- [Desacoplamiento de análisis y visualización](https://islas.dev/2026/03/20/desacoplamiento) — create_*/render_* split, no render_* computes.

### Naming convention

| Prefix | Level | Role |
|--------|-------|------|
| `compute_*` | 1 Pure | In-memory calculation, no I/O |
| `plot_*` | 1 Pure | In-memory ggplot2, no I/O |
| `.name` (dot prefix) | 2 Helper | Private helper called only by Level 2 |
| `create_*` | 2 Artifact | Read → compute → write (exported) |
| `render_*` | 2 Artifact | Read → plot → write (exported) |
| `get_domain_specific_options` | — | Exported exception (CLI helper) |

R does not allow identifiers starting with underscore. Use dot prefix for private helpers (`.helper_function()`).

### Layer rules

- Level 1 Pure (`compute_*`, `plot_*`): never read/write files, never call Level 1 I/O.
- Level 1 I/O (`read_*`, `write_*`, `import_*`, `export_*`): only disk I/O, no computation. Third-party I/O calls (`readr::read_csv`, `sf::st_write`, `ggsave`) are used directly by Level 2 — no wrappers.
- Level 2 (`create_*`, `render_*`): compose Level 1 functions. Only Make orchestrates Level 2 calls — they never call each other.

### Filter ownership rule

Every data row filter (`[`, `dplyr::filter`, `subset`) must be delegated to a `compute_*` function. `create_*` and `render_*` functions must not transform data — they orchestrate (read → compute → write) without filtering, mutating, or selecting rows.

This includes:
- `data[data$Returns == "Yes", ]` → inside `compute_project_returning_tracks`
- `data[data$Returns == "Yes", ]` → inside `compute_trips_summary`
- date-range filtering → inside `compute_filtered_between_dates`
- lat/lon filtering → inside `compute_filtered_fisheries_by_lat_lon`

Exceptions (not data filtering):
- Reading from the `options` list (configuration access, not data transformation)
- I/O parameters (e.g., `show_col_types = FALSE`)
- Column selection that is inherent to output format (e.g., extracting `@data` from a Spatial object before writing CSV)

### Layer ownership rule (no redundant computation)

Every track2KBA function must be called in **exactly one** `compute_*` (or `plot_*`).  
Every `compute_*` must be called in **exactly one** `create_*` (or `render_*`).  
Every `create_*` writes its result to disk.  

Consequences:
- No `compute_*` calls another `compute_*` — if a `compute_*` needs another computation's result, the caller (`create_*`) reads it from disk and passes it as a parameter.
- Every intermediate result is materialized on disk by a `create_*` function. The second time the same computation is needed, it is read from disk instead of re-run.
- Exceptions must be explicitly documented with justification.

### Spatial (S2) and Colony

`sf_use_s2(FALSE)` save/restore is the responsibility of `compute_*` functions
but the pattern is NOT yet implemented — fixture scripts handle S2 externally.
`plot_*` never sets S2 (they only use ggplot2). `create_*`/`render_*` are
completely unaware of S2 state.

Colony is kept only inside `compute_*` calls to `track2KBA` algorithms
(`tripSplit`, `tripSummary`). `plot_*` and `render_*` never receive or use colony.

## Package structure

- **`R/`** — 5 files. Entrypoint: `cli.R` (Level 2 functions: `create_*`, `render_*`, ). Compute layer: `compute.R` (all `compute_*` functions). Plot layer: `plot.R` (internal `plot_*` functions). I/O: `io.R` (`import_config()`). Exception: `get_domain_specific_options.R`.
- **`tests/testthat/`** — 17 fast + 4 slow in `slow/`. Uses `testthat` edition 3 + `testtools` helpers for file-existence assertions. Each file contains exactly one `describe()` block.
  - Fast: `test_compute_individual_kde.R`, `test_compute_representative_assessment.R`, `test_create_individual_kde.R`, `test_create_potential_kba.R`, `test_create_processed_data.R`, `test_create_representative_assessment.R`, `test_filter_gps_between_dates.R`, `test_fisheries_process.R`, `test_get_domain_specific_options.R`, `test_kernels.R`, `test_plot_individual_kde.R`, `test_plot_potential_kba.R`, `test_plot_representative_assessment.R`, `test_process_fisheries.R`, `test_track_example.R`, `test_write_trips_geographic_points.R`, `test_write_trips_summary.R`.
  - Slow: `slow/test_compute_potential_kba.R`, `slow/test_render_individual_kde.R`, `slow/test_render_potential_kba.R`, `slow/test_render_representative_assessment.R`.
- **`tests/data/`** — CSV and RDS fixtures. Paths hardcoded as `/workdir/tests/data/…` (Docker convention).
- **`tests/src/`** — One-off scripts (e.g., `create_test_fixtures.R`). Not part of the test suite.
- **`NAMESPACE`** — roxygen2-generated. Deleted by `make clean`, regenerated by `make setup`. 12 exported functions.
- **`man/`** — 7 `.Rd` files (roxygen2-generated).
- **`track2kba/`** — Read-only reference clone of `BirdLifeInternational/track2kba` (master branch, clean checkout). Not a git submodule. Not modified. Used to inspect and study the external package source without depending on GitHub availability. The actual dependency is installed from GitHub via `DESCRIPTION` `Remotes:`.
- **`DESCRIPTION`** — 4 remote dependencies: `BirdLifeInternational/track2kba`, `IslasGECI/gecioptparse`, `IslasGECI/testtools`, `r-quantities/units`.

## Testing quirks

- `make tests_file file=<path>` runs a single test file without commit/restore.
- Coverage script: `tests/testthat/coverage.R` (uses `covr`, sends to codecov). HTML report written to `tests/coverage-report.html`.
- `covr::package_coverage()` runs only the fast test suite — `render_*` function bodies are exercised only by slow tests, so they show as uncovered.
- All paths in tests are `/workdir/…` — to run outside Docker, symlink or adjust paths.

## Fixture scripts

- `tests/src/create_test_fixtures.R` generates `.rds` fixture files in `tests/data/`.
  Not part of the test suite — run once, commit the `.rds` files. Rerun when test
  fixtures need regeneration: `docker exec bycatch_code_ci Rscript tests/src/create_test_fixtures.R`.
- The script calls internal `compute_*` functions via `bycatch:::` (e.g.,
  `bycatch:::compute_individual_kde()`). Internal functions are never exported;
  use `bycatch:::` outside the package namespace.

## CI

GitHub Actions (`.github/workflows/actions.yml`): `docker build` → `make check` → `make coverage` → `make mutants` → push Docker images to Docker Hub. Everything runs inside Docker.

## Commit conventions

Each commit message follows this format:
- **Gitmoji** prefix matching the change type (🔥 remove, 🗑️ deprecate, 📝 docs, 🛑🧪🧩🚧  Red phase of TDD, ✅🧪🧩🚧 Green phase of TDD, 🧩 🚧 small step of a bigger plan ).
- **Imperative verb** immediately after the gitmoji.
- **Summary** under 72 characters.
- **Blank second line.**
- **Body** explains motivation (why, not what). Avoid restating the diff.
- **No Conventional Commits** prefixes (`feat:`, `fix:`, etc.).

## Repo conventions

- **Formatting**: `styler` is mandatory. `make check` enforces it in CI.
- **Docs**: roxygen2 with `markdown = TRUE`. Run `devtools::document()` (or `make install`) to regenerate `NAMESPACE` and `man/*.Rd`.
  `NAMESPACE` is gitignored; `man/` files are untracked. Roxygen2 `#'` tags in `R/*.R` are the source of truth — generated files are never committed manually.
- **OO pattern**: No R6 classes remain. Legacy `Track2KBA_Wrapper` was removed. All state is passed explicitly through function parameters.
- **Compute/plot layer**: `compute_*` functions are pure (no I/O, no side effects), return lists or data.frames. `plot_*` functions are pure, return ggplot2 objects. Disk I/O lives only in exported `create_*` / `render_*` functions in `R/cli.R`.
- **`(options)` convention**: All Level 2 exported functions (`create_*`, `render_*`) accept a single `options` list parameter via `get_domain_specific_options()`. This is a permanent design decision — the `(options)` signature will not be changed.
- **Parser-option coupling**: Every option key that a Level 2 function reads (`options[["key-name"]]`) must have a corresponding flag definition in `get_domain_specific_options()`. When adding a new function or a new option key to an existing function, always add the flag definition in `R/get_domain_specific_options.R` and add the key name to `tests/testthat/test_get_domain_specific_options.R`. Otherwise, CLI calls via `get_domain_specific_options()` fail with "long flag is invalid".
- **Bug-scope investigation**: When a bug report mentions missing parser flags, cross-reference ALL exported Level 2 functions against `get_domain_specific_options()` — the report may list only a subset of affected functions. Use `grep('options\\[\\[', R/cli.R)` to find all consumed keys.
- **Cache design**: Two RDS cache files produced: individual_kde.rds (KDE_surface, UDPolygons, tracks) and assessment.rds (assessment_summary, assessment_detail, KDE_surface). Colony was removed from `compute_individual_kde` when the function was simplified — it no longer calls `tripSummary`.
- **License**: AGPL-3.0-or-later.
