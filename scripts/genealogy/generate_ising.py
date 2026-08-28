#!/usr/bin/env python3
"""Stage 1: Ising Model — cooperative dynamics simulation.

Thin runner: imports all math from phosphene.genealogy.formulas.
Handles only I/O: parameter setup, simulation loop, JSON output, console summary.
"""
import json
import os
import sys

import numpy as np
from phosphene.genealogy.formulas import ising_hamiltonian, metropolis_sweep

SEED = 42
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "genealogy")


def run_ising_simulation(L=16, J=1.0, h=0.0, n_sweeps=1000,
                         T_range=(1.5, 3.5), n_temps=30):
    rng = np.random.default_rng(SEED)
    temps = np.linspace(T_range[0], T_range[1], n_temps)
    mags = np.zeros(n_temps)

    for t_idx, T in enumerate(temps):
        beta = 1.0 / T
        spins = rng.choice([-1, 1], size=(L, L))
        for _ in range(n_sweeps):
            spins = metropolis_sweep(spins, L, beta, J, h, rng)
        mags[t_idx] = np.abs(np.mean(spins))

    return {
        "stage": "ising",
        "formula": "H = -J·Σσᵢσⱼ - h·Σσᵢ",
        "parameters": {"L": L, "J": J, "h": h, "n_sweeps": n_sweeps},
        "data": {"temperatures": temps.tolist(), "magnetization": mags.tolist()},
        "metadata": {
            "seed": SEED,
            "code": "phosphene.genealogy.formulas.ising_hamiltonian + metropolis_sweep",
        },
    }


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    result = run_ising_simulation()
    out_path = os.path.join(OUTPUT_DIR, "ising_simulation.json")
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Ising simulation complete → {out_path}")
    print(f"  L={result['parameters']['L']}, J={result['parameters']['J']}")
    print(f"  Critical region (Tc ≈ 2.27 for J=1, h=0): "
          f"|M| at T=2.27: {result['data']['magnetization'][14]:.3f}")
    print(f"  Seed: {SEED}")


if __name__ == "__main__":
    main()
