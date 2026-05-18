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
> Fast tests (ideally ~37s) can be run with `make tests_fast`, which skips the slow tests
> in `tests/testthat/slow/`. However, `tests/testthat/test_cache.R` contains a `create_potential_kba`
> test that calls `findSite` internally and takes ~5 minutes — it is **not** in `slow/` yet,
> so `make tests_fast` currently takes ~6 minutes total. Slow tests require `make tests` (or `make tests_slow`).
> 
> Slow test timing (individual files, via `testthat::test_file`):
>
> | Test file | Runtime |
> |---|---|
> | `test_compute_potential_kba.R` | 6m 28s |
> | `test_render_potential_kba.R` | <1s (was 5m — Sprint 5 made it artifact-reading) |
> | `test_render_representative_assessment.R` | <1s (was 34s — Sprint 5 made it artifact-reading) |
> | `test_render_individual_kde.R` | <1s (was 23s — Sprint 5 made it artifact-reading) |
>
> After Sprint 5, all three `render_*` tests read pre-computed fixtures instead
> of running the full compute pipeline, reducing them from minutes to sub-second.
> The bottleneck shifted to `test_cache.R` (5m) and `test_compute_potential_kba.R`
> (6m 28s), both calling `findSite` internally. `make tests_file` does **not** work
> for files in `slow/`; use `testthat::test_file()` directly instead.

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

R does not allow identifiers starting with underscore. Use dot prefix for private helpers (`.adapt_config`).

### Layer rules

- Level 1 Pure (`compute_*`, `plot_*`): never read/write files, never call Level 1 I/O.
- Level 1 I/O (`read_*`, `write_*`, `import_*`, `export_*`): only disk I/O, no computation. Third-party I/O calls (`readr::read_csv`, `sf::st_write`, `ggsave`) are used directly by Level 2 — no wrappers.
- Level 2 (`create_*`, `render_*`): compose Level 1 functions. Only Make orchestrates Level 2 calls — they never call each other.

### Spatial (S2) and Colony

`sf_use_s2(FALSE)` save/restore is the responsibility of `compute_*` functions
but the pattern is NOT yet implemented — fixture scripts handle S2 externally.
`plot_*` never sets S2 (they only use ggplot2). `create_*`/`render_*` are
completely unaware of S2 state.

Colony is kept only inside `compute_*` calls to `track2KBA` algorithms
(`tripSplit`, `tripSummary`). `plot_*` and `render_*` never receive or use colony.

## Package structure

- **`R/`** — 4 files. Entrypoint: `cli.R` (Level 2 functions: `create_*`, `render_*`, `.adapt_config`). Compute layer: `compute.R` (all `compute_*` functions). Plot layer: `plot.R` (internal `plot_*` functions). Exception: `get_domain_specific_options.R`.
- **`tests/testthat/`** — 9 fast + 4 slow in `slow/`. Uses `testthat` edition 3 + `testtools` helpers for file-existence assertions.
  - Fast: `test_cache.R`, `test_cli.R`, `test_compute_individual_kde.R`, `test_compute_representative_assessment.R`, `test_fisheries_process.R`, `test_get_domain_specific_options.R`, `test_kernels.R`, `test_plot.R`, `test_track_example.R`.
  - Slow: `slow/test_compute_potential_kba.R`, `slow/test_render_*.R`.
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
- **OO pattern**: No R6 classes remain. Legacy `Track2KBA_Wrapper` was removed in Sprint 6. All state is passed explicitly through function parameters.
- **Compute/plot layer**: `compute_*` functions are pure (no I/O, no side effects), return lists or data.frames. `plot_*` functions are pure, return ggplot2 objects. Disk I/O lives only in exported `create_*` / `render_*` functions in `R/cli.R`.
- **`(options)` convention**: All Level 2 exported functions (`create_*`, `render_*`) accept a single `options` list parameter via `get_domain_specific_options()`. This is a permanent design decision — no signature cleanup sprint will occur.
- **Parser-option coupling**: Every option key that a Level 2 function reads (`options[["key-name"]]`) must have a corresponding flag definition in `get_domain_specific_options()`. When adding a new function or a new option key to an existing function, always add the flag definition in `R/get_domain_specific_options.R` and add the key name to `tests/testthat/test_get_domain_specific_options.R`. Otherwise, CLI calls via `get_domain_specific_options()` fail with "long flag is invalid".
- **Bug-scope investigation**: When a bug report mentions missing parser flags, cross-reference ALL exported Level 2 functions against `get_domain_specific_options()` — the report may list only a subset of affected functions. Use `grep('options\\[\\[', R/cli.R)` to find all consumed keys.
- **Cache design**: Only `repAssess` output is cached (two data.frames: `assessment_summary`, `assessment_detail`). KDE_surface, UDPolygons, and tracks are fast to recompute and never cached. Colony is used internally by `compute_individual_kde` but never returned or cached.
- **License**: AGPL-3.0-or-later.
