# Self-Calibration Work Program — Ticketed (Working Notes)

**Namespace:** lower — the work breakdown for turning the simulation
genealogy ([`simulation-genealogy-and-practice.md`](simulation-genealogy-and-practice.md))
on ourselves. Every ticket is stated in the review's hypothetico-axiomatic
form: a **hypothesis** about our own instrument, a **formalization**
(implementation), and the **establishment under test** — the observable
consequences that would confirm or refute the hypothesis (Braithwaite,
*Scientific Explanation*, ch. VI). A ticket is done only when its exit gate
is green.

**Author:** Ed Phillips + Flow (recorded 2026-08-30).
**Status:** Proposal — awaiting go/no-go, one ticket at a time, C-series
first.

---

## How to read a ticket

Each ticket is one principle under test:

- **Hypothesis (principle under test)** — the claim about our own method,
  stated as a testable proposition. Not a description of work; the claim the
  work would establish.
- **Formalization (implementation)** — what gets built.
- **Establishment under test** — the concrete assertions / artifacts that
  would establish the hypothesis. If the assertions fail, the hypothesis is
  refuted (the method is not calibrated) and we have learned something about
  our instrument.
- **Tasks** — the individual units of work.
- **Exit gate** — the CI-verifiable condition of done.
- **Depends on** — ordering.

Two series:

- **C-series (calibration)** — the statistical-design layer: sweeping,
  calibrating, falsifying, and rank-checking our own estimators. C1–C8.
- **E-series (engineering)** — concrete gaps the lens exposes in the existing
  codebase: coverage, a disabled invariants suite, and an archive of extracted
  edge probes. E1–E3.

Already-planned work in the
[`empirical-testing-expansion-plan.md`](empirical-testing-expansion-plan.md)
(L3 wiring, drop-in empirical hooks, magnitude metrics) is referenced where it
feeds the battery; it is not re-ticketed here.

---

## Summary

| ID | Principle under test (abbreviated) | Module | New? |
|----|-------------------------------------|--------|------|
| C1 | Recovery is a function of DGM × effect × n × noise; the sweep is the unit of characterization | calibration harness | new |
| C2 | Type-I error equals nominal α within MCSE; p uniform under null | all estimators | new |
| C3 | Discriminating claims hold iff competitor data fails to recover | oracle flags | new |
| C4 | Violated assumptions degrade detectably, not silently | DGM-violation battery | new |
| C5 | Shared noise draws sharpen comparisons | comparing simulacra | new |
| C6 | MCSE is reported; replication count set by precision | marks / logging | new |
| C7 | Intervals are rank-calibrated (SBC) | GLM / PGLS / bootstrap CIs | new |
| C8 | Calibration layer has a declared ADEMP structure + manifest conformance | manifest | new |
| E1 | ≥80% unit coverage binds on all shipped modules | `p_series_a_priori`, `dynamics_classes`, `formal_model_classes`, `test_registry` | fix |
| E2 | Property-based invariants are a permanent guard, not a disabled file | `test-invariants-empirical.R.disabled` | revive |
| E3 | Extracted edge probes are absorbed into the battery or retired, not archived in limbo | `tests/testthat/_problems/` | triage |

---

## C-series — calibration

### C1 — Factorial DGM sweep (power curves and minimum detectable effect)

- **Hypothesis.** Each estimator's recovery and error behavior is a monotone,
  quantifiable function of effect size × sample size × noise. A
  single-condition simulacrum cannot characterize an estimator; therefore the
  foundry currently does not know the minimum detectable effect at its real
  sample sizes (n = 12, n = 15, n = 8), which is the precondition for reading
  any empirical result's meaning.
- **Formalization.** A `calibration/` suite: a common sweep driver
  `sweep_design()` that takes a generator, a grid of (effect, n, noise), and a
  statistic, and returns a tidy tibble of estimates + metadata (seed, MCSE,
  converged). Reuses the existing `inst/simulacra/*` generators (A1/A2) —
  no new math.
- **Establishment under test.** For each estimator (PGLS slope/λ, bi-exp vs
  mono ΔAICc/BF, gene-loss ρ, transfer bird-ρ, cusp loop area, autocatalytic
  DD sign): power curves rendered; power monotone in effect and n (asserted);
  the smallest effect recoverable at the foundry's actual n with power ≥ 0.8
  reported in `results/calibration/`.
- **Tasks.** (1) Define sweep-grid schema. (2) Implement `sweep_design()`.
  (3) Wire each generator. (4) Power-curve renders. (5) Assertions +
  gate file `tests/testthat/test-calibration-sweep.R`.
- **Exit gate.** CI gate `calibration` green; power curves committed;
  minimum-detectable-effect table in `results/`.
- **Depends on.** —
- **Blast radius.** New directory + new gate. No existing code touched.

### C2 — Type-I error calibration (null rejection at nominal α)

- **Hypothesis.** Under each null, the estimator rejects at its nominal α:
  the observed rejection rate is within Monte Carlo error of α, and p is
  uniform under the null. If the foundry's null controls pass at ~100 reps,
  that proves nothing about α — the rate is unresolvable at that n.
- **Formalization.** Run each existing null DGM at an MCSE-targeted
  replication count (≥1,900 reps for a 0.05 rate to ±0.005, per C6), record
  empirical rejection rate and p-values.
- **Establishment under test.** For each test statistic: empirical rejection
  at α = 0.05 ∈ [0.04, 0.06]; p-value uniformity passes a KS test; both
  reported with MCSE.
- **Tasks.** (1) Inventory null generators. (2) Replication-count design
  (C6). (3) Uniform-p harness. (4) Assertions + gate.
- **Exit gate.** Type-I table in `results/calibration/`; gate green.
- **Depends on.** C1 (harness), C6 (MCSE).
- **Blast radius.** New tests; existing null controls reused, not rewritten.

### C3 — Competitor-generative falsification (enforce `distinguishes_from_competitor`)

- **Hypothesis.** A claim discriminates the framework from a named competitor
  iff the method *fails* to recover framework signal from data generated by
  the competitor's process, and *does* recover it from data generated by the
  framework's process. The oracle's `distinguishes_from_competitor` flags are
  currently annotations; an annotation is not a test.
- **Formalization.** Competitor DGMs per discriminating test — constant-rate /
  accelerating (ratchet) for biphasic (T3), random loss for ordering (T6),
  independent slopes for transfer (L3), drift-only for niche-vs-Ne (T4),
  Ne-only for fluidity (T5) — plus a `falsification_contrast()` that runs the
  method on both framework-DGM and competitor-DGM data and asserts the oracle
  flags.
- **Establishment under test.** For every oracle entry with
  `distinguishes_from_competitor: true`: competitor data → no framework
  signal recovered; framework data → signal recovered. The flags move from
  annotation to enforced regression entries (ties into expansion-plan Phase 4).
- **Tasks.** (1) Competitor DGM per test. (2) `falsification_contrast()`.
  (3) Oracle-flag enforcement. (4) Gate file.
- **Exit gate.** All discriminating flags enforced and passing; a
  competitor-DGM regression entry for each.
- **Depends on.** C1.
- **Blast radius.** New generators + new gate; oracle flags become enforced.

### C4 — Misspecification robustness (DGM-violation battery)

- **Hypothesis.** A method whose assumptions are violated must degrade
  detectably — flag in metadata, fail convergence, or degrade predictably —
  never silently mislead. The T3 cross-sectional confound (Remark R6) was
  found by inspecting real data; a deliberate violation sweep finds it
  systematically and prevents silent recurrence.
- **Formalization.** A DGM-violation battery: cross-sectional confound (T3's
  design), λ misspecification (PGLS), heteroskedastic / non-normal residuals,
  correlated errors, small n, missingness. Each violation is generated
  deliberately and the method's response classified.
- **Establishment under test.** For each violation: the method either flags it
  (metadata / convergence status) or degrades in a documented, predicted way.
  T3's cross-sectional failure is captured as a regression-guard: if the
  design reappears, the battery catches it.
- **Tasks.** (1) Violation-DGM inventory. (2) Per-test violation checks.
  (3) Failure-mode classification table. (4) Gate file.
- **Exit gate.** Violation table in `results/calibration/`; gate green; T3's
  misspecification permanently regression-guarded.
- **Depends on.** C1. Feeds the T3 redesign (expansion-plan R6).
- **Blast radius.** New tests; classifies (does not change) existing methods.

### C5 — Common random numbers across comparing simulacra

- **Hypothesis.** Comparisons between conditions (framework vs competitor,
  model A vs B) are more precise when noise draws are shared where legitimate:
  correlated draws isolate the contrast and reduce the MCSE of the difference.
  Independent draws inflate the variance of every comparison the foundry
  currently reports.
- **Formalization.** Seed-family discipline: a fixed base seed plus a
  per-condition offset, so comparable conditions draw the same noise streams;
  a standards bullet in `PHOSPHENE_R_STANDARDS.md`; documented in the
  simulacrum helpers.
- **Establishment under test.** For each comparing simulacrum: determinism
  preserved (A2); the MCSE of the contrast is reported and smaller than the
  independent-draw version on the same data.
- **Tasks.** (1) Seed-family convention. (2) Apply to comparing simulacra.
  (3) MCSE-of-difference report. (4) Standards bullet.
- **Exit gate.** Comparing simulacra use CRN; contrast MCSE reported.
- **Depends on.** C6.
- **Blast radius.** Test-level; determinism guarantees comparability with
  previous runs.

### C6 — Monte Carlo error and replication-count discipline

- **Hypothesis.** Every simulated performance measure carries Monte Carlo
  error; replication count is set by target precision, not habit. The current
  ~100-rep simulacra cannot resolve a type-I rate at all; their pass/fail
  asserts gross function, not calibration.
- **Formalization.** A `required_reps(target_mcse, p_hat)` helper
  (Koehler/Brown/Haneuse: reps ≈ p(1−p)/MCSE²); MCSE attached to every
  reported rate in the marks (`simulacra_logging.R`); key simulacra bumped to
  precision-targeted counts.
- **Establishment under test.** Every mark reporting a rate includes MCSE;
  key rates carry error bars; a doc table states the target MCSE and
  replication count per test.
- **Tasks.** (1) `required_reps()` helper. (2) MCSE in marks. (3) Rep bumps.
  (4) Doc table.
- **Exit gate.** Marks carry MCSE; replication counts justified by precision.
- **Depends on.** —
- **Blast radius.** Logging/marks layer + tests. Runtime increase from rep
  bumps must be CI-budgeted (see C1 design).

### C7 — Rank calibration (SBC) for interval-producing pipelines

- **Hypothesis.** Any pipeline that produces intervals or posteriors is
  calibrated iff, averaging over prior draws and simulated data, the true
  parameter's rank under the posterior/interval is uniform. The foundry
  produces GLM CIs (empirical formal model), PGLS CIs, and bootstrap CIs
  (cultural module) — none are rank-checked.
- **Formalization.** An SBC harness around the interval-producing machinery:
  draw θ from a prior over the model's parameters, simulate data, fit, record
  the rank of true θ; rank histogram + KS / band check (Talts et al. 2018).
- **Establishment under test.** For the GLM, PGLS, and bootstrap-CI paths:
  rank uniformity at ≥1,000 draws; a rank-histogram artifact committed to
  `results/calibration/`.
- **Tasks.** (1) SBC harness. (2) Wire GLM / PGLS / bootstrap paths. (3) Rank
  diagnostics. (4) Gate.
- **Exit gate.** Rank-uniformity check passes for each interval path.
- **Depends on.** C1.
- **Blast radius.** New tests; may surface real miscalibration (that is the
  point).

### C8 — Declared design (ADEMP manifest conformance)

- **Hypothesis.** A simulation study should be declared before run — aims,
  DGM, estimand, method, performance measure — so diagnosis is automatic and
  the design is auditable. This generalizes the foundry's existing manifest
  conformance (A3) from the pipeline to the calibration layer.
- **Formalization.** A `calibration:` block in `pipeline.yml` declaring each
  calibration design (generator, grid, estimand, estimator, measure); a
  `diagnose_design()` that checks declared vs actual, mirroring the A3
  manifest test.
- **Establishment under test.** Manifest conformance for the calibration
  suite: a design declared but not run, or run but not declared, fails the
  gate.
- **Tasks.** (1) ADEMP manifest schema. (2) `diagnose_design()`. (3)
  Conformance test. (4) Gate.
- **Exit gate.** Calibration suite conforms to its declared manifest.
- **Depends on.** C1.
- **Blast radius.** Manifest + one test; mirrors existing A3.

---

## E-series — engineering gaps the lens exposes

### E1 — Coverage gate on under-covered modules

- **Hypothesis.** The CI unit gate (coverage ≥ 80%) should bind on all shipped
  modules; an under-covered module is an untested module. Four modules are
  below the gate today: `R/p_series_a_priori.R` (19.4%),
  `R/dynamics_classes.R` (49.7%), `R/formal_model_classes.R` (50.6%),
  `R/test_registry.R` (64.1%) — the newer a-priori P-series and the class
  constructors have almost no direct tests.
- **Formalization.** Per-file test inventory and added tests to lift each
  module ≥ 80%, with behavior contracts (not coverage-hacking).
- **Establishment under test.** Re-run coverage: all four modules ≥ 80%;
  overall coverage rises from 83.4%; unit gate green.
- **Tasks.** (1) Inventory untested paths per file. (2) Add contract tests.
  (3) Coverage re-run. (4) Gate.
- **Exit gate.** All four modules ≥ 80%; unit gate green.
- **Depends on.** —
- **Blast radius.** Tests only; high-value because the P-series and class
  constructors are the least-tested shipped code.

### E2 — Revive the property-based empirical invariants suite

- **Hypothesis.** Property-based invariants — statistical quantities in their
  valid ranges under any valid input — are a permanent guard. A disabled file
  is a regression in the making. `tests/testthat/test-invariants-empirical.R.disabled`
  is a genuine 10-invariant suite (PGLS recovers negative β; R² ∈ [0,1]; ρ ∈
  [−1,1]; depletion ratio ≥ 0; null mean ρ ≈ 0; sign preservation; pseudo-R²
  ∈ [0,1]; fluidity R² ∈ [0,1]; biphasic R² ≥ 0) that is currently
  invisible to the gates.
- **Formalization.** Diagnose why it was disabled (likely environment / API
  drift, e.g. `pgls_orobanchaceae` signature), repair against current
  signatures, re-enable as `test-invariants-empirical.R`, and fold its
  synthetic generators into the C1/C2 harness where they overlap.
- **Establishment under test.** File re-enabled and green; its generators
  shared with the calibration suite; no duplicate synthetic infrastructure.
- **Tasks.** (1) Diff against current API. (2) Repair + re-enable. (3) Fold
  generators into calibration helpers. (4) Gate.
- **Exit gate.** `test-invariants-empirical.R` passes; suite visible in gate.
- **Depends on.** C1 (shared generators).
- **Blast radius.** One re-enabled file + helper consolidation.

### E3 — Absorb or retire the extracted edge probes (`_problems/`)

- **Hypothesis.** The 13 files in `tests/testthat/_problems/` — extracted
  one-off probes from failing lines, chiefly the fit-biexp seed-fragility and
  noise-monotonicity boundary checks (e.g. `test-unit-fit-biexp-266.R`: high
  noise must select bi-exponential less than low noise) — are exactly the
  boundary conditions the calibration battery should characterize. Archived in
  limbo, they are neither tested nor deliberately retired.
- **Formalization.** Triage each probe into: **absorb** into the C-series
  battery (fit-biexp seed-fragility → C2/C4; manifest conformance probe →
  C8; noise-monotonicity → C1 power behavior), **fix** and restore as a unit
  test, or **retire** with a written reason in the triage table.
- **Establishment under test.** Every `_problems/` file has a resolution
  (absorbed / fixed / retired-with-reason); no file left in limbo; the
  battery covers the boundaries the probes exposed.
- **Tasks.** (1) Inventory + classify all 13. (2) Execute absorptions / fixes /
  retirements. (3) Triage table committed. (4) Gate.
- **Exit gate.** `_problems/` empty or every entry resolved in the triage
  table; battery covers the recovered boundaries.
- **Depends on.** C1, C2, C4, C8.
- **Blast radius.** Test-layer; the fit-biexp probes are the highest-value
  raw material (they already encode the seed-fragility boundary documented in
  `fit-biexp-numerical-challenges.md`).

---

## Linked, already-planned (not re-ticketed)

Referenced from the
[`empirical-testing-expansion-plan.md`](empirical-testing-expansion-plan.md)
where they feed the battery:

- **Phase 1 — L3 wiring + contracts** (fixes a real latent bug; `C3` needs
  the corrected wiring before the L3 falsification contrast can run).
- **Phase 2 — drop-in empirical hooks** for the *Homo* inversion and cusp
  (their data requirements are made explicit; the synthetic side is covered by
  `C1`–`C4`).
- **Phase 3 — magnitude metrics** (loop area, DD contrast, sign-transfer;
  these give `C1`/`C3` the quantitative targets to sweep).
- **Phase 4 — regression-gate promotion** of simulacrum known-parameters (the
  enforcement vehicle for `C3` and `C6`).

---

## Execution order and commit structure

One commit per ticket, each with code + tests + docs in lockstep, suite green
on the branch before push. Suggested order, cheapest-and-highest-value first:

1. **E2** (revive the invariants suite — it is already written),
2. **E1** (coverage on the four under-covered modules),
3. **C6** (MCSE discipline — the harness everything else needs),
4. **C1** (sweep harness — the unit of characterization),
5. **C2** (type-I calibration, depends on C1 + C6),
6. **C5** (common random numbers, depends on C6),
7. **C4** (misspecification battery, depends on C1),
8. **C7** (rank calibration, depends on C1),
9. **C3** (competitor-generative falsification, depends on C1; ties to
   expansion-plan Phase 4),
10. **C8** (declared design, depends on C1),
11. **E3** (absorb the `_problems/` probes, depends on C1/C2/C4/C8).

The C-series can also proceed as one "calibration battery" ticket if preferred
with C1/C6 as the foundation commit — but each sub-hypothesis is independently
refutable and should land as its own green commit.

---

## Open questions for review

1. **C1 scope** — all estimators, or start with the two discriminating core
   tests (T3 biphasic model selection, T6 ordering) where the power question
   is sharpest? Starting narrow gives the first power curve sooner.
2. **C6 CI budget** — precision-targeted reps (≥1,900 for type-I) will raise
   calibration-gate runtime. Accept a separate (non-blocking) calibration gate
   on CI, or budget the reps into the existing suite?
3. **C7 scope** — rank-calibrate the current interval paths (GLM, PGLS,
   bootstrap) only, or also the Bayesian machinery elsewhere in the org when
   it produces intervals for the review's claims?
4. **E3 retirement** — is retiring a probe with a written reason acceptable,
   or should every `_problems/` boundary be absorbed into the battery?
