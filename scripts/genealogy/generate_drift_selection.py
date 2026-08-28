#!/usr/bin/env python3
"""Stage (falsified): Wright-Fisher drift vs selection — ρ_sat test.

Falsified (T2): the ρ_sat ≈ 0.35 claim was not derivable from
Wright-Fisher dynamics alone. Preserved for reproducibility.

Thin runner: imports all math from phosphene.genealogy.formulas.
"""
import json
import os

import numpy as np
from phosphene.genealogy.formulas import wright_fisher_fixation

SEED = 42
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "genealogy")


def run_drift_selection_simulation(N=100, n_reps=1000, n_delta=20,
                                   delta_range=(-0.01, 0.1)):
    rng = np.random.default_rng(SEED)
    deltas = np.linspace(delta_range[0], delta_range[1], n_delta)
    retention_probs = np.zeros(n_delta)

    for d_idx, delta in enumerate(deltas):
        fixes = sum(
            wright_fisher_fixation(N, delta, rng, p_init=0.5, n_generations=5000)
            for _ in range(n_reps)
        )
        retention_probs[d_idx] = fixes / n_reps

    return {
        "stage": "drift_selection",
        "status": "falsified",
        "falsification": "T2: ρ_sat ≈ 0.35 not derivable from WF dynamics alone",
        "parameters": {"N": N, "n_reps": n_reps, "n_delta": n_delta},
        "data": {
            "deltas": deltas.tolist(),
            "retention_probs": retention_probs.tolist(),
        },
        "metadata": {
            "seed": SEED,
            "code": "phosphene.genealogy.formulas.wright_fisher_fixation",
        },
    }


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    result = run_drift_selection_simulation()
    out_path = os.path.join(OUTPUT_DIR, "drift_selection_simulation.json")
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Drift-selection simulation complete → {out_path}")
    print(f"  STATUS: FALSIFIED (T2)")
    print(f"  N={result['parameters']['N']}, n_reps={result['parameters']['n_reps']}")
    print(f"  Seed: {SEED}")


if __name__ == "__main__":
    main()
