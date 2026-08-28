---
uri: valence-foundry/design-spec
owner: edphos
status: draft
updated: 2026-08-18
---

# Valence Foundry — Design Specification

## Architectural Principles

### Separation of Concerns

Three layers, one-way dependency flow:

```
Layer 1: Generators (pure functions, no I/O)
    ↓
Layer 2: Fitters/Analyzers (pure functions, take data → return results)
    ↓
Layer 3: Tests (arrange-act-assert, call Layer 1 + Layer 2)
```

No layer calls upward. No generator imports a fitter. No fitter imports a test. No layer does I/O.

### DFT (Design-For-Testability)

Every function is:
- **Pure** — same inputs → same outputs, no side effects (A1)
- **Seeded** — RNG via `withr::with_seed`, never hidden (A2)
- **Proof-structured** — returns `list(values=..., metadata=...)` (A6)
- **Self-describing** — metadata contains generator name, params, convergence

### Module Boundaries

| Module | Responsibility | Files |
|--------|---------------|-------|
| `inst/simulacra/` | Synthetic data generators (valence claims) | one per generator |
| `inst/genealogy/` | Synthetic data generators (precursor environments) | one per generator |
| `R/` | Package exports, fitters, analyzers, formal model | one per concern |
| `tests/testthat/` | AAA tests, parametrized, null controls | one per simulacrum/genealogy stage |
| `tests/testthat/helper-*.R` | Source helpers — module loading only | two files |

### Naming

- Generators: `generate_<system>.R` — one function, same name as file
- Fitters: `fit_<model>.R` — returns list with AIC, parameters, model name
- Tests: `test-<module>-<behavior>.R` — describes what is tested
- Helpers: `helper-<module>.R` — sources generators for test env

---

## Layer 1: Generators

Each generator is a single file containing one function.

### Simulacra (valence claims)

| File | Function | Tests | Claim tested |
|------|----------|-------|-------------|
| `generate_step.R` | `generate_step_function` | `test-simulacrum-step-recovery.R` | ρ_sat recovery, θ*≈0 |
| `generate_sigmoid.R` | `generate_steep_sigmoid` | same | Step vs sigmoid discrimination |
| `generate_null_rho.R` | `generate_null_rho` | same | No false positives on flat data |
| `generate_percolation.R` | `generate_percolation_network` | same | θ*=0 on connected networks (FAILS — gap found) |
| `generate_autocatalytic.R` | existing | existing | Diversity-dependence detection |
| `generate_biphasic_genome.R` | existing | existing | Biphasic kinetics |
| `generate_cross_kingdom.R` | existing | existing | Cross-kingdom parameter transfer |
| `generate_cusp_system.R` | existing | existing | Cusp bifurcation |

### Genealogy (precursor environments)

| File | Function | Tests | Stage |
|------|----------|-------|-------|
| `generate_ising.R` | `generate_ising` | `test-genealogy-models.R` | 1: Ising (1925) |
| `generate_landau.R` | `generate_landau` | same | 2: Landau mean-field |
| `generate_cusp.R` | `generate_cusp` | same | 3: Thom cusp (1972) |
| `generate_drift_selection.R` | `generate_drift_selection` | same | 5: Drift-selection boundary |

### Generator contract

Every generator MUST return:

```r
list(
  values = list(...),      # Named scalars — ground truth parameters
  metadata = list(
    seed = <int>,
    data = <data.frame>,    # The synthetic data
    params = list(...),     # All input parameters
    generator = "<name>",   # Self-identification
    converged = <logical>   # Did the simulation converge?
  )
)
```

No I/O. No file reads. No network calls. No print statements.

---

## Layer 2: Fitters and Analyzers

Currently inlined in tests. Should be extracted into `R/` as proper exports.

### Planned fitters

| File | Function | Input | Output |
|------|----------|-------|--------|
| `R/fit_step.R` | `fit_step` | (theta, rho) | list(step=..., sigmoid=..., best_model=..., delta_aic=...) |
| `R/fit_landau.R` | `fit_landau` | (a, M) | list(M_eq=..., F_min=..., bifurcation=...) |

**DFT rule:** Fitters are pure functions. No RNG. No I/O. Deterministic given inputs.

### Current state

`fit_step` is inlined in `test-simulacrum-step-recovery.R`. This violates separation of concerns — the fitter is test infrastructure, not test logic. T4 will extract it.

---

## Layer 3: Tests

### AAA pattern (pytest-testing §1.1, applied to R)

- **Arrange:** call generator with known parameters
- **Act:** call fitter on generated data
- **Assert:** recovered parameters match ground truth, within tolerance

### Null controls

Every simulacrum has a null condition. If the pipeline reports signal in null data, the test fails.

### Parametrization

Tests sweep across:
- Parameter values (ρ_sat, θ*, noise_sd)
- Sample sizes (n=3, 5, 10, 20, 40)
- Random seeds (10+ replicates for consistency checks)

---

## Compositional Chain

```
Ising (MC) → Landau (mean-field) → Cusp (bifurcation) → ... → valence (step)
```

Each arrow is a mapping. The chain is tested by:
1. Each stage produces data from its own equations (genealogy tests)
2. Each stage's data, fed to the next stage's analyzer, produces consistent results (chain tests — T4, T6)
3. The final stage (valence step) is tested directly (step recovery simulacrum)

### Current gaps in the chain

| Gap | Between | Status |
|-----|---------|--------|
| Cusp → Percolation | Stage 3 → Stage 4 | T9: "structural analogy" — make formal or drop |
| Percolation → Drift-selection | Stage 4 → Stage 5 | No connection claimed |
| Drift-selection → valence | Stage 5 → Stage 6 | T2: does WF produce ρ_sat ≈ 0.35? |

---

## Dependency Graph

```
T1 (fix pre-existing) ── no dependencies
T2 (ρ_sat from WF) ── no dependencies
T3 (small-n discrimination) ── no dependencies
T4 (Landau→step pipeline) ── extracts fit_step into R/
T5 (percolation: repair or remove) ── decision needed
T6 (Ising→Landau formal) ── no dependencies
T7 (GitHub Pages simulacra) ── depends on T2, T3, T4 for content
T8 (banking upcycle) ── large, depends on T2 conceptually
T9 (cusp→percolation mapping) ── decision needed, related to T5
```

### Recommended execution order

1. T1 — clear the red tests (non-negotiable green)
2. T2 — ρ_sat from Wright-Fisher (fast, tests a paper claim)
3. T3 — small-n discrimination (fast, tests AIC validity)
4. T4 — extract `fit_step` into `R/`, Landau→step pipeline
5. T6 — Ising→Landau formal verification
6. T5 + T9 — percolation decision (after we know what the chain actually supports)
7. T7 — GitHub Pages (after the math is settled)
8. T8 — banking upcycle (large, separate effort)
