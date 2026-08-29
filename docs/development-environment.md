---
uri: monograph-review/docs/development-environment
type: guide
title: "Development Environment — local R, gates, and verification"
owner: edphos
created: 2026-08-29
status: living
---

# Development Environment

*How to run this repository's R stack locally. Written after the local R
was located on the agent host (2026-08-29) — before that, CI was treated
as the only runner and the README's `renv`-based reproduction steps were
aspirational, not operational.*

## The short version

Local R **is** available on this host. It is in a non-standard place
(miniforge conda tree). All four gates can run locally in minutes.

```bash
export PATH="$HOME/.openclaw/tools/miniforge3/bin:$PATH"   # or /data/R/miniforge/bin
cd <repo>
R CMD INSTALL --no-docs --no-multiarch --with-keep.source .
Rscript run_tests.R unit        # or: simulacra / integration / regression / (all)
```

CI remains authoritative, but a local run catches things the committed
package would actually fail — which is how the stale-NAMESPACE bug was
found (below).

## Finding R

The R binary is installed via miniforge, not the system path. Known
locations (all R 4.5.3, 2026-03-11 "Reassured Reassurer"):

- `$HOME/.openclaw/tools/miniforge3/bin/R` and `.../bin/Rscript`
- `/data/R/miniforge/bin/R` (the 1 TB volume copy)
- `/home/node/.openclaw/tools/miniforge3/pkgs/r-base-4.5.3-*/lib/R/bin/R`

Add the bin dir to `PATH` before calling R or `Rscript`:

```bash
export PATH="$HOME/.openclaw/tools/miniforge3/bin:$PATH"
```

## First-time setup (once per checkout)

1. **Install the package** from source so internal functions resolve via
   `test_local()`:

   ```bash
   R CMD INSTALL --no-docs --no-multiarch --with-keep.source .
   ```

   (The runner calls `test_local(".", ...)` — pkgload-based — so a bare
   `library(valence.foundry)` is *not* the right invocation for the suite.)

2. **Install `minpack.lm`** (needed by `fit_biexp`'s Levenberg-Marquardt
   path). Without it, 12 unit tests fail because the base-R fallback
   optimizer is not equivalent. Install once:

   ```bash
   Rscript -e 'install.packages("minpack.lm", repos="https://cloud.r-project.org")'
   ```

   `minpack.lm` is used via `requireNamespace` guards, so the package
   *loads* without it — which is exactly why the failures were silent
   until the suite was run.

3. **Run a gate.** Results are tallied by expectation class
   (pass/fail/skip); a gate fails on any failure **or** error.

## The gates (what each verifies)

| Gate | Runner | Filters | Purpose |
|------|--------|---------|---------|
| unit | `Rscript run_tests.R unit` | `test-unit-*` | Mathematical correctness, contracts, data loaders, viz |
| simulacra | `Rscript run_tests.R simulacra` | `test-simulacrum-*` | Parameter recovery, null rejection, STDD |
| integration | `Rscript run_tests.R integration` | `test-integration-*` | BDD pipeline scenarios + pipeline.yml manifest conformance |
| regression | `Rscript run_tests.R regression` | `test-regression-*` | Pipeline output vs baseline oracle |

`Rscript run_tests.R` with no argument runs the whole suite.
`run_tests.R` hard-errors if a known gate matches zero test files (the
"no silent no-op" guard).

## Current local results (2026-08-29, after NAMESPACE fix)

| Gate | Passed | Failed | Skipped |
|------|--------|--------|---------|
| unit | 671 | 0 | 1 |
| simulacra | 266 | 0 | 0 |
| integration | 13 | 0 | 1 |
| regression | 15 | 0 | 7 |
| **full suite** | **8417** | **0** | **11** |

Skipped = data-reconciliation items (see `docs/review/session-handoff.md`)
and environment-conditioned skips, not silent passes.

## Why this mattered: the stale-NAMESPACE bug

The committed `NAMESPACE` was one generation behind the source: the five
P-series exports (`p1_buchnera_two_component`, `p2_ltee_niche_fba`,
`p3_plastid_erosion_order`, `p4_echolocation_centrality`,
`p5_c4_integration_depth`) were `@export`-tagged in
`R/p_series_a_priori.R` and declared in `pipeline.yml`, but absent from
`NAMESPACE`. The integration gate's manifest-conformance test
(`test-integration-pipeline.R`) caught it the moment the suite ran
locally — the docs claimed integration was green, but the committed
package would have failed it in CI. Fix:

```r
roxygen2::roxygenise()   # regenerates NAMESPACE + man/, drops orphaned vi_*.Rd
R CMD INSTALL --no-docs --no-multiarch --with-keep-source .
```

**Rule:** if `R/*.R` roxygen comments change, re-run `roxygenise()` and
commit the regenerated `NAMESPACE`/`man/` in the same change, or the same
drift recurs silently.

## Also noted in this pass

- The README's "How to Reproduce" (`renv::restore()` + `make all`)
  references a `renv` environment that does not exist in this repo (no
  `renv/`, no `renv.lock`). The `make` targets and `run_tests.R` are the
  real entry points; `renv::restore()` is not operational here. See
  `docs/standards/DEPENDENCY_STRATEGY.md` for the intended dependency
  discipline; the repo currently relies on CI's container
  (`rocker/tidyverse:4.5.3`) plus the local miniforge R for the missing
  pieces (`minpack.lm`).
