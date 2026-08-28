# Review, Calculation Audit & Phased Breakdown

This directory holds the critical review of the Valence-Ingression framework
monograph and of this repository's computational artifacts, the literate
calculation audit that traces every divergence to its root cause, and the
phased breakdown of how the foundry was built.

These documents are authored by **Ed Phillips**
([@phosphene](https://github.com/phosphene)) and licensed under MIT, consistent
with the standards in [`docs/standards/`](../standards/).

## Contents

| Document | What it is |
|----------|-----------|
| [`valence-ingression-review.md`](valence-ingression-review.md) | Critical review of the valence monograph (Ritch-Frel, v9) and the valence-foundry artifacts. Numbered **Remarks** (R1…) and **Review Items** (1–6). The foundry's code cites these directly. |
| [`calculation-review.md`](calculation-review.md) | Literate walkthrough of the calculation audit: for each oracle entry, the prediction, the broken output, the root-cause diagnosis, and the fix. The analysis-level companion to the review. |
| [`math-review.md`](math-review.md) | Audit of the mathematics vs. the implementation vs. the claims: does the code realize the math it states, and do the claims follow? Seven issues ranked by severity (two severe). |
| [`refactoring-plan.md`](refactoring-plan.md) | Execution plan for the math-review issues: proposed refactoring, blast radius, risk, and phasing for each of the seven issues (three phases, safest-first). |
| [`valence-foundry-phased-breakdown.md`](valence-foundry-phased-breakdown.md) | Phase-by-phase breakdown of the foundry build, current gate status, and the open data-reconciliation work (items 4–6). |
| [`algorithms-and-findings.md`](algorithms-and-findings.md) | Formal, literate survey of every algorithm, its prediction, its competitor, and a plain-language reading of the current result. The synthesis of what the foundry establishes, what it does not, and what that means for the framework. |
| [`empirical-testing-expansion-plan.md`](empirical-testing-expansion-plan.md) | Proposal for moving the three "testable but not yet tested" modules (Homo inversion, cusp irreversibility, cross-kingdom transfer) toward tested. Phases: fix the L3 wiring bug + contracts; drop-in empirical hooks; quantitative magnitude metrics; regression-gate enforcement. Honest about the data boundary. |
| [`modeling-sim-viz-review.md`](modeling-sim-viz-review.md) | Review of the author's existing modeling (finds the original empirical formal model — a GLM — was broken: wrong sign on dependency, non-significant parasitism, wrong-signed cross-kingdom transfer; the foundry hid this by replacing it with a theoretical ODE simulation). Evaluation of the simulation and visualization infrastructure (three latent viz bugs, found and fixed). Proposal for a speculative simulation capacity extending valence into four toy realms (genome reduction, cross-kingdom transfer, irreversibility, Homo inversion) — 80% built from existing components. |
| [`toy-realms-plan.md`](toy-realms-plan.md) | Execution plan for the speculative simulation capacity proposed in modeling-sim-viz-review Part III. Four phased toy realms (genome-reduction explorer, irreversibility explorer, Homo-inversion explorer, cross-kingdom transfer explorer), each with what it explores, what it reuses, what it adds, exit criteria, and the experiment that would convert it from speculative to empirical. Honest about the data boundary: the realms are theoretical exploration, not empirical test. |
| [`formal-model-reproduction.md`](formal-model-reproduction.md) | Deep-dive reproduction of the author's broken GLM. **Root cause:** a data-flattening bug (`as.vector(t(retention))` misaligns `dep` and `retention`). **Fix:** remove one `t()`. With correct alignment, the additive GLM gives `dep = +0.84` (p = 0.0008), `para` p < 0.0001, cross-kingdom ρ = +0.755 — all matching valence. Contrasts five model specs (misaligned GLM, corrected additive GLM, interaction GLM, threshold fit, foundry ODE) against the foundry's non-empirical simulation. **Now implemented:** the corrected GLM is restored as `empirical_formal_model()`, the 8×6 matrix is bundled in `data/`, and it is wired into the pipeline and regression gate. Includes executable companion (`inst/examples/formal-model-comparison.R`) and formal deprecation note. Records the finding as **Remark R7** in the review. |
| [`fit-biexp-numerical-challenges.md`](fit-biexp-numerical-challenges.md) | Rigorous revisit of the bi-exponential relaxation fitter (`fit_biexp` + `relaxation_phase_analysis`): the ill-conditioning, the seed-fragile mono/bi boundary (10/50 one-channel seeds spuriously select bi), the biphasic-flag bug (old ratio-only rule fired on 71% of one-channel datasets while contradicting the model selection), the degenerate-sampling and noise boundaries. **Proposal implemented:** the guarded four-condition `biphasic` rule (AIC-agreement + ratio>2 + same-sign + amplitude floor 0.15). Reproducible via `scripts/validate_fit_biexp.py`. |
| [`cross-kingdom-ordering-direction.md`](cross-kingdom-ordering-direction.md) | Why the sign fix in `predict_bird_ordering` is inevitable: the code negated the plant slope, inverting the dependency ordering, while its own docstring (`rank(a*x) = rank(x)`), the plant fixture (`loss_rank` high for high dep), and the shared-positive-slope simulacrum (bird_rho > 0.7) all demanded the direct transfer. Surfaced by the first full-suite coverage run. Includes the companion T15 RNG-provenance lesson. |

## How the code references this review

The test suite and pipeline cite this review by number so that a skip or a
divergence points at a specific, written finding rather than an opaque message:

- **Remark R1** — the framework's name is ambiguous; see the *Valence-Ingression*
  glossary entry in the root [`README.md`](../../README.md).
- **Review items 4–6** — the data-reconciliation items. They are the reason the
  regression gate `skip()`s T6 and L3 (no bundled data) and reports numerical
  drift on T1–T5 / T7 (bundled data does not yet reproduce the oracle). See the
  breakdown for the per-entry status table.
