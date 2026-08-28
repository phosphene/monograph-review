#!/usr/bin/env python3
"""Stage 2: Landau Mean-Field Free Energy — equilibrium landscape.

Thin runner: imports all math from phosphene.genealogy.formulas.
"""
import json
import os

import numpy as np
from phosphene.genealogy.formulas import landau_free_energy, landau_equilibrium

SEED = 42
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "genealogy")


def run_landau_simulation(n_points=100, a_range=(-1.0, 1.0), b=1.0, h=0.0):
    np.random.seed(SEED)
    a_vals = np.linspace(a_range[0], a_range[1], n_points)
    M_grid = np.linspace(-1.5, 1.5, 200)
    M_eq = np.zeros(n_points)
    F_min = np.zeros(n_points)

    for i, a in enumerate(a_vals):
        M_eq[i], F_min[i] = landau_equilibrium(M_grid, a, b, h)

    return {
        "stage": "landau",
        "formula": "F(M) = a·M² + b·M⁴ + h·M",
        "parameters": {"a_range": list(a_range), "b": b, "h": h},
        "data": {
            "a_values": a_vals.tolist(),
            "M_equilibrium": M_eq.tolist(),
            "F_min": F_min.tolist(),
        },
        "metadata": {
            "seed": SEED,
            "code": "phosphene.genealogy.formulas.landau_free_energy + landau_equilibrium",
        },
    }


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    result = run_landau_simulation()
    out_path = os.path.join(OUTPUT_DIR, "landau_simulation.json")
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Landau simulation complete → {out_path}")
    print(f"  Critical point (a=0): M_eq = {result['data']['M_equilibrium'][50]:.3f}")
    print(f"  Below Tc (a=-0.5): M_eq = {result['data']['M_equilibrium'][25]:.3f}")
    print(f"  Seed: {SEED}")


if __name__ == "__main__":
    main()
