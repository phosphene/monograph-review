# The valence-foundry Math Review — Implementation vs. Mathematics vs. Claims

**Author:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**License:** MIT
**Status:** All seven issues RESOLVED — see
[`refactoring-plan.md`](refactoring-plan.md) § "Execution log". Each issue
heading below is tagged with its resolution.

---

## What this document is

A line-by-line audit of the mathematics in `valence-foundry`: for each analysis
function, does the **implementation** correctly realize the **mathematics** it
claims to, and do the **claims** (in docstrings, the oracle, and the review)
actually follow from that math? This is a different cut from
[`calculation-review.md`](calculation-review.md), which traced divergences
between the pipeline output and the manuscript oracle. Here we ask whether the
math itself is sound and whether the code does what the math says.

The audit found seven issues, ranked by severity:

| # | Severity | Function | The problem |
|---|----------|----------|-------------|
| 1 | **Severe** | `ltee_cosegregation` (T7) | The claim is the *opposite* of the result |
| 2 | **Severe** | `threshold_model` docstring | The stated ODE is a third equation that gives nonsense |
| 3 | **Moderate** | `threshold_model` k1/k2 | A displacement ratio, mislabeled as a rate ratio |
| 4 | **Moderate** | `cusp_hysteresis_check` | Detects hysteresis only via an undocumented stateful-closure contract |
| 5 | **Moderate** | `pgls_cross_family` (T2) | Tests family-mean correlation, not within-family replication |
| 6 | **Moderate** | `diversity_dependence_sign` | "Positive" means increasing, not diversity-dependent |
| 7 | **Minor** | `transfer_test` / `predict_bird_ordering` | Null is one draw; ranking discards the transferred slope |

---

## Issue 1 — T7: the claim is the opposite of the result  *(RESOLVED, Phase 1)*

### The claim

`ltee_cosegregation()` is documented as testing whether "metabolic function
loss in the LTEE co-segregates with beneficial mutations **more than expected
by chance**." The value `enrichment_ratio` is named to suggest enrichment. The
oracle records `observed_pct: 36.4` and `expected_pct: 61.7`.

### The math

```r
observed_near <- 92L
total_mutations <- 253L
expected_rate <- 0.617
observed_prop <- observed_near / total_mutations   # 0.364
bt <- binom.test(observed_near, total_mutations, p = expected_rate,
                 alternative = "less")
enrichment_ratio <- observed_prop / expected_rate   # 0.589
```

The observed proportion (0.364) is **less than** the expected rate (0.617). The
binomial test uses `alternative = "less"` — it computes `P(X ≤ 92 | p = 0.617)`,
which is significant precisely *because* the observed count is below expectation.
`enrichment_ratio = 0.589` is a **depletion** ratio (below 1.0), not enrichment.

### The contradiction

| Stated claim | Actual math |
|--------------|-------------|
| co-segregation **more** than chance | observed **less** than chance |
| `enrichment_ratio` (implies > 1) | 0.589 (depletion) |
| `alternative = "greater"` would match the claim | `alternative = "less"` is used |

The result — function-loss mutations are **depleted** near beneficial sweeps —
is in fact *consistent* with the valence drift prediction (unused genes drift, so
their loss mutations are not concentrated near adaptive sweeps). But the
function's documentation, the `enrichment_ratio` name, and the oracle framing
all describe the opposite of what the code computes.

### The fix

The naming and documentation must be corrected to match the math. Either:
- Rename `enrichment_ratio` → `depletion_ratio` and rewrite the docstring to say
  "co-segregate **less** than chance (consistent with passive drift in unused
  genes)"; or, if the intended claim really was "more than chance," the test
  direction (`alternative = "less"`) and the data are wrong and must be
  corrected. The current state — claim and result pointing opposite ways — must
  not stand. **This is the most serious finding** because it is a sign error on
  a discriminating test, hidden by a passing gate (the gate only checks the
  observed/expected *magnitudes*, not the direction of the claim).

---

## Issue 2 — `threshold_model`: the docstring's ODE is a third equation  *(RESOLVED, Phase 1)*

### The claim (docstring)

The model header states:

> The valence formal model: dC_i/dt = -λ × M(t) × I(d_i < θ)

This is a **linear** ODE in C (no C factor on the right-hand side). Its
solution would be `C(T) = 1 - λ·∫M dt`, which for the oracle parameters gives:

```
C(100) = 1 - (0.15 × 10 / 0.05) × (1 - e^(-5)) = 1 - 28.8 = -27.8
```

A retention probability of −27.8 is nonsensical.

### The implementation (code)

The Euler loop actually computes:

```r
d_c <- -lambda * m_t * retention[i] * dt   # note the retention[i] factor
```

This is `dC/dt = -λ·M(t)·C` — an **exponential** decay ODE. Its solution is
`C(T) = exp(-λ·∫M dt)`, which for the oracle parameters gives `C(100) ≈ 1.1e-13`
— a valid probability. This matches the closed-form `retention_at_time()`,
which computes `exp(-λ·(m0/α)·(1 - e^(-αT)))`.

### The verification

```
docstring ODE  (dC/dt = -λM,    linear):     C(100) = -27.80   ← nonsense
code           (dC/dt = -λMC,   exponential): C(100) = 1.03e-13 ← valid
closed-form    (exp(-λ∫M dt)):               C(100) = 1.15e-13 ← valid, matches code
```

### The fix

The code and the closed-form agree (both exponential decay); the **docstring is
wrong**. The header must state `dC_i/dt = -λ·M(t)·C_i·I(d_i < θ)` (with the `C_i`
factor), so the documented equation matches what is integrated. The
`equilibrium_retention()` docstring has the same omission. As written, a
reviewer reading the docstring and checking the math would conclude the model is
broken (it integrates a different equation than it claims to) — when in fact the
*implementation* is self-consistent; only the *documentation* is wrong.

---

## Issue 3 — `threshold_model` k1/k2: a displacement ratio, not a rate ratio  *(RESOLVED, Phase 2a)*

### The claim

`k1_k2_ratio` is presented as the biphasic signature: "Phase 1 rate / Phase 2
rate," with the oracle value ≈ 281,000. The implication is that Phase 1 and
Phase 2 are two distinct ODE rates, and their ratio quantifies biphasicity.

### The math

```r
phase1_rate <- mean(retention_history[1,] - retention_history[phase1_end+1,])[unprotected]
phase2_rate <- mean(retention_history[phase1_end+1,] - retention_history[n+1,])[unprotected]
k1_k2 <- phase1_rate / phase2_rate
```

`phase1_rate` is the **mean change in retention probability** over the first 10%
of the time window (a displacement, ΔC, not a rate dC/dt). `phase2_rate` is the
same over the last 90%. Because the decay is exponential and completes early
(retention → ~1e-13 well before t=10), `phase1_rate ≈ 1.0` (retention drops from
1 to ~0) and `phase2_rate ≈ 3.6e-6` (nothing left to lose). Their ratio
(280,980) is large **by arithmetic construction**, not because there are two
distinct ODE rates.

### The problem

The actual biphasic signal in this model is the **threshold gate**: protected
traits (`d ≥ θ`) stay at 1.0 forever, unprotected traits decay to ~0. That is
the biphasicity — a step function in retention indexed by integration depth,
not a two-phase temporal decay. The `k1_k2_ratio` measures how completely the
unprotected traits finished decaying in the first 10% of time, which is a
function of `λ·M₀/α` (how fast the exponential completes), not a property of two
phases. A single-exponential model with the same completion time would produce
the same huge ratio.

### The fix

Either (a) rename `k1_k2_ratio` to reflect that it is a temporal displacement
ratio (and document that the real biphasic signal is the protected/unprotected
split in `final_retention`), or (b) redefine it as a genuine two-rate statistic
fit to the retention trajectory. As is, the number 281,000 is being read as
"strongly biphasic" when it really means "the decay finished early."

---

## Issue 4 — `cusp_hysteresis_check`: detects hysteresis only via an undocumented stateful-closure contract  *(RESOLVED, Phase 3)*

> **Correction (post-review).** An earlier version of this section stated the
> function "cannot detect hysteresis by construction" and is "always FALSE."
> That was overclaimed. The cusp simulacrum passes `has_hysteresis = TRUE`
> because `make_cusp_equilibrium_fn()` (in
> `inst/simulacra/generate_cusp_system.R`) is a **stateful closure** — it uses
> `<<-` to track the previous state and follow the nearest equilibrium branch
> across calls. So hysteresis *is* detected, but through an **undocumented
> contract**: the caller must pass a stateful closure that does
> branch-following via side effects. `cusp_hysteresis_check` itself carries no
> state; with a pure `equilibrium_fn` (e.g. `function(x) ifelse(x>0, x^2,
> -x^2)`) it returns `has_hysteresis = FALSE` always, which is what the
> original review observed. The real defect is a **misplaced contract**, not
> "cannot detect by construction."

### The claim

The function claims to "check for hysteresis (path dependence)" — the hallmark
of irreversibility in the cusp catastrophe, where the forward path (increasing
commitment) differs from the reverse path (decreasing commitment).

### The math

```r
# Forward path
for (i in seq_len(n)) {
  state <- equilibrium_fn(control_values[i])   # state recomputed afresh
  forward_states[i] <- state
}
# Reverse path
for (i in seq_len(n)) {
  state <- equilibrium_fn(control_values[n - i + 1])  # state recomputed afresh
  reverse_states[i] <- state
}
differences <- abs(forward_states - rev(reverse_states))
has_hysteresis <- any(differences > 0.01)
```

Both loops call `equilibrium_fn()` **afresh on each control value**, and
`cusp_hysteresis_check` itself discards `state` each iteration — it carries no
state of its own. Hysteresis *requires* that the state depends on the previous
state (path dependence). With a **pure** `equilibrium_fn` (state a function of
control only), the state at step `i` depends only on `control_values[i]`, so
`forward_states == rev(reverse_states)` always, `differences` is always 0, and
`has_hysteresis` is **always FALSE**.

The function only detects hysteresis when the caller passes a **stateful
closure** that does branch-following via side effects (`<<-`) — which is what
the simulacrum's `make_cusp_equilibrium_fn()` does. But that contract is
undocumented: the `@param equilibrium_fn` docstring says "Maps control value →
equilibrium state," implying a pure function.

### The verification

Tested with a pure equilibrium function that has a genuine fold
(`ifelse(x > 0, x^2, -x^2)`): `has_hysteresis = FALSE`, `max_difference = 0`.
The simulacrum, using the stateful `make_cusp_equilibrium_fn`, does report
`has_hysteresis = TRUE` — confirming the detection works *only* via the
caller's closure, not via the function under test.

### The fix

A real hysteresis check must carry state forward **inside the function**: the
contract for `equilibrium_fn` should be a pure `function(control, state) ->
new_state` (or `function(control) -> roots_vector` with the function picking
the branch nearest the carried state). `cusp_hysteresis_check` should carry
`state` through the forward sweep (initialized at the first control) and the
reverse sweep (initialized at the last control), so the two paths can settle
to different branches. As written, the branch-following logic is misplaced in
the caller's closure, the contract is undocumented, and the unit test never
asserts `has_hysteresis = TRUE` (only that `max_difference` is numeric) — so
unit coverage of hysteresis detection is zero. (The refactoring plan, Phase 3,
moves the state into the function.)

---

## Issue 5 — T2: family-mean correlation, not within-family replication  *(RESOLVED, Phase 1)*

### The claim

`pgls_cross_family()` claims to test whether "the plastome size ~ parasitism
gradient **replicates across independently evolved parasitic plant families**."

### The math

```r
family_means <- aggregate(cbind(plastome_size_kb, parasitism_score) ~ family,
                          data = data, FUN = mean)
cor.test(family_means$plastome_size_kb, family_means$parasitism_score)
```

The function aggregates 91 species to **15 family means** and computes a single
correlation across those 15 points (r = −0.90, n = 15). This tests whether
family-mean plastome size correlates with family-mean parasitism — a
cross-sectional family-level association. It does **not** test replication: a
true replication test would fit the plastome ~ parasitism slope **within each
family** and check that the slopes agree in sign and magnitude across the
independent origins.

### The problem

"Replicates across families" means the gradient appears *in each family*. The
implementation instead asks whether the gradient appears *between family
averages*. These are different questions: between-family correlation can be
strong while within-family slopes are weak or inconsistent (Simpson's paradox),
and vice versa. The oracle value (n = 91, species-level) is itself a third
quantity. The claim, the implementation, and the oracle are three different
tests.

### The fix

Either reframe the claim to "family-mean plastome size correlates with
family-mean parasitism" (matching the implementation), or implement a
within-family slope analysis (fit per-family, report the distribution of slopes
and their concordance). And align the oracle's n (91 species vs. 15 families).

---

## Issue 6 — `diversity_dependence_sign`: "positive" ≠ diversity-dependent  *(RESOLVED, Phase 2b)*

### The claim

The function returns `sign` ("positive"/"negative") and `is_superlinear`, with
the theoretical context framing these as diversity-dependence: "positive
diversity-dependence in cultural substrate — the Homo inversion."

### The math

```r
mod <- lm(innovation_counts ~ time)           # linear fit: count vs TIME
slope <- coef(mod)[2]
sign <- ifelse(slope > 0, "positive", "negative")
log_mod <- lm(log(counts) ~ log(time))        # log-log: power-law exponent
log_slope <- coef(log_mod)[2]
is_superlinear <- log_slope > 1.0 + 1e-6
```

`sign` is the slope of a linear regression of **innovation count against time**.
"Positive" means innovations are increasing over time — that is growth, not
diversity-dependence. Diversity-dependence is a claim about the **per-capita
speciation rate as a function of standing diversity** (N), not about count
against time. `is_superlinear` (log-log slope > 1) is a proxy for accelerating
growth, which is *related* to positive diversity-dependence but is not the same
thing — superlinear growth can arise from many non-diversity-dependent
mechanisms.

### The problem

The `sign` field answers "are counts going up?" — which is almost always true
in any growing system and says nothing about whether diversity drives the rate.
A reader taking `sign = "positive"` as evidence for "positive
diversity-dependence" (the Homo inversion claim) would be overreading. The
log-log slope is a better (if still indirect) proxy, but it is not labeled as
the diversity-dependence measure.

### The fix

Rename `sign` to `growth_direction` (or similar) and reserve
"diversity-dependence" for a direct test: regress per-capita innovation rate
`(dN/dt)/N` against `N` and report the sign of *that* slope. The current
`is_superlinear` is a reasonable exploratory check but should be documented as
a proxy, not the definitive diversity-dependence test.

---

## Issue 7 — `transfer_test`: a one-draw null and a ranking that discards the slope  *(RESOLVED, Phase 2c)*

### The claim

`transfer_test()` is "the strongest test in the monograph": fit the
integration-depth model on plant data, apply the slope to predict bird
morphological-change ordering without refitting, and check the null (random
slope) does not recover.

### The math — two sub-issues

**Sub-issue A: the null is a single draw.**

```r
random_slope <- runif(1, -1, 1)          # ONE random slope
null_predicted <- random_slope * bird_data$dependency_score
null_ranks <- rank(null_predicted)
null_cor <- cor.test(null_ranks, observed_ranks, method = "spearman")
```

`null_rho` is the correlation from **one** random slope. A proper null needs a
*distribution* (many random slopes) to compute a null p-value
(`P(ρ_random ≥ ρ_observed)`). A single draw is an anecdote, not a null
distribution — it cannot support a "the null does not recover" claim with any
statistical weight.

**Sub-issue B: ranking discards the transferred slope magnitude.**

```r
predict_bird_ordering <- function(bird_data, plant_slope) {
  predicted <- plant_slope * bird_data$dependency_score
  rank(predicted, ties.method = "average")     # ranks!
}
```

The predicted values are `plant_slope × dependency_score`, then converted to
**ranks**. But `rank(a × x) = rank(x)` for any `a > 0` (and `rev(rank(x))` for
`a < 0`): multiplying by a positive scalar does not change the order. So as long
as the plant slope is positive, `predicted_ranks` is just `rank(dependency_score)`
— the **magnitude** of the transferred slope is discarded entirely. The
"transfer" reduces to "does bird observed_rank correlate with
dependency_score?" The plant model contributes only the *sign* of the slope
(positive → same direction), not its fitted value. This is a much weaker claim
than "plant parameters predict bird ordering."

### The fix

For (A), generate a null distribution (e.g., 1000 random slopes) and report
`null_p = mean(null_rhos >= bird_rho)`. For (B), either compare the *predicted
values* (not ranks) to observed, or be honest that the test transfers only the
slope *sign* and is really an ordering-concordance test, not a parameter
transfer. As is, "the strongest test in the monograph" is a sign-concordance
check with a one-draw null.

---

## What is sound

For balance, the functions that are mathematically sound and correctly
implemented:

- **`pgls_orobanchaceae` (T1).** Uses `caper::pgls` correctly; fits in kb units;
  p-value from the F-statistic; adjusted R². The PGLS math is delegated to a
  well-tested package and used appropriately. Sound.
- **`cusp_bifurcation_point`.** The discriminant `4a³ + 27b² = 0` is the
  standard cusp catastrophe bifurcation curve. Correct.
- **`endosymbiont_biphasic` (T3).** After the calculation-review fixes, the R²
  formula (`1 - RSS/TSS`) is correct, and the k1/k2 extraction (curve slope at
  youngest vs. oldest age) is a legitimate — if not the only — definition. The
  method misspecification (cross-sectional vs. within-lineage) is documented in
  R6; the *math that runs* is correct.
- **`niche_vs_ne` (T4) / `pangenome_fluidity` (T5).** After the calculation-review
  fixes, the log-scale regressions and the `^Ne$` grep are correct. Sound.
- **`gene_loss_ordering` (T6) permutation test.** The null (shuffle dependency
  scores, keep ranks fixed) is the correct null for "no association between
  integration depth and loss order." Two-sided `|ρ| ≥ |ρ_obs|` is appropriate.
  (Caveat: ties in `loss_rank` force asymptotic Spearman p-values — a warning,
  not an error.)

---

## Summary and priorities

The two **severe** issues must be fixed before any empirical claim is trusted:

1. **T7 sign error** (Issue 1): the claim and the result point opposite
   directions. This is on a discriminating test and is currently hidden by a
   gate that checks magnitudes, not the claim's direction.
2. **Formal model docstring** (Issue 2): the documented ODE is not the equation
   being integrated. The implementation is self-consistent; the documentation
   is wrong and would mislead any reviewer checking the math.

The **moderate** issues (3–6) are cases where the math is internally consistent
but does not support the strength of the claim being made: a displacement ratio
called a rate ratio, a hysteresis check that cannot detect hysteresis, a
replication test that is not a replication test, and a growth-direction flag
called diversity-dependence. These do not produce wrong numbers, but they
license overreadings.

The **minor** issue (7) means the "strongest test" is weaker than advertised.

None of these are caught by the test suite, because the tests check that the
functions *return values* and *recover parameters on synthetic data* — not that
the *claims* match the *math*. That is the gap this review fills. Closing it
means: correct the documentation to match the implementation (Issues 2, 3, 6),
correct the naming to match the math (Issues 1, 6), and fix the functions that
are structurally wrong (Issues 4, 7) or reframe their claims (Issue 5).
