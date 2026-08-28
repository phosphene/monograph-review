#!/usr/bin/env python3
"""
Evolution Laser Beam: test the step-function formula against all available data.
"""
import json
import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path

WORKSPACE = Path("/home/node/.openclaw/workspace")
OUTPUT_DIR = WORKSPACE / "valence-foundry" / "data" / "formula-analysis"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

results = {}

# ============================================================
# 1. ISLAND BIRDS — ρ for trait loss ordering
# ============================================================
print("="*60)
print("1. ISLAND BIRDS — Trait loss ordering")
print("="*60)

birds = pd.read_csv(WORKSPACE / "valence-foundry/data/island_bird_morphology.csv")
print(f"Data: {len(birds)} structures")
print(birds)

rho_bird, p_bird = stats.spearmanr(birds['dependency_score'], birds['observed_rank'])
print(f"\nρ (dependency vs loss rank): {rho_bird:.3f}, p={p_bird:.4f}")

# Step function test: dep=0 traits lost first, dep>0 traits retained
dep_zero = birds[birds['dependency_score'] == 0]
dep_nonzero = birds[birds['dependency_score'] > 0]
print(f"Zero-dep traits: mean rank = {dep_zero['observed_rank'].mean():.1f} (lost first)")
print(f"Non-zero-dep traits: mean rank = {dep_nonzero['observed_rank'].mean():.1f} (retained)")
print(f"Step: {dep_nonzero['observed_rank'].mean() - dep_zero['observed_rank'].mean():.1f} rank units")

results['island_birds'] = {
    'rho': float(rho_bird), 'p': float(p_bird),
    'n': len(birds),
    'zero_dep_mean_rank': float(dep_zero['observed_rank'].mean()),
    'nonzero_dep_mean_rank': float(dep_nonzero['observed_rank'].mean()),
}

# ============================================================
# 2. CROSS-FAMILY PLASTOME DATA — step function in plastome size
# ============================================================
print("\n\n" + "="*60)
print("2. CROSS-FAMILY PLASTOME — Size vs parasitism")
print("="*60)

cross = pd.read_csv(WORKSPACE / "valence-foundry/data/cross_family_plastome_data.tsv", sep="\t")
print(f"Data: {len(cross)} species")

# θ = parasitism_score / max
cross['theta'] = cross['parasitism_score'] / 4.0
# Retention = plastome_bp / max_plastome_bp (normalized genome retention)
max_bp = cross['plastome_bp'].max()
cross['retention'] = cross['plastome_bp'] / max_bp

rho_cross, p_cross = stats.spearmanr(cross['parasitism_score'], cross['plastome_bp'])
print(f"ρ (parasitism vs plastome size): {rho_cross:.3f}, p={p_cross:.6f}")

# Check for step function: is there a sharp drop at some parasitism threshold?
from scipy.optimize import curve_fit

def step_func(x, x_star, y_low, y_high):
    """Heaviside step: f(x) = y_low if x < x_star, else y_high."""
    return np.where(x < x_star, y_low, y_high)

parasitism = cross['parasitism_score'].values
plastome = cross['plastome_bp'].values

# Try different thresholds
best_r2 = -np.inf
best_threshold = None
for t in np.arange(0.5, 4.0, 0.1):
    below = plastome[parasitism < t]
    above = plastome[parasitism >= t]
    if len(below) > 0 and len(above) > 0:
        predicted = np.where(parasitism < t, below.mean(), above.mean())
        ss_res = np.sum((plastome - predicted)**2)
        ss_tot = np.sum((plastome - plastome.mean())**2)
        r2 = 1 - ss_res / ss_tot
        if r2 > best_r2:
            best_r2 = r2
            best_threshold = t
            best_below = below.mean()
            best_above = above.mean()

print(f"\nStep function: threshold={best_threshold:.1f}, below={best_below:.0f} bp, above={best_above:.0f} bp, R²={best_r2:.3f}")
print(f"  → {'STEP CONFIRMED' if best_r2 > 0.5 else 'no clear step'}")

results['cross_family_plastome'] = {
    'rho': float(rho_cross), 'p': float(p_cross),
    'n': len(cross),
    'step_threshold': float(best_threshold),
    'step_r2': float(best_r2),
    'below_mean_bp': float(best_below),
    'above_mean_bp': float(best_above),
}

# ============================================================
# 3. SPECIES PLASTOME DATA — finer-grained parasitism gradient
# ============================================================
print("\n\n" + "="*60)
print("3. SPECIES PLASTOME — Finer parasitism gradient")
print("="*60)

species = pd.read_csv(WORKSPACE / "valence-foundry/data/species_plastome_data.tsv", sep="\t")
print(f"Data: {len(species)} species")
print(f"Parasitism scores: {sorted(species['parasitism_score'].unique())}")

rho_sp, p_sp = stats.spearmanr(species['parasitism_score'], species['plastome_length_bp'])
print(f"ρ (parasitism vs plastome size): {rho_sp:.3f}, p={p_sp:.6f}")

# Step function test
parasitism_sp = species['parasitism_score'].values
plastome_sp = species['plastome_length_bp'].values

best_r2_sp = -np.inf
best_threshold_sp = None
for t in np.arange(0.5, 4.0, 0.1):
    below = plastome_sp[parasitism_sp < t]
    above = plastome_sp[parasitism_sp >= t]
    if len(below) > 2 and len(above) > 2:
        predicted = np.where(parasitism_sp < t, below.mean(), above.mean())
        ss_res = np.sum((plastome_sp - predicted)**2)
        ss_tot = np.sum((plastome_sp - plastome_sp.mean())**2)
        r2 = 1 - ss_res / ss_tot
        if r2 > best_r2_sp:
            best_r2_sp = r2
            best_threshold_sp = t

print(f"Step function: threshold={best_threshold_sp:.1f}, R²={best_r2_sp:.3f}")

# Also fit linear for comparison
slope_sp, intercept_sp, r_sp, p_sp_lin, _ = stats.linregress(parasitism_sp, plastome_sp)
print(f"Linear: slope={slope_sp:.0f}, R²={r_sp**2:.3f}")

results['species_plastome'] = {
    'rho': float(rho_sp), 'p': float(p_sp),
    'n': len(species),
    'step_threshold': float(best_threshold_sp),
    'step_r2': float(best_r2_sp),
    'linear_r2': float(r_sp**2),
}

# ============================================================
# 4. DEWAR PANGENOME — Lifestyle vs fluidity
# ============================================================
print("\n\n" + "="*60)
print("4. DEWAR PANGENOME — Lifestyle vs pan-genome fluidity")
print("="*60)

dewar = pd.read_csv(WORKSPACE / "valence-foundry/data/dewar_pangenome_lifestyles.csv")
# fluidity = accessory / pan (openness of pan-genome)
dewar['fluidity'] = dewar['pangenome_fluidity']
# genome_size is in the data
print(f"Data: {len(dewar)} species")
print(f"Lifestyles: {dewar['Host_or_free'].value_counts().to_dict()}")

# Compare fluidity across lifestyles
for lifestyle in ['Free', 'Both', 'Host']:
    sub = dewar[dewar['Host_or_free'] == lifestyle]
    if len(sub) > 0:
        print(f"  {lifestyle}: fluidity={sub['fluidity'].mean():.3f} ± {sub['fluidity'].std():.3f} (n={len(sub)})")

# Step function test: Free vs (Both + Host)
free_fluid = dewar[dewar['Host_or_free'] == 'Free']['fluidity']
symb_fluid = dewar[dewar['Host_or_free'].isin(['Both', 'Host'])]['fluidity']
if len(free_fluid) > 0 and len(symb_fluid) > 0:
    t_stat, t_p = stats.ttest_ind(free_fluid, symb_fluid)
    print(f"\nFree vs Symbiotic: t={t_stat:.2f}, p={t_p:.4f}")
    print(f"  Free: {free_fluid.mean():.3f}")
    print(f"  Symbiotic: {symb_fluid.mean():.3f}")
    print(f"  Difference: {symb_fluid.mean() - free_fluid.mean():.3f}")

# Also: genome size across lifestyles
for lifestyle in ['Free', 'Both', 'Host']:
    sub = dewar[dewar['Host_or_free'] == lifestyle]
    if len(sub) > 0 and sub['genome_size'].notna().any():
        print(f"  {lifestyle}: genome={sub['genome_size'].dropna().mean():.0f} bp (n={sub['genome_size'].notna().sum()})")

results['dewar_pangenome'] = {
    'n_species': len(dewar),
    'free_fluidity': float(free_fluid.mean()) if len(free_fluid) > 0 else None,
    'symbiotic_fluidity': float(symb_fluid.mean()) if len(symb_fluid) > 0 else None,
    't_stat': float(t_stat) if len(free_fluid) > 0 and len(symb_fluid) > 0 else None,
    't_p': float(t_p) if len(free_fluid) > 0 and len(symb_fluid) > 0 else None,
}

# ============================================================
# 5. ENDOSYMBIONT DATA — θ vs retention (all 367 species)
# ============================================================
print("\n\n" + "="*60)
print("5. ENDOSYMBIONT — θ vs retention (species-level)")
print("="*60)

endo = pd.read_csv(WORKSPACE / "valence-foundry/data/endosymbiont_genome_data.tsv", sep="\t")
print(f"Data: {len(endo)} species, {endo['genus'].nunique()} genera")

# θ = 1 - (genome/ancestor)
endo['theta'] = 1 - (endo['genome_bp'] / 4_500_000)
endo['theta'] = endo['theta'].clip(0, 1)
# Retention = aa_pathways / 20
endo['retention'] = endo['aa_pathways_retained'] / 20.0

rho_endo, p_endo = stats.spearmanr(endo['theta'], endo['retention'])
print(f"ρ (θ vs retention): {rho_endo:.3f}, p={p_endo:.6f}")

# Step function: try different θ* thresholds
best_r2_endo = -np.inf
best_theta_star = None
for ts in np.arange(0.01, 0.99, 0.01):
    below = endo[endo['theta'] < ts]
    above = endo[endo['theta'] >= ts]
    if len(below) > 5 and len(above) > 5:
        predicted = np.where(endo['theta'].values < ts, below['retention'].mean(), above['retention'].mean())
        ss_res = np.sum((endo['retention'].values - predicted)**2)
        ss_tot = np.sum((endo['retention'].values - endo['retention'].mean())**2)
        r2 = 1 - ss_res / ss_tot
        if r2 > best_r2_endo:
            best_r2_endo = r2
            best_theta_star = ts

print(f"Step function: θ*={best_theta_star:.2f}, R²={best_r2_endo:.3f}")

# Also linear
slope_e, intercept_e, r_e, p_e, _ = stats.linregress(endo['theta'], endo['retention'])
print(f"Linear: R²={r_e**2:.3f}")

results['endosymbiont_species'] = {
    'rho': float(rho_endo), 'p': float(p_endo),
    'n': len(endo),
    'step_theta_star': float(best_theta_star),
    'step_r2': float(best_r2_endo),
    'linear_r2': float(r_e**2),
}

# ============================================================
# 6. OROBANCHACEAE — per-gene-category retention vs dependency
# ============================================================
print("\n\n" + "="*60)
print("6. OROBANCHACEAE — Pooled ρ and step function")
print("="*60)

orobanch = pd.read_csv(WORKSPACE / "valence-foundry/data/orobanchaceae_retention_matrix.tsv", sep="\t")
# Pooled ρ
rho_oro, p_oro = stats.spearmanr(orobanch['dependency_score'], orobanch['retention'])
print(f"Pooled ρ (dependency vs retention): {rho_oro:.3f}, p={p_oro:.6f}")

# Step function: dep=0 vs dep>0
dep_zero_oro = orobanch[orobanch['dependency_score'] == 0]
dep_nonzero_oro = orobanch[orobanch['dependency_score'] > 0]
print(f"Zero-dep retention: {dep_zero_oro['retention'].mean():.3f} (n={len(dep_zero_oro)})")
print(f"Non-zero-dep retention: {dep_nonzero_oro['retention'].mean():.3f} (n={len(dep_nonzero_oro)})")
print(f"Step: {dep_nonzero_oro['retention'].mean() - dep_zero_oro['retention'].mean():.3f}")

# Only parasitic species (exclude autotroph)
parasitic = orobanch[orobanch['parasitism_score'] > 0]
rho_par, p_par = stats.spearmanr(parasitic['dependency_score'], parasitic['retention'])
print(f"\nParasitic only ρ: {rho_par:.3f}, p={p_par:.6f}")

dep_zero_par = parasitic[parasitic['dependency_score'] == 0]
dep_nonzero_par = parasitic[parasitic['dependency_score'] > 0]
print(f"Zero-dep retention: {dep_zero_par['retention'].mean():.3f} (n={len(dep_zero_par)})")
print(f"Non-zero-dep retention: {dep_nonzero_par['retention'].mean():.3f} (n={len(dep_nonzero_par)})")

results['orobanchaceae'] = {
    'pooled_rho': float(rho_oro), 'pooled_p': float(p_oro),
    'parasitic_rho': float(rho_par), 'parasitic_p': float(p_par),
    'zero_dep_retention': float(dep_zero_par['retention'].mean()),
    'nonzero_dep_retention': float(dep_nonzero_par['retention'].mean()),
}

# ============================================================
# 7. COMBINE ALL SYSTEMS — Meta-analysis
# ============================================================
print("\n\n" + "="*60)
print("7. META-ANALYSIS — All systems on the laser beam")
print("="*60)

# All ρ values we've computed
all_rhos = [
    ('LTEE (free-living)', 0.000, -0.039, 'bacteria_free_living'),
    ('Sodalis (endosymbiont)', 0.044, 0.353, 'bacteria_symbiotic'),
    ('Buchnera (endosymbiont)', 0.500, 0.372, 'bacteria_symbiotic'),
    ('Island birds (trait loss)', None, float(rho_bird), 'animal_trait_loss'),
    ('Orobanchaceae pooled (parasitic plants)', 0.562, float(rho_par), 'plant_parasitic'),
    ('Cross-family plastome (parasitism vs size)', None, float(rho_cross), 'plant_parasitic'),
    ('Endosymbiont species (θ vs retention)', None, float(rho_endo), 'bacteria_symbiotic'),
]

print(f"{'System':45s} {'θ':>8s} {'ρ':>8s} {'Domain':25s}")
print("-"*90)
for name, theta, rho, domain in all_rhos:
    theta_str = f"{theta:.3f}" if theta is not None else "N/A"
    print(f"{name:45s} {theta_str:>8s} {rho:8.3f} {domain:25s}")

# ============================================================
# PLOT
# ============================================================
fig, axes = plt.subplots(2, 3, figsize=(18, 10))

# Panel 1: Island birds
ax = axes[0, 0]
ax.scatter(birds['dependency_score'], birds['observed_rank'], s=100, c='steelblue', edgecolors='black')
for i, row in birds.iterrows():
    ax.annotate(row['structure'], (row['dependency_score'], row['observed_rank']), fontsize=7, xytext=(5, 5), textcoords='offset points')
ax.set_xlabel('Dependency score')
ax.set_ylabel('Loss rank (1=lost first)')
ax.set_title(f'Island Birds: ρ={rho_bird:.3f}')
ax.grid(True, alpha=0.3)

# Panel 2: Cross-family plastome
ax = axes[0, 1]
colors = {'autotroph': 'green', 'hemiparasite': 'orange', 'holoparasite': 'red'}
for cat, color in colors.items():
    mask = cross['parasitism_level'] == cat
    if mask.any():
        ax.scatter(cross.loc[mask, 'parasitism_score'], cross.loc[mask, 'plastome_bp'], c=color, label=cat, edgecolors='black')
ax.axvline(x=best_threshold, color='blue', linestyle='--', alpha=0.5, label=f'Step at {best_threshold:.1f}')
ax.set_xlabel('Parasitism score')
ax.set_ylabel('Plastome size (bp)')
ax.set_title(f'Cross-Family: ρ={rho_cross:.3f}, Step R²={best_r2:.3f}')
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

# Panel 3: Species plastome
ax = axes[0, 2]
sc = ax.scatter(species['parasitism_score'], species['plastome_length_bp'], c='steelblue', edgecolors='black', s=30)
ax.axvline(x=best_threshold_sp, color='red', linestyle='--', alpha=0.5, label=f'Step at {best_threshold_sp:.1f}')
ax.set_xlabel('Parasitism score')
ax.set_ylabel('Plastome size (bp)')
ax.set_title(f'Species Plastome: ρ={rho_sp:.3f}, Step R²={best_r2_sp:.3f}')
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

# Panel 4: Dewar fluidity
ax = axes[1, 0]
lifestyles = ['Free', 'Both', 'Host']
fluid_means = [dewar[dewar['Host_or_free']==l]['fluidity'].dropna().mean() for l in lifestyles]
fluid_stds = [dewar[dewar['Host_or_free']==l]['fluidity'].dropna().std() for l in lifestyles]
ax.bar(lifestyles, fluid_means, yerr=fluid_stds, color=['green', 'orange', 'red'], edgecolor='black', capsize=5)
ax.set_ylabel('Pan-genome fluidity')
ax.set_title('Dewar: Fluidity by Lifestyle')
ax.grid(True, alpha=0.3, axis='y')

# Panel 5: Endosymbiont θ vs retention
ax = axes[1, 1]
sc = ax.scatter(endo['theta'], endo['retention'], c='steelblue', edgecolors='black', s=20, alpha=0.6)
ax.axvline(x=best_theta_star, color='red', linestyle='--', alpha=0.5, label=f'Step at θ={best_theta_star:.2f}')
ax.set_xlabel('θ (genome reduction)')
ax.set_ylabel('Retention (AA/20)')
ax.set_title(f'Endosymbionts: ρ={rho_endo:.3f}, Step R²={best_r2_endo:.3f}')
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

# Panel 6: Orobanchaceae step
ax = axes[1, 2]
cats = ['dep=0', 'dep>0']
means = [dep_zero_par['retention'].mean(), dep_nonzero_par['retention'].mean()]
ax.bar(cats, means, color=['red', 'green'], edgecolor='black')
ax.set_ylabel('Retention rate')
ax.set_title(f'Orobanchaceae: Step at dep=0\nρ={rho_par:.3f}')
ax.grid(True, alpha=0.3, axis='y')
for i, m in enumerate(means):
    ax.text(i, m + 0.02, f'{m:.3f}', ha='center', fontsize=10)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'laser_beam_all_systems.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'laser_beam_all_systems.png'}")

# Save results
with open(OUTPUT_DIR / 'laser_beam_results.json', 'w') as f:
    json.dump(results, f, indent=2)
print(f"Saved: {OUTPUT_DIR / 'laser_beam_results.json'}")
