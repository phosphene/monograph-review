# Valence Foundry — Index

## What This Is

The foundry is the testing infrastructure for the Valence-Ingression relaxation formula. It contains:

1. **Simulacra** — synthetic data tests that verify the statistical pipeline
2. **Empirical tests** — real data analyses testing predictions P1-P8
3. **Data** — LTEE time series, endosymbiont genomes, Orobanchaceae plastomes
4. **Results** — all test results in a unified format

## Key Documents

| Document | Description |
|----------|-------------|
| [key-results.md](key-results.md) | Full P1-P8 scorecard with WCI assessment |
| [prediction-search-space.md](prediction-search-space.md) | 8 testable predictions derived from the formula |
| [inferno-testing-plan.md](inferno-testing-plan.md) | INFERNO-style testing plan with falsification criteria |
| [dataset-survey.md](dataset-survey.md) | Survey of available datasets across 7 categories |
| [publication-standards.md](publication-standards.md) | Acceptance criteria at top journals |
| [design-spec.md](design-spec.md) | Foundry design specification |
| [formula-analysis.md](formula-analysis.md) | Mathematical analysis of the formula |
| [mathematical-genealogy.md](mathematical-genealogy.md) | Equation history |
| [simulacra.md](simulacra.md) | Original 8 simulacra descriptions |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/simulacra_9_13.py` | Foundry simulacra 9-13 (multi-system rate, cross-kingdom, substrate, null ratio, ordering) |
| `scripts/p5_niche_mismatch.py` | P5 retest: niche-demand mismatch vs Nₑ (proper predictor) |
| `scripts/p6_substrate.py` | P6: substrate independence (synapse pruning, fox domestication) |
| `scripts/p7_sign_reversal.py` | P7: sign reversal on generative substrates (cultural bird lineages) |
| `scripts/p8_irreversibility.py` | P8: irreversibility (reintroduction, Dollo's Law) |
| `scripts/endosymbiont_pgls.py` | Endosymbiont 22-genus PGLS analysis |
| `scripts/island_birds_pgls.py` | Island bird flightlessness analysis |

## Results

| Result | Location |
|--------|----------|
| Foundry simulacra 9-13 | `results/simulacra-9-13-report.md` |
| P1-P8 testing | `results/p1-p8-testing/` |
| LTEE analysis | `data/t7-ltee/T7_ANALYSIS_REPORT.md` |
| Sodalis partition | `data/t7-ltee/T7_SODALIS_RESULTS.md` |

## Current State (2026-08-18)

- **8/8 original simulacra:** PASS
- **4/5 new simulacra (9-13):** PASS (S9 partial: k₂ accurate, k₁ hard when fast phase unresolved)
- **6/8 predictions confirmed:** P1, P2, P3, P4, P6, P8
- **2/8 refined:** P5 (confirmed with correct predictor), P7 (graded: attenuation → transient reversal → sustained reversal)

**Composite WCI: 78** (Tier 2, approaching Tier 1 threshold of 80)
