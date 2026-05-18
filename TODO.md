# TODO

## Bug: `get_domain_specific_options()` missing `--gpkg-path` and `--rds-path` flags

Package: bycatch (bycatch_code) v0.9.0
Files: `R/get_domain_specific_options.R` (parser), `tests/testthat/test_get_domain_specific_options.R` (test)

### Symptoms

Five exported functions read `options[[…]]` keys that
`get_domain_specific_options()` does not define in its parser:

| Function | Reads `options[[…]]` | Corresponding `--flag` | Defined in parser? |
|---|---|---|---|
| `render_individual_kde` | `gpkg-path` | `--gpkg-path` | ❌ |
| `render_potential_kba` | `gpkg-path` | `--gpkg-path` | ❌ |
| `render_representative_assessment` | `rds-path` | `--rds-path` | ❌ |
| `create_potential_kba` | `rds-path` | `--rds-path` | ❌ |
| `create_representative_assessment` | `rds-path` | `--rds-path` | ❌ |

All five functions already use the correct key names in their code and
roxygen docs. No function code changes are needed — only the parser is
missing the flag definitions.

### Reproduction

```shell
docker exec bycatch_code_ci \
  Rscript -e "bycatch::render_individual_kde(bycatch::get_domain_specific_options())" \
  --gpkg-path some/file.gpkg --output-path out.png
```

Result: `Error: long flag "gpkg-path" is invalid`

### Design decisions (design interview)

| Decision | Chosen option | Rationale |
|---|---|---|
| Flag names | Two specialized flags: `--gpkg-path` and `--rds-path` | Each input format has its own explicit flag |
| Short flags | `-g` for `--gpkg-path`, `-r` for `--rds-path` | Both unused, mnemonics: **g**pkg, **r**ds |
| Bug scope | All 5 functions (not just the 3 render functions) | TODO symptom table was incomplete |
| Doc updates | Update `DOCS.md` returned-names list | Keeps the interface reference accurate |
| Test order | Alphabetical insertion of new expected names | Consistent with existing test style |

### Implementation: TDD Red / Green

This fix follows the project's documented TDD workflow (see `AGENTS.md`):

- **Red phase** — write a failing test that expresses the bug, commit only
  test changes. The test asserts that `"gpkg-path"` and `"rds-path"` are
  present in the options returned by `get_domain_specific_options()`.
  It will fail because the parser doesn't define them yet.

- **Green phase** — add the two flag definitions to the parser, make the
  test pass, commit all production and doc changes.

Each phase has a clear stopping condition (tests fail / tests pass) and
a separate commit.

---

### Red phase — write the failing test

#### Step 1 — Edit the test

File: `tests/testthat/test_get_domain_specific_options.R`

Add `"gpkg-path"` and `"rds-path"` to the `expected_options` vector in
alphabetical position:

```
expected_options <- c(
  "config-path",
  "data-path",
  "date-column-name",
  "end",
  "gpkg-path",         ← new
  "lat-max",
  "lat-min",
  "lon-max",
  "lon-min",
  "n-iterations",
  "output-path",
  "percentage-distribution",
  "population-size",
  "rds-path",          ← new
  "smoothing-method",
  "start"
)
```

Note: The vector is reordered alphabetically so the position of the new
entries is predictable. The existing test uses `%in%` (order-independent
assertion), so alphabetical order is a readability choice, not a
functional requirement.

#### Step 2 — Run the test (expect Red)

```shell
docker exec bycatch_code_ci make tests_file \
  file=tests/testthat/test_get_domain_specific_options.R
```

Expected: test **fails** — `"gpkg-path"` and `"rds-path"` are not yet
defined in the parser.

#### Step 3 — Guard: check for false negative

If the test **passes** (unexpected), the bug does not exist yet. Run
`git restore tests/` and investigate.

#### Step 4 — Commit the failing test (Red)

```shell
git add tests/testthat/test_get_domain_specific_options.R
git commit -m "🛑🧪🧩🚧  Add failing test for missing --gpkg-path and --rds-path flags"
```

---

### Green phase — fix the bug

#### Step 5 — Edit the parser

File: `R/get_domain_specific_options.R`

Add two new option definitions **after** `output_path` (grouping path
options together):

```r
gpkg_path <- gecioptparse::character_option(
  c("-g", "--gpkg-path"),
  default = "",
  help = "Path to input GeoPackage (KBA polygons or UD polygons)"
)

rds_path <- gecioptparse::character_option(
  c("-r", "--rds-path"),
  default = "",
  help = "Path to input RDS cache file"
)
```

Append `gpkg_path` and `rds_path` to the `option_names` vector.

No other production code changes are needed. The five affected functions
already read `options[["gpkg-path"]]` and `options[["rds-path"]]`
correctly — only the parser was missing.

#### Step 6 — Update documentation

File: `DOCS.md`

Add `gpkg-path` and `rds-path` to the returned-names list in the
`get_domain_specific_options()` entry (around line 165).

#### Step 7 — Run `make format`

```shell
docker exec bycatch_code_ci make format
```

#### Step 8 — Run the test (expect Green)

```shell
docker exec bycatch_code_ci make tests_file \
  file=tests/testthat/test_get_domain_specific_options.R
```

Expected: test **passes** — parser now defines both flags.

#### Step 9 — Guard: check for false positive

If the test **fails**, iterate on steps 5–8 until it passes.

#### Step 10 — Run the full fast test suite

```shell
docker exec bycatch_code_ci make tests_fast
```

Verify no regressions.

#### Step 11 — Commit the fix (Green)

```shell
git add R/get_domain_specific_options.R DOCS.md
git commit -m "✅🧪🧩🚧  Add --gpkg-path and --rds-path flags to get_domain_specific_options"
```

---

### Impact

This bug blocks `bycatch_thesis` from upgrading its Makefile to use the
new `render_*` functions. Without this fix, every render or create call
that uses `get_domain_specific_options()` fails with "long flag is
invalid" when passing `--gpkg-path` or `--rds-path`.

---

## Misc

- `sf_use_s2(FALSE)` save/restore in every `compute_*` that calls
  `track2KBA`. Pattern: `previous <- sf::sf_use_s2(FALSE);
  on.exit(sf::sf_use_s2(previous))`. Currently handled externally by
  fixture scripts. See AGENTS.md "Spatial (S2) and Colony" section.
