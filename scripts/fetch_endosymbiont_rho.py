#!/usr/bin/env python3
"""
Fetch endosymbiont genomes from NCBI, extract gene names, and compute
Spearman rho between iJO1366 dependency scores and gene retention.

Usage: uv run python scripts/fetch_endosymbiont_rho.py
"""

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from collections.abc import Iterator
from pathlib import Path

import numpy as np
from scipy.stats import spearmanr

# ── Config ──────────────────────────────────────────────────────────────────
EMAIL = "flow@ind.media"
TOOL = "openclaw"
BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
DELAY = 0.5  # seconds between batches

GENERA = [
    "Hodgkinia",
    "Sulcia",
    "Tremblaya",
    "Portiera",
    "Baumannia",
    "Blochmannia",
    "Wigglesworthia",
    "Nasuia",
]

DATA_DIR = Path("/home/node/.openclaw/workspace/valence-foundry/data")
DEP_SCORES = DATA_DIR / "t7-ltee" / "gene_dependency_scores.tsv"

# ── NCBI helpers ────────────────────────────────────────────────────────────


def ncbi_request(params: dict, retries: int = 3) -> str:
    """Make an NCBI EUtils request with retries and polite delay."""
    params["email"] = EMAIL
    params["tool"] = TOOL
    url = BASE + "/" + params.pop("endpoint", "esearch.fcgi")
    url += "?" + urllib.parse.urlencode(params)
    for attempt in range(1, retries + 1):
        try:
            with urllib.request.urlopen(url, timeout=30) as resp:
                return resp.read().decode("utf-8")
        except (urllib.error.URLError, urllib.error.HTTPError) as exc:
            if attempt < retries:
                time.sleep(2**attempt)
            else:
                raise RuntimeError(f"NCBI request failed after {retries} attempts: {exc}") from exc


def esearch_count(genus: str) -> int:
    """Get total protein count for genus in RefSeq."""
    xml = ncbi_request({
        "endpoint": "esearch.fcgi",
        "db": "protein",
        "term": f"{genus}[organism] AND refseq[filter]",
        "retmax": "0",
        "retmode": "xml",
    })
    root = ET.fromstring(xml)
    count_el = root.find(".//Count")
    return int(count_el.text) if count_el is not None else 0


def esearch_ids(genus: str, retmax: int = 500) -> list[str]:
    """Get up to *retmax* protein GI/UIDs for a genus."""
    xml = ncbi_request({
        "endpoint": "esearch.fcgi",
        "db": "protein",
        "term": f"{genus}[organism] AND refseq[filter]",
        "retmax": str(retmax),
        "retmode": "xml",
    })
    root = ET.fromstring(xml)
    return [id_el.text for id_el in root.findall(".//IdList/Id") if id_el.text]


def efetch_batch(ids: list[str]) -> str:
    """Fetch GenBank XML for a batch of up to 100 protein IDs."""
    xml = ncbi_request({
        "endpoint": "efetch.fcgi",
        "db": "protein",
        "id": ",".join(ids),
        "rettype": "gb",
        "retmode": "xml",
    })
    return xml


def extract_gene_names_from_gb_xml(xml: str) -> set[str]:
    """
    Parse GenBank XML and extract gene names from GBFeature gene qualifiers.
    Returns a set of lowercased gene names.
    """
    genes: set[str] = set()
    root = ET.fromstring(xml)
    # GBSeq entries
    for gbseq in root.findall(".//GBSeq"):
        for gbqual in gbseq.findall(".//GBQualifier"):
            qual_name = gbqual.findtext("GBQualifier_name", "")
            qual_val = gbqual.findtext("GBQualifier_value", "")
            if qual_name == "gene" and qual_val.strip():
                # Normalise: lowercase, strip whitespace
                genes.add(qual_val.strip().lower())
    return genes


def fetch_all_genes(genus: str) -> set[str]:
    """Fetch all gene names for a genus from NCBI (up to 500 records)."""
    ids = esearch_ids(genus, retmax=500)
    if not ids:
        print(f"  ⚠ No IDs found for {genus}")
        return set()

    all_genes: set[str] = set()
    # Batch in chunks of 100
    for i in range(0, len(ids), 100):
        batch = ids[i : i + 100]
        print(f"  Fetching batch {i // 100 + 1}/{(len(ids) + 99) // 100} ({len(batch)} ids)...")
        xml = efetch_batch(batch)
        genes = extract_gene_names_from_gb_xml(xml)
        all_genes.update(genes)
        time.sleep(DELAY)  # polite delay between batches

    return all_genes


# ── Dependency scores ───────────────────────────────────────────────────────


def load_dependency_scores(path: Path) -> list[dict]:
    """Load the iJO1366 dependency scores TSV."""
    records: list[dict] = []
    with open(path) as f:
        header = f.readline().strip().split("\t")
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) < 4:
                continue
            rec = dict(zip(header, parts))
            try:
                rec["dependency_score"] = float(rec["dependency_score"])
            except (ValueError, KeyError):
                rec["dependency_score"] = float("nan")
            records.append(rec)
    return records


# ── Rho computation ─────────────────────────────────────────────────────────


def compute_rho(
    dependency_records: list[dict],
    retained_genes: set[str],
) -> dict:
    """
    Compute Spearman rho between dependency_score and retention_binary.
    retention=1 if gene name (lowered) is in retained_genes, else 0.
    Returns dict with rho, p-value, n (total genes), n_retained.
    """
    dep_scores: list[float] = []
    retention: list[int] = []
    n_retained = 0
    n_total = 0

    for rec in dependency_records:
        name = rec.get("name", "").strip().lower()
        if not name:
            continue
        score = rec.get("dependency_score")
        if score is None or np.isnan(score):
            continue
        retained = 1 if name in retained_genes else 0
        dep_scores.append(score)
        retention.append(retained)
        n_retained += retained
        n_total += 1

    if len(dep_scores) < 3:
        return {
            "rho": None,
            "p": None,
            "n_total": n_total,
            "n_retained": n_retained,
            "error": "Too few records for correlation",
        }

    rho, p = spearmanr(dep_scores, retention)
    return {
        "rho": round(float(rho), 6),
        "p": round(float(p), 6),
        "n_total": n_total,
        "n_retained": n_retained,
    }


# ── Main ────────────────────────────────────────────────────────────────────


def main():
    print("=" * 60)
    print("iJO1366 Endosymbiont ρ Analysis")
    print("=" * 60)

    # Load dependency scores
    print("\n📄 Loading dependency scores...")
    dep_records = load_dependency_scores(DEP_SCORES)
    print(f"   Loaded {len(dep_records)} records from {DEP_SCORES.name}")

    results = []

    for genus in GENERA:
        print(f"\n{'─' * 50}")
        print(f"🔬 {genus}")
        print(f"{'─' * 50}")

        genus_lower = genus.lower()

        # Count total proteins
        print(f"  Counting RefSeq proteins...")
        try:
            count = esearch_count(genus)
            print(f"  Total RefSeq proteins: {count}")
        except Exception as exc:
            print(f"  ⚠ Count failed: {exc}")
            count = 0

        # Fetch gene names
        print(f"  Fetching gene names...")
        try:
            genes = fetch_all_genes(genus)
            print(f"  Retrieved {len(genes)} unique gene names")
        except Exception as exc:
            print(f"  ⚠ Fetch failed: {exc}")
            genes = set()

        # Save gene list
        gene_list_path = DATA_DIR / f"{genus_lower}_gene_list.txt"
        with open(gene_list_path, "w") as f:
            for g in sorted(genes):
                f.write(g + "\n")
        print(f"  💾 Gene list saved: {gene_list_path.name}")

        # Compute rho
        print(f"  Computing ρ...")
        rho_result = compute_rho(dep_records, genes)
        print(f"  ρ = {rho_result.get('rho')}, p = {rho_result.get('p')}")
        print(f"  n = {rho_result.get('n_total')}, retained = {rho_result.get('n_retained')}")

        # Save rho result
        rho_path = DATA_DIR / f"{genus_lower}_rho_result.json"
        with open(rho_path, "w") as f:
            json.dump(
                {
                    "genus": genus,
                    "theta_aa": count,
                    "theta_genome": count,  # placeholder — same as protein count for now
                    "rho": rho_result.get("rho"),
                    "p": rho_result.get("p"),
                    "n_retained": rho_result.get("n_retained"),
                    "n_total": rho_result.get("n_total"),
                    "n_genes_found": len(genes),
                },
                f,
                indent=2,
            )
        print(f"  💾 ρ result saved: {rho_path.name}")

        results.append(
            {
                "genus": genus,
                "theta_aa": count,
                "theta_genome": count,
                "rho": rho_result.get("rho"),
                "p": rho_result.get("p"),
                "n_retained": rho_result.get("n_retained"),
                "n_total": rho_result.get("n_total"),
            }
        )

    # ── Summary table ───────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("📊 SUMMARY TABLE")
    print("=" * 60)
    print(f"{'Genus':<18} {'θ_aa':>10} {'θ_genome':>10} {'ρ':>10} {'p':>12} {'n_ret':>8} {'n_total':>8}")
    print("-" * 76)
    for r in results:
        rho_str = f"{r['rho']:.6f}" if r["rho"] is not None else "N/A"
        p_str = f"{r['p']:.6f}" if r["p"] is not None else "N/A"
        print(
            f"{r['genus']:<18} {r['theta_aa']:>10} {r['theta_genome']:>10} {rho_str:>10} {p_str:>12} "
            f"{r['n_retained']:>8} {r['n_total']:>8}"
        )
    print("=" * 60)

    # Save combined results
    combined_path = DATA_DIR / "endosymbiont_rho_results.json"
    with open(combined_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\n💾 Combined results saved: {combined_path.name}")
    print("✅ Done.")


if __name__ == "__main__":
    main()