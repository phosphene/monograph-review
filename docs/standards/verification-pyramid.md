---
uri: vi-foundry/standards/verification-pyramid
title: Verification Pyramid Standard — Unit, BDD, and the Integration Gap
author: Flow + Ed Phil
status: living
version: 1.0.0
updated: 2026-08-19
tags:
  - testing
  - bdd
  - verification-pyramid
  - py-arch-008
  - process
  - inferno-labs
---

# Verification Pyramid Standard

## The Three Layers

| Layer | What it tests | What it catches | What it misses |
|-------|-------------|----------------|---------------|
| **Unit (pytest, AAA)** | Individual functions in isolation | Logic errors, wrong formulas, edge cases | Integration errors — functions correct alone but wrong together |
| **BDD (behave, Gherkin)** | Emergent behavior — does the system do what it should? | Integration bugs, sign errors, wrong wiring between functions | Performance, edge cases at the boundary |
| **Simulacra (natural language)** | Human understanding — does the behavior match the science? | Conceptual errors — right math, wrong phenomenon | Nothing executable — it's documentation, not test |

## The Integration Gap

Unit tests verify that each function is correct in isolation. BDD verifies
that the system behaves correctly as a whole. The gap between them is where
integration bugs live — cases where individually correct functions produce
incorrect emergent behavior.

**Case study: `metropolis_sweep` (August 2026)**

The function used `s_new` where it should have used `s_old` in the ΔE
computation. This inverted the sign of the energy change, causing every
spin flip to be accepted regardless of temperature.

- **Unit tests:** `metropolis_accept` was tested directly and passed
  (it was always correct). `ising_hamiltonian` was tested directly and
  passed (also correct). The unit tests could not catch the bug because
  they tested the parts, not the whole.
- **BDD scenario:** "Metropolis sweep converges toward alignment at low
  temperature" — this scenario asks: does a 32×32 lattice magnetize
  after 1000 sweeps at T=1.5? The answer should be yes. The buggy
  version produced |M| = 0.0 — every flip accepted, no alignment.
  The BDD caught it because it tests the emergent property (magnetization)
  that no individual function computes.

The BDD scenario is a falsification test in the Braithwaite-Wisdom sense:
it derives an observable consequence from the hypothesis (the system should
magnetize below Tc) and checks it. If the consequence fails, something is
wrong — not necessarily the hypothesis, but something in the deductive chain
from axiom to observation.

## The Standard

### When writing new functionality:

1. **Write the unit tests first** (AAA pattern, deductive syllogism).
   Each function tested in isolation. This is the base of the pyramid.

2. **Write at least one BDD scenario that tests emergent behavior.**
   The scenario should ask a question about what the system DOES, not
   what any individual function returns. Good BDD scenarios ask:
   - Does the system converge?
   - Does the system produce the expected phase transition?
   - Does the system prefer the correct model?
   - Does the system detect the expected pattern?

3. **Write a simulacrum** (natural-language walkthrough) that connects
   the math to the science. The simulacrum is documentation, not test,
   but it serves as a human-readable check: if the simulacrum describes
   behavior that doesn't match the BDD scenario output, something is
   wrong with the understanding, not just the code.

### When reviewing existing functionality:

1. **Check for the integration gap.** Are there functions that are
   unit-tested individually but never tested together? That's the gap.
   Write a BDD scenario that exercises the integration.

2. **Check that BDD scenarios test emergent behavior, not just repeated
   unit tests.** A BDD scenario that calls a single function and checks
   its return value is a unit test in Gherkin syntax. It doesn't test
   integration. Good BDD scenarios test properties that emerge from
   the interaction of multiple functions.

### BDD scenario quality checklist:

- [ ] Does the scenario test behavior, not implementation?
- [ ] Does the scenario exercise at least two functions working together?
- [ ] Does the scenario ask a question that no single function can answer?
- [ ] Does the scenario have a clear pass/fail criterion tied to a
      scientific property (convergence, phase transition, model preference)?
- [ ] Could a domain expert read the scenario and understand what is
      being tested without reading the step definitions?

## Connection to Phosphene Standards

This standard operationalizes PY-ARCH-008 (verification pyramid):
- **Base:** Unit tests (deductive — each function proven correct)
- **Middle:** BDD (teleological — each behavior proven correct)
- **Top:** Simulacra (hermeneutic — each concept proven correct)

The three layers correspond to the three epistemic registers:
- Unit tests: verum factum (we know what we built because we built it)
- BDD: empirical (we test the deductive consequences against observation)
- Simulacra: geometrical (we study what the construction means)

A bug that passes all three layers is either not a bug or is so deep
in the assumptions that it requires revising the axiom set — which is
the Wisdom principle in action.
