# fit_biexp: The Numerical Challenges, Rigorously Revisited

**Status:** active · **Owner:** Ed Phillips · **Date:** 2026-08-28
**Scope:** `R/fit_biexp.R`, `R/relaxation_model.R`, `tests/testthat/test-unit-fit-biexp.R`,
`tests/testthat/test-unit-relaxation-model.R`
**Reproducible evidence:** `scripts/validate_fit_biexp.py` (run it — every number below regenerates)

> This is the rigorous revisit of the bi-exponential relaxation fitter that
> sits on one side of the cross-program biphasic pair (endosymbiont genome
> reduction × physiological relaxation kinetics). The standard applied here is
> the vintage-label one: the bottle must say what is in it, and the contents
> must be reproducible by anyone who clones the repo. Where the fitter cannot
> resolve a two-timescale structure, the honest output is a boundary probe —
> "this pattern is not resolvable at this sampling scale" — not a forced
> conclusion.

---

## 1. The model and why fitting it is hard

The relaxation formula predicts retention follows

\[
\rho(t) = c_0 + A_1 e^{-k_1 t} + A_2 e^{-k_2 t}, \qquad k_1 \ge k_2
\]

and `fit_biexp` compares this against the mono-exponential baseline
\(\rho = c_0 + A e^{-kt}\) and a linear null on AIC.

Fitting this model is **ill-conditioned in a specific, documented way**: the
fast channel decays within the first few sampling intervals, so naive starting
values collapse both channels onto the slow rate, or fail to converge entirely.
Three defences are already layered into the fitter (see the `Fitting Strategy`
roxygen block):

1. **Exponential peeling** — data-derived starting values from a log-linear
   tail fit (slow channel) plus early-residual fit (fast channel).
2. **Log-rate reparameterisation** — rates are fitted as \(\log k\), so they
   are structurally positive and the Jacobian never degenerates from
   negative-rate drift.
3. **Fast/slow convention** — channels relabelled so \(k_1 \ge k_2\).

Plus, since commit `1998a66`, the fit is always performed on normalised time
\(\tilde t \in [0,1]\); `normalize_t` only controls the **reporting scale** of
the rates. Because the model space is closed under time-scaling
(\(t \mapsto a t\) is absorbed into \(k \mapsto k/a\)), the least-squares
optimum, RSS and AIC are identical on any scale — this made model selection
and convergence genuinely scale-invariant, closing the old norm/raw
disagreement on the extreme-\(t_\max\) fixture.

**But** scale invariance fixes the *basin-finding* problem; it does not fix the
*identifiability* problem. That is what this revisit is about.

---

## 2. The challenges, with evidence

### C1 — Spurious fast channel on one-channel data (the mono/bi boundary)

**The maths.** A single-exponential dataset has *no* second channel. But a
5-parameter model can absorb noise: the optimizer finds a tiny-amplitude
"fast" channel that lowers RSS by a hair, and — because AIC's penalty for two
extra parameters is weak at the amplitudes involved — the bi model can win.

**The evidence** (reproduced by `scripts/validate_fit_biexp.py`):

> On pure single-exponential data (`make_monoexp_data`, noise 0.001), **10 of
> 50 seeds** spuriously select `biexponential`. The worst case (seed 3) is a
> *decisive* win: \(\Delta\mathrm{AIC}_{\mathrm{bi-mono}} = +4.52\) with a
> spurious fast channel at 9.5% of amplitude.

**The hidden test bug.** The pre-existing T2 ("mono wins or is competitive")
only passes because it fixes `seed = 42` — which happens to be a safe case
(\(\Delta\mathrm{AIC} = -2.12\)). The fitter's mono/bi decision is
seed-fragile at this boundary, and the test was not probing it.

**The honest rule.** A decisive two-timescale claim must not ride on a
negligible channel. The identifiability boundary test (T17) asserts: *a
decisive bi selection (\(\Delta\mathrm{AIC} > 2\)) must be accompanied by a
material fast channel (\(A_1\)-fraction ≥ 0.15), else the claim is a numerical
artefact.* Verified: 0 violations in 100 one-channel seeds.

### C2 — The biphasic flag contradicted the model selection

**The maths.** `relaxation_phase_analysis` decided `biphasic` from the rate
ratio alone: `rate_ratio > 2`. This ignores amplitude entirely. A spurious
low-amplitude fast channel (C1) inflates the ratio to hundreds, and the flag
fires on data the *model selection itself rejected as mono*.

**The evidence** (this is the headline):

> The old ratio-only rule fired `biphasic = TRUE` on **143 of 200 (71%)**
> single-exponential datasets. One seed even reported `biphasic = TRUE` while
> the AIC model comparison *preferred mono* (\(\Delta\mathrm{AIC} = -0.13\)).
> The interpretation layer was actively contradicting the fit layer.

**The fix (this proposal).** The flag now requires **four** conditions to
hold simultaneously:

| # | Condition | What it excludes |
|---|-----------|------------------|
| a | \(\Delta\mathrm{AIC}_{\mathrm{bi-mono}} > 0\) | mono preferred → no two timescales claimed |
| b | \(k_1/k_2 > 2\) | no genuine rate separation |
| c | \(\mathrm{sign}(A_1) = \mathrm{sign}(A_2)\) | degenerate opposite-sign channels |
| d | \(\min(A_1, A_2)/(A_1+A_2) \ge 0.15\) | spurious negligible fast channel |

**Validated trade-off** (100–200 seeds each):

- One-channel false positives: **143/200 → 4/200 (71% → 2%)**.
- Genuine two-channel detection: **100/100** preserved.
- The 0.15 floor sits in a clean gap: genuine two-channel relaxations have
  min-fraction **0.218–0.289**; spurious same-sign cases sit **≤ 0.11**.

The residual 2% is the genuine identifiability boundary (e.g. seed 49, where
AIC honestly prefers bi on mono data) — documented, not hidden.

### C3 — Degenerate sampling: the fast phase decays between samples

**The maths.** With \(n\) points on \([0, t_\max]\), the fast channel is
resolvable only if \(k_1 \cdot \Delta t \lesssim 1\). For \(t_\max = 56500\),
\(k_1 \Delta t \approx 2.2\) at \(n=80\) — the fast phase is dead between
samples.

**The behaviour.** The fitter now reports `best_model = "monoexponential"`
here — the honest answer. This is exactly the Kull-style boundary probe from
the family-kinds discipline: a non-instantiating case is not a refutation of
biphasic structure, it is a measurement that *at this sampling scale the fast
phase is not resolvable*. Locked by T15.

### C4 — The noise boundary: when structure stops being separable

**The maths.** As noise rises, the two-timescale structure becomes
unidentifiable and honest selection retreats toward mono/linear.

**The evidence:**

| noise | 0.001 | 0.005 | 0.01 | 0.02 | 0.05 |
|-------|-------|-------|------|------|------|
| seeds selecting bi (of 10) | 10 | 10 | 3 | 3 | 1 |

Locked by T18 as a monotone-direction assertion (high-noise count <
low-noise count), which documents the boundary without over-constraining.

### C5 — Hygiene properties (confirmed sound)

- **Determinism** (DFT A2): same input → byte-identical output. T12.
- **Parameter recovery** on the raw scale: k1/k2 within 20%, amplitudes within
  30%, c0 within 20% of truth on clean data. T11.
- **Halflife is physical** (raw-time): \(\tau_{1/2} = \ln 2 / k_{\mathrm{raw}}\)
  regardless of `normalize_t`. T13.
- **Amplitude fractions bounded**: metadata uses `abs()`, so
  \(A_1/(A_1+A_2) \in [0,1]\) even on degenerate opposite-sign fits. T14.
- **Zero time range**: guard returns without error. T16.

---

## 3. The test map

| Test | Locks |
|------|-------|
| T11 | Parameter recovery accuracy (raw scale) |
| T12 | Determinism (DFT A2) |
| T13 | Halflife is a physical raw-time quantity |
| T14 | Amplitude fractions bounded in [0,1] |
| T15 | Degenerate sampling → honest mono (boundary probe, C3) |
| T16 | Zero time-range guard |
| T17 | Identifiability boundary: decisive bi requires a material channel (C1) |
| T18 | Noise boundary: bi selection rate falls with noise (C4) |
| T19+ (relaxation) | Biphasic never contradicts model selection (C2a) |
| T20+ (relaxation) | No biphasic claim on one-channel data (C2b) |
| T21+ (relaxation) | Genuine two-channel data still detected (C2c) |
| T22+ (relaxation) | Phase amplitudes bounded |

Each challenge is locked by a test that would **fail on the pre-fix code** —
that is the difference between a documented concern and a tested contract.

---

## 4. Reproducibility

Every quantitative claim in §2 regenerates from:

```bash
python scripts/validate_fit_biexp.py
```

This is a faithful port of the R implementation (same log-rate
parameterisation, same peeling start, same grid, same `abs()` metadata
semantics) so the boundary characterisation is checkable without an R
toolchain. The R tests remain the source-of-truth contract and run in CI.

---

## 5. Relationship to the broader thread

This is the operational form of the Bohr austerity adopted in
[`bohr-complementarity-lineage.md`](bohr-complementarity-lineage.md): the
relaxation fitter is one of the two non-commuting apparatuses whose agreement
makes the biphasic pattern "largely irrefutable at the level of observation."
For that agreement to mean anything, this half must be reproducible and must
not over-claim. The guarded `biphasic` rule is the foundry saying, in effect:
we will report a two-timescale structure only when the data forces it — and
when the data does not, we say so. That is the vintage label, applied to the
bottle that produces the numbers.

See also [`family-kinds-genealogy.md`](family-kinds-genealogy.md) for the
boundary-probe epistemology (Kull, Kunz, polythetic classes) that justifies
treating non-instantiating cases as measurements rather than refutations.
