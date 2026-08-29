---
title: "Formal Model Reproduction: The Data-Flattening Bug and the One-Character Fix"
author: "Ed Phillips ([@phosphene](https://github.com/phosphene))"
date: 2025-08-08
license: MIT
---

# Formal Model Reproduction

> **Central finding.** The author's original formal model — an additive
> quasibinomial GLM (`retention ~ dep + para`) in
> `archive/pre-foundry-scripts/run_formal_model.R` — is broken not because the
> model is misspecified, but because of a **data-flattening bug**: the script
> uses `as.vector(t(retention))` (species-major) where it should use
> `as.vector(retention)` (gene-major). The mismatch shuffles `dep` and
> `retention`, so the GLM fits scrambled data and produces the wrong sign on
> `dep`. **Removing one `t()` fixes everything**: `dep = +0.84` (p = 0.0008),
> `para` p < 0.0001, cross-kingdom ρ = +0.755 — all matching the framework's prediction predictions.
>
> The foundry replaced this fixable one-character bug with a theoretical ODE
> simulation that cannot fail (it does not fit the 8×6 matrix at all), hiding
> both the bug and the fix.

This document reproduces the author's errors, diagnoses the root cause,
proposes three alternative model specifications, and contrasts all of them
against the foundry's pure ODE simulation. It is the deep-dive companion to
[`modeling-sim-viz-review.md`](modeling-sim-viz-review.md), which first
identified the broken GLM but attributed the failure to misspecification and
separation. The deeper root cause — the flattening bug — supersedes that
diagnosis; see the [correction note](#correction-to-modeling-sim-viz-review)
at the end.

The executable companion is
[`inst/examples/formal-model-comparison.R`](../../inst/examples/formal-model-comparison.R).

---

## 1. The data

The author's 8×6 retention matrix records the plastid-gene retention
probability for 8 Orobanchaceae species (parasitism gradient 0 → 4) across 6
gene categories with functional-dependency scores 0 → 5:

| Species | para | ndh (0) | rpo (1) | psa (1) | psb (2) | atp (3) | rpl_rps (5) |
|---------|------|---------|---------|---------|---------|---------|-------------|
| Lindenbergia | 0.0 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| Pedicularis | 1.0 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| C.exaltata | 1.5 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.78 |
| C.gronovii | 2.5 | 0.00 | 0.00 | 1.00 | 1.00 | 1.00 | 0.72 |
| C.campestris | 3.0 | 0.00 | 0.00 | 0.80 | 1.00 | 1.00 | 0.50 |
| Boulardia | 3.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.50 | 0.67 |
| Epifagus | 3.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.50 | 0.67 |
| Conopholis | 4.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.48 |

**Mean retention by dependency** (correctly aligned — see §2):

| dep | gene | mean retention |
|-----|------|---------------|
| 0 | ndh | 0.125 |
| 1 | rpo | 0.375 |
| 1 | psa | 0.600 |
| 2 | psb | 0.625 |
| 3 | atp | 0.750 |
| 5 | rpl_rps | 0.728 |

The means are **roughly monotonic in dependency**: higher-dep traits are more
retained. This is the pattern the framework predicts. The GLM should capture it easily —
and it does, once the data is flattened correctly.

The bird data for cross-kingdom transfer (from
`archive/pre-foundry-scripts/run_cross_kingdom_L3.R`):

| Trait | dep | observed order |
|-------|-----|---------------|
| Wing prop. | 0.0 | 1 |
| Pect. musc. | 0.5 | 3 |
| Sternal keel | 1.0 | 2 |
| Feather asym. | 1.0 | 7 |
| Wing bones | 1.5 | 4 |
| Pelvic | 3.0 | 6 |
| Hindlimb | 4.0 | 5 |
| Feather struct. | 5.0 | 8 |

The oracle target is ρ = +0.755 (bird Spearman, `baseline/oracle.yml`:
`cross_kingdom_l3.values.bird_rho`).

---

## 2. The data-flattening bug

The author's script flattens the 8×6 matrix into a 48-row data frame:

```r
df <- data.frame(
  dep       = rep(dep_scores, each = 8),     # gene-major: 8 per gene
  para      = rep(parasitism, 6),            # gene-major: 8 per gene
  retention = as.vector(t(retention)),       # BUG: species-major: 6 per species
  dep_name  = rep(dep_names, each = 8),      # gene-major: 8 per gene
  species   = rep(species, 6)                # gene-major: 8 per gene
)
```

The `dep`, `para`, `dep_name`, and `species` vectors are all **gene-major**
(8 values per gene, 6 blocks). But `as.vector(t(retention))` is
**species-major** (6 values per species, 8 blocks):

- `retention` is 8×6 (8 species × 6 genes), stored column-major.
- `t(retention)` is 6×8 (6 genes × 8 species).
- `as.vector(t(retention))` reads the 6×8 matrix column-by-column, yielding
  **one species at a time**: `[Lindenbergia's 6 genes, Pedicularis's 6 genes, …]`.

So `df$dep[1:8]` is `[0,0,0,0,0,0,0,0]` (ndh, dep=0, for 8 species), but
`df$retention[1:8]` is `[1,1,1,1,1,1,0,1]` (Lindenbergia's 6 genes + the
first 2 of Pedicularis). **Every retention value is paired with the wrong
dependency score.**

The fix is one character — remove the `t()`:

```r
retention = as.vector(retention)   # gene-major: 8 per gene — matches dep/para
```

`as.vector(retention)` reads the 8×6 matrix column-by-column, yielding
**one gene at a time**: `[ndh for 8 species, rpo for 8 species, …]`. This
matches the gene-major `dep` and `para` vectors.

Verification — the first 8 values with `dep = 0` should be ndh retention
`[1, 0, 0, 0, 0, 0, 0, 0]` (retained in the autotroph, lost in all parasites):

```
Author  (misaligned): 1 1 1 1 1 1 0 1   ← Lindenbergia's 6 genes + Pedicularis's first 2
Correct (aligned):    1 0 0 0 0 0 0 0   ← ndh for 8 species ✓
```

---

## 3. Model A0: Additive GLM, misaligned data (author's original — DEPRECATED)

**Specification:** `retention ~ dep + para`, `family = quasibinomial()`.

This is the author's original code, with the flattening bug. The GLM fits
scrambled data:

| Coefficient | Estimate | p-value | the framework's prediction | Verdict |
|-------------|----------|---------|---------------|---------|
| intercept | +2.050 | 0.0151 | — | — |
| **dep** | **−0.828** | **0.0013** | **> 0** | **WRONG SIGN** |
| **para** | **−0.138** | **0.5924** | **< 0** | **ns** |

- Pseudo-R² = 0.269
- Cross-kingdom ρ = **−0.755** (oracle: +0.755 — **wrong sign**)

The GLM reports a *significant* negative `dep` effect — the opposite of what
the framework predicts. The `para` effect is non-significant. The cross-kingdom transfer
gives the wrong sign. **Every framework prediction fails.**

> **Deprecation note.** The additive GLM as implemented in
> `archive/pre-foundry-scripts/run_formal_model.R` is **deprecated**. Its
> wrong-sign results are an artifact of the `as.vector(t(retention))`
> data-flattening bug (§2), not a property of the additive model
> specification. Do not cite the author's reported `dep = −0.83` or
> `ρ = −0.755` — they are artifacts of scrambled data. The script also
> hardcodes `ρ = 0.755` and `ρ = 0.986` in its narrative `cat()` output,
> which do not match the `−0.755` the code actually computes; the hardcoded
> values reflect what the author believed the result should be, not what the
> buggy code produces.

---

## 4. Model A: Additive GLM, correct data (the one-character fix)

**Specification:** same `retention ~ dep + para`, `family = quasibinomial()`,
but with `as.vector(retention)` (no transpose).

| Coefficient | Estimate | p-value | the framework's prediction | Verdict |
|-------------|----------|---------|---------------|---------|
| intercept | +3.002 | 0.0032 | — | — |
| **dep** | **+0.837** | **0.0008** | **> 0** | **✓ significant** |
| **para** | **−1.864** | **<0.0001** | **< 0** | **✓ significant** |

- Pseudo-R² = 0.552
- Cross-kingdom ρ = **+0.755** (oracle: +0.755 — **matches**)

**The additive GLM works.** With the correct data flattening, every framework
prediction is confirmed: `dep` is positive and significant (higher dependency
→ higher retention), `para` is negative and significant (deeper parasitism →
lower retention), and the cross-kingdom transfer gives ρ = +0.755, matching
the oracle exactly. The pseudo-R² doubles from 0.27 to 0.55.

The additive model is not misspecified for this dataset. The mean retention
by dependency is roughly monotonic (§1), and the additive logit captures the
main effects of `dep` and `para` without needing an interaction term.

---

## 5. Model B: Interaction GLM (theoretically correct specification)

**Specification:** `retention ~ dep * para`, `family = quasibinomial()`,
parasites only (autotroph row dropped to avoid separation — all retention =
1.0 at para = 0).

the framework predicts that `dep` matters *more* at higher `para` (the protection
threshold θ bites harder as parasitism deepens). This is an interaction:
`dep:para` should be **positive** (the `dep` effect strengthens with `para`).

| Coefficient | Estimate | p-value |
|-------------|----------|---------|
| (Intercept) | +1.625 | 0.4196 |
| dep | +1.769 | 0.1807 |
| para | −1.341 | 0.0978 |
| dep:para | −0.322 | 0.4545 |

- Pseudo-R² = 0.491
- At para = 3, effective `dep` effect = +1.769 + (−0.322 × 3) = **+0.801**
- Cross-kingdom ρ = **+0.755**

The interaction GLM gives the **correct sign** on `dep` (+1.77, though not
significant due to the interaction absorbing variance and the small sample).
The interaction term `dep:para` is **negative** (−0.32) and non-significant
(p = 0.45) — suggesting `dep` matters *less* at higher `para`, which is
*against* the framework interaction prediction. But this is non-significant and the
effective `dep` effect at para = 3 is still positive (+0.80).

**Assessment.** The interaction GLM is the theoretically preferred
specification (the framework predicts an interaction), but in this 48-observation
dataset the interaction is non-significant and the additive model (Model A)
captures the main effects more cleanly (higher pseudo-R², significant `dep`).
The interaction GLM does not change the cross-kingdom ρ (+0.755 in both).
For this data, the additive model is adequate; the interaction would matter
with more data or a wider parasitism range.

---

## 6. Model C: Direct threshold-model fit (R6 option)

**Specification:** `C(d, P) = 1 if d ≥ θ, else exp(−λP)`. Grid-search θ
over dependency midpoints {0.5, 1.5, 2.5, 4.0}; for each θ, fit λ via
`optimize()` minimizing SSE on unprotected traits.

This is the R6 option from
[`manuscript-review.md`](manuscript-review.md): fit the
threshold model directly to the retention matrix, rather than deriving it
from a theoretical ODE.

| θ | λ | SSE | R² |
|---|---|-----|-----|
| 0.5 | 10.0000 | 13.405 | −0.345 |
| 1.5 | 0.5408 | 8.266 | 0.171 |
| 2.5 | 0.4425 | 6.892 | 0.309 |
| 4.0 | 0.3643 | 6.709 | **0.327** |

- Best: θ = 4.0, λ = 0.364, R² = 0.327
- Cross-kingdom ρ = **+0.504** (6 of 8 unprotected bird traits share the same
  predicted retention → tied ranks)

**Assessment.** The threshold model is the **weakest** of the three fitted
models (R² = 0.33 vs 0.55 for the additive GLM). The step function is too
rigid: it predicts C = 1.0 for all protected traits (d ≥ θ) regardless of
parasitism, and a single exponential decay for all unprotected traits. The
real data has smooth gradations (0.78, 0.72, 0.50, 0.67, 0.48) that the step
function cannot capture.

The cross-kingdom ρ drops to +0.504 because the threshold model produces
**degenerate rankings**: all unprotected traits (6 of 8 bird traits with
θ = 4.0) share the same predicted retention `exp(−λ × 3)`, so they tie. The
threshold model distinguishes protected vs unprotected but not gradations
within each class — insufficient for ordering transfer.

---

## 7. Cross-kingdom transfer comparison

| Model | xfer ρ | Mechanism |
|-------|--------|-----------|
| A0: Additive GLM (misaligned) | **−0.755** | Wrong sign from scrambled data |
| A: Additive GLM (correct) | **+0.755** | Full logistic prediction at para = 3 |
| B: Interaction GLM (correct) | **+0.755** | Full logistic prediction at para = 3 |
| C: Threshold fit | +0.504 | Step function; 6/8 tied |
| D: Foundry ODE | n/a | Does not use the 8×6 matrix |
| E: Foundry lm + ρ | +0.755 | Sign-only (discards slope magnitude) |

Models A, B, and E all give ρ = +0.755, but by different routes:

- **Model A/B** (the GLM): predicts a *retention probability* for each bird
  trait from the full logistic model, then ranks by predicted retention. The
  magnitude of the `dep` effect enters the prediction, so the ranking carries
  model information.
- **Model E** (the foundry): fits `lm(loss_rank ~ dep)` on *idealized
  literature ranks* `[1,2,3,4,5,6]` (not the real 8×6 matrix), then transfers
  only the slope *sign* — `rank(plant_slope × bird_dep)` = `rank(bird_dep)`
  regardless of slope magnitude. It gives +0.755 because the idealized ranks
  are perfectly monotonic in `dep`, not because the model fits the data.

**The GLM (Model A) is the stronger result**: it fits the real retention
matrix, estimates `dep` and `para` from data, and the cross-kingdom ρ emerges
from the fitted model — not from idealized ranks with discarded magnitude.

---

## 8. Contrast with the foundry's ODE simulation (Model D)

The foundry's `R/formal_model.R` implements a deterministic ODE:

```
dC_i/dt = −λ × M(t) × I(d_i < θ)
```

where `M(t) = M₀ × exp(−αt)`. This is a **theoretical simulation**, not an
empirical fit. It takes parameters `(λ, θ, M₀, α, time)` as inputs and
produces retention trajectories. It **does not fit the 8×6 matrix** — it
cannot fail because it never compares its output to the data.

The foundry replaced the author's (buggy) empirical GLM with this simulation
and used its deterministic outputs as regression targets. The
`threshold_biphasicity` metric (= 1.0) confirms the ODE produces biphasic
kinetics — but this is a property of the model's construction, not an
empirical finding. The ODE *assumes* a protection threshold (θ) and a decay
rate (λ); it cannot *test* whether the data supports them.

**The contrast:**

| Property | Author's GLM (A0, buggy) | Corrected GLM (A) | Foundry ODE (D) |
|----------|-------------------------|--------------------|-----------------|
| Fits the 8×6 matrix? | Yes (misaligned) | Yes (correct) | No |
| Can fail empirically? | Yes (and did) | Yes (and passes) | No |
| dep estimated from data? | Yes (wrong sign) | Yes (+0.84, p=0.0008) | No (input parameter) |
| para estimated from data? | Yes (ns) | Yes (p<0.0001) | No (input parameter) |
| Cross-kingdom ρ from model? | −0.755 | +0.755 | n/a |

The foundry traded a fixable one-character bug for a simulation that cannot
fail. The corrected GLM (Model A) is the empirical test the framework needs:
it fits the real data, estimates parameters from data, and confirms the framework
predictions with significant coefficients and the correct cross-kingdom ρ.

---

## 9. Formal critique and deprecation

### 9.1 Deprecation of the author's additive GLM (as implemented)

The additive GLM in `archive/pre-foundry-scripts/run_formal_model.R` is
**deprecated** for three reasons:

1. **Data-flattening bug (root cause).** `as.vector(t(retention))` is
   species-major; `rep(dep_scores, each = 8)` is gene-major. The mismatch
   shuffles `dep` ↔ `retention`, so the GLM fits scrambled data. All reported
   coefficients and the cross-kingdom ρ are artifacts. **Fix: remove the
   `t()`** — use `as.vector(retention)`. With the fix, the additive model
   gives correct results (Model A, §4).

2. **Hardcoded results.** The script's narrative `cat()` output states
   `ρ = 0.986` (plants) and `ρ = 0.755` (birds), but the code computes
   `ρ = −0.755` (birds). The hardcoded values do not match the code's output.
   The `ρ = 0.986` is never computed at all — it appears only in the text.

3. **Separation (secondary).** The autotroph row (para = 0) has all
   retention = 1.0, causing quasi-separation in the logit. This inflates
   standard errors but does not change the sign. Dropping the autotroph row
   (as in Model B, §5) or applying a continuity correction addresses this,
   but the primary issue is the flattening bug.

### 9.2 What the foundry did instead (now corrected)

The foundry originally replaced the GLM with:

- **A theoretical ODE** (`R/formal_model.R`, `threshold_model()`) that simulates
  retention trajectories from input parameters. It does not fit the 8×6 matrix
  and cannot fail empirically.
- **An `lm(loss_rank ~ dep) + Spearman` transfer test** (`R/empirical_tests.R`,
  `transfer_test()`) that uses idealized literature ranks, not the real
  retention matrix, and transfers only the slope sign (discarding magnitude).

Both sidestepped the 8×6 matrix. The GLM — the only model that fits the real
  data — was dropped entirely.

**This has now been corrected.** The empirical GLM is restored as
`empirical_formal_model()` in `R/formal_model.R`, the 8×6 retention matrix
is bundled in `data/orobanchaceae_retention_matrix.tsv` (corrected
flattening), and the bird morphology data is bundled in
`data/island_bird_morphology.csv`. The function is wired into the pipeline
(`scripts/run_pipeline.R`) and the regression gate
(`tests/testthat/test-regression-baseline.R`), with oracle targets in
`baseline/oracle.yml`. The ODE (`threshold_model()`) remains as the
theoretical companion.

### 9.3 Status: implemented

The recommendation below has been **implemented**:

- ✅ The 8×6 retention matrix is bundled (`data/orobanchaceae_retention_matrix.tsv`).
- ✅ The corrected additive GLM is restored as `empirical_formal_model()`.
- ✅ It fits the real data, estimates `dep` and `para` from data, and confirms
  the framework's predictions: `dep = +0.84` (p = 0.0008), `para` p < 0.0001.
- ✅ Cross-kingdom ρ = +0.755 from the fitted model.
- ✅ The regression gate enforces the oracle values; the unit tests verify
  the framework's predictions on both synthetic and real data.
- ✅ The ODE (`threshold_model()`) remains as the theoretical companion — both
  are in the pipeline as `formal_model` (ODE) and `empirical_formal_model` (GLM).

The interaction GLM (Model B) is the theoretically preferred specification
but is not needed for this dataset. The threshold-model fit (Model C) is too
rigid (step function, R² = 0.33) and produces degenerate rankings. The
foundry's ODE (Model D) remains as a useful *simulation* alongside the new
*empirical test*.

The corrected additive GLM (Model A) is the right empirical model: it is the
simplest model that fits the data, confirms the framework's predictions, and can fail.

---

## Correction to modeling-sim-viz-review

[`modeling-sim-viz-review.md`](modeling-sim-viz-review.md) Part I reported
that the author's GLM was "misspecified (additive where the framework predicts
interaction)" and attributed the wrong sign to this misspecification plus
separation. That diagnosis was **incomplete**. The root cause is the
data-flattening bug (§2): `as.vector(t(retention))` misaligns `dep` and
`retention`. The additive specification is adequate for this data — with
correct alignment, it gives the right sign, significant coefficients, and the
correct cross-kingdom ρ. The interaction GLM is theoretically preferred but
not needed for the sign. See §4–5 above for the corrected analysis.

The modeling-sim-viz-review's broader finding — that the foundry hid the
broken GLM by replacing it with a non-empirical ODE — stands and is
strengthened: the foundry replaced a *fixable one-character bug* with a
simulation that cannot fail.
