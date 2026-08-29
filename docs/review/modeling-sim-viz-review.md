# the foundry Modeling, Simulation & Visualization Review — and a Speculative Simulation Proposal

**Author:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**License:** MIT

---

## What this document is

The [`algorithms-and-findings.md`](algorithms-and-findings.md) survey and the
[`empirical-testing-expansion-plan.md`](empirical-testing-expansion-plan.md)
both concluded that three modules (the *Homo* inversion, cusp irreversibility,
cross-kingdom transfer) are "validated as testable but not yet tested," and
that the remaining work is empirical data collection (blocked on the author).
This document recurses on what we *can* do without that data: it reviews the
**author's existing modeling** (as preserved in `archive/pre-foundry-scripts/`),
evaluates the **simulation and visualization infrastructure** (`R/viz.R`,
`R/simulacra_viz.R`, `R/simulacra_logging.R`, the simulacra generators, and
`scripts/render_pages.R`), and proposes a **speculative simulation capacity** —
a way to extend the framework hypothesis into toy models that explores the theory's
consequences without claiming empirical test.

The review found one significant modeling finding (the author's empirical
formal model was broken and the foundry hid this by replacing it with a
theoretical simulation), three latent viz bugs, and a viable path to a
speculative simulation capacity that is 80% built already.

---

## Part I — Review of the author's existing modeling

### The finding: the foundry replaced the author's broken empirical model with a clean theoretical simulation

The author's original formal model script
(`archive/pre-foundry-scripts/run_formal_model.R`) was an **empirical** model:
a quasibinomial logistic GLM, `retention ~ dep + para`, fit to a real 8-species
× 6-gene-category retention matrix (Lindenbergia through Conopholis; ndh through
rpl_rps; 48 observations). The foundry's `threshold_model()` is a
**theoretical** model: a deterministic ODE simulation (`dC/dt = -λMC`) with no
data fit at all. The refactoring replaced a fit-to-data with a simulation-of-
theory, and in doing so hid the fact that the fit-to-data was broken.

### The author's GLM, when run, does not support the framework

Reproducing the author's original script verbatim:

```
quasibinomial GLM: retention ~ dep + para  (48 obs)
  intercept (a) =  2.050  (p = 0.0151)
  dep       (b) = -0.828  (p = 0.0013)   ← the framework predicts b > 0; fit gives b < 0
  para      (c) = -0.138  (p = 0.5924)   ← not significant
  pseudo-R²     =  0.269
```

Three things are wrong:

1. **The dependency coefficient has the wrong sign.** the framework predicts `b > 0`
   (deeper integration → higher retention). The fit gives `b = −0.828 < 0`.
   The author's own script annotates this coefficient as
   `"b > 0: higher dependency → higher retention probability"` — the comment
   states the prediction; the fit contradicts it.

2. **The parasitism coefficient is not significant** (p = 0.59). The author's
   script claims "dep and para both significant" — the fit does not bear this
   out for `para`.

3. **The cross-kingdom transfer gives the wrong sign.** Applying the fitted GLM
   to the bird dependency scores at `para = 3` (the author's "deep commitment"
   analog) and ranking the predicted retentions:

   ```
   bird ρ (GLM transfer) = −0.755     ← oracle says +0.755
   ```

   The GLM predicts bird morphological change ordering with the **opposite**
   sign to the oracle. This is a direct consequence of `b < 0`: the logistic
   `logistic(a + b·dep + c·3)` is *decreasing* in `dep`, so high-dep traits
   get *low* predicted retention and are predicted to change *first* — the
   reverse of what is observed.

### Why the GLM is broken: it is misspecified

> **⚠ Correction (superseded).** The diagnosis below — that the GLM is broken
> because it is *misspecified* (additive where the framework predicts interaction) — was
> **incomplete**. The root cause is a **data-flattening bug**: the author's
> script uses `as.vector(t(retention))` (species-major) where it should use
> `as.vector(retention)` (gene-major), scrambling `dep` ↔ `retention`. With
> the one-character fix, the additive GLM gives `dep = +0.84` (p = 0.0008),
> `para` p < 0.0001, and cross-kingdom ρ = +0.755 — all matching the framework's prediction. The
> additive specification is adequate; the interaction is theoretically
> preferred but not needed for the sign. See
> [`formal-model-reproduction.md`](formal-model-reproduction.md) for the full
> corrected analysis. The broader finding — that the foundry hid the broken
> GLM by replacing it with a non-empirical ODE — stands and is strengthened:
> the foundry replaced a *fixable one-character bug* with a simulation that
> cannot fail.

The framework's prediction is an **interaction**: dependency depth matters *more* at
higher parasitism (deeper commitment). At `para = 0` (autotroph), every trait
is retained regardless of depth; at `para = 4` (holoparasite), only the
deepest trait survives. The author's GLM is **additive** (`dep + para`, no
interaction): it forces the log-odds ratio between two depths to be the same
at every parasitism level. The data violate this — depth has zero effect at
`para = 0` and a large effect at `para = 4` — so the additive model averages
across regimes and the averaged coefficient comes out wrong-signed.

The deeper problem is **separation**: the autotroph row (`para = 0`,
retention = 1.0 for all depths) produces infinite logits, which destabilize
the quasibinomial fit. The GLM is not just misspecified; it is unfit for this
data shape. The author's script did not diagnose this because it printed the
coefficients and the author's annotation ("b > 0") without checking the sign
of the actual fit.

### What the foundry did, and why it hid the problem

The foundry's `threshold_model()` is a deterministic Euler integration of
`dC/dt = -λ·M(t)·C·𝟙(d < θ)`. It takes `(λ, θ, M₀, α)` as *given* parameters
and produces retention trajectories. It **never fits** these parameters to
data — they are oracle inputs (`λ = 0.15, θ = 2.5, M₀ = 10, α = 0.05`). The
model cannot fail to support the framework because it is a simulation of the framework: given the framework's
equation, it produces the framework's prediction. This is legitimate as a *theoretical*
model (it shows the equation produces the predicted biphasic gate), but it is
not an *empirical* test.

By replacing the GLM with the ODE, the foundry:
- **Lost the empirical content.** The 8×6 retention matrix (real data: 0.0,
  0.5, 0.67, 0.72, 0.78, 0.80, 1.0 values across real species and genes) is
  not bundled in `data/` and not used by any foundry function.
- **Lost the cross-kingdom GLM transfer.** The author had a *stronger*
  cross-kingdom test (`run_formal_model.R` Step 4): the fitted GLM's nonlinear
  logistic predictions, ranked, carry model information beyond the raw
  dependency ranking (the logistic saturation reshapes the ordering). The
  foundry adopted the *weaker* version (`run_cross_kingdom_L3.R`:
  `lm(loss_rank ~ dep)` + Spearman), which — as math-review Issue 7 found —
  discards the slope magnitude entirely.
- **Hid the wrong sign.** The GLM's wrong-signed `b` and wrong-signed
  cross-kingdom ρ are invisible in the foundry because the foundry never runs
  the GLM. A reader of the foundry sees a clean ODE that produces the right
  answer; they do not see that the empirical model it replaced produced the
  wrong answer.

### The honest reading

The author's empirical formal model (the GLM) is **misspecified and broken**:
wrong sign on `dep`, non-significant `para`, wrong-signed cross-kingdom
transfer. The foundry's theoretical formal model (the ODE) is **correct but
non-empirical**: it simulates the theory, it does not test it. Neither is an
empirical test of the framework. The 8×6 retention matrix is real data that should be
bundled, and the right empirical model is an **interaction** GLM
(`retention ~ dep * para`) or — better — a direct fit of the threshold model's
parameters (λ, θ) to the retention matrix, which is exactly the "direct fit of
the formal threshold model to the data" option flagged in Remark R6 for T3.

This is recorded here, not acted on, because (a) the empirical-testing
expansion is deferred pending the author's data, and (b) the right response is
the speculative simulation capacity proposed in Part III, which makes the
theory's consequences explorable without depending on the broken GLM.

---

## Part II — Evaluation of the simulation and visualization infrastructure

### What exists

The simulation and visualization stack has four layers:

1. **Simulacra generators** (`inst/simulacra/`, 5 files) — generate synthetic
   data from known parameters (STDD parameter-recovery). Reviewed in
   `algorithms-and-findings.md` Part IV; sound.
2. **Empirical viz** (`R/viz.R`, 1,513 lines, 13 `plot_*` functions) — one
   publication-quality ggplot2/patchwork plot per empirical test (T1–T7), the
   formal model, the cusp, the autocatalytic set, L3, and the baseline oracle
   forest plot.
3. **Simulacrum viz** (`R/simulacra_viz.R`, 305 lines, 5 functions) —
   true-vs-recovered scatter, recovery trajectory, parameter-space projection,
   rolling recovery rate, and a multi-page PDF report.
4. **Mark logging** (`R/simulacra_logging.R`, 124 lines) — YAML mark files
   capturing true/recovered parameters per simulation, consumed by the
   simulacrum viz.
5. **Pages renderer** (`scripts/render_pages.R`, 639 lines) — a self-contained
   GitHub Pages HTML site (simulacra overview + plots + baseline oracle forest
   + key results), with base64-embedded PNGs and inline CSS.

### What is sound

- The empirical viz functions are pure (A1: data in, ggplot out) and return
  inspectable objects (A6). The T1–T7 plots are well-constructed: the PGLS
  plot overlays a phylogeny, the biphasic plot compares three curves with
  ΔAICc, the gene-loss heatmap orders rows by dependency. The forest plot is a
  clear pass/fail communication.
- The simulacrum viz design (true-vs-recovered on the y=x diagonal; null
  scatter off-diagonal) is the right communication of parameter recovery.
- The pages renderer degrades gracefully (placeholder sections when no marks
  exist) and always renders the baseline oracle from the committed YAML.

### What is broken or latent

Three latent bugs and one dead-code path, all in the viz layer:

#### Viz bug 1 — `plot_retention_trajectory()` references the renamed `k1_k2_ratio` (latent NA annotation)

`R/viz.R:903` reads `model_result$values[["k1_k2_ratio"]]`, which was renamed
to `early_late_displacement_ratio` in Phase 2a of the math refactoring. The
field no longer exists, so `k1_k2` is `NULL`, and the annotation
`sprintf("k₁/k₂ = %.1f", k1_k2)` (line 933) renders as `k₁/k₂ = NA`. The unit
test passes because it only asserts `expect_s3_class(p, "ggplot")`, not the
annotation content. Verified:

```
values names: ..., early_late_displacement_ratio, threshold_biphasicity
k1_k2_ratio: NULL (renamed)
plot builds: OK — but the k1/k2 annotation is NA
```

**Fix:** reference `early_late_displacement_ratio` (and optionally also
annotate `threshold_biphasicity`, the genuine biphasic signal). Add a unit
assertion on the annotation value, not just the class.

#### Viz bug 2 — `plot_cusp_bifurcation()` has dead code and an ad-hoc hysteresis protocol

Two sub-issues:

**(a) Dead code.** `R/viz.R:1032` defines `forward_state <- function(x) { ... }`
that is never called — a leftover from an abandoned approach. Confirmed: the
function is defined but the only references are to `forward_states` (the
numeric vector), not `forward_state` (the function).

**(b) The hysteresis loop uses an ad-hoc protocol inconsistent with
`cusp_hysteresis_check()`.** The viz's Panel B computes forward and reverse
paths by Newton's method, but **both sweeps start from `x_guess = 0`** (lines
1047, 1055) — not from the forward sweep's final state. This is the *viz
analog of math-review Issue 4*: the loop appears (max |fwd − rev| ≈ 1.4,
verified), but for the wrong reason (the two sweeps start from different ends
and converge to different branches from `x = 0`), not from path dependence
carried through a shared start. The `cusp_hysteresis_check()` contract
established in Phase 3 — reverse starts from forward's final state — is not
reflected in the viz.

**Fix:** delete the dead `forward_state` function; make the viz's reverse
sweep start from the forward sweep's final state, matching
`cusp_hysteresis_check()`. (Or, better: have the viz *call*
`cusp_hysteresis_check()` with `make_cusp_equilibrium_fn()` and plot its
output, rather than recomputing the loop with a homebrew solver.)

#### Viz bug 3 — The simulacrum mark pipeline is dead code in practice

`R/simulacra_logging.R` (`init_mark_log`, `mark`, `read_marks`,
`read_all_marks`) and `R/simulacra_viz.R` (`plot_true_vs_recovered`, etc.,
`render_simulacra_report`) depend on mark YAML files being produced during
simulacrum runs. But `scripts/run_pipeline.R` **does not emit marks** — no
`init_mark_log()` or `mark()` call exists in the pipeline. The simulacrum
*tests* (`test-simulacrum-*.R`) also do not emit marks; they assert recovery
inline. So the entire mark-logging + simulacrum-viz layer is dead code in the
running pipeline. The `render_pages.R` renderer has a graceful-degradation
fallback ("no marks exist yet" → placeholder), which is why this is latent
rather than breaking.

This is not a bug per se — the marks are aspirational infrastructure — but it
means the "simulacra plots" section of the GitHub Pages site is currently
empty, and the 305 lines of simulacrum viz are unexercised by the pipeline.
**Fix (or decision):** either wire the simulacrum tests to emit marks (so the
viz has data to render), or document the mark layer as a future capability
and remove it from the renderer's promised sections.

### Summary of the viz evaluation

The empirical viz (T1–T7, forest plot) is sound and is the foundry's clearest
communication layer. The dynamics viz (retention trajectory, cusp
bifurcation, log-log growth) has two latent bugs (renamed field, ad-hoc
hysteresis) that the tests don't catch because they assert class, not content.
The simulacrum viz is well-designed but dead in the pipeline (no marks
emitted). The pages renderer is robust but renders placeholder simulacra
sections. None of this is blocking, but the latent bugs should be fixed so
the viz faithfully reflects the (refactored) math.

---

## Part III — A speculative simulation capacity: extending the framework to toy models

### The idea

The empirical tests are blocked on data. The formal model is a theoretical
simulation that cannot fail. Between these lies a gap the foundry can fill
without external data: a **speculative simulation capacity** that lets a
reader explore the *consequences* of the framework under review across parameter space
and across hypothetical substrates — "toy models." This is not empirical
testing; it is theoretical exploration. It asks: *if the framework were true, what would
we expect to see in worlds we have not measured?* The answer sharpens the
predictions and, when the data arrives, makes the empirical tests more
discriminating.

The foundry is 80% of the way there. The simulacra generators already produce
synthetic data from known parameters; the viz layer already plots
trajectories, bifurcations, and growth curves. What is missing is a unifying
**exploratory** layer that wraps these into parameterized, interactive toy
realms — each a self-contained "what if" world with a simulator, a set of
dials, and a visualization.

### Four toy models

#### Toy model 1 — Genome-reduction explorer

**What it explores.** Given a dependency architecture (a vector of integration
depths for a hypothetical organism's traits), a protection threshold θ, and
shedding parameters (λ, M₀, α), simulate the loss trajectory and visualize
*which traits shed when*. The reader can shift θ and watch the protected set
change; skew the dependency distribution and watch the loss ordering tighten
or loosen; push λ and watch Phase 1 compress.

**What it is built from.** `threshold_model()` (the ODE) +
`plot_retention_trajectory()` (the trajectory plot), wrapped in a function
that takes a dependency architecture and parameter set and returns a
parameterized simulation + visualization. Add a **parameter sweep** mode:
fix the architecture, vary θ over a grid, and visualize how
`threshold_biphasicity` and the loss ordering change across θ. This makes the
threshold gate *visible* as a control parameter, not just a fixed oracle
input.

**What it teaches.** The threshold gate is the heart of the framework's biphasic
prediction. Seeing it respond to θ across a sweep builds the intuition that
the biphasic signal is *the gate*, not the displacement ratio (math-review
Issue 3). It also makes the R6 method-misspecification visceral: a
cross-sectional regression across organisms with *different* θ would see
noise, not a logistic — which is exactly why T3 fails on real data.

#### Toy model 2 — Cross-kingdom transfer explorer

**What it explores.** Given a plant dependency architecture and a bird
dependency architecture, simulate the cross-kingdom transfer and visualize
*when the transfer works and when it breaks*. The reader can watch the
logistic saturation reshape the bird ordering, and see directly why the slope
*magnitude* is discarded by ranking (math-review Issue 7) — and when the
logistic nonlinearity nonetheless lets the *model* (not just the sign)
transfer.

**What it is built from.** The author's original GLM approach
(`run_formal_model.R` Step 4: fit `retention ~ dep * para` to a synthetic
plant retention matrix, predict bird retention at a commitment level, rank) —
but fit to **synthetic** data from `generate_synthetic_population()` rather
than the broken real matrix. This isolates the *method* from the
*misspecification*: on clean synthetic data with a true interaction, the GLM
transfer works; the reader can then introduce misspecification (drop the
interaction, add separation) and watch the transfer degrade.

**What it teaches.** The cross-kingdom transfer is the monograph's strongest
claim, and it is the one the foundry flattened most (Issue 7: only the sign
transfers). The toy model lets a reader see *why* — ranking is sign-only by
construction — and explore whether the GLM's logistic nonlinearity recovers
genuine model transfer. It also turns the broken-GLM finding (Part I) into a
*lesson*: the reader can reproduce the wrong-signed `b` by fitting the
additive model to the real matrix, then fix it with the interaction term.

#### Toy model 3 — Irreversibility explorer

**What it explores.** Given a cusp system (control parameter `a`, a path
through `b`-space forward and reverse), simulate the hysteresis loop and
visualize the *loop area* as a function of the path. The reader can sweep `a`
from the monotone regime (no bifurcation, loop area → 0) through the cusp
region (bifurcation, loop area → large) and watch irreversibility emerge.

**What it is built from.** `cusp_hysteresis_check()` (now with the pure
branch-following contract from Phase 3) + `make_cusp_equilibrium_fn()` + a
new `hysteresis_loop_area` metric (proposed in the empirical-testing plan
Phase 3a) + a fixed `plot_cusp_bifurcation()`. The explorer sweeps `a` and
plots loop area vs. `a`, overlaying the bifurcation set. This makes the
cusp's "testable but not tested" status *concrete*: the reader sees exactly
what experiment (a forward+reverse path through a real system's control
parameter) would fill it.

**What it teaches.** Irreversibility is the framework's sharpest departure from gradual
reversibility. The explorer shows that irreversibility is *quantitative*
(loop area), not just boolean (`has_hysteresis`), and that it emerges
discontinuously at the bifurcation. It also makes the data requirement
honest: no real capacity-reallocation experiment has measured both paths, so
the cusp remains speculative — but the reader can see *what would count* as
the test.

#### Toy model 4 — The Homo-inversion explorer

**What it explores.** Given a growth model (autocatalytic vs. logistic) and a
diversification time series, simulate the diversity-dependence sign and
visualize the *contrast* between the framework (positive DD, the Homo inversion) and the
competitor (negative DD, niche-filling). The reader can toggle the growth
model and watch `diversity_dependence_sign` flip, and explore the
endogenous-K bifurcation (Review Item 3) by sweeping the cultural-feedback
parameter.

**What it is built from.** `generate_autocatalytic_set()` (now genuinely
positive-DD after Phase 2b) + `diversity_dependence_sign()` + the proposed
`diversity_dependence_contrast()` (empirical-testing plan Phase 3b) +
`plot_loglog_growth()`. The explorer overlays the autocatalytic and logistic
trajectories and their per-capita-rate-vs-N slopes, making the sign flip
visible in one figure. Add a bifurcation sweep: vary the endogenous-K
feedback strength and show where the DD sign flips from negative (niche-
filling) to positive (Homo inversion).

**What it teaches.** The Homo inversion is the framework's signature
theoretical contribution and its least empirically constrained (Review Item
3: no parameter estimates from real systems). The explorer makes the
*bifurcation* — the prediction that there is a threshold in cultural
complexity beyond which DD flips — explorable. It cannot test this (no
hominin diversification data), but it can show *what the prediction looks
like* and *what data would test it* (a species-through-time series for Homo
spanning the threshold).

### What the speculative capacity is, and is not

**It is:** a theoretical-exploration layer that makes the framework's predictions
explorable across parameter space and hypothetical substrates. It sharpens
the predictions (the threshold gate, the transfer breakdown, the
irreversibility bifurcation, the DD flip), it is honest about the data
boundary (each realm names the experiment that would fill it), and it is
built almost entirely from existing, validated components.

**It is not:** an empirical test. It does not source new data. It does not
claim to corroborate the framework. A toy model that shows "the framework predicts X in world W"
is a theoretical statement, not an empirical one. The value is in making the
theory's consequences visible and its data requirements precise — so that
when the author delivers data, the empirical tests are sharper, and when a
reader encounters the framework cold, they can *play* with it rather than
read 400 lines of ODE.

### Relationship to the existing infrastructure

| Toy model | Reuses | Adds |
|-----------|--------|------|
| 1. Genome reduction | `threshold_model()`, `plot_retention_trajectory()` | parameter-sweep wrapper; θ-sweep viz; `plot_threshold_gate()` |
| 2. Cross-kingdom | `generate_synthetic_population()`, `generate_cross_kingdom_data()` | GLM-transfer wrapper (with interaction); transfer-breakdown viz; the broken-GLM reproduction as a lesson |
| 3. Irreversibility | `cusp_hysteresis_check()`, `make_cusp_equilibrium_fn()` | `hysteresis_loop_area`; `a`-sweep viz; fixed `plot_cusp_bifurcation()` |
| 4. Homo inversion | `generate_autocatalytic_set()`, `diversity_dependence_sign()` | `diversity_dependence_contrast()`; endogenous-K bifurcation sweep; overlay viz |

The capacity is a new module (`R/speculative.R` or `inst/toy_realms/`) plus a
vignette ("Exploring the framework in toy models") that walks a reader through each realm
with dials and visualizations. It is the literate-documentation Layer 2
(vignette) the standards require, realized as exploration rather than
reproduction.

---

## Recommendations

1. **Record the GLM finding (Part I).** The author's empirical formal model
   is broken (wrong sign, non-significant para, wrong-signed cross-kingdom
   transfer). The foundry hid this by replacing it with a theoretical
   simulation. This should be documented in the review and, when the data
   arrives, the right empirical model (interaction GLM or direct threshold-
   model fit) should be used — not the additive GLM restored.

2. **Fix the three viz bugs (Part II).** The renamed `k1_k2_ratio` (Viz bug
   1), the dead `forward_state` + ad-hoc hysteresis (Viz bug 2), and the dead
   mark pipeline (Viz bug 3) are all low-risk fixes. Do them before building
   the speculative capacity, so the new layer inherits a clean viz base.

3. **Build the speculative simulation capacity (Part III).** It is the right
   response to the data block: it makes the theory explorable without
   claiming empirical test, it is 80% built from existing components, and it
   sharpens the predictions for when the data arrives. Start with Toy model 1
   (genome-reduction explorer) — it is the simplest, it exercises the
   threshold gate (the heart of the framework), and it directly visualizes the R6
   method misspecification that blocks T3.

4. **Do not restore the author's GLM as-is.** It is misspecified and broken.
   If an empirical formal model is wanted, fit an interaction GLM
   (`retention ~ dep * para`) or — better — fit the threshold model's (λ, θ)
   directly to the retention matrix (the R6 "direct fit" option). Bundle the
   8×6 retention matrix either way; it is real data currently trapped in an
   archived script.

---

## Open questions for review

1. **Part I (GLM finding)** — record the broken-GLM finding in
   `manuscript-review.md` as a new Remark (R7) or Review Item (7)?
   It is a modeling finding, not a foundry data item, so it may belong as a
   Remark.
2. **Part II (viz bugs)** — fix the three viz bugs now (low risk, suite
   green), or fold them into the speculative-capacity build?
3. **Part III (toy models)** — build all four realms, or start with Toy model
   1 (genome reduction) and gate the rest on whether the author wants the
   exploratory layer to go further?
4. **The 8×6 retention matrix** — bundle it in `data/` now (it is real data,
   trapped in an archived script), or leave it until the empirical formal
   model is redesigned?

If approved, I'll fix the three viz bugs first (Phase A), then build Toy
realm 1 as a proof-of-concept (Phase B), and report before proceeding to the
other realms.
