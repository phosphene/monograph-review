#!/usr/bin/env python3
"""Stage 3: Cusp Catastrophe — bifurcation geometry.

Thin runner: imports all math from phosphene.genealogy.formulas.
"""
import json
import os

import numpy as np
from phosphene.genealogy.formulas import (
    cusp_potential,
    cubic_discriminant,
    solve_cubic_one_root,
    solve_cubic_three_roots,
    cusp_bifurcation_set,
)

SEED = 42
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "genealogy")


def run_cusp_simulation(n_a=50, n_b=50, a_range=(-2.0, 2.0), b_range=(-2.0, 2.0)):
    np.random.seed(SEED)
    a_vals = np.linspace(a_range[0], a_range[1], n_a)
    b_vals = np.linspace(b_range[0], b_range[1], n_b)

    # Build the bifurcation set grid
    bif_grid = cusp_bifurcation_set(a_vals, b_vals)

    # Sample some cusp potentials
    examples = []
    for a, b in [(-1.0, 0.0), (-1.0, 0.5), (1.0, 0.5)]:
        x = np.linspace(-2, 2, 200)
        V = cusp_potential(x, a, b)
        delta = cubic_discriminant(a, b)
        if delta > 0 and a < 0:
            roots = solve_cubic_three_roots(a, b)
        else:
            roots = [solve_cubic_one_root(a, b)]
        examples.append({
            "a": a, "b": b, "delta": delta,
            "roots": roots,
            "V": V.tolist(), "x": x.tolist(),
        })

    return {
        "stage": "cusp",
        "formula": "V(x) = x⁴/4 + a·x²/2 + b·x; Δ = -(4a³ + 27b²)",
        "parameters": {"n_a": n_a, "n_b": n_b},
        "data": {
            "a_vals": a_vals.tolist(),
            "b_vals": b_vals.tolist(),
            "bifurcation_set": bif_grid.tolist(),
            "examples": examples,
        },
        "metadata": {
            "seed": SEED,
            "code": "phosphene.genealogy.formulas.cusp_potential + cubic_discriminant + solve_cubic_*",
        },
    }


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    result = run_cusp_simulation()
    out_path = os.path.join(OUTPUT_DIR, "cusp_simulation.json")
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Cusp simulation complete → {out_path}")
    print(f"  Bifurcation set: {result['parameters']['n_a']}×{result['parameters']['n_b']} grid")
    print(f"  Example (a=-1, b=0): Δ = {result['data']['examples'][0]['delta']:.1f}, "
          f"roots = {result['data']['examples'][0]['roots']}")
    print(f"  Seed: {SEED}")


if __name__ == "__main__":
    main()
