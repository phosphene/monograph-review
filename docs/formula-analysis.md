# Formula Analysis — Three-Move Derivation

> **⚠️ Updated August 2026:** The step function formula ρ(θ) = ρ_sat · H(θ − θ*) has been superseded by the relaxation formula dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂). Foundry simulacra showed the step function was a 3-point artifact (n=3 cannot distinguish step from sigmoid) and the percolation/drift-selection derivation paths did not hold. The formal chain Ising → Landau → Cusp is verified, but describes relaxation dynamics, not a phase transition. See [Economics Extrapolations](economics-extrapolations.md) for the updated formula and predictions.


**Author:** Flow Feel ([@FlowFeel](https://github.com/FlowFeel))
**Date:** August 2026
**License:** MIT

---

## What This Is

This document presents the **three-move analysis** for deriving the functional form of the framework's effect. The monograph proposes that the framework's effect on genome retention follows a substrate-shift equation: α(x) = −k_ecol + k_cult · σ((x − x*)/s). The question is whether the data falls on a recognizable curve — and if so, whether that curve matches the theory's prediction.

The analysis uses three epistemic moves, executed in parallel:

1. **Ohta (inductive):** Plot ρ vs θ across all systems. Let the data reveal the functional form.
2. **Fisher (decompositional):** Partition Sodalis retention variance into framework + essentiality + drift + hitchhiking.
3. **Wimsatt (triangulation):** Fit candidate functions, compare to the monograph's predicted form.

---

## Data Points

### Systems with comparable ρ (Spearman: iJO1366 dependency score vs binary retention)

| System | θ | ρ | p | n | Source |
|--------|------|-------|------|------|--------|
| LTEE (E. coli, free-living) | 0.000 | −0.039 | 0.137 | 754 | T7 redesigned |
| Sodalis (tsetse endosymbiont) | 0.044 | 0.353 | <0.0001 | 1366 | T7 Sodalis |
| Buchnera (aphid endosymbiont) | 0.500 | 0.372 | 5×10⁻⁴⁶ | 1367 | NCBI fetch + iJO1366 match |

### Orobanchaceae per-species ρ (different metric: cross-species PGLS)

| Species | Parasitism score | θ | ρ | p |
|---------|------|------|-------|------|
| Lindenbergia (autotroph) | 0 | 0.000 | — (constant) | — |
| Pedicularis | 1 | 0.250 | 0.664 | 0.150 |
| C. exaltata | 1.5 | 0.375 | 0.171 | 0.745 |
| C. gronovii | 2.5 | 0.625 | 0.454 | 0.366 |
| C. campestris | 3 | 0.750 | 0.552 | 0.256 |
| Boulardia | 3 | 0.750 | 0.857 | 0.029 |
| Epifagus | 3 | 0.750 | 0.857 | 0.029 |
| Conopholis | 4 | 1.000 | 0.664 | 0.150 |
| **Pooled (PGLS-corrected)** | — | 0.562 | **0.955** | **0.001** |

---

## Move 1 — Ohta: ρ vs θ

### Method

Plot the framework's effect size (ρ) against niche dependency parameter (θ) across all systems. θ measures the degree to which the environment (host) provides metabolic requirements — the control parameter. ρ measures how strongly gene-level dependency predicts retention — the order parameter.

### Results

**3 comparable ρ-θ points (same metric):**

| System | θ | ρ |
|--------|------|-------|
| LTEE | 0.000 | −0.039 |
| Sodalis | 0.044 | 0.353 |
| Buchnera | 0.500 | 0.372 |

**Key finding:** Sodalis (θ=0.04) and Buchnera (θ=0.50) have nearly identical ρ despite a 12× difference in θ. The framework's effect saturates immediately once symbiosis begins.

**11-point fit (including Orobanchaceae per-species):**

| Formula | Fit | R² |
|---------|-----|------|
| Power: ρ = 0.755·θ^0.301 | Best fit | 0.587 |
| √θ (mean-field): ρ = 0.828·√θ | | 0.541 |
| Sigmoid (3-param): ρ = 0.744/(1+exp(−5.48·(θ−0.205))) | | 0.525 |
| Logarithmic: ρ = 1.056·ln(θ+1.203) | | 0.504 |
| Sigmoid (ρ_max=1): ρ = 1/(1+exp(−2.92·(θ−0.419))) | | 0.491 |
| Linear: ρ = 0.635·θ + 0.224 | | 0.480 |

The power law wins on R², but the Orobanchaceae per-species points are noisy (n=6 gene categories per species). The PGLS-corrected point (ρ=0.955) is well above all fitted curves — phylogenetic correction removes shared-ancestry noise that inflates the raw Spearman denominator.

### Interpretation

The three comparable points (LTEE, Sodalis, Buchnera) show a **step function**, not a gradual sigmoid. ρ jumps from ~0 to ~0.35 at the onset of symbiosis and stays there regardless of how deep the dependency goes. The Orobanchaceae PGLS ρ=0.955 suggests the true ceiling is much higher than raw ρ indicates.

---

## Move 2 — Fisher: Sodalis Variance Partition

### Method

Within the Sodalis system (1,366 genes matched to iJO1366), partition retention variance into components: framework (dependency score), selection (essentiality), drift (baseline), and hitchhiking (residual).

### Results

| Component | Effect size | Metric |
|-----------|------------|--------|
| framework (high-dep minus low-dep retention) | +0.398 | Difference in retention rates |
| Selection (essential minus nonessential) | +0.388 | Difference in retention rates |
| Drift baseline | 0.428 | Overall retention rate |

**Logistic regression decomposition:**

| Model | AUC | ΔAUC (above 0.5) |
|-------|-----|------------------|
| framework (dependency score) | 0.656 | 0.156 |
| Essentiality | 0.622 | 0.122 |
| framework + Essentiality | 0.656 | 0.157 |

**Key finding:** Adding essentiality to the framework's measure gives **zero improvement** in AUC (0.656 → 0.656). The framework's measure subsumes essentiality entirely. The genes that are metabolically essential ARE the high-dependency genes — there is no independent selection signal beyond what dependency captures.

### Retention by dependency level

| Dependency bin | Retention rate | n |
|---------------|---------------|------|
| Low (≤0.01) | 33.6% | 1061 |
| Mid (0.01–0.5) | 78.4% | 37 |
| High (≥0.5) | 74.6% | 268 |

The jump from 34% to 78% between low and mid is the framework signal — it is not gradual but a **step within the system**. Genes with any non-trivial dependency (above 0.01) are retained at roughly twice the rate of zero-dependency genes.

---

## Move 3 — Wimsatt: Theory-Data Convergence

### Method

Compare empirical fits to the monograph's predicted functional forms:
1. Rate function: dC/dt = −k·M·f(I(C))
2. Substrate-shift: α(x) = −k_ecol + k_cult · σ((x−x*)/s)
3. Cusp catastrophe: S = f(a, b) — irreversibility threshold
4. Autocatalytic closure: Kauffman set

### Results

The sigmoid fit gives: θ* = 0.205, s = 5.48, ρ_max = 0.744. But with only 3 comparable points, the sigmoid's steepness parameter is poorly constrained. The key observation is that s appears very high — the transition is sharp, not gradual.

**The step function interpretation:** All three symbiotic systems show raw ρ ≈ 0.35–0.37 regardless of θ:

| System | θ | Raw ρ |
|--------|------|-------|
| Sodalis | 0.04 | 0.353 |
| Buchnera | 0.50 | 0.372 |
| Orobanchaceae (pooled) | 0.56 | 0.369 |

The raw framework's effect is constant across symbiotic systems at different dependency levels. This is consistent with a **first-order phase transition** (discontinuous jump), not a second-order transition (continuous sigmoid).

### Physics Attractor Mapping

The step-function finding maps directly onto physics attractor theory:

| framework concept | Physics analog |
|------------|---------------|
| θ (niche dependency) | T/Tc (reduced temperature) |
| ρ (the framework's effect) | M (magnetization, order parameter) |
| θ* (onset threshold) | Tc (Curie temperature) |
| ρ_sat (saturation level) | M_sat (saturation magnetization) |
| Basin switch | First-order phase transition |

Below θ*, the system is in the "free-living" attractor basin (full genome, no effect). Above θ*, it jumps to the "symbiotic" attractor basin (reducing genome, effect active). The jump is discontinuous — like water to ice, not like iron cooling through the Curie point.

This is the cusp catastrophe structure already in the monograph (§S5): the irreversibility threshold IS the basin-switching event. The formula's steepness s → ∞ because the cooperative coupling is very strong — once one gene's dependency triggers retention, it cascades through the network instantly. This is the "magnetic" effect: cooperative alignment, like spins locking into a ferromagnetic domain.

### Proposed Formula

$$\rho(\theta) = \rho_{\text{sat}} \cdot H(\theta - \theta^*)$$

Where:
- H is the Heaviside step function
- ρ_sat ≈ 0.35 (raw Spearman) or higher (PGLS-corrected)
- θ* is between 0 and 0.04 (extremely sharp transition)

The monograph's sigmoid α(x) = −k_ecol + k_cult · σ((x−x*)/s) is the smooth version of this step function. In the limit s → ∞, the sigmoid becomes the Heaviside. The data suggests s is very large — the cooperativity parameter is high.

---

## Limitations

1. **Only 3 comparable ρ-θ points.** The within-system ρ metric (Spearman of iJO1366 dependency vs binary retention) is only available for LTEE, Sodalis, and Buchnera. Carsonella was attempted but only 4 genes matched — too few for a reliable ρ. More endosymbiont systems require BLAST-based orthology, not gene-name matching.

2. **Orobanchaceae per-species points are noisy.** Each species has only 6 gene categories, giving very low statistical power. The PGLS-corrected ρ=0.955 is the robust value, but it uses a different metric (cross-species PGLS vs within-system Spearman).

3. **θ is not directly comparable across domains.** The θ for bacterial endosymbionts (genome ratio or aa pathway fraction) measures something different from the θ for Orobanchaceae (parasitism score). A unified θ metric based on metabolic complementarity would be more rigorous.

4. **PGLS correction is only available for Orobanchaceae.** If PGLS were applied to Sodalis and Buchnera, the raw ρ≈0.35 might increase toward 0.95 — or it might not. Without PGLS, we cannot distinguish "true saturation at 0.35" from "shared-ancestry noise inflating the denominator."

5. **The step-function interpretation relies on 2 points (Sodalis + Buchnera).** Two points cannot distinguish a step function from a very steep sigmoid. More intermediate-θ points would resolve this.

---

## Next Steps

1. **Compute ρ for Hodgkinia, Sulcia, Tremblaya** — requires BLAST-based orthology matching to iJO1366 (gene-name matching fails at extreme reduction).
2. **PGLS-correct Sodalis and Buchnera** — phylogenetic correction for within-system ρ to remove shared-ancestry noise.
3. **Unified θ metric** — compute metabolic complementarity (proportion of metabolic requirements externally provided) from metabolic models, not genome size ratios.
4. **Test the step-function prediction** — if the formula is Heaviside, then a system at θ just above θ* should show the same ρ as a system at θ → 1. Sodalis (θ=0.04) already supports this, but a system at θ=0.01 would be decisive.

---

## Reproducibility

All analysis code is in the repository:

| File | What it does |
|------|-------------|
| `scripts/three_move_analysis.py` | Main three-move analysis (Move 1, 2, 3) |
| `scripts/formula_deep_analysis.py` | 11-point comprehensive fit with all candidate formulas |
| `scripts/buchnera_rho.py` | NCBI fetch of Buchnera APS proteins + iJO1366 match + ρ computation |

Data files:

| File | What it contains |
|------|-----------------|
| `data/formula-analysis/three_move_results.json` | Numerical results from three-move analysis |
| `data/formula-analysis/formula_deep_results.json` | Numerical results from deep analysis |
| `data/formula-analysis/*.png` | All plots |
| `data/buchnera_rho_result.json` | Buchnera ρ computation result |
| `data/buchnera_gene_list.txt` | Buchnera gene names matched to iJO1366 |
| `data/t7-ltee/T7_SODALIS_RESULTS.md` | Full Sodalis analysis report |
| `data/t7-ltee/gene_dependency_scores.tsv` | iJO1366 FBA dependency scores |
| `data/orobanchaceae_retention_matrix.tsv` | Orobanchaceae gene retention data |
| `data/endosymbiont_genome_data.tsv` | Endosymbiont genus-level data (367 species) |

---

## Relation to Foundry Standards

This analysis extends the foundry's existing test suite (T1–T7, formal model, L3) with a new **formula derivation** track. The Python scripts are supplementary to the R package — they perform data fetching (NCBI API) and analysis that is not yet ported to R. The findings are consistent with:

- **T6 (gene-loss ordering):** ρ=0.955 (PGLS) — the strongest within-system result
- **T7 (LTEE co-segregation):** ρ≈0 for free-living — the null baseline
- **Formal model:** α(x) = −k_ecol + k_cult·σ((x−x*)/s) — the theoretical prediction
- **Cusp catastrophe:** the irreversibility threshold IS the step-function jump

The step-function finding (s → ∞ in the sigmoid limit) is a **new result** not in the monograph. It suggests the monograph's sigmoid is correct but its steepness is underestimated — the transition is sharper than predicted. This is consistent with the cusp catastrophe interpretation: the basin switch is discontinuous.
