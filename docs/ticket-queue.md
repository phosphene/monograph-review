---
uri: valence-foundry/ticket-queue
owner: edphos
status: living
updated: 2026-08-18
---

# The Foundry — Ticket Queue

## Design Principles

1. **One generator per file.** No monoliths. No mere scripting.
2. **Pure functions (A1).** Seeded determinism (A2). Proof objects (A6).
3. **Solver separation.** Math decoupled from I/O.
4. **Compositional chain.** Each stage's output feeds the next.
5. **Honest claims.** Simulacra test what the paper claims. If a claim fails, the paper changes.
6. **Formula alignment.** All tickets serve the relaxation formula dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂), not the deprecated step function ρ(θ) = ρ_sat · H(θ − θ*).

---

## Resolved Tickets (T1–T9)

### T1: Fix pre-existing test failures — ✅ DONE
`generate_dd_series` implemented in `R/speculative.R`. Suite green.

### T2: ρ_sat from drift-selection — ✅ DONE (FALSIDIED)
Wright-Fisher simulation (`inst/genealogy/measure_rho_sat.R`) tested ρ_sat across N ∈ {100, 500, 1000} × delta_range ∈ {[0,0.01], [0,0.05], [0,0.1]}. **Result:** ρ_sat varies from ~0.0 to ~0.99. The value 0.35 is not recovered. Closest: 0.247 (N=1000, delta=[0,0.05]). The ρ_sat ≈ 0.35 claim is not supported by the simulation. Paper updated to relaxation formula — ρ_sat is no longer a parameter.

### T3: Small-n discrimination — ⚠️ STALE (SUPERSEDED)
Step-vs-sigmoid discrimination on n=3 points. Under relaxation formula, the cross-sectional question is bi-exp vs mono-exp vs breakpoint. **Covered by foundry Simulacrum 4** (discrete levels → step) and the island bird analysis (breakpoint model preferred, ΔAICc = 18.2). No further work needed.

### T4: Landau→Step pipeline — ⚠️ STALE (NEEDS REFRAMING)
Was: does Landau data run through step-fitter recover a step? Under relaxation formula: does Landau mean-field data, interpreted as relaxation toward equilibrium, produce bi-exponential decay? This is T11 (relaxation simulation). Reframed ticket created as T11.

### T5: Percolation — repair or remove — ❌ OBSOLETE
Percolation θ*=0 claim falsified. Genealogy doc already warns: "percolation and drift-selection links have been tested and do not hold." Dropped. The relaxation formula does not require a percolation threshold.

### T6: Ising→Landau formal verification — ⚠️ STALE (NEEDS REINTERPRETATION)
Algebraic identity is valid (Ising mean-field = Landau free energy). But the chain was framed as phase transition → step function. Under relaxation formula, the chain describes relaxation dynamics: Landau free energy defines the potential well; the Landau-Lifshitz equation is the time-dependent relaxation toward that well. This is the relaxation ODE itself. Reframed in T10.

### T7: Extended simulacra for GitHub Pages — ⚠️ STALE (NEEDS RELAXATION CONTENT)
GitHub Pages simulacra should show relaxation formula content: bi-exp fits, cross-kingdom parameter transfer, substrate independence. The existing simulacra 9-13 (Python) cover this. R/viz.R would need updating. Deferred until T13 (R package update).

### T8: Banking — upcycle model (Bagehot→Marx→equations) — ✅ KEEP
Independent of formula change. Ed's banking program. State variables: P_K, P_c, Q, D, W, λ. Goodwin predator-prey + Minsky debt accumulation. Start from Bagehot's Lombard Street. Effort: Large.

### T9: Genealogy — cusp→percolation mapping — ❌ OBSOLETE
Percolation link broken (T5). Cusp catastrophe still valid as the potential landscape, but the connection to percolation theory is not supported. Dropped.

---

## Active Tickets (T10–T15)

### T10: Rewrite genealogy doc for relaxation formula
**Problem:** `mathematical-genealogy.md` (3,500 words) presents the step function ρ(θ) = ρ_sat · H(θ − θ*) as the formula. The monograph has moved to dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂). The Ising → Landau → Cusp chain is valid but framed as phase transition dynamics; it should be framed as relaxation dynamics.

**Design:**
- Keep stages 1–3 (Ising, Landau, Cusp) with reinterpretation: the Landau free energy defines the equilibrium well; the Landau-Lifshitz equation dM/dt = −∂F/∂M is the relaxation ODE — same form as our formula.
- Archive stages 4–5 (percolation, drift-selection) as historical hypotheses that were tested and falsified. Keep the code; label honestly.
- Add new stage 5 (was 6): the relaxation formula as synthesis. Show that the Landau-Lifshitz relaxation equation with two channels (fast + slow) IS our formula.
- Update the chain diagram: Ising → Landau → Cusp → Relaxation (drop percolation and drift-selection from the active chain).

**Output:** Rewritten `mathematical-genealogy.md`.
**Effort:** Medium.
**Depends on:** T14 (honest labels first).

### T11: Add relaxation simulation (genealogy stage 6)
**Problem:** No code simulates dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) in the genealogy chain. The existing scripts simulate Ising (static equilibrium), Landau (static free energy), Cusp (bifurcation), but not the actual relaxation dynamics.

**Design:**
- New script `generate_relaxation.py` (or `.R`) that:
  1. Generates bi-exponential decay data from the formula with known k₁, k₂, ρ₁, ρ₂
  2. Shows two-phase decay: fast phase (k₁) shedding, slow phase (k₂) erosion
  3. Fits bi-exp, mono-exp, and linear; computes AIC comparison
  4. Produces proof object: parameter recovery within tolerance
- Compositional: feeds from the Cusp stage — the cusp potential defines the equilibrium well; relaxation is the trajectory toward it.
- Follows simulacrum protocol: seeded, deterministic, ground-truth known.

**Output:** `inst/genealogy/generate_relaxation.py` + test.
**Effort:** Small.
**Depends on:** T10 (goes in rewritten genealogy doc).

### T12: Port R genealogy scripts to Python
**Problem:** 6 R scripts in `inst/genealogy/` are solid code (real Metropolis MC, real Wright-Fisher), but the rest of the foundry is Python. Two-language stack creates friction for reproducibility and INFERNO Labs registration.

**Design:**
- Port `generate_ising.R` → `generate_ising.py` (Metropolis MC on 2D lattice)
- Port `generate_landau.R` → `generate_landau.py` (free energy minimization on M grid)
- Port `generate_cusp.R` → `generate_cusp.py` (cubic root finding, bifurcation set)
- Port `generate_drift_selection.R` → `generate_drift_selection.py` (Wright-Fisher)
- Keep R versions as reference implementations in `inst/genealogy/reference/`
- Include T11 (new relaxation simulation) as Python-native

**Output:** Python genealogy suite in `inst/genealogy/` (or `scripts/genealogy/`).
**Effort:** Medium.
**Depends on:** T11 (include relaxation stage in the port).

### T13: Update R package for relaxation formula
**Problem:** R package has 28 source files, 38 test files, ~12,700 lines, 8417 tests passing. Core modules reference the old step-function formula:
- `fit_step.R` fits the step function — needs `fit_biexp.R` equivalent
- `formal_model.R` implements the threshold model — needs relaxation ODE
- `economics_formula.R` may reference old formula
- `cusp_catastrophe.R` — still valid but context changes
- `proofs.R` — needs relaxation formula proofs

**Design:**
1. Audit all 22 R files for step-function dependencies
2. Add `fit_biexp.R` alongside `fit_step.R` (don't remove — keep for reproducibility)
3. Add `relaxation_model.R` alongside `formal_model.R`
4. Update tests: add bi-exp tests, keep step-function tests as regression
5. Verify 8417 tests still pass; add new tests for relaxation formula

**Output:** Updated R package, all tests green, relaxation formula supported.
**Effort:** Large.
**Depends on:** None (independent of T10-T12).

### T14: Honest provenance labels on genealogy stages
**Problem:** Genealogy stages 4–5 (percolation θ*=0, drift-selection ρ_sat≈0.35) are falsified by the foundry's own simulations but still presented without clear labeling in some contexts.

**Design:**
- Stage 1 (Ising): valid, label as "relaxation dynamics precursor"
- Stage 2 (Landau): valid, label as "equilibrium landscape"
- Stage 3 (Cusp): valid, label as "bifurcation geometry of relaxation"
- Stage 4 (percolation θ*=0): falsified, label as "historical hypothesis — tested in T2, not supported by simulation"
- Stage 5 (drift-selection ρ_sat≈0.35): falsified, label as "historical hypothesis — tested in T2, not supported by simulation"
- Stage 6 (relaxation formula): current formula, supported by 8/8 predictions

**Output:** Updated labels in `inst/genealogy/README.md` and `docs/mathematical-genealogy.md` header.
**Effort:** Small.
**Depends on:** None.

### T15: INFERNO Labs transposition — genealogy as registered pipeline
**Problem:** Genealogy simulations are R scripts in a directory. For INFERNO Labs, each stage should be a registered, versioned, DOI-trackable artifact with provenance chain.

**Design:**
- Each genealogy stage becomes an INFERNO Labs registered simulation:
  - Stage 1: Ising MC → registered with seed, params, output hash
  - Stage 2: Landau free energy → registered computation
  - Stage 3: Cusp bifurcation → registered computation
  - Stage 6: Relaxation formula → registered simulation
- Provenance chain: each stage's output is input to the next
- DOI-trackable: each stage gets a Zenodo DOI on archive
- Reproducibility: anyone can re-run the chain from Ising to relaxation with one command

**Output:** INFERNO Labs registered pipeline for the genealogy chain.
**Effort:** Medium-Large (depends on INFERNO Labs registration infrastructure).
**Depends on:** T12 (Python versions needed for registration).

---

## Status

| Ticket | Status | Effort | Assigned |
|--------|--------|--------|----------|
| T1 | ✅ Done | — | — |
| T2 | ✅ Done (falsified) | — | — |
| T3 | ⚠️ Stale (superseded) | — | — |
| T4 | ⚠️ Stale → T11 | — | — |
| T5 | ❌ Obsolete | — | — |
| T6 | ⚠️ Stale → T10 | — | — |
| T7 | ⚠️ Stale → deferred | — | — |
| T8 | ✅ Keep | Large | — |
| T9 | ❌ Obsolete | — | — |
| T10 | **Ready** | Medium | — |
| T11 | **Ready** | Small | — |
| T12 | **Ready** (after T11) | Medium | — |
| T13 | **Ready** | Large | — |
| T14 | **Ready** | Small | — |
| T15 | **Ready** (after T12) | Med-Large | — |

## Dependencies

```
T14 ── T10 (honest labels before rewrite)
T10 ── T11 (relaxation sim goes in rewritten genealogy)
T11 ── T12 (Python port includes relaxation stage)
T12 ── T15 (INFERNO needs Python versions)
T13 (R package — independent, large, can parallelize)
T8 (banking — independent, keep as-is)
```

## Recommended Execution Order

1. **T14** — Honest provenance labels (quick, unblocks T10)
2. **T10** — Rewrite genealogy doc for relaxation formula
3. **T11** — Add relaxation simulation
4. **T12** — Port R scripts to Python
5. **T13** — Update R package (large, parallelizable with T12)
6. **T15** — INFERNO Labs transposition
7. **T8** — Banking upcycle (independent, anytime)
