---
title: "Toy Realms: A Speculative Simulation Capacity — Execution Plan"
author: "Ed Phillips ([@phosphene](https://github.com/phosphene))"
date: 2025-08-10
license: MIT
---

# Toy Realms — Execution Plan

> **Status: COMPLETE — all 4 realms built, tested, and documented.**
> Phases 1–4 are implemented in `R/speculative.R` (12 exported functions),
> with 56 unit tests in `test-unit-speculative.R` and a 4-section vignette
> (`vignettes/exploring-toy-realms.Rmd`). Suite green (598 pass / 0 fail / 9 skip).
> Each realm surfaced a finding or bug; see the per-phase risk sections below.

> **What this is.** An execution plan for building a speculative simulation
> capacity — four "toy realms" that let a reader *explore* the consequences
> of the valence framework across parameter space and hypothetical substrates.
> This is the actionable companion to the proposal in
> [`modeling-sim-viz-review.md`](modeling-sim-viz-review.md) Part III. It
> takes the proposal's four realms and turns them into phased, shippable
> work with concrete functions, files, tests, and exit criteria.
>
> **What this is not.** An empirical test. The toy realms do not source new
> data, do not claim to corroborate valence, and do not replace the blocked
> empirical work (Items 4–6). They are theoretical exploration — "if valence
> were true, what would we expect to see in worlds we have not measured?"
> — that sharpens the predictions for when the data arrives.

## Purpose

The empirical tests are blocked on data (Items 4–6). The formal model is a
theoretical ODE that cannot fail. Between these lies a gap the foundry can
fill without external data: a layer that makes valence's predictions *explorable*.
The existing simulacra generators already produce synthetic data from known
parameters; the viz layer already plots trajectories, bifurcations, and
growth curves. What is missing is a unifying **exploratory** layer that wraps
these into parameterized toy realms — each a self-contained "what if" world
with a simulator, a set of dials, and a visualization.

This plan builds that layer in four phases, one per realm, each independently
shippable. The suite stays green between phases.

## The honesty boundary (read first)

| The toy realms ARE | The toy realms ARE NOT |
|--------------------|------------------------|
| Theoretical exploration across parameter space | Empirical tests |
| Built from existing, validated components | New data collection |
| Sharper predictions for when data arrives | Claims of corroboration |
| A literate vignette (Layer 2) | A replacement for Items 4–6 |
| Honest about what experiment would fill each realm | The experiment itself |

Each realm names the experiment that would convert it from speculative to
empirical. The realms make the data requirements *precise* — a reader can see
exactly what dataset would test each prediction.

## Recommendations at a glance

| Phase | Realm | Reuses | Adds | Risk | Ship? |
|-------|-------|--------|------|------|-------|
| 1 | Genome-reduction explorer | `threshold_model()`, `plot_retention_trajectory()` | θ-sweep wrapper, `plot_threshold_gate()` | Low | **Yes — start here** |
| 2 | Irreversibility explorer | `cusp_hysteresis_check()`, `make_cusp_equilibrium_fn()` | `hysteresis_loop_area()`, `a`-sweep viz | Low-Medium | Yes |
| 3 | *Homo*-inversion explorer | `generate_autocatalytic_set()`, `diversity_dependence_sign()` | `diversity_dependence_contrast()`, endogenous-K sweep | Medium | Yes |
| 4 | Cross-kingdom transfer explorer | `generate_cross_kingdom_data()`, `transfer_test()` | GLM-transfer wrapper, transfer-breakdown viz | Medium | Yes (builds on R7) |

**Suggested order:** 1 → 2 → 3 → 4. Realm 1 is simplest and exercises the
threshold gate (the heart of valence). Realm 2 adds one new metric
(`hysteresis_loop_area`). Realm 3 adds the DD contrast and the endogenous-K
bifurcation (Review Item 3). Realm 4 builds on the R7 finding (the corrected
GLM) and is the richest. Each phase's exit gate is: suite green + the realm's
viz renders + a unit test asserts the exploration contract.

## Architecture

```
R/speculative.R              ← new module: all 4 realms' exploration functions
inst/toy_realms/             ← (optional) self-contained realm scripts
vignettes/exploring-toy-realms.Rmd  ← Layer 2 literate vignette
tests/testthat/test-unit-speculative.R  ← contract tests
```

All exploration functions are **pure** (DFT A1: no I/O) and **deterministic**
where possible (DFT A2). They return A6 proof objects (values + metadata) so
they compose with the existing pipeline and regression infrastructure. The
vignette is the Layer 2 deliverable required by
[`docs/standards/LITERATE_DOCS.md`](../standards/LITERATE_DOCS.md).

---

## Phase 1 — Genome-reduction explorer  ✅ DONE

### What it explores

Given a dependency architecture (a vector of integration depths for a
hypothetical organism's traits), a protection threshold θ, and shedding
parameters (λ, M₀, α), simulate the loss trajectory and visualize *which
traits shed when*. The reader can shift θ and watch the protected set change;
skew the dependency distribution and watch the loss ordering tighten or
loosen; push λ and watch Phase 1 compress.

### What it teaches

The threshold gate is the heart of valence's biphasic prediction. Seeing it
respond to θ across a sweep builds the intuition that the biphasic signal is
*the gate* (math-review Issue 3, resolved), not the displacement ratio. It
also makes the R6 method-misspecification visceral: a cross-sectional
regression across organisms with *different* θ would see noise, not a
logistic — which is exactly why T3 fails on real data.

### What it reuses

| Component | Source | Role |
|-----------|--------|------|
| `threshold_model()` | `R/formal_model.R` | The ODE simulator (depths, λ, θ, M₀, α, time) |
| `plot_retention_trajectory()` | `R/viz.R` | The trajectory plot |
| `threshold_biphasicity` | `R/formal_model.R` (Phase 2a metric) | The biphasic signal |

### What it adds

**`R/speculative.R`:**

```r
#' Sweep the protection threshold θ across a grid and return the biphasic
#' signal + loss ordering at each θ.
#'
#' @param depths Numeric vector. The dependency architecture.
#' @param theta_grid Numeric vector. θ values to sweep.
#' @param lambda, m0, alpha, time Numeric. ODE parameters (fixed).
#' @return A6: values = list of per-θ results; metadata = params + grid.
#' @export
sweep_threshold <- function(depths, theta_grid, lambda = 0.15,
                            m0 = 10, alpha = 0.05, time = 100) { ... }

#' Visualize the threshold gate: θ (x) vs threshold_biphasicity (y),
#' with the protected/unprotected split annotated at each θ.
#' @export
plot_threshold_gate <- function(sweep_result) { ... }
```

**`vignettes/exploring-toy-realms.Rmd`** — Section 1: "The threshold gate."

### Exit criteria  ✅ all met

- [x] `sweep_threshold()` returns an A6 proof object with per-θ results
- [x] `plot_threshold_gate()` renders a ggplot showing θ vs biphasicity
- [x] Unit test: sweeping θ from 0 to max(depths) shows biphasicity rising
      from ~0 to ~1 then falling back to ~0 (the gate opens then closes)
- [x] Vignette Section 1 renders with a worked example
- [x] Suite green (516 pass / 0 fail / 9 skip)

**Also fixed:** a latent edge-case bug in `threshold_model()` — the
all-protected case (θ ≤ min(depths)) crashed because `phase2_rate` was NaN
(mean of empty unprotected set) and the `if (phase2_rate > 0)` guard didn't
handle NaN. Added an `is.na()` guard. The all-protected case now returns
`threshold_biphasicity = NA` and `early_late_displacement_ratio = NA`
gracefully instead of crashing.

### The experiment that would fill this realm

A real organism with a known dependency architecture (gene categories +
integration-depth scores) and a measured retention trajectory across a
parasitism/commitment gradient. The θ-sweep would then be calibrated against
real data, and the gate's θ would be an empirical estimate, not a dial.

---

## Phase 2 — Irreversibility explorer  ✅ DONE

### What it explores

Given a cusp system (control parameter `a`, a path through `b`-space forward
and reverse), simulate the hysteresis loop and visualize the *loop area* as a
function of the path. The reader can sweep `a` from the monotone regime (no
bifurcation, loop area → 0) through the cusp region (bifurcation, loop area →
large) and watch irreversibility emerge.

### What it teaches

Irreversibility is valence's sharpest departure from gradual reversibility. The
explorer shows that irreversibility is *quantitative* (loop area), not just
boolean (`has_hysteresis`), and that it emerges discontinuously at the
bifurcation. It also makes the data requirement honest: no real
capacity-reallocation experiment has measured both paths, so the cusp remains
speculative — but the reader can see *what would count* as the test.

### What it reuses

| Component | Source | Role |
|-----------|--------|------|
| `cusp_hysteresis_check()` | `R/cusp_catastrophe.R` | The hysteresis detector (pure branch-following, Phase 3) |
| `make_cusp_equilibrium_fn()` | `R/cusp_catastrophe.R` | The equilibrium solver (needs export) |
| `plot_cusp_bifurcation()` | `R/viz.R` | The bifurcation plot (fixed in viz bug 2) |

### What it adds

**`R/speculative.R`:**

```r
#' Compute the hysteresis loop area: the area between the forward and
#' reverse equilibrium paths. Zero = no hysteresis; large = irreversible.
#'
#' Uses the trapezoid rule on the forward/reverse state sequences from
#' cusp_hysteresis_check().
#'
#' @param control_values Numeric vector. The control parameter path.
#' @param equilibrium_fn Function. Pure (control, prev_state) -> state.
#' @param seed Integer. Default 42.
#' @param initial_state Numeric. Starting state for the forward sweep.
#' @return A6: values = list(loop_area, max_difference, has_hysteresis);
#'         metadata = params + n.
#' @export
hysteresis_loop_area <- function(control_values, equilibrium_fn, seed = 42L,
                                 initial_state = 0) { ... }

#' Sweep the cusp parameter `a` across a grid and return the loop area at
#' each `a`. Shows irreversibility emerging at the bifurcation (a < 0).
#' @export
sweep_cusp_irreversibility <- function(a_grid, control_values, seed = 42L) { ... }

#' Visualize: `a` (x) vs loop_area (y), with the bifurcation set overlaid.
#' @export
plot_irreversibility_sweep <- function(sweep_result) { ... }
```

**`make_cusp_equilibrium_fn()`** — export it (currently internal; the
exploration functions need it).

### Exit criteria

- [ ] `hysteresis_loop_area()` returns an A6 proof object with `loop_area`
- [ ] `hysteresis_loop_area()` is 0 for `a = 1` (no bifurcation) and > 0 for
      `a = -1` (cusp region)
- [ ] `sweep_cusp_irreversibility()` + `plot_irreversibility_sweep()` show
      loop area rising from 0 as `a` crosses from positive to negative
- [ ] Unit test: loop area is monotonic in `|a|` for `a < 0`
- [ ] Vignette Section 2 renders
- [ ] Suite green

### The experiment that would fill this realm

A real system (a lineage, an ecosystem, an economy) where the control
parameter (parasitism depth, commitment, complexity) has been ramped both up
and down, with the state (genome size, capacity, diversity) measured at each
point. The loop area would then be an empirical quantity. No such experiment
exists for capacity reallocation; the realm makes this absence visible.

### Risk

`make_cusp_equilibrium_fn()` is currently internal (not exported). Exporting
it is a low-risk change (it's already used by the simulacrum tests and the
viz). The `hysteresis_loop_area()` metric was proposed in the
empirical-testing plan (Phase 3a) but not yet built; building it here (in the
speculative layer) is the natural home — it is a theoretical metric until the
empirical experiment exists.

---

## Phase 3 — The *Homo*-inversion explorer  ✅ DONE

### What it explores

Given a growth model (autocatalytic vs. logistic) and a diversification time
series, simulate the diversity-dependence sign and visualize the *contrast*
between valence (positive DD, the *Homo* inversion) and the competitor (negative
DD, niche-filling). The reader can toggle the growth model and watch
`diversity_dependence_sign` flip, and explore the endogenous-K bifurcation
(Review Item 3) by sweeping the cultural-feedback parameter.

### What it teaches

The *Homo* inversion is the framework's signature theoretical contribution
and its least empirically constrained (Review Item 3: no parameter estimates
from real systems). The explorer makes the *bifurcation* — the prediction
that there is a threshold in cultural complexity beyond which DD flips —
explorable. It cannot test this (no hominin diversification data), but it can
show *what the prediction looks like* and *what data would test it* (a
species-through-time series for *Homo* spanning the threshold).

### What it reuses

| Component | Source | Role |
|-----------|--------|------|
| `generate_autocatalytic_set()` | `inst/simulacra/generate_autocatalytic.R` | Positive-DD generator (fixed in Phase 2b) |
| `diversity_dependence_sign()` | `R/autocatalytic_set.R` | The DD sign detector (genuine metric, Phase 2b) |
| `plot_loglog_growth()` | `R/viz.R` | The log-log growth plot |

### What it adds

**`R/speculative.R`:**

```r
#' Compute the diversity-dependence contrast: the difference in per-capita-
#' rate-vs-N slope between autocatalytic (positive DD) and logistic (negative
#' DD) growth on matched time series. Positive = valence signature; negative =
#' competitor.
#'
#' @param n_steps Integer. Time series length.
#' @param innovation_rate, capacity Numeric. Generator params.
#' @param seed Integer.
#' @return A6: values = list(autocatalytic_dd_slope, logistic_dd_slope,
#'         contrast, sign); metadata = params.
#' @export
diversity_dependence_contrast <- function(n_steps = 20, innovation_rate = 0.3,
                                          capacity = 30, seed = 42L) { ... }

#' Sweep the endogenous-K feedback parameter (cultural complexity) and
#' return the DD sign at each level. Shows the bifurcation from negative
#' (niche-filling) to positive (Homo inversion) as feedback strengthens.
#' @export
sweep_endogenous_k <- function(feedback_grid, n_steps = 20, seed = 42L) { ... }

#' Visualize: overlay the autocatalytic and logistic trajectories + their
#' per-capita-rate-vs-N slopes in one figure. The sign flip is visible.
#' @export
plot_dd_contrast <- function(contrast_result) { ... }
```

### Exit criteria

- [x] `diversity_dependence_contrast()` returns A6 with positive contrast
      (autocatalytic DD slope > 0, logistic DD slope < 0)
- [x] `sweep_endogenous_k()` shows the DD sign flipping from "negative" to
      "positive" as the feedback parameter increases
- [x] `plot_dd_contrast()` renders the overlay
- [x] Unit test: contrast is positive for the default params; sign flips in
      the sweep
- [x] Vignette Section 3 renders
- [x] Suite green

### The experiment that would fill this realm

A hominin (or any cultural-species) diversification time series spanning the
putative complexity threshold: innovation counts or cultural-variant counts
through time, long enough to estimate the per-capita-rate-vs-diversity slope
on both sides of the threshold. No such dataset exists; the realm makes the
prediction and its data requirement concrete.

### Risk — and the formula bug it surfaced (resolved)

The endogenous-K sweep requires a *parameterized* generator that can vary the
feedback strength continuously. The plan proposed: per-capita rate =
r × (feedback + (1 − feedback) × N/(N+K)), where `feedback` ∈ [0, 1]
interpolates between logistic (feedback = 0, negative DD) and autocatalytic
(positive DD).

**This formula is wrong.** At feedback = 0 it gives r × N/(N+K), whose
derivative w.r.t. N is rK/(N+K)² > 0 — *always positive DD*. The function
N/(N+K) is increasing in N, so the blend is always increasing; it cannot
produce negative DD at any feedback value. It interpolates between two
positive-DD forms, not between logistic and autocatalytic.

**Corrected formula** (implemented): blend two bounded functions — one
increasing (autocatalytic), one decreasing (bounded logistic):

    pc_rate = r × [feedback × (0.5 + 0.5·N/(N+K)) + (1 − feedback) × K/(N+K)]

The analytical derivative is rK/(N+K)² × (1.5·feedback − 1): negative for
feedback < 2/3 (niche-filling), positive for feedback > 2/3 (*Homo*
inversion), zero at feedback = 2/3 (the bifurcation). At feedback = 1 this
reduces to r × (0.5 + 0.5·N/(N+K)), exactly matching the existing
`generate_autocatalytic_set()` dynamics (verified: identical time series).

The measured bifurcation (where the linear-regression DD slope crosses zero)
landed at feedback ≈ 0.666 — within 0.001 of the theoretical 2/3, validating
the corrected formula. The risk is now fully resolved; see the comment block
above `generate_dd_series()` in `R/speculative.R` and the Risk note section
in `diversity_dependence_contrast()`'s roxygen for the full analysis.

---

## Phase 4 — Cross-kingdom transfer explorer  ✅ DONE

### What it explores

Given a plant dependency architecture and a bird dependency architecture,
simulate the cross-kingdom transfer and visualize *when the transfer works
and when it breaks*. The reader can watch the logistic saturation reshape the
bird ordering, and see directly why the slope *magnitude* is discarded by
ranking (math-review Issue 7) — and when the logistic nonlinearity lets the
*model* (not just the sign) transfer.

### What it teaches

The cross-kingdom transfer is the monograph's strongest claim, and it is the
one the foundry flattened most (Issue 7: only the sign transfers). The toy
realm lets a reader see *why* — ranking is sign-only by construction — and
explore whether the GLM's logistic nonlinearity recovers genuine model
transfer. It also turns the broken-GLM finding (Remark R7) into a *lesson*:
the reader can reproduce the wrong-signed `b` by fitting the additive model
to misaligned data, then fix it with the correct flattening.

### What it reuses

| Component | Source | Role |
|-----------|--------|------|
| `generate_cross_kingdom_data()` | `inst/simulacra/generate_cross_kingdom.R` | Synthetic plant + bird data with known shared slope |
| `transfer_test()` | `R/cross_kingdom_transfer.R` | The sign-transfer test (reframed in Phase 2c) |
| `empirical_formal_model()` | `R/formal_model.R` (new, R7) | The corrected GLM with cross-kingdom prediction |
| `generate_synthetic_population()` | `inst/simulacra/` | Synthetic retention matrix generator |

### What it adds

**`R/speculative.R`:**

```r
#' Simulate cross-kingdom transfer via the corrected GLM (R7): fit
#' retention ~ dep + para to a synthetic plant matrix, predict bird
#' retention at a commitment level, rank, and compare to observed.
#'
#' Unlike transfer_test() (which transfers only the slope sign), this
#' transfers the full logistic model — so the ranking carries the model's
#' nonlinearity, not just the sign.
#'
#' @param plant_data Data frame. Synthetic retention matrix.
#' @param bird_data Data frame. Bird morphology.
#' @param para_for_transfer Numeric. Commitment level for prediction.
#' @return A6: values = list(plant_dep, plant_para, cross_kingdom_rho,
#'         model_rho, sign_only_rho); metadata = params.
#' @export
glm_transfer <- function(plant_data, bird_data, para_for_transfer = 3) { ... }

#' Sweep the plant noise level and show how the GLM transfer degrades
#' relative to the sign-only transfer. At low noise, the model transfer
#' outperforms (higher rho); at high noise, both converge to sign-only.
#' @export
sweep_transfer_robustness <- function(plant_arch, bird_arch, noise_grid,
                                      seed = 42L) { ... }

#' Visualize: noise (x) vs rho (y), with model-transfer and sign-only
#' transfer overlaid. Shows when the model beats the sign.
#' @export
plot_transfer_breakdown <- function(sweep_result) { ... }
```

### Exit criteria

- [x] `glm_transfer()` returns A6 with `cross_kingdom_rho` (model) and
      `sign_only_rho` (sign), with model ≥ sign
- [x] `sweep_transfer_robustness()` shows the model-transfer rho decaying
      toward the sign-only rho as noise increases
- [x] `plot_transfer_breakdown()` renders the overlay
- [x] Unit test: at zero noise, model rho > sign-only rho; at high noise,
      they converge
- [x] Vignette Section 4 renders
- [x] Suite green

### The experiment that would fill this realm

A real target-kingdom dataset with *varying* parasitism/commitment scores
(not just dependency scores): e.g., bird morphology data with a per-species
parasitism column, or a third substrate (economic specialization) with
varying commitment. The GLM transfer would then be empirical, and the
model-vs-sign gap would be a real, testable quantity. The foundry now has
the plant data (R7) and the bird data (bundled); the varying-parasitism
column is the open empirical frontier.

### Risk — and the finding it surfaced (resolved)

This phase builds on the R7 finding (the corrected GLM) and the bundled data.
The `glm_transfer()` function reuses the GLM fit from `empirical_formal_model()`
but adds a synthetic-data path (via a new internal generator,
`generate_transfer_data()`, rather than modifying
`generate_synthetic_population()` — which serves a different purpose in the
simulacra).

**Key design decision:** the synthetic bird data has *varying* parasitism
scores — this is the only way to make the model transfer differ from the
sign-only transfer. When para is constant (as in the real bird data),
`rank(logistic(a + b·dep + c·const)) = rank(dep)` if b > 0 — the transfer is
sign-only by construction. The varying para is what lets the model transfer
genuinely outperform.

**Seed-stream bug found and fixed:** the initial prototype used a single
`withr::with_seed()` for both plant and bird generation. At noise = 0,
`rnorm(n, 0, 0)` consumes no RNG draws, shifting the bird-data RNG state
relative to noise > 0 — so the bird data changed with the noise level,
confounding the sweep. Fixed by using separate seed streams (plant = seed,
bird = seed + 1000), making the bird data identical across noise levels and
isolating the effect of plant noise on the transfer.

**Honest finding (beyond the plan):** at extreme noise (beyond the default
grid, e.g. 0.4–0.5), the model transfer dips *below* the sign-only transfer.
The noisy para coefficient injects noise that the sign-only transfer (ignoring
para) avoids. The model transfer is not unconditionally superior — it pays a
noise penalty for using the para coefficient. This is documented in the risk
note of `sweep_transfer_robustness()` and in vignette Section 4.

---

## Cross-cutting: the vignette

`vignettes/exploring-toy-realms.Rmd` is the Layer 2 deliverable. It follows
the structure required by [`docs/standards/LITERATE_DOCS.md`](../standards/LITERATE_DOCS.md):

1. **Scientific motivation** — why exploration matters when empirical data is
   blocked
2. **Method overview** — the four realms and what each explores
3. **Worked example** — one realm per section, with dials + visualizations
4. **Limitations** — what the realms cannot establish (they are not empirical
   tests)
5. **Interpretation guide** — how to read each realm's output, and what
   experiment would convert it from speculative to empirical

The vignette is built incrementally: each phase adds one section. The
vignette is not a separate phase; it is the delivery vehicle for each phase's
exit criteria.

## Suggested commit structure

| Commit | Phase | Content |
|--------|-------|---------|
| 1 | 1 | `R/speculative.R`: `sweep_threshold()` + `plot_threshold_gate()` + unit tests + vignette §1 |
| 2 | 2 | `hysteresis_loop_area()` + `sweep_cusp_irreversibility()` + `plot_irreversibility_sweep()` + export `make_cusp_equilibrium_fn()` + unit tests + vignette §2 |
| 3 | 3 | `diversity_dependence_contrast()` + `sweep_endogenous_k()` + `plot_dd_contrast()` + generalized generator + unit tests + vignette §3 |
| 4 | 4 | `glm_transfer()` + `sweep_transfer_robustness()` + `plot_transfer_breakdown()` + unit tests + vignette §4 |

Each commit is independently shippable: the suite is green, the new functions
have unit tests, and the vignette section renders.

## Open questions for review (all resolved by implementation)

1. **Module location.** `R/speculative.R` (one module, all 4 realms) or
   `inst/toy_realms/` (separate scripts, like the simulacra generators)?
   **Resolved:** `R/speculative.R` — the realms are package functions, not
   generators, and are exported and unit-tested like the rest of the package.

2. **Generalized autocatalytic generator.** Phase 3 needs a parameterized
   feedback generator. Should it replace `generate_autocatalytic_set()` or be
   a new function? **Resolved:** new internal function `generate_dd_series()`
   — the existing generator is unchanged (tested and works); the new one adds
   the feedback dial. At `feedback = 1` it matches the existing generator
   exactly (verified).

3. **Synthetic retention matrix.** Phase 4 needs a synthetic retention matrix
   (species × genes) for the GLM transfer. **Resolved:** new internal
   function `generate_transfer_data()` — the existing
   `generate_synthetic_population()` produces a flat panel, not a matrix; a
   matrix generator is a different shape.

4. **Vignette vs. inst/examples.** **Resolved:** vignette only — the toy
   realms are exploration, not analysis; a vignette is the right home.

5. **All four or start with one?** **Resolved:** built all four, one phase
   at a time. Each phase was independently shippable; the decision to
   proceed was made after each phase passed its exit criteria.

## Findings surfaced by implementation

Each realm surfaced a finding or bug that sharpened the understanding of the
Valence framework's testability:

| Realm | Finding |
|-------|---------|
| 1 (threshold gate) | Fixed a latent edge-case bug in `threshold_model()` (all-protected θ ≤ min(depths) → NaN phase2_rate). The gate is sharp: below θ, retention collapses to ~0; above, it's ~1. |
| 2 (irreversibility) | Loop area is robust to `initial_state` — the metric depends only on the system (`a`), not the observer's starting point. Irreversibility is quantitative (loop area), not boolean. |
| 3 (Homo inversion) | The plan's proposed feedback formula was **wrong** (always positive-DD). Corrected formula blends autocatalytic + bounded-logistic; bifurcation at feedback = 2/3, measured at 0.666. The Homo inversion is a DD sign flip, not just a growth direction. |
| 4 (cross-kingdom transfer) | Issue 7 (ranking discards magnitude) is visible as a **gap between two curves**. The model transfer outperforms sign-only at low noise, converges at high noise, and can dip below at extreme noise (noisy para hurts). The real bird data makes the empirical transfer sign-only by construction (no varying para). |
