#!/usr/bin/env python3
"""
Reciprocal best-hit BLAST orthology for endosymbiont genomes.

Replaces gene-name matching (which fails at extreme genome reduction) with
reciprocal best-hit blastp against E. coli K-12 MG1655 (NC_000913.3).

For each endosymbiont genus:
  1. Fetch reference proteome from NCBI (RefSeq assembly, via Datasets API)
  2. blastp: endosymbiont proteome -> E. coli MG1655 proteins (query DB)
  3. blastp: E. coli iJO1366 gene set -> endosymbiont proteome (reciprocal)
  4. Ortholog = reciprocal best hit (e-value < 1e-5 both directions)
  5. Gene retained = has ortholog in the endosymbiont genome
  6. rho = Spearman(dependency_score, retained) over iJO1366 genes

Outputs:
  data/blast_orthology/blast_orthology_results.json   — per-genus rho
  data/blast_orthology/<genus>_retention.tsv          — gene-level retention
  data/blast_orthology/summary.tsv                    — full comparison table
"""

from __future__ import annotations

import io
import json
import os
import subprocess
import sys
import time
import urllib.request
import zipfile
from pathlib import Path

import numpy as np
from scipy.stats import spearmanr

# ── Config ──────────────────────────────────────────────────────────────────
EMAIL = "flow@ind.media"
TOOL = "openclaw"
BLAST_BIN = Path(os.environ.get("BLAST_BIN", "/tmp/ncbi-blast-2.16.0+/bin"))
WORK = Path(os.environ.get("BLAST_WORK", "/tmp/ncbi_blast"))
foundry = Path("/home/node/.openclaw/workspace/valence-foundry")
DATA_DIR = foundry / "data" / "blast_orthology"
DEP_SCORES = foundry / "data" / "t7-ltee" / "gene_dependency_scores.tsv"
IJO_GENES = foundry / "data" / "t7-ltee" / "sodalis" / "ecoli_gene_names.txt"
GBK = WORK / "ecoli_mg1655.gbk"
ECOLI_FASTA = WORK / "ecoli_mg1655_proteins.faa"
ECOLI_DB = WORK / "ecoli_mg1655_db"
IJO_FASTA = WORK / "ijo1366_proteins.faa"
EVALUE_CUTOFF = 1e-5
MIN_COVERAGE = 0.5  # alignment length / query length

# Genus -> RefSeq assembly accession (representative reference genome)
GENOMES = {
    "Buchnera": "GCF_000009605.1",      # Buchnera aphidicola APS
    "Sodalis": "GCF_000287795.1",       # Sodalis glossinidius morsitans
    "Wigglesworthia": "GCF_000010245.1",  # Wigglesworthia glossinidia
    "Blochmannia": "GCF_000010505.1",   # Blochmannia floridanus
    "Carsonella": "GCF_000009445.1",    # Carsonella ruddii PV
    "Hodgkinia": "GCF_000278815.2",     # Hodgkinia cicadicola
    "Tremblaya": "GCF_000194075.1",     # Tremblaya princeps
    "Portiera": "GCF_000271165.1",      # Portiera aleyrodidarum
    "Baumannia": "GCF_000020325.1",     # Baumannia cicadellinicola
    "Sulcia": "GCF_000020385.1",        # Sulcia muelleri
    "Nasuia": "GCF_000422645.1",        # Nasuia deltocephalinicola
}

# ── E. coli reference ───────────────────────────────────────────────────────


def parse_genbank_proteins(gbk_path: Path):
    """Extract {gene_name: (protein_id, translation)} from GenBank CDS features."""
    text = gbk_path.read_text()
    genes = {}
    # Split into features; simple scanner for CDS blocks
    for block in text.split("\n     CDS"):
        if "/translation=" not in block:
            continue
        gene = None
        prot_id = None
        trans_parts = []
        in_trans = False
        for line in block.split("\n"):
            s = line.strip()
            if s.startswith('/gene="'):
                gene = s.split('"')[1]
            elif s.startswith('/protein_id="'):
                prot_id = s.split('"')[1]
            elif s.startswith("/translation="):
                in_trans = True
                trans_parts.append(s.split('"')[1] if '"' in s else "")
            elif in_trans:
                if '"' in s:
                    trans_parts.append(s.split('"')[0])
                    in_trans = False
                else:
                    trans_parts.append(s.strip())
        if gene and prot_id and trans_parts:
            translation = "".join(trans_parts).replace("\n", "")
            genes[gene] = (prot_id, translation)
    return genes


def build_ecoli_db():
    """Build E. coli MG1655 protein DB and iJO1366 query FASTA."""
    if not GBK.exists():
        raise FileNotFoundError(f"Missing GenBank file: {GBK}")
    genes = parse_genbank_proteins(GBK)
    print(f"E. coli MG1655 CDS with gene names: {len(genes)}")

    # Write all MG1655 proteins
    with open(ECOLI_FASTA, "w") as f:
        for gene, (pid, seq) in sorted(genes.items()):
            f.write(f">{gene}|{pid}\n")
            for i in range(0, len(seq), 60):
                f.write(seq[i:i + 60] + "\n")
    print(f"Wrote {ECOLI_FASTA}")

    # makeblastdb
    subprocess.run(
        [str(BLAST_BIN / "makeblastdb"), "-in", str(ECOLI_FASTA), "-dbtype", "prot",
         "-out", str(ECOLI_DB), "-parse_seqids"],
        check=True, capture_output=True,
    )

    # iJO1366 subset (the 1366 genes with dependency scores)
    ijo_names = [l.strip() for l in IJO_GENES.read_text().splitlines() if l.strip()]
    with open(IJO_FASTA, "w") as f:
        n = 0
        for gene in ijo_names:
            if gene in genes:
                _, seq = genes[gene]
                f.write(f">{gene}\n{seq}\n")
                n += 1
    print(f"iJO1366 proteins with sequences: {n}/{len(ijo_names)}")


# ── Proteome fetch (NCBI Datasets) ──────────────────────────────────────────


def fetch_proteome(genus: str, accession: str, dest: Path) -> Path:
    """Download RefSeq protein FASTA via NCBI Datasets API. Returns fasta path."""
    fasta = dest / f"{genus.lower()}_proteins.faa"
    if fasta.exists() and fasta.stat().st_size > 1000:
        return fasta
    url = (
        f"https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/"
        f"{accession}/download?include_annotation_type=PROTEIN_FASTA"
    )
    req = urllib.request.Request(url, headers={"Accept": "application/zip"})
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = resp.read()
    zf = zipfile.ZipFile(io.BytesIO(data))
    for name in zf.namelist():
        if name.endswith("protein.faa"):
            content = zf.read(name)
            with open(fasta, "wb") as f:
                f.write(content)
            print(f"  {genus}: fetched {len(content)} bytes -> {fasta.name}")
            return fasta
    raise RuntimeError(f"No protein.faa in Datasets zip for {genus} {accession}")


# ── BLAST ───────────────────────────────────────────────────────────────────


def blastp_query(query_fa: Path, db: str, out: Path, max_targets: int = 5) -> None:
    """Run blastp; results in tabular format (subject may be many)."""
    with open(out, "w") as fout:
        subprocess.run(
            [str(BLAST_BIN / "blastp"), "-query", str(query_fa), "-db", db,
             "-outfmt", "6 qseqid sseqid pident length qlen slen evalue bitscore",
             "-max_target_seqs", str(max_targets), "-evalue", "1e-3",
             "-num_threads", "8"],
            stdout=fout, check=True,
        )


def parse_blast(out: Path) -> dict[str, list[tuple]]:
    """Return {qseqid: [(sseqid, pident, length, qlen, evalue, bitscore), ...]}"""
    hits: dict[str, list[tuple]] = {}
    if not out.exists():
        return hits
    for line in out.read_text().splitlines():
        p = line.split("\t")
        if len(p) < 7:
            continue
        q, s = p[0], p[1]
        pident, length, qlen, evalue, bitscore = float(p[2]), float(p[3]), float(p[4]), float(p[6]), float(p[7])
        hits.setdefault(q, []).append((s, pident, length, qlen, evalue, bitscore))
    return hits


def best_hit(hits: dict[str, list[tuple]], q: str) -> tuple | None:
    hs = hits.get(q, [])
    if not hs:
        return None
    # Best by e-value, then bitscore
    return min(hs, key=lambda h: (h[4], -h[5]))


def reciprocal_orthologs(endo_fasta: Path, genus: str, dest: Path) -> dict[str, bool]:
    """
    Reciprocal best hits between iJO1366 proteins and endosymbiont proteome.
    Returns {ijO_gene: retained_bool}
    """
    prefix = genus.lower()
    fwd_out = dest / f"{prefix}_fwd.tsv"     # endo -> ecoli
    rev_out = dest / f"{prefix}_rev.tsv"     # ecoli(ijo) -> endo
    endo_db = dest / f"{prefix}_db"

    # forward: endosymbiont proteome against E. coli DB
    blastp_query(endo_fasta, str(ECOLI_DB), fwd_out, max_targets=5)
    # reverse: iJO1366 proteins against endosymbiont DB
    subprocess.run(
        [str(BLAST_BIN / "makeblastdb"), "-in", str(endo_fasta), "-dbtype", "prot",
         "-out", str(endo_db), "-parse_seqids"],
        check=True, capture_output=True,
    )
    blastp_query(IJO_FASTA, str(endo_db), rev_out, max_targets=5)

    fwd = parse_blast(fwd_out)   # endo protein -> best ecoli gene(s)
    rev = parse_blast(rev_out)   # iJO gene -> best endo protein(s)

    # For each endo protein, its best ecoli hit
    endo_to_ecoli = {q: best_hit(fwd, q) for q in fwd}
    # For each ecoli gene, its best endo hit
    ecoli_to_endo = {q: best_hit(rev, q) for q in rev}

    # Reciprocal: endo protein X hits ecoli gene G as its best; G's best is X
    retained: dict[str, bool] = {}
    for g in IJO_GENES.read_text().splitlines():
        g = g.strip()
        if not g:
            continue
        g_hit = ecoli_to_endo.get(g)
        if g_hit is None:
            retained[g] = False
            continue
        endo_prot, pident, length, qlen, evalue, bitscore = g_hit
        if evalue > EVALUE_CUTOFF or length / qlen < MIN_COVERAGE:
            retained[g] = False
            continue
        # endo_prot's best ecoli hit must be g
        e_hit = endo_to_ecoli.get(endo_prot)
        if e_hit is None:
            retained[g] = False
            continue
        e_gene = e_hit[0].split("|")[0]
        retained[g] = (e_gene == g)
    return retained


# ── ρ computation ───────────────────────────────────────────────────────────


def compute_rho(retention: dict[str, bool]) -> dict:
    """Spearman rho between iJO1366 dependency scores and retention."""
    deps = {}
    with open(DEP_SCORES) as f:
        next(f)
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) >= 4:
                deps[parts[1]] = float(parts[3])
    xs, ys = [], []
    for g, retained in retention.items():
        if g in deps:
            xs.append(deps[g])
            ys.append(1.0 if retained else 0.0)
    xs_arr, ys_arr = np.array(xs), np.array(ys)
    if len(xs) < 10 or np.all(ys_arr == ys_arr[0]):
        return {"n_genes": len(xs), "n_retained": int(ys_arr.sum()),
                "rho": float("nan"), "p": float("nan")}
    rho, p = spearmanr(xs_arr, ys_arr)
    return {"n_genes": len(xs), "n_retained": int(ys_arr.sum()),
            "rho": float(rho), "p": float(p)}


# ── Main ────────────────────────────────────────────────────────────────────


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    print("═══ Building E. coli reference ═══")
    build_ecoli_db()

    results = []
    summary_lines = ["genus\taccession\tn_genes\tn_retained\trho\tp"]
    for genus, acc in GENOMES.items():
        print(f"\n═══ {genus} ({acc}) ═══")
        try:
            fasta = fetch_proteome(genus, acc, DATA_DIR)
            n_prots = sum(1 for l in fasta.read_text().splitlines() if l.startswith(">"))
            print(f"  proteome: {n_prots} proteins")
            retention = reciprocal_orthologs(fasta, genus, DATA_DIR)
            res = compute_rho(retention)
            res["genus"] = genus
            res["accession"] = acc
            res["n_proteome"] = n_prots
            results.append(res)
            print(f"  rho = {res['rho']:.3f}  (n_retained={res['n_retained']}/{res['n_genes']})")
            summary_lines.append(
                f"{genus}\t{acc}\t{res['n_genes']}\t{res['n_retained']}\t{res['rho']:.4f}\t{res['p']:.2e}"
            )
            # save gene-level retention
            with open(DATA_DIR / f"{genus.lower()}_retention.tsv", "w") as f:
                f.write("gene\tretained\n")
                for g, r in retention.items():
                    f.write(f"{g}\t{int(r)}\n")
        except Exception as exc:
            print(f"  ✗ FAILED: {exc}")
            results.append({"genus": genus, "accession": acc, "error": str(exc)})
        time.sleep(1)  # polite delay

    with open(DATA_DIR / "blast_orthology_results.json", "w") as f:
        json.dump(results, f, indent=2)
    with open(DATA_DIR / "summary.tsv", "w") as f:
        f.write("\n".join(summary_lines) + "\n")
    print("\n═══ Summary ═══")
    for r in results:
        if "rho" in r:
            print(f"{r['genus']:15s} rho={r['rho']:.3f} retained={r['n_retained']}/{r['n_genes']}")
        else:
            print(f"{r['genus']:15s} ✗ {r.get('error', '')}")


if __name__ == "__main__":
    main()