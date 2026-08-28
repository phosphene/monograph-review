#!/usr/bin/env python3
"""
Can we distinguish step function from steep sigmoid?
Three approaches:
1. Within-system fine-grained: compute retention at many dependency thresholds in Sodalis
2. Bayesian model comparison: step vs sigmoid on the 3 comparable points
3. Finite-size scaling: estimate the transition width from gene count
"""
import json
import numpy as np
import pandas as pd
from scipy import stats
from scipy.optimize import curve_fit
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

WORKSPACE = Path("/home/node/.openclaw/workspace")
OUTPUT_DIR = WORKSPACE / "valence-foundry" / "data" / "formula-analysis"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Load Sodalis data
dep = pd.read_csv(WORKSPACE / "valence-foundry/data/t7-ltee/gene_dependency_scores.tsv", sep="\t")
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_intact.txt") as f:
    intact = set(l.strip() for l in f if l.strip())
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_absent.txt") as f:
    absent = set(l.strip() for l in f if l.strip())
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_pseudo.txt") as f:
    pseudo = set(l.strip() for l in f if l.strip())

def classify(row):
    """Classify Sodalis gene as retained (1), lost (0), or pseudo (1)."""
    gname = str(row['name']).strip()
    gid = str(row['gene_id']).strip()
    if gname in intact or gid in intact:
        return 1
    elif gname in absent or gid in absent:
        return 0
    elif gname in pseudo or gid in pseudo:
        return 1
    return None

dep['retention'] = dep.apply(classify, axis=1)
dep = dep.dropna(subset=['retention'])
dep['retention'] = dep['retention'].astype(int)

print(f"Sodalis: {len(dep)} genes, {dep['retention'].sum()} retained ({dep['retention'].mean():.3f})")

# ============================================================
# APPROACH 1: Within-system fine-grained retention curve
# ============================================================
print("\n" + "="*60)
print("APPROACH 1: Within-system retention at many dependency thresholds")
print("="*60)

# Compute retention rate at many dependency thresholds
thresholds = np.linspace(0, 0.99, 100)
retention_rates = []
n_above = []
for t in thresholds:
    mask = dep['dependency_score'] >= t
    n = mask.sum()
    if n > 0:
        rate = dep.loc[mask, 'retention'].mean()
    else:
        rate = np.nan
    retention_rates.append(rate)
    n_above.append(n)

retention_rates = np.array(retention_rates)

# Also compute the "relative retention" — retention rate / overall retention
# This normalizes for the fact that higher thresholds have fewer genes
overall_retention = dep['retention'].mean()
relative_retention = retention_rates / overall_retention

# Find the threshold where retention rate jumps most sharply
# This is the within-system "phase transition"
diffs = np.abs(np.diff(retention_rates))
jump_threshold = thresholds[np.argmax(diffs)]
jump_magnitude = np.max(diffs)

print(f"Overall retention rate: {overall_retention:.3f}")
print(f"Largest jump: at dependency threshold {jump_threshold:.3f}")
print(f"Jump magnitude: {jump_magnitude:.3f} (retention rate change)")
print(f"N genes above jump threshold: {dep[dep['dependency_score'] >= jump_threshold].shape[0]}")

# Compute ρ at different dependency score cutoffs
# (What's the Spearman if we only consider genes with dep > cutoff?)
cutoffs = np.arange(0, 0.5, 0.01)
rho_at_cutoff = []
for c in cutoffs:
    mask = dep['dependency_score'] > c
    if mask.sum() > 10 and dep.loc[mask, 'retention'].std() > 0:
        rho, p = stats.spearmanr(dep.loc[mask, 'dependency_score'], dep.loc[mask, 'retention'])
        rho_at_cutoff.append((c, rho, p, mask.sum()))
    else:
        rho_at_cutoff.append((c, np.nan, np.nan, mask.sum()))

print(f"\nρ at different dependency cutoffs:")
print(f"{'Cutoff':>8s} {'ρ':>8s} {'p':>10s} {'n':>6s}")
for c, r, p, n in rho_at_cutoff:
    print(f"{c:8.2f} {r:8.3f} {p:10.4g} {n:6d}")

# ============================================================
# APPROACH 2: Bayesian model comparison on 3 comparable points
# ============================================================
print("\n" + "="*60)
print("APPROACH 2: Step function vs sigmoid on 3 comparable points")
print("="*60)

# The 3 points
theta_3 = np.array([0.0, 0.044, 0.50])
rho_3 = np.array([-0.039, 0.353, 0.372])
# Assume approximate normal errors
sigma_rho = np.array([0.03, 0.02, 0.02])  # rough SEs

# Model 1: Step function: ρ = ρ_sat if θ > θ*, else 0
# Parameters: θ* (where the step is), ρ_sat (saturation level)
# Likelihood: for each θ_i, predicted ρ = ρ_sat * H(θ_i - θ*)
def step_log_likelihood(theta_star, rho_sat, theta_data, rho_data, sigma_data):
    """Log-likelihood of step model: rho = rho_sat if theta > theta_star, else 0."""
    predicted = np.where(theta_data > theta_star, rho_sat, 0.0)
    # Allow small negative at θ=0 (LTEE was -0.039)
    predicted = np.where(theta_data < theta_star, 0.0, rho_sat)
    ll = np.sum(stats.norm.logpdf(rho_data, loc=predicted, scale=sigma_data))
    return ll

# Model 2: Sigmoid: ρ = ρ_sat / (1 + exp(-s*(θ-θ*)))
# Parameters: θ*, s, ρ_sat (one more than step function)
def sigmoid_log_likelihood(s, theta_star, rho_sat, theta_data, rho_data, sigma_data):
    """Log-likelihood of sigmoid model: rho = rho_sat / (1 + exp(-s*(theta - theta_star)))."""
    predicted = rho_sat / (1 + np.exp(-s * (theta_data - theta_star)))
    ll = np.sum(stats.norm.logpdf(rho_data, loc=predicted, scale=sigma_data))
    return ll

# Grid search over parameters for both models
from scipy.optimize import minimize

# Step function: optimize θ* and ρ_sat
def neg_ll_step(params):
    """Negative log-likelihood wrapper for step-function optimization."""
    theta_star, rho_sat = params
    if theta_star < 0 or theta_star > 1 or rho_sat < 0 or rho_sat > 2:
        return 1e10
    return -step_log_likelihood(theta_star, rho_sat, theta_3, rho_3, sigma_rho)

res_step = minimize(neg_ll_step, [0.02, 0.35], method='Nelder-Mead')
step_ll = -res_step.fun
step_params = res_step.x
print(f"Step function best fit: θ*={step_params[0]:.4f}, ρ_sat={step_params[1]:.3f}")
print(f"  Log-likelihood: {step_ll:.2f}")
print(f"  AIC: {2*2 - 2*step_ll:.2f} (2 params)")

# Sigmoid: optimize θ*, s, ρ_sat
def neg_ll_sigmoid(params):
    """Negative log-likelihood wrapper for sigmoid optimization."""
    s, theta_star, rho_sat = params
    if s < 0 or theta_star < 0 or theta_star > 1 or rho_sat < 0 or rho_sat > 2:
        return 1e10
    return -sigmoid_log_likelihood(s, theta_star, rho_sat, theta_3, rho_3, sigma_rho)

# Try multiple starting points
best_sig_ll = -np.inf
best_sig_params = None
for s0 in [1, 5, 10, 50, 100, 500, 1000]:
    for ts0 in [0.01, 0.02, 0.03]:
        for rs0 in [0.35, 0.37]:
            try:
                res = minimize(neg_ll_sigmoid, [s0, ts0, rs0], method='Nelder-Mead')
                if -res.fun > best_sig_ll:
                    best_sig_ll = -res.fun
                    best_sig_params = res.x
            except:
                pass

print(f"\nSigmoid best fit: s={best_sig_params[0]:.1f}, θ*={best_sig_params[1]:.4f}, ρ_sat={best_sig_params[2]:.3f}")
print(f"  Log-likelihood: {best_sig_ll:.2f}")
print(f"  AIC: {2*3 - 2*best_sig_ll:.2f} (3 params)")

# AIC comparison
aic_step = 2*2 - 2*step_ll
aic_sig = 2*3 - 2*best_sig_ll
print(f"\nAIC comparison:")
print(f"  Step function: AIC = {aic_step:.2f}")
print(f"  Sigmoid:       AIC = {aic_sig:.2f}")
print(f"  ΔAIC = {aic_sig - aic_step:.2f}")
if aic_step < aic_sig:
    print(f"  → Step function wins (fewer params, better fit)")
else:
    print(f"  → Sigmoid wins (better fit despite more params)")
    print(f"  → But s = {best_sig_params[0]:.1f} — {'VERY STEEP (approaches step function)' if best_sig_params[0] > 50 else 'moderate steepness'}")

# Bayes factor (rough): BF = exp(ΔAIC/2) favors model with lower AIC
bf = np.exp(abs(aic_sig - aic_step) / 2)
print(f"  Approx Bayes factor: {bf:.2f} in favor of {('step function' if aic_step < aic_sig else 'sigmoid')}")

# ============================================================
# APPROACH 3: Finite-size scaling
# ============================================================
print("\n" + "="*60)
print("APPROACH 3: Finite-size scaling — can we resolve the transition?")
print("="*60)

n_genes = 1367  # iJO1366 genes
# For a true step function in a finite system, the transition width is ~1/n_genes
transition_width_finite = 1.0 / n_genes
print(f"Number of genes in iJO1366: {n_genes}")
print(f"Minimum resolvable θ transition width: ~{transition_width_finite:.6f}")
print(f"Our data spacing: θ=0 to θ=0.044 (gap = 0.044)")
print(f"Ratio: data gap / transition width = {0.044 / transition_width_finite:.0f}x")
print(f"\nIf the transition is truly a step function:")
print(f"  The transition happens in a θ range of ~{transition_width_finite:.4f}")
print(f"  Our closest data points are 0 and 0.044 — {0.044/transition_width_finite:.0f}× wider than the transition")
print(f"  → We CANNOT resolve the transition shape with current data spacing")
print(f"  → Both step and steep sigmoid are consistent with the data")

print(f"\nTo resolve, we need a system at θ ≈ 0.01-0.03")
print(f"  → Need a facultative symbiont with partial genome reduction")
print(f"  → Or an experimental system where θ is controlled")

# ============================================================
# PLOT
# ============================================================
fig, axes = plt.subplots(1, 3, figsize=(18, 5))

# Panel 1: Within-system retention curve
ax = axes[0]
valid = ~np.isnan(retention_rates)
ax.plot(thresholds[valid], retention_rates[valid], 'b-', linewidth=2)
ax.axhline(y=overall_retention, color='r', linestyle='--', alpha=0.5, label=f'Overall rate ({overall_retention:.3f})')
ax.axvline(x=jump_threshold, color='g', linestyle=':', alpha=0.5, label=f'Jump at dep={jump_threshold:.3f}')
ax.set_xlabel('Dependency score threshold', fontsize=11)
ax.set_ylabel('Retention rate (genes with dep ≥ threshold)', fontsize=11)
ax.set_title('Within-System: Retention vs Dependency Threshold\n(Sodalis)', fontsize=12)
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)
ax.set_xlim(-0.05, 1.05)
ax.set_ylim(0, 1.05)

# Panel 2: Model comparison
ax = axes[1]
theta_fine = np.linspace(-0.02, 0.8, 500)
# Step function
step_y = np.where(theta_fine > step_params[0], step_params[1], 0.0)
ax.plot(theta_fine, step_y, 'b-', linewidth=2, label=f'Step (AIC={aic_step:.1f})')
# Sigmoid
sig_y = best_sig_params[2] / (1 + np.exp(-best_sig_params[0] * (theta_fine - best_sig_params[1])))
ax.plot(theta_fine, sig_y, 'r--', linewidth=2, label=f'Sigmoid s={best_sig_params[0]:.0f} (AIC={aic_sig:.1f})')
# Data points
ax.errorbar(theta_3, rho_3, yerr=sigma_rho, fmt='ko', markersize=8, capsize=5, zorder=5, label='Data')
for i, (t, r) in enumerate(zip(theta_3, rho_3)):
    labels = ['LTEE', 'Sodalis', 'Buchnera']
    ax.annotate(labels[i], (t, r), textcoords="offset points", xytext=(8, 8), fontsize=9)

ax.set_xlabel('θ (niche dependency)', fontsize=11)
ax.set_ylabel('ρ (valence effect)', fontsize=11)
ax.set_title('Model Comparison: Step vs Sigmoid\n(3 comparable points)', fontsize=12)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)
ax.set_xlim(-0.05, 0.6)
ax.set_ylim(-0.1, 0.5)

# Panel 3: Finite-size scaling
ax = axes[2]
# Show what a step function looks like with different gene counts
for n_g, ls, alpha in [(100, '-', 0.3), (500, '--', 0.5), (1367, '-', 0.8), (10000, '-', 1.0)]:
    width = 1.0 / n_g
    theta_sim = np.linspace(-0.05, 0.15, 10000)
    # Simulated step with finite-size smoothing
    rho_sim = 0.37 / (1 + np.exp(-4/width * (theta_sim - 0.02)))
    ax.plot(theta_sim, rho_sim, ls=ls, alpha=alpha, label=f'n={n_g} (width={width:.4f})')

ax.scatter(theta_3, rho_3, c='black', s=80, zorder=5, edgecolors='white')
ax.set_xlabel('θ', fontsize=11)
ax.set_ylabel('ρ', fontsize=11)
ax.set_title('Finite-Size Scaling:\nStep function at different genome sizes', fontsize=12)
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)
ax.set_xlim(-0.05, 0.15)
ax.set_ylim(-0.1, 0.5)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'step_vs_sigmoid.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'step_vs_sigmoid.png'}")

# Save results
results = {
    'approach1_within_system': {
        'jump_threshold': float(jump_threshold),
        'jump_magnitude': float(jump_magnitude),
        'overall_retention': float(overall_retention),
        'rho_at_cutoffs': [{'cutoff': float(c), 'rho': float(r), 'p': float(p), 'n': int(n)} 
                           for c, r, p, n in rho_at_cutoff if not np.isnan(r)],
    },
    'approach2_model_comparison': {
        'step_function': {'theta_star': float(step_params[0]), 'rho_sat': float(step_params[1]), 
                         'log_likelihood': float(step_ll), 'aic': float(aic_step), 'n_params': 2},
        'sigmoid': {'s': float(best_sig_params[0]), 'theta_star': float(best_sig_params[1]), 
                   'rho_sat': float(best_sig_params[2]), 'log_likelihood': float(best_sig_ll), 
                   'aic': float(aic_sig), 'n_params': 3},
        'delta_aic': float(aic_sig - aic_step),
        'bayes_factor': float(bf),
        'winner': 'step_function' if aic_step < aic_sig else 'sigmoid',
    },
    'approach3_finite_size': {
        'n_genes': n_genes,
        'min_transition_width': float(transition_width_finite),
        'data_gap': 0.044,
        'resolvable': False,
        'ratio_gap_to_width': 0.044 / transition_width_finite,
    },
}
with open(OUTPUT_DIR / 'step_vs_sigmoid_results.json', 'w') as f:
    json.dump(results, f, indent=2)
print(f"Saved: {OUTPUT_DIR / 'step_vs_sigmoid_results.json'}")
