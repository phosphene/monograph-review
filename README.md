# Monograph Review

An open, reproducible review apparatus for scientific monographs. Each review is a
**vertex**: one monograph under review, its claims re-derived from the monograph's
mathematics, its software, and its data, with every reported value verified by the
pipeline under continuous integration. Nothing is asserted that cannot be reproduced
from the code and data shipped here.

The apparatus is general; the vertices are concrete. Both proceed under the uniform
evaluation standard ([`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md)):
three vertices of scrutiny — **mathematics, software, data** — each tested for
**well-formedness, coherence, and reproducibility**, with no claim exceeding its
stated-and-tested conditions.

---

## Review Vertices

| Review | Monograph | Focus | Status | Vertex Dossier |
|--------|-----------|-------|--------|----------------|
| **Review I: Recovery Dynamics** | Jan Ritch-Frel (2026), *Animal Recovery Dynamics and Multiscale Relaxation* | Multiscale relaxation timescales ($\tau_1/\tau_2$), tissue autonomy, integration structure | Complete; computational artifact live (`valence.foundry`) | [`docs/review-vertices/recovery-dynamics/`](docs/review-vertices/recovery-dynamics/README.md) |
| **Review II: Niche Construction** | Odling-Smee, Laland & Feldman (2003), *Niche Construction: The Neglected Process in Evolution* | Two-locus eco-inheritance recursions, timescale compression, discrete–continuous correspondence | Active — specification phase | [`docs/review-vertices/niche-construction/`](docs/review-vertices/niche-construction/README.md) |

---

## Repository Index & Documentation Architecture

The repository's review documentation is partitioned into focused corpora:

### 1. Active Review Vertices
- **Review I Dossier:** [`docs/review-vertices/recovery-dynamics/README.md`](docs/review-vertices/recovery-dynamics/README.md) — Empirical spine, animal systems of study, mathematical methods, bundled datasets, and the baseline oracle results.
- **Review II Dossier:** [`docs/review-vertices/niche-construction/README.md`](docs/review-vertices/niche-construction/README.md) — Claim under test, two-locus difference equations, dynamical deficits (timescale compression, spatial homogenization, demographic omission), and the correspondence benchmark spec.

### 2. Methodological Standards & Evaluation Contract
- [Review Evaluation Standard](docs/review/review-evaluation-standard.md) — The three-vertex scrutiny contract (mathematics, software, data) and three properties (well-formedness, coherence, reproducibility).
- [Review Method & Naming Discipline](docs/review/method.md) — Epistemic commitments (Braithwaite–Wisdom picture), qualified-naming discipline (Frege → Hickey–Tellman), and the boundary rule for identifiers.
- [Phosphene R Standards](docs/standards/PHOSPHENE_R_STANDARDS.md) — Pure functional structure, three-pillar separation, and manifest conformance.
- [Stochastic Test-Driven Development (STDD)](docs/standards/STDD_SPEC.md) — Parameter recovery, null controls, and distributional verification.
- [Verification Pyramid](docs/standards/verification-pyramid.md) — Gate hierarchy from unit tests to oracle regression.
- [Standards Directory Index](docs/standards/README.md) — Complete guide to engineering policies, CI/CD, and dependency management.

### 3. Critical Audits & Technical Analyses (Review I)
- [Review Documentation Index](docs/review/README.md) — Comprehensive master index of all critical notes, Remark citations (R1–R7), and Review Items (1–6).
- [Manuscript Review](docs/review/manuscript-review.md) — Detailed critical review of manuscript draft v9.
- [Calculation Review](docs/review/calculation-review.md) — Literate walkthrough of the calculation audit and discrepancy diagnoses.
- [Mathematical Review](docs/review/math-review.md) — Audit of mathematics vs. implementation vs. claims (seven issues addressed across three refactoring phases).
- [Refactoring Plan](docs/review/refactoring-plan.md) — Completed three-phase execution plan for math-review issues.
- [Formal Model Reproduction](docs/review/formal-model-reproduction.md) — Resolution of the broken GLM data-flattening bug (`Remark R7`).
- [Fit-Biexp Numerical Challenges](docs/review/fit-biexp-numerical-challenges.md) — Numerical conditioning, ill-conditioned parameter identification, and guarded biphasic classifications.
- [Axis B Mathematical Review](docs/review/axis-b-mathematical-review.md) — Scenario matrix formalization and live 8-cell subspace reduction.

### 4. Genealogies & Epistemic Traditions
- [Simulation Genealogy & Practice](docs/review/simulation-genealogy-and-practice.md) — The lineage of fabricated data from Fisher randomization through Boxian checking to modern simulation-based calibration.
- [Complementarity Lineage](docs/review/bohr-complementarity-lineage.md) — Bohr (1932) → Delbrück → Elsasser/Pattee/Rosen/Stent.
- [Family-Kinds Genealogy](docs/review/family-kinds-genealogy.md) — Definitory apparatus from Wittgenstein (1953) to Beckner, Sokal & Sneath, and Kull (2016).

---

## Quick Reference: Mathematical Notation

Every mathematical symbol used throughout the review benches maintains a fixed, declared meaning:

| Symbol | Context | Meaning |
|--------|---------|---------|
| $\tau_1, \tau_2$ | Review I | Recovery timescales — fast and slow relaxation decay constants |
| $\Delta\text{AICc}$ | Review I | Corrected Akaike information criterion difference between competing model fits |
| $\text{BF}$ | Review I | Bayes factor — evidence ratio between compared models ($\text{BF} > 6$ moderate, $\text{BF} > 10$ strong) |
| $\beta$ | Review I | Regression coefficient (PGLS slope; kb/level in T1) |
| $R^2$ | Review I | Coefficient of determination — share of variance explained |
| $\rho$ | Review I | Spearman's rank correlation coefficient |
| $\lambda$ | Review I | Pagel's $\lambda$ — phylogenetic signal in regression residuals |
| $p$ | Both | Attained significance level under exact permutation or parametric tests |
| $E, A$ | Review II | Construction and recipient genetic loci |
| $R$ | Review II | Modified external environmental resource pool |
| $\mu$ | Review II | Linear resource degradation / depletion rate |
| $\lambda_{\text{nct}}$ | Review II | Ecological construction rate coefficient |
| $c_k$ | Review II | Construction contribution per active phenotype |
| $\tau$ | Review II | Generation time control parameter in discrete–continuous correspondence benchmark |

---

## Computational Reproduction

The Review I test bench is packaged as the R package `valence.foundry`:

```bash
git clone https://github.com/phosphene/monograph-review.git
cd monograph-review
R CMD INSTALL --no-docs --no-multiarch --with-keep-source .
make all            # unit → simulacra → integration → regression
make integration    # full pipeline on real data
make regression     # compare all results against baseline/oracle.yml
```

### Verification Pipeline & Gates

The pipeline enforces eight strictly sequential gates:
1. **Lint** — Code style and static analysis conformance
2. **Unit** — Contract assertions on pure functions (package coverage $\ge 80\%$, currently $93.25\%$)
3. **Simulacra** — Synthetic data generator parameter recovery under known truth
4. **Integration** — End-to-end execution across all bundled empirical datasets
5. **Regression** — Automated verification against [`baseline/oracle.yml`](baseline/oracle.yml) (ground-truth values within $0.001$ tolerance)
6. **R CMD check** — CRAN packaging and contract standards
7. **Pages** — Static HTML documentation and literate report compilation
8. **Summary** — Pipeline verification report

---

## Repository Structure

```
valence.foundry/
├── R/                     # Pure functional library (three-pillar separation)
├── tests/                 # STDD test suite & verification gates
├── baseline/              # Ground truth oracle (baseline/oracle.yml)
├── data/                  # Bundled datasets with YAML provenance
├── inst/simulacra/        # Synthetic data generators for known-truth calibration
├── inst/examples/         # Literate analysis reports & reproduction scripts
├── vignettes/             # Formal package vignettes
├── docs/                  # Documentation suite & GitHub Pages site
│   ├── review-vertices/   # Standalone dossiers for each monograph review
│   │   ├── recovery-dynamics/  # Review I dossier (Ritch-Frel 2026)
│   │   └── niche-construction/ # Review II dossier (Odling-Smee et al. 2003)
│   ├── review/            # Critical audits, calculation walkthroughs, genealogies
│   └── standards/         # Phosphene engineering, STDD, and CI/CD standards
├── pipeline.yml           # Formal pipeline stage manifest
├── .github/workflows/     # CI pipeline definitions
└── Makefile               # Single-command reproduction targets
```

---

## Authors & Provenance

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript under review (Review I) and collaborator.
- **[Edward Phillips](https://github.com/phosphene)** — Lead reviewer, author and designer of the mathematical audits, foundry software architecture, STDD methodology, and review standards.
- **[FlowBot](https://github.com/FlowFeel)** — Automated implementation, testing, CI/CD, and review verification support.

## License

MIT License. See `LICENSE` for details.
