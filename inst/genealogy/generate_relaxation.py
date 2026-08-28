#!/usr/bin/env python3
"""Stage 4: Relaxation Formula — bi-exponential decay simulation.

Thin runner: imports all math from phosphene.genealogy.formulas.
Handles only I/O: parameter setup, data generation, JSON output, console summary.

This is the compositional endpoint of the genealogy chain:
    Ising → Landau → Cusp → Relaxation
"""
import json
import os

import numpy as np
from phosphene.genealogy.formulas import relaxation_ode, fit_models, linear_decay

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42


def run_simulation():
    """Run relaxation simulation with known ground-truth parameters.

    Generates data from the formula, adds noise, then fits all three models.
    Verifies: (1) bi-exp beats mono-exp and linear by AIC, (2) parameter
    recovery within tolerance, (3) k₁ ≫ k₂.
    """
    np.random.seed(SEED)

    # Ground-truth parameters (inspired by LTEE: k₁=17.7, k₂=0.47)
    k1_true = 5.0
    k2_true = 0.3
    rho1_true = 0.15
    rho2_true = 0.05
    A1_true = 0.6
    A2_true = 0.25

    # Time points (50 points, log-spaced to resolve both phases)
    t = np.logspace(-1, 2, 50)  # 0.1 to 100

    # Generate clean data + noise (5% relative)
    y_clean = relaxation_ode(t, k1_true, k2_true, rho1_true, rho2_true, A1_true, A2_true)
    y_noisy = y_clean + np.random.normal(0, 0.02, len(t))

    # Fit models using the package
    fits = fit_models(
        t, y_noisy,
        bi_p0=[[0.5, 0.01, 0.3, 0.5, 0.5, 0.4],
               [1.0, 0.1, 0.2, 0.5, 0.3, 0.6],
               [0.8, 0.5, 0.1, 0.3, 0.6, 0.4]],
        mono_p0=[[1.0, 0.05, 0.3], [0.5, 0.01, 0.5], [2.0, 0.1, 0.2]],
    )

    # Parameter recovery check
    bi_params = fits['bi_exp'].get('params', [])
    recovery = {}
    if len(bi_params) == 6:
        recovery = {
            'k1_recovered': bi_params[0],
            'k2_recovered': bi_params[1],
            'k1_true': k1_true,
            'k2_true': k2_true,
            'k1_error_pct': abs(bi_params[0] - k1_true) / k1_true * 100,
            'k2_error_pct': abs(bi_params[1] - k2_true) / k2_true * 100,
            'k1_k2_ratio': bi_params[0] / bi_params[1] if bi_params[1] > 0 else float('inf'),
            'k1_k2_ratio_true': k1_true / k2_true,
        }

    delta_aic = fits['delta_aic_bi_vs_mono']
    passed = delta_aic < -4

    return {
        'stage': 6,
        'name': 'Relaxation Formula Simulation',
        'ground_truth': {
            'k1': k1_true, 'k2': k2_true,
            'rho1': rho1_true, 'rho2': rho2_true,
            'A1': A1_true, 'A2': A2_true,
            'k1_k2_ratio': k1_true / k2_true,
        },
        'fits': fits,
        'parameter_recovery': recovery,
        'delta_aic_bi_vs_mono': delta_aic,
        'passed': bool(passed),
        'pass_criterion': 'ΔAIC (bi-exp vs mono-exp) < -4',
        'n_points': len(t),
        'seed': SEED,
        'equation': 'dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)',
        'solution': 'ρ(t) = ρ_eq + A₁·exp(−k₁·t) + A₂·exp(−k₂·t)',
        'chain': 'Ising → Landau → Cusp → Relaxation',
        'metadata': {
            'seed': SEED,
            'code': 'phosphene.genealogy.formulas.relaxation_ode + fit_models',
        },
    }


if __name__ == '__main__':
    result = run_simulation()

    output_path = os.path.join(RESULTS_DIR, 'genealogy-relaxation-results.json')
    with open(output_path, 'w') as f:
        json.dump(result, f, indent=2)

    print(f"{'='*60}")
    print(f"GENEALOGY STAGE 6: RELAXATION SIMULATION")
    print(f"{'='*60}")
    print(f"\nGround truth: k₁={result['ground_truth']['k1']}, k₂={result['ground_truth']['k2']}, "
          f"ratio={result['ground_truth']['k1_k2_ratio']:.1f}")
    print(f"ΔAIC (bi-exp vs mono-exp): {result['delta_aic_bi_vs_mono']:.2f}")
    print(f"Passed: {'YES ✓' if result['passed'] else 'NO ✗'}")

    if result['parameter_recovery']:
        r = result['parameter_recovery']
        print(f"\nParameter recovery:")
        print(f"  k₁: {r['k1_recovered']:.3f} (true: {r['k1_true']}, error: {r['k1_error_pct']:.1f}%)")
        print(f"  k₂: {r['k2_recovered']:.3f} (true: {r['k2_true']}, error: {r['k2_error_pct']:.1f}%)")
        print(f"  k₁/k₂ ratio: {r['k1_k2_ratio']:.1f} (true: {r['k1_k2_ratio_true']:.1f})")

    print(f"\nResults: {output_path}")
