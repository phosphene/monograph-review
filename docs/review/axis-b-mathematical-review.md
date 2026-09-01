# Axis B — Mathematical Review: Is the Scenario Matrix Worked Out?

**Author:** FeelingFlow (@feelingflowingbot), on the scenario-axes protocol
**Date:** 2026-09-01
**License:** MIT
**Status:** Review — Axis B is a *labeled parameter set*, not yet a
mathematical object. This review supplies the missing map from each flip to
the equations in this repo, decomposes the space into **live** vs.
**Axis-A-locked** flips, and states what "carrying an alternative" must mean
to be non-vacuous.

---

## What this document is

The scenario-axes protocol (Axis A = settled ledger, Axis B = flippable
parameters, Axis C = test program) requires that before any hypothesis is
locked, its parameter settings are stated together with ≥ 1 alternative —
turning the scenario into a laboratory instead of a single narrative. Axis B
lists six binary flips. This review asks the same three questions the foundry
asks of every other artifact:

1. **Is the mathematics real** — does each flip change the equations?
2. **Is it coherent** — do the two settings of each flip predict different
   observables?
3. **Is it reproducible** — can the repo's model family realize each flip?

The reference model family in this repo:

| Component | File | Form |
|-----------|------|------|
| Threshold gate (cross-sectional) | `R/formal_model.R` (`threshold_model`) | `C_i(T) = exp(−λ ∫₀ᵀ M(t)dt)` if `d_i < θ`, else `1` |
| Relaxation (temporal) | `R/relaxation_model.R` (`relaxation_ode_rhs`) | `dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂)` |
| Coupled system | `R/cultural_ode_models.R` (§9 revised) | `dB/dt = εβB(1−B/K) − δ_B·B + J + I(B,S)`; `dρ/dt = −k₁(ρ−ρ₁(B)) − k₂(ρ−ρ₂(B))`; `dS/dt = L_s(ρ)·T·A(B) − μ_s·S` |

---

## 1. The two defects that keep Axis B non-mathematical

### D1 — No flip is stated as a change to the equations
None of P1–P6 says "set this term in the model family to X instead of Y."
Until a flip has an algebraic meaning, the matrix cannot *generate*
hypotheses — it can only label them. A scenario cell is a mathematical object
only once it denotes a concrete model instance (parameter vector + forcing
structure). In repo terms: a cell must name a call to
`relaxation_simulate()`/`threshold_model()`/`valence_ode_solution()` with
specific arguments, or a switch in the coupled system.

### D2 — No distinguishability requirement
"Carry an alternative" is only meaningful if the alternative **predicts
something different**. A flip whose two settings produce identical predictions
is vacuous — it consumes a degree of freedom and contributes nothing to
Axis C. The protocol needs: *every live flip must change at least one
observable prediction, and that prediction must be stated.*

---

## 2. The flips, mapped to the model family

| Param | Flip (A → B) | Algebraic change in repo terms | Status |
|---|---|---|---|
| **P1** timing | staggered → simultaneous | two-channel solution, activation times t₁ < t₂ → t₁ = t₂ | **LOCKED** — A3 (Kimberella gut, Ediacaran) rules out simultaneous |
| **P2** scope | pre-metazoan → metazoan-only | domain restriction of the substrate universe | **LOCKED** — A2 (pre-metazoan electrogenesis established) |
| **P3** direction | one-way → reciprocal | open-loop → closed-loop: `M(t)` exogenous → endogenous. Coupled system (Eqs 1–3 of `cultural_ode_models.R`) already has `dρ/dt` driven by `B(S)`; the flip adds `dM/dt = −αM − γρ` | **LIVE — most consequential flip** |
| **P4** commitment | seeking → seeking+persistence | measurement model change: B-T3 test statistic gains a persistence/niche-locking observable | **LIVE** — partially corroborated (sponge settlement 🟢) |
| **P5** sponge role | intermediate → full relict | substrate classification of Porifera | **LOCKED** — A4 (intracellular digestion; strong version false) |
| **P6** locus | event → ongoing | forcing term: `dρ/dt` gains source `s(t) ≠ 0` throughout vs. `s(t) = 0` after internalization (autonomous relaxation) | **LIVE** |

**Main result: 3 locked, 3 live.** The nominal 2⁶ = 64-cell space collapses to
a **live subspace of 2³ = 8 scenario cells** (P3 × P4 × P6). P1, P2, P5 are
demoted from degrees of freedom to *verified constraints* — still stated, but
no longer flipped; the Axis A ledger has settled them. Flipping a locked
parameter is a formulation error, not a variation.

---

## 3. Discrimination matrix — the experiment behind each live flip

| Flip | Distinguishing experiment | Prediction differential |
|---|---|---|
| **P3** one-way vs reciprocal | Rate-remaining proportionality (LTEE; foundry's 1-of-4 result); endosymbiont logistic-vs-biphasic ΔAICc | Open loop: proportionality holds, k₁,k₂ window-stable. Closed loop: proportionality **fails** as commitment consumes mismatch — the 3/4 LTEE failures may already be a P3 signal; k₁/k₂ estimates shift with observation window |
| **P6** event vs ongoing | Post-internalization electrome perturbation (anesthesia P10-A, 4/4 cortical) | Event: ρ trajectory is perturbation-insensitive after internalization. Ongoing: trajectory shifts when the driver is disrupted |
| **P4** seeking vs +persistence | Sponge settlement: larvae choose site before metamorphosis (already 🟢) | Seeking-only: B-T3 = approach/withdraw tracking only. +Persistence: niche-locking observable required |

---

## 4. What "fully worked out" requires (the build list)

1. **Scenario schema** — each live cell = explicit model instance in this
   repo's model family (a named call with parameter vector + forcing
   structure), not prose.
2. **Enumerate the 8 cells** — run each through the simulacra harness;
   emit an 8-row prediction fingerprint table (the Axis C input,
   scenario-indexed instead of flat).
3. **Closed-loop implementation (P3)** — extend `relaxation_model.R` with a
   `closed_loop = TRUE/FALSE` switch on the ODE:
   `dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂) + β·M`; `dM/dt = −αM − γρ`. Test
   identifiability of k₁, k₂ under both regimes. This is the piece that
   decides whether the 1-of-4 LTEE proportionality result is evidence *for*
   reciprocity. (The coupled system in `cultural_ode_models.R` is the
   natural home.)
4. **Forcing-term implementation (P6)** — `s(t)` switch on the same module.
5. **Locked parameters become constraints** — P1, P2, P5 move to the
   verified-constraints set in Axis A; the protocol stops listing them as
   variations to try.

---

## 5. Immediate consequences for the scenario

- The **one causal claim that really can flip** is P3. It is also the flip
  with the strongest existing empirical handle (LTEE proportionality). Axis C
  should carry a dedicated P3 row with the closed-loop simulacrum as its
  known-answer check.
- P4's +persistence setting is already corroborated by the sponge settlement
  result — so the honest default is B-T3 must include the persistence
  observable, not seeking-only.
- P6 is currently tested **for free** by the anesthesia result set: those
  experiments only discriminate if they are framed as post-internalization
  perturbations of an ongoing driver. That framing should be made explicit
  before more data is collected.

---

## Cross-references

- Scenario protocol (Axis A/B/C): framework's scenario-axes protocol
  (source: `work/marsyas6/papers/valence-ingress/scenario-axes-protocol.md`)
- Coupled system: [`R/cultural_ode_models.R`](../../R/cultural_ode_models.R)
- Relaxation model: [`R/relaxation_model.R`](../../R/relaxation_model.R)
- Threshold model: [`R/formal_model.R`](../../R/formal_model.R)
- Simulacra harness: [`scripts/run_simulacra.R`](../../scripts/run_simulacra.R)
