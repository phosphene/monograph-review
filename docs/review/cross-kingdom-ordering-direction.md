# Cross-Kingdom Ordering Direction: Why the Sign Fix Is Inevitable

**Status:** active · **Owner:** Ed Phillips · **Date:** 2026-08-28
**Scope:** `R/cross_kingdom_transfer.R` (`predict_bird_ordering`, `transfer_test`),
`tests/testthat/test-unit-cross-kingdom.R`, `inst/simulacra/generate_cross_kingdom.R`
**Trigger:** the merged-main CI run (`d572c43`, run 33198990411) — the first
full-suite coverage run to reach the cross-kingdom unit test.

> This is the operational form of the vintage-label standard, applied to a
> sign convention. The CI did not fail because the test was wrong; it failed
> because the *code contradicted its own documentation and its own simulacrum*.
> Once the gate finally ran the whole suite, the contradiction was
> unavoidable. Fixing the sign was not a choice — it was the only way to make
> the label match the bottle.

---

## 1. The bug, in one line

```r
# before (inverted):
predicted <- -plant_slope * bird_data$dependency_score
# after (direct):
predicted <-  plant_slope * bird_data$dependency_score
```

`predict_bird_ordering()` predicts the order in which bird structures change
from a plant-derived slope, then converts to ranks (`1 = first to change`).
The negation made **high-dependency structures rank first** — the exact
opposite of the biology the model is supposed to transfer.

## 2. Why the change was inevitable (three independent witnesses)

The sign error was not ambiguous. Three things in the repository already
knew the correct direction, and all three were contradicted by the negation:

**(a) The docstring.** The `transfer_test` roxygen note states explicitly:
> `predict_bird_ordering()` ranks (plant_slope * dependency_score), and
> `rank(a*x) = rank(x)` for any a > 0 ... a positive plant slope yields the
> same ordering as dependency_score itself.

The code negated; the documentation said direct. A vintage-label violation:
label and contents disagreed on the most important property of the function.

**(b) The plant fixture.** `fit_plant_model`'s own fixture is
`loss_rank = c(1,2,3,4,5,6)` for `dependency = c(0,1,1,2,3,5)` — high
dependency gets a **high** loss rank (retained longer), and the test asserts
`slope > 0`. So plant loss_rank and bird observed_rank run in the **same**
direction (high dep → later change → high rank). The old comment claiming
"plant loss_rank is inversely related to dependency" was factually wrong
against the fixture it sat next to.

**(c) The simulacrum.** `generate_cross_kingdom.R` builds *both* kingdoms
from a **shared positive slope** (`true_slope = 0.6`, `slope × dep + noise`,
rank-transformed). The recovery simulacrum asserts `bird_rho > 0.7`. With the
negation, predicted ranks are anti-correlated with observed ranks → ρ goes
strongly negative → Simulacrum 5 cannot pass. The bug was guaranteed to fail
the recovery test; it had simply never been reached because earlier coverage
failures masked the full suite.

Three independent witnesses, all pointing the same way. That is what "the
change is inevitable" means: it is not a preference, it is the only consistent
reading of the code's own evidence.

## 3. Why the gate caught it only now

The unit *gate* (`run_tests.R unit`, 558 tests) was green on this code — the
cross-kingdom unit test at `test-unit-cross-kingdom.R:47` failed only under
the **coverage step**, which runs the *full* suite (660+ tests). Two reasons
it had been masked:

1. The coverage step errored earlier in the pipeline (the `skip_if_null`
   non-function), aborting before this test ran. Fixing that surfaced this.
2. The unit gate's 558-test subset simply did not include this assertion
   with this data.

This is the foundry's core discipline earning its keep: the *full* suite is
the honest test surface, and a green subset is not a green bottle.

## 4. The fix and the strengthened contract

- **Code:** removed the negation; corrected the misleading comment to state
  the same-direction convention and *why* (plant and bird both rank high-dep
  as late-change).
- **Test:** the single pairwise assertion (`dep 5 > dep 0`) is strengthened
  to the full contract — `order(predicted) == order(dependency)` (monotone),
  the permutation property (`predicted` is a re-ordering of 1..n), plus the
  original pair. The strengthened test fails on the pre-fix code.
- **Simulacrum:** untouched — it was already correct (shared positive
  slope); it now passes because the prediction no longer inverts it.

## 5. The companion change in the same pass (T15)

The same merged-main run surfaced a second failure: `test-unit-fit-biexp.R`
T15 asserted that a degenerate sample (`t_max = 56500`) *reports mono*. The
real-R fitter selects bi on that seed. That test had been validated against
**Python's** RNG (`numpy.default_rng(42)`), not R's Mersenne-Twister — a
vintage-label violation of the same family: asserting R behavior without
running R. The fix (PR #3) asserts the RNG-independent boundary-probe
guarantee instead: mono/linear, *or* a selected bi whose fitted fast channel
is itself unresolvable at that sampling (`k1·dt > 1`) — true by the math
(`c0` pinned at the tail minimum), not by the seed.

**The common lesson:** both changes are "inevitable" in the same sense. The
label promised something the contents did not deliver — one by sign, one by
RNG provenance — and the gate, once it could run the whole suite, made the
discrepancy undeniable. The response in both cases is the same: make the
contents match the label, and write the reasoning down so the next reader
does not have to rediscover the contradiction.

## 6. Relationship to the broader thread

The cross-kingdom transfer is the *agreement* program in the Bohr
complementarity framing: plant and bird lineages are two non-commuting
apparatuses, and the claim "ordering transfers across kingdoms" is the
pattern under test. For that pattern to be "largely irrefutable at the level
of observation," the sign of the transfer must be unambiguous — a test whose
pass/fail depends on a negation that contradicts its own documentation is not
a measurement, it is a coin flip. The fixed sign makes the transfer test an
honest instrument: reproducible, self-consistent, and audited by a simulacrum
with known ground truth.

Reproducible evidence: the CI run `33198990411` on `d572c43` (failures),
and the green run on the merged fix (see PR #3 → main).
