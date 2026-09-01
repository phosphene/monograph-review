# Monograph Review

An open, reproducible review apparatus for a scientific monograph on animal recovery dynamics.
The repository is a model open-science test bench: the manuscript's claims are re-derived from
its mathematics, its software, and its data, and every reported value is verified by the
pipeline under continuous integration. Assertions claim to reproducibility.

## Proposed

The monograph under review proposes the following statement about animal life as supported by 
empirical test.

> When an animal is displaced from its homeorhetic trajectory — by exercise, injury, infection,
> or anesthesia — its return is a multiscale relaxation: a recovery composed of multiple
> superimposed decay rates. High-resolution temporal tracking resolves this recovery into two
> distinct phases: a rapid, tissue-autonomous phase present even in aneural animals, and a
> prolonged phase that follows. The ratio of the two recovery timescales (τ₁/τ₂) varies
> systematically with integration structure, remaining invariant within an evolutionary grade
> and shifting across major transitions in organization. What the two phases are, physically —
> tissue-autonomous versus systemically integrated processes — is a labeled, sourced hypothesis
> under test, outside the empirical spine.

An empirical attempt at some measurement: multiscale (non-mono-exponential) recovery;
two distinct phases appear at temporal resolutions; a rapid phase present in aneural
animals (tissue-autonomous, in the cell-autonomous lineage of developmental genetics); a
negative control (sleep slow-wave activity recovers as a single exponential) showing the claim
is specific, not vacuous. Classical scaffolding carries that core: homeorhetic trajectory
(Waddington 1957); recovery timescales τ₁, τ₂ as the within-organism kinetic structure, with
fast and slow as tempo and mode in Simpson's sense (1944) reserved for grade-level divergence
and anchored by the fast-slow continuum of life history (Stearns 1983; Wikelski et al. 2003;
Réale et al. 2010); integration structure (Olson & Miller 1958; Cheverud 1996); evolutionary
grade (Huxley 1958; Simpson 1944).

## Tradition

This review stands in a tradition of observational naturalism. Charles Darwin is an exemplar: his final book, *The Formation of Vegetable Mould,
Through the Action of Worms* (1881), models patient inference from observable behavior — what
the animals do, from observable inputs and outputs. J.O.
Wisdom opens his study of scientific inference, *Foundations of Inference in Natural Science*
(1952), with Darwin for exactly this reason: the earthworm study is a model of drawing no more
from an observation than it licenses. Our genealogy descends from that tradition —
observation first, austerity of inference, all claims tested against data. The systems
of study below fittingly begin with Darwin's worms.

## The systems of study

The empirical work behind the review spans a deliberately wide sample of animal life, from the
invertebrate to the vertebrate, from the sessile to the highly mobile:

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
not as abstracted data sources. The data sets derived from them are described below.

## Mathematical methods

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

**Notation and conventions.** Every symbol used in this document has a fixed meaning, stated
once here so the README is self-specifying in its use of mathematical notation:

| Symbol | Meaning |
|--------|---------|
| τ₁, τ₂ | the two recovery timescales — the fast and slow decay constants of the two-phase fit |
| ΔAICc | difference in corrected Akaike information criterion between competing model fits |
| BF | Bayes factor — the evidence ratio between the two models compared |
| β | regression coefficient (PGLS slope), in the reported units (kb per level for T1) |
| R² | coefficient of determination — the share of variance explained by the model |
| ρ | Spearman's rank correlation coefficient |
| λ | phylogenetic signal — the strength of shared-evolutionary-history correlation in the PGLS residuals |
| p | attained significance level of the stated test |

## Data sets

All data are bundled in the repository (`data/`) with provenance documented in YAML
(`data/README.md`). Sources include:

- **NCBI GenBank** — plastome sizes and phylogenies (parasitic plant gradient).
- **Bobay & Ochman (2017) Table S1** — niche breadth data (bacterial endosymbionts).
- **Dewar et al. (2024) supplementary** — pan-genome data.
- **Good et al. (2017)** — LTEE metagenomic data (the Long-Term Evolution Experiment, 12
  populations of *E. coli* tracked since 1988).
- **MIT-BIH ST Change and Sleep-EDF archives** (PhysioNet) — the beat-level cardiac recovery
  data on which mono was rejected 28/28, and the slow-wave sleep data of the negative control.

## Implementation and reproduction

The review is implemented as a standard R package, `valence.foundry` (the "foundry" for short),
organized so that every inferential step is a named, pure function with a declared contract. This is the operational
enforcement of the review's method — inference as code, and code as the record. (The method
commitments themselves are documented separately; see the index below.)

- **Three-pillar separation.** Every analysis is decomposed into (A) data preparation — a pure
  function that validates inputs and outputs; (B) model fitting — seed-locked and deterministic
  given the same inputs; (C) result extraction — a pure function returning structured data. I/O
  is isolated to thin `main()` wrappers that never run under `source()`, only under `Rscript`.
- **Structured results.** Functions that do work return `values` + `metadata` (seed, sample
  size, convergence status, elapsed time) — a bare number provides no evidence of what happened;
  a structured result lets a reviewer trace every number back to its computational conditions.
- **Manifest conformance.** The pipeline is declared as a YAML manifest (`pipeline.yml`); a test
  verifies the actual pipeline matches it, so an added stage that is not declared fails CI.
- **Stochastic Test-Driven Development (STDD).** Deterministic math (log-likelihoods, matrix
  transforms, exact permutation enumeration) is tested with exact assertions. Stochastic
  transitions (sampling, bootstrap, permutation) are tested under controlled seeds with three
  classes of assertion: **parameter recovery** (synthetic data from known parameters → the
  pipeline recovers them within the credible interval), **null control** (synthetic data with no
  signal → the pipeline does *not* recover: specificity), and **distributional verification**
  (empirical draws vs analytical distributions, Kolmogorov–Smirnov).
- **The simulacrum.** A controlled environment with known test data where the pipeline is
  verified to produce correct results *before* it is pointed at data where the right answer is
  unknown. On real data you do not know the answer — that is why you are running the analysis —
  so the simulacrum is the only place a known baseline exists.
- **The baseline oracle** (`baseline/oracle.yml`). Every manuscript-reported value is recorded
  as ground truth — the prediction, the competing hypothesis, expected values with numerical
  tolerance, whether the result supports the thesis, whether it distinguishes the thesis from
  the named competitor. The regression gate compares pipeline output to the oracle; divergence
  means either a code regression (fix it) or a genuine method improvement (update the oracle,
  with proof).

Reproduction:

```bash
git clone https://github.com/phosphene/monograph-review.git
cd monograph-review
R CMD INSTALL --no-docs --no-multiarch --with-keep-source .
make all            # unit → simulacra → integration → regression
make integration    # full pipeline on real data
make regression     # compare all results to the baseline oracle
```

The canonical runner is `run_tests.R` (`Rscript run_tests.R <gate>`). CI pins its environment via
`rocker/tidyverse:4.5.3`; local runs use the miniforge R plus `minpack.lm`. Eight CI gates, each
depending on the previous: lint → unit (coverage ≥ 80%) → simulacra → integration → regression
→ `R CMD check` → Pages → summary. A gate result is only a result once CI is green.

## Calibration program (self-calibration)

The foundry turns its own instrument back on itself through a ticketed work program
(11 tickets, C1–C8 + E1–E3) stated in hypothetico-axiomatic form — each ticket is a hypothesis
about our own method, a formalization, and the observable consequences that establish or refute it.
One commit per ticket, suite green before push; a ticket is done only when its exit gate is green.

Status (2026-08-30):
- **E1 — coverage gate (DONE, PR #22).** Unit coverage lifted above the ≥80% gate on all four
  previously under-covered modules and held for the whole package: `p_series_a_priori.R` 19.4% →
  100%, `dynamics_classes.R` 49.7% → 96.0%, `formal_model_classes.R` 50.6% → 91.4%,
  `test_registry.R` 64.1% → 94.7%; overall 83.98% → **93.25%**. 201 contract-test assertions added
  (constructor → validator → helper round-trips, degenerate/NA-fallback branches, registry public
  API) on synthetic fixtures — behavior contracts, not coverage-hacking. Two real robustness bugs
  surfaced and fixed: `p3_plastid_erosion_order` crashed on constant dependency score (now NA
  fallback), and the autocatalytic validator rejected its own documented `"inconclusive"` fallback.
- **E2 — revive the property-based invariants suite (DONE, merged).** `test-invariants-empirical.R`
  re-enabled after fixing a return-contract drift in the PGLS synthetic generator (documented
  `list(data, tree)` vs bare data.frame → every validation died) plus a seed-locked monotone DGM
  for the transfer invariant and lint cleanup. Full suite green. Two vignette contract drifts that
  were failing `R CMD check` were also fixed (`as_valence_autocatalytic_result` counts,
  `retention_at_time` return shape), closing the check gate.
- **Next:** C6 (Monte Carlo error / replication-count discipline), then C1 → C2 → C5 → C4 → C7 →
  C3 → C8 → E3.

## Key results

Every value below is the manuscript-reported result, stored as ground truth in the baseline
oracle; the pipeline must reproduce it within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes the thesis from competitors? |
|------|-----------------|-----------|-----------------------------------|
| T1: Orobanchaceae PGLS | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts the same gradient |
| T3: Endosymbiont biphasic | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| T6: Gene-loss ordering | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| L3: Cross-kingdom transfer | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — independence of the two kingdoms predicts no transfer |

## Documentation

The repository ships a complete review trail — every claim traced to its root cause, every
algorithm surveyed with its prediction and competitor, every finding recorded as a numbered
Remark or Review Item that the code cites directly. All working notes, methodological
commitments, and commentary live in the lower namespace below; the top level only indexes them.

**Convention.** Findings are recorded as numbered Remarks (R1, R2, …) and Review Items (1–6);
the test suite and pipeline cite them by number so that a divergence points at a specific,
written finding rather than an opaque message.

**Method and working notes**

1. [Review method and naming discipline](docs/review/method.md) — the commitments the review
   proceeds under (Braithwaite–Wisdom picture of empirical science), the qualified-naming
   discipline (Frege → Hickey–Tellman), and the boundary rule for names with its worked cases.
2. [Review evaluation standard](docs/review/review-evaluation-standard.md) — the contract this review upholds: vertices (mathematics, software, data) and properties (well-formedness, coherence, reproducibility).
3. [Review index](docs/review/README.md) — full index of all review documentation.

**Critical review**

4. [Manuscript review](docs/review/manuscript-review.md) — critical review of the manuscript (v9) and the foundry artifacts. Numbered Remarks (R1–R7) and Review Items (1–6).
5. [Calculation review](docs/review/calculation-review.md) — literate walkthrough of the calculation audit: prediction, broken output, root-cause diagnosis, fix.
6. [Math review](docs/review/math-review.md) — audit of the mathematics vs. the implementation vs. the claims (seven issues; two severe; all resolved by the three-phase refactoring).
7. [Refactoring plan](docs/review/refactoring-plan.md) — execution plan for the math-review issues. Status: COMPLETE.

**Genealogies**

8. [Family-kinds genealogy](docs/review/family-kinds-genealogy.md) — the definitory-apparatus lineage: Wittgenstein (1953) → Beckner (1959) → Sokal & Sneath (1963) → … → Kull (2016).
9. [Complementarity lineage](docs/review/bohr-complementarity-lineage.md) — Bohr (Light and Life, 1932) → Delbrück → Elsasser/Pattee/Rosen/Stent.
10. [fit_biexp numerical challenges](docs/review/fit-biexp-numerical-challenges.md) — the operational enforcement of claim-evidence conformance in the relaxation fitter.

**Empirical frontier**

11. [Algorithms & findings](docs/review/algorithms-and-findings.md) — formal literate survey of every algorithm, its prediction, its competitor, and a plain-language reading of the current result.
12. [Formal model reproduction](docs/review/formal-model-reproduction.md) — deep-dive reproduction of the broken GLM. Root cause: `as.vector(t(retention))` misaligns dep and retention. Fix: remove one `t()`. Recorded as Remark R7.
13. [Empirical-testing expansion plan](docs/review/empirical-testing-expansion-plan.md) — proposal for moving the three "testable but not yet tested" modules toward tested. Honest about the data boundary.
14. [Modeling, simulation & viz review](docs/review/modeling-sim-viz-review.md) — review of the author's existing modeling; evaluation of the sim/viz infrastructure; proposal for a speculative simulation capacity.
15. [Exploratory models plan](docs/review/toy-models-plan.md) — execution plan for the speculative simulation capacity: four phased exploratory models. Status: COMPLETE.
16. [Foundry phased breakdown](docs/review/foundry-phased-breakdown.md) — phase-by-phase breakdown of the build, current gate status, and the open data-reconciliation work.
17. [Session handoff](docs/review/session-handoff.md) — current state and forward agenda for continuing software work.

**Standards** (engineering practice for open-science test benches)

18. [Phosphene R standards](docs/standards/PHOSPHENE_R_STANDARDS.md) — the R engineering standards behind the foundry.
19. [Standards index](docs/standards/README.md) — CI/CD guide, dependency strategy, literate docs, verification pyramid, and related.

## Repository structure

```
valence.foundry/
├── R/                    Pure functional library
├── tests/                Test suite (38 gate files)
├── baseline/             Ground truth oracle (YAML — human-readable)
├── data/                 Bundled datasets with provenance
├── inst/simulacra/       Synthetic data generators (9 files)
├── inst/examples/        Literate analysis reports (R Markdown)
├── vignettes/            Package vignettes
├── docs/                 GitHub Pages site + review docs + standards
├── compose/              Docker simulacrum stack (docker-compose)
├── docker/               Dockerfiles (R runtime, Verifier; Postgres via compose)
├── scripts/              Utility scripts (viz generation, pipeline, simulacra)
├── archive/              Pre-foundry scripts (with migration map)
├── pipeline.yml          Pipeline manifest (manifest conformance)
├── .github/workflows/    CI pipeline (7 gates)
├── Makefile              Single-command reproduction
└── DESCRIPTION           R package metadata
```

## Authors

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript under review and an active contributor to this codebase.
- **[Edward Phillips](https://github.com/phosphene)** — Author and designer of the mathematics and the software implementations (the R engineering standards, three-pillar separation, STDD, and the foundry architecture itself).
- **[FlowBot](https://github.com/FlowFeel)** — Helper agent: implementation, testing, CI/CD, and review support.

## License

MIT

## Related

- Manuscript under review (Jan Ritch-Frel, 2026)
- Review evaluation standard: [`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md)
- Live visualizations: [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/)
- Review index: [`docs/review/README.md`](docs/review/README.md)
