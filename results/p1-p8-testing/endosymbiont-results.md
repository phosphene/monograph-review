# Endosymbiont Genome Reduction Analysis: Comprehensive Results

> **Superseded in part.** This is the original first-pass analysis (22 genera). The predictor comparison in §2 (time vs Nₑ) was superseded by the corrected niche-demand-mismatch analysis in `results/p1-p8-testing/p5-retest-results.md` — time since symbiosis is the wrong predictor (the relaxation formula depends on niche-demand mismatch, not elapsed time); mismatch beats Nₑ (bootstrap 99.6%). The integration-depth analysis (§4) remains valid support. A priori two-component results: `results/p-series/P-SERIES-RESULTS.md`.

## Dataset Summary
- **22 endosymbiont genera** across Gammaproteobacteria, Betaproteobacteria, Alphaproteobacteria, and Bacteroidetes
- Genome sizes range: 0.1120 – 3.5000 Mb
- Mean genome size: 0.5873 ± 0.7092 Mb
- Mean genome reduction from ancestor: 84.0%
- Time since symbiosis: 100 – 260 Mya

## 1. Bi-Exponential vs Mono-Exponential Decay

### Mono-Exponential: f(t) = A·exp(−k·t) + C
| Parameter | Value |
|-----------|-------|
| A | 6.127598 |
| k | 0.019491 |
| C | 0.126883 |
| R² | 0.2078 |
| AIC | -14.25 |

### Bi-Exponential: f(t) = A₁·exp(−k₁·t) + A₂·exp(−k₂·t) + C
| Parameter | Value |
|-----------|-------|
| A₁ | 4.997929 |
| k₁ | 0.019495 |
| A₂ | 1.129737 |
| k₂ | 0.019474 |
| C | 0.126885 |
| R² | 0.2078 |
| AIC | -10.25 |

**Verdict:** Mono-exponential model preferred (ΔAIC = 4.00)

## 2. Predictor Comparison

### Correlations
| Predictor | r | p-value |
|-----------|---|---------|
| Time since symbiosis | 0.4239 | 0.049295 |
| log₁₀(Nₑ) | -0.7642 | 0.000035 |
| Time (partial, controlling Nₑ) | 0.3464 | 0.114319 |
| log₁₀(Nₑ) (partial, controlling time) | -0.7441 | 0.000072 |

### OLS Models
| Model | R² | adj R² | AIC | BIC |
|-------|-----|--------|-----|-----|
| reduction ~ time | 0.1797 | 0.1387 | -14.56 | -12.37 |
| reduction ~ log₁₀(Nₑ) | 0.5840 | 0.5632 | -29.50 | -27.31 |
| reduction ~ time + log₁₀(Nₑ) | 0.6339 | 0.5954 | -30.31 | -27.03 |
| reduction ~ time + time² | 0.2015 | 0.1175 | -13.15 | -9.88 |

## 3. PGLS (Phylogenetic GLS)

### PGLS: reduction ~ time
| Parameter | Value | SE | t | p |
|-----------|-------|----|----|----|
| λ (phylogenetic signal) | 1.0000 | — | — | — |
| Intercept | 0.719689 | 0.179371 | — | — |
| Time | 0.000783 | 0.000769 | 1.0181 | 0.321433 |
| Pseudo-R² | 0.0520 | — | — | — |
| LR test (PGLS vs OLS) | χ² = -42.5863 | — | — | p = 1.000000 |

### PGLS: reduction ~ log₁₀(Nₑ)
| Parameter | Value | SE | t | p |
|-----------|-------|----|----|----|
| λ (phylogenetic signal) | 1.0000 | — | — | — |
| Intercept | 2.020911 | 0.273559 | — | — |
| log₁₀(Nₑ) | -0.255198 | 0.056005 | -4.5567 | 0.000216 |

## 4. Integration-Depth Analysis

### Gene Retention by Dependency Level
| Category | Mean ± SD |
|----------|-----------|
| High dependency | 0.320 ± 0.132 |
| Medium dependency | 0.154 ± 0.126 |
| Low dependency | 0.072 ± 0.096 |

### Paired Comparisons
| Comparison | t | p | Significant? |
|-----------|---|----|-------------|
| High vs Low | 19.2082 | 0.000000 | Yes |
| High vs Medium | 21.2528 | 0.000000 | Yes |
| Medium vs Low | 10.1998 | 0.000000 | Yes |

### Retention vs Reduction Correlations
| Category | r | p |
|----------|---|----|
| High | -0.9045 | 0.000000 |
| Medium | -0.9608 | 0.000000 |
| Low | -0.9849 | 0.000000 |

## 5. Raw Data

| Genus | Genome Size (Mb) | Reduction (%) | Time (Mya) | log₁₀(Nₑ) | Lifestyle |
|-------|-----------------|---------------|------------|------------|-----------|
| Buchnera | 0.6435 | 85.7 | 180 | 5.00 | obligate |
| Carsonella | 0.1670 | 95.8 | 200 | 4.00 | obligate |
| Blochmannia | 0.7923 | 82.4 | 150 | 4.70 | obligate |
| Wigglesworthia | 0.7195 | 82.0 | 100 | 5.00 | obligate |
| Sulcia | 0.2450 | 93.0 | 260 | 5.00 | obligate |
| Nasuia | 0.1120 | 96.3 | 200 | 4.00 | obligate |
| Karelsulcia | 0.2740 | 90.9 | 200 | 5.00 | obligate |
| Tremblaya | 0.1390 | 96.5 | 150 | 4.00 | obligate |
| Moranella | 0.5383 | 84.6 | 100 | 4.70 | obligate |
| Hodgkinia | 0.1440 | 92.8 | 200 | 4.00 | organellar |
| Zinderia | 0.2090 | 93.0 | 200 | 4.00 | obligate |
| Portiera | 0.3540 | 89.9 | 150 | 4.70 | obligate |
| Baumannia | 0.6860 | 80.4 | 100 | 5.00 | obligate |
| Evansia | 0.3570 | 88.1 | 150 | 4.70 | obligate |
| Uzinura | 0.2630 | 91.2 | 150 | 4.70 | obligate |
| Walczuchella | 0.2870 | 90.4 | 150 | 4.70 | obligate |
| Gullanella | 0.9380 | 68.7 | 150 | 4.70 | obligate |
| Brownia | 0.1700 | 94.3 | 100 | 4.00 | obligate |
| Desantisia | 0.1600 | 94.7 | 100 | 4.00 | obligate |
| Ruthia | 1.2000 | 70.0 | 100 | 5.00 | obligate |
| Vesicomyosocius | 1.0220 | 74.4 | 100 | 5.00 | obligate |
| Endoriftia | 3.5000 | 12.5 | 100 | 6.00 | obligate |
