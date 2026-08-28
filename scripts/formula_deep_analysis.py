#!/usr/bin/env python3
"""
Deep formula analysis: combine all available data, try to get more ρ-θ points,
fit candidate formulas, compare to physics attractor theory.
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

# ============================================================
# 1. COMBINE ALL ρ-θ DATA POINTS
# ============================================================

print("=" * 60)
print("COMPREHENSIVE ρ-θ ANALYSIS")
print("=" * 60)

all_points = []

# --- LTEE (θ=0, ρ≈0) ---
all_points.append({
    'system': 'LTEE',
    'domain': 'bacteria_free_living',
    'theta': 0.0,
    'theta_metric': 'free_living (no host)',
    'rho': -0.039,
    'rho_metric': 'Spearman(dep_score, LoF_timing)',
    'n_genes': 754,
    'rho_p': 0.137,
    'source': 'T7 redesigned'
})

# --- Sodalis (θ based on genome ratio, ρ=0.353) ---
all_points.append({
    'system': 'Sodalis (FBA full)',
    'domain': 'bacteria_endosymbiont',
    'theta': 1 - (4_300_000 / 4_500_000),  # 0.044
    'theta_alt': 1183 / (4979 + 1183),  # pseudogene fraction = 0.192
    'theta_metric': 'genome_ratio + pseudogene_fraction',
    'rho': 0.353,
    'rho_metric': 'Spearman(dep_score, retention_binary)',
    'n_genes': 1366,
    'rho_p': 0.0001,
    'source': 'T7 Sodalis'
})

all_points.append({
    'system': 'Sodalis (composite)',
    'domain': 'bacteria_endosymbiont',
    'theta': 1 - (4_300_000 / 4_500_000),
    'theta_alt': 1183 / (4979 + 1183),
    'theta_metric': 'genome_ratio + pseudogene_fraction',
    'rho': 0.248,
    'rho_metric': 'Spearman(composite_integration, retention_binary)',
    'n_genes': 1366,
    'rho_p': 0.0001,
    'source': 'T7 Sodalis'
})

# --- Orobanchaceae: per-species ρ values (NEW POINTS!) ---
orobanch = pd.read_csv(WORKSPACE / "valence-foundry/data/orobanchaceae_retention_matrix.tsv", sep="\t")
for sp in orobanch['species'].unique():
    sp_data = orobanch[orobanch['species'] == sp]
    if sp_data['retention'].std() == 0:
        continue  # constant — can't compute ρ
    rho, p = stats.spearmanr(sp_data['dependency_score'], sp_data['retention'])
    ps = sp_data['parasitism_score'].iloc[0]
    all_points.append({
        'system': f'Orobanchaceae: {sp}',
        'domain': 'plant_parasite',
        'theta': ps / 4.0,  # normalized 0-1
        'theta_metric': 'parasitism_score/4',
        'rho': rho,
        'rho_metric': 'Spearman(dep_score, retention)',
        'n_genes': len(sp_data),
        'rho_p': p,
        'source': 'T6 retention_matrix'
    })

# Orobanchaceae pooled (PGLS-corrected)
all_points.append({
    'system': 'Orobanchaceae (PGLS)',
    'domain': 'plant_parasite',
    'theta': orobanch['parasitism_score'].mean() / 4.0,
    'theta_metric': 'parasitism_score/4 (mean)',
    'rho': 0.955,
    'rho_metric': 'Spearman PGLS-corrected',
    'n_genes': 48,
    'rho_p': 0.001,
    'source': 'T6 PGLS'
})

# --- Endosymbiont genus-level: use symbiosis age as θ ---
# Published logistic β values from the monograph
endo_published = [
    {'genus': 'Buchnera', 'beta': 0.0017, 'p': 0.001, 'aa_pathways': 10, 
     'symbiosis_age': 200, 'genome_bp': 568614, 'n_species': 38},
    {'genus': 'Carsonella', 'beta': 0.0036, 'p': 7e-6, 'aa_pathways': 2,
     'symbiosis_age': 150, 'genome_bp': 171553, 'n_species': 73},
    {'genus': 'Brugia (Wolbachia)', 'beta': 0.0160, 'p': 0.0001, 'aa_pathways': None,
     'symbiosis_age': 100, 'genome_bp': None, 'n_species': 1},
]

# For endosymbiont genera with published β, note: β is NOT comparable to ρ
# Cannot convert logistic β to Spearman ρ — different metrics
# Skip these and note as limitation
print("\nNOTE: Published logistic β values (Buchnera, Carsonella, Brugia)")
print("cannot be converted to Spearman ρ — different effect size metrics.")
print("Need raw gene-level data to compute comparable ρ.")
print("Skipping these for now. To get more points, need to download")
print("endosymbiont genomes and compute ρ directly.")

# Print all points
print(f"\n{'System':35s} {'Domain':25s} {'θ':>8s} {'ρ':>8s} {'p':>10s} {'Source':20s}")
print("-" * 120)
for pt in all_points:
    theta_str = f"{pt['theta']:8.3f}" if pt['theta'] is not None else "     N/A"
    print(f"{pt['system']:35s} {pt['domain']:25s} {theta_str} {pt['rho']:8.3f} {pt['rho_p']:10.4g} {pt['source']:20s}")

# ============================================================
# 2. FIT CANDIDATE FORMULAS
# ============================================================

print("\n\n" + "=" * 60)
print("FORMULA FITTING")
print("=" * 60)

# Use all points with numeric θ and ρ
theta_arr = np.array([pt['theta'] for pt in all_points if pt['theta'] is not None and not np.isnan(pt['rho'])])
rho_arr = np.array([pt['rho'] for pt in all_points if pt['theta'] is not None and not np.isnan(pt['rho'])])
labels = [pt['system'] for pt in all_points if pt['theta'] is not None and not np.isnan(pt['rho'])]

print(f"\nFitting to {len(theta_arr)} data points:")
for i, (t, r, l) in enumerate(zip(theta_arr, rho_arr, labels)):
    print(f"  {l:35s}  θ={t:.3f}  ρ={r:.3f}")

# Remove NaN/inf
mask = np.isfinite(theta_arr) & np.isfinite(rho_arr)
theta_arr = theta_arr[mask]
rho_arr = rho_arr[mask]
labels = [l for i, l in enumerate(labels) if mask[i]]

print(f"\nAfter removing NaN/inf: {len(theta_arr)} points")

# Sort by θ
sort_idx = np.argsort(theta_arr)
theta_arr = theta_arr[sort_idx]
rho_arr = rho_arr[sort_idx]
labels = [labels[i] for i in sort_idx]

# Linear fit
slope, intercept, r_value, p_value, std_err = stats.linregress(theta_arr, rho_arr)
print(f"\nLinear: ρ = {slope:.3f}·θ + {intercept:.3f}, R²={r_value**2:.3f}, p={p_value:.4f}")

# Power law
def powerlaw(x, a, b):
    """Power law: f(x) = a*x^b. Candidate if scale-free."""
    return a * np.power(np.maximum(x, 1e-10), b)
try:
    popt_power, _ = curve_fit(powerlaw, theta_arr, rho_arr, p0=[1, 0.5], maxfev=10000)
    power_y = powerlaw(theta_arr, *popt_power)
    power_r2 = 1 - np.sum((rho_arr - power_y)**2) / np.sum((rho_arr - np.mean(rho_arr))**2)
    print(f"Power: ρ = {popt_power[0]:.3f}·θ^{popt_power[1]:.3f}, R²={power_r2:.3f}")
except Exception as e:
    print(f"Power fit failed: {e}")
    popt_power = None

# 3-parameter sigmoid (floor=0, max=1, variable threshold and steepness)
def sigmoid3(x, s, theta_star, rho_max):
    """3-param sigmoid: f(x) = rho_max / (1 + exp(-s*(x - theta_star)))."""
    return rho_max / (1 + np.exp(-s * (x - theta_star)))

try:
    popt_sig3, _ = curve_fit(sigmoid3, theta_arr, rho_arr, p0=[5, 0.3, 1], maxfev=20000)
    sig3_y = sigmoid3(theta_arr, *popt_sig3)
    sig3_r2 = 1 - np.sum((rho_arr - sig3_y)**2) / np.sum((rho_arr - np.mean(rho_arr))**2)
    print(f"Sigmoid(3-param): ρ = {popt_sig3[2]:.3f}/(1+exp(-{popt_sig3[0]:.2f}·(θ-{popt_sig3[1]:.3f}))), R²={sig3_r2:.3f}")
    print(f"  → θ* (threshold) = {popt_sig3[1]:.3f}")
    print(f"  → s (steepness) = {popt_sig3[0]:.2f}")
    print(f"  → ρ_max = {popt_sig3[2]:.3f}")
except Exception as e:
    print(f"Sigmoid 3-param fit failed: {e}")
    popt_sig3 = None

# 2-parameter sigmoid (fix rho_max=1, just threshold and steepness)
def sigmoid2(x, s, theta_star):
    """2-param sigmoid: f(x) = 1 / (1 + exp(-s*(x - theta_star)))."""
    return 1.0 / (1 + np.exp(-s * (x - theta_star)))
try:
    popt_sig2, _ = curve_fit(sigmoid2, theta_arr, rho_arr, p0=[5, 0.3], maxfev=20000)
    sig2_y = sigmoid2(theta_arr, *popt_sig2)
    sig2_r2 = 1 - np.sum((rho_arr - sig2_y)**2) / np.sum((rho_arr - np.mean(rho_arr))**2)
    print(f"Sigmoid(2-param, ρ_max=1): ρ = 1/(1+exp(-{popt_sig2[0]:.2f}·(θ-{popt_sig2[1]:.3f}))), R²={sig2_r2:.3f}")
except Exception as e:
    print(f"Sigmoid 2-param fit failed: {e}")
    popt_sig2 = None

# Logarithmic
def logfunc(x, a, b):
    """Logarithmic: f(x) = a*ln(x + b)."""
    return a * np.log(np.maximum(x, 1e-10) + b)
try:
    popt_log, _ = curve_fit(logfunc, theta_arr, rho_arr, p0=[0.5, 0.1], maxfev=10000)
    log_y = logfunc(theta_arr, *popt_log)
    log_r2 = 1 - np.sum((rho_arr - log_y)**2) / np.sum((rho_arr - np.mean(rho_arr))**2)
    print(f"Logarithmic: ρ = {popt_log[0]:.3f}·ln(θ+{popt_log[1]:.3f}), R²={log_r2:.3f}")
except Exception as e:
    print(f"Log fit failed: {e}")
    popt_log = None

# Square root (physics: diffusion/mean-field)
def sqrtfunc(x, a):
    """Square root: f(x) = a*sqrt(x). Diffusion/mean-field candidate."""
    return a * np.sqrt(np.maximum(x, 0))
try:
    popt_sqrt, _ = curve_fit(sqrtfunc, theta_arr, rho_arr, p0=[1], maxfev=10000)
    sqrt_y = sqrtfunc(theta_arr, *popt_sqrt)
    sqrt_r2 = 1 - np.sum((rho_arr - sqrt_y)**2) / np.sum((rho_arr - np.mean(rho_arr))**2)
    print(f"Square root: ρ = {popt_sqrt[0]:.3f}·√θ, R²={sqrt_r2:.3f}")
except Exception as e:
    print(f"Square root fit failed: {e}")
    popt_sqrt = None

# ============================================================
# 3. COMPREHENSIVE PLOT
# ============================================================

fig, axes = plt.subplots(2, 2, figsize=(14, 12))

# --- Panel A: All data points with best fits ---
ax = axes[0, 0]
# Color by domain
domain_colors = {
    'bacteria_free_living': 'red',
    'bacteria_endosymbiont': 'steelblue',
    'plant_parasite': 'green',
}
# Color by domain - just plot all points
for i, (t, r, l) in enumerate(zip(theta_arr, rho_arr, labels)):
    # Find domain
    domain = 'unknown'
    for pt in all_points:
        if pt.get('system') == l:
            domain = pt.get('domain', 'unknown')
            break
    color = domain_colors.get(domain, 'steelblue')
    ax.scatter(t, r, s=80, c=color, edgecolors='black', zorder=5)
    fontsize = 7 if len(l) > 25 else 8
    ax.annotate(l, (t, r), textcoords="offset points", xytext=(5, 5), fontsize=fontsize)

# Plot fits
theta_fine = np.linspace(0, 1, 500)
ax.plot(theta_fine, slope * theta_fine + intercept, 'b--', alpha=0.4, label=f'Linear R²={r_value**2:.2f}')
if popt_power is not None:
    ax.plot(theta_fine, powerlaw(theta_fine, *popt_power), 'g-.', alpha=0.5, label=f'Power R²={power_r2:.2f}')
if popt_sig3 is not None:
    ax.plot(theta_fine, sigmoid3(theta_fine, *popt_sig3), 'r-', alpha=0.5, linewidth=2, label=f'Sigmoid R²={sig3_r2:.2f}')
if popt_sig2 is not None:
    ax.plot(theta_fine, sigmoid2(theta_fine, *popt_sig2), 'm:', alpha=0.5, label=f'Sigmoid(ρ_max=1) R²={sig2_r2:.2f}')
if popt_sqrt is not None:
    ax.plot(theta_fine, sqrtfunc(theta_fine, *popt_sqrt), 'c-', alpha=0.3, label=f'√θ R²={sqrt_r2:.2f}')

ax.set_xlabel('θ (niche dependency parameter)', fontsize=11)
ax.set_ylabel('ρ (valence effect size)', fontsize=11)
ax.set_title('A. All Data: ρ vs θ with Candidate Formulas', fontsize=12)
ax.legend(fontsize=8, loc='upper left')
ax.set_xlim(-0.05, 1.05)
ax.set_ylim(-0.2, 1.15)
ax.axhline(y=0, color='gray', linestyle='-', alpha=0.3)
ax.grid(True, alpha=0.3)

# --- Panel B: Physics Attractor Interpretation ---
ax = axes[0, 1]
# Plot as phase diagram: θ on x-axis, ρ on y-axis
# Show the "phase transition" region
ax.scatter(theta_arr, rho_arr, s=80, c='steelblue', edgecolors='black', zorder=5)

if popt_sig3 is not None:
    s, theta_star, rho_max = popt_sig3
    # Draw the sigmoid
    ax.plot(theta_fine, sigmoid3(theta_fine, *popt_sig3), 'r-', linewidth=2, alpha=0.7)
    # Mark the critical point
    ax.axvline(x=theta_star, color='red', linestyle='--', alpha=0.3)
    ax.annotate(f'θ* = {theta_star:.3f}\n(Critical point)', 
                (theta_star, 0.5), textcoords="offset points", xytext=(15, 0), fontsize=9, color='red')
    # Shade the "phases"
    ax.axvspan(0, theta_star, alpha=0.1, color='blue', label='Disordered\n(valence absent)')
    ax.axvspan(theta_star, 1, alpha=0.1, color='red', label='Ordered\n(valence present)')

ax.set_xlabel('θ (control parameter — analog of temperature)', fontsize=11)
ax.set_ylabel('ρ (order parameter — analog of magnetization)', fontsize=11)
ax.set_title('B. Physics Attractor Interpretation\n(Ising / Landau / Curie analog)', fontsize=12)
ax.legend(fontsize=9)
ax.set_xlim(-0.05, 1.05)
ax.set_ylim(-0.2, 1.15)
ax.grid(True, alpha=0.3)

# --- Panel C: Endosymbiont genus-level with symbiosis age as θ ---
ax = axes[1, 0]
endo = pd.read_csv(WORKSPACE / "valence-foundry/data/endosymbiont_genome_data.tsv", sep="\t")
genus_sum = endo.groupby('genus').agg(
    mean_genome_bp=('genome_bp', 'mean'),
    mean_aa=('aa_pathways_retained', 'mean'),
    mean_age=('symbiosis_age_mya', 'mean'),
    n=('species', 'count'),
).reset_index()

# θ from symbiosis age (normalized 0-1)
max_age = genus_sum['mean_age'].max()
genus_sum['theta_age'] = genus_sum['mean_age'] / max_age
# Retention from aa pathways
genus_sum['retention_aa'] = genus_sum['mean_aa'] / 20.0
# θ from genome ratio
genus_sum['theta_genome'] = 1 - (genus_sum['mean_genome_bp'] / 4_500_000)

for _, row in genus_sum.sort_values('theta_age').iterrows():
    ax.scatter(row['theta_age'], row['retention_aa'], s=row['n']*8, c='steelblue', edgecolors='black', zorder=5)
    ax.annotate(f"{row['genus']}\n({row['mean_age']:.0f}Mya, n={row['n']})", 
                (row['theta_age'], row['retention_aa']), fontsize=7, xytext=(5, 5), textcoords='offset points')

# Add LTEE point
ax.scatter([0], [1.0], s=100, c='red', marker='*', edgecolors='black', zorder=5)
ax.annotate('LTEE\n(0 Mya)', (0, 1.0), fontsize=8, xytext=(5, -15), textcoords='offset points')

# Fit sigmoid to this data
theta_endo_age = np.concatenate([[0], genus_sum['theta_age'].values])
retention_endo_age = np.concatenate([[1.0], genus_sum['retention_aa'].values])
try:
    popt_endo_age, _ = curve_fit(sigmoid3, theta_endo_age, retention_endo_age, p0=[5, 0.5, 0.5], maxfev=20000)
    endo_age_y = sigmoid3(theta_endo_age, *popt_endo_age)
    endo_age_r2 = 1 - np.sum((retention_endo_age - endo_age_y)**2) / np.sum((retention_endo_age - np.mean(retention_endo_age))**2)
    ax.plot(theta_fine, sigmoid3(theta_fine, *popt_endo_age), 'r-', alpha=0.5, label=f'Sigmoid R²={endo_age_r2:.2f}')
    print(f"\nEndosymbiont (symbiosis age θ): sigmoid θ*={popt_endo_age[1]:.3f}, s={popt_endo_age[0]:.2f}, R²={endo_age_r2:.3f}")
except Exception as e:
    print(f"Endosymbiont age sigmoid failed: {e}")

ax.set_xlabel('θ = symbiosis_age / max_age', fontsize=11)
ax.set_ylabel('Retention (AA pathways / 20)', fontsize=11)
ax.set_title('C. Endosymbionts: θ from Symbiosis Age\n(Independent control parameter)', fontsize=12)
ax.legend(fontsize=9)
ax.set_xlim(-0.05, 1.05)
ax.set_ylim(-0.1, 1.15)
ax.grid(True, alpha=0.3)

# --- Panel D: Residual analysis (observed - predicted) ---
ax = axes[1, 1]
if popt_sig3 is not None:
    predicted = sigmoid3(theta_arr, *popt_sig3)
    residuals = rho_arr - predicted
    ax.bar(range(len(residuals)), residuals, color=['red' if r < 0 else 'steelblue' for r in residuals], edgecolor='black')
    ax.set_xticks(range(len(residuals)))
    ax.set_xticklabels([l[:15] for l in labels], rotation=45, ha='right', fontsize=7)
    ax.axhline(y=0, color='black', linewidth=1)
    ax.set_ylabel('Residual (observed - predicted)')
    ax.set_title('D. Residuals from Sigmoid Fit', fontsize=12)
    ax.grid(True, alpha=0.3, axis='y')
    
    # Print residual stats
    print(f"\nResidual stats:")
    print(f"  Mean: {np.mean(residuals):.4f}")
    print(f"  Std: {np.std(residuals):.4f}")
    print(f"  Max: {np.max(residuals):.4f} ({labels[np.argmax(residuals)]})")
    print(f"  Min: {np.min(residuals):.4f} ({labels[np.argmin(residuals)]})")
else:
    ax.text(0.5, 0.5, "Sigmoid fit not available", ha='center', va='center', fontsize=14)
    ax.set_title('D. Residuals (no fit available)', fontsize=12)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'formula_deep_analysis.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'formula_deep_analysis.png'}")

# ============================================================
# 4. MONOGRAPH COMPARISON
# ============================================================

print("\n\n" + "=" * 60)
print("MONOGRAPH THEORY COMPARISON")
print("=" * 60)

print(f"""
Monograph's proposed forms:
  1. Rate function: dC/dt = -k·M·f(I(C))
  2. Substrate-shift: α(x) = -k_ecol + k_cult · σ((x-x*)/s)
  3. Cusp catastrophe: S = f(a, b) — irreversibility
  4. Autocatalytic closure: Kauffman set

Empirical findings:""")

if popt_sig3 is not None:
    print(f"""
  Sigmoid fit: ρ = {popt_sig3[2]:.3f} / (1 + exp(-{popt_sig3[0]:.2f}·(θ - {popt_sig3[1]:.3f})))
  R² = {sig3_r2:.3f}
  
  Mapping to monograph:
  - ρ_max = {popt_sig3[2]:.3f} → k_cult (amplitude of valence effect)
  - θ* = {popt_sig3[1]:.3f} → x* (critical threshold, substrate-shift point)
  - s = {popt_sig3[0]:.2f} → s (steepness, cooperativity)
  
  Physics attractor mapping:
  - θ* ↔ Tc (Curie temperature) — critical point
  - ρ ↔ M (magnetization) — order parameter
  - θ ↔ T/Tc (reduced temperature) — control parameter
  - s ↔ J/kT (coupling strength) — cooperativity
  
  IF this mapping holds, the formula IS the physics attractor form:
    ρ(θ) = ρ_max / (1 + exp(-s·(θ - θ*)))
  
  This is the Fermi-Dirac distribution, the Ising mean-field solution,
  and the Landau order parameter — all the same mathematical object.
""")

if popt_power is not None:
    print(f"  Power law alternative: ρ = {popt_power[0]:.3f}·θ^{popt_power[1]:.3f}, R²={power_r2:.3f}")
    print(f"  → Sublinear (exponent < 1): response accelerates then saturates")
    print(f"  → Consistent with sigmoid at low resolution")
    print(f"  → But power law has no threshold — no phase transition")

if popt_sqrt is not None:
    print(f"  Square root: ρ = {popt_sqrt[0]:.3f}·√θ, R²={sqrt_r2:.3f}")
    print(f"  → This is the mean-field critical scaling below Tc")
    print(f"  → In Landau theory: M ∝ √(Tc-T) below Tc")
    print(f"  → Or diffusion-limited aggregation scaling")

# ============================================================
# 5. SUMMARY AND VERDICT
# ============================================================

print("\n" + "=" * 60)
print("SUMMARY VERDICT")
print("=" * 60)

fits_summary = []
if r_value**2 > 0:
    fits_summary.append(('Linear', r_value**2, len(theta_arr)))
if popt_power is not None:
    fits_summary.append(('Power', power_r2, len(theta_arr)))
if popt_sig3 is not None:
    fits_summary.append(('Sigmoid(3-param)', sig3_r2, len(theta_arr)))
if popt_sig2 is not None:
    fits_summary.append(('Sigmoid(ρ_max=1)', sig2_r2, len(theta_arr)))
if popt_sqrt is not None:
    fits_summary.append(('√θ (mean-field)', sqrt_r2, len(theta_arr)))
if popt_log is not None:
    fits_summary.append(('Logarithmic', log_r2, len(theta_arr)))

fits_summary.sort(key=lambda x: -x[1])
print(f"\nFormula ranking (by R²):")
for name, r2, n in fits_summary:
    marker = " ★" if r2 == max(f[1] for f in fits_summary) else ""
    print(f"  {name:25s}  R²={r2:.3f}  (n={n}){marker}")

print(f"\nKey finding:")
if popt_sig3 is not None and sig3_r2 > 0.7:
    print(f"  Sigmoid fit R²={sig3_r2:.3f} — valence effect follows a phase-transition curve")
    print(f"  θ* = {popt_sig3[1]:.3f} is the critical dependency threshold")
    print(f"  This IS the physics attractor form Jan intuited")
elif popt_power is not None and power_r2 > 0.7:
    print(f"  Power law fit R²={power_r2:.3f} — valence effect follows a power law")
    print(f"  Exponent {popt_power[1]:.3f} — sublinear, approaching saturation")
    print(f"  Consistent with sigmoid at low resolution, but no explicit threshold")

# Save results
results = {
    'n_data_points': len(theta_arr),
    'data_points': [{'system': l, 'theta': float(t), 'rho': float(r)} for l, t, r in zip(labels, theta_arr, rho_arr)],
    'fits': {name: {'r_squared': r2} for name, r2, _ in fits_summary},
    'best_fit': fits_summary[0] if fits_summary else None,
}
if popt_sig3 is not None:
    results['sigmoid_params'] = {
        'steepness': float(popt_sig3[0]),
        'theta_star': float(popt_sig3[1]),
        'rho_max': float(popt_sig3[2]),
        'r_squared': float(sig3_r2),
    }

with open(OUTPUT_DIR / 'formula_deep_results.json', 'w') as f:
    json.dump(results, f, indent=2, default=str)
print(f"\nSaved: {OUTPUT_DIR / 'formula_deep_results.json'}")
