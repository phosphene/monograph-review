---
uri: docs/test-informed-genealogy
owner: edphos
status: living
updated: 2026-08-21
prior: phosphene/react-d3-hotload-test-demo (2014)
descendant: docs/review/cross-filter-dashboard.html (2026)
lineage: TDD → test-informed development → spec-first design
---

# Test-Informed Development: A Genealogy

## The Lineage

```
Kent Beck — Test-Driven Development (TDD, ~2003)
        │
        ▼
Ed Phil / phosphene — Test-Informed Development (~2014)
        │
        ▼
FlowFeel / valence-foundry — Spec-First D3 (2026)
```

## What TDD Is

Kent Beck's TDD: write the test, watch it fail, write the code, watch it pass, refactor. Red-Green-Refactor. The test *drives* the implementation — it fails first, then you make it pass. The cycle is tight: seconds, not minutes. The test is the motor.

## What Test-Informed Development Is

Test-informed development is a play on TDD that Ed Phil and phosphene adopted in 2014. The distinction:

**TDD says:** The test *drives* the code. Write it first, make it fail, then make it pass.

**Test-informed says:** The test *informs* the design. Write the spec first, but not as a failure motor — as a **design probe**. The spec asks: what should this thing do? What's the API? What are the inputs and outputs? The spec is information about the system you're building, gathered before you build it.

The difference is subtle but real:

| TDD | Test-Informed |
|-----|---------------|
| Test fails → write code to pass | Spec describes → design API to satisfy |
| Tight red-green cycle | Spec is a design document that happens to be executable |
| Test is the motor | Test is the blueprint |
| Focus on coverage | Focus on interface |
| "Does it work?" | "What should it be?" |

In the phosphene 2014 repo, this looked like:

```js
// Counter-test.js — the spec INFORMS the component API
xdescribe("A suite", function() {
  it("contains spec with an expectation", function() {
    expect(shallow(<Counter store={this.props.appState}/>).find('h2').length).toBe(1);
  });
});
```

The spec was written first. It said: "a Counter renders an h2." That informed the component's API — it needs to render an h2, it takes a store prop. The implementation was then built to satisfy that informed design.

The `xdescribe` prefix (Jasmine's pending marker) is telling: the spec existed but was marked pending — it was **information**, not a gate. It informed the developer about what should be true without blocking the build.

## The 2026 Inheritance

The foundry cross-filter dashboard inherits this exact posture. The spec file `test/d3-dashboard.spec.js` was written before the implementation. Its describe blocks are design probes:

```js
describe('filterBySeeds', () => {
  it('should return all data when selectedSet is empty', () => {
    const result = filterBySeeds(allPoints, new Set());
    expect(result.length).toBe(4);
  });
});
```

This spec says: "filterBySeeds takes data and a Set, returns filtered data, empty Set means return all." That **informs** the function signature — `filterBySeeds(data, selectedSet) → filteredArray` — before the function exists. The implementation is then shaped by what the spec told us the API should be.

The pure functions are the key inheritance. By isolating `getAllDataPoints`, `filterBySeeds`, `computeOpacity`, `getSelectedSeeds`, `generateTrajectory` from any DOM dependency, the spec can test them from Node, from a browser, from any harness. The functions don't know about D3. They don't know about SVG. They know about data and Sets. That's test-informed: the spec told us the functions should be pure, so they are.

## Why "Informed" Not "Driven"

TDD drives the code: the test's failure is the force that moves implementation forward. Test-informed doesn't use failure as a motor. It uses the spec as a **thinking tool** — a way to figure out what you're building before you build it. The spec might be pending (`xdescribe`). It might not cover every branch. It might not run in CI. What it does is force you to design the interface first.

This is closer to what Michael Feathers called "characterization tests" or what Freeman & Pryce described in *Growing Object-Oriented Software* — tests as a way to understand and shape the system, not just verify it. The phosphene contribution was applying this posture to **interactive visualization**: writing specs for D3 components before the components exist, using the spec to figure out what the dashboard should do.

## The Deeper Lineage

The test-informed posture has roots in several traditions:

1. **BDD (Dan North, ~2006):** "Behavior-driven development" reframed TDD from "test" to "specification." The spec describes behavior, not implementation. Jasmine's `describe`/`it`/`expect` syntax comes from this tradition.

2. **Design by Contract (Bertrand Meyer, ~1988):** Preconditions, postconditions, invariants. The spec defines what the function promises before you write it. Test-informed inherits this: the spec defines the contract.

3. **Specification by Example (Gojko Adzic, ~2011):** Concrete examples as the specification. The test data IS the spec. Our mock data in `d3-dashboard.spec.js` — `{ seed: 42, k1: 0.5146, k2: 0.8062, ... }` — is specification by example.

4. **Exploratory Programming (phosphene, 2014):** The 2014 repo's `react-hot-loader` setup was exploratory: change the code, see it live, tests alongside. The spec informs the exploration — it's the compass, not the gate.

## The Pattern Across Generations

| Generation | Year | Spec Style | Test as | Failure as |
|-----------|------|-----------|---------|------------|
| Beck TDD | 2003 | JUnit `test*` methods | Gate | Motor |
| North BDD | 2006 | `describe`/`it`/`should` | Specification | Information |
| phosphene TID | 2014 | Jasmine + Enzyme | Design probe | None (pending ok) |
| the foundry | 2026 | Jasmine + ES modules | Interface blueprint | None (spec-first) |

## What phosphene Contributed

The specific contribution was applying test-informed development to **interactive D3 visualization**. In 2014, most D3 work was exploratory — you wrote a chart, looked at it in the browser, tweaked it. Tests were rare. The phosphene repo said: you can spec a dashboard before you build it. The spec tells you what the charts should render, what the filters should do, what the API should be.

That insight — that visualization benefits from test-informed design just as much as business logic — is the genealogical contribution. The foundry inherits it: the cross-filter dashboard was spec'd before it was built, and the spec is still live, testing the real module, on GitHub Pages.

## Artifacts

| Artifact | Location | Role |
|----------|----------|------|
| phosphene repo (2014) | `github.com/phosphene/react-d3-hotload-test-demo` | Prior — test-informed D3 with Karma/Jasmine/Enzyme |
| the foundry spec (2026) | `test/d3-dashboard.spec.js` | 38 specs — the design probe |
| the foundry module (2026) | `docs/review/js/cross-filter.js` | Implementation — shaped by the spec |
| the foundry runner (2026) | `docs/test-runner.html` | Live Jasmine runner — tests the real module |
| D3 genealogy doc | `docs/d3-genealogy.md` | Technology lineage (dc.js → D3 v7) |
| This document | `docs/test-informed-genealogy.md` | Methodology lineage (TDD → TID → spec-first) |

---

*This document is part of the Foundry genealogy series — tracing the lineage of ideas, methods, and code through the projects that shaped them. The prior is phosphene (2014). The methodology is test-informed development. The inheritance is the discipline: spec first, design from outside in, pure functions, test the real thing.*
