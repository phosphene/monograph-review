---
title: "Review Evaluation Standard: Vertices and Properties"
uri: docs/review/review-evaluation-standard
author: edphos (Ed Phillips)
date: 2026-08-28
status: living
license: MIT
---

# Review Evaluation Standard: Vertices and Properties

*Ed Phillips, 2026-08-28: "These are the standards for a monograph review
topic and the responsibility for the vertices that that review topic has to
support if it's going to actually evaluate the mathematics and the software
as well as the data — for well-formedness, for coherence, and for
reproducibility."*

This document states, in public scientific language, the standard the
monograph review itself must uphold. It is the contract of this review
topic: what the review evaluates, and the properties it evaluates for.

---

## The role of the review and platform team: underwriting, not discovery

*Ed Phillips, 2026-08-28: "This gets into the discussion about being in
the business of running the platform. We used the public analogy of the
underwriting of insurance for the inferential claims or predictive
apparatus of any given research program. The individual authors in those
domains are in the business of Discovery, but as the review team and the
platform team we are not. We underwrite the insurance for that process of
discovery."*

The review team and the platform team do not do what the authors do. The
authors in a research program propose new inferential claims and new
predictive apparatus — they are in the business of producing claims. The
review and platform teams are in a different business: they **underwrite**
the reliability of those claims.

The insurance-underwriting analogy is a public one, not a private
construct: insurance underwriting is the established practice of assessing
a proposed risk before accepting it, of pricing the premium against the
probability and severity of failure, and of specifying the conditions under
which coverage holds (ancient in origin; formalized in actuarial science
and in institutions such as Lloyd's of London). Applied to a research
program, it means:

- The **inferential claim or predictive apparatus** is the proposed risk —
  the thing seeking coverage.
- **Coverage** is reliance: being cited, published, or used as a basis for
  further work.
- **Underwriting** is the assessment this review performs: for each claim,
  evaluate its three vertices (mathematics, software, data) against the
  three properties (well-formedness, coherence, reproducibility), and
  state the conditions under which the claim is covered.
- The **premium** is the proof obligation: the testing and reproduction the
  claim must survive before coverage is granted.
- The **policy** is the stated-and-tested conditions themselves — the
  claim is covered only under exactly the conditions it has stated and
  tested, and not beyond them.

This is why the review team is not in the discovery business and has no
"Discovery" of its own (per the austerity rule): the review adds no new
claims about the world. It assesses the risk of the claims others propose,
and issues coverage only for what is actually verified. A claim that has
not passed its underwriting is not denied in the sense of being refuted —
it is simply not yet covered, and remains under test.

This role is the platform team's business: running the platform is running
the underwriting infrastructure — the foundry, the CI gates, the oracle
baseline, the review standard — so that any research program's claims can
be assessed the same way, against the same three vertices and three
properties.

---

## The three vertices (what the review evaluates)

The review evaluates three objects, each as an independent vertex. A
review that evaluates only the prose, or only the numbers, has not done
its job — each vertex can fail on its own while the others look fine.

| Vertex | What it is | Where it lives in this repository |
|--------|-----------|-----------------------------------|
| **Mathematics** | The equations, models, rate laws, statistics, and transfer functions the monograph states; the formal framework itself | `docs/review/math-review.md`, the formal model, the GLM, the ODE threshold model, the bi-exponential fitter |
| **Software** | The implementation: the R package, the pipeline, the test suite, the CI gates — whether the code realizes the math it claims to realize | `R/`, `tests/testthat/`, `run_tests.R`, `.github/workflows/ci.yml` |
| **Data** | The empirical datasets and how they are loaded, aligned, and reconciled with the analysis | `data/`, `baseline/oracle.yml`, the integration and regression gates |

The three vertices map to the three layers of a computational finding:
**data → mathematics → code**. A finding is only as strong as the weakest
vertex.

## The three properties (what the review evaluates for)

For each vertex, the review evaluates three properties. All three must
hold for a vertex to pass; a vertex that passes only one or two is
flagged as partial, not as passing.

| Property | What it means | Fails when |
|----------|---------------|-----------|
| **Well-formedness** | The object is correctly formed: the math is parse-balanced and internally consistent to equation level; the code is valid and its contracts are explicit; the data are aligned correctly (rows, columns, and units mean what the analysis assumes) | The GLM flattening bug (a `t()` misaligned `dep` and `retention`); a claim stated beyond its conditions; a dataset whose columns do not mean what the script assumes |
| **Coherence** | The layers agree with each other: the interpretation layer matches the fit layer; the claim follows from the analysis; the code does what its own documentation says | The biphasic rate-ratio-only rule firing `biphasic=TRUE` on 71% of single-phase datasets while the fit layer preferred mono — interpretation contradicted fit; a docstring narrating behavior the code does not have |
| **Reproducibility** | The object re-produces under test: same input gives the same output on any machine; the reported numbers re-run clean against a known oracle; a third party can re-run and get the same result | The regression gate that has never fired (oracle skips instead of enforcing); seed-dependent assertions validated against a different RNG than the one shipped; results that cannot be re-run |

## The review's responsibility

The review topic must support all three vertices against all three
properties. Concretely, for every result the monograph reports, the review
asks:

1. **Mathematics:** Is the math well-formed (internally consistent,
   specified to equation level)? Is it coherent (do the claims follow from
   the equations)? Is it reproducible (does the math re-derive cleanly,
   and does the code realize it)?
2. **Software:** Is the implementation well-formed (valid code, explicit
   contracts)? Is it coherent (does the code do what its own documentation
   says)? Is it reproducible (same input → same output, under CI, on real
   R)?
3. **Data:** Is the data well-formed (correctly aligned, units right)? Is
   it coherent (does the analysis match the data's actual structure)? Is
   it reproducible (does the bundled data re-produce the reported
   numbers)?

A result is **rely-on-able** — the word the review has used throughout —
only when all three vertices pass all three properties. Anything short of
that is a result under test, not a result established.

## Relationship to the other standards documents

- This is the standard for **what the review evaluates**. It is distinct
  from, and upstream of, the engineering standards in
  `docs/standards/` (how the code is written) and the journal-facing
  thresholds in `docs/publication-standards.md` (what evidence a journal
  would demand). The review applies this standard first; the engineering
  standards make it achievable; the publication thresholds are the
  external test of whether the result, once verified, would be accepted.
- The property list is the review's operational form of the claim-evidence
  conformance standard used across phosphene: **no claim exceeds its
  stated-and-tested conditions**. A result that has not passed all three
  vertices on all three properties is not claimed as established; it is
  either stated with its tested conditions or marked as untested/proposed.

## Status

- [ ] Apply the three-vertices × three-properties grid to each §5 result
      of the monograph (T1–T7, formal model, cross-kingdom transfer)
- [ ] For each cell of the grid, record pass / partial / fail with the
      evidence (test, oracle entry, or review remark)
- [ ] Where a cell is partial or fail, tie it to a review item or a
      regression-gate skip so it is actionable
