---
uri: vi-foundry/standards/inference-packets
title: Inference Packets — Structured Knowledge for Research-Active LLMs
author: Marsyas + Ed Phil
status: living
version: 1.0.0
updated: 2026-08-19
tags:
  - inference-packets
  - research-practice
  - scientific-method
  - llm
  - inferno-labs
---

# Inference Packets — Structured Knowledge for Research-Active LLMs

> Packets are self-contained knowledge modules designed for LLM ingestion.
> Each packet captures a fundamental research activity: what it is, what
> the LLM can do well, what it can't, and how it connects to the other
> activities in the research cycle.
>
> Packets are written in the axiomatic-hypothetical register: assertive
> commitments, not hedged suggestions. Each claim is open to revision
> without destroying the framework.

---

## Packet 1 — The Research Cycle: Fundamental Mechanics of Science Production

### 1.1 What This Packet Is

A structured description of the core research loop — the cycle of
activities that produce scientific knowledge. Not a methodology textbook.
A set of commitments about what each activity *is*, what it *requires*,
and how an LLM participates in it.

The cycle:

```
Hypothesis Generation
       ↓
Experiment Planning
       ↓
Data Labeling / Curation
       ↓
Prediction
       ↓
Execution & Measurement
       ↓
Results Interpretation
       ↓
Hypothesis Revision (→ back to top)
```

Each stage feeds the next. The cycle is recursive — interpretation
generates new hypotheses. The cycle is not linear in practice; stages
overlap, iterate, and branch. But the *structure* is what makes it
science rather than unsystematic observation.

### 1.2 Hypothesis Generation

**What it is:** The act of committing to a specific, testable claim about
the phenomenon under study. A hypothesis is not a topic ("let's study X")
or a question ("does X cause Y?"). It is an assertion: "X causes Y under
conditions Z." The assertion is the hypothesis. Its specificity is its
scientific value.

**Braithwaite-Wisdom framing:** A hypothesis is an axiom you commit to.
Its status — generalization or non-instantial — determines what kind of
test is available. A generalization ("arsenic is poisonous") can be tested
by observing instances. A non-instantial hypothesis ("gravitational
attraction follows 1/r²") requires a deductive chain connecting to
observable consequences. Most productive scientific hypotheses sit
between these poles.

**What the LLM does well:**
- Generating multiple candidate hypotheses from a domain survey. The
  model can survey a conceptual space and produce candidates that a
  single researcher might miss.
- Identifying the *type* of hypothesis (generalization vs. non-instantial)
  and therefore the kind of test it requires.
- Checking internal consistency: does the hypothesis contradict itself?
  Does it contain hidden assumptions that should be made explicit?
- Cross-domain hypothesis transfer: taking a hypothesis structure from
  one field and recognizing its applicability in another (see War Story
  #6 — Cross-Domain Method Transfer).

**What the LLM does poorly:**
- Judging whether a hypothesis is *interesting* vs. merely *testable*.
  The model tends toward the obvious. Interesting hypotheses often
  come from the researcher's domain expertise and intuition.
- Knowing when to stop generating candidates. The model will produce
  more; the researcher must select.

**Connection to next stage:** A hypothesis is not testable until it has
been specified to the point where an experiment can distinguish it from
its alternatives. Hypothesis generation flows into experiment planning.

### 1.3 Experiment Planning

**What it is:** The design of a procedure that will produce evidence
capable of confirming or disconfirming the hypothesis. The plan must
specify: what will be measured, under what conditions, with what controls,
and what outcomes would count as confirmation vs. disconfirmation.

**The critical commitment:** The experiment plan must be specified
*before* the data are examined. This is not a moral injunction — it is
an epistemic requirement. If the criterion for confirmation is chosen
after seeing the results, the test is not a test. It is a description
dressed as a test.

**What the LLM does well:**
- Specifying the deductive chain: given the hypothesis, what observable
  consequences follow? What measurements would distinguish the
  hypothesis from its alternatives?
- Identifying confounds and control conditions. The model can survey
  the space of alternative explanations for a predicted result and
  specify what controls would rule them out.
- Generating sample size estimates from effect size assumptions.
- Structuring the plan as a proof object: seeded, deterministic,
  reproducible.

**What the LLM does poorly:**
- Judging feasibility. The model doesn't know what equipment, time, or
  data access is available. It will propose experiments that are
  logically sound but practically impossible.
- Judging whether the planned measurement has enough resolution to
  distinguish the hypothesis from its alternatives. The model can
  compute statistical power but may miss domain-specific noise sources.

**Connection to next stage:** The experiment plan specifies what data
will be collected and how. This flows into data labeling.

### 1.4 Data Labeling and Curation

**What it is:** The assignment of meaning to raw measurements. A
temperature reading is a number; labeling it as "ambient temperature
at time t under condition C" is the act that makes it data. Without
labels, measurements are noise. With labels, they become evidence.

**The key distinction:** Data labeling is not the same as data
interpretation. Labeling is the assignment of *what* the measurement is
(its provenance, conditions, units, reliability). Interpretation is
the assignment of *what the measurement means* for the hypothesis.
Labeling happens before interpretation. If labeling is contaminated by
the desired interpretation, the test is compromised.

**What the LLM does well:**
- Generating consistent labeling schemas across large datasets. The
  model can apply a labeling protocol uniformly, which is where human
  labelers introduce inter-rater drift.
- Detecting label inconsistencies: flagging measurements that are
  labeled differently under the same conditions.
- Proposing controlled vocabularies for labels, drawing on
  domain-specific terminology.

**What the LLM does poorly:**
- Judging whether a label accurately describes the measurement. The
  model doesn't have access to the measurement context — it sees the
  number, not the apparatus that produced it.
- Handling edge cases in labeling where domain expertise is needed
  to classify ambiguous measurements.

**Connection to next stage:** Labeled data flows into prediction —
the hypothesis must generate specific predictions about the labeled
measurements.

### 1.5 Prediction

**What it is:** The derivation of specific expected outcomes from the
hypothesis, *before* the data are examined. A prediction is the
deductive consequence of the hypothesis combined with the experimental
setup. "If H is true and the experiment is run under conditions C, then
measurement M will fall in range R."

**The epistemic structure:** This is the Braithwaite deductive chain
made operational. The hypothesis is the axiom. The experimental setup
provides the auxiliary premises. The prediction is the observable
consequence. The test is whether the actual measurement falls in the
predicted range.

**What the LLM does well:**
- Deriving predictions from hypotheses when the mathematical structure
  is explicit. Given H and the experimental setup, the model can
  compute what should be observed.
- Generating the full prediction space: not just the expected outcome
  but the range of outcomes that would count as confirmation,
  ambiguity, or disconfirmation.
- Computing effect sizes, confidence intervals, and the statistical
  power of the planned test.

**What the LLM does poorly:**
- Recognizing when a prediction is trivially true (tautological) vs.
  genuinely risky. A prediction that can't fail isn't a prediction.
  The model sometimes produces "predictions" that are definitions
  rather than empirical commitments.
- Judging whether the predicted effect size is large enough to be
  measurable with available instruments.

**Connection to next stage:** Predictions are tested against actual
measurements during execution.

### 1.6 Execution and Measurement

**What it is:** The physical act of running the experiment and recording
measurements. In computational science, this is the simulation run; in
empirical science, this is the lab or field procedure.

**What the LLM does well:**
- Executing computational experiments: running simulations, generating
  synthetic data, fitting models. This is where the model's code-writing
  capacity directly serves the research cycle.
- Logging: maintaining structured records of what was run, with what
  parameters, producing what outputs.

**What the LLM does poorly:**
- Anything requiring physical apparatus, field observation, or
  wet-lab work. The model cannot execute empirical experiments.
- Judging whether a measurement anomaly is instrument noise or a
  real signal. This requires domain expertise the model doesn't have.

**Connection to next stage:** Raw measurements flow into results
interpretation.

### 1.7 Results Interpretation

**What it is:** The act of determining what the measurements mean for
the hypothesis. This is *not* "what do the results show?" — it is
"do the results confirm, disconfirm, or leave ambiguous the specific
predictions derived from the hypothesis?"

**The critical discipline:** Interpretation must be consistent with
the hypothesis and experiment plan. If the plan said "outcome X confirms
H" and outcome X occurred, the result is confirmation — regardless of
whether the researcher *wants* H to be true. If the plan said "outcome
X disconfirms H" and outcome X occurred, the result is disconfirmation.
The interpretation is constrained by the plan, not free-floating.

**What the LLM does well:**
- Comparing actual results to the prediction space. The model can
  determine whether the measurement falls in the confirmation,
  ambiguity, or disconfirmation region defined before the experiment.
- Computing statistical tests: AIC, likelihood ratios, Bayesian
  updating. The model can apply the statistical machinery specified
  in the plan.
- Flagging interpretation that drifts from the plan. If the
  researcher starts reinterpreting a disconfirming result as
  "actually confirming if you think about it differently," the model
  can catch this — *if* the original plan was explicit.

**What the LLM does poorly:**
- Judging whether an unexpected result is a measurement error, a
  confound, or a genuine anomaly that should revise the hypothesis.
  The model tends toward the first two (explain it away) rather than
  the third (take it seriously).
- Knowing when to abandon a hypothesis vs. revise it. The model
  will often propose *ad hoc* modifications to save a hypothesis
  rather than admitting disconfirmation. This is the human's
  judgment.

**Connection to next stage:** Interpretation either closes the cycle
(hypothesis confirmed or disconfirmed → new hypothesis needed) or
identifies ambiguity requiring a refined experiment (→ back to
experiment planning with revised design).

### 1.8 Hypothesis Revision

**What it is:** The response to results. If confirmed, the hypothesis
is strengthened but not proven — it survives to face the next test. If
disconfirmed, the hypothesis must be revised or abandoned. If ambiguous,
the experiment was insufficient — a better experiment is needed.

**The Wisdom principle:** Revision is not failure — it is the process
working. A non-instantial hypothesis is revised through its deductive
consequences. The empirical record (the measurements) are preserved; the
axiom set (the hypothesis) is what changes. This is the structure Wisdom
identified: assertive axioms, revisable without destroying the empirical
record.

**What the LLM does well:**
- Generating candidate revisions: given a disconfirmed hypothesis,
  what minimal modification would make it consistent with the data?
  The model can survey the space of possible revisions.
- Checking revision consistency: does the revised hypothesis still
  generate testable predictions? Or has it become unfalsifiable
  (Wisdom's Level 1 — structurally untestable)?
- Identifying which assumption in the hypothesis was the likely
  source of failure.

**What the LLM does poorly:**
- Judging whether a revision is a genuine improvement or an *ad hoc*
  rescue. The model will often propose the smallest possible change,
  which may preserve the hypothesis without actually improving it.
- Knowing when to abandon rather than revise. Some hypotheses should
  be given up. The model doesn't have the domain judgment to know
  when the evidence is strong enough to walk away.

---

## Packet Design Principles

These packets are designed for LLM ingestion. The principles:

1. **Explicit structure.** Each activity is a named section with
   defined subcomponents. The LLM can navigate the packet by section
   heading, not by reading linearly.

2. **Explicit claims.** "The LLM does well at X" is an assertion, not
   a suggestion. The assertion can be wrong — that's what makes it
   useful. Vague claims ("the LLM may have some capability in this
   area") are not testable.

3. **Defined terms.** "Hypothesis," "prediction," "interpretation" —
   each term is defined in place. The LLM doesn't need to infer what
   we mean from context.

4. **Deductive chain visible.** The connections between stages are
   stated explicitly. The LLM can trace: hypothesis → prediction →
   measurement → interpretation → revision.

5. **Honest constraints.** Each packet states what the LLM does
   poorly. This is not modesty — it's calibration. The constraints
   are as important as the capabilities.

6. **Axiomatic-hypothetical register.** Commitments, not hedging.
   Each claim is assertive and revisable. The register is the one
   we established in the Braithwaite-Wisdom formulation: assert
   boldly, derive rigorously, revise honestly.

---

## Planned Packets

| # | Topic | Status |
|---|-------|--------|
| 1 | The Research Cycle: Fundamental Mechanics | ✅ This document |
| 2 | Domain Vocabulary and Glossary Construction | Planned |
| 3 | Citation Practices and Verification | Planned |
| 4 | Document Architecture for Bot-Readable Science | Planned |
| 5 | Cross-Domain Analogy and Method Transfer | Planned |
| 6 | Statistical Reasoning and Model Comparison | Planned |
| 7 | Falsification, Confirmation, and the Boundary | Planned |
| 8 | The Recursive Process: Iteration and Emergence | Planned |
