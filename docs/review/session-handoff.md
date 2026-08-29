---
uri: monograph-review/docs/review/session-handoff
type: handoff
title: "Foundry Software Session Handoff — current state, next actions"
owner: edphos
created: 2026-08-29
status: living
branch: fix/t15-boundary-probe
---

# Foundry Software Session Handoff

*Compact state card for continuing the software work in a fresh session or
topic. Repo is the source of truth; this doc tells the next session exactly
where the code work stands and what to do next. Public language, claim-
evidence standard: every line below is the current stated-and-tested state,
not aspiration.*

## Where the work lives

- **Repo:** `phosphene/monograph-review` (GitHub)
- **Branch:** `fix/t15-boundary-probe` (pushed; work continues here)
- **Package:** `valence.foundry` — R package, production-grade artifacts for
  the monograph review
- **Tests:** 39 test files under `tests/testthat/`
- **CI:** GitHub Actions — 7 gates (`run_tests.R`), container
  `rocker/tidyverse:4.5.3`. **No local R on the agent host — CI is the
  runner.** Never claim a test passes without a CI green.
- **Standards:** public scientific language only; no private models/
  metaphors; no claim exceeds its stated-and-tested conditions
  (see `docs/standards/`, `docs/review/review-evaluation-standard.md`).

## Current state (verified 2026-08-29)

- Language scrub complete: all private terms removed from the corpus
  (docs, code comments, tests, archive). Zero "vintage", zero "VI"
  framework-acronym, zero private brand terms in authored text. Two
  bibliographic citations of the real Vintage imprint remain as data only.
- **Green gates:** unit suite, coverage ≥ 80% enforced, lint (non-blocking),
  integration, simulacra, CI/CD container verification — all complete/green.
- **Partially passing:** the calculation gate — 2 entries pass (T5,
  formal_model), T4 confirms the framework (niche subsumes Ne). **7 skips:**
  - T6 + L3 — **no bundled data** (Review Items 4–5)
  - T1, T2, T4, T7 — **data-version drift** where the science holds (Item 6)
  - T3 — **method misspecification** (Remark R6)

## The forward agenda (the actual code work)

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

1. `git fetch && git checkout fix/t15-boundary-probe` in the review repo.
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
