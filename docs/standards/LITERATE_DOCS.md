# Literate Documentation Standards

## Principle

Code without context is infrastructure without purpose. Every foundry package
documents not only *what* the functions do (roxygen2) but *why* they exist —
what theoretical prediction they test, what competing framework they distinguish
against, and how results map to scientific claims.

## Three Documentation Layers

### Layer 1: Function-Level (Roxygen2)

Every exported function has standard roxygen2 documentation *plus* a
`@section Theoretical Context:` block that states:

1. **What valence prediction this function tests** (or supports)
2. **What competing framework predicts differently** (relaxed selection,
   Muller's ratchet, drift)
3. **What result would support vs. refute valence**

Example:

```r
#' Compute the Capacity Depletion Index (CDI)
#'
#' @param counts Numeric matrix (genes x samples).
#' @param normalize Character. Normalization method.
#' @return List with CDI values, gene counts, and detection correlation.
#' @export
#'
#' @section Theoretical Context:
#'
#' valence predicts that transcriptomic commitment narrows the expressed gene
#' repertoire in an ordered fashion (integration-depth dependent). CDI
#' (negative Shannon entropy) measures this narrowing. A higher CDI
#' (less negative) indicates a narrower transcriptome.
#'
#' Competing frameworks (relaxed selection, Muller's ratchet) predict
#' random gene loss, not ordered. CDI alone cannot distinguish ordered
#' from random loss — that requires `gene_category_spearman()`.
#'
#' CDI is necessary but not sufficient for valence claims. A significant CDI
#' change without integration-depth ordering is consistent with valence but
#' does not confirm it.
compute_cdi <- function(counts, normalize = "size_factor") { ... }
```

### Layer 2: Package-Level (Vignette)

Every foundry package has a vignette (`vignettes/` directory) that provides:

1. **Scientific motivation** — what theory, what predictions, what gap
2. **Method overview** — how each function maps to a prediction
3. **Worked example** — real data analysis from start to finish
4. **Limitations** — what the functions cannot establish
5. **Interpretation guide** — how to read results, what supports/refutes

Vignette structure:

```markdown
# valence.stats: Testing Vestigial Information Predictions

## Scientific Motivation

Valence predicts that transcriptomic commitment follows integration-depth
ordering: deeply integrated functions resist loss more than shallowly
integrated ones. This is testable via RNA-seq data...

## Function Map

| Function | valence Prediction Tested | Competitor Prediction |
|----------|---------------------|----------------------|
| `compute_cdi()` | Transcriptome narrows under commitment | No prediction (measurement only) |
| `gene_category_spearman()` | Ordered narrowing by integration depth | Random loss (relaxed selection) |
| `paired_cdi_test()` | CDI changes between commitment states | No change (drift) |
| `sensitivity_analysis()` | Pattern survives confound exclusion | Pattern is confound artifact |
| `responder_split_test()` | Effect is biological, not pharmacological | Effect is drug artifact |

## Worked Example: CTVT Analysis

[Full analysis with real data, from loading to interpretation...]

## Limitations

CDI measures transcriptomic evenness, not functional capacity. It cannot
distinguish healthy diversity from pathological dysregulation. Detection
rate confounds CDI when sequencing depth varies — always report
`detection_correlation`...
```

### Layer 3: Analysis-Level (Literate Report)

Every analysis script (in `inst/examples/` or companion packages) produces
a literate report — an R Markdown document that interleaves code, results,
and scientific interpretation. This is not a log file; it is a document
that a reader can follow without running the code.

Structure:

```markdown
---
title: "CTVT Test 1: Integration-Depth-Ordered Capacity Loss"
author: "Flow"
date: "2026-07-25"
output: html_document
---

## Background

CTVT is a 6,000-year-old clonal transmissible cancer. Valence predicts...

## Data

12 paired samples from 6 dogs (ENA PRJEB21960)...

## Results

### CDI Values

```{r}
cdi_result <- compute_cdi(counts)
```

The CDI values show... [interpretation]

### Integration-Depth Ordering

```{r}
spearman_result <- gene_category_spearman(fc, ranks)
```

The Spearman rho is `r spearman_result$spearman_rho` (p = `r spearman_result$p_value`).
Valence predicts a negative rho (deeper genes retained more). The observed
value is `r ifelse(spearman_result$spearman_rho < 0, "consistent with", "opposite to")`
Valence's prediction.

## Interpretation

[What the results mean for valence, honestly stated]

## Limitations

n=6, detection confound, no single-cell resolution...
```

## What This Adds Beyond Existing Standards

The existing Phosphene R Standards (§8) cover roxygen2 syntax, README
structure, and data provenance. Literate documentation adds:

| Existing | Literate Addition |
|----------|-------------------|
| `@param`, `@return`, `@export` | `@section Theoretical Context:` |
| README: "What is this?" | Vignette: "Why does this exist?" |
| `data/README.md`: provenance | Analysis report: interpretation |
| Code comments | Scientific narrative |

## File Locations

```
packages/valence.stats/
├── vignettes/
│   └── vi-stats.Rmd           # Package vignette (Layer 2)
├── inst/
│   └── examples/
│       ├── run_ctvt_analysis.R      # Executable script
│       └── ctvt_test_report.Rmd     # Literate report (Layer 3)
├── R/
│   └── compute_cdi.R          # With @section Theoretical Context (Layer 1)
└── README.md                  # Existing standard
```

## Quality Gate

A package is not "foundry-complete" until all three layers exist:

1. ✅ All exported functions have `@section Theoretical Context:`
2. ✅ Package vignette exists with the 5 required sections
3. ✅ At least one analysis example has a literate report (.Rmd)

This gate is enforced in CI: `covr::package_coverage()` checks file
existence; missing literate docs fail the build.

## Relationship to INFERNO

Literate documentation is the *positive* complement to INFERNO's *negative*
discipline. INFERNO asks: "What is wrong with this claim?" Literate docs
ask: "What does this code mean for the theory?" Both are required. A package
that passes INFERNO but lacks literate documentation is rigorously tested
but incomprehensible. A package with beautiful docs that fails INFERNO is
persuasive but wrong.
