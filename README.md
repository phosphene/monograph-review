# Monograph Review: Purpose, Method, and Hypothesis

**Purpose.** The review asks whether the monograph under review is a scientific explanation in
Braithwaite's sense: an ordered deductive system in which empirical generalizations are exhibited
as consequences of higher-level hypotheses (*Scientific Explanation*, 1953). It asks whether the
monograph's moves from observation to hypothesis are scientific inferences in Wisdom's sense:
inferences that do not attribute more than the observations license (J.O. Wisdom; Darwin's worms
as the model of austere inference from observable inputs and outputs).

To that end the review examines the monograph at three vertices — **mathematics, software, data** —
each for three properties: **well-formedness, coherence, reproducibility**. A claim is reliable —
fit to be built upon in further work — only when all three vertices pass all three properties;
until then it remains under test. The review's output is not a verdict but an assessment of the
degree of confidence the monograph's claims warrant: what is established, what is asserted, what
is untested, and the conditions under which the inferences hold.

## Method

The review proceeds under commitments that are themselves part of the Braithwaite–Wisdom picture
of empirical science.

- **Explanation as deduction from higher hypotheses.** The monograph is examined as an ordered
  system of claims. Lower-level empirical generalizations must be exhibited as consequences of
  higher-level hypotheses; theoretical terms take their meaning from their place in the system
  together with their observable consequences. Only derivation propagates through the citation
  chain; speculation does not compound (Braithwaite, chs. II–III).
- **Establishment by consequences.** A hypothesis is established by its verified empirical
  consequences; the weight of evidence, and so the degree of confidence it warrants, grows with
  the variety of consequences that survive testing (Braithwaite, ch. VI). This is the standard
  the review applies: a claim is supported by conditions that are stated and tested, or it is
  not advanced — or is advanced only as a proposal, explicitly marked untested. There is no
  third state.
- **Inference as austerity (Wisdom).** The move from observation to hypothesis must not
  attribute more than the evidence supports. Darwin's worms: patient observation of what
  earthworms do, reasoning from observable inputs and outputs without an extra causal
  ingredient. Where the argument exceeds its evidence, the excess is labeled — speculation,
  open question, hypothesis — and never cited as established fact.
- **Sufficient positive predication.** An assertion is a positive predication: it states what a
  thing is, and thereby carries the implicit negation of what it is not. Specification by
  explicit negation is a weak form of specification — it contrasts rather than predicates, and
  leaves the positive claim underdetermined. Claims are therefore stated by what they are;
  explicit negation is reserved for reporting what happened to a rejected null, never as the
  primary form of a claim.
- **Qualified naming (Hickey–Talman).** Every name must carry sufficient semantic meaningfulness
  as a name. An abstract term sufficient unto its abstraction — within mathematics or within a
  research program — is never a top-level claim on its own: it must be tied to the research
  program from which it draws its meaning. Such a term may appear inside a paragraph that names
  its program, but any name exposed at top level — a hypothesis, a thesis, metadata — must be
  fully qualified, its research-program namespace stated as part of the name.
- **Observation as the production of conditions (Wisdom).** Observations are the foundation of
  scientific method because they are the conditions in which statements can be made — and those
  conditions can be reproduced. The reproduction of the conditions is itself observation: to
  observe is to produce, or reproduce, the conditions under which a statement holds. The review
  therefore does not assert that observation is free of the observer's framework, nor does it
  assert that the research programs it draws on do or do not commute; neither is settled, and
  the argument depends on neither. It depends on the reproducibility of conditions: anyone who
  re-runs the analysis reproduces them, and may draw their own conclusions.
- **Austerity of vocabulary.** No private models, no private metaphors, no terms imported from
  another domain. Every word is a resident of classical evolutionary science or is forced by the
  measurement itself; every model has a named public source. The April category-theoretic sketch
  is the structural reason: an import is a category error.
- **Induction as a policy, and the record.** The justification of induction is pragmatic — it is
  the policy best suited to achieving our aims, and it presupposes a reliable record of past
  trials (Braithwaite, ch. VIII). The record is therefore part of the method, not bookkeeping:
  reproducibility means same input, same output, enforced under CI against a pinned oracle.

## Hypothesis

The monograph under review proposes the following natural statement about animal life. It emerges
from the empirical work; it was not presupposed.

> When an animal is displaced from its homeorhetic trajectory — by exercise, injury, infection,
> or anesthesia — its return is a multiscale relaxation: a recovery composed of multiple
> superimposed decay rates. High-resolution temporal tracking resolves this recovery into two
> distinct phases: a rapid, tissue-autonomous phase present even in aneural animals, and a
> prolonged phase that follows. The ratio of the two recovery timescales (τ₁/τ₂) varies
> systematically with integration structure, remaining invariant within an evolutionary grade
> and shifting across major transitions in organization. What the two phases are, physically —
> tissue-autonomous versus systemically integrated processes — is a labeled, sourced hypothesis
> under test, outside the empirical spine.

The empirical core is forced by the measurement: multiscale (non-mono-exponential) recovery;
two distinct phases that appear at high temporal resolution; a rapid phase present in aneural
animals (tissue-autonomous, in the cell-autonomous lineage of developmental genetics); a
negative control (sleep slow-wave activity recovers as a single exponential) showing the claim
is specific, not vacuous. Classical scaffolding carries that core: homeorhetic trajectory
(Waddington 1957); recovery timescales τ₁, τ₂ as the within-organism kinetic structure, with
fast and slow as tempo and mode in Simpson's sense (1944) reserved for grade-level divergence
and anchored by the fast-slow continuum of life history (Stearns 1983; Wikelski et al. 2003;
Réale et al. 2010); integration structure (Olson & Miller 1958; Cheverud 1996); evolutionary
grade (Huxley 1958; Simpson 1944).

## The systems of study

The empirical work behind the review spans a deliberately wide sample of animal life, from the
invertebrate to the vertebrate, from the sessile to the highly mobile:

- **Earthworms** (*Lumbricus terrestris*) — Darwin's own study organism; the model of austere
  inference from observable behavior (Wisdom).
- **Nematodes, fruit flies, and other laboratory invertebrates** — short-generation systems in
  which recovery dynamics can be observed across the whole life course.
- **Zebrafish** (*Danio rerio*) — a vertebrate model with a resolved developmental sequence and
  a nervous system that develops late relative to the earliest recovery dynamics.
- **Domesticated mammals** — dogs, horses, and the laboratory mouse (*Mus musculus*); lineage
  records provide the comparative frame for integration structure.
- **Sleep states in humans and songbirds (e.g., the zebra finch)** — the negative control: slow-
  wave activity recovers as a single tempo, showing the two-tempo claim is specific, not vacuous.

These are naturalist names in the classical sense: the systems are studied as living animals,
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

## The R code and its reproduction

The review is implemented as a standard R package (`valence.foundry`), organized so that every
inferential step is a named, pure function with a declared contract. This is the operational
enforcement of the method above — inference as code, and code as the record.

- **Three-pillar separation.** Every analysis is decomposed into (A) data preparation — a pure
  function that validates inputs and outputs; (B) model fitting — seed-locked and deterministic
  given the same inputs; (C) result extraction — a pure function returning structured data. I/O
  is isolated to thin `main()` wrappers that never run under `source()`, only under `Rscript`.
- **Structured results (DFT A6).** Functions that do work return `values` + `metadata` (seed,
  sample size, convergence status, elapsed time) — a bare number provides no evidence of what
  happened; a structured result lets a reviewer trace every number back to its computational
  conditions.
- **Manifest conformance (DFT A3).** The pipeline is declared as a YAML manifest
  (`pipeline.yml`); a test verifies the actual pipeline matches it, so an added stage that is
  not declared fails CI.
- **STDD (Stochastic Test-Driven Development).** Deterministic math (log-likelihoods, matrix
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
the `rocker/tidyverse:4.5.3` container; local runs use the miniforge R plus `minpack.lm`. Seven
CI gates, each depending on the previous: lint → unit (coverage ≥ 80%) → simulacra → integration
→ regression → `R CMD check` → Pages. A gate result is only a result once CI is green.

## Key results

Every value below is the manuscript-reported result, stored as ground truth in the baseline
oracle; the pipeline must reproduce it within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes the thesis from competitors? |
|------|-----------------|-----------|-----------------------------------|
| T1: Orobanchaceae PGLS | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts the same gradient |
| T3: Endosymbiont biphasic | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| T6: Gene-loss ordering | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| L3: Cross-kingdom transfer | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — substrate independence predicts no transfer |

## Documentation

The repository ships a complete review trail — every claim traced to its root cause, every
algorithm surveyed with its prediction and competitor, every finding recorded as a numbered
Remark or Review Item that the code cites directly. Index of the review documentation
(all documents live in [`docs/review/`](docs/review/)):

**Standards**

1. [Review evaluation standard](docs/review/review-evaluation-standard.md) — the contract this review upholds: vertices (mathematics, software, data) and properties (well-formedness, coherence, reproducibility).
2. [Review index](docs/review/README.md) — full index of all review documentation.

**Critical review**

3. [Manuscript review](docs/review/manuscript-review.md) — critical review of the manuscript (v9) and the foundry artifacts. Numbered Remarks (R1–R7) and Review Items (1–6).
4. [Calculation review](docs/review/calculation-review.md) — literate walkthrough of the calculation audit: prediction, broken output, root-cause diagnosis, fix.
5. [Math review](docs/review/math-review.md) — audit of the mathematics vs. the implementation vs. the claims (seven issues; two severe; all resolved by the three-phase refactoring).
6. [Refactoring plan](docs/review/refactoring-plan.md) — execution plan for the math-review issues. Status: COMPLETE.

**Genealogies**

7. [Family-kinds genealogy](docs/review/family-kinds-genealogy.md) — the definitory-apparatus lineage: Wittgenstein (1953) → Beckner (1959) → Sokal & Sneath (1963) → … → Kull (2016).
8. [Complementarity lineage](docs/review/bohr-complementarity-lineage.md) — Bohr (Light and Life, 1932) → Delbrück → Elsasser/Pattee/Rosen/Stent.
9. [fit_biexp numerical challenges](docs/review/fit-biexp-numerical-challenges.md) — the operational enforcement of claim-evidence conformance in the relaxation fitter.

**Empirical frontier**

10. [Algorithms & findings](docs/review/algorithms-and-findings.md) — formal literate survey of every algorithm, its prediction, its competitor, and a plain-language reading of the current result.
11. [Formal model reproduction](docs/review/formal-model-reproduction.md) — deep-dive reproduction of the broken GLM. Root cause: `as.vector(t(retention))` misaligns dep and retention. Fix: remove one `t()`. Recorded as Remark R7.
12. [Empirical-testing expansion plan](docs/review/empirical-testing-expansion-plan.md) — proposal for moving the three "testable but not yet tested" modules toward tested. Honest about the data boundary.
13. [Modeling, simulation & viz review](docs/review/modeling-sim-viz-review.md) — review of the author's existing modeling; evaluation of the sim/viz infrastructure; proposal for a speculative simulation capacity.
14. [Exploratory models plan](docs/review/toy-models-plan.md) — execution plan for the speculative simulation capacity: four phased exploratory models. Status: COMPLETE.
15. [Foundry phased breakdown](docs/review/foundry-phased-breakdown.md) — phase-by-phase breakdown of the build, current gate status, and the open data-reconciliation work.
16. [Session handoff](docs/review/session-handoff.md) — current state and forward agenda for continuing software work.

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
├── pipeline.yml          Pipeline manifest (DFT A3: manifest conformance)
├── .github/workflows/    CI pipeline (7 gates)
├── Makefile              Single-command reproduction
└── DESCRIPTION           R package metadata
```

## Authors

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript under review and an active contributor to this codebase.
- **[Edward Phillips](https://github.com/phosphene)** — Author and designer of the mathematics and the software implementations (the R engineering standards, three-pillar separation, DFT axioms, STDD, and the foundry architecture itself).
- **[FlowBot](https://github.com/FlowFeel)** — Helper agent: implementation, testing, CI/CD, and review support.

## License

MIT

## Related

- Manuscript under review (Jan Ritch-Frel, 2026)
- R engineering standards: [`docs/standards/PHOSPHENE_R_STANDARDS.md`](docs/standards/PHOSPHENE_R_STANDARDS.md)
- Review evaluation standard: [`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md)
- Live visualizations: [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/)
- Review index: [`docs/review/README.md`](docs/review/README.md)