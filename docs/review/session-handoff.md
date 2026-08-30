---
uri: monograph-review/docs/review/session-handoff
type: handoff
title: "Foundry Software Session Handoff — current state, next actions"
owner: edphos
created: 2026-08-29
status: living
branch: fix/e1-coverage-gate
---

# Foundry Software Session Handoff

*Compact state card for continuing the software work in a fresh session or
topic. Repo is the source of truth; this doc tells the next session exactly
where the code work stands and what to do next. Public language, claim-
evidence standard: every line below is the current stated-and-tested state,
not aspiration.*

## Where the work lives

- **Repo:** `phosphene/monograph-review` (GitHub)
- **Branch:** `fix/e1-coverage-gate` (E1, PR #22); E2 merged to `main` via PR #21
- **Package:** `valence.foundry` — R package, production-grade artifacts for
  the monograph review
- **Tests:** 44 test files under `tests/testthat/` (E1 added 4 contract-test files: 201 assertions)
- **CI:** GitHub Actions — 8 gates (`run_tests.R`), container
  `rocker/tidyverse:4.5.3`.
- **Local R IS available** (found 2026-08-29): R 4.5.3 via miniforge at
  `~/.openclaw/tools/miniforge3/bin/R` (also `/data/R/miniforge`).
  `export PATH=~/.openclaw/tools/miniforge3/bin:$PATH` before R calls.
  Install `minpack.lm` once (required for `fit_biexp`; without it 12 unit
  tests fail on the base-R fallback optimizer). Package is NOT installed —
  `R CMD INSTALL .` after checking out, then `Rscript run_tests.R <gate>`.
  CI remains authoritative; local runs catch things CI documents as green
  but that the committed package would actually fail (see the NAMESPACE
  fix below).
- **Standards:** public scientific language only; no private models/
  metaphors; no claim exceeds its stated-and-tested conditions
  (see `docs/standards/`, `docs/review/review-evaluation-standard.md`).

## Current state (verified 2026-08-30)

- **Language scrub complete:** all private terms removed from the corpus
  (docs, code comments, tests, archive). Zero "vintage", zero "VI"
  framework-acronym, zero private brand terms in authored text. Two
  bibliographic citations of the real Vintage imprint remain as data only.
- **E2 — invariants suite revived (DONE, merged PR #21, `ce7b6bc`).**
  `test-invariants-empirical.R` re-enabled after fixing a return-contract drift in the
  PGLS synthetic generator (documented `list(data, tree)` vs a bare data.frame → every call
  died in validation) plus a seed-locked monotone DGM for the transfer invariant and full lint
  cleanup (commented-code + five pre-existing line-length lints). Two vignette contract drifts
  that were failing `R CMD check` were also fixed (`as_valence_autocatalytic_result` counts;
  `retention_at_time` return shape), closing the check gate.
- **E1 — coverage gate (DONE, PR #22).** Four contract-test files (201 assertions) lift the
  under-covered modules past the ≥80% gate: `p_series_a_priori.R` 19.4% → 100%,
  `dynamics_classes.R` 49.7% → 96.0%, `formal_model_classes.R` 50.6% → 91.4%,
  `test_registry.R` 64.1% → 94.7%; overall 83.98% → **93.25%**. Two real robustness bugs
  surfaced and fixed: `p3_plastid_erosion_order` crashed on constant dependency score (now NA
  fallback), and the autocatalytic validator rejected its own documented `"inconclusive"`
  fallback.
- **Green gates (local, 2026-08-30, CI-matching R 4.5.3):** full suite green (exit 0), all
  eight CI gates green on the E1 head. CI gates: lint, unit (coverage ≥ 80%), simulacra,
  integration, regression, R CMD check, Pages, summary.
- **Coverage:** 93.25% overall; every shipped module ≥ 80% except the package load hook
  (`zzz.R`), which is a pre-existing non-ticket 0% (`.onLoad`).
- **Latent bug fixed earlier (2026-08-29):** committed `NAMESPACE` was stale — missing the 5
  P-series exports (`p1_buchnera_two_component` … `p5_c4_integration_depth`) that
  `pipeline.yml` declares. Fixed by `roxygen2::roxygenise()` (commit `725a674`); ~140 orphaned
  `vi_*.Rd` removed. If docs are ever edited, re-run roxygenise or the same drift recurs.
- **Partially passing:** the calculation gate — 2 entries pass (T5,
  formal_model), T4 confirms the framework (niche subsumes Ne). **7 skips:**
  - T6 + L3 — **no bundled data** (Review Items 4–5)
  - T1, T2, T4, T7 — **data-version drift** where the science holds (Item 6)
  - T3 — **method misspecification** (Remark R6)

## The forward agenda (the actual code work)

### Self-calibration program — next ticket

**C6 — Monte Carlo error and replication-count discipline** is next (then C1 → C2 → C5 →
C4 → C7 → C3 → C8 → E3). E1 (coverage gate) and E2 (invariants revive) are done; see
README's calibration-program status block.

### A. The three "testable but not yet tested" modules
(from `empirical-testing-expansion-plan.md` — phases 1–4, commit-structure and
open questions Q1–Q4 inside):

1. **L3 cross-kingdom parameter transfer** (`transfer_test()`) — blocked by
   **two datasets** (Items 4 & 5) **and** a latent **wiring bug**
   (`predict_bird_ordering`/plant side). **Most tractable.** Phase 1: fix the
   wiring + contracts, add `load_gene_categories()`, point T6 and L3 at it.
2. ***Homo* inversion** (`diversity_dependence_sign()`) — blocked by
   external hominin diversification data the foundry does not own. Drop-in
   empirical hook + methodological enforcement only (Phase 2).
3. **Cusp irreversibility** (`cusp_hysteresis_check()`) — empirically hard;
   needs a real system measured forward and reverse. Quantitative metric +
   methodological enforcement only (Phases 2–3).

### B. Data reconciliation (Review Items 4–6)
The reason gates skip. Sourcing the missing datasets (gene-category matrix
for T6, `island_bird_morphology.csv` for L3) and pinning oracle values to the
bundled data versions would flip skips into enforced assertions.

### C. Refactoring plan
`docs/review/refactoring-plan.md` — seven math-review issues (two severe),
three phases, safest-first.

## How to pick up (first 30 minutes of a session)

1. `git fetch && git checkout main` in the review repo.
2. Read `docs/review/README.md` (map), then
   `docs/review/foundry-phased-breakdown.md` (gate status) — the two orienting
   docs.
3. Read `docs/review/empirical-testing-expansion-plan.md` Phase 1 in full —
   it is the recommended next step.
4. Make a change → push → open PR → **wait for CI green** → report the gate
   result. A gate result that has not run is not a result.

## Agile handoff mechanism (for the next Jan-created topic)

When a new topic opens for continuing software work, the host drops this doc
into it (repo link + this file). It is designed so a fresh session can be
oriented and productive within one read — state, forward agenda, first-actions,
and the honesty boundary all in one place. Keep this file updated as gates flip;
a stale handoff is a broken handoff.
