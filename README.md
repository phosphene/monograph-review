# Monograph Review: Computational Test Infrastructure (`valence.foundry`)

**A complete, reproducible computational pipeline for evaluating the quantitative claims of a manuscript on trait loss and niche commitment — implemented in R, with every claim expressed as a testable function and every result traceable to its computational environment.**

---

## What This Is

The manuscript under review advances a specific thesis about evolution: when a lineage commits to a new niche — symbiosis, parasitism, or a culturally embedded existence — it does not lose traits at random or merely because selection on them has relaxed. Trait loss is *ordered*, and the ordering is governed by the relationship between each trait and the niche the lineage has entered.

The mathematical form of that claim is sharp. If ρ is the within-system correlation between a trait's metabolic dependency and whether it is retained, and θ is niche dependency, the manuscript predicts a **step function**:

```
ρ(θ) = ρ_sat · H(θ − θ*)
```

Zero-dependency traits are lost as if at random; any trait with non-zero connection to the new niche is retained; there is no gradient above the step. This signature distinguishes the thesis from its two standard competitors — relaxed selection and Muller's ratchet — both of which predict gradual or random loss rather than a step at the point of niche entry. The claim is substrate-independent: the same step should appear in bacterial endosymbionts, parasitic plants, island birds, and grammatical features across languages.

This repository is the computational machinery for testing that claim. It does three things, in a specific order:

1. **Formalizes the thesis as code.** Every claim is a pure, testable function with contract enforcement. There is no prose that cannot be traced to a function, and no function that cannot be traced to a claim (via numbered Remarks and Review Items that the test suite cites directly).
2. **Validates the methods against known truth.** Every statistical procedure — PGLS, exact permutation, biphasic model selection, cross-kingdom transfer — is first exercised on synthetic data with known ground truth, verifying parameter recovery and null control before it is ever pointed at real data.
3. **Reproduces the manuscript's reported results.** The repository bundles its data, pins a baseline oracle of every reported value, and re-runs the full pipeline against it under CI, so a result is only a result when it reproduces within numerical tolerance.

The code is an R package (`valence.foundry`). The testing strategy, the CI gates, and the reproducibility contract are described below.

---

## Method

This review is conducted under a small set of methodological commitments, all of which are standard practice in the empirical sciences and each of which has a named place in the literature.

**Claim-evidence conformance.** No claim exceeds its stated-and-tested conditions. A claim is either supported by conditions that are stated and tested, or it is not advanced (or is advanced only as proposed, explicitly marked untested). There is no third state. A claim that exceeds its tested conditions is an inferential error. This is the single standard under which the review is conducted; everything else in this section is an operational consequence of it.

**Complementarity as a realist axiom under test (Bohr).** The patterns reported here come from research programs that do not commute — different systems, different measures, different founding assumptions, no shared apparatus. They do not need to commute. The observation is naked: each apparatus registers something definite, and that registration does not carry any one theory's vocabulary. The representation is theory-laden: models, metrics, and instruments are built to their own frameworks. The strategy is never to fight over representations but to hold the naked observations side by side and let the pattern show itself. Anyone who re-runs the pipeline and re-represents the observations in their own vocabulary is welcome to; the conclusions they draw are theirs. *(Bohr, "Light and Life," 1932; genealogy in [`docs/review/bohr-complementarity-lineage.md`](docs/review/bohr-complementarity-lineage.md).)*

**Family-kinds discipline (boundary-challenged concepts).** The cross-domain concepts here — ordered loss, integration depth, niche commitment, substrate independence — are family-resemblance categories: present in many instances, not essential in all. They are defined operationally within each domain (a fitted biphasic model, a PGLS slope, a permutation ordering, a cross-kingdom transfer), and the cross-domain pattern is the family resemblance. A non-instantiating case is a *boundary probe*, not a refutation: it measures the domain of validity of the pattern rather than contradicting it. *(Wittgenstein 1953 → Beckner 1959 → Sokal & Sneath 1963 → … → Kull 2016; genealogy in [`docs/review/family-kinds-genealogy.md`](docs/review/family-kinds-genealogy.md).)*

These commitments are enforced operationally rather than asserted. The remainder of this README describes how.

---

## The Technical Implementation

### Inferential reasoning as code

The pipeline is organized so that each inferential step is a named, pure function with a declared contract:

- **Three-pillar separation.** Every analysis is decomposed into (A) data preparation — a pure function that validates inputs and outputs; (B) model fitting — seed-locked and deterministic given the same inputs; (C) result extraction — a pure function returning structured data. I/O is isolated to thin `main()` wrappers that never run under `source()`, only under `Rscript`.
- **Structured results (A6).** Functions that do work return a list of `values` and `metadata` (seed, sample size, convergence status, elapsed time). A function returning a bare number provides no evidence of what happened; a structured result lets a reviewer trace every number back to its computational conditions.
- **Manifest conformance (A3).** The pipeline is declared as a YAML manifest (`pipeline.yml`); a test verifies the actual pipeline matches it, so an added stage that is not declared fails CI.

### The means of empiricism

Testing probabilistic inference is the hard part, and the repository solves it with stochastic test-driven development (STDD):

- **Deterministic math** (log-likelihoods, matrix transforms, exact permutation enumeration) is tested with exact assertions: same input → same output, always.
- **Stochastic transitions** (sampling, bootstrap, permutation when exhaustive is infeasible) are tested under controlled seeds with three classes of assertion:
  - **Parameter recovery** — generate synthetic data from known parameters (θ*), run the pipeline, verify the recovered estimates (θ̂) fall within the credible interval of θ*. If the pipeline can recover known signal, it can be trusted to detect unknown signal.
  - **Null control** — generate synthetic data with no signal, run the pipeline, verify it does *not* recover. This tests specificity: the pipeline must not produce false positives.
  - **Distributional verification** — for conjugate models, compare empirical draws to analytical distributions (Kolmogorov–Smirnov).

The **simulacrum** is the bridge from synthetic to real data: a controlled environment with known test data where the pipeline is verified to produce correct results *before* it is pointed at data where the right answer is unknown. On real data you do not know the answer — that is why you are running the analysis — so the simulacrum is the only place a known baseline exists.

The **baseline oracle** (`baseline/oracle.yml`) records every manuscript-reported value as ground truth: the prediction, the competing hypothesis, the expected values with numerical tolerance, whether the result supports the thesis, and whether it distinguishes the thesis from the named competitor. The regression gate compares pipeline output to the oracle; divergence means either a code regression (fix it) or a genuine method improvement (update the oracle, with proof).

### Code as R code

All of the above is implemented as a standard R package:

- **Package layout.** `R/` (pure functional library), `tests/testthat/` (the gate suites), `baseline/` (oracle), `data/` (bundled datasets with provenance), `inst/simulacra/` (synthetic data generators), `vignettes/` (literate analyses), `docs/` (review + standards), plus the Docker simulacrum stack and CI.
- **Test pyramid.** Unit tests (pure math, contracts, deterministic — 0 ms, no filesystem) at the base; simulacra (parameter recovery + null control) and integration (real data through the full pipeline, oracle comparison) above; E2E via Docker at the top.
- **CI gates.** Seven gates, each depending on the previous: lint → unit (with ≥ 80% coverage enforced) → simulacra → integration → regression → `R CMD check` → Pages. A gate result is only a result once CI is green.

---

## How to Reproduce

Local R is available (see [Development Environment](docs/development-environment.md) for the R location, first-time setup, and current gate results).

```bash
# Clone and enter
git clone https://github.com/phosphene/monograph-review.git
cd monograph-review

# Install the package (see docs/development-environment.md for the R setup)
R CMD INSTALL --no-docs --no-multiarch --with-keep-source .

# Run all gates (unit → simulacra → integration → regression)
make all

# Or run individual gates
make unit          # Pure unit tests — mathematical correctness + contracts
make integration   # Full pipeline on real data
make regression    # Compare all results to the baseline oracle
```

> The canonical runner is `run_tests.R` (`Rscript run_tests.R <gate>`).
> CI pins its environment via the `rocker/tidyverse:4.5.3` container; local runs
> use the miniforge R plus `minpack.lm`. See [Development Environment](docs/development-environment.md).

---

## Key Results

Every value below is the manuscript-reported result, stored as ground truth in [`baseline/oracle.yml`](baseline/oracle.yml). The pipeline must reproduce these within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes the thesis from competitors? |
|------|-----------------|-----------|-----------------------------------|
| T1: Orobanchaceae PGLS | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts the same gradient |
| T3: Endosymbiont biphasic | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| T6: Gene-loss ordering | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| L3: Cross-kingdom transfer | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — substrate independence predicts no transfer |

**Live visualizations:** [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/) — simulacra parameter recovery, baseline oracle, key results, and four exploratory simulation models (threshold gate, irreversibility, the *Homo* inversion, cross-kingdom transfer), all with literate context.

---

## Documentation

The repository ships a complete review trail — every claim traced to its root cause, every algorithm surveyed with its prediction and competitor, every finding recorded as a numbered Remark or Review Item that the code cites directly. All documents are in [`docs/review/`](docs/review/) (see the [review index](docs/review/README.md) for the full list).

### Critical review

| Document | What it is |
|----------|-----------|
| [Manuscript review](docs/review/manuscript-review.md) | Critical review of the manuscript (v9) and the foundry artifacts. Numbered **Remarks** (R1–R7) and **Review Items** (1–6). The code cites these directly. |
| [Calculation review](docs/review/calculation-review.md) | Literate walkthrough of the calculation audit: for each oracle entry, the prediction, the broken output, the root-cause diagnosis, and the fix. |
| [Math review](docs/review/math-review.md) | Audit of the mathematics vs. the implementation vs. the claims (seven issues ranked by severity; two severe). All seven resolved by the three-phase refactoring. |
| [Refactoring plan](docs/review/refactoring-plan.md) | Execution plan for the math-review issues: proposed refactoring, blast radius, risk, and three-phase ordering (safest-first). Status: COMPLETE. |

### Genealogies

| Document | What it is |
|----------|-----------|
| [Family-kinds genealogy](docs/review/family-kinds-genealogy.md) | The definitory-apparatus lineage: Wittgenstein (family resemblance, 1953) → Beckner (polytypic classes, 1959) → Sokal & Sneath (operational polythetic groups, 1963) → Mayr → Ghiselin → Paterson → Templeton → de Queiroz → Pigliucci → Kunz → Kull (semiotic species, 2016). Why boundary-challenged concepts are handled as family-resemblance categories and non-instantiating cases as boundary probes. |
| [Complementarity lineage](docs/review/bohr-complementarity-lineage.md) | The epistemology: Bohr (Light and Life, 1932) → Delbrück → Elsasser/Pattee/Rosen/Stent. Observation is naked, representation is theory-laden, programs need not commute. |
| [fit_biexp numerical challenges](docs/review/fit-biexp-numerical-challenges.md) | The operational enforcement of claim-evidence conformance in the relaxation fitter: the ill-conditioning, the seed-fragile mono/bi boundary, the biphasic-flag guard, and the degenerate-sampling/noise boundaries as boundary probes. Reproducible via `scripts/validate_fit_biexp.py`. |

### Build history and synthesis

| Document | What it is |
|----------|-----------|
| [Phased breakdown](docs/review/foundry-phased-breakdown.md) | Phase-by-phase breakdown of the build, current gate status, and the open data-reconciliation work (items 4–6). |
| [Algorithms & findings](docs/review/algorithms-and-findings.md) | Formal literate survey of every algorithm, its prediction, its competitor, and a plain-language reading of the current result. The synthesis of what the foundry establishes, what it does not, and what that means for the thesis. |

### Modeling, data, and the empirical frontier

| Document | What it is |
|----------|-----------|
| [Modeling, sim & viz review](docs/review/modeling-sim-viz-review.md) | Review of the author's existing modeling (finds the original empirical GLM was broken by a data-flattening bug; the foundry hid this with a theoretical simulation). Evaluation of the sim/viz infrastructure (three latent viz bugs found and fixed). Proposal for a speculative simulation capacity. |
| [Formal model reproduction](docs/review/formal-model-reproduction.md) | Deep-dive reproduction of the broken GLM. **Root cause:** `as.vector(t(retention))` misaligns dep and retention. **Fix:** remove one `t()`. The corrected additive GLM gives dep = +0.84 (p = 0.0008), para p < 0.0001, cross-kingdom ρ = +0.755 — all matching the thesis's prediction. Recorded as **Remark R7**. |
| [Empirical-testing expansion plan](docs/review/empirical-testing-expansion-plan.md) | Proposal for moving the three "testable but not yet tested" modules (the *Homo* inversion, cusp irreversibility, cross-kingdom transfer) toward tested. Honest about the data boundary. |
| [Exploratory models plan](docs/review/toy-models-plan.md) | Execution plan for the speculative simulation capacity: four phased exploratory models that make the thesis's predictions explorable without claiming empirical test. Status: COMPLETE — all 4 models built, tested, and documented. |

---

## Glossary

### Framework Terms

**Niche commitment** — The thesis's core claim: when a lineage enters a niche, the environment begins providing what the lineage's traits once supplied, and the traits erode. The erosion is not random and not merely a relaxation of selection; it is ordered by the relationship between each trait and the niche.

**Integration depth** — A trait's position in the functional architecture of an organism. Traits that participate in many developmental pathways (e.g., ribosomal RNA genes) have high integration depth; traits serving a single function (e.g., NADH dehydrogenase in non-photosynthetic parasites) have low integration depth. The thesis predicts that high-integration-depth traits resist loss during capacity reallocation.

**Step function / threshold gate** — The distinguishing signature of the thesis: final retention is a step function of integration depth, with protected traits at 1.0 and unprotected traits at 0. The gate is at the zero-vs-nonzero boundary of dependency, not at some intermediate threshold. This is the prediction that relaxed selection and Muller's ratchet do not make.

**Capacity reallocation** — The process by which an organism shedding traits (due to niche commitment) preferentially loses low-integration-depth functions first, reallocating the saved maintenance budget to the remaining high-integration-depth functions. This produces an ordered pattern of trait loss, not random loss.

**Substrate independence** — The thesis's claim that the step function holds across substrates — bacteria, plants, animals, language — because the underlying principle (ordered loss by niche relationship) does not depend on the kingdom. Tested most strongly by cross-kingdom parameter transfer: parameters estimated on one kingdom applied to another without refitting.

**The *Homo* inversion** — The observation that the *Homo* lineage shows positively diversity-dependent speciation (more species over time), the inverse of the standard pattern in most clades (negatively diversity-dependent, or niche-filling). The thesis explains this via the cultural substrate's autocatalytic dynamics.

### Statistical Methods

**PGLS (Phylogenetic Generalized Least Squares)** — A regression method that corrects for the non-independence of species due to shared evolutionary history. Without PGLS, correlations between traits across species can appear significant simply because closely related species share traits by descent, not because of a real functional relationship. PGLS uses a phylogenetic tree and a parameter (λ) that measures the strength of phylogenetic signal in the residuals.

**Exact permutation test** — A non-parametric significance test that enumerates all possible orderings of the data to compute a p-value. For 6 items, there are 720 permutations (6! = 720), small enough to compute exactly. The p-value is the proportion of permutations that produce a test statistic at least as extreme as the observed one. Preferred over asymptotic approximations when sample sizes are small.

**Biphasic kinetics** — A pattern of change with two distinct rates: a fast phase followed by a slow phase. In genome reduction, this means rapid initial gene loss (Phase 1, unprotected traits) followed by slow loss (Phase 2, protected traits). The mathematical signature is a logistic (saturation) curve, distinguishable from a linear (constant-rate) or exponential (accelerating) curve via model selection (ΔAICc).

**Cross-kingdom parameter transfer** — A test where parameters estimated on data from one biological kingdom (e.g., plants) are applied to data from another kingdom (e.g., birds) without refitting. If the ordering transfers, the underlying principle is substrate-independent. This is the strongest test in the manuscript because it controls for kingdom-specific confounds.

**Bayes Factor (BF)** — A ratio of marginal likelihoods comparing two statistical models. BF > 6 is moderate evidence for the numerator model; BF > 10 is strong. Here, BF compares the biphasic (logistic) model to the constant-rate (exponential) model.

### Software Engineering Terms

**Three-pillar separation** — Every analysis is decomposed into three pillars: (A) data preparation — pure function, validates inputs and outputs; (B) model fitting — seed-locked, deterministic given the same inputs; (C) result extraction — pure function, returns structured data. I/O is isolated to thin wrapper functions called `main()`, which never runs when the file is `source()`d — only when executed via `Rscript`.

**DFT axioms (Design For Testability)** — Six principles adapted from production software engineering for scientific code:

- **A1 — Pure IO separation**: Statistical logic never touches the filesystem, network, or databases. I/O is isolated to thin loader functions, making the mathematical core testable in zero milliseconds with inline data.
- **A2 — Determinism**: No `set.seed()` hidden inside logic functions. The random seed is injected by the caller, making every stochastic operation reproducible. Cross-platform reproducibility requires specifying the RNG algorithm (`Mersenne-Twister`) and normal inversion method (`Inversion`) explicitly.
- **A3 — Manifest conformance**: The analysis pipeline is declared as a YAML manifest (`pipeline.yml`); tests verify the actual pipeline matches the manifest.
- **A4 — Documentation**: Every source file declares its testability contract in a `@dft` roxygen2 block.
- **A5 — Real in-process fakes**: Instead of mocking `read.csv()` with a stub, a `FakeDataLoader` returns real dataframes from in-memory fixtures — data your logic can actually process.
- **A6 — Check-result**: Functions that do work return a structured result: `values` + `metadata` (seed, sample size, convergence status, elapsed time).

**STDD (Stochastic Test-Driven Development)** — Standard TDD breaks on probabilistic code: `expect_equal(mcmc_draw, 1.234)` is meaningless because the output varies with seed, data, and platform. STDD decouples deterministic math from stochastic transitions: deterministic functions get exact assertions; stochastic transitions get parameter-recovery, null-control, and distributional assertions under controlled seeds.

**Simulacrum** — A controlled environment with known test data where the pipeline is verified to produce correct results before being run against real data. The simulacrum is the only place where a known baseline exists; on real data you do not know the right answer — that is why you are running the analysis.

**Baseline oracle** — A YAML file ([`baseline/oracle.yml`](baseline/oracle.yml)) containing every manuscript-reported result as ground truth: the prediction, the competing hypothesis, expected values (with tolerance), whether the result supports the thesis, whether it distinguishes the thesis from the competitor, and caveats. The regression gate compares pipeline output to the oracle.

### Biological Terms

**Orobanchaceae** — The broomrape family, a clade of parasitic plants spanning the full gradient from autotrophic (full plastome) to extreme holoparasitic (severely reduced plastome). This gradient makes it the primary test system for the integration-depth predictions.

**Endosymbiont** — A bacterium living inside a host cell in a permanent, obligate symbiosis. Examples: *Buchnera* (aphid), *Wigglesworthia* (tsetse fly), *Carsonella* (psyllid), *Blochmannia* (ants). These bacteria undergo severe genome reduction over evolutionary time, making them a test system for the biphasic-kinetics prediction.

**LTEE (Long-Term Evolution Experiment)** — Richard Lenski's ongoing experiment (since 1988) tracking 12 populations of *E. coli* over 75,000+ generations. Used here to test whether metabolic function loss co-segregates with beneficial mutations (the drift prediction) or is independently assorted (the competitor's pleiotropy prediction).

**NCC (Neural Crest Cell)** — A population of migratory embryonic cells in vertebrates that give rise to facial morphology, pigmentation, and parts of the nervous system. NCC-derived traits are predicted to change early in domestication because they have low integration depth.

### Data Structures

**Mark (simulacrum mark)** — A structured YAML entry logged during a simulacrum run, capturing: the true parameters (the vertex in parameter space being tested), the recovered parameters (where the pipeline landed), whether recovery succeeded (within credible interval), the null control result, and the random seed. Marks can be projected into 2D visualizations: true vs recovered scatter plots, recovery trajectories, parameter-space projections, and rolling recovery-rate plots.

**Structured result (DFT axiom A6)** — The standard return value of every function in this package: `values` (named numeric vector) + `metadata` (seed, sample size, convergence status, elapsed time).

---

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

- **38 test files** covering the full suite
- **9 simulacra** — each generates synthetic data with known ground truth, runs the pipeline, verifies parameter recovery, and confirms the null control does NOT recover (specificity)
- **Baseline oracle** — YAML ground truth for every manuscript value, compared within numerical tolerance
- **5 BDD feature files** — statistical contracts in Gherkin (same seed → same output, pipeline idempotency, numerical stability, parameter recovery)
- **Coverage gate** — minimum 80%, enforced in CI
- **Current full-suite status** — 8,417 assertions passing, 0 failing, 11 skipped (the 11 skips are the known data-reconciliation items, tracked in the review)

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
| 7. Pages | Verify + commit regenerated visualizations to `docs/` | [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/) |

---

## Data

All data files are bundled in `data/` with provenance documented in [`data/README.md`](data/README.md) (YAML format). Sources include NCBI GenBank (plastome sizes, phylogenies), Bobay & Ochman (2017) Table S1 (niche breadth data), Dewar et al. (2024) supplementary (pan-genome data), and Good et al. (2017) (LTEE metagenomic data).

---

## Repository Structure

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

---

## Authors

- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the manuscript under review and an active contributor to this codebase.
- **[Edward Phillips](https://github.com/phosphene)** — Author and designer of the mathematics and the software implementations (the R engineering standards, three-pillar separation, DFT axioms, STDD, and the foundry architecture itself).
- **FlowBot** — Helper agent: implementation, testing, CI/CD, and review support.

## License

MIT

## Related

- Manuscript under review (Jan Ritch-Frel, 2026)
- R engineering standards: [`docs/standards/PHOSPHENE_R_STANDARDS.md`](docs/standards/PHOSPHENE_R_STANDARDS.md)
- Review evaluation standard: [`docs/review/review-evaluation-standard.md`](docs/review/review-evaluation-standard.md)
- Live visualizations: [https://phosphene.github.io/monograph-review/](https://phosphene.github.io/monograph-review/)
- Review index: [`docs/review/README.md`](docs/review/README.md) — links to all 11 review documents
