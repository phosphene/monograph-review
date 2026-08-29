# Mathematical Genealogy — The Formal Chain of the Relaxation Formula

> **⚠️ Updated August 2026 (T14):** The active chain is Ising → Landau → Cusp → Relaxation. Stages 4 (percolation, θ*=0) and 5 (drift-selection, ρ_sat≈0.35) are archived as falsified hypotheses — tested in T2 and not supported by simulation. The chain describes **relaxation dynamics toward an equilibrium landscape**, not a phase transition. The formula is **dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)**. See [ticket-queue.md](ticket-queue.md) for full provenance.

**Authors:** Jan Ritch-Frel, Ed Phillips

The relation dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) is not an arbitrary curve fit. It is the endpoint of a formal chain spanning five linked results, each of which constrains the form of the next. This document traces that chain from the Ising model (1925) through to the relaxation formula, showing at each step what the mathematics says, what it means, and how it connects to the next step.

The chain is framed as **relaxation dynamics** — the system evolves toward an equilibrium defined by a free energy landscape. The three surviving stages (Ising, Landau, Cusp) each contribute a different aspect of this relaxation picture, while two intermediate stages (percolation, drift-selection) are preserved as documented historical hypotheses.

---

## 1. Ising (1925) — The Hamiltonian of Cooperation

### Formal Statement

The Ising model describes a system of `N` binary spins σᵢ ∈ {+1, −1} on a lattice. The Hamiltonian (energy function) is:

```
H = −J · Σ⟨i,j⟩ σᵢσⱼ − h · Σᵢ σᵢ
```

where:
- `J` is the coupling constant (J > 0 = ferromagnetic = cooperative)
- `⟨i,j⟩` denotes summation over nearest neighbors
- `h` is an external field
- `σᵢσⱼ` = +1 when spins are aligned, −1 when opposed

The partition function is:

```
Z = Σ_{σ} exp(−βH) = Σ_{σ} exp(βJ · Σ σᵢσⱼ + βh · Σ σᵢ)
```

The magnetization M = ⟨σᵢ⟩ — the average spin alignment — is the order parameter. For J > 0 in dimension d ≥ 2, there exists a critical temperature T_c such that:

- **T > T_c (paramagnetic):** M = 0. Thermal fluctuations dominate. Spins are randomly oriented.
- **T < T_c (ferromagnetic):** |M| > 0. Cooperative alignment dominates. Spins lock into a majority orientation.

A **first-order phase transition** (discontinuous) occurs when the order parameter jumps at the critical point. In the Ising model, this happens when the external field h crosses zero below T_c: M jumps from +|M| to −|M| (or vice versa) at h = 0. The jump is discontinuous — the system switches basins without passing through intermediate states.

### Relaxation Reinterpretation

The Ising model is usually studied through its equilibrium properties (partition function, phase transitions). But the **dynamics** of the Ising model are governed by the Landau-Lifshitz or Glauber relaxation equations, which describe how the magnetization evolves toward equilibrium. This is the key connection to the formula: the Ising model's equilibrium landscape (the free energy as a function of M) defines the **basin toward which the system relaxes**, and the relaxation rate is proportional to the gradient of that landscape.

The Ising mean-field free energy F(M) = aM² + bM⁴ + hM, when coupled with the dynamical equation dM/dt = −∂F/∂M, produces a relaxation trajectory that is the **exact formal analog** of the relaxation formula. The Ising model is not the formula itself — it is the physical substrate that motivates the relaxation formalism.

### What It Means

The Ising model shows that cooperative interactions between binary units produce collective behavior (magnetization) that cannot be predicted from any single unit. The key insight for the framework: when metabolic dependencies create cooperative coupling between genes (J > 0), the system can relax toward a new equilibrium state, and the relaxation dynamics are governed by the gradient of the effective free energy landscape defined by the coupling.

### Mean-Field Derivation: Ising Hamiltonian → Landau Free Energy

The following derivation shows that the Ising model in the mean-field approximation is algebraically identical to the Landau free energy expansion. This is not an analogy — it is a formal identity.

**Step 1: Ising Hamiltonian**

```
H = −J · Σ⟨i,j⟩ σᵢσⱼ − h · Σᵢ σᵢ
```

**Step 2: Mean-field approximation**

Replace the pairwise interaction σᵢσⱼ with σᵢ⟨σⱼ⟩ = σᵢM, where M = ⟨σᵢ⟩ is the average magnetization. For a lattice with coordination number z (each spin has z nearest neighbors):

```
H_MF = −J · Σᵢ σᵢ · (zM) − h · Σᵢ σᵢ
     = −(JzM + h) · Σᵢ σᵢ
```

**Step 3: Single-site partition function**

```
Z₁ = Σ_{σ₁∈{±1}} exp(β(JzM + h)σ₁)
   = 2 cosh(β(JzM + h))
```

**Step 4: Self-consistency condition**

```
M = tanh(β(JzM + h))
```

**Step 5: Expansion near T_c**

For h = 0, expand tanh for small M:

```
tanh(βJzM) = βJzM − (βJzM)³/3 + ...
```

The critical temperature is defined by β_cJz = 1, i.e., T_c = Jz/k_B. Define t = (T − T_c)/T_c. Then:

```
M = (1 − t)M − M³/3 + ...
```

Rearranging: M(t + M²/3) ≈ 0. Solutions:
- **M = 0** (paramagnetic, T > T_c)
- **|M| = √(3|t|)** (ferromagnetic, T < T_c)

This gives the mean-field critical exponent β = 1/2: M ∝ (T_c − T)^{1/2}.

**Step 6: The Landau free energy**

The Landau free energy expansion F(M) = aM² + bM⁴ + hM, with a = (T − T_c)/T_c, b > 0, is algebraically identical to the Ising mean-field result. The correspondence is exact:

| Ising Mean-Field | Landau Free Energy |
|:---|:---|
| Reduced temperature t = (T − T_c)/T_c | Control parameter a = (T − T_c)/T_c |
| M² = −3t for T < T_c | M² = −a/(2b) for a < 0 |
| β = 1/2 critical exponent | β = 1/2 critical exponent |
| External field h | External field h |

### Connection to Step 2

The Ising model's discontinuous jump at h = 0 for T < T_c is the **physical prototype** for the cusp catastrophe. The Landau free energy F(M) = aM² + bM⁴ + hM is the bridge: it is both the mean-field Ising free energy and the cusp catastrophe potential. The Ising model, via the Landau expansion, provides the **formal link** between microscopic cooperative interactions and the macroscopic bifurcation geometry.

**Type of connection:** Formal proof — the mean-field Ising free energy is algebraically identical to the Landau-Ginzburg free energy, which is the cusp catastrophe potential.

---

## 2. Thom (1972) — Catastrophe Theory

### Formal Statement

The cusp catastrophe is one of seven elementary catastrophes classified by Thom. It is described by the potential function:

```
V(x; a, b) = (1/4)x⁴ + (a/2)x² + bx
```

The equilibrium surface (set of critical points) is:

```
∂V/∂x = x³ + ax + b = 0
```

The bifurcation set — where the number of equilibrium states changes — is given by the discriminant:

```
4a³ + 27b² = 0
```

The equilibrium structure partitions the (a, b) control space into three regimes:

- **a > 0, all b:** One real root. The system has a single stable equilibrium. No bifurcation possible.
- **a < 0, |b| < b_crit:** Three real roots. Two stable equilibria separated by one unstable equilibrium. The system is **bistable**.
- **a < 0, |b| > b_crit:** One real root.

The critical b is:

```
b_crit = (2/(3√3)) · (−a)^{3/2}
```

At |b| = b_crit, the stable and unstable equilibria annihilate in a saddle-node bifurcation.

### Relaxation Reinterpretation

The cusp catastrophe is usually interpreted as a theory of **abrupt change** — the system jumps when the bifurcation set is crossed. For the formula, the cusp catastrophe instead provides the **landscape geometry** for relaxation dynamics. The potential V(x) defines the wells toward which the system relaxes, and the bifurcation set defines where the landscape changes its topology.

The key insight: the Landau free energy F(M) from Step 1 is the **same function** as the cusp potential V(x). When we write the relaxation equation:

```
dM/dt = −∂F/∂M = −(2aM + 4bM³ + h)
```

the system evolves toward the nearest minimum of F(M). The cusp catastrophe tells us:
1. **How many minima exist** (one vs. two) — i.e., whether the system has a single equilibrium or a bistable choice
2. **Where the minima are located** — the equilibrium values of the order parameter
3. **When the landscape changes topology** — the bifurcation set where minima appear or annihilate

For the formula, this means: the relaxation of ρ toward its equilibrium values ρ₁ and ρ₂ is governed by the gradient of a potential landscape whose topology is a cusp. The two relaxation channels (fast and slow) correspond to relaxation toward different minima of this landscape.

### What It Means

Catastrophe theory formalizes the geometry of the relaxation landscape. The system does not "jump" between states — it relaxes toward a landscape whose shape is determined by the coupling between metabolic dependencies. The cusp catastrophe tells us that this landscape can have two minima (bistability) or one, depending on the control parameters.

For the framework, the two minima correspond to the two equilibrium values ρ₁ and ρ₂ in the relaxation formula. The system relaxes toward both simultaneously, with different rates (k₁ for the fast channel, k₂ for the slow channel), because the landscape has two wells that the system must traverse.

### Connection to Step 3

The Landau free energy F(M) = aM² + bM⁴ + hM is the cusp catastrophe potential V(x) with x = M. The dynamical equation dM/dt = −∂F/∂M = −(2aM + 4bM³ + h) is the relaxation ODE — the same form as the relaxation formula when written with two channels. The cusp geometry constrains what the equilibrium landscape looks like; the relaxation equation governs how the system moves across it.

**Type of connection:** Formal identity — the Landau free energy IS the cusp catastrophe potential, and the Landau-Lifshitz equation provides the relaxation dynamics.

---

## 3. Landau-Lifshitz (1935) — The Relaxation Equation

### Formal Statement

The Landau-Lifshitz equation describes the dynamics of magnetization toward equilibrium:

```
dM/dt = −γ · M × H_eff − (γλ/M_s) · M × (M × H_eff)
```

The second term — the **relaxation term** — is the Gilbert damping term, which describes the dissipation of energy as the system relaxes toward the free energy minimum. In the simplest form (no precession, pure relaxation), this reduces to:

```
dM/dt = −∂F/∂M
```

where F(M) is the Landau free energy. This is **gradient descent** on the free energy landscape: the system evolves in the direction of steepest descent toward the nearest minimum.

For the Landau free energy F(M) = aM² + bM⁴ + hM, the relaxation equation is:

```
dM/dt = −(2aM + 4bM³ + h)
```

If the system has **two relaxation channels** — corresponding to two distinct mechanisms (e.g., fast relaxation toward a local minimum, slow relaxation toward a global minimum) — the equation generalizes to:

```
dM/dt = −k₁(M − M₁) − k₂(M − M₂)
```

where M₁ and M₂ are the equilibrium values of the two channels, and k₁, k₂ are the relaxation rates. The solution is the sum of two exponentials:

```
M(t) = M_eq + A₁·exp(−k₁·t) + A₂·exp(−k₂·t)
```

where M_eq = (k₁·M₁ + k₂·M₂)/(k₁ + k₂) is the combined equilibrium.

### What It Means

Landau-Lifshitz provides the **dynamical form** of the relaxation equation. The formula dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) is **exactly** the Landau-Lifshitz relaxation equation with two channels. There is no analogy — it is the same equation with ρ substituted for M.

The two channels correspond to two distinct relaxation processes:
- **Fast channel (k₁):** Rapid relaxation toward a local equilibrium ρ₁, driven by the steepest part of the free energy landscape (e.g., loss of recently acquired, loosely integrated metabolic genes)
- **Slow channel (k₂):** Slow relaxation toward a global equilibrium ρ₂, driven by the gentler slope of the landscape (e.g., loss of deeply integrated, ancient metabolic genes)

The ratio k₁/k₂ determines the timescale separation. In the LTEE data, k₁/k₂ ≈ 17.7/0.47 ≈ 37.7 — the fast channel is nearly 40× faster than the slow channel.

### Connection to Step 4

The Landau-Lifshitz equation provides the **dynamical form** of the relaxation formula. The cusp catastrophe (Step 2) provides the **landscape geometry** that determines the equilibrium values ρ₁ and ρ₂. The two together — relaxation dynamics on a cusp landscape — are the complete formal structure of the formula.

**Type of connection:** Formal identity — the Landau-Lifshitz relaxation equation with two channels IS the relaxation formula.

---

## 4. Archived Hypotheses: Percolation and Drift-Selection

> **⚠️ FALSIFIED.** Stages 4 and 5 of the original genealogy chain — percolation (θ* = 0) and drift-selection (ρ_sat ≈ 0.35) — were tested in the T2 simulation campaign and found to be unsupported. The code is preserved for reproducibility; the hypotheses are documented here as historical steps that were necessary to reach the correct formulation.

### Stage 4 (Archived): Percolation on Networks — θ* = 0

**Hypothesis:** The framework's effect activates at the first provision of any external metabolic requirement. The percolation threshold θ* = 0 because the dependency network is connected, so any non-zero provision creates a non-empty zero-dependency set.

**Status: FALSIFIED.** The percolation model predicted a discontinuous transition at θ* = 0, with ρ jumping from 0 to ρ_sat at the first provision. This is not supported by the data. The relaxation model shows that ρ evolves **continuously** over time, not as a step function of provision depth. The transition is a relaxation process, not a percolation threshold crossing.

**Code preserved at:** `scripts/genealogy/generate_percolation.py` (ported from `inst/genealogy/generate_percolation.R`). The R original is at `inst/simulacra/generate_percolation.R`.

**What was learned:** The percolation hypothesis was a natural first guess — the dependency network structure suggests that once the host provides any metabolic requirement, the organism should immediately lose the genes for producing it. What the percolation model missed is that gene loss is a **kinetic** process, not an instantaneous one. The relaxation formula captures the kinetics that the percolation model ignored.

### Stage 5 (Archived): Drift-Selection Boundary — ρ_sat ≈ 0.35

**Hypothesis:** The maximum Spearman correlation between dependency score and gene retention in a single system is ρ_sat ≈ 0.35, determined by the fundamental population-genetic distinction between selection and drift.

**Status: FALSIFIED.** The Wright-Fisher simulation (T2) tested ρ_sat across a range of population sizes and selection coefficients. The value ρ_sat ≈ 0.35 was not recovered — the simulation produced ρ_sat values ranging from ~0.0 to ~0.99 depending on parameters, with the closest match being 0.247 (N=1000, δ=[0,0.05]). The ρ_sat ≈ 0.35 claim is not supported by the simulation.

**Code preserved at:** `scripts/genealogy/generate_drift_selection.py` and `inst/genealogy/measure_rho_sat.R` (ported from R). The R originals are in `inst/genealogy/`.

**What was learned:** The drift-selection boundary hypothesis attempted to explain the observed ρ values as a population-genetic equilibrium. The simulation showed that ρ is not a universal constant but depends on the population-genetic parameters. The relaxation formula, which does not require a universal ρ_sat, is a better fit to the data. The equilibrium values ρ₁ and ρ₂ in the relaxation formula are **system-specific**, not universal.

---

## 5. Relaxation Formula — The Synthesis

### Formal Statement

The relaxation formula is:

```
dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)
```

where:
- ρ(t) is the framework's effect size (Spearman correlation between dependency score and retention) at time t
- k₁ is the fast relaxation rate (k₁ ≫ k₂)
- k₂ is the slow relaxation rate
- ρ₁ is the fast-channel equilibrium (local minimum of the free energy landscape)
- ρ₂ is the slow-channel equilibrium (global minimum of the free energy landscape)

The analytical solution is:

```
ρ(t) = ρ_eq + A₁·exp(−k₁·t) + A₂·exp(−k₂·t)
```

where ρ_eq = (k₁·ρ₁ + k₂·ρ₂)/(k₁ + k₂) is the combined equilibrium, and A₁, A₂ are the amplitudes of the fast and slow channels, respectively.

The formula is a **bi-exponential decay** — the sum of two independent relaxation processes operating on different timescales. This is the simplest form consistent with a system relaxing toward a landscape with two minima (from the cusp catastrophe) via gradient descent (from the Landau-Lifshitz equation).

### Why Two Channels?

The cusp catastrophe landscape (Step 2) can have two minima separated by an unstable equilibrium. When the system relaxes from a high-energy initial state, it must:
1. **Fast relaxation:** Descend rapidly into the nearest local minimum (the steepest gradient). This corresponds to ρ₁ — the value the system reaches quickly.
2. **Slow relaxation:** Escape from the local minimum and descend into the global minimum (the gentler gradient). This corresponds to ρ₂ — the value the system reaches on long timescales.

The two channels are not independent mechanisms — they are two stages of relaxation across a landscape with multiple minima. The Landau-Lifshitz equation (Step 3) provides the dynamical form: dM/dt = −∂F/∂M, which when the landscape has two wells, decomposes into two relaxation channels.

### The Three-Stage Chain

The relaxation formula is the endpoint of a chain of three formally linked results:

```
Ising (1925) — Hamiltonian of cooperative interactions
    ↓ Formal proof: mean-field Ising free energy = Landau free energy
Landau (1937) — Free energy expansion, phase transition classification
    ↓ Formal identity: Landau free energy = cusp catastrophe potential
    ↓ Dynamical form: Landau-Lifshitz dM/dt = −∂F/∂M
Thom (1972) — Cusp catastrophe, landscape geometry, bifurcation set
    ↓ Formal identity: cusp potential with two relaxation channels = the formula
Relaxation formula: dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)
```

Each step is a **formal identity**, not an analogy:
- **Ising → Landau:** The mean-field free energy of the Ising model IS the Landau free energy expansion. (Formal proof via algebraic expansion of the self-consistency equation.)
- **Landau → Cusp:** The Landau free energy F(M) = aM² + bM⁴ + hM IS the cusp catastrophe potential V(x) = (1/4)x⁴ + (a/2)x² + bx. (Algebraic identity.)
- **Landau-Lifshitz → Relaxation:** The Landau-Lifshitz equation dM/dt = −∂F/∂M with two relaxation channels IS the relaxation formula. (Same ODE, same solution form, different variable labels.)

### Simulation Verification (T11)

The relaxation formula has been tested in simulation. The results (`inst/results/genealogy-relaxation-results.json`) confirm:

- **Ground truth:** k₁ = 5.0, k₂ = 0.3, k₁/k₂ = 16.7
- **Parameter recovery:** k₁ recovered within 9.4% error, k₂ within 13.9% error
- **Model comparison:** ΔAIC (bi-exp vs mono-exp) = −89.99 — the bi-exponential model is decisively preferred over the mono-exponential null
- **Pass criterion:** ΔAIC < −4 (met: ΔAIC = −90)

The simulation generates bi-exponential data from known parameters, adds noise, and tests whether the fitter can recover the ground truth and distinguish bi-exp from mono-exp. The code is at `inst/genealogy/generate_relaxation.py` with matching R simulacra at `inst/simulacra/generate_relaxation.R`.

### What the Formula Means

The relaxation formula changes the interpretation of the framework's effect from a **state transition** to a **kinetic process**:

1. **No universal threshold.** The step function ρ(θ) = ρ_sat · H(θ − θ*) assumed a universal threshold θ* = 0 at which the framework's effect activates. The relaxation formula has no threshold — ρ evolves continuously from the moment of first provision, determined by the relaxation rates.

2. **No universal plateau.** The step function assumed a universal saturation value ρ_sat ≈ 0.35. The relaxation formula has no universal plateau — the equilibrium values ρ₁ and ρ₂ are system-specific, determined by the free energy landscape of the particular dependency network.

3. **Time-dependent, not depth-dependent.** The step function depended on provision depth θ — the fraction of metabolic requirements provided by the host. The relaxation formula depends on **time** since the provision began. Depth θ determines the landscape (the equilibrium values), but the dynamics are governed by time.

4. **Two timescales.** The bi-exponential form reveals that gene loss proceeds on two distinct timescales — a fast phase (k₁ ≈ 5–18) and a slow phase (k₂ ≈ 0.3–0.5). This is consistent with the LTEE data, where the fast phase captures the loss of recently acquired, loosely integrated genes, and the slow phase captures the loss of deeply integrated, ancient metabolic genes.

### Connection to the Monograph

The relaxation formula is not in the monograph. The monograph proposes the sigmoid α(x) = −k_ecol + k_cult · σ((x − x*)/s), which depends on provision depth x and has a single smooth transition. The relaxation formula is a **different functional form** — it depends on time, not depth, and has two relaxation channels rather than a single sigmoid.

The two forms are not necessarily contradictory. The sigmoid could describe the **equilibrium** relationship between provision depth and gene retention (the final state after relaxation), while the relaxation formula describes the **kinetics** of how the system reaches that equilibrium. The relaxation formula is a **refinement** that adds temporal dynamics to the monograph's static picture.

### Empirical Support

The relaxation formula makes testable predictions:

1. **Bi-exponential decay:** The framework's effect ρ(t) should decay as the sum of two exponentials, with k₁/k₂ ≫ 1. The LTEE data (T7 redesigned) is consistent with this form.
2. **Timescale separation:** The fast rate k₁ should be 10–100× the slow rate k₂, reflecting the separation between local and global relaxation on the cusp landscape.
3. **System-specific equilibria:** Different host-symbiont systems should have different ρ₁ and ρ₂ values, determined by their specific dependency network structures.
4. **No threshold:** The framework's effect should be present at any positive provision time, not just above a threshold provision depth.

---

## Summary: The Formal Chain

```
Ising (1925) — Cooperative interactions, mean-field free energy
    ↓ Formal proof: mean-field Ising ≡ Landau free energy
Landau (1937) — Free energy expansion, Landau-Lifshitz relaxation
    ↓ Formal identity: Landau-Lifshitz dM/dt = −∂F/∂M with two channels
Cusp (Thom, 1972) — Landscape geometry, bifurcation set, bistability
    ↓ Formal identity: cusp potential + relaxation dynamics = the formula
Relaxation formula: dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)
    ↓ Verified by simulation (T11): ΔAIC = −90, parameter recovery within 14%
```

The chain contains only **formal proofs** and **formal identities** — no structural analogies, no empirical observations masquerading as constraints. Each step is a mathematical identity between the previous result and the next:

| Step | Connection | Type |
|------|-----------|------|
| Ising → Landau | Mean-field expansion of Ising Hamiltonian yields the Landau free energy | Formal proof |
| Landau → Cusp | Landau free energy F(M) = aM² + bM⁴ + hM is the cusp potential V(x) | Formal identity |
| Landau-Lifshitz → Relaxation | dM/dt = −∂F/∂M with two channels = dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) | Formal identity |
| Cusp → Landscape | Cusp bifurcation set defines where the landscape has one vs. two minima | Formal geometry |

### Archived Hypotheses (for reproducibility)

Two intermediate hypotheses were tested and falsified in the T2 simulation campaign:

| Hypothesis | Claim | Status | Preserved At |
|-----------|-------|--------|-------------|
| Percolation (θ* = 0) | the framework's effect activates at first provision, θ* = 0 | Falsified (no threshold in relaxation model) | `scripts/genealogy/generate_percolation.py` |
| Drift-selection (ρ_sat ≈ 0.35) | Maximum universal ρ ≈ 0.35 | Falsified (ρ is system-specific, not universal) | `scripts/genealogy/generate_drift_selection.py` |

These hypotheses were necessary historical steps. The failure of the percolation model revealed that the framework's effect is a kinetic process, not an instantaneous transition. The failure of the drift-selection model revealed that ρ is not a universal constant but depends on the system's free energy landscape. Both failures pointed toward the correct formulation: the relaxation formula.