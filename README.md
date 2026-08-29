# Monograph Review: Computational Test Infrastructure (`valence.foundry`)

**Production-grade computational artifacts for evaluating the claims of the manuscript under review — *A Trajectory Account of Adaptive Evolution from Homo to the Wider Animal Kingdom* (Ritch-Frel, 2026).**

---

## What This Is

This repository contains the complete computational pipeline for testing the manuscript's claims: a theory of adaptive evolution that predicts organisms committing to specific ecological niches undergo ordered capacity reallocation, losing traits in proportion to their integration depth (how deeply a trait is embedded in the organism's functional architecture) rather than at random.

The artifacts here do not merely reproduce numbers from the manuscript. They constitute the proof machinery: every claim is a pure, testable function with contract enforcement; every statistical method is validated against synthetic data with known ground truth; and every result is traceable to its computational environment.

The package serves three audiences:

- **Researchers** evaluating the framework's empirical support
- **Reviewers** checking whether the statistical methods are sound
- **Replicators** reproducing the results on different data or platforms

---

## The Standards Under Which This Review Is Conducted

This review operates under the Phosphene standards and ethos, stated in
public scientific language:

- **Public language only.** No private models, no private metaphors, no
  private acronyms. Every model and metaphor used here is already in the
  published literature, with a named genealogy. Under scientific review,
  nothing is coined.
- **No claim exceeds its stated-and-tested conditions.** A claim is either
  supported by conditions that are stated and tested, or it is not
  advanced (or is advanced only as proposed/untested). There is no third
  state. A claim that exceeds its tested conditions is *overclaiming* —
  an inferential error.
- **The review's responsibility (three vertices × three properties).**
  The review evaluates the manuscript's **mathematics, software, and
  data** — each for **well-formedness, coherence, and reproducibility**.
  A result is rely-on-able only when all three vertices pass all three
  properties. See
  [`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md).
- **Underwriting, not discovery.** The authors propose claims; the review
  team and platform team assess them. We underwrite the reliability of the
  inferential claims and predictive apparatus of the research program — we
  do not ourselves discover. A claim that has not passed underwriting is
  not refuted; it is not yet covered, and remains under test.

---

## How to Reproduce

```bash
# Clone and enter
git clone [https://github.com/phosphene/monograph-review](https://github.com/phosphene/monograph-review).git
cd monograph-review

# Restore the R environment (exact package versions)
renv::restore()

# Run all gates (lint → unit tests → simulacra → integration → regression → check)
make all

# Or run individual gates
make unit          # Pure unit tests — mathematical correctness, no Docker
make integration   # Full pipeline on real data via Docker simulacrum stack
make regression    # Compare all results to the baseline oracle
```

---

## Methodological Note

The empirical posture of this repository follows two linked
intellectual lines, both public and both traced in the
[genealogies](#genealogies):

**Complementarity as a realist axiom under test (Bohr).**
The patterns reported here come from research programs that do not
commute — different systems, different measures, different founding
assumptions, no shared apparatus. They do not need to commute. The
*observation* is naked: each apparatus registers something definite,
and that registration does not carry any one theory's vocabulary. The
*representation* is theory-laden: models, metrics, and instruments are
built to their own frameworks. The strategy is therefore never to fight
over representations, but to hold the naked observations side by side
and let the pattern show itself. Anyone who re-runs the pipeline and
re-represents the observations in their own vocabulary is welcome to;
the conclusions they draw are theirs.

**The family-kinds discipline (boundary-challenged concepts).** The
cross-domain concepts here — adaptive-returns seeking, conserved core,
ordered loss, substrate independence — are *family-resemblance*
categories: present in many instances, not essential in all. They are
defined operationally within each domain (a fitted biphasic model, a PGLS
slope, a permutation ordering, a cross-kingdom transfer), and the
cross-domain pattern is the family resemblance. A non-instantiating case
is a *boundary probe*, not a refutation: it measures the domain of
validity of the pattern rather than contradicting it. See
[`docs/review/family-kinds-genealogy.md`](docs/review/family-kinds-genealogy.md).

**Claim-evidence conformance.** Because the concepts are
boundary-challenged, no claim here exceeds its stated-and-tested
conditions: every claim is reproducible (CI gates, baseline oracle,
seed-locked fits), every citation points at a real passage, and the
representation is openly theory-laden while the observation is left naked
for anyone to verify.

The standard is enforced operationally in the relaxation fitter — see
[`docs/review/fit-biexp-numerical-challenges.md`](docs/review/fit-biexp-numerical-challenges.md),
the rigorous revisit of `fit_biexp` and its `biphasic` consumer. The
fitter reports a two-timescale structure only when the data forces it
(guarded rule: AIC agreement, rate ratio, same sign, amplitude floor),
and treats a degenerate sample as a boundary probe rather than a
forced conclusion. Reproducible via `scripts/validate_fit_biexp.py`.

---

## Key Results

Every value below is the manuscript-reported result, stored as ground truth in [`baseline/oracle.yml`](baseline/oracle.yml). The pipeline must reproduce these within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes the framework from competitors? |
|------|-----------------|-----------|-----------------------------------|
| T1: Orobanchaceae PGLS | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts the same gradient |
| T3: Endosymbiont biphasic | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| T6: Gene-loss ordering | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| L3: Cross-kingdom transfer | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — substrate independence predicts no transfer |

**Live visualizations:** [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/) — simulacra parameter recovery, baseline oracle, key results, and four speculative toy models (threshold gate, irreversibility, Homo inversion, cross-kingdom transfer), all with literate context.

---

## Documentation

The repository ships a complete review trail — every claim traced to its root cause, every algorithm surveyed with its prediction and competitor, every finding recorded as a numbered Remark or Review Item that the code cites directly. All documents are in [`docs/review/`](docs/review/) (see the [review index](docs/review/README.md) for the full list).

### Critical review

| Document | What it is |
|----------|-----------|
| [Manuscript review](docs/review/manuscript-review.md) | Critical review of the manuscript (Ritch-Frel, v9) and the foundry artifacts. Numbered **Remarks** (R1–R7) and **Review Items** (1–6). The code cites these directly. |
| [Calculation review](docs/review/calculation-review.md) | Literate walkthrough of the calculation audit: for each oracle entry, the prediction, the broken output, the root-cause diagnosis, and the fix. |
| [Math review](docs/review/math-review.md) | Audit of the mathematics vs. the implementation vs. the claims (seven issues ranked by severity; two severe). All seven resolved by the three-phase refactoring. |
| [Refactoring plan](docs/review/refactoring-plan.md) | Execution plan for the math-review issues: proposed refactoring, blast radius, risk, and three-phase ordering (safest-first). Status: COMPLETE. |

### Genealogies

| Document | What it is |
|----------|-----------|
| [Family-kinds genealogy](docs/review/family-kinds-genealogy.md) | The definitory-apparatus lineage: Wittgenstein (family resemblance, 1953) → Beckner (polytypic classes, 1959) → Sokal & Sneath (operational polythetic groups, 1963) → Mayr → Ghiselin → Paterson → Templeton → de Queiroz → Pigliucci → Kunz → Kull (semiotic species, 2016). Why boundary-challenged concepts are handled as family-resemblance categories and non-instantiating cases as boundary probes. |
| [Complementarity lineage](docs/review/bohr-complementarity-lineage.md) | The epistemology: Bohr (Light and Life, 1932) → Delbrück → Elsasser/Pattee/Rosen/Stent. Observation is naked, representation is theory-laden, programs need not commute. The realist axiom under test. |
| [fit_biexp numerical challenges](docs/review/fit-biexp-numerical-challenges.md) | The operational enforcement of claim-evidence conformance in the relaxation fitter: the ill-conditioning, the seed-fragile mono/bi boundary, the biphasic-flag bug and its guarded fix, and the degenerate-sampling/noise boundaries as boundary probes. Reproducible via `scripts/validate_fit_biexp.py`. |

### Build history and synthesis

| Document | What it is |
|----------|-----------|
| [Phased breakdown](docs/review/foundry-phased-breakdown.md) | Phase-by-phase breakdown of the foundry build, current gate status, and the open data-reconciliation work (items 4–6). |
| [Algorithms & findings](docs/review/algorithms-and-findings.md) | Formal literate survey of every algorithm, its prediction, its competitor, and a plain-language reading of the current result. The synthesis of what the foundry establishes, what it does not, and what that means for the framework. |

### Modeling, data, and the empirical frontier

| Document | What it is |
|----------|-----------|
| [Modeling, sim & viz review](docs/review/modeling-sim-viz-review.md) | Review of the author's existing modeling (finds the original empirical GLM was broken by a data-flattening bug; the foundry hid this with a theoretical simulation). Evaluation of the sim/viz infrastructure (three latent viz bugs found and fixed). Proposal for a speculative simulation capacity. |
| [Formal model reproduction](docs/review/formal-model-reproduction.md) | Deep-dive reproduction of the broken GLM. **Root cause:** `as.vector(t(retention))` misaligns dep and retention. **Fix:** remove one `t()`. The corrected additive GLM gives dep = +0.84 (p = 0.0008), para p < 0.0001, cross-kingdom ρ = +0.755 — all matching the framework's prediction. Recorded as **Remark R7**. |
| [Empirical-testing expansion plan](docs/review/empirical-testing-expansion-plan.md) | Proposal for moving the three "testable but not yet tested" modules (Homo inversion, cusp irreversibility, cross-kingdom transfer) toward tested. Honest about the data boundary. |
| [Toy models plan](docs/review/toy-models-plan.md) | Execution plan for the speculative simulation capacity: four phased toy models that make the framework's predictions explorable without claiming empirical test. Status: COMPLETE — all 4 models built, tested, and documented. |

---

## Glossary

### Framework Terms

**The framework under review** — The manuscript's hypothesis: organisms
enter ecological spaces offering adaptive returns, are reshaped by those
spaces, and this commitment process directs evolutionary trajectory more
fundamentally than selection alone. (The manuscript's working name for the
framework is under review — see Remark R1 in the review file — because it
requires reading internal definitions before it becomes meaningful. This
repository refers to the hypothesis in plain descriptive terms.)

**Integration depth** — A trait's position in the functional architecture of an organism. Traits that participate in many developmental pathways (e.g., ribosomal RNA genes) have high integration depth; traits serving a single function (e.g., NADH dehydrogenase in non-photosynthetic parasites) have low integration depth. The framework predicts that high-integration-depth traits resist loss during capacity reallocation.

**Capacity reallocation** — The process by which an organism shedding traits (due to niche commitment) preferentially loses low-integration-depth functions first, reallocating the saved maintenance budget to the remaining high-integration-depth functions. This produces an ordered pattern of trait loss, not random loss.

**Substrate shift** — The transition point where an organism's primary adaptive challenges move from one ecological substrate (e.g., photosynthesis) to another (e.g., parasitism). The framework predicts this shift is autocatalytic — innovations in the new substrate generate further innovations faster than they are lost.

**Homo inversion** — The observation that the Homo lineage shows positively diversity-dependent speciation (more species over time), which is the inverse of the standard pattern in most clades (negatively diversity-dependent, or niche-filling). The framework explains this via the cultural substrate's autocatalytic dynamics.

### Statistical Methods

**PGLS (Phylogenetic Generalized Least Squares)** — A regression method that corrects for the non-independence of species due to shared evolutionary history. Without PGLS, correlations between traits across species can appear significant simply because closely related species share traits by descent, not because of a real functional relationship. PGLS uses a phylogenetic tree and a parameter (λ, lambda) that measures the strength of phylogenetic signal in the residuals. When λ = 1, traits evolve under Brownian motion; when λ = 0, traits are independent of phylogeny (equivalent to ordinary least squares).

**Exact permutation test** — A non-parametric significance test that enumerates all possible orderings of the data to compute a p-value. For 6 items, there are 720 permutations (6! = 720), which is small enough to compute exactly. The p-value is the proportion of permutations that produce a test statistic at least as extreme as the observed one. This is preferred over asymptotic approximations when sample sizes are small.

**Biphasic kinetics** — A pattern of change with two distinct rates: a fast phase followed by a slow phase. In genome reduction, this means rapid initial gene loss (Phase 1, unprotected traits) followed by slow loss (Phase 2, protected traits). The mathematical signature is a logistic (saturation) curve, distinguishable from a linear (constant-rate) or exponential (accelerating) curve via model selection (ΔAICc).

**Cross-kingdom parameter transfer** — A test where parameters estimated on data from one biological kingdom (e.g., plants) are applied to data from another kingdom (e.g., birds) without refitting. If the ordering transfers, the underlying principle is substrate-independent. This is the strongest test in the manuscript because it controls for kingdom-specific confounds.

**Bayes Factor (BF)** — A ratio of marginal likelihoods comparing two statistical models. BF > 6 is moderate evidence for the numerator model; BF > 10 is strong. Here, BF compares the biphasic (logistic) model to the constant-rate (exponential) model.

### Software Engineering Terms

**Three-pillar separation (MPI Handoff Blueprint)** — A code organization principle from the Phosphene R standards. Every analysis is decomposed into three pillars: (A) data preparation — pure function, validates inputs and outputs; (B) model fitting — seed-locked, deterministic given the same inputs; (C) result extraction — pure function, returns structured data. Input/output operations (file reading, writing) are isolated to thin wrapper functions called `main()`, which never runs when the file is `source()`d — only when executed via `Rscript`.

**DFT axioms (Design For Testability)** — Six principles adapted from production software engineering for scientific code:

- **A1 — Pure IO separation**: Statistical logic (estimation, inference, hypothesis testing) never touches the filesystem, network, or databases. I/O is isolated to thin loader functions. This makes the mathematical core testable in zero milliseconds with inline data.
- **A2 — Determinism**: No `set.seed()` hidden inside logic functions. The random seed is injected by the caller, making every stochastic operation reproducible. Cross-platform reproducibility requires specifying the RNG algorithm (`Mersenne-Twister`) and normal inversion method (`Inversion`) explicitly.
- **A3 — Manifest conformance**: The analysis pipeline is declared as a YAML manifest (`pipeline.yml`). Every stage lists its inputs, outputs, and the function that executes it. Tests verify the actual pipeline matches the manifest — if someone adds a stage without updating the manifest, the test fails.
- **A4 — Documentation**: Every source file declares its testability contract in a `@dft` roxygen2 block, stating which axioms it satisfies.
- **A5 — Real in-process fakes**: Instead of mocking `read.csv()` with a mock that records "you called read.csv," a `FakeDataLoader` returns real dataframes from in-memory fixtures. The fake executes real behavior — it returns data your logic can actually process.
- **A6 — Check-result**: Functions that do work return a structured result: a list containing `values` (the results) and `metadata` (seed, sample size, convergence status, elapsed time). A function returning `invisible(NULL)` provides no evidence of what happened.

**STDD (Stochastic Test-Driven Development)** — Standard test-driven development breaks on probabilistic code: `expect_equal(mcmc_draw, 1.234)` is meaningless because the output varies with seed, data, and platform. STDD solves this by decoupling deterministic math from stochastic transitions:

1. **Deterministic functions** (log-likelihoods, matrix transforms, exact permutation enumeration): tested with exact assertions. Same input → same output, always.
2. **Stochastic transitions** (sampling, bootstrap, permutation when exhaustive is infeasible): tested under controlled seeds with structural and statistical assertions:
   - **Parameter recovery**: generate synthetic data from known parameters (θ*), run the pipeline, verify the recovered estimates (θ̂) fall within the credible interval of θ*. If the pipeline can recover known signal, it can be trusted to detect unknown signal.
   - **Null control**: generate synthetic data with no signal (random parameters), run the pipeline, verify it does NOT recover. This tests specificity — the pipeline must not produce false positives.
   - **Distributional verification**: for conjugate models, compare empirical draws to analytical distributions using a Kolmogorov-Smirnov test (p > 0.05 means "cannot reject the hypothesis that the samples come from the same distribution").

**Simulacrum** — Borrowed from Nancy Cartwright's philosophy of science: a model that captures essential properties of the target system while being explicitly not the target system. In practice: a Dockerized environment with known test data where you verify the pipeline produces correct results before running against real data. The simulacrum is the only place where you have a known baseline. On real data, you don't know the right answer — that's why you're running the analysis.

**Baseline oracle** — A YAML file ([`baseline/oracle.yml`](baseline/oracle.yml)) containing every manuscript-reported result as ground truth. Each entry includes: the prediction being tested, the competing hypothesis, the expected values (with numerical tolerance), whether the result supports the framework, whether it distinguishes the framework from the named competitor, and any caveats. The regression gate compares pipeline output to the oracle — if results diverge, either the code regressed (fix it) or the method improved (update the oracle with proof).

### Biological Terms

**Orobanchaceae** — The broomrape family, a clade of parasitic plants spanning the full gradient from autotrophic (self-feeding, full plastome) to extreme holoparasitic (entirely dependent on host, severely reduced plastome). This gradient makes it the primary test system for the framework's integration-depth predictions.

**Endosymbiont** — A bacterium living inside a host cell in a permanent, obligate symbiosis. Examples: *Buchnera* (aphid endosymbiont), *Wigglesworthia* (tsetse fly), *Carsonella* (psyllid), *Blochmannia* (ants). These bacteria undergo severe genome reduction over evolutionary time, making them a test system for the framework's biphasic kinetics prediction.

**LTEE (Long-Term Evolution Experiment)** — Richard Lenski's ongoing experiment (since 1988) tracking 12 populations of *E. coli* over 75,000+ generations. Used here to test whether metabolic function loss co-segregates with beneficial mutations (the framework's drift prediction) or is independently assorted (the competitor's pleiotropy prediction).

**NCC (Neural Crest Cell)** — A population of migratory embryonic cells in vertebrates that give rise to facial morphology, pigmentation, and parts of the nervous system. NCC-derived traits are predicted by the framework to change early in domestication because they have low integration depth in the developmental architecture.

### Data Structures

**Mark (simulacrum mark)** — A structured YAML entry logged during a simulacrum run, capturing: the true parameters (the vertex in parameter space being tested), the recovered parameters (where the pipeline landed), whether recovery succeeded (within credible interval), the null control result, and the random seed. Marks can be projected into 2D visualizations: true vs recovered scatter plots, recovery trajectories, parameter-space projections, and rolling recovery-rate plots.

**Structured result (DFT axiom A6)** — The standard return value of every function in this package. A list with two elements: `values` (named numeric vector of the results) and `metadata` (list with seed, sample size, convergence status, elapsed time). A function returning a bare number provides no evidence of what happened; a structured result lets a reviewer trace every result back to its computational conditions.

---

## Standards

This repository is self-sufficient. The Phosphene R engineering standards —
including the three-pillar separation, DFT axioms, STDD specification, literate
documentation requirements, CI/CD guide, and dependency strategy — are
reproduced in [`docs/standards/`](docs/standards/) so that a reader or
contributor does not need to consult external sources to understand the
conventions used here.

All standards documents are authored by **Ed Phillips**
([@phosphene](https://github.com/phosphene)) and licensed under MIT.

## How It Is Tested

The testing strategy is a pyramid:

```
              ┌─────────┐
              │  E2E    │  5% — Full pipeline on real data via Docker simulacrum
              │ Tests   │      + BDD features (Gherkin: simulation, data integrity, pipeline)
              ├─────────┤
              │Integration│ 15% — Real data through the full pipeline
              │  Tests   │      + baseline oracle comparison
              ├─────────┤
              │ Simulacra │  5% — Synthetic data with known parameters
              │  Tests   │      + parameter recovery + null controls (STDD)
              ├─────────┤
              │  Unit   │ 80% — Pure math, contracts, deterministic
              │  Tests  │      0ms each, no Docker, no filesystem
              └─────────┘
```

- **18 test files**, **267 test cases** (`test_that` blocks)
- **5 simulacra** — each generates synthetic data with known ground truth, runs the pipeline, verifies parameter recovery, and confirms the null control does NOT recover (specificity)
- **Baseline oracle** — YAML ground truth for every manuscript value, compared within numerical tolerance
- **5 BDD feature files** — statistical contracts in Gherkin (same seed → same output, pipeline idempotency, numerical stability, parameter recovery)
- **Coverage gate** — minimum 80%, enforced in CI

---

## Continuous Integration

Seven gates, each depends on the previous:

| Gate | What It Checks | Artifact |
|------|---------------|----------|
| 1. Lint | Code style and static analysis | — |
| 2. Unit | Mathematical correctness + contracts + coverage ≥ 80% | Coverage report |
| 3. Simulacra | Parameter recovery from synthetic data + null controls | Simulacra report (PDF) + marks (YAML) + visualizations (HTML) |
| 4. Integration | Full pipeline via Docker simulacrum stack + BDD features | Integration results |
| 5. Regression | All results match baseline oracle within tolerance | — |
| 6. R CMD check | Package validation (no errors, warnings, or notes) | Check report |
| 7. Pages | Verify + commit regenerated visualizations to `docs/` (served via legacy branch deployment from `main/docs`) | [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/) |

---

## Data

All data files are bundled in `data/` with provenance documented in [`data/README.md`](data/README.md) (YAML format). Sources include NCBI GenBank (plastome sizes, phylogenies), Bobay & Ochman (2017) Table S1 (niche breadth data), Dewar et al. (2024) supplementary (pan-genome data), and Good et al. (2017) (LTEE metagenomic data).

---

## Repository Structure

```
valence.foundry/
├── R/                    Pure functional library (12 files, 30+ exported functions)
├── tests/                Test suite (18 files, 267 test cases)
├── baseline/             Ground truth oracle (YAML — human-readable)
├── data/                 Bundled datasets with provenance
├── inst/simulacra/       Synthetic data generators (5 files)
├── inst/examples/        Literate analysis reports (R Markdown)
├── vignettes/            Package vignettes (foundry + toy models)
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

---

## Authors

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript under review, *"A Trajectory Account of Adaptive Evolution from Homo to the Wider Animal Kingdom"*. Jan is also an active contributor to this codebase.
- **[Edward Phillips](https://github.com/phosphene)** — Author and designer of the mathematics and the software implementations (the Phosphene R engineering standards, three-pillar separation, DFT axioms, STDD, and the foundry architecture itself).
- **FlowBot** — Helper agent: implementation, testing, CI/CD, and review support.

## License

MIT

## Related

- Manuscript under review: "A Trajectory Account of Adaptive Evolution from Homo to the Wider Animal Kingdom" (Jan Ritch-Frel, 2026)
- Phosphene R Standards: [`docs/standards/PHOSPHENE_R_STANDARDS.md`](docs/standards/PHOSPHENE_R_STANDARDS.md)
- Review evaluation standard: [`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md)
- Live visualizations: [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/)
- Review index: [`docs/review/README.md`](docs/review/README.md) — links to all 11 review documents
