# Simulation as an Instrument — Genealogy and Practice (Working Notes)

**Namespace:** lower — working notes behind the public documentation. This
document records the intellectual lineage of *fabricated data used to test
inferential machinery*, the best-practice commitments that lineage entails as
known in the literature and as applicable to R, and an honest measurement of
where the foundry's own practice sits in that lineage. It is the methodological
record behind the self-calibration work program (see
[`self-calibration-tickets.md`](self-calibration-tickets.md)). It is not part
of the public top level; the root [`README`](../../README.md) indexes the
review trail and this document is one working-note entry in it.

---

## 1. Why record this

The review's content-genealogy is written down (Darwin → Wisdom, in the
Tradition section; Ockham → Darwin → Popper → Beck in the principles lineage;
Ising → Landau → cusp → relaxation in the mathematics lineage). But the review
*fabricates data* — the simulacrum, STDD, the null controls — and that practice
has its own genealogy, distinct from the content it tests. The foundry's
simulation practice descends from a named tradition whether we have said so or
not. This document says so, and then measures the foundry against the
discipline that tradition has accumulated.

The point is not historical completeness. It is that the discipline is
**load-bearing**: each stage of the lineage added a specific obligation that
our own simulation practice must meet, and most of those obligations are
currently unmet. Naming them makes the gap legible, which is the precondition
for ticketing it (Ed Phil, 2026-08-30).

---

## 2. The genealogy of fabricated data as an instrument

### 2.1 Randomization (Fisher, 1925–35) — the null as generated data

Fisher's contribution to simulation is usually read as experimental design:
randomize the experiment. But the deeper move was epistemic — **you can
generate the distribution of a test statistic under the null by reordering the
data you already have.** Randomization justifies the *permutation* argument:
the observed statistic is one draw from a distribution of statistics over all
reorderings, and its extremity is its p-value. Pitman (1937) made this
explicit as a test procedure. Every null-control test the foundry writes is a
direct descendant: shuffle / permute / reorder, and ask where the observed
value falls.

**Obligation added:** a null must be *generated*, not assumed. If we cannot
produce the null distribution by rearrangement or simulation, we have not
specified what "no effect" means.

### 2.2 Monte Carlo (Metropolis & Ulam, 1949) — the computer as probability engine

The electronic computer became a probability engine: fabricate the data the
theory says should occur, and estimate by frequency what cannot be derived by
integration. This is synthetic data in the strong sense — data generated from
the *model*, not the world — and it converts an intractable integral into a
counting problem. Every `generate_*` function in `inst/simulacra/` is a
Monte Carlo generator.

**Obligation added:** a forward model must be runnable. If we cannot generate
from the model, we do not actually possess the model as a computing object.

### 2.3 Boxian model checking (Box, 1976; 1979) — simulation as the checking mechanism

"All models are wrong" is usually quoted as pessimism; Box's actual program
was constructive — **simulate from your model, and compare the predicted
distribution to the observed.** The prior predictive check is the first
systematic "does my machinery behave as it claims" procedure, and it is
*calibration by simulation*, not by optimism. Box (1979) is the canonical
statement: robustness and criticism both proceed by confronting model output
with what the world (or the known generating process) actually does.

**Obligation added:** a model must be checked *against its own predictions*,
on data where the answer is known, before it is trusted where the answer is
unknown. This is the obligation the simulacrum concept operationalizes.

### 2.4 Bootstrap (Efron, 1979) — resampling as inference

The bootstrap is the mirror image of Monte Carlo: instead of generating from a
model, **resample from the empirical distribution you have**, treating it as
if it were the truth (the plug-in principle). The parametric bootstrap draws
from a *fitted* model to study the estimator's own sampling distribution. This
is where fabricated data becomes a *method-design* tool: the target is not a
hypothesis about the world but the behavior of the estimator itself.

**Obligation added:** an estimator's uncertainty is itself estimable by
simulation from the fitted object — and if the estimator's sampling
distribution is only ever asserted, never simulated, it is unexamined.

### 2.5 Null models in ecology and comparative biology (Gotelli & Graves, 1996; Manly, 1997/2007)

The empirical domains the foundry works in grew up on this practice: randomize
traits across phylogenies, randomize niches, randomize association matrices,
and ask whether the observed pattern is extreme relative to the ensemble.
Gotelli & Graves made the null model a first-class object — a constrained
randomization whose construction *encodes the hypothesis being tested*.
Comparative biology's native testing practice, and the direct ancestor of what
the foundry's simulacra do with PGLS and gene-loss ordering.

**Obligation added:** the null model's randomization scheme is itself a
model choice; it must be stated and defended, not defaulted.

### 2.6 Simulation-based inference (ABC, synthetic likelihood) — forward simulation as likelihood

Approximate Bayesian Computation (Pritchard et al. 1999; Beaumont et al. 2002)
made simulation *inferential*: when the likelihood is intractable, simulate
forward from parameters, keep the simulations that match the observed summary,
and the retained parameters approximate the posterior. Synthetic likelihood
(Wood, 2010) fits a Gaussian to simulated summary statistics. The significance
for the foundry is architectural: **the generator is the likelihood**, so a
well-built generator is not an add-on to inference — it is the instrument of
inference itself.

**Obligation added:** if a model can be simulated, it can be fit — the
generator and the estimator are one system and must be tested as such.

### 2.7 Simulation-Based Calibration (Cook, Gelman & Rubin, 2006; Talts et al., 2018) — the pipeline-level check

SBC is the gold standard for "is my inferential machinery calibrated." The
procedure: draw θ from the prior, simulate data from θ, fit the posterior, and
record the rank of the true θ under the posterior. If the machinery is
calibrated, the ranks are uniform. This is a **joint** check over prior × data
× posterior — not a per-function check. Talts, Betancourt, Simpson, Vehtari &
Gelman (2018) sharpened it into the rank-uniformity diagnostic with a
computed expected band. It detects exactly the silent failure mode the
foundry's regression gate exists to prevent: machinery that *looks* fine on a
few hand-picked cases but is systematically miscalibrated.

**Obligation added:** any pipeline that produces intervals or posteriors must
be rank-calibrated on simulated data before those intervals are trusted on
real data.

### 2.8 Simulation studies as designed experiments (Burton et al., 2006; Koehler, Brown & Haneuse, 2009; Morris, White & Crowther, 2019)

The meta-layer. A simulation study is itself an experiment with aims,
**data-generating mechanisms (DGMs)**, estimands, performance measures, and —
critically — **Monte Carlo error** (Koehler, Brown & Haneuse, 2009): the
standard error of a simulated performance measure, which sets the number of
replications as a design choice, not a habit. Morris, White & Crowther (2019)
is the canonical modern handbook: "Using simulation studies to evaluate
statistical methods," with the ADEMP structure (Aims, Data-generating
mechanisms, Estimands, Methods, Performance measures). A simulation study that
does not declare its ADEMP structure and does not report MCSE is not yet a
designed experiment.

**Obligation added:** a simulation study is declared (aims, DGM, estimand,
methods, performance measures) and its results carry Monte Carlo error. This
is the direct generalization of the foundry's manifest conformance (A3) from
the pipeline to the calibration layer.

### 2.9 Declared designs (Blair, Cooper, Coppock & Humphreys; DeclareDesign, 2019)

The R formalization of 2.8: `declare_population()` → `declare_estimand()` →
`declare_estimator()` → `diagnose_design()`. A design is a declared object;
diagnosis (bias, power, coverage, type-I error) is an automatic consequence of
declaring it. This is the modern, package-native statement of the obligation
Burton/Morris added — and it is directly implementable in the foundry's
existing manifest-and-gate architecture.

### 2.10 R-native tools for the practice

The discipline has package-native R support, which is the operational
translation of the lineage:

- **RNG control:** `set.seed` + `RNGkind()` (Mersenne-Twister, Inversion for
  cross-platform normal draws); `withr::with_seed()` for localized, auto-
  teardown seed isolation — already the foundry's STDD wrapper basis
  (`stdd_seed_env`).
- **Generators as data:** `simstudy` (Goldfeld & Wujciak-Jens) and
  `fabricatr` (Blair, Coppock, Humphreys) — declarative DGM construction;
  `DeclareDesign` for the design-as-object layer.
- **Phylogenetic simulation** (the foundry's domain): `geiger::sim.char`,
  `phytools` (`fastBM`, `OUCH`), `mvMORPH` — simulate traits on a real tree
  under BM, OU, λ-transformed models, and check recovery. These give the
  foundry ready-made DGM diversity for PGLS validation, including
  λ-contamination (the exact PGLS failure mode a robustness battery wants).
- **Statistical primitives:** `stats::simulate()`, `replicate`, `boot`
  (Canty & Ripley), and the permutation tooling the foundry already uses for
  exact tests.

---

## 3. Best-practice commitments (the discipline we adopt)

From the genealogy, stated as commitments the foundry's simulation practice
undertakes. Each is a hypothesis about our own method, to be enforced by the
calibration battery (ticketed in `self-calibration-tickets.md`).

- **C01 — DGM as factorial design.** Recovery and error behavior are functions
  of DGM × effect size × n × noise. A single-condition simulacrum cannot
  characterize an estimator; the sweep is the unit of characterization.
- **C02 — Type-I error is measured, not assumed.** Under each null, the
  estimator must reject at its nominal α, with the observed rate within MCSE
  of α, and p must be uniform under the null.
- **C03 — Discriminating claims are enforced, not annotated.** A claim that
  distinguishes the framework from a competitor holds only if the method
  *fails* to recover framework signal from competitor-generated data (and
  recovers it from framework-generated data). The oracle's
  `distinguishes_from_competitor` flags must become enforced tests.
- **C04 — Misspecification is swept, not discovered by luck.** A method whose
  assumptions are violated must degrade detectably (flag or metadata), not
  silently mislead. Violations are generated deliberately, per assumption.
- **C05 — Common random numbers.** Comparisons between conditions are more
  precise when noise draws are shared where legitimate (correlated noise
  isolates the contrast); independent draws inflate MCSE of the difference.
- **C06 — Monte Carlo error is reported.** Every simulated performance measure
  carries MCSE; replication counts are set by target precision (e.g. ≥1,900
  reps to resolve a 0.05 rate to ±0.005), not by habit.
- **C07 — Intervals are rank-calibrated.** Any pipeline producing intervals or
  posteriors passes an SBC rank-uniformity check on simulated data.
- **C08 — Designs are declared.** The calibration layer has a declared ADEMP
  structure and a manifest-conformance check, generalizing the pipeline
  manifest (A3).

These are deliberately phrased as *principles under test*: each is a
hypothesis about our own instrument, and each has a defined experiment that
would establish or refute it. That is the hypothetico-axiomatic form the work
program uses (see the tickets document).

---

## 4. Where the foundry stands in this lineage (measured)

### Already earned

- **The simulacrum concept** — controlled environment with known truth before
  touching unknown data — is the designed-simulation-study ethos, made
  CI-enforceable. This is genuinely good practice, ahead of most research
  repos.
- **STDD's three classes map cleanly onto the lineage:** parameter recovery
  (= Monte Carlo / ABC forward-check), null control (= Fisher permutation /
  null-model logic), distributional verification / KS (= Boxian checking).
- **Determinism discipline:** pure generators (A1), seed-locked (A2),
  structured results (A6) — the `generate_*` functions are textbook
  `withr::with_seed` generators.
- **Oracle + regression gate** — performance measures locked against code
  regression (the Morris/White/Crowther "performance measures" idea made
  permanent).

### Not yet earned (measurable against Morris/White/Crowther, SBC, Koehler)

- **No factorial DGM sweep** — no power curves, no minimum detectable effect
  at the foundry's real sample sizes (n = 12, n = 15, n = 8). Single-condition
  simulacra only.
- **Replication counts too small for calibrated error rates** — the ~100-rep
  simulacra cannot resolve a type-I rate at all; no MCSE in the marks.
- **No misspecification battery** — the T3 cross-sectional confound (R6) was
  found by *inspecting real data*, the slow way; a DGM-violation sweep would
  have found it systematically, and would prevent silent recurrence.
- **No SBC / rank-uniformity check** on the interval-producing pipeline
  (the GLM CIs, the PGLS CIs, any bootstrap CIs the cultural module adds).
- **No common-random-numbers discipline** across the comparing simulacra
  (framework vs competitor, model A vs B).
- **`distinguishes_from_competitor` flags are annotations, not tests.** The
  oracle declares them; nothing generates competitor data and asserts failure
  to recover.
- **A disabled invariants suite and an archive of extracted edge probes**
  (see tickets E2, E3) are exactly the latent calibration material the battery
  should absorb.

### The honest summary

The foundry has the *structure* of a mature simulation practice and sits early
on the *statistical-design* axis. It can fabricate data (Monte Carlo, 1949);
it cannot yet fabricate data *designed to test its own method's calibration*
(SBC, 2018; Morris/White/Crowther, 2019). The calibration battery completes
the descent.

---

## 5. The Wisdom symmetry

There is a structural identity worth recording because it ties the method
genealogy to the review's own tradition (Darwin → Wisdom) stated twice.

Wisdom's principle — **observation is the production of conditions** — is
exactly what synthetic data *is*: you manufacture the conditions under which a
statement is supposed to hold, and then you observe whether it holds.
Darwin's earthworms are the naturalist's data-generating mechanism: the worm
box, the observed inputs and outputs, no extra causal ingredient. The
simulacrum is the mechanized worm-box — the production of conditions under
which the foundry's estimators are supposed to recover known truth, and the
observation of whether they do.

So the content-genealogy (Darwin → Wisdom: infer no more than the observation
licenses) and the method-genealogy (Fisher → Morris: fabricate the conditions
and observe) are **the same lineage, stated twice** — one in the naturalist's
register, one in the statistician's. The calibration battery is not an
imported procedure; it is the completion of the review's own commitment, in
the form the tradition requires. This is recorded here, in the lower
namespace, because it is working-note reasoning about our own practice — it
does not belong at the public top level.

---

## 6. Source trail

- Fisher, *Statistical Methods for Research Workers* (1925); *The Design of
  Experiments* (1935) — randomization and the generated null.
- Pitman, "Significance tests which may be applied to samples from any
  populations" (1937) — permutation tests.
- Metropolis & Ulam, "The Monte Carlo method" (1949).
- Box, "Science and statistics" (1976); "Robustness in the strategy of
  scientific model building" (1979).
- Efron, "Bootstrap methods" (1979).
- Gotelli & Graves, *Null Models in Ecology* (1996); Manly, *Randomization,
  Bootstrap and Monte Carlo Methods in Biology* (2nd ed. 1997, 3rd ed. 2007).
- Pritchard et al., "Population growth of human Y chromosomes" (1999);
  Beaumont, Zhang & Balding, "Approximate Bayesian computation in population
  genetics" (2002).
- Wood, "Statistical inference for noisy nonlinear ecological dynamic
  systems" (2010) — synthetic likelihood.
- Cook, Gelman & Rubin, "Validation of software for Bayesian models using
  posterior quantiles" (2006); Talts, Betancourt, Simpson, Vehtari & Gelman,
  "Validating Bayesian inference algorithms with simulation-based
  calibration" (2018).
- Burton, Altman, Royston & Holder, "The design of simulation studies in
  medical statistics" (2006); Koehler, Brown & Haneuse, "On the choice of the
  number of Monte Carlo runs" (2009); Morris, White & Crowther, "Using
  simulation studies to evaluate statistical methods" (2019) — the ADEMP
  structure.
- Blair, Cooper, Coppock & Humphreys, *DeclareDesign* / "Declaring and
  diagnosing research designs" (2019).
- Goldfeld & Wujciak-Jens, *simstudy*; Blair, Coppock & Humphreys,
  *fabricatr* — R-native DGM construction.
- Harmon et al., *geiger*; Revell, *phytools*; Clavel et al., *mvMORPH* —
  phylogenetic simulation.
- Wisdom, *Foundations of Inference in Natural Science* (1952) — observation
  as the production of conditions (see the Tradition section at the public top
  level; the working detail stays here).
