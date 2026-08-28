#!/usr/bin/env python3
"""
Fetch Buchnera aphidicola APS protein records from NCBI,
extract gene names, match to iJO1366, compute ρ.
"""
import urllib.request
import xml.etree.ElementTree as ET
import time
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy import stats

WORKSPACE = Path("/home/node/.openclaw/workspace")

# Step 1: Search for all Buchnera APS proteins
search_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=protein&term=Buchnera+aphidicola+APS+refseq&retmax=1000&tool=openclaw&email=flow@ind.media"
print("Searching NCBI for Buchnera APS proteins...")
with urllib.request.urlopen(search_url) as resp:
    search_xml = resp.read()
root = ET.fromstring(search_xml)
ids = [id_elem.text for id_elem in root.findall('.//Id')]
print(f"Found {len(ids)} protein IDs")

# Step 2: Fetch protein records in batches, extract gene names
all_genes = []
batch_size = 100
for i in range(0, len(ids), batch_size):
    batch_ids = ids[i:i+batch_size]
    id_str = ",".join(batch_ids)
    fetch_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={id_str}&rettype=gb&retmode=xml&tool=openclaw&email=flow@ind.media"
    print(f"  Fetching batch {i//batch_size + 1}/{(len(ids)-1)//batch_size + 1}...")
    with urllib.request.urlopen(fetch_url, timeout=30) as resp:
        fetch_xml = resp.read()
    
    root = ET.fromstring(fetch_xml)
    for seq in root.findall('.//GBSeq'):
        accession = seq.findtext('GBSeq_primary-accession', '')
        definition = seq.findtext('GBSeq_definition', '')
        # Extract gene name from features
        gene_name = None
        for feat in seq.findall('.//GBFeature'):
            fkey = feat.findtext('GBFeature_key', '')
            if fkey == 'gene':
                for qual in feat.findall('.//GBQualifier'):
                    if qual.findtext('GBQualifier_name') == 'gene':
                        gene_name = qual.findtext('GBQualifier_value')
                        break
            if fkey == 'CDS' and gene_name is None:
                for qual in feat.findall('.//GBQualifier'):
                    if qual.findtext('GBQualifier_name') == 'gene':
                        gene_name = qual.findtext('GBQualifier_value')
                        break
        
        if gene_name:
            all_genes.append({
                'accession': accession,
                'gene': gene_name,
                'definition': definition,
            })
    
    time.sleep(0.5)  # rate limit

print(f"\nExtracted {len(all_genes)} gene names")
buchnera_genes = set(g['gene'] for g in all_genes)
print(f"Unique gene names: {len(buchnera_genes)}")
print(f"Sample: {list(buchnera_genes)[:20]}")

# Save gene list
with open(WORKSPACE / "valence-foundry/data/buchnera_gene_list.txt", 'w') as f:
    for g in sorted(buchnera_genes):
        f.write(g + "\n")

# Step 3: Load iJO1366 dependency scores
dep_scores = pd.read_csv(WORKSPACE / "valence-foundry/data/t7-ltee/gene_dependency_scores.tsv", sep="\t")
print(f"\niJO1366 dependency scores: {len(dep_scores)} genes")

# Step 4: Match Buchnera genes to iJO1366
# The dep_scores has 'name' column with gene names (e.g., 'cysE')
buchnera_genes_iJO = dep_scores[dep_scores['name'].isin(buchnera_genes)].copy()
buchnera_absent_iJO = dep_scores[~dep_scores['name'].isin(buchnera_genes)].copy()
print(f"Matched to iJO1366: {len(buchnera_genes_iJO)} retained, {len(buchnera_absent_iJO)} absent/lost")

# Step 5: Compute ρ
dep_scores['retention'] = 0
dep_scores.loc[dep_scores['name'].isin(buchnera_genes), 'retention'] = 1

matched = dep_scores[dep_scores['name'].isin(buchnera_genes) | ~dep_scores['name'].isin(buchnera_genes)].copy()
rho, p = stats.spearmanr(matched['dependency_score'], matched['retention'])
print(f"\nBuchnera ρ (Spearman dependency vs retention): {rho:.3f}, p={p:.6f}")

# Also compute for essential vs nonessential
ess = matched[matched['essential'] == 'essential']
noness = matched[matched['essential'] == 'nonessential']
print(f"Essential retention: {ess['retention'].mean():.3f} ({ess['retention'].sum()}/{len(ess)})")
print(f"Nonessential retention: {noness['retention'].mean():.3f} ({noness['retention'].sum()}/{len(noness)})")

# Retention by dependency bin
for label, mask in [('Low (≤0.01)', matched['dependency_score'] <= 0.01),
                     ('Mid (0.01-0.5)', (matched['dependency_score'] > 0.01) & (matched['dependency_score'] < 0.5)),
                     ('High (≥0.5)', matched['dependency_score'] >= 0.5)]:
    sub = matched[mask]
    print(f"  {label}: retention={sub['retention'].mean():.3f} (n={len(sub)})")

# θ for Buchnera
theta_aa = 1 - (10 / 20)  # 10/20 aa pathways retained → θ = 0.50
theta_genome = 1 - (641802 / 4_500_000)  # genome ratio → θ = 0.857
print(f"\nθ (aa pathways): {theta_aa:.3f}")
print(f"θ (genome ratio): {theta_genome:.3f}")

# Save results
result = {
    'system': 'Buchnera (aphid endosymbiont)',
    'theta_aa': theta_aa,
    'theta_genome': theta_genome,
    'rho': float(rho),
    'rho_p': float(p),
    'n_retained': int(buchnera_genes_iJO.shape[0]),
    'n_lost': int(buchnera_absent_iJO.shape[0]),
    'n_total': int(len(matched)),
    'essential_retention': float(ess['retention'].mean()),
    'nonessential_retention': float(noness['retention'].mean()),
}
print(f"\nResult: {json.dumps(result, indent=2)}")

with open(WORKSPACE / "valence-foundry/data/buchnera_rho_result.json", 'w') as f:
    json.dump(result, f, indent=2)
