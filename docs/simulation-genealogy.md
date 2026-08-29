---
uri: docs/simulation-genealogy
owner: edphos
status: living
updated: 2026-08-21
prior: phosphene/react-d3-hotload-test-demo (2014)
lineage: phosphene dashboards → framework simulacra → cross-filter dashboard
descendant: docs/review/cross-filter-dashboard.html (2026)
---

# Simulation as Proving Ground: A Genealogy

## The Claim

The cross-filter dashboard is not just a visualization. It's a **simulation proving ground** — the latest in a lineage of simulations used to test theoretical claims before they face empirical data. This genealogy traces how simulation evolved from a design tool in the phosphene D3 work to an epistemic instrument in the framework under review.

## The Lineage

```
phosphene D3 dashboards (2014) — simulation as design probe
        │
        ▼
Framework simulacra (2025) — simulation as epistemic instrument
        │
        ▼
Cross-filter dashboard (2026) — simulation as proving ground
```

## Phase 1: Simulation as Design Probe (phosphene, 2014)

The phosphene D3 dashboards — `NasDashDC`, `VcDashboardDC`, `ThrashDashDC` — were interactive simulations of financial data. They weren't testing a theory. They were **probing a design space**: what does the data look like when you filter it? What patterns emerge when you brush across dimensions?

The dashboards used dc.js cross-filtering: brush a range on one chart, watch the others re-aggregate. This was simulation in the design sense — you simulate the user's interaction with the data to figure out what the dashboard should do.

**What was simulated:** The user's exploratory process. The dashboard was a model of how an analyst thinks — filter, compare, drill down.

**What was proved:** The design. Does the cross-filter pattern work? Does brushing produce insight? The simulation proved the dashboard's design before it was deployed.

**The test-informed connection:** The specs (Karma + Jasmine) simulated the component's behavior: "when given this data, does it render this many elements?" The test was a simulation of the component's contract. The spec was the proving ground for the implementation.

## Phase 2: Simulation as Epistemic Instrument (framework simulacra, 2025)

The framework under review introduced simulacra — simulations that test theoretical claims. The foundry contains generative scripts across several directories:

- `inst/simulacra/generate_relaxation.R` — simulate bi-exponential decay from known parameters
- `inst/simulacra/generate_cross_kingdom.R` — simulate cross-kingdom gene transfer
- `inst/genealogy/generate_cusp.R` — simulate cusp catastrophe dynamics
- `inst/genealogy/generate_drift_selection.R` — simulate drift vs selection balance
- `inst/genealogy/generate_ising.R` — simulate Ising model phase transitions
- `inst/genealogy/generate_landau.R` — simulate Landau theory energy landscapes
- `scripts/genealogy/generate_upcycle.py` — simulate upcycling dynamics

These are not design probes. They are **epistemic instruments**. Each simulacrum asks: if the theory is correct, what should we observe? The simulation produces a prediction. The prediction faces empirical data. If they match, the theory gains support. If they don't, the theory fails.

**What was simulated:** The theory's predictions. The bi-exponential relaxation model says: organisms with multi-level integration should show two-timescale decay. The simulacrum generates this prediction from known parameters.

**What was proved:** The theory. Does the bi-exponential hold when you generate data from the model's own parameters? Can you recover the parameters from the generated data? The genealogy simulacrum (Stage 6) answers: yes, with ΔAIC = −89.99 and parameter recovery within 9-14%.

**The Popperian connection:** The simulacrum is a falsifiability engine. If the simulation can't recover its own parameters, the theory is wrong. The simulation is the proving ground for the theory — not a narrative about it.

## Phase 3: Simulation as Proving Ground (Cross-filter dashboard, 2026)

The cross-filter dashboard unifies both lineages. It is simultaneously:

1. **A design probe** (phosphene inheritance): the cross-filter pattern tests whether linked views produce insight
2. **An epistemic instrument** (simulacra inheritance): the bi-exponential trajectory generation tests whether the model's parameters produce the predicted decay
3. **A proving ground** (the synthesis): the dashboard runs the simulation in the browser — ρ(t) = f·e^(−k₁t) + s·e^(−k₂t) — and lets you interact with the results

The `generateTrajectory()` function in `cross-filter.js` is the bridge:

```js
export function generateTrajectory(seed, t) {
  const { k1, k2, fast_fraction, slow_fraction } = seed;
  return t.map(function (ti) {
    return fast_fraction * Math.exp(-k1 * ti) + slow_fraction * Math.exp(-k2 * ti);
  });
}
```

This is not a chart. This is a **simulation running in the browser**. The fitted parameters from the Python GRN simulation — k₁, k₂, fast_fraction, slow_fraction — are fed back into the model equation, and the browser generates 20 trajectories in real time. The visualization IS the simulation.

And the spec tests it:

```js
describe('generateTrajectory', () => {
  it('should return 1.0 at t=0', () => {
    const rho = generateTrajectory(seed, [0]);
    expect(rho[0]).toBeCloseTo(1.0, 10);
  });
  it('should produce strictly decreasing values', () => {
    const rho = generateTrajectory(seed, [0, 1, 2, 5, 10]);
    for (let i = 1; i < rho.length; i++) {
      expect(rho[i]).toBeLessThan(rho[i - 1]);
    }
  });
});
```

The spec is the proving ground for the simulation. The simulation is the proving ground for the theory. The theory is the proving ground for the parsimony claim. And the parsimony claim traces back to Ockham.

## The Consolidation

| Phase | Year | What's simulated | What's proved | The test |
|-------|------|-----------------|---------------|-----------|
| Design probe | 2014 | User exploration | Dashboard design | Karma + Jasmine specs |
| Epistemic instrument | 2025 | Theory's predictions | The theory itself | Parameter recovery, ΔAIC |
| Proving ground | 2026 | Both | Design + theory | 38 specs + live dashboard |

## The Deep Principle

Simulation has always served a dual role: it **designs** (what should this be?) and it **proves** (is this claim true?). The phosphene dashboards were design simulations. The framework simulacra were epistemic simulations. The cross-filter dashboard is both — and that unification is the contribution.

The genealogy reveals that "proving ground" is the right metaphor. A proving ground is where you test something before you deploy it. The phosphene tradition proved the design. The framework tradition proves the theory. The dashboard proves both — and it does it in the browser, interactively, with the spec watching.

## Artifacts

| Artifact | Phase | What it proves |
|----------|-------|---------------|
| phosphene `Counter-test.js` (2014) | Design probe | Component renders correctly |
| phosphene dc.js dashboards (2014) | Design probe | Cross-filter produces insight |
| framework simulacra `generate_relaxation.R` (2025) | Epistemic | Bi-exponential recovers its own params |
| framework genealogy Stage 6 (2025) | Epistemic | ΔAIC = −89.99, param recovery 9-14% |
| `cross-filter.js` `generateTrajectory()` (2026) | Proving ground | Bi-exponential runs in-browser, spec-verified |
| `d3-dashboard.spec.js` (2026) | Proving ground | 38 specs test the real simulation module |
| `cross-filter-dashboard.html` (2026) | Proving ground | Interactive simulation + cross-filter |

---

*This document is part of the Foundry genealogy series. The prior is phosphene (2014). The methodology is simulation as proving ground. The inheritance: design probe + epistemic instrument = proving ground.*
