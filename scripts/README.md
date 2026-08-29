# The Foundry Scripts

## P1-P8 Testing Scripts

| Script | Prediction | Status | Executable? | Data Source |
|--------|-----------|--------|-------------|-------------|
| `simulacra_9_13.py` | Foundry simulacra 9-13 | ✅ PASS (12/13) | Yes | Synthetic data (numpy) |
| `p5_niche_mismatch.py` | P5: Niche beats Nₑ | ✅ Confirmed (99.6% bootstrap) | Yes | Endosymbiont data (JSON) + iJO1366 model |
| `p6_substrate.py` | P6: Substrate independence | ✅ Confirmed (3/3) | Yes | Embedded data (Huttenlocher, Petanjek, Trut) |
| `p7_sign_reversal.py` | P7: Sign reversal | ⚠️ Refined (graded) | No (outline) | Literature analysis (Garcia-Porta 2022, van Holstein 2024) |
| `p8_irreversibility.py` | P8: Irreversibility | ✅ Confirmed | Yes | Embedded data (Jule 2008, Dollo's Law literature) |
| `endosymbiont_pgls.py` | P1/P3/P5: Endosymbiont analysis | ✅ Results | Yes | Endosymbiont data (JSON) |
| `island_birds_pgls.py` | P1/P3: Island bird analysis | ✅ Results | Yes | Wright 2016 dataset |

## Data Dependencies

- `p5_niche_mismatch.py` and `endosymbiont_pgls.py` are legacy scripts that reference the old `drafts/valence-ingress/` data directory (now archived). Endosymbiont data is at `data/endosymbiont_genome_data.tsv` and `data/endosymbiont_rho_results.json`. The scripts may need path updates to run.
- `island_birds_pgls.py` requires Wright 2016 dataset in `data/island-birds/`
- `p6_substrate.py` and `p8_irreversibility.py` have all data embedded
- `simulacra_9_13.py` generates synthetic data internally

## Original Foundry Scripts (Simulacra 1-8)

| Script | Purpose |
|--------|---------|
| `blast_orthology_rho.py` | BLAST-based orthology analysis for ρ calculation |
| `buchnera_rho.py` | ρ calculation for *Buchnera* |
| `fetch_endosymbiont_rho.py` | Fetch endosymbiont data for ρ analysis |
| `formula_deep_analysis.py` | Deep analysis of formula properties |
| `step_vs_sigmoid.py` | Step vs sigmoid model comparison |
| `three_move_analysis.py` | Three-move analysis (Ohta, Fisher, Wimsatt) |
| `laser_beam.py` | LASER analysis of gene loss patterns |
| `language_laser_beam.py` | LASER analysis applied to linguistic data |
| `economic_extrapolations.py` | Economic extrapolations of the formula |

## Running

All scripts use `python3` (Python 3.10+). Dependencies: numpy, scipy, statsmodels, matplotlib, scikit-learn.

From the repository root:
```bash
python3 scripts/<script>.py
```

(Python 3.10+ required; dependencies: numpy, scipy, statsmodels, matplotlib, scikit-learn.)
