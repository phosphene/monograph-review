---
uri: valence-foundry/genealogy-models
owner: edphos
status: living
updated: 2026-08-18
---

# Genealogy Models — Runnable Precursor Environments

Each stage in the mathematical genealogy of the framework formula is implemented as a
runnable simulation that **generates data from the equations of that era**.
The genealogy is not prose — it is executable code that reproduces the
behavior of each precursor environment.

## Stages

| Stage | Environment | Equation | Status | Output |
|-------|-------------|----------|--------|-------|
| 1 | Ising (1925) | H = -J Σ σᵢσⱼ - h Σ σᵢ | ✅ Valid (relaxation precursor) | Magnetization vs T/Tc |
| 2 | Landau mean-field (1937) | F(M) = aM² + bM⁴ + hM | ✅ Valid (equilibrium landscape) | Free energy landscape |
| 3 | Thom cusp (1972) | V(x) = ¼x⁴ + ½ax² + bx | ✅ Valid (bifurcation geometry) | Bifurcation diagram |
| 4 | Percolation on networks | Z(S) = {v : dep(v) ⊆ S} | ❌ Falsified (T2/T5) | — |
| 5 | Drift-selection boundary | P(retain\|δ>0) - P(retain\|δ=0) | ❌ Falsified (T2: ρ_sat ≠ 0.35) | — |
| 6 | Relaxation formula | dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) | ✅ Current formula (8/8 predictions) | Bi-exponential decay |

### Stage provenance notes

- **Stages 1–3** are valid and form the active chain: Ising → Landau → Cusp.
  The chain describes **relaxation dynamics**, not a phase transition. The
  Landau-Lifshitz equation dM/dt = −∂F/∂M is the time-dependent relaxation
  toward the Landau equilibrium — same ODE form as the relaxation formula.

- **Stage 4** (percolation, θ* = 0): historical hypothesis. Tested in T2 and T5.
  The percolation threshold claim was not supported by simulation. Archived;
  not part of the active chain.

- **Stage 5** (drift-selection, ρ_sat ≈ 0.35): historical hypothesis. Tested in T2
  via Wright-Fisher simulation (`measure_rho_sat.R`). The value 0.35 was not
  recovered across a 9-point parameter grid (range: 0.0–0.99). Archived;
  not part of the active chain.

- **Stage 6** (relaxation formula): the current formula. Supported by 8/8
  predictions tested across DNA, neural, and behavioral substrates. The
  Landau-Lifshitz relaxation equation from stage 2 IS the relaxation formula
  when written with two channels: dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂).

## Compositional Chain (Active)

```
Ising (1925) — cooperative dynamics
    ↓ Formal proof: mean-field → Landau (algebraic identity)
Landau (1937) — equilibrium landscape, relaxation ODE
    ↓ The cusp is the bifurcation geometry of that landscape
Cusp (1972) — irreversibility structure
    ↓ Relaxation toward the cusp-defined equilibrium IS the formula
Relaxation formula (2026) — dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)
```

Each stage produces a data frame with known ground-truth parameters,
following the simulacrum protocol (Cartwright 1983). The chain is
compositional: each stage's output is the input to the next.
