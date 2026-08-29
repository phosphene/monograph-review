---
uri: docs/principles-genealogy
owner: edphos
status: living
updated: 2026-08-21
lineage: Aristotle → Ockham → Darwin → Beck → phosphene → framework-foundry
---

# A Genealogy of Principles

## The Claim

The technology changes. The principles don't. What follows is not a history of frameworks or languages — that's boring. This is a genealogy of the **principles** that shape how we build, test, and understand systems. Each principle has a prior. Each prior has a deeper prior. The lineage runs through philosophy of science, through evolutionary biology, through software engineering, and lands in a D3 dashboard on GitHub Pages.

## The Lineage

```
Aristotle — Formal causality (≈330 BCE)
        │
        ▼
Ockham — Parsimony (≈1320)
        │
        ▼
Darwin — Explain through measurable dynamics, not metaphysics (1859)
        │
        ▼
Popper — Falsifiability as demarcation (1934)
        │
        ▼
Beck — The test as epistemic probe (2003)
        │
        ▼
phosphene — Test as information, not gate (2014)
        │
        ▼
The Foundry — Spec as design probe + parsimony floor (2026)
```

## Principle 1: Parsimony

**Prior:** William of Ockham (~1320)
**Statement:** Entities should not be multiplied beyond necessity. Don't posit what you can't measure.

**In science:** Darwin didn't claim to know how variation arose. He claimed that variation exists and selection acts on it. The mechanism was below his budget floor. He explained what he could measure and stopped.

**In software:** Don't add abstractions, frameworks, or indirections unless they're necessary. The 2014 phosphene repo used React + webpack + Babel + Karma + Enzyme — that was the necessary stack for hot-loading D3 in 2014. The 2026 foundry uses vanilla D3 + ES modules + Jasmine — because that's all that's necessary now. The framework disappeared. The principle stayed.

**In the framework under review:** The bi-exponential holds at the food level. The budget floor is the parsimony floor. No pre-programming, no cognition, no mechanism claim below the observable dynamics. When the math works, you don't invoke intelligence — the structure explains itself. This is Ockham's razor applied to biology: don't posit a cognitive layer when a relaxation kinetics layer suffices.

**The inheritance:** Ockham → Darwin (explain through material constraints) → the foundry (the parsimony floor). The principle is the same: stop at what you can measure.

## Principle 2: Falsifiability

**Prior:** Karl Popper (1934)
**Statement:** A theory is scientific only if it can be proven wrong. The test is the demarcation.

**In science:** A theory that can accommodate any observation explains nothing. Einstein predicted the bending of light during an eclipse — a specific, falsifiable claim. If the light didn't bend, general relativity would have been wrong.

**In software:** A spec that can't fail isn't a spec — it's a tautology. The phosphene 2014 specs could fail: `expect(shallow(<Counter/>).find('h2').length).toBe(1)` — either the component renders an h2 or it doesn't. The 2026 foundry specs can fail: `expect(computeOpacity('uniform_42', new Set(['two_tier_42']))).toBe(0.1)` — either the function returns 0.1 or it doesn't.

**In the framework under review:** The bubble sort contrast. When Levin's sort didn't work, he called it intelligence. That's unfalsifiable — the failure confirms the thesis. The framework under review takes the opposite stance: the bi-exponential fit either holds or it doesn't. ΔBIC is a number. R² is a number. If the fit fails, the theory fails. That's the Popperian commitment.

**The inheritance:** Popper → test-informed development (the spec must be able to fail) → the foundry (the math must fit or the theory is wrong). The principle: if it can't be wrong, it can't be right.

## Principle 3: The Spec Precedes the Implementation

**Prior:** Aristotle's formal causality (~330 BCE) → Design by Contract (Meyer, 1988) → BDD (North, 2006) → phosphene test-informed (2014)
**Statement:** The form precedes the matter. The contract precedes the code. The spec precedes the implementation.

**In philosophy:** Aristotle distinguished material causality (what something is made of) from formal causality (what something is). The form of a house exists before the bricks are laid — the blueprint is the formal cause, the bricks are the material cause.

**In software:** The spec is the formal cause. The implementation is the material cause. TDD writes the test first (formal), then the code (material). Test-informed development — the phosphene variation — writes the spec as a **design probe**, not a gate. The spec asks: what should this be? Not: does this pass?

The `xdescribe` in the 2014 repo is the purest expression: the spec exists as form, marked pending, informing the design without blocking it. The implementation is then built to match the form.

**In the foundry:** The 38 specs were written before `cross-filter.js` existed. They defined `filterBySeeds(data, selectedSet) → filteredArray` — the formal cause. The implementation — `export function filterBySeeds(data, selectedSet) { ... }` — is the material cause, built to match.

**The inheritance:** Aristotle (formal causality) → Meyer (design by contract) → North (BDD: spec as behavior) → phosphene (spec as information) → the foundry (spec as interface blueprint). The principle: figure out what the thing should be before you build it.

## Principle 4: Isolation of Logic from IO

**Prior:** Aristotle's distinction between theoretical and practical knowledge → Dijkstra (1974: "On the role of scientific thought") → Hermetic Modular pattern (the foundry, 2026)
**Statement:** Pure logic should not depend on its environment. The function that computes should not be the function that renders.

**In philosophy:** Aristotle distinguished episteme (theoretical knowledge — pure, universal) from techne (practical knowledge — applied, situated). A theorem in geometry doesn't change when you draw it on paper vs. chalkboard. The logic is independent of the medium.

**In software:** Dijkstra said: "The art of programming is the art of organising unorganisation." The pure function — `filterBySeeds(data, set) → array` — knows nothing about D3, SVG, the DOM, or the browser. It operates on data structures. The renderer — `renderScatter({container, data, ...})` — takes the result and paints it. Logic here, IO there.

**In the foundry:** The pure functions (`getAllDataPoints`, `filterBySeeds`, `computeOpacity`, `getSelectedSeeds`, `generateTrajectory`) have zero DOM dependency. They're testable from Node, from a browser, from any harness. The renderers take a config object and return an SVG selection. No hidden state. No side effects beyond the DOM they're given.

**In the framework under review:** The Logic/IO Separation axiom. The mathematical model — ρ(t) = f·e^(−k₁t) + s·e^(−k₂t) — is pure logic. The simulation that produces the data is IO. The fit that recovers parameters is logic. The visualization that displays them is IO. You can run the model with paper and pencil. You need a computer for the simulation.

**The inheritance:** Aristotle (episteme vs. techne) → Dijkstra (logic vs. hardware) → the foundry (pure functions vs. renderers). The principle: the computation is independent of the medium.

## Principle 5: Genealogical Thinking

**Prior:** Nietzsche's *Genealogy of Morals* (1887) → Foucault's *Archaeology of Knowledge* (1969)
**Statement:** To understand a thing, trace its descent. What you see today is the product of what came before, transformed through transmission.

**In philosophy:** Nietzsche didn't ask "what is morality?" He asked: "where did this morality come from? What pressures shaped it?" The answer reveals that what seems eternal and necessary is actually contingent — the product of a specific history that could have gone differently.

**In software:** A framework isn't just a framework. It's the product of a lineage of ideas, each inherited from a prior, each transformed by the generation that received it. React inherits from MVC. MVC inherits from Smalltalk. Smalltalk inherits from Simula. Simula inherits from the formal causality tradition. The stack changes. The questions persist.

**In this project:** The cross-filter dashboard inherits from phosphene (2014). Phosphene inherits from Beck's TDD. TDD inherits from BDD. BDD inherits from design by contract. The technology — dc.js → D3 v7, Karma → Jasmine standalone, React → vanilla — is the contingent layer. The principles — spec-first, pure functions, parsimony — are the necessary layer.

**The inheritance:** Nietzsche → Foucault → this document. The principle: trace the descent, and you see what's contingent (the tech) and what's necessary (the principles).

## The Consolidation

| Principle | Philosophical Prior | Software Inheritance | Framework Expression |
|-----------|--------------------|-----------------------|------------------------|
| Parsimony | Ockham (~1320) | Minimal stack, no unnecessary frameworks | Budget floor = parsimony floor |
| Falsifiability | Popper (1934) | Specs that can fail | ΔBIC is a number, not a narrative |
| Spec precedes implementation | Aristotle (~330 BCE) | Test-informed development | 38 specs before the module |
| Logic isolated from IO | Aristotle / Dijkstra (1974) | Pure functions vs. renderers | Logic/IO Separation axiom |
| Genealogical thinking | Nietzsche (1887) | This document | Trace the descent |

## What This Document Is

This is not a README. It's not a tech doc. It's a genealogy — a tracing of descent through ideas. The technology is the contingent layer: React → vanilla, dc.js → D3 v7, Karma → Jasmine. The principles are the necessary layer: parsimony, falsifiability, spec-first, logic/IO isolation, genealogical thinking.

The phosphene contribution was specific: applying test-informed development to interactive visualization. The foundry inheritance is specific: carrying that discipline forward with a lighter stack, a richer domain, and a deeper lineage.

The genealogy matters because it reveals that the principles are older than the tech. Ockham's razor is older than software. Aristotle's formal causality is older than D3. Popper's falsifiability is older than Jasmine. What we're doing is inheriting these principles and applying them to a new medium — the same way every generation does.

---

*This document is part of the Foundry genealogy series. The prior is phosphene (2014). The principles are older. The inheritance is the discipline.*
