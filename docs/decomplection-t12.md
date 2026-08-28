---
uri: vi-foundry/docs/decomplection-t12
title: T12 — Genealogy Script Decomplection Report
author: Flow
status: complete
version: 1.0.0
updated: 2026-08-19
tags:
  - t12
  - decomplection
  - genealogy
  - phosphene-genealogy
  - py-arch-001
---

# T12 — Genealogy Script Decomplection Report

## Objective

Rewrite the six genealogy scripts as thin runners that import from
`phosphene.genealogy` instead of duplicating mathematical logic.

## Before

Six scripts, each containing duplicated math functions (formulas, AIC,
model fitting, ODEs) tangled with I/O code (parameter setup, simulation
loops, JSON output, console summaries).

| Script | Before (lines) | Duplicated functions |
|--------|--------------|----------------------|
| `generate_ising.py` | ~165 | `metropolis_sweep`, `ising_hamiltonian` (inline) |
| `generate_landau.py` | ~152 | `landau_free_energy`, `find_equilibrium` |
| `generate_cusp.py` | ~213 | `cusp_potential`, `cubic_discriminant`, `solve_cubic_*` |
| `generate_drift_selection.py` | ~160 | `wright_fisher_fixation` |
| `generate_upcycle.py` | ~280 | `sigmoid`, `upcycle_ode`, `bi_exp_growth`, `mono_exp_growth`, `linear_growth`, `compute_aic`, `fit_accumulation_models` |
| `generate_relaxation.py` | ~222 | `relaxation_ode`, `mono_exp`, `linear_model`, `compute_aic`, `fit_models` |
| **Total** | **~1,192** | |

## After

Six thin runners + one pure functional core + tests.

| Component | After (lines) | Role |
|-----------|-------------|------|
| `formulas.py` | 744 | Pure functional core — all math, zero I/O |
| `models.py` | 53 | Frozen dataclasses for results |
| `test_formulas.py` | 391 | 40 AAA-pattern unit tests |
| `generate_ising.py` | 57 | Thin runner — I/O only |
| `generate_landau.py` | 55 | Thin runner — I/O only |
| `generate_cusp.py` | 77 | Thin runner — I/O only |
| `generate_drift_selection.py` | 61 | Thin runner — I/O only |
| `generate_upcycle.py` | 115 | Thin runner + posture classification (domain-specific) |
| `generate_relaxation.py` | 122 | Thin runner — I/O only |
| **Package total** | **1,188** | |
| **Scripts total** | **487** | |
| **Grand total** | **1,675** | |

Net reduction: ~1,192 → 487 lines of script code (59% reduction).
Math is now in one place, tested by 40 tests.

## Functions Added to Package

Four functions were in the scripts but not in the package. Added during
decomplection:

| Function | Purpose |
|----------|---------|
| `metropolis_sweep` | Full MC lattice sweep (uses `ising_hamiltonian` + `metropolis_accept`) |
| `solve_cubic_one_root` | Cardano formula for single real root (Δ < 0) |
| `solve_cubic_three_roots` | Trigonometric method for three real roots (Δ > 0) |
| `fit_accumulation_models` | Growth-model AIC comparison (counterpart to `fit_models` for decay) |

## What Stays in Scripts

- Parameter setup and constants (SEED, lattice size, time spans)
- Simulation loop orchestration (calling package functions)
- JSON serialization and file output
- Console summaries
- Domain-specific classification (`classify_financing_posture` in upcycle — not pure math)

## Phosphene Compliance

| Axiom | Status |
|-------|--------|
| PY-ARCH-001 | ✅ Functional core / imperative shell — `formulas.py` has no I/O imports |
| PY-ARCH-002 | ✅ DFT — pure functions, zero mocking in tests |
| PY-ARCH-004 | ✅ Immutability — `GoodwinMinskyParams` is frozen dataclass |
| PY-ARCH-005 | ✅ Types — all functions have return type annotations |
| PY-ARCH-008 | ✅ Verification pyramid — 40 unit tests at the base |
| PY-MOD-003 | ✅ Pure logic module pattern — `formulas.py` is a pure logic module |

## Verification

- 40/40 package tests pass (0.78s)
- All 6 scripts execute successfully
- Ising: 30 temperatures, magnetization curve generated
- Landau: equilibrium found, critical point at a=0
- Cusp: bifurcation set + cubic roots computed
- Drift-Selection: falsified status preserved (T2)
- Upcycle: Goodwin-Minsky ODE integrated, P7 test run
- Relaxation: ΔAIC = −89.99 (bi-exp strongly preferred over mono-exp)

## Falsifiability Check

The decomplection is falsifiable: if any script produces different output
after the rewrite, the extraction was incomplete. All six scripts produce
the same results as before — the math was extracted verbatim, not
reimplemented.
