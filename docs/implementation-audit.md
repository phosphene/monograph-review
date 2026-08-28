# Implementation Audit — Formal Claims vs. Computational Verification

**Authors:** Jan Ritch-Frel, Ed Phillips

This document audits the gap between the formal claims of the valence framework and the computational implementation in the valence-foundry R package. It covers: which R functions implement which equations, whether the tests test the right things, whether the monograph numbers trace back to foundry outputs, and the remaining gaps.

---

## 1. Equation-to-Function Mapping

### 1.1 Formal Model (ODE)

| Equation | R function | File | Correct? |
|----------|-----------|------|----------|
| dC_i/dt = −λ · M(t) · C_i · I(d_i < θ) | `threshold_model()` | `R/formal_model.R` | Yes |
| M(t) = M₀ · exp(−αt) | `mismatch_function()` | `R/formal_model.R` | Yes |
| ∫₀ᵀ M(t)dt = (M₀/α) · (1 − e^{−αT}) | `retention_closed_form()` | `R/formal_model.R` | Yes |
| C_i(T) = exp(−λ · ∫₀ᵀ M(t)dt) | `retention_at_time()` | `R/formal_model.R` | Yes |
| C_i(∞) = exp(−λ · M₀/α) | `equilibrium_retention()` | `R/formal_model.R` | Yes |
| Phase transition time: t = −ln(threshold_fraction)/α | `phase_transition_time()` | `R/formal_model.R` | Yes |

**Audit status:** The ODE implementation is correct. The Euler integration is validated against the closed-form solution via `prove_convergence()`, which shows error decreasing from ~10⁻³ at 100 steps to ~10⁻⁶ at 10,000 steps. The C_i factor (current retention) in the ODE is essential — without it, the solution goes negative. The implementation includes it, matching the monograph's derivation.

**Caveat:** The equilibrium function `equilibrium_retention()` returns a bare numeric vector, not a `valence_equilibrium` S3 object. The S3 class exists (`R/formal_model_classes.R`) but the wrapper function does not use it. The invariant test for `valence_equilibrium` S3 methods is explicitly skipped (`skip("equilibrium_retention returns plain numeric for backward compat")`). This is a structural debt, not a numerical error.

### 1.2 Empirical Formal Model (GLM)

| Equation | R function | File | Correct? |
|----------|-----------|------|----------|
| retention ~ dep + para (quasibinomial GLM) | `empirical_formal_model()` | `R/formal_model.R` | Yes |
| Cross-kingdom transfer: bird_ρ = Spearman(predicted, observed) | `empirical_formal_model()` | `R/formal_model.R` | Yes |

**Audit status:** The GLM specification is correct (additive quasibinomial, logit link). The flattening correction (Remark R7) is applied — the original author's script had a data-flattening bug (`as.vector(t(retention))` is species-major; `rep(dep_scores, each=8)` is gene-major) that scrambled dep ↔ retention and produced the wrong sign (dep = −0.83). The foundry uses `as.vector(retention)` (gene-major), which gives the correct dep = +0.84 (p = 0.0008). The oracle baseline (`baseline/oracle.yml`) records the corrected values.

### 1.3 Cusp Catastrophe

| Equation | R function | File | Correct? |
|----------|-----------|------|----------|
| x³ + ax + b = 0 (equilibrium surface) | `prove_cusp_bifurcation()` | `R/proofs.R` | Yes |
| 4a³ + 27b² = 0 (bifurcation set) | `prove_cusp_bifurcation()` | `R/proofs.R` | Yes |
| A = ∫(x_hi − x_lo) db (hysteresis loop area) | `prove_hysteresis_loop_area()` | `R/proofs.R` | Yes |
| Forward/reverse sweep | `cusp_hysteresis_check()` | `R/cusp_catastrophe.R` | Yes |

**Audit status:** Correct. The cusp proofs are pure analytical + numeric proofs (DFT A1, A2, A6). The hysteresis loop area is validated against analytic integration. The branch-following contract was refactored from a stateful closure (using `<<-`, which hid the detection logic) to a pure function with explicit state threading — a documented improvement from the math review (Issue 4, resolved in Phase 3).

### 1.4 Autocatalytic Growth

| Equation | R function | File | Correct? |
|----------|-----------|------|----------|
| dN/dt = r·N·(1/2 + 1/2·N/(N+K)) | `prove_dd_sign()` | `R/proofs.R` | Yes |
| df/dN = rK / (2(N+K)²) > 0 | `prove_dd_sign()` | `R/proofs.R` | Yes |
| f(0) = r/2, f(∞) → r, bounded | `prove_autocatalytic_growth_rate()` | `R/proofs.R` | Yes |

**Audit status:** Correct. The proofs are pure analytical with numeric verification. The 100-random-parameter invariant tests confirm monotonicity and boundedness.

### 1.5 Economics (Formula-Grounded)

| Equation | R function | File | Correct? |
|----------|-----------|------|----------|
| ρ(θ) = ρ_sat · H(θ − θ*) | `fit_step_models()` | `R/economics_formula.R` | Yes |
| Step model fit (breakpoint search + AIC) | `rho_sat_prediction()` | `R/economics_formula.R` | Yes |
| Step vs logistic vs exponential AIC | `step_cdi_comparison()` | `R/economics_formula.R` | Yes |

**Audit status:** The step model fit is correct (grid search for breakpoint, RSS minimization, AIC computation). The formula prediction (ρ_sat ≈ 0.35) is hard-coded as a target value, not discovered from the data — this is correct because the formula derivation is the purpose of the test, not the data. The AIC comparison between step, sigmoid, and logistic is correctly implemented.

---

## 2. Test Coverage Audit

### 2.1 What the Tests Cover

| Test file | What it tests | Recovery? | Null control? |
|-----------|--------------|-----------|---------------|
| `test-simulacrum-param-recovery.R` | Parameter recovery (slope, R²) in synthetic PGLS | Yes | Yes (λ = 0) |
| `test-simulacrum-biphasic.R` | Biphasic model selection (logistic vs exponential) | Expected | Expected |
| `test-simulacrum-cusp.R` | Cusp hysteresis detection | Expected | Expected |
| `test-simulacrum-autocatalytic.R` | Diversity-dependence sign | Expected | Expected |
| `test-simulacrum-cross-kingdom.R` | Cross-kingdom parameter transfer | Expected | Expected |
| `test-unit-formal-model.R` | Unit tests: retention, threshold, phase transition | N/A | N/A |
| `test-invariants-formal-model.R` | 10 invariants across 1000 random parameter sets | N/A | N/A |
| `test-invariants-dynamics.R` | Cusp, autocatalytic, economics invariants | N/A | N/A |
| `test-unit-cusp-catastrophe.R` | Cusp bifurcation, hysteresis unit tests | N/A | N/A |
| `test-regression-baseline.R` | Oracle regression gate (manuscript values) | N/A | N/A |
| `test-integration-pipeline.R` | End-to-end pipeline, idempotency, manifest | N/A | N/A |

**Note:** "Expected" means the test file exists and the framework is set up, but we have not read the full content of all five simulacrum test files. The oracle baseline (`baseline/simulacra-oracle.yml`) defines the expected true parameters and null control criteria for all five simulacra.

### 2.2 What the Tests Should Cover But Do Not

**The monograph's §12 values are not fully regressed.** The baseline oracle (`baseline/oracle.yml`) records every manuscript value, but the regression gate (`test-regression-baseline.R`) skips most entries with explicit reasons:

| Entry | Status | Reason |
|-------|--------|--------|
| T1 (Orobanchaceae PGLS) | Skipped | Data drift / known statistical bugs |
| T2 (Cross-family) | Skipped | Data drift / known statistical bugs |
| T3 (Endosymbiont biphasic) | Skipped | Data drift |
| T4 (Niche vs Ne) | Skipped | Data drift |
| T5 (Pan-genome fluidity) | Skipped | Data drift |
| T6 (Gene-loss ordering) | Skipped | Gene-category dataset not bundled |
| T7 (LTEE co-segregation) | Running | Functional |
| Formal model (ODE) | Running | Deterministic, exact |
| Empirical formal model (GLM) | Skipped | Retention matrix not always bundled |
| Cross-kingdom L3 | Skipped | Bird data not always bundled |

The skip messages say "items 4-6" — referring to the review document's open items. The data drift means the bundled data no longer produces the manuscript values within tolerance. The regression gate is honest about this: it runs, compares, and skips with an explicit report of actual vs expected values, rather than silently passing or failing.

**The ρ formula is not tested.** The formula ρ(θ) = ρ_sat · H(θ − θ*) is derived in the Python analysis scripts (`scripts/three_move_analysis.py`, `scripts/formula_deep_analysis.py`), not in the R package. The foundry's formula-grounded economics functions (`rho_sat_prediction()`, `step_cdi_comparison()`) test the formula's predictions in economic data, but they do not test whether the formula itself is correct — they assume the formula and test whether economic systems conform to it. The formula's derivation (the three-move analysis) is not replicated in R.

**The θ* = 0 prediction is not directly tested.** The percolation argument that θ* = 0 is a formal proof, not a computational test. The foundry tests the consequence (systems at θ > 0 show ρ ≈ ρ_sat) but not the threshold location itself. A test that generates data at θ = 0.001, θ = 0.01, θ = 0.1, and θ = 0.5 and verifies that ρ is constant across all four would test the θ* = 0 prediction directly. Such a test does not exist.

### 2.3 Parameter Recovery + Null Controls: The Right Design

The simulacra use the correct test design: parameter recovery on synthetic data with known ground truth, plus a null control where the signal is absent. This is the standard for computational verification — Cartwright's simulacrum framework, as described in the simulacra documentation.

The existing simulacra cover: autocatalytic diversity-dependence, biphasic kinetics, cross-kingdom transfer, cusp bifurcation, and simple parameter recovery. Each has a null control.

**Gap:** The null controls are defined in the oracle YAML but we have not verified that every null control test is implemented and passing. The `test-simulacrum-param-recovery.R` file has a null control (λ = 0, tests that slope is near zero). The other simulacra test files need to be checked for null control implementation.

---

## 3. Monograph Number Traceability

### 3.1 Verified Numbers

| Monograph value | Foundry source | Traceable? |
|----------------|---------------|------------|
| T1: β = −23.5, R² = 0.652, p < 10⁻⁹ | `baseline/oracle.yml` | Yes, but not actively regressed |
| T2: r = −0.934, p = 1.39 × 10⁻⁴¹ | `baseline/oracle.yml` | Yes, but not actively regressed |
| T3: R² = 0.920, k1/k2 = 19.0 | `baseline/oracle.yml` | Yes, but not actively regressed |
| T4: niche R² = 0.343, Ne R² = 0.198 | `baseline/oracle.yml` | Yes, but not actively regressed |
| T5: lifestyle subsumes Ne | `baseline/oracle.yml` | Yes, but not actively regressed |
| T6: ρ = 0.955, p = 0.0083 | `baseline/oracle.yml` | Yes, but not bundled |
| Formal model: threshold_biphasicity = 1.0 | `baseline/oracle.yml` | Yes, actively regressed (deterministic, passes) |
| Empirical GLM: dep = +0.84, p = 0.0008 | `baseline/oracle.yml` | Yes, but not always bundled |
| L3: ρ = 0.755, p = 0.031 | `baseline/oracle.yml` | Yes, but not always bundled |

### 3.2 Numbers Not Yet Traceable

| Value | Why not traceable |
|-------|------------------|
| Orobanchaceae PGLS (T1) | Data drift: the bundled data no longer produces β = −23.5 within tolerance |
| Cross-family correlation (T2) | Data drift: same issue |
| Endosymbiont biphasic (T3) | Data drift: the R² = 0.920 is not reproduced from the bundled data |
| Niche vs Ne (T4) | Data drift: not reproduced |
| Pan-genome fluidity (T5) | Data drift: not reproduced |
| Gene-loss ordering (T6) | Gene-category dataset not bundled with the package |

The data drift is documented in the regression gate's skip messages. The review document (items 4-6) tracks the reconciliation. The regression gate is designed so that when the data/methods are reconciled, the skips become enforced `expect_equal` checks automatically — no code change is needed in the gate itself.

### 3.3 The ρ Formula Numbers

| Value | Source | Reproducible? |
|-------|--------|---------------|
| ρ_sat ≈ 0.35 | `data/formula-analysis/three_move_results.json` | Yes (Python scripts) |
| θ* = 0 | Percolation proof | Formal proof, not computational |
| Odds ratio ≈ 5.5 | `data/formula-analysis/three_move_results.json` | Yes (Python scripts) |
| Sodalis ρ = 0.353 | `data/t7-ltee/T7_SODALIS_RESULTS.md` | Yes (R package T7) |
| Buchnera ρ = 0.372 | `data/buchnera_rho_result.json` | Yes (Python fetch + match) |

The ρ formula derivation is primarily in Python. The R package contains the formula-grounded economics tests (`R/economics_formula.R`) that test the formula's predictions, but not the formula derivation itself. Porting the three-move analysis to R would close this gap.

---

## 4. Identified Gaps

### 4.1 Critical Gaps

1. **Data drift for T1–T5.** The monograph's §12 values are recorded in the oracle but not reproduced from the bundled data. The regression gate skips these entries. Until the data drift is resolved, the foundry cannot verify the central quantitative claims of the monograph.

2. **T6 data not bundled.** The gene-loss ordering test (ρ = 0.955, the strongest discriminating result) cannot run because the gene-category dataset is not included in the package. This is the most important single value to verify.

3. **L3 / cross-kingdom transfer not bundled.** The bird morphology data is not always bundled, so the cross-kingdom ρ = 0.755 (the most discriminating test of the framework) cannot be routinely verified.

### 4.2 Moderate Gaps

4. **ρ formula not in R.** The three-move analysis (Ohta, Fisher, Wimsatt) that derives ρ(θ) = ρ_sat · H(θ − θ*) is in Python, not R. The R package tests the formula's predictions but does not replicate the derivation.

5. **θ* = 0 not directly tested.** The percolation proof is formal, not computational. A simulacrum that tests whether the valence effect activates at θ = 0.001 (vs. requiring θ > 0.1) would test the prediction directly.

6. **Null controls not systematically verified.** Each simulacrum defines a null control in the oracle YAML, but we have not audited whether every null control test is implemented and passing. The oracle describes the null control criteria, but test coverage needs verification.

### 4.3 Minor Gaps

7. **S3 class debt in equilibrium_retention.** The function returns a bare numeric, not a `valence_equilibrium` S3 object. The invariant test skips the S3 method checks. This is structural debt, not a numerical error.

8. **Economics tests use synthetic data.** The formula-grounded economics tests (`rho_sat_prediction()`, `step_cdi_comparison()`) use synthetic data in their examples. Real economic data has not been tested, so the formula's economic predictions are unverified.

9. **No cross-platform reproducibility test.** The deterministic tests assume identical RNG on all platforms. The test uses `withr::with_seed()` with explicit Mersenne-Twister + Inversion kinds, but the test suite is not run on a second platform (e.g., Windows or macOS) to verify cross-platform reproducibility.

---

## 5. Summary

| Area | Status |
|------|--------|
| ODE implementation | ✅ Correct, validated against closed-form solution |
| GLM implementation | ✅ Correct, flattening bug fixed (Remark R7) |
| Cusp catastrophe proofs | ✅ Correct, analytic + numeric verified |
| Autocatalytic proofs | ✅ Correct, invariant tests pass |
| Simulacra design | ✅ Correct (recovery + null control structure) |
| Baseline oracle | ✅ Complete (all §12 values recorded) |
| Regression gate | ⚠️ Honest (skips with reasons, not silent failures) |
| T1–T5 data drift | ❌ Not reproduced from bundled data |
| T6 data bundled | ❌ Not bundled |
| L3 data bundled | ❌ Not always bundled |
| ρ formula in R | ❌ Python only |
| θ* = 0 computational test | ❌ Does not exist |
| Null control audit | ⚠️ Not systematically verified |
| S3 class consistency | ⚠️ Minor debt (equilibrium_retention) |
| Cross-platform reproducibility | ⚠️ Not tested |
| Economics real-data test | ❌ Not done |

The valence-foundry is a well-designed verification layer with a correct ODE implementation, proper simulacra design, and an honest regression gate. The critical gaps are the T1–T5 data drift and the T6/L3 missing data — once these are resolved, the regression gate will enforce all monograph values automatically. The ρ formula derivation is a secondary gap: the formula is consistent with the data and the economic tests test its predictions, but the derivation itself is not replicated in the R package.