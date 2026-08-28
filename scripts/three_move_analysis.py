#!/usr/bin/env python3
"""
Three-Move Analysis: Ohta (inductive) + Fisher (decompositional) + Wimsatt (triangulation)
Goal: Arrive at the functional form of valence — the formula.

Move 1 (Ohta): Plot ρ vs θ across all systems. Let data reveal functional form.
Move 2 (Fisher): Partition Sodalis variance into valence + drift + hitchhiking + selection.
Move 3 (Wimsatt): Fit candidate functions, compare to monograph's predicted form.
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
# MOVE 1: OHTA — Plot ρ vs θ across all systems
# ============================================================

print("=" * 60)
print("MOVE 1: OHTA — Inductive plot of ρ vs θ")
print("=" * 60)

# --- System data points ---

# LTEE: free-living E. coli, θ ≈ 0, ρ ≈ 0
ltee_rho_fba = -0.039  # FBA full model
ltee_rho_composite = -0.006
ltee_rho_ppi = -0.028

# Sodalis: tsetse endosymbiont, θ moderate, ρ = 0.353
sodalis_rho_fba = 0.353
sodalis_rho_ltee_env = 0.267
sodalis_rho_composite = 0.248
sodalis_rho_ppi = 0.247

# Orobanchaceae: parasitic plants, θ high, ρ = 0.955 (from T6 PGLS analysis, phylogenetically corrected)
# Also compute from retention matrix for comparison
orobanch = pd.read_csv(WORKSPACE / "valence-foundry/data/orobanchaceae_retention_matrix.tsv", sep="\t")
# ρ across all gene categories within each species
orobanch_species = orobanch['species'].unique()
orobanch_rhos = {}
for sp in orobanch_species:
    sp_data = orobanch[orobanch['species'] == sp]
    rho, p = stats.spearmanr(sp_data['dependency_score'], sp_data['retention'])
    orobanch_rhos[sp] = (rho, p, sp_data['parasitism_score'].iloc[0])
    
print("\nOrobanchaceae per-species ρ (dependency vs retention):")
for sp, (rho, p, ps) in sorted(orobanch_rhos.items(), key=lambda x: x[1][2]):
    print(f"  {sp:15s}  parasitism_score={ps:.1f}  ρ={rho:.3f}  p={p:.4f}")

# Overall Orobanchaceae ρ (pooled, uncorrected)
oroban_rho_pooled, oroban_p_pooled = stats.spearmanr(orobanch['dependency_score'], orobanch['retention'])
# T6 PGLS ρ (phylogenetically corrected — the robust value)
oroban_rho_all = 0.955
oroban_p_all = 0.001  # from T6 analysis
print(f"\nOrobanchaceae pooled (uncorrected): ρ={oroban_rho_pooled:.3f}, p={oroban_p_pooled:.6f}")
print(f"Orobanchaceae T6 PGLS (corrected): ρ={oroban_rho_all:.3f}, p={oroban_p_all}")

# --- θ parameterization ---

# Ancestral genome size for Enterobacteriaceae (E. coli K-12): ~4.5 Mb
# θ = 1 - (genome_size / ancestral_size)
ANCESTOR_BP = 4_500_000

# Endosymbiont data
endo = pd.read_csv(WORKSPACE / "valence-foundry/data/endosymbiont_genome_data.tsv", sep="\t")
# Per-genus summary
genus_summary = endo.groupby('genus').agg(
    mean_genome_bp=('genome_bp', 'mean'),
    mean_aa_pathways=('aa_pathways_retained', 'mean'),
    n_species=('species', 'count'),
    min_genome_bp=('genome_bp', 'min'),
    max_genome_bp=('genome_bp', 'max'),
).reset_index()
genus_summary['theta_genome'] = 1 - (genus_summary['mean_genome_bp'] / ANCESTOR_BP)
genus_summary['theta_genome'] = genus_summary['theta_genome'].clip(0, 1)

print("\n\nEndosymbiont genus-level summary:")
print(f"{'Genus':15s} {'Mean bp':>10s} {'AA pathways':>12s} {'N':>4s} {'θ (genome)':>10s}")
for _, row in genus_summary.sort_values('theta_genome').iterrows():
    print(f"{row['genus']:15s} {row['mean_genome_bp']:10.0f} {row['mean_aa_pathways']:12.1f} {row['n_species']:4d} {row['theta_genome']:10.3f}")

# For endosymbionts: aa_pathways_retained as function of θ
# aa_pathways_retained is a retention metric (more = less reduction)
# θ = 1 - (genome/ancestor) is the dependency metric

# --- The ρ-θ data points ---

# Systems where we have ρ (dependency-retention Spearman):
# LTEE (θ≈0), Sodalis (θ=moderate), Orobanchaceae (θ=high)

# θ for Sodalis: genome 4.3 Mb vs ancestor 4.5 Mb → θ = 1 - 4.3/4.5 = 0.044
# But θ should measure niche dependency, not just genome reduction
# Sodalis has 51% coding capacity, 1183 pseudogenes — it's mid-reduction
# Let's use a composite θ: genome reduction + pseudogene fraction
sodalis_genome_bp = 4_300_000
sodalis_coding_fraction = 0.51
sodalis_pseudogene_count = 1183
sodalis_total_genes = 4979 + 1183  # CDS + pseudogenes
sodalis_pseudo_fraction = sodalis_pseudogene_count / sodalis_total_genes

# θ for Sodalis: use genome ratio + pseudogene fraction as composite
sodalis_theta_genome = 1 - (sodalis_genome_bp / ANCESTOR_BP)
# Better: use pseudogene fraction as proxy for niche dependency
# 0.19 (19% pseudogenes) → moderate θ
# Let's also compute θ from aa pathways if we can
# Sodalis doesn't have aa_pathways in the endosymbiont data
# Use genome ratio as primary, note it's conservative (Sodalis is early-stage)

# For Orobanchaceae: use parasitism_score normalized to 0-1
# parasitism_score ranges 0 (autotroph) to 4 (holoparasite)
orobanch_max_ps = 4.0

# Data points for ρ-θ plot
rho_theta_points = []

# LTEE
rho_theta_points.append({
    'system': 'LTEE (E. coli)',
    'theta': 0.0,
    'theta_source': 'free-living',
    'rho_fba': ltee_rho_fba,
    'rho_composite': ltee_rho_composite,
    'rho_ppi': ltee_rho_ppi,
})

# Sodalis — use genome-based θ
sodalis_theta = sodalis_theta_genome  # ≈ 0.044
# But this seems too low for a system with 51% coding and 1183 pseudogenes
# Alternative: use proportion of genes lost from ancestor
# E. coli K-12 has ~4300 CDS. Sodalis has 4979 CDS (intact) + 1183 pseudo
# The ancestor was likely ~5000-6000 genes. Sodalis has lost ~1183+ from an ancestor
# Let's use pseudogene fraction as θ proxy
sodalis_theta_alt = sodalis_pseudo_fraction  # 0.193

rho_theta_points.append({
    'system': 'Sodalis (tsetse)',
    'theta': sodalis_theta,
    'theta_alt': sodalis_theta_alt,
    'theta_source': 'genome_ratio',
    'rho_fba': sodalis_rho_fba,
    'rho_composite': sodalis_rho_composite,
    'rho_ppi': sodalis_rho_ppi,
})

# Orobanchaceae — use max parasitism_score species for the ρ
# The ρ=0.955 was computed across species at different parasitism levels
# For θ, use the average parasitism_score weighted by species
orobanch_theta = orobanch['parasitism_score'].mean() / orobanch_max_ps  # normalized
rho_theta_points.append({
    'system': 'Orobanchaceae (parasitic plants)',
    'theta': orobanch_theta,
    'theta_source': 'parasitism_score',
    'rho_fba': oroban_rho_all,
    'rho_composite': oroban_rho_all,  # same metric
    'rho_ppi': None,
})

print("\n\nρ-θ Data Points (Move 1):")
print(f"{'System':30s} {'θ':>8s} {'ρ(FBA)':>8s} {'ρ(comp)':>8s} {'ρ(PPI)':>8s}")
for pt in rho_theta_points:
    print(f"{pt['system']:30s} {pt['theta']:8.3f} {pt['rho_fba']:8.3f} {pt['rho_composite']:8.3f} {str(pt.get('rho_ppi','')):>8s}")

# Also add endosymbiont genus-level points using aa_pathways as retention
# For endosymbionts, θ = 1 - (genome/ancestor), retention = aa_pathways/20
print("\n\nEndosymbiont genus-level θ-retention (different metric, not ρ):")
print(f"{'Genus':15s} {'θ':>8s} {'AA retained':>11s} {'retention_ratio':>14s}")
for _, row in genus_summary.sort_values('theta_genome').iterrows():
    retention_ratio = row['mean_aa_pathways'] / 20.0  # 20 aa pathways in ancestor
    print(f"{row['genus']:15s} {row['theta_genome']:8.3f} {row['mean_aa_pathways']:11.1f} {retention_ratio:14.3f}")

# --- Plot 1a: ρ vs θ for systems with Spearman ρ ---
fig, ax = plt.subplots(1, 1, figsize=(8, 6))
thetas_rhopy = [pt['theta'] for pt in rho_theta_points]
rhos_fba = [pt['rho_fba'] for pt in rho_theta_points]
rhos_comp = [pt['rho_composite'] for pt in rho_theta_points]
labels = [pt['system'] for pt in rho_theta_points]

ax.scatter(thetas_rhopy, rhos_fba, s=150, c='steelblue', edgecolors='black', zorder=5, label='ρ (FBA)')
ax.scatter(thetas_rhopy, rhos_comp, s=150, c='coral', marker='s', edgecolors='black', zorder=5, label='ρ (composite)')

for i, label in enumerate(labels):
    offset_y = 0.02
    ax.annotate(label, (thetas_rhopy[i], rhos_fba[i]), 
                textcoords="offset points", xytext=(10, 10+offset_y*100), fontsize=9)

# Fit candidate functions
# We have 3 points — can fit linear, threshold, and try sigmoid
thetas_arr = np.array(thetas_rhopy)
rhos_arr = np.array(rhos_fba)

# Linear fit
slope, intercept, r_value, p_value, std_err = stats.linregress(thetas_arr, rhos_arr)
print(f"\n\nLinear fit (ρ vs θ): ρ = {slope:.3f}·θ + {intercept:.3f}, R²={r_value**2:.3f}, p={p_value:.4f}")

# Sigmoid fit (4-parameter logistic)
def sigmoid(x, a, b, c, d):
    """4PL: a=min, b=steepness, c=midpoint, d=max-a"""
    return a + d / (1 + np.exp(-b * (x - c)))

try:
    popt_sigmoid, _ = curve_fit(sigmoid, thetas_arr, rhos_arr, p0=[0, 10, 0.3, 1], maxfev=10000)
    sigmoid_y = sigmoid(thetas_arr, *popt_sigmoid)
    sigmoid_r2 = 1 - np.sum((rhos_arr - sigmoid_y)**2) / np.sum((rhos_arr - np.mean(rhos_arr))**2)
    print(f"Sigmoid fit: ρ = {popt_sigmoid[0]:.3f} + {popt_sigmoid[3]:.3f}/(1+exp(-{popt_sigmoid[1]:.1f}·(θ-{popt_sigmoid[2]:.3f}))), R²={sigmoid_r2:.3f}")
except Exception as e:
    print(f"Sigmoid fit failed: {e}")
    popt_sigmoid = None

# Power law fit
try:
    def powerlaw(x, a, b):
        """Power law: f(x) = a*(x + 1e-10)^b."""
        return a * np.power(x + 1e-10, b)
    popt_power, _ = curve_fit(powerlaw, thetas_arr, rhos_arr, p0=[1, 0.5], maxfev=10000)
    power_y = powerlaw(thetas_arr, *popt_power)
    power_r2 = 1 - np.sum((rhos_arr - power_y)**2) / np.sum((rhos_arr - np.mean(rhos_arr))**2)
    print(f"Power fit: ρ = {popt_power[0]:.3f}·θ^{popt_power[1]:.3f}, R²={power_r2:.3f}")
except Exception as e:
    print(f"Power fit failed: {e}")
    popt_power = None

# Threshold fit: ρ = 0 for θ < θ*, ρ = k·(θ-θ*) for θ ≥ θ*
try:
    def threshold(x, k, theta_star):
        """Threshold: f(x) = 0 for x < theta_star, k*(x-theta_star) for x >= theta_star."""
        return np.where(x < theta_star, 0, k * (x - theta_star))
    popt_thresh, _ = curve_fit(threshold, thetas_arr, rhos_arr, p0=[1, 0.05], maxfev=10000)
    thresh_y = threshold(thetas_arr, *popt_thresh)
    thresh_r2 = 1 - np.sum((rhos_arr - thresh_y)**2) / np.sum((rhos_arr - np.mean(rhos_arr))**2)
    print(f"Threshold fit: ρ = {popt_thresh[0]:.3f}·max(0, θ-{popt_thresh[1]:.3f}), R²={thresh_r2:.3f}")
except Exception as e:
    print(f"Threshold fit failed: {e}")
    popt_thresh = None

# Plot fits
theta_fine = np.linspace(0, 1, 200)
ax.plot(theta_fine, slope * theta_fine + intercept, 'b--', alpha=0.5, label=f'Linear (R²={r_value**2:.2f})')
if popt_sigmoid is not None:
    ax.plot(theta_fine, sigmoid(theta_fine, *popt_sigmoid), 'r-', alpha=0.5, label=f'Sigmoid (R²={sigmoid_r2:.2f})')
if popt_power is not None:
    ax.plot(theta_fine, powerlaw(theta_fine, *popt_power), 'g-.', alpha=0.5, label=f'Power (R²={power_r2:.2f})')
if popt_thresh is not None:
    ax.plot(theta_fine, threshold(theta_fine, *popt_thresh), 'm:', alpha=0.5, label=f'Threshold (R²={thresh_r2:.2f})')

ax.set_xlabel('θ (niche dependency parameter)', fontsize=12)
ax.set_ylabel('ρ (dependency-retention Spearman)', fontsize=12)
ax.set_title('Move 1 (Ohta): ρ vs θ — Does valence effect increase with niche dependency?', fontsize=13)
ax.legend(fontsize=9)
ax.set_xlim(-0.05, 1.0)
ax.set_ylim(-0.15, 1.1)
ax.axhline(y=0, color='gray', linestyle='-', alpha=0.3)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'move1_oha_rho_vs_theta.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'move1_oha_rho_vs_theta.png'}")

# --- Plot 1b: Endosymbiont genus-level θ vs retention (aa pathways) ---
fig, ax = plt.subplots(1, 1, figsize=(10, 6))
genus_thetas = genus_summary['theta_genome'].values
genus_retention = (genus_summary['mean_aa_pathways'] / 20.0).values  # normalize to 0-1
genus_names = genus_summary['genus'].values
genus_sizes = genus_summary['n_species'].values

# Scale point size by number of species
ax.scatter(genus_thetas, genus_retention, s=genus_sizes*20, c='steelblue', edgecolors='black', zorder=5)

for i, name in enumerate(genus_names):
    ax.annotate(f"{name}\n(n={genus_sizes[i]})", (genus_thetas[i], genus_retention[i]),
                textcoords="offset points", xytext=(8, 8), fontsize=8)

# Add LTEE point (θ=0, retention=1.0)
ax.scatter([0], [1.0], s=100, c='red', marker='*', edgecolors='black', zorder=5, label='LTEE (free-living)')

# Add Sodalis point (θ based on genome, retention based on coding fraction)
sodalis_theta_val = 1 - (4_300_000 / ANCESTOR_BP)
sodalis_retention_val = 0.51  # coding fraction
ax.scatter([sodalis_theta_val], [sodalis_retention_val], s=150, c='green', marker='D', edgecolors='black', zorder=5, label='Sodalis')

# Fit sigmoid to endosymbiont data
theta_endo = np.concatenate([[0, sodalis_theta_val], genus_thetas])
retention_endo = np.concatenate([[1.0, sodalis_retention_val], genus_retention])

try:
    # Constrain sigmoid to reasonable range
    from scipy.optimize import Bounds
    bounds_sig = Bounds([0, 0.1, 0.5, 0.1], [0.5, 50, 1.5, 1.0])
    popt_endo, _ = curve_fit(sigmoid, theta_endo, retention_endo, p0=[0.1, 5, 0.9, 0.9], bounds=bounds_sig, maxfev=20000)
    endo_fit = sigmoid(theta_fine, *popt_endo)
    endo_r2 = 1 - np.sum((retention_endo - sigmoid(theta_endo, *popt_endo))**2) / np.sum((retention_endo - np.mean(retention_endo))**2)
    ax.plot(theta_fine, endo_fit, 'r-', alpha=0.5, label=f'Sigmoid fit (R²={endo_r2:.3f})')
    print(f"\nEndosymbiont sigmoid: retention = {popt_endo[0]:.3f} + {popt_endo[3]:.3f}/(1+exp(-{popt_endo[1]:.1f}·(θ-{popt_endo[2]:.3f}))), R²={endo_r2:.3f}")
except Exception as e:
    print(f"Endosymbiont sigmoid fit failed: {e}")

# Linear for comparison
slope_e, intercept_e, r_e, p_e, _ = stats.linregress(theta_endo, retention_endo)
ax.plot(theta_fine, slope_e * theta_fine + intercept_e, 'b--', alpha=0.3, label=f'Linear (R²={r_e**2:.3f})')

ax.set_xlabel('θ = 1 - (genome_size / ancestral_size)', fontsize=12)
ax.set_ylabel('Retention (AA pathways / 20)', fontsize=12)
ax.set_title('Endosymbiont Genome Reduction: Retention vs θ (genus-level)', fontsize=13)
ax.legend(fontsize=9)
ax.set_xlim(-0.05, 1.05)
ax.set_ylim(-0.1, 1.15)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'move1b_endosymbiont_theta_retention.png', dpi=150)
print(f"Saved: {OUTPUT_DIR / 'move1b_endosymbiont_theta_retention.png'}")

# ============================================================
# MOVE 2: FISHER — Partition Sodalis variance
# ============================================================

print("\n\n" + "=" * 60)
print("MOVE 2: FISHER — Partition Sodalis retention variance")
print("=" * 60)

# Load Sodalis merged data
sodalis_genes = pd.read_csv(WORKSPACE / "valence-foundry/data/t7-ltee/t7_merged_analysis.tsv", sep="\t")
print(f"Sodalis merged data: {len(sodalis_genes)} genes")
print(f"Columns: {list(sodalis_genes.columns)}")

# We need the Sodalis-specific data (retention vs lost)
# The t7_merged_analysis.tsv has LTEE mutation data matched to iJO1366
# For Sodalis retention, we need the Sodalis classification
# Let's load the Sodalis gene lists
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_intact.txt") as f:
    intact_genes = set(line.strip() for line in f if line.strip())
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_absent.txt") as f:
    absent_genes = set(line.strip() for line in f if line.strip())
with open(WORKSPACE / "valence-foundry/data/t7-ltee/sodalis/iJO_pseudo.txt") as f:
    pseudo_genes = set(line.strip() for line in f if line.strip())

print(f"\nSodalis gene classification:")
print(f"  Intact (retained): {len(intact_genes)}")
print(f"  Absent (lost): {len(absent_genes)}")
print(f"  Pseudogene: {len(pseudo_genes)}")

# Load dependency scores
dep_scores = pd.read_csv(WORKSPACE / "valence-foundry/data/t7-ltee/gene_dependency_scores.tsv", sep="\t")
print(f"\nDependency scores: {len(dep_scores)} genes")

# Load STRING centrality
string_cent = pd.read_csv(WORKSPACE / "valence-foundry/data/t7-ltee/string_centrality.tsv", sep="\t")
print(f"STRING centrality: {len(string_cent)} genes")

# Build Sodalis dataframe: gene_id, dependency_score, centrality, retention
sodalis_df = dep_scores.copy()

# Add retention classification
def classify_retention(row, intact_set, absent_set, pseudo_set):
    """Classify gene as retained (1), lost (0), or unclassified (None)."""
    gid = row['gene_id']
    gname = row.get('name', '')
    # Check gene name first (Sodalis lists use names), then b-number
    if gname in intact_set or gid in intact_set:
        return 1  # retained
    elif gname in absent_set or gid in absent_set:
        return 0  # lost
    elif gname in pseudo_set or gid in pseudo_set:
        return 1  # pseudogenes with intact paralogs = retained
    else:
        return None  # unclassified

sodalis_df['retention'] = sodalis_df.apply(lambda r: classify_retention(r, intact_genes, absent_genes, pseudo_genes), axis=1)
sodalis_df = sodalis_df.dropna(subset=['retention'])
sodalis_df['retention'] = sodalis_df['retention'].astype(int)

# Merge with centrality if available
if 'gene_id' in string_cent.columns:
    # Try to merge
    string_cent_renamed = string_cent.rename(columns={string_cent.columns[0]: 'gene_id'})
    common_cols = list(set(sodalis_df.columns) & set(string_cent_renamed.columns))
    common_cols = [c for c in common_cols if c != 'gene_id']
    if common_cols:
        sodalis_df = sodalis_df.merge(string_cent_renamed[['gene_id'] + common_cols], on='gene_id', how='left')

print(f"\nSodalis analysis dataset: {len(sodalis_df)} genes")
print(f"  Retained: {sodalis_df['retention'].sum()} ({sodalis_df['retention'].mean()*100:.1f}%)")
print(f"  Lost: {(1-sodalis_df['retention']).sum()} ({(1-sodalis_df['retention']).mean()*100:.1f}%)")

# Partition variance in retention
# Component 1: valence (dependency score)
# Component 2: Essentiality (selection proxy)
# Component 3: Network centrality (integration proxy)
# Component 4: Random (unexplained)

from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

# valence component: dependency score
Valence_rho, valence_p = stats.spearmanr(sodalis_df['dependency_score'], sodalis_df['retention'])
print(f"\n--- Variance Partition ---")
print(f"valence component (dependency score): ρ={valence_rho:.3f}, p={valence_p:.6f}")

# Essentiality component
if 'essential' in sodalis_df.columns:
    # Handle essential column — direct comparison (Arrow string type)
    sodalis_df['ess_binary'] = (sodalis_df['essential'] == 'essential').astype(int)
    ess_rho, ess_p = stats.spearmanr(sodalis_df['ess_binary'], sodalis_df['retention'])
    print(f"Essentiality component: ρ={ess_rho:.3f}, p={ess_p:.6f}")
    
    # Odds ratio
    ess_retained = sodalis_df[sodalis_df['ess_binary']==1]['retention'].mean()
    noness_retained = sodalis_df[sodalis_df['ess_binary']==0]['retention'].mean()
    print(f"  Essential retention rate: {ess_retained:.3f}")
    print(f"  Nonessential retention rate: {noness_retained:.3f}")

# Logistic regression: decompose
# Model 1: valence only (dependency score)
# Model 2: Essentiality only
# Model 3: valence + Essentiality
# Compare AUC to see unique contribution

features = {}
if 'dependency_score' in sodalis_df.columns:
    features['valence'] = sodalis_df[['dependency_score']].fillna(0)
if 'ess_binary' in sodalis_df.columns:
    features['Ess'] = sodalis_df[['ess_binary']].fillna(0)
if 'dependency_score' in sodalis_df.columns and 'ess_binary' in sodalis_df.columns:
    features['valence+Ess'] = sodalis_df[['dependency_score', 'ess_binary']].fillna(0)

# Add centrality if available
cent_cols = [c for c in sodalis_df.columns if 'degree' in c.lower() or 'between' in c.lower() or 'eigen' in c.lower()]
if cent_cols:
    features['Centrality'] = sodalis_df[cent_cols].fillna(0)
    features['valence+Ess+Cent'] = sodalis_df[['dependency_score', 'ess_binary'] + cent_cols].fillna(0)

print(f"\nLogistic regression decomposition:")
print(f"{'Model':25s} {'AUC':>6s} {'ΔAUC':>6s}")
baseline_auc = 0.5
for name, X in features.items():
    try:
        y = sodalis_df['retention'].values
        if len(np.unique(y)) < 2:
            continue
        lr = LogisticRegression(max_iter=1000)
        lr.fit(X.values, y)
        y_pred = lr.predict_proba(X.values)[:, 1]
        auc = roc_auc_score(y, y_pred)
        print(f"{name:25s} {auc:6.3f} {auc-0.5:6.3f}")
    except Exception as e:
        print(f"{name:25s} FAILED: {e}")

# Fisher-style partition: ΔG = α·valence + β·drift + γ·hitchhiking + δ·selection
# In Sodalis:
# - Total retention rate = observed
# - valence component = what dependency score explains above baseline
# - Selection component = what essentiality explains above valence
# - Drift = baseline expectation (random loss)
# - Hitchhiking = residual after valence + selection (could be position effect)

total_retention = sodalis_df['retention'].mean()
# Random expectation: if loss is random, retention = fraction of genes retained
# Actually, the "drift" component is the baseline retention rate
# valence component: genes with high dependency (top quartile) should be retained more
q75 = sodalis_df['dependency_score'].quantile(0.75)
q25 = sodalis_df['dependency_score'].quantile(0.25)
high_dep_retention = sodalis_df[sodalis_df['dependency_score'] >= q75]['retention'].mean()
low_dep_retention = sodalis_df[sodalis_df['dependency_score'] <= q25]['retention'].mean()
Valence_effect = high_dep_retention - low_dep_retention

if 'ess_binary' in sodalis_df.columns:
    ess_retention = sodalis_df[sodalis_df['ess_binary']==1]['retention'].mean()
    noness_retention = sodalis_df[sodalis_df['ess_binary']==0]['retention'].mean()
    selection_effect = ess_retention - noness_retention
else:
    selection_effect = None

print(f"\n--- Fisher Partition (effect sizes) ---")
print(f"Total retention rate: {total_retention:.3f}")
print(f"valence effect (high-dep minus low-dep retention): {valence_effect:.3f}")
if selection_effect is not None:
    print(f"Selection effect (ess minus noness retention): {selection_effect:.3f}")
print(f"Drift baseline: {total_retention:.3f} (random expectation)")
print(f"Residual (hitchhiking + unexplained): {total_retention - valence_effect - (selection_effect or 0):.3f}")

# --- Plot 2: Retention by dependency quintile with partition ---
fig, ax = plt.subplots(1, 1, figsize=(8, 6))
sodalis_df['dep_bin'] = pd.cut(sodalis_df['dependency_score'], bins=[-0.01, 0.01, 0.5, 1.01], labels=['Low (≤0.01)','Mid (0.01-0.5)','High (≥0.5)'])
quintile_retention = sodalis_df.groupby('dep_bin', observed=True)['retention'].agg(['mean', 'count'])
n_bins = len(quintile_retention)

print(f"\nRetention by dependency bin:")
print(quintile_retention)

ax.bar(range(n_bins), quintile_retention['mean'], color='steelblue', edgecolor='black')
ax.axhline(y=total_retention, color='red', linestyle='--', label=f'Baseline ({total_retention:.3f})')
ax.set_xlabel('Dependency Score Bin', fontsize=12)
ax.set_ylabel('Retention Rate', fontsize=12)
ax.set_title('Move 2 (Fisher): Sodalis Retention by Dependency Level\nVI effect = High - Low', fontsize=13)
ax.set_xticks(range(n_bins))
ax.set_xticklabels(quintile_retention.index)
for i, (mean, count) in enumerate(zip(quintile_retention['mean'], quintile_retention['count'])):
    ax.text(i, mean + 0.01, f'{mean:.2f}\n(n={count})', ha='center', fontsize=9)
ax.legend()
ax.grid(True, alpha=0.3, axis='y')
plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'move2_fisher_sodalis_partition.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'move2_fisher_sodalis_partition.png'}")

# ============================================================
# MOVE 3: WIMSATT — Compare empirical fit to monograph theory
# ============================================================

print("\n\n" + "=" * 60)
print("MOVE 3: WIMSATT — Triangulation: empirical fit vs theory")
print("=" * 60)

# Monograph's proposed forms:
# 1. Rate function: dC/dt = -k·M·f(I(C)) 
#    where M = niche-demand mismatch, I(C) = mean integration depth
# 2. Substrate-shift: α(x) = -k_ecol + k_cult · σ((x - x*)/s)
# 3. Cusp catastrophe for irreversibility: S = f(a, b)
# 4. Autocatalytic closure (Kauffman)

# The key comparison: does ρ vs θ follow a sigmoid with threshold structure?
# Monograph predicts: effect goes from ~0 (ecological) to strong (cultural/symbiotic)
# The substrate-shift equation α(x) = -k_ecol + k_cult·σ((x-x*)/s) predicts:
# - Near-zero effect at low θ (ecological regime)
# - Threshold crossing at θ*
# - Saturation at high θ (cultural/symbiotic regime)

print("\nMonograph predicted form: α(x) = -k_ecol + k_cult · σ((x - x*)/s)")
print("Where σ is sigmoid, x is substrate type, x* is threshold")
print()

# With 3 ρ-θ points, let's see what we can infer:
print("Empirical data (ρ vs θ):")
for pt in rho_theta_points:
    print(f"  {pt['system']:30s}  θ={pt['theta']:.3f}  ρ={pt['rho_fba']:.3f}")

print(f"\nLinear fit: ρ = {slope:.3f}·θ + {intercept:.3f}")
print(f"  R² = {r_value**2:.3f}")
print(f"  Interpretation: {'monotonic increase' if slope > 0 and p_value < 0.1 else 'no clear signal'}")

if popt_sigmoid is not None:
    print(f"\nSigmoid fit parameters:")
    print(f"  floor (min): {popt_sigmoid[0]:.3f}")
    print(f"  steepness: {popt_sigmoid[1]:.3f}")
    print(f"  threshold θ*: {popt_sigmoid[2]:.3f}")
    print(f"  amplitude: {popt_sigmoid[3]:.3f}")
    print(f"  R² = {sigmoid_r2:.3f}")
    print(f"  → If θ* ≈ {popt_sigmoid[2]:.3f}, this is the niche-dependency threshold")
    print(f"  → Monograph's x* maps to this θ*")

# --- Endosymbiont data: more points for Wimsatt ---
print("\n\nEndosymbiont genus-level (retention vs θ, 11+ points):")
# Fit sigmoid to endosymbiont data
try:
    print(f"  Sigmoid: retention = {popt_endo[0]:.3f} + {popt_endo[3]:.3f}/(1+exp(-{popt_endo[1]:.1f}·(θ-{popt_endo[2]:.3f})))")
    print(f"  R² = {endo_r2:.3f}")
    print(f"  Threshold θ* = {popt_endo[2]:.3f}")
    print(f"  Steepness = {popt_endo[1]:.1f}")
except:
    print("  Sigmoid fit not available")

# --- Attractor theory connection ---
print("\n\n" + "=" * 60)
print("PHYSICS ATTRACTOR INTERPRETATION")
print("=" * 60)

print("""
Jan's hunch: chemistry-physics attractor theory (magnetism/electricity).

The monograph already contains physics-style formalisms:
1. Cusp catastrophe (Thom/Zeeman) — bifurcation theory for irreversibility
2. Autocatalytic closure (Kauffman) — phase transition to self-sustaining set
3. Rate function dC/dt = -k·M·f(I(C)) — dynamical system

The attractor interpretation:
- At θ≈0 (free-living): attractor = full genome. Basin is wide, deep.
- At θ≈1 (maximal dependency): attractor = minimal genome. Basin dominates.
- At θ* (threshold): bifurcation — attractor landscape changes shape.
- The sigmoid ρ(θ) IS the crossover between attractor basins.

This is structurally identical to:
- Landau free energy: F(x) = a·x² + b·x⁴ — double-well potential
  → order parameter m transitions at critical temperature Tc
  → sigmoid magnetization M(T) below Curie point
- Ising model: spin alignment as function of coupling strength J
  → M = tanh(J·H/T) — sigmoid response to field
- Dielectric polarization: P = P_sat · tanh(E/E_c) — sigmoid response

If the empirical ρ(θ) is sigmoidal with threshold θ*:
  ρ(θ) = ρ_max / (1 + exp(-s·(θ - θ*)))
  
This IS the physics attractor form. The "magnetism" Jan intuited is the
order-parameter transition: below θ* the system is in the "disordered" 
(valence doesn't discriminate, ρ≈0) state; above θ* it's in the "ordered"
(valence discriminates, ρ→ρ_max) state. The steepness s measures how sharp
the phase transition is.

The monograph's α(x) = -k_ecol + k_cult·σ((x-x*)/s) has the SAME structure:
- k_ecol = negative baseline (ecological regime, valence absent)
- k_cult = positive amplitude (cultural regime, valence present)  
- σ = sigmoid gate (phase transition)
- x* = critical point (Curie temperature analog)
- s = steepness (cooperativity parameter)
""")

# --- Summary plot: all three moves ---
fig, axes = plt.subplots(1, 3, figsize=(18, 5))

# Panel 1: Move 1 — ρ vs θ
ax1 = axes[0]
ax1.scatter(thetas_arr, rhos_arr, s=150, c=['red','green','blue'], edgecolors='black', zorder=5)
labels_short = ['LTEE\n(θ≈0)', 'Sodalis\n(θ≈0.04)', 'Orobanchaceae\n(θ≈0.47)']
for i, label in enumerate(labels_short):
    ax1.annotate(label, (thetas_arr[i], rhos_arr[i]), textcoords="offset points", xytext=(10, -15), fontsize=8)
ax1.plot(theta_fine, slope * theta_fine + intercept, 'b--', alpha=0.5, label=f'Linear R²={r_value**2:.2f}')
if popt_sigmoid is not None:
    ax1.plot(theta_fine, sigmoid(theta_fine, *popt_sigmoid), 'r-', alpha=0.5, label=f'Sigmoid R²={sigmoid_r2:.2f}')
ax1.set_xlabel('θ (niche dependency)')
ax1.set_ylabel('ρ (valence effect)')
ax1.set_title('Move 1 (Ohta): ρ vs θ')
ax1.legend(fontsize=8)
ax1.grid(True, alpha=0.3)

# Panel 2: Move 2 — Sodalis quintile
ax2 = axes[1]
ax2.bar(range(n_bins), quintile_retention['mean'], color='steelblue', edgecolor='black')
ax2.axhline(y=total_retention, color='red', linestyle='--', label=f'Baseline {total_retention:.2f}')
ax2.set_xlabel('Dependency Bin')
ax2.set_ylabel('Retention Rate')
ax2.set_title('Move 2 (Fisher): Sodalis\nVI effect partition')
ax2.set_xticks(range(n_bins))
ax2.set_xticklabels(quintile_retention.index, fontsize=7)
ax2.legend(fontsize=8)
ax2.grid(True, alpha=0.3, axis='y')

# Panel 3: Move 3 — Endosymbiont θ vs retention with sigmoid fit
ax3 = axes[2]
ax3.scatter(theta_endo, retention_endo, s=50, c='steelblue', edgecolors='black', zorder=5)
ax3.scatter([0], [1.0], s=100, c='red', marker='*', edgecolors='black', zorder=5)
if popt_endo is not None:
    ax3.plot(theta_fine, sigmoid(theta_fine, *popt_endo), 'r-', alpha=0.5, label=f'Sigmoid R²={endo_r2:.2f}')
ax3.set_xlabel('θ (genome reduction)')
ax3.set_ylabel('Retention (AA/20)')
ax3.set_title('Move 3 (Wimsatt): Endosymbionts\nTheory-data convergence')
ax3.legend(fontsize=8)
ax3.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'three_move_summary.png', dpi=150)
print(f"\nSaved: {OUTPUT_DIR / 'three_move_summary.png'}")

# Save numerical results
results = {
    'move1_ohta': {
        'rho_theta_points': rho_theta_points,
        'linear_fit': {'slope': slope, 'intercept': intercept, 'r_squared': r_value**2, 'p': p_value},
        'sigmoid_fit': {'params': list(popt_sigmoid) if popt_sigmoid is not None else None, 'r_squared': sigmoid_r2 if popt_sigmoid is not None else None},
        'power_fit': {'params': list(popt_power) if popt_power is not None else None, 'r_squared': power_r2 if popt_power is not None else None},
        'threshold_fit': {'params': list(popt_thresh) if popt_thresh is not None else None, 'r_squared': thresh_r2 if popt_thresh is not None else None},
        'endosymbiont_sigmoid': {'params': list(popt_endo) if popt_endo is not None else None, 'r_squared': endo_r2 if popt_endo is not None else None},
    },
    'move2_fisher': {
        'total_retention': total_retention,
        'valence_effect': valence_effect,
        'selection_effect': selection_effect,
        'quintile_retention': quintile_retention.to_dict(),
    },
    'move3_wimsatt': {
        'monograph_form': 'α(x) = -k_ecol + k_cult · σ((x - x*)/s)',
        'empirical_sigmoid': {'threshold_theta_star': popt_sigmoid[2] if popt_sigmoid else None, 'steepness': popt_sigmoid[1] if popt_sigmoid else None},
        'endosymbiont_threshold': float(popt_endo[2]) if popt_endo is not None else None,
    }
}

with open(OUTPUT_DIR / 'three_move_results.json', 'w') as f:
    json.dump(results, f, indent=2, default=str)
print(f"\nSaved: {OUTPUT_DIR / 'three_move_results.json'}")

print("\n\n" + "=" * 60)
print("ANALYSIS COMPLETE")
print("=" * 60)
