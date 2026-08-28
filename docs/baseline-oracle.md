# Baseline Oracle — §12 Manuscript Results

## What Is a Baseline Oracle?

A **baseline oracle** is a configuration file (`baseline/oracle.yml`) that stores every quantitative result reported in §12 of the monograph as **ground truth** — the value the manuscript claims, with a tolerance band specifying how much deviation is acceptable. The CI pipeline runs each test against the oracle: if the pipeline's output deviates from the baseline beyond tolerance, the gate fails. This means the numbers in the monograph are not claims — they are **reproducible artifacts**. Anyone can clone the repository, run the pipeline, and verify that the code produces the same values.

Each oracle entry is tagged with two boolean fields:

- **Supports valence** — does the result support the valence prediction?
- **Distinguishes from competitor** — does the result distinguish valence from a named competitor hypothesis?

Where `distinguishes_from_competitor: false`, the **caveat** field explains why. The foundry does not hide non-discriminating results — it labels them. A result that supports valence but does not distinguish it from relaxed selection is reported as exactly that, not as evidence for valence uniquely.

## Forest Plot

The forest plot shows every oracle value as a point with a blue tolerance band. The band is the acceptance region — if the pipeline's output falls within the band, the gate passes. Values to the left of zero are negative (loss, shedding, depletion); values to the right are positive (retention, protection, accumulation).

## Oracle Entries

### T1 — Orobanchaceae PGLS

**Prediction:** Plastome size correlates with parasitism level across Orobanchaceae species.
**Result:** β = −23.5 kb/level, R² = 0.652, p = 1.25 × 10⁻⁹, n = 12 species
**Supports valence:** Yes
**Distinguishes from competitor:** No
**Competitor:** Relaxed selection (Lahti et al., 2009) — predicts the same gradient
**Caveat:** Relaxed selection predicts the same pattern. The result is consistent with valence but does not discriminate it from the relaxed-selection alternative. The discriminating signal is in T4 and T6.

### T2 — Between-Family Correlation

**Prediction:** Family-mean plastome size correlates with family-mean parasitism across independent parasitic plant lineages.
**Result:** r = −0.934, n = 15 families, p = 1.39 × 10⁻⁴¹
**Supports valence:** Yes
**Distinguishes from competitor:** No
**Competitor:** Stochastic gene loss — also predicted by relaxed selection on photosynthetic genes
**Caveat:** This is a between-family correlation test, not a within-family replication. The n = 15 is families, not species. Non-discriminating.

### T3 — Endosymbiont Biphasic Kinetics

**Prediction:** Genome reduction follows biphasic kinetics (rapid then slow).
**Result:** R² = 0.920, threshold_biphasicity = 1.0, early/late temporal displacement ratio = 19.0×
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** Constant rate (Lynch, 2007), accelerating (Muller's ratchet)
**Caveat:** n = 10 genera; sensitivity to individual data points not fully tested. The biphasic signal is structural (threshold gate separating protected from unprotected traits), not a two-phase rate ratio. The displacement ratio reflects how completely Phase 1 finishes before Phase 2 begins.

### T4 — Niche vs Ne

**Prediction:** Niche breadth predicts gene loss better than Ne alone.
**Result:** Niche R² = 0.343 vs Ne R² = 0.198
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** Drift (Lynch, 2007) — predicts Ne as the sole driver
**Caveat:** Both R² values are modest. Niche wins but does not dominate. The discriminating signal is that niche breadth subsumes Ne as a predictor — not that Ne is irrelevant.

### T5 — Pan-Genome Fluidity

**Prediction:** Pan-genome openness tracks lifestyle (commensal vs free-living).
**Result:** Lifestyle subsumes Ne (pMCMC = 0.004, Dewar et al., 2024)
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** Ne-only model — lifestyle signal persists after controlling for Ne
**Caveat:** None. Published independent analysis (Dewar et al., 2024).

### T6 — Gene-Loss Ordering

**Prediction:** Integration-depth determines gene-loss order.
**Result:** ρ = 0.955 (Orobanchaceae), ρ = 0.986 (*Cuscuta*), cross-family concordance = 0.941, permutation p = 0.0083
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** Random loss — does not predict an ordering
**Caveat:** None. This is the strongest discriminating test. The permutation null is exact (6 of 720 possible orderings).

### T7 — LTEE Co-Segregation

**Prediction:** Function-loss mutations co-segregate with beneficial sweeps less than chance (passive drift in unused genes).
**Result:** 36.4% observed vs 61.7% expected, p = 0.0001
**Supports valence:** Yes (suggestive)
**Distinguishes from competitor:** No
**Competitor:** Independent assortment
**Caveat:** Hitchhiking confound (asexual system means all mutations hitchhike during sweeps). Arbitrary 2,000-generation window. Misspecified null. Reported as suggestive, not as a discriminating test.

### Formal Model — Empirical GLM

**Prediction:** Additive GLM (retention ~ dep + para): dep > 0 (protected), para < 0 (shed); cross-kingdom ρ > 0.
**Result:** dep = +0.84 (p = 0.0008), para = −1.86 (p < 0.0001), pseudo-R² = 0.55, cross-kingdom ρ = 0.755
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** dep ≤ 0 (random loss), para ns (relaxed selection), ρ ≤ 0 (no transfer)
**Caveat:** The dependency coefficient sign is the discriminating signal. The empirical GLM can fail (it fits real data); the theoretical ODE cannot (it is deterministic). The GLM is the honest test.

### L3 — Cross-Kingdom Parameter Transfer

**Prediction:** Plant-derived slope predicts bird morphological loss ordering with no refitting.
**Result:** ρ = 0.755, p = 0.031
**Supports valence:** Yes
**Distinguishes from competitor:** Yes
**Competitor:** Substrate independence — no transfer expected if substrates are genuinely independent
**Caveat:** Small sample (n = 7 morphological traits). Null is ranking concordance, not full permutation. The ordering claim is the substantive result; the magnitude of the slope transfer is secondary. Significant but should be treated as indicative rather than definitive.
