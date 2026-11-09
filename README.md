# Monograph Review

An open, reproducible review apparatus for a scientific monograph on animal recovery dynamics.
The repository is a model open-science test bench: the manuscript's claims are re-derived from
its mathematics, its software, and its data, and every reported value is verified by the
pipeline under continuous integration. Assertions claim to reproducibility.

---

## Index

| Section | Description |
|---------|-------------|
| [About](#about) | Core statement, tradition, and systems of study |
| [Methods](#mathematical-methods) | Statistical procedures and notation |
| [Data](#data-sets) | Data sources and provenance |
| [Implementation](#implementation-and-reproduction) | R package architecture and reproduction |
| [Calibration](#calibration-program-self-calibration) | Self-validation tickets and status |
| [Results](#key-results) | Summary of key test results |
| [Documentation](#documentation) | Full documentation index |
| [Structure](#repository-structure) | Repository layout |
| [Contributors](#authors) | Authors and roles |

---

### Quick Links

- **Review index:** [`docs/review/README.md`](docs/review/README.md)
- **Standards:** [`docs/standards/README.md`](docs/standards/README.md)
- **Baseline oracle:** [`baseline/oracle.yml`](baseline/oracle.yml)
- **Live docs:** [phosphene.github.io/monograph-review](https://phosphene.github.io/monograph-review/)

## About

### Proposed Statement

The monograph proposes:

> When an animal is displaced from its homeorhetic trajectory — by exercise, injury, infection,
> or anesthesia — its return is a multiscale relaxation: a recovery composed of multiple
> superimposed decay rates. High-resolution temporal tracking resolves this recovery into two
> distinct phases: a rapid, tissue-autonomous phase present even in aneural animals, and a
> prolonged phase that follows. The ratio of the two recovery timescales (τ₁/τ₂) varies
> systematically with integration structure, remaining invariant within an evolutionary grade
> and shifting across major transitions in organization. What the two phases are, physically —
> tissue-autonomous versus systemically integrated processes — is a labeled, sourced hypothesis
> under test, outside the empirical spine.

**Core observations:** Multiscale (non-mono-exponential) recovery; two distinct phases appear at
temporal resolution; a rapid phase present in aneural animals (tissue-autonomous lineage); a
negative control (sleep slow-wave activity recovers as a single exponential) showing the claim
is specific, not vacuous. Classical scaffolding carries that core: homeorhetic trajectory
(Waddington 1957); recovery timescales τ₁, τ₂ as the within-organism kinetic structure, with
fast and slow as tempo and mode in Simpson's sense (1944) reserved for grade-level divergence
and anchored by the fast-slow continuum of life history (Stearns 1983; Wikelski et al. 2003;
Réale et al. 2010); integration structure (Olson & Miller 1958; Cheverud 1996); evolutionary
grade (Huxley 1958; Simpson 1944).

### Tradition & Genealogy

This review stands in a tradition of observational naturalism. Charles Darwin is an exemplar:
his final book, *The Formation of Vegetable Mould Through the Action of Worms* (1881), models
patient inference from observable behavior — what the animals do, from observable inputs
and outputs. J.O. Wisdom opens his study of scientific inference, *Foundations of Inference
in Natural Science* (1952), with Darwin for exactly this reason: the earthworm study is a
model of drawing no more from an observation than it licenses. Our genealogy descends from
that tradition — observation first, austerity of inference, all claims tested against data.

### Systems of Study

The empirical work behind the review spans a deliberately wide sample of animal life, from
the invertebrate to the vertebrate, from the sessile to the highly mobile:

- **Earthworms** (*Lumbricus terrestris*) — Darwin's own study organism; a model of
  inference from observable behaviors.
- **Nematodes, fruit flies, and other laboratory invertebrates** — short-generation systems in
  which recovery dynamics can be observed across the whole life course.
- **Zebrafish** (*Danio rerio*) — a vertebrate model with a resolved developmental sequence and
  a nervous system that develops late relative to the earliest recovery dynamics.
- **Domesticated mammals** — dogs, horses, and the laboratory mouse (*Mus musculus*); lineage
  records provide the comparative frame for integration structure.
- **Sleep states in humans and songbirds (e.g., the zebra finch)** — the negative control: slow-
  wave activity recovers as a single tempo.

Naturalist names in the classical sense: the systems are studied as living animals,
not as abstracted data sources.

## Mathematical Methods

The statistical procedures are those standard in the evolutionary and physiological literature,
each validated against known truth before use:

- **Model selection among recovery shapes** — single-exponential versus two-tempo
  (bi-exponential) fits, compared by information criteria (ΔAICc) and Bayes factors (BF > 6 as
  moderate evidence, BF > 10 as strong). This is the core contrast: mono rejected 28/28 at
  beat-level resolution.
- **PGLS (Phylogenetic Generalized Least Squares)** — regression correcting for the non-
  independence of species due to shared evolutionary history (the λ parameter measures the
  strength of phylogenetic signal in the residuals).
- **Exact permutation tests** — non-parametric significance enumeration (all orderings; for six
  items, all 720), preferred over asymptotic approximations for small samples.
- **Biphasic kinetics** — the pattern of change with two distinct rates: a fast phase followed
  by a slow phase; mathematical signature a logistic (saturation) curve distinguishable from
  linear (constant-rate) or exponential (accelerating) alternatives.
- **Cross-kingdom parameter transfer** — parameters estimated in one kingdom applied to another
  without refitting; the strongest test of the claim's generality because it controls for
  kingdom-specific confounds.

**Notation and conventions.** Every symbol used in this document has a fixed meaning:

| Symbol | Meaning |
|--------|---------|
| τ₁, τ₂ | the two recovery timescales — the fast and slow decay constants |
| ΔAICc | difference in corrected Akaike information criterion |
| BF | Bayes factor — evidence ratio between compared models |
| β | regression coefficient (PGLS slope) |
| R² | coefficient of determination — share of variance explained |
| ρ | Spearman's rank correlation coefficient |
| λ | phylogenetic signal — strength of phylogenetic correlation in residuals |
| p | attained significance level of the stated test |

## Data Sets

All data are bundled in the repository (`data/`) with provenance documented in YAML
(`data/README.md`). Sources include:

- **NCBI GenBank** — plastome sizes and phylogenies (parasitic plant gradient).
- **Bobay & Ochman (2017) Table S1** — niche breadth data (bacterial endosymbionts).
- **Dewar et al. (2024) supplementary** — pan-genome data.
- **Good et al. (2017)** — LTEE metagenomic data (12 populations of *E. coli* tracked since 1988).
- **MIT-BIH ST Change and Sleep-EDF archives** (PhysioNet) — beat-level cardiac recovery data
  on which mono was rejected 28/28, and the slow-wave sleep data of the negative control.

## Implementation and Reproduction

The review is implemented as a standard R package, `valence.foundry` (the "foundry" for short),
organized so that every inferential step is a named, pure function with a declared contract.

- **Three-pillar separation.** Every analysis is decomposed into (A) data preparation — a pure
  function that validates inputs and outputs; (B) model fitting — seed-locked and deterministic
  given the same inputs; (C) result extraction — a pure function returning structured data. I/O
  is isolated to thin `main()` wrappers that never run under `source()`, only under `Rscript`.
- **Structured results.** Functions that do work return `values` + `metadata` (seed, sample
  size, convergence status, elapsed time) — a bare number provides no evidence; a structured
  result lets a reviewer trace every number back to its computational conditions.
- **Manifest conformance.** The pipeline is declared as a YAML manifest (`pipeline.yml`); a test
  verifies the actual pipeline matches it, so an added stage that is not declared fails CI.
- **Stochastic Test-Driven Development (STDD).** Deterministic math is tested with exact
  assertions. Stochastic transitions (sampling, bootstrap, permutation) are tested under
  controlled seeds with three classes of assertion: **parameter recovery**, **null control**,
  and **distributional verification**.
- **The simulacrum.** A controlled environment with known test data where the pipeline is
  verified to produce correct results *before* it is pointed at data where the right answer is
  unknown.
- **The baseline oracle** (`baseline/oracle.yml`). Every manuscript-reported value is recorded
  as ground truth. The regression gate compares pipeline output to the oracle.

Reproduction:

```bash
git clone https://github.com/phosphene/monograph-review.git
cd monograph-review
R CMD INSTALL --no-docs --no-multiarch --with-keep-source .
make all            # unit → simulacra → integration → regression
make integration    # full pipeline on real data
make regression     # compare all results to the baseline oracle
```

CI gates (eight, in sequence): lint → unit (coverage ≥ 80%) → simulacra → integration → regression
→ `R CMD check` → Pages → summary.

## Calibration Program (Self-Calibration)

The foundry turns its own instrument back on itself through a ticketed work program
(11 tickets, C1–C8 + E1–E3) stated in hypothetico-axiomatic form. One commit per ticket,
suite green before push.

**Status (2026-08-30):**

- **E1 — coverage gate (DONE, PR #22).** Unit coverage lifted above the ≥80% gate: overall
  83.98% → **93.25%**. Two robustness bugs fixed.
- **E2 — revive the property-based invariants suite (DONE, merged).** Full suite green.
- **Next:** C6, then C1 → C2 → C5 → C4 → C7 → C3 → C8 → E3.

## Key Results

Every value below is stored as ground truth in the baseline oracle; the pipeline must reproduce
it within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes thesis? |
|------|-----------------|-----------|----------------------|
| T1: Orobanchaceae PGLS | Plastome vs parasitism | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No |
| T3: Endosymbiont biphasic | Genome reduction shape | R² = 0.920, BF = 6.7 | Yes |
| T6: Gene-loss ordering | Dependency vs retention | ρ = 0.955, p = 0.0083 | Yes |
| L3: Cross-kingdom transfer | Plant → bird morphology | ρ = 0.755, p = 0.031 | Yes |

## Documentation

Findings are recorded as numbered Remarks (R1, R2, …) and Review Items (1–6); the test suite
and pipeline cite them by number.

**Method and working notes**

1. [Review method and naming discipline](docs/review/method.md) — commitments, qualified-naming discipline
2. [Review evaluation standard](docs/review/review-evaluation-standard.md) — vertices and properties
3. [Review index](docs/review/README.md) — full index of review documentation

**Critical review**

4. [Manuscript review](docs/review/manuscript-review.md) — critical review of the manuscript (v9)
5. [Calculation review](docs/review/calculation-review.md) — literate walkthrough of calculation audit
6. [Math review](docs/review/math-review.md) — audit of math vs implementation vs claims
7. [Refactoring plan](docs/review/refactoring-plan.md) — execution plan (COMPLETE)

**Genealogies**

8. [Family-kinds genealogy](docs/review/family-kinds-genealogy.md) — definitory-apparatus lineage
9. [Complementarity lineage](docs/review/bohr-complementarity-lineage.md) — Bohr → Delbrück lineage
10. [fit_biexp numerical challenges](docs/review/fit-biexp-numerical-challenges.md)

**Empirical frontier**

11. [Algorithms & findings](docs/review/algorithms-and-findings.md) — formal survey of algorithms
12. [Formal model reproduction](docs/review/formal-model-reproduction.md) — deep-dive GLM reproduction
13. [Empirical-testing expansion plan](docs/review/empirical-testing-expansion-plan.md)
14. [Modeling, simulation & viz review](docs/review/modeling-sim-viz-review.md)
15. [Exploratory models plan](docs/review/toy-models-plan.md) (COMPLETE)
16. [Foundry phased breakdown](docs/review/foundry-phased-breakdown.md)
17. [Session handoff](docs/review/session-handoff.md)

**Standards**

18. [Phosphene R standards](docs/standards/PHOSPHENE_R_STANDARDS.md)
19. [Standards index](docs/standards/README.md)

## Repository Structure

```
valence.foundry/
├── R/                    Pure functional library
├── tests/                Test suite (38 gate files)
├── baseline/             Ground truth oracle (YAML)
├── data/                 Bundled datasets with provenance
├── inst/simulacra/       Synthetic data generators (9 files)
├── inst/examples/        Literate analysis reports
├── vignettes/            Package vignettes
├── docs/                 GitHub Pages site + review docs
├── compose/              Docker simulacrum stack
├── docker/               Dockerfiles
├── scripts/              Utility scripts
├── archive/              Pre-foundry scripts
├── pipeline.yml          Pipeline manifest
├── .github/workflows/    CI pipeline (7 gates)
├── Makefile              Single-command reproduction
└── DESCRIPTION           R package metadata
```

## Authors

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript; active contributor
- **[Edward Phillips](https://github.com/phosphene)** — Mathematics and software design
- **[FlowBot](https://github.com/FlowFeel)** — Implementation, testing, CI/CD, review support

## License

MIT

## Related

- Manuscript under review (Jan Ritch-Frel, 2026)
- Live visualizations: [phosphene.github.io/monograph-review](https://phosphene.github.io/monograph-review/)
