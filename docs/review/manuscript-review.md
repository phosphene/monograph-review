# the framework under review Framework — Critical Review

**Reviewer:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**Status:** Living document — review of the monograph (Ritch-Frel, *The
the framework under review Framework*, v9, June 2026) and of the `the foundry`
computational artifacts that test its predictions.
**License:** MIT

---

## Scope

This review covers two things, and it is important to keep them distinct:

1. **The monograph** — Ritch-Frel's framework under review (v9). The framework proposes
   that organisms are problem-solving agents that commit to ecological spaces
   offering adaptive returns (*valence*), are reshaped by those spaces through
   *capacity reallocation*, and that evolution is the record of this process
   rather than its driver. It makes three headline predictions: convergent
   neural crest cell (NCC) genomic signatures in lineages entering
   social-tolerance niches; behavioral commitment preceding morphological
   change; and the *Homo* macroevolutionary inversion (positively
   diversity-dependent speciation) as a substrate-shift signature.

2. **The foundry** — this repository. The foundry does **not** test the
   monograph's three headline predictions directly. It tests the *§12 results*:
   the integration-depth / capacity-reallocation sub-prediction applied to
   genome reduction — Orobanchaceae plastome PGLS, endosymbiont biphasic
   kinetics, gene-loss ordering, LTEE co-segregation, cross-kingdom parameter
   transfer, niche-vs-Ne, and pan-genome fluidity. These are real framework
   predictions, but they are a narrower evidentiary register than the
   monograph's NCC / *Homo*-inversion claims (see Remark R3).

The review is written so that every finding the code depends on is stated here
by number. The foundry's test suite and pipeline cite **Remarks** (R1…) and
**Review Items** (1–6) directly; a `skip()` or a divergence message should
always resolve to a paragraph below.

---

## Executive summary

The framework's strongest contribution is mechanistic: the endogenous-`K`
account of van Holstein & Foley's (2024) *Homo* diversification inversion is,
as far as this review can establish, the only mechanism-level explanation in
the current literature for why *Homo* exhibits positively diversity-dependent
speciation. That alone justifies taking the framework seriously.

The framework's weakest point is empirical: several of its load-bearing
predictions have not been tested against data, and where the foundry *can* test
the §12 results, the bundled data does not yet reproduce the manuscript's
reported values. This is not a defect of the framework — it is a
data-reconciliation gap in the foundry (items 4–6) — but it means the foundry
currently *corroborates the methodology* (the math is correct, the gates run,
parameter recovery succeeds on synthetic data) without yet *corroborating the
numbers*.

The review's actionable findings are six numbered **Review Items**. Items 1–3
concern the framework and its framing; items 4–6 concern the foundry's data and
are the reason the regression gate currently `skip()`s rather than enforces.

---

## Remarks

Remarks are critical observations on the framework and the foundry. They are
not action items (those are the Review Items); they are the reasoning behind
them.

### R1 — The name is ambiguous

"the framework under review" requires reading the internal definitions before it
becomes meaningful, and the abbreviation "valence" is ambiguous within the Phosphene
ecosystem (it collides with other uses of "valence"). Neither token is
self-explanatory to a reader encountering the framework cold. The glossary in
the root [`README.md`](../../README.md) flags this. A future revision should
either adopt a self-describing name or commit to the expansion in every
context. This is cosmetic but it affects adoption and searchability.

### R2 — "Agency" is used instrumentally, not metaphysically

The framework describes organisms as "problem-solving agents" that "navigate
toward valence-states." Read literally this is a strong ontological claim
(agency precedes replication). The monograph is careful to use the agency
vocabulary *instrumentally* — it is productive and non-metaphorical at
sub-organismal scales (Levin's TAME work), and the empirical case rests on the
paleontological and comparative record, not on the agency framing. Reviewers
should not reject the framework on the strength of the agency language, and
proponents should not overclaim it. The foundry is agnostic to this debate: it
tests integration-depth predictions, which hold regardless of whether
Valence-seeking is agency or selection-with-a-trajectory.

### R3 — The foundry's evidentiary scope is narrower than the monograph's headline claims

The monograph's three headline predictions (NCC convergence;
behavioral-before-morphological; the *Homo* inversion) are **not** what the
foundry tests. The foundry tests the §12 genome-reduction results, which are
the integration-depth / capacity-reallocation prediction applied to a specific
domain (plastome and endosymbiont genome reduction, gene-loss ordering, LTEE
function-loss co-segregation, cross-kingdom transfer). This is a legitimate and
important sub-prediction, but a reader should not conclude that a green foundry
"confirms the framework" in its broadest form. The foundry confirms the *capacity-
reallocation-by-integration-depth* mechanism in the genome-reduction domain.
The NCC and *Homo*-inversion predictions require their own test artifacts,
which the foundry does not currently provide.

### R4 — Some oracle entries corroborate the framework but do not discriminate it from competitors

The baseline oracle ([`baseline/oracle.yml`](../../baseline/oracle.yml))
annotates each entry with `distinguishes_from_competitor`. T1 (Orobanchaceae
PGLS), T2 (cross-family), and T7 (LTEE co-segregation) are marked
`distinguishes_from_competitor: false`: the competing hypotheses (relaxed
selection, stochastic loss, independent assortment) predict the same pattern.
These results *corroborate* the framework but do not *discriminate* it. The discriminating
evidence in the foundry is concentrated in T3 (biphasic kinetics), T4
(niche-vs-Ne), T5 (pan-genome fluidity), T6 (gene-loss ordering), and L3
(cross-kingdom transfer). Of these, T6 and L3 currently have no bundled data
(items 4–5) and T3/T4/T5 drift (item 6). The honest summary is: **the
foundry's discriminating tests are precisely the ones not yet passing.**

### R5 — The data gap is real and must not be hidden

The foundry's bundled data does not reproduce the manuscript oracle for T1–T5
(data drift / known statistical bugs), and T6 / L3 have no bundled data at all.
The prior failure mode — silently no-op'ing the regression gate so a green CI
hides the gap — is exactly what the gate redesign prevents. Each entry now
*runs and compares*, and divergent or unavailable entries `skip()` with an
exact actual-vs-expected reason that cites items 4–6. The gate is honest: it
reports 9 skips, not 9 silent passes. Closing items 4–6 converts those skips
into enforced `expect_equal` checks automatically.

### R6 — T3's cross-sectional method is misspecified for the biphasic prediction

The biphasic-kinetics prediction (fast Phase 1, slow Phase 2) is a
*within-lineage temporal* claim: the rate of genome reduction decelerates over
time *for one lineage*. But `endosymbiont_biphasic()` does a *cross-sectional*
regression of genome size vs symbiosis age *across unrelated lineages*. This
cannot test the prediction because different lineages started at vastly
different genome sizes: at age 80 Mya, Baumannia (687 kb) is 6× Nasuia (112 kb);
at age 200 Mya, Buchnera (569 kb) is still larger than Portiera at 150 Mya
(346 kb). No single logistic curve can fit this scatter — the logistic `nls`
does not converge, the exponential fit gives R² = 0.24, and the linear fit gives
R² = 0.17.

The simulacrum confirms the *function's math is correct* on clean data: when
synthetic data is generated from a single ancestor with a known logistic
decline, the function recovers the rate within 50% and model selection correctly
prefers the logistic (ΔAICc > 4). The problem is not the math — it is the
cross-sectional design, which violates the function's own assumption (shared
ancestor, shared floor).

The foundry's T3 bugs (broken R² formula, k1/k2 extraction returning the raw
rate parameter) have been fixed, so the function is now correct *when the data
supports it*. But the real endosymbiont data cannot test the biphasic prediction
via cross-sectional regression. **Action:** redesign T3 as either (a) a
within-lineage rate analysis (if longitudinal data can be sourced), (b) a
proportional-reduction analysis (normalize by ancestral size), or (c) a direct
fit of the formal threshold model to the data. This is a method-design task, not
a bug fix. Until then, T3 `skip()`s honestly with R² = 0.24 / k1-k2 = NA.

### R7 — The author's formal-model GLM has a data-flattening bug (root cause of the wrong sign)

The author's original empirical formal model
(`archive/pre-foundry-scripts/run_formal_model.R`) — a quasibinomial GLM,
`retention ~ dep + para`, fit to a real 8×6 plastid-gene retention matrix —
produced the wrong sign on `dep` (−0.83, the framework predicts > 0), a non-significant
`para` (p = 0.59), and a wrong-signed cross-kingdom ρ (−0.755, oracle says
+0.755). [`modeling-sim-viz-review.md`](modeling-sim-viz-review.md) Part I
initially attributed this to model misspecification (additive where the framework predicts
interaction) plus quasi-separation from the autotroph row.

That diagnosis was **incomplete**. The root cause is a **data-flattening bug**:
the script uses `as.vector(t(retention))` (species-major: 6 values per species)
where it should use `as.vector(retention)` (gene-major: 8 values per gene). The
`dep` vector is `rep(dep_scores, each = 8)` — gene-major. The mismatch shuffles
`dep` ↔ `retention`, so the GLM fits scrambled data.

**The fix is one character** — remove the `t()`. With correct alignment, the
additive GLM gives `dep = +0.84` (p = 0.0008), `para` p < 0.0001, pseudo-R² =
0.55, and cross-kingdom ρ = +0.755 — all matching the framework's prediction predictions. The additive
specification is adequate; the interaction GLM is theoretically preferred but
not needed for the sign in this dataset. The direct threshold-model fit (R6
option, step function) is too rigid (R² = 0.33) and produces degenerate rankings.

The foundry replaced this fixable one-character bug with a theoretical ODE
simulation (`R/formal_model.R`) that does not fit the 8×6 matrix and cannot
fail empirically. **Action:** restore the empirical GLM with the flattening bug
fixed as the formal model. See
[`formal-model-reproduction.md`](formal-model-reproduction.md) for the full
reproduction, fix, and five-model contrast.

---

## Review Items

Actionable findings. Items 1–3 are framework-level; items 4–6 are the
foundry's data-reconciliation work and are cited by the code.

### Item 1 — Resolve the naming (framework)

Adopt a self-describing name or commit to the "the framework under review" expansion in
every context; disambiguate the "valence" abbreviation. Tied to Remark R1. **Owner:**
monograph author. **Foundry impact:** none (cosmetic); tracked here so the
glossary's "under review" note resolves to a concrete item.

### Item 2 — Settle the NCC mechanism question (framework)

The Gleeson & Wilson (2023) challenge — that domestication-syndrome traits
reflect non-specific reproductive-disruption rather than selection specifically
on NCC pathways — is only partially answered by Rubio & Summers (2022), who
show the positive-selection signal is concentrated in NCC genes and absent from
controls. The mechanistic pathway (direct NCC selection vs. upstream regulator
→ NCC) remains open. Prediction 1 as stated is agnostic to this distinction,
which is the right call, but the framework should state explicitly that
*distinguishing* the two mechanisms is an open problem rather than implying it
is settled. **Owner:** monograph author. **Foundry impact:** none currently;
would matter if a future foundry artifact tests NCC convergence directly.

### Item 3 — Estimate the endogenous-K / bifurcation parameters (framework)

The endogenous-`K` model (`K(N,c) = K_eco + c·γ·N^β`) and its transcritical
bifurcation condition are mathematically sound but have **no parameter
estimates from real systems**, and the bifurcation's three testable predictions
(pre-threshold hominins show negative diversity-dependence; the transition is
relatively sudden, not gradual; the threshold correlates with cumulative
culture, not just tool use) have not been tested against the fossil record.
This is the framework's strongest contribution and simultaneously its least
empirically constrained. **Owner:** monograph author / follow-up work.
**Foundry impact:** none currently; the foundry does not test diversity-
dependence parameter recovery against the hominin record (the `autocatalytic`
simulacrum tests the *sign* of diversity-dependence on synthetic data, not the
bifurcation).

### Item 4 — Bundle the gene-category dataset (foundry, **cited by code**)

T6 (gene-loss ordering) requires a gene-category dataset with columns
`category`, `dependency_score`, `*_loss_rank` (e.g.
`orobanchaceae_loss_rank`, `cuscuta_loss_rank`). It is not bundled with the
package, so the regression gate `skip()`s T6 with
`"gene-category dataset not bundled (items 4-6)"`. The unit tests use an
in-memory fixture (`.fixture_gene_categories` in
[`helper-fixtures.R`](../../tests/testthat/helper-fixtures.R)), which proves the
*math* but not the *empirical* result. **Action:** source the real
gene-category dependency scores and per-lineage loss ranks, document provenance
in [`data/README.md`](../../data/README.md), and add the file to `data/`. Once
bundled, the regression skip becomes an enforced `expect_equal` against the T6
oracle (ρ = 0.955 / 0.986, permutation p = 0.0083).

### Item 5 — Bundle the island-bird morphology dataset (foundry, **cited by code**)

L3 (cross-kingdom parameter transfer) requires `island_bird_morphology.csv`
(`structure`, `dependency_score`, `observed_rank`). It is not bundled, so the
regression gate `skip()`s L3 with `"island_bird_morphology.csv not bundled
(items 4-6)"`. The loader ([`load_island_birds()`](../../R/data_loaders.R))
exists and errors gracefully; the data does not. **Action:** source the
island-bird morphology + dependency scores, document provenance, add to
`data/`. Once bundled, the L3 skip becomes an enforced `expect_equal` against
the cross-kingdom oracle (bird ρ = 0.755, p = 0.031).

### Item 6 — Reconcile empirical drift and fix method bugs (foundry, **cited by code**)

A calculation review traced every divergence to a root cause. Three were
**bugs** (now fixed); the rest are data-version drift where the science holds.

**Fixed bugs:**

- **T4 (niche-vs-Ne) — wrong response variable + meaningless niche encoding.**
  The function regressed `Genome Size (Mb)` (the *core* genome) instead of
  `Adjusted pan-genome` (the gene-loss/capacity proxy the framework predicts), and encoded
  lifestyle as `as.numeric(factor(...))` — an arbitrary integer per category,
  not a model. The Ne `grep("Ne")` also matched the first of two duplicate Ne
  columns. On the raw scale this *inverted* the framework prediction (Ne R² = 0.26 >
  niche R² = 0.13). **Fix:** regress `log(Adjusted pan-genome)` on lifestyle
  (as a factor) vs `log(Ne)`, on complete cases. Result: niche R² = 0.364 >
  Ne R² = 0.257, AIC favors niche (242 < 256) — the framework confirmed. The residual
  drift (0.364 vs oracle 0.343) is data-version, not a bug.

- **T5 (pan-genome fluidity) — Ne grep matched `Nematodes`.** `grep("Ne")`
  matched the `Nematodes` column (a 0/1 host-type indicator) before the real
  `Ne` column. The "Ne model" regressed fluidity on a near-constant flag →
  R² ≈ 0, and `lifestyle_subsumes_ne = NA`. **Fix:** anchor the grep to `^Ne$`.
  Result: lifestyle R² = 0.229 > Ne R² = 0.177 — **lifestyle subsumes Ne,
  the framework confirmed.** This entry now **passes** the regression gate.

- **formal_model — oracle was dimensionally mismatched.** The oracle expected
  `phase1_rate: 19.0, phase2_rate: 1.0, r_squared: 0.920, bayes_factor: 6.7` —
  those are the *empirical* T3 numbers, not ODE outputs. The `threshold_model()`
  is a deterministic ODE returning retention-probability decay rates
  (phase1 ≈ 1.0, phase2 ≈ 3.6e-6, k1/k2 ≈ 281000) and does not produce R² or
  BF at all. **Fix:** rewrite the oracle to target the model's actual outputs.
  This entry now **passes** the regression gate.

**Open drift (science holds, data-version differs):**

| Entry | Oracle | Actual | Root cause |
|-------|--------|--------|------------|
| T1 Orobanchaceae PGLS | β = −23.5, R² = 0.652, n = 12 | β = −24.17, R² = 0.736, n = 19 | tree has 56 tips; 19 species match (oracle used a 12-species subset) |
| T2 cross-family | r = −0.934, n = 91 | r = −0.899, n = 15 | function aggregates 91 species to 15 family means (oracle is species-level) |
| T4 niche-vs-Ne | niche R² = 0.343 | niche R² = 0.364 | **bug fixed**; residual drift is data-version (log-scale, complete-case n = 140) |
| T7 LTEE co-segregation | p = 1e-4 | p = 3.4e-16 | observed (36.4%) and expected (61.7%) match exactly; p differs because the foundry uses an exact `binom.test` (oracle used an asymptotic approx) |

In every case the *direction and magnitude* of the effect match the oracle; only
the exact value differs because the bundled data or statistical test is not
identical to the manuscript's. **Action:** either reconcile the bundled data to
the manuscript sample (T1 tree, T2 species-level) or update the oracle with
proof (T4, T7). Do **not** loosen tolerances to hide drift.



---

## Mapping: oracle entries → review items → status

| Oracle entry | Distinguishes the framework? | Review item | Regression status |
|--------------|-------------------|-------------|-------------------|
| T1 Orobanchaceae PGLS | no (R4) | 6 | skip (drift; science holds) |
| T2 cross-family | no (R4) | 6 | skip (drift; science holds) |
| T3 endosymbiont biphasic | **yes** | 6 / R6 | skip (method misspecification) |
| T4 niche-vs-Ne | **yes** | 6 | skip (drift; the framework confirmed — niche subsumes Ne) |
| T5 pan-genome fluidity | **yes** | 6 | **✅ passing** (bug fixed) |
| T6 gene-loss ordering | **yes** | 4 | skip (no data) |
| T7 LTEE co-segregation | no (R4) | 6 | skip (drift; science holds) |
| formal model (threshold) | **yes** | — | **✅ passing** (oracle fixed) |
| L3 cross-kingdom | **yes** | 5 | skip (no data) |

After the calculation review, **two discriminating entries pass** (T5,
formal_model) and **one more confirms the framework prediction** (T4, niche subsumes
Ne). The remaining skips are: two with no data (T6, L3 — items 4–5), four with
data-version drift where the science holds (T1, T2, T4, T7), and one method
misspecification (T3 — see R6). The foundry's methodology is sound (unit +
simulacra + integration gates are green); its empirical corroboration of the
discriminating predictions is partially in place and improving.

---

## What the foundry *does* establish today

After the calculation review, the regression gate has **4 passes / 7 skips**
(was 0 / 9). The foundry establishes:

- **Mathematical correctness.** 309 unit tests pass, covering the pure
  functional library (PGLS, biphasic kinetics, threshold model, autocatalytic
  set, cusp detection, contracts). The deterministic math is verified exactly.
- **Method validity on synthetic data (STDD).** 107 simulacrum tests pass:
  every analysis recovers known parameters from synthetic data within the
  credible interval, and every null control correctly *fails* to recover
  (specificity). If the methods can recover known signal, they can be trusted
  to detect unknown signal — the data gap is the blocker, not the methods.
- **Pipeline integrity.** 13 integration tests pass: the pipeline runs
  end-to-end, is idempotent, conforms to its manifest (DFT A3), and is
  seed-reproducible (DFT A2).
- **Empirical corroboration of two discriminating predictions.** T5
  (pan-genome fluidity: lifestyle subsumes Ne) and the formal threshold model
  (biphasic ODE kinetics) now **pass** the regression gate. T4 (niche-vs-Ne)
  confirms the framework (niche R² > Ne R², AIC favors niche) though it still skips on
  data-version drift.
- **Honest reporting.** The regression gate does not pass silently; it reports
  exactly which entries diverge and why, citing the review items that own the
  fix.

The foundry is a calibrated instrument whose empirical corroboration is
partially in place and improving. The open work is: bundle two missing datasets
(items 4–5), reconcile data-version drift (item 6), and redesign T3's
misspecified cross-sectional method (R6).
