# Simulacra — Parameter Recovery Tests

## What Is a Simulacrum?

Following Cartwright (1983, *How the Laws of Physics Lie*), a **simulacrum** is a model that captures essential properties of a target system while being explicitly *not* the target system. In the Foundry, a simulacrum is a synthetic dataset with known ground-truth parameters — data generated from an equation whose parameters we chose, so that we know the correct answer before running the pipeline. The simulacrum is the only place in the testing pipeline where we have a known baseline. On real data, we do not know the right answer — that is why we are running the analysis. The simulacrum verifies that the pipeline can recover known parameters when the answer is provided; if it cannot, no result the pipeline produces on real data can be trusted.

A **parameter-recovery test** runs the full statistical pipeline on the simulacrum and asks: can the pipeline recover the parameters that generated the data? If it can, the methods are sound. If it cannot, the methods cannot be trusted on real data — no matter how significant the real results appear.

Each simulacrum includes a **null control**: a condition where no signal is present in the synthetic data. If the pipeline reports signal in the null condition, the test fails — the methods are producing false positives.

## Simulacra Summary

| Simulacrum | True parameter | Recovered | Recovery | Null control | Result |
|------------|----------------|-----------|----------|-------------|--------|
| Autocatalytic diversity-dependence | slope = 1.0 | 1.051 | 100% within CI | Pass | ✅ |
| Biphasic kinetics | rate = 0.08 | 0.0796 | 100% within CI | Pass | ✅ |
| Cross-kingdom transfer | slope = 0.6 | 0.833 | 100% within CI | Pass | ✅ |
| Cusp bifurcation | b = 0.1361 | 0.4094 | 100% within CI | Pass | ✅ |
| Parameter recovery | slope = −48750 | −46652 | 100% within CI | Pass | ✅ |

**Key to the table:**

- **True parameter**: the value we chose when generating the synthetic data. This is the correct answer.
- **Recovered**: the value the pipeline estimated from the synthetic data, without knowing the true value.
- **Recovery (within CI)**: the percentage of simulation runs where the recovered value falls within the credible interval of the true value. 100% means the pipeline never misses.
- **Null control**: whether the pipeline correctly reports *no signal* when the synthetic data contains no signal. "Pass" means the pipeline does not produce false positives.
- **Result**: ✅ means the simulacrum passes both recovery and null control.

## How to Read the 4-Panel Summaries

Each simulacrum produces a 4-panel figure. The panels serve distinct diagnostic purposes:

**Panel 1 — True vs. Recovered (top-left).** Each point represents one simulation run. The x-axis is the true parameter value (the value we put in); the y-axis is the recovered parameter value (the value the pipeline got out). If the pipeline is working, points cluster on the 1:1 diagonal line. Scatter away from the diagonal indicates estimation error. This panel answers: *does the pipeline recover the right number?*

**Panel 2 — Recovery Trajectory (top-right).** The x-axis is simulation iteration (run number); the y-axis is the recovered parameter. The horizontal line is the true value. If the pipeline is working, the recovered values hover around the true line across all iterations. Systematic drift away from the true line indicates bias — the pipeline consistently over- or under-estimates. This panel answers: *is the pipeline stable across runs, or does it drift?*

**Panel 3 — Parameter Space (bottom-left).** When a simulacrum has two or more parameters, this panel shows a scatter plot of recovered parameter pairs across all runs. The true parameter combination is marked. If the pipeline is working, the cloud of recovered pairs centers on the true combination. This panel answers: *do parameters interact in ways that destabilize recovery?*

**Panel 4 — Recovery Rate (bottom-right).** The x-axis is simulation iteration; the y-axis is the cumulative proportion of runs that recovered within the credible interval. If the pipeline is working, this line rises to 1.0 and stays there. If it plateaus below 1.0, some fraction of runs fail — indicating sensitivity to initial conditions or data noise. This panel answers: *what fraction of runs succeed, and is that fraction stable?*

## What Each Simulacrum Tests

### Autocatalytic Diversity-Dependence

**What it tests:** Whether the pipeline can detect **positive diversity-dependent speciation** — the pattern the framework predicts for the *Homo* lineage after the substrate shift from ecological to cultural niche exploitation. "Positive diversity-dependent" means that as species count increases, speciation rate increases (the system is autocatalytic: more species produce more speciation). The simulacrum generates data where speciation rate scales linearly with diversity (slope = 1.0). Recovery tests whether the pipeline's diversity-dependence detection correctly identifies the positive slope.

**What a failure would mean:** If the pipeline cannot detect diversity-dependent speciation in synthetic data where it exists by construction, the positive diversity-dependence reported for *Homo* (§3) could be a false negative or a mischaracterized signal. The null control verifies that the pipeline does not report diversity-dependence when none is present.

### Biphasic Kinetics

**What it tests:** Whether the pipeline can detect **biphasic decay** — the characteristic two-phase trajectory (rapid initial shedding, slow equilibrium erosion) that the framework predicts for capacity reallocation. "Biphasic" means the trajectory has two distinct phases: an early phase where the rate of capacity loss is high (organism entering a new niche, large mismatch) and a late phase where the rate is low (organism approaching equilibrium, only deeply integrated traits remain). The simulacrum generates data following a biphasic exponential decay model. Recovery tests whether the biphasic fit correctly identifies both phases.

**What a failure would mean:** If the pipeline cannot distinguish biphasic from monophasic decay in synthetic data, the biphasic kinetics reported for endosymbiont genome reduction (§12.1.4, R² = 0.920) could be an artifact of the fitting method rather than a genuine two-phase trajectory. The null control verifies that monophasic data is not misclassified as biphasic.

### Cross-Kingdom Transfer

**What it tests:** Whether a **parameter** (a numerical coefficient in the model) measured in one substrate can predict outcomes in another — the L3 cross-kingdom claim that is the most discriminating test of the framework. "Substrate" refers to the biological domain (e.g., plant plastid biochemistry vs. bird anatomy). The simulacrum generates data where the same underlying parameter governs loss ordering across two independent substrates. Recovery tests whether the pipeline correctly identifies the transfer.

**What a failure would mean:** If the pipeline cannot detect parameter transfer in synthetic data where it exists by construction, the cross-kingdom transfer reported for plants → birds (ρ = 0.755, §12.3.5) could be a chance concordance rather than a genuine shared principle. The null control verifies that unrelated substrates are not reported as concordant.

### Cusp Bifurcation

**What it tests:** Whether the pipeline can detect **hysteresis** (path dependence) — the formal analog of **irreversibility** in the framework under review. "Irreversibility" means that once a lineage crosses a commitment threshold, reversing the environmental parameter does not restore the ancestral state, because the developmental scaffolding has been reallocated. The **cusp catastrophe** is the mathematical structure the framework uses to formalize the **specialization trap** (the point where a lineage's commitment to a niche becomes structurally irreversible). The simulacrum generates data from a cusp catastrophe with known **bifurcation parameter** (the value at which the system jumps from one stable state to another). Recovery tests whether the pipeline correctly identifies the hysteresis.

**What a failure would mean:** If the pipeline cannot detect hysteresis in synthetic data where it exists by construction, the irreversibility claims throughout the monograph (§§10.7–10.9) lack computational support. The null control verifies that non-hysteretic systems are not misclassified.

### Parameter Recovery

**What it tests:** Whether the pipeline can recover a known **slope** (rate of change) from synthetic data with realistic noise structure. The true slope is extreme (−48750) to stress-test the pipeline's ability to recover parameter values at the boundary of numerical stability.

**What a failure would mean:** If the pipeline cannot recover parameters in the simple case, no parameter estimate in the monograph can be trusted. This is the foundational test — the floor of credibility.
