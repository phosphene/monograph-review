#!/usr/bin/env python3
"""
Evolution Laser Beam: Language evolution via Grambank.
Test: do languages show a step function in grammatical feature retention?

θ = speaker population size or family diversity (proxy for linguistic niche dependency)
Feature dependency = co-occurrence degree (how many other features depend on this one)
ρ = correlation between feature dependency and feature presence (1/0)
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
GB_DIR = WORKSPACE / "data/glottobank/grambank/grambank_extracted/grambank-grambank-7ae000c/cldf"
OUTPUT_DIR = WORKSPACE / "valence-foundry/data/formula-analysis"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================
# 1. LOAD GRAMBANK DATA
# ============================================================
print("="*60)
print("LOADING GRAMBANK DATA")
print("="*60)

values = pd.read_csv(GB_DIR / "values.csv")
languages = pd.read_csv(GB_DIR / "languages.csv")
parameters = pd.read_csv(GB_DIR / "parameters.csv")
feature_groups = pd.read_csv(WORKSPACE / "data/glottobank/grambank/grambank_extracted/grambank-grambank-7ae000c/docs/feature_groupings/feature_grouping_for_analysis.csv")

print(f"Values: {len(values)} rows")
print(f"Languages: {len(languages)}")
print(f"Features: {len(parameters)}")
print(f"Feature groups: {len(feature_groups)}")

# Filter to binary values (0/1) only
values_bin = values[values['Value'].isin(['0', '1'])].copy()
values_bin['Value'] = values_bin['Value'].astype(int)
print(f"Binary values: {len(values_bin)} rows")
print(f"Value=1 (present): {values_bin['Value'].sum()} ({values_bin['Value'].mean()*100:.1f}%)")

# ============================================================
# 2. COMPUTE FEATURE DEPENDENCY (co-occurrence network degree)
# ============================================================
print("\n" + "="*60)
print("COMPUTING FEATURE DEPENDENCY SCORES")
print("="*60)

# Create language × feature matrix
matrix = values_bin.pivot_table(index='Language_ID', columns='Parameter_ID', values='Value', aggfunc='first')

# For each feature, compute how many other features it co-occurs with
# Feature dependency = how correlated this feature is with all other features
# High dependency = feature is in the core (many other features depend on it)
# Low dependency = feature is peripheral (varies independently)

# Compute pairwise feature correlations
feature_cols = matrix.columns
n_features = len(feature_cols)
print(f"Computing pairwise correlations for {n_features} features...")

# For each feature, compute mean absolute correlation with all other features
# This is the "dependency score" — how interconnected this feature is
feature_deps = []
for i, feat in enumerate(feature_cols):
    col = matrix[feat].dropna()
    corrs = []
    for j, other_feat in enumerate(feature_cols):
        if feat == other_feat:
            continue
        other_col = matrix[other_feat].dropna()
        common = col.index.intersection(other_col.index)
        if len(common) > 10:
            c = col.loc[common].corr(other_col.loc[common])
            if not np.isnan(c):
                corrs.append(abs(c))
    dep_score = np.mean(corrs) if corrs else 0
    feature_deps.append({
        'feature': feat,
        'dependency_score': dep_score,
        'mean_abs_corr': dep_score,
        'n_correlated': len(corrs),
        'prevalence': col.mean(),  # how often this feature is present
    })
    
dep_df = pd.DataFrame(feature_deps)
dep_df = dep_df.sort_values('dependency_score', ascending=False)

print(f"\nTop 10 most dependent features:")
print(dep_df.head(10)[['feature', 'dependency_score', 'prevalence']].to_string(index=False))
print(f"\nBottom 10 least dependent features:")
print(dep_df.tail(10)[['feature', 'dependency_score', 'prevalence']].to_string(index=False))

# ============================================================
# 3. COMPUTE θ (NICHE DEPENDENCY) FOR LANGUAGES
# ============================================================
print("\n" + "="*60)
print("COMPUTING θ FOR LANGUAGES")
print("="*60)

# θ proxy: number of features present (fewer = more reduced = higher θ)
# Languages with fewer grammatical features are more "niche-dependent"
# (larger speaker populations, more contact → simplification)
language_feature_counts = matrix.sum(axis=1)
language_feature_counts.name = 'n_features_present'

# θ = 1 - (n_features_present / max_features)
max_features = matrix.shape[1]
language_theta = 1 - (language_feature_counts / max_features)
language_theta.name = 'theta'

# Merge with language metadata
lang_data = languages.set_index('ID').join(language_feature_counts).join(language_theta)
print(f"Languages with feature data: {lang_data['n_features_present'].notna().sum()}")
print(f"θ distribution: mean={lang_data['theta'].mean():.3f}, std={lang_data['theta'].std():.3f}")
print(f"  min={lang_data['theta'].min():.3f}, max={lang_data['theta'].max():.3f}")

# θ by macroarea
print(f"\nθ by macroarea:")
for area in lang_data['Macroarea'].dropna().unique():
    sub = lang_data[lang_data['Macroarea'] == area]
    print(f"  {area:20s}: θ={sub['theta'].mean():.3f} ± {sub['theta'].std():.3f} (n={len(sub)})")

# ============================================================
# 4. COMPUTE ρ PER LANGUAGE (dependency vs presence)
# ============================================================
print("\n" + "="*60)
print("COMPUTING ρ PER LANGUAGE")
print("="*60)

# For each language: ρ = Spearman(feature_dependency_score, feature_present)
# High ρ = high-dependency features retained, low-dependency features lost
# Low ρ = random feature loss (no dependency ordering)

rho_results = []
for lang_id in matrix.index:
    lang_features = matrix.loc[lang_id].dropna()
    if len(lang_features) < 50:
        continue
    # Merge with dependency scores
    lang_dep = dep_df.set_index('feature').loc[lang_features.index]
    if lang_features.std() == 0:
        rho_results.append({
            'language_id': lang_id,
            'rho': np.nan,
            'p': np.nan,
            'n_features': len(lang_features),
            'theta': language_theta.get(lang_id, np.nan),
            'n_present': int(lang_features.sum()),
        })
        continue
    rho, p = stats.spearmanr(lang_dep['dependency_score'], lang_features)
    rho_results.append({
        'language_id': lang_id,
        'rho': rho,
        'p': p,
        'n_features': len(lang_features),
        'theta': language_theta.get(lang_id, np.nan),
        'n_present': int(lang_features.sum()),
    })

rho_df = pd.DataFrame(rho_results).dropna(subset=['rho'])
print(f"Languages with valid ρ: {len(rho_df)}")
print(f"ρ distribution: mean={rho_df['rho'].mean():.3f}, std={rho_df['rho'].std():.3f}")
print(f"  min={rho_df['rho'].min():.3f}, max={rho_df['rho'].max():.3f}")
print(f"  median={rho_df['rho'].median():.3f}")

# Significance
sig = rho_df[rho_df['p'] < 0.05]
print(f"  Significant (p<0.05): {len(sig)} ({len(sig)/len(rho_df)*100:.1f}%)")

# ============================================================
# 5. ρ vs θ — THE LASER BEAM TEST
# ============================================================
print("\n" + "="*60)
print("LASER BEAM: ρ vs θ FOR LANGUAGES")
print("="*60)

# Overall correlation
rho_theta_corr, p_theta = stats.spearmanr(rho_df['theta'], rho_df['rho'])
print(f"ρ vs θ: Spearman = {rho_theta_corr:.3f}, p={p_theta:.6f}")

# Binned analysis
bins = np.linspace(0, 1, 11)
bin_centers = (bins[:-1] + bins[1:]) / 2
bin_rhos = []
bin_ns = []
for i in range(len(bins)-1):
    mask = (rho_df['theta'] >= bins[i]) & (rho_df['theta'] < bins[i+1])
    sub = rho_df[mask]
    if len(sub) > 5:
        bin_rhos.append(sub['rho'].mean())
        bin_ns.append(len(sub))
    else:
        bin_rhos.append(np.nan)
        bin_ns.append(0)

print(f"\nρ by θ bin:")
print(f"{'θ range':15s} {'mean ρ':>8s} {'n':>6s}")
for i in range(len(bins)-1):
    print(f"{bins[i]:.1f}-{bins[i+1]:.1f}     {bin_rhos[i]:8.3f} {bin_ns[i]:6d}")

# Step function test: is there a sharp transition?
best_r2 = -np.inf
best_threshold = None
for t in np.arange(0.1, 0.9, 0.05):
    below = rho_df[rho_df['theta'] < t]['rho']
    above = rho_df[rho_df['theta'] >= t]['rho']
    if len(below) > 10 and len(above) > 10:
        predicted = np.where(rho_df['theta'].values < t, below.mean(), above.mean())
        ss_res = np.sum((rho_df['rho'].values - predicted)**2)
        ss_tot = np.sum((rho_df['rho'].values - rho_df['rho'].mean())**2)
        r2 = 1 - ss_res / ss_tot
        if r2 > best_r2:
            best_r2 = r2
            best_threshold = t

# Linear for comparison
slope_l, intercept_l, r_l, p_l, _ = stats.linregress(rho_df['theta'], rho_df['rho'])
print(f"\nStep function: θ*={best_threshold:.2f}, R²={best_r2:.3f}")
print(f"Linear: R²={r_l**2:.3f}, p={p_l:.6f}")

# ============================================================
# 6. WITHIN-LANGUAGE STEP FUNCTION (zero vs non-zero dependency)
# ============================================================
print("\n" + "="*60)
print("WITHIN-LANGUAGE STEP: zero vs non-zero feature dependency")
print("="*60)

# For each language, split features into zero and non-zero dependency
# and compare retention rates
step_results = []
for lang_id in matrix.index:
    lang_features = matrix.loc[lang_id].dropna()
    if len(lang_features) < 50:
        continue
    lang_dep = dep_df.set_index('feature').loc[lang_features.index]
    
    # Split at median dependency
    dep_median = lang_dep['dependency_score'].median()
    low_dep = lang_features[lang_dep['dependency_score'] <= dep_median]
    high_dep = lang_features[lang_dep['dependency_score'] > dep_median]
    
    if len(low_dep) > 0 and len(high_dep) > 0:
        step_results.append({
            'language_id': lang_id,
            'low_dep_retention': low_dep.mean(),
            'high_dep_retention': high_dep.mean(),
            'step_size': high_dep.mean() - low_dep.mean(),
            'theta': language_theta.get(lang_id, np.nan),
        })

step_df = pd.DataFrame(step_results)
print(f"Languages with step data: {len(step_df)}")
print(f"Mean step size: {step_df['step_size'].mean():.3f}")
print(f"  Low-dep retention: {step_df['low_dep_retention'].mean():.3f}")
print(f"  High-dep retention: {step_df['high_dep_retention'].mean():.3f}")
print(f"  Step: {step_df['high_dep_retention'].mean() - step_df['low_dep_retention'].mean():.3f}")

# ============================================================
# 7. PLOT
# ============================================================
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

# Panel 1: ρ vs θ scatter
ax = axes[0, 0]
# Color by macroarea
areas = rho_df.merge(languages[['ID', 'Macroarea']], left_on='language_id', right_on='ID')
area_colors = {'Eurasia': 'steelblue', 'Africa': 'orange', 'Papunesia': 'green',
               'NorthAmerica': 'red', 'SouthAmerica': 'purple', 'Australia': 'brown'}
for area, color in area_colors.items():
    mask = areas['Macroarea'] == area
    if mask.any():
        ax.scatter(areas.loc[mask, 'theta'], areas.loc[mask, 'rho'], c=color, s=20, alpha=0.5, label=area)
ax.set_xlabel('θ (linguistic niche dependency — 1 - features_present/max)')
ax.set_ylabel('ρ (feature dependency vs retention)')
ax.set_title(f'Language Laser Beam: ρ vs θ\nSpearman={rho_theta_corr:.3f}, p={p_theta:.6f}')
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

# Panel 2: Binned ρ vs θ
ax = axes[0, 1]
valid = ~np.isnan(bin_rhos)
ax.bar(bin_centers[valid], np.array(bin_rhos)[valid], width=0.08, color='steelblue', edgecolor='black')
ax.set_xlabel('θ (binned)')
ax.set_ylabel('Mean ρ')
ax.set_title(f'Binned ρ vs θ\nStep R²={best_r2:.3f}, Linear R²={r_l**2:.3f}')
ax.grid(True, alpha=0.3, axis='y')

# Panel 3: Step size distribution
ax = axes[1, 0]
ax.hist(step_df['step_size'], bins=50, color='steelblue', edgecolor='black')
ax.axvline(x=0, color='red', linestyle='--', alpha=0.5)
ax.set_xlabel('Step size (high-dep retention - low-dep retention)')
ax.set_ylabel('Number of languages')
ax.set_title(f'Within-Language Step\nMean step={step_df["step_size"].mean():.3f}')
ax.grid(True, alpha=0.3)

# Panel 4: Feature dependency distribution
ax = axes[1, 1]
ax.hist(dep_df['dependency_score'], bins=50, color='steelblue', edgecolor='black')
ax.set_xlabel('Feature dependency score (mean abs correlation)')
ax.set_ylabel('Number of features')
ax.set_title(f'Feature Dependency Distribution\n(n={len(dep_df)} features)')
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'language_laser_beam.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'language_laser_beam.png'}")

# Save results
results = {
    'n_languages': len(rho_df),
    'n_features': len(dep_df),
    'rho_vs_theta_spearman': float(rho_theta_corr),
    'rho_vs_theta_p': float(p_theta),
    'step_threshold': float(best_threshold),
    'step_r2': float(best_r2),
    'linear_r2': float(r_l**2),
    'mean_rho': float(rho_df['rho'].mean()),
    'mean_step_size': float(step_df['step_size'].mean()),
    'low_dep_retention': float(step_df['low_dep_retention'].mean()),
    'high_dep_retention': float(step_df['high_dep_retention'].mean()),
}
with open(OUTPUT_DIR / 'language_laser_beam_results.json', 'w') as f:
    json.dump(results, f, indent=2)
print(f"Saved: {OUTPUT_DIR / 'language_laser_beam_results.json'}")
