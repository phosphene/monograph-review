# Wright et al. 2016 — Island Bird Flightlessness Analysis Results

## Overview

This analysis replicates and extends Wright, Steadman & Witt (2016) *"Predictable evolution toward flightlessness in volant island birds"* (PNAS), fitting bi-exponential models to test whether flightlessness evolution follows a two-phase process.

## Data Sources

| Source | Description | Records |
|--------|-------------|---------|
| **Skeletal data** (GitHub: coereba/islands) | 41 morphological variables per specimen | 2,238 specimens |
| **Muscle mass data** (GitHub) | Flight muscle weights (pectoralis, supracoracoideus) | 8,890 specimens |
| **Figshare** (doi: 10.6084/m9.figshare.3123148.v1) | Species-level flight muscle averages | 868 species |
| **Phylogenetic trees** | `bird_pop_tree.tre` — not in GitHub repo; trees from Ponti et al. 2025 dataset (Dryad) unavailable due to access restrictions | — |

## Data Processing

Following the original R analysis pipeline:
1. **Filtering**: Removed continent/Australia populations, specimens with missing key measurements
2. **PCA**: PCA on coracoid, femur, humerus, tarsometatarsus → PC1 (body size, 88.2% variance)
3. **Flightlessness index**: keel.length ~ PC1 residuals (negative = smaller keel = more flightless)
4. **Population averaging**: 366 island populations from 1,723 filtered specimens

### PCA Loadings

| Element | PC1 Loading |
|---------|-------------|
| Coracoid | 0.522 |
| Femur | 0.522 |
| Humerus | 0.516 |
| Tarsometatarsus | 0.433 |

**Keel ~ PC1**: R² = 0.7228 — body size explains 72% of keel length variation

## Non-Phylogenetic Models

| Model | R² | p-value | Interpretation |
|-------|-----|---------|----------------|
| keel_resid ~ log10(spp.rich) | 0.0726 | < 0.001 | Flightlessness ↑ with isolation ↓ |
| keel_resid ~ log10(area) | 0.0083 | 0.082 | Weak area effect |
| shape ~ log10(spp.rich) | 0.0430 | < 0.001 | Body shape shifts with isolation |

## Bi-exponential Model Fitting

Time proxy: log10(landbird species richness) — lower richness = longer isolation.

### Model Comparison (AIC)

| Model | k | AIC | AICc | ΔAICc | Weight |
|-------|---|-----|------|-------|--------|
| **Breakpoint (segmented)** | 4 | 1419.09 | 1419.20 | 0.00 | ~1.00 |
| Bi-exponential | 5 | 1437.22 | 1437.39 | 18.19 | ~0.00 |
| Mono-exponential | 3 | 1438.50 | 1438.56 | 19.36 | ~0.00 |
| Linear | 2 | 1450.79 | 1450.83 | 31.63 | ~0.00 |

### Key Finding: Breakpoint Model Dominates

The **segmented (breakpoint) regression** is the clear best model (~100% AIC weight). The bi-exponential model is degenerate — the two rates are nearly identical (k1 ≈ k2), indicating the data do not support a true two-phase exponential process.

### Parameter Estimates

#### Segmented (Breakpoint) Model
- **Breakpoint**: log10(spp.rich) = **2.18** (~151 landbird species)
- **Left slope** (richness < 151): +9.89 (keel increases with richness — flightlessness decreases)
- **Right slope** (richness > 151): −6.28 (keel decreases with richness — flightlessness increases)
- **Davies' test**: F = 18.46, **p < 0.001** (highly significant)

#### Mono-exponential Model
- Amplitude (A): −32.11
- Rate (k): 1.25
- Asymptote (c): 3.52

#### Bi-exponential Model (degenerate)
- A1: −5713.57, k1: 2.94
- A2: 5817.84, k2: 3.00
- **Note**: k1 ≈ k2 indicates the model collapses to a single exponential — not a true two-phase process

## Davies' Breakpoint Test

| Metric | Value |
|--------|-------|
| Breakpoint location | log10(richness) = 2.18 |
| Corresponding richness | ~151 landbird species |
| Davies' F-statistic | 18.46 |
| p-value | < 0.001 |
| Breakpoint model AICc | 1419.20 |

**Interpretation**: A significant threshold exists. Below ~150 species, flightlessness evolution accelerates markedly. This is consistent with a "release from competition" threshold — once competitor diversity drops below a critical level, selection for flight efficiency is relaxed.

## Flight Muscle Analysis

The muscle mass dataset (8,890 specimens) contains:
- `flight_both`: total flight muscle mass (pectoralis + supracoracoideus, both sides)
- `flight_both_body`: flight muscle mass as proportion of body mass
- Body mass, sex, elevation, and locality data

*Note: Full population-level analysis of flight muscles requires matching to the phylogenetic tree, which was unavailable.*

## Phylogenetic Analysis

**Status**: The phylogenetic tree (`bird_pop_tree.tre`) was not present in the GitHub repository. The 100 alternative trees from the Ponti et al. 2025 Dryad dataset could not be downloaded due to Dryad API access restrictions.

**Alternative approach**: The Ponti et al. 2025 dataset (`doi:10.5061/dryad.1zcrjdg57`) contains NEXUS-formatted trees but does not share the same species taxonomy as the Wright et al. 2016 data.

## Summary of Findings

1. **Flightlessness increases with island isolation** — keel size (proxy for flight muscle) decreases with lower landbird species richness (R² = 0.073, p < 0.001)

2. **Breakpoint at ~150 species** — a significant threshold exists below which flightlessness evolution accelerates. This supports a "competition release" model where relaxed competition on species-poor islands drives rapid evolution toward flightlessness.

3. **Bi-exponential model is degenerate** — the data do not support a two-phase exponential process. The two rates collapse to nearly identical values. A segmented linear model (breakpoint) is strongly preferred.

4. **Body size explains 72% of keel variation** — PC1 of skeletal elements accounts for 88.2% of morphological variance, confirming that body size is the dominant axis of skeletal variation in island birds.

5. **Phylogenetic correction pending** — the Wright et al. 2016 tree file is missing from the public repository. Non-phylogenetic results are consistent with the original published findings.

## Figures

![Analysis results](island_birds_analysis.png)

*Figure 1: (Top left) Keel residual vs. log10(species richness) with model fits. (Top right) Residuals. (Bottom left) Tarsometatarsus residual vs. richness. (Bottom right) Body shape index vs. richness.*

## Data Files

*Note: The island-birds data directory (`data/island-birds/`) is not present in this repository. Large data files are stored in `FlowFeel/woodchipper-data`. The analysis script `scripts/island_birds_pgls.py` exists in this repo.*

| File | Path | Size |
|------|------|------|
| Population-level data | `data/island-birds/processed/population_data.csv` | 93 KB |
| Analysis script | `scripts/island_birds_pgls.py` | 29 KB |
| Original data | `data/island-birds/wright2016_github/` | 3.0 MB |
| Supplement | `data/island-birds/wright2016_supplement.pdf` | 1.4 MB |
| Species averages | `data/island-birds/species_averages_flight_muscles.xlsx` | 156 KB |
| Skeletal supplement | `data/island-birds/skeletal_data.xlsx` | 514 KB |