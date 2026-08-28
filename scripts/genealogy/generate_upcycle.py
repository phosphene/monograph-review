#!/usr/bin/env python3
"""Stage 5/T8: Banking Upcycle — Goodwin-Minsky with cultural accumulation.

Thin runner: imports all math from phosphene.genealogy.formulas.
Handles only I/O and the financing-posture classification (domain-specific,
not pure math).
"""
import json
import os
import sys

import numpy as np
from scipy.integrate import solve_ivp
from phosphene.genealogy.formulas import (
    GoodwinMinskyParams,
    upcycle_ode,
    sigmoid,
    bi_exp_growth,
    mono_exp_growth,
    linear_growth,
    fit_accumulation_models,
    analyze_positive_dd,
)

SEED = 42
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "genealogy")


# --- Domain-specific classification (stays here — not pure math) ---

def classify_financing_posture(omega: float, D: float, params: GoodwinMinskyParams) -> str:
    if omega < 0.70 and D < params.D_max:
        return "hedge"
    elif omega < 0.85 and D < params.D_max * 1.2:
        return "speculative"
    else:
        return "ponzi"


def classify_all_postures(omega_vals, D_vals, params: GoodwinMinskyParams):
    return [classify_financing_posture(w, d, params) for w, d in zip(omega_vals, D_vals)]


# --- Runner ---

def run_upcycle_simulation(params: GoodwinMinskyParams | None = None,
                           t_span=(0, 200), n_points=1000):
    if params is None:
        params = GoodwinMinskyParams()

    y0 = [0.65, 0.65, 0.15, 0.95, 5.0]
    t_eval = np.linspace(t_span[0], t_span[1], n_points)

    sol = solve_ivp(
        upcycle_ode, t_span, y0, args=(params,),
        t_eval=t_eval, method="RK45", rtol=1e-8, atol=1e-10
    )

    omega, lam, D, r, N_inst = sol.y

    # Model fitting for instrument diversification (P7 test)
    t = sol.t
    fit_results = fit_accumulation_models(t, N_inst)

    # P7 diversity-dependent growth test
    dd_test = analyze_positive_dd(t, N_inst)

    # Posture classifications
    postures = classify_all_postures(omega, D, params)

    # Minsky moment detection
    profit_rate = (1.0 - omega) * params.nu - params.delta
    minsky_moments = np.where(
        (D > params.D_max) & (profit_rate < 0)
    )[0].tolist()

    return {
        "stage": "banking_upcycle",
        "formula": "Goodwin-Minsky ODE + cultural accumulation (P7 sign reversal)",
        "parameters": params.__dict__,
        "data": {
            "t": t.tolist(),
            "omega": omega.tolist(),
            "lambda": lam.tolist(),
            "D": D.tolist(),
            "r": r.tolist(),
            "N_inst": N_inst.tolist(),
            "postures": postures,
            "minsky_moments": minsky_moments,
        },
        "model_comparison": fit_results,
        "p7_test": dd_test,
        "metadata": {
            "seed": SEED,
            "code": "phosphene.genealogy.formulas.upcycle_ode + fit_accumulation_models + analyze_positive_dd",
        },
    }


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    result = run_upcycle_simulation()
    out_path = os.path.join(OUTPUT_DIR, "upcycle_simulation.json")
    with open(out_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Banking upcycle simulation complete → {out_path}")
    p7 = result.get("p7_test", {})
    print(f"  P7 verdict: {p7.get('verdict', 'N/A')} (α={p7.get('alpha', 'N/A')})")
    mc = result.get("model_comparison", {})
    print(f"  Bi-exp preferred: {mc.get('bi_exp_preferred', 'N/A')}")
    print(f"  Seed: {SEED}")


if __name__ == "__main__":
    main()
