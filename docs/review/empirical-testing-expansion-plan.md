# valence-foundry Empirical-Testing Expansion Plan

**Author:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**License:** MIT
**Status:** Proposal — awaiting go/no-go per phase

---

## Purpose

The [`algorithms-and-findings.md`](algorithms-and-findings.md) survey closes by
naming three modules that are "validated as testable but not yet tested":

1. **The *Homo* inversion** (positive diversity-dependence) —
   `diversity_dependence_sign()` / `autocatalytic_closure()`.
2. **Cusp irreversibility** (hysteresis) — `cusp_hysteresis_check()`.
3. **Cross-kingdom parameter transfer** (L3) — `transfer_test()`.

Each is validated on synthetic data (simulacrum: known parameters recovered,
null rejected) but has **no enforced empirical test**. This plan proposes the
refactoring that moves them from "testable" toward "tested" — and is explicit
about where that movement is real and where it is blocked by data we do not
have.

---

## The honesty boundary (read first)

"Testable but not tested" has two different causes, and the plan treats them
differently. Conflating them would overclaim.

| Module | Blocker | Can it become a real empirical test? |
|--------|---------|--------------------------------------|
| **L3 cross-kingdom** | **Data** (two datasets) + a latent wiring bug | **Yes** — once Items 4 & 5 are bundled and the wiring is fixed. Most tractable. |
| ***Homo* inversion** | **Data** (hominin diversification series) + no bifurcation parameter estimates (Review Item 3) | **No** — not without external data the foundry does not own. Drop-in hook + methodological enforcement only. |
| **Cusp irreversibility** | **Empirically hard** — a true test needs a real system measured on *both* forward and reverse paths; no such experiment exists for capacity reallocation | **No** — quantitative metric + methodological enforcement only. Proxies on existing data are confounded (see Q3). |

**What this plan does NOT do:** it does not manufacture paleontological,
island-bird, or experimental-evolution data. For the *Homo* inversion and the
cusp, the plan makes the instrument **drop-in ready** and **methodologically
enforced**; it does not claim they become empirically tested. Only **L3** can
become a real empirical test, and only after the two missing datasets are
sourced (Review Items 4–5) — the plan fixes the wiring and contracts so that
sourcing the data is a one-step unblock.

A concrete wiring bug was found while writing this plan and is the subject of
Phase 1; it is recorded here because it changes what "bundle the bird data"
actually requires.

---

## The L3 wiring bug (found during this review)

The L3 regression/pipeline stage is **mis-wired on the plant side**, and the
bug is **masked** by the bird-data check happening first.

Today the runner is:

```r
cross_kingdom_l3 = function() {
  if (!has_data("island_bird_morphology.csv")) stop("island-bird data not bundled (items 4-6)")
  plant <- load_orobanchaceae()              # species-level plastome data
  bird  <- load_island_birds()
  transfer_test(plant$data, bird$data, seed = 42)$values
}
```

But `transfer_test()` → `fit_plant_model()` → `validate_gene_categories()`,
which **requires gene-category data** (`category`, `dependency_score`,
`*_loss_rank`). `load_orobanchaceae()` returns species-level plastome data
(`species`, `plastome_size_bp`, `parasitism_score`, …) — **none** of the
required columns. Verified:

```
orobanchaceae columns: species, genus, accession, plastome_size_bp,
                       parasitism_category, parasitism_score, plastome_size_kb
transfer_test(plant$data, bird, ...) → "data missing required columns:
                                       category, dependency_score"
```

The skip reason today reads "island-bird data not bundled (items 4-6)". That is
**incomplete**: even if the bird data were bundled, the stage would immediately
fail plant-side validation. The L3 plant side needs the **gene-category**
dataset — the *same* dataset T6 needs (Review Item 4). So:

> **L3 is blocked by Items 4 AND 5, not Item 5 alone, and has a latent wiring
> bug.** Bundling the bird data without also (a) bundling the gene-category
> dataset and (b) re-wiring the plant side would convert one skip into a
> validation error, not into a passing test.

---

## Recommendations at a glance

| Phase | What it adds | Modules | Risk | Empirically tested after? |
|-------|--------------|---------|------|---------------------------|
| 1 — Fix L3 wiring + contracts | Correct plant-side wiring; shared `load_gene_categories()`; bird schema contract; honest skip reasons | L3 (+ T6) | low | L3: **yes**, once Items 4+5 bundled |
| 2 — Drop-in empirical hooks | `homo_inversion_test()` + `cusp_irreversibility_test()` wrappers + loaders + skip-honest regression entries | Homo, cusp | low | **No** — drop-in ready, skip-honest until data |
| 3 — Quantitative magnitude metrics | `hysteresis_loop_area`; `diversity_dependence_contrast()`; `slope_sign_transfers` | Homo, cusp, L3 | low-medium | Methodologically enforced (magnitude, not just direction) |
| 4 — Regression-gate enforcement | Oracle entries for simulacrum known-parameters → enforced regression targets | all three | low | "Testable" → "enforced against regression" |

**What we will NOT do now** (documented, not done):
- Source hominin diversification data, island-bird morphology data, or
  experimental forward/reverse evolution data. Those are data-owner tasks
  (Review Items 3–5).
- Add a bimodality or jump-detection "proxy" for the cusp on existing data.
  The endosymbiont/plastome data is cross-sectional across unrelated lineages
  (Remark R6), so bimodality at a given control value would reflect different
  ancestral states, not fold bifurcation. The proxy is confounded and is
  **not** recommended (see Open Question Q3).

---

## Phase 1 — Fix L3 wiring + contracts (low risk, high value)

### 1a. Correct the L3 plant-side wiring

**Change.** The L3 stage feeds species-plastome data into a function that
needs gene-category data. Re-wire it to use the gene-category dataset (the same
one T6 needs, Review Item 4). Add a `load_gene_categories()` loader (1b) and
point both T6 and L3's plant side at it. Until Item 4 is bundled, the skip
reason must read "blocked by items 4 AND 5" (not just 5), so the blocker is
honest.

**Blast radius.** `scripts/run_pipeline.R`, `tests/testthat/test-regression-baseline.R`,
`pipeline.yml` (the `cross_kingdom_l3` stage inputs). No math change.

**Risk.** Low. Wiring + skip-reason correction. The latent bug is currently
masked; this makes it visible and correct.

### 1b. Shared `load_gene_categories()` loader + contract

**Change.** Add a loader for the gene-category dataset
(`category`, `dependency_score`, `*_loss_rank`), with provenance documented in
`data/README.md`. Both T6 (`gene_loss_ordering`) and L3's plant side
(`fit_plant_model`) consume it. This advances Review Item 4: sourcing one
dataset unblocks two tests. Add a `validate_gene_categories()` contract test
that fails loud on wrong columns (it already exists; add a loader-level test).

**Blast radius.** `R/data_loaders.R` (new loader), `data/README.md`,
`tests/testthat/test-unit-data-loaders.R`, `pipeline.yml` (T6 + L3 inputs).

**Risk.** Low. The validator already exists; this is a loader + contract.

### 1c. `load_island_birds()` schema-contract test (drop-in readiness)

**Change.** Add a unit test that asserts the bird loader, when a file is
present, returns the exact schema `transfer_test` needs
(`structure`, `dependency_score`, `observed_rank`, n ≥ 5). Today the loader
exists but its contract is not tested against the downstream consumer. This
makes the bird data a one-step drop-in: source the file, the test enforces it
is shaped correctly.

**Blast radius.** `tests/testthat/test-unit-data-loaders.R`.

**Risk.** Low. Contract test only.

**Phase 1 exit gate.** L3 skip reason is honest ("items 4 AND 5"); the wiring
bug is fixed; the gene-category and bird loaders have enforced contracts; the
suite is green. When Items 4+5 are bundled, L3 becomes a passing enforced
`expect_equal` with no further code change.

---

## Phase 2 — Drop-in empirical hooks for the *Homo* inversion and cusp (low risk)

These modules have no empirical data infrastructure at all — no loader, no
regression entry, no skip. They are invisible to the regression gate. Phase 2
makes them **visible and skip-honest**: a thin wrapper + loader + regression
entry that `skip()`s with a precise reason until data is bundled. This converts
"not tested (silently)" into "tested-when-data-arrives, skip-honestly-until-then."

### 2a. `homo_inversion_test()` hook

**Change.** Add a thin wrapper `homo_inversion_test(species_through_time)` that
runs `diversity_dependence_sign()` on a hominin diversification series and
returns the DD sign + slope (the *Homo*-inversion signature). Add
`load_homo_diversification()` that `stop()`s honestly when no data is bundled.
Document the exact schema (`time`, `species_count`) and the target source
(a van Holstein & Foley (2024)-style *Homo* species-through-time curve). Add a
regression-gate entry that `skip()`s until data is bundled.

**Blast radius.** `R/autocatalytic_set.R` (wrapper), `R/data_loaders.R` (loader),
`baseline/oracle.yml` (entry, `supports_vi`/`distinguishes`), `pipeline.yml`,
`scripts/run_pipeline.R`, `tests/testthat/test-regression-baseline.R`,
`tests/testthat/test-unit-autocatalytic.R` (wrapper unit test on a fixture).

**Risk.** Low. The math is `diversity_dependence_sign` (already tested). The
wrapper + loader + skip is scaffolding that fails loud, not silent.

### 2b. `cusp_irreversibility_test()` hook

**Change.** Add a thin wrapper `cusp_irreversibility_test(forward_path,
reverse_path, control_values)` that runs `cusp_hysteresis_check()` on a real
system's measured forward and reverse paths. Document that this requires
experimental data with both paths measured (unavailable for capacity
reallocation); the regression entry `skip()`s honestly. The wrapper's contract
makes the data requirement explicit: a reader sees *exactly* what experiment
would fill it.

**Blast radius.** `R/cusp_catastrophe.R` (wrapper), `baseline/oracle.yml`,
`pipeline.yml`, `scripts/run_pipeline.R`, `tests/testthat/test-regression-baseline.R`,
`tests/testthat/test-unit-cusp-catastrophe.R`.

**Risk.** Low. Scaffolding + honest skip.

**Phase 2 exit gate.** Both modules have regression-gate entries that `skip()`
with precise data-requirement reasons (not silent no-ops). The unit tests cover
the wrappers on fixtures. The suite is green. The modules are drop-in ready.

> **Honesty note.** Phase 2 does **not** make these empirically tested. It
> makes the data requirement explicit and the skip honest. The *Homo* inversion
> remains blocked by Review Item 3 (no bifurcation parameter estimates) and the
> absence of a bundled hominin series; the cusp remains blocked by the absence
> of any forward/reverse experimental data.

---

## Phase 3 — Quantitative magnitude metrics (low-medium risk)

"Testable" is stronger when it enforces **magnitude**, not just **direction**.
Today the cusp reports a boolean (`has_hysteresis`) and the autocatalytic
module reports a sign. Phase 3 adds the quantitative measures that a real
empirical test would enforce, and locks them on the simulacra.

### 3a. Cusp — `hysteresis_loop_area`

**Change.** Add `hysteresis_loop_area` to `cusp_hysteresis_check()`: the
integral of `|forward − reverse|` over the control values (the standard
quantitative hysteresis measure — the area of the hysteresis loop). A real
irreversibility claim is "the loop area is large," not just "hysteresis
exists." Enforce a known value on the simulacrum (a = −1 → loop area ≈ X,
computed exactly from the cubic). This converts the boolean into a magnitude.

**Blast radius.** `R/cusp_catastrophe.R`, `tests/testthat/test-simulacrum-cusp.R`,
`tests/testthat/test-unit-cusp-catastrophe.R`, `baseline/oracle.yml` (cusp
entry, if added in Phase 4).

**Risk.** Low-medium. New metric; simulacrum must be re-validated. The loop
area is deterministic (pure function of the cubic + control grid), so the
target is exact.

### 3b. Autocatalytic — `diversity_dependence_contrast()`

**Change.** Add an explicit `diversity_dependence_contrast(autocatalytic_counts,
logistic_counts)` that runs `diversity_dependence_sign()` on both and asserts
the **sign flip** (positive on autocatalytic, negative on logistic) in one
place, with non-trivial magnitudes. The *Homo*-inversion claim is **contrastive**
— positive DD *where the competitor predicts negative*. This packages the
discriminating methodological core into one enforced test. (The pieces exist
across two simulacrum tests; this makes the contrast explicit and enforced.)

**Blast radius.** `R/autocatalytic_set.R`, `tests/testthat/test-unit-autocatalytic.R`,
`tests/testthat/test-simulacrum-autocatalytic.R`.

**Risk.** Low. Re-arrangement + explicit assertion of existing math.

### 3c. Cross-kingdom — `slope_sign_transfers`

**Change.** Add a `slope_sign_transfers` boolean to `transfer_test()`: `TRUE`
when the plant slope and the bird observed_rank are concordant in sign. This
makes the honest claim (math-review Issue 7: only the slope *sign* transfers)
a **reported value**, not just a docstring caveat. Enforce it on the
cross-kingdom simulacrum.

**Blast radius.** `R/cross_kingdom_transfer.R`, `tests/testthat/test-simulacrum-cross-kingdom.R`,
`tests/testthat/test-unit-cross-kingdom.R`, `baseline/oracle.yml`.

**Risk.** Low. The ranking already discards magnitude; this reports the
consequence honestly.

**Phase 3 exit gate.** The cusp reports loop area (magnitude); the
autocatalytic module has an enforced contrast test; the cross-kingdom test
reports sign-transfer honestly. Simulacra re-validated. Suite green.

---

## Phase 4 — Regression-gate enforcement of methodological targets (low risk)

Today the simulacrum known-parameters live in `baseline/simulacra-oracle.yml`
(descriptive) and are enforced by the **simulacrum test files**, not the
**regression gate**. Phase 4 promotes the three modules' methodological targets
to **enforced regression entries**: the known true parameters of each generator
become oracle values, and the regression gate enforces recovery. This locks the
methodological core against code regression — "testable" becomes "enforced."

### 4a. Autocatalytic regression target

**Change.** Add an `autocatalytic_methodology` oracle entry: known
`innovation_rate`/`capacity` → enforced `diversity_dependence_sign == "positive"`,
`is_superlinear == TRUE`, `achieves_closure == TRUE`, `closure_fraction`. The
regression runner generates from known params and asserts recovery.

### 4b. Cusp regression target

**Change.** Add a `cusp_methodology` oracle entry: known a = −1 → enforced
`has_hysteresis == TRUE`, `hysteresis_loop_area ≈ X`; a = +1 → enforced
`has_hysteresis == FALSE`, loop area ≈ 0.

### 4c. Cross-kingdom regression target

**Change.** Add a `cross_kingdom_methodology` oracle entry: known shared slope
0.6 → enforced `bird_rho > 0.7`, `slope_sign_transfers == TRUE`; independent
slope → enforced `null_p` large.

**Blast radius.** `baseline/oracle.yml`, `scripts/run_pipeline.R`,
`tests/testthat/test-regression-baseline.R`.

**Risk.** Low. Deterministic targets; lock-down only. These entries run on
synthetic data, so they always pass (no data blocker).

**Phase 4 exit gate.** The three modules have enforced regression entries
(methodological). The regression gate now reports 8+ pass (up from 5), and the
three modules' "testable" status is enforced against code regression.

---

## Cross-cutting: what "tested" means after this plan

| Module | Before this plan | After this plan | Empirically tested? |
|--------|------------------|-----------------|---------------------|
| L3 cross-kingdom | skip (silent; mis-wired) | wiring fixed; contracts enforced; skip honest ("items 4+5") | **Yes**, once Items 4+5 bundled |
| *Homo* inversion | not in regression gate at all | drop-in hook + contrast test + enforced methodological target | **No** — drop-in ready, methodologically enforced |
| Cusp irreversibility | not in regression gate at all | drop-in hook + loop-area metric + enforced methodological target | **No** — drop-in ready, methodologically enforced |

The plan's honest contribution: **L3 becomes a real empirical test (pending
data); the *Homo* inversion and cusp become drop-in ready and methodologically
enforced, with their data requirements made explicit and their skips honest.**
It does not claim to empirically test the two data-blocked modules.

---

## Suggested commit structure

One commit per phase (4 commits), or one per sub-item if preferred. Each
commit: code + tests + oracle + docs in lockstep, suite green on the branch
before push. Phase 1 first (fixes a real bug), then 2, 3, 4 — each is a
reviewable, shippable unit. Phase 4 can be deferred if the simulacrum test
files are judged sufficient enforcement (Open Question Q4).

---

## Open questions for review

1. **Phase 1** — bundle a real gene-category dataset now (advances Review Item
   4 and unblocks T6 + L3's plant side), or fix the wiring + contracts and
   leave the dataset to the data owner?
2. **Phase 2** — are the `homo_inversion_test()` and `cusp_irreversibility_test()`
   drop-in hooks worth adding now (they will `skip()` until data), or are they
   premature scaffolding better added when data is in hand?
3. **Cusp proxy (NOT recommended)** — attempt a bimodality or jump-detection
   proxy for the cusp on existing endosymbiont/plastome data? *This plan says
   no:* the data is cross-sectional across unrelated lineages (Remark R6), so
   bimodality at a given control value would reflect different ancestral
   states, not fold bifurcation. Confirm we should leave the cusp as
   methodologically-enforced-only.
4. **Phase 4** — promote the simulacrum known-parameters to enforced regression
   entries, or leave enforcement to the simulacrum test files (current state)?

If approved, I'll execute Phase 1 first (it fixes a real bug) and report before
proceeding to 2–4.
