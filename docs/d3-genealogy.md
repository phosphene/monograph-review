---
uri: docs/d3-genealogy
owner: edphos
status: living
updated: 2026-08-21
prior: phosphene/react-d3-hotload-test-demo (2014)
descendant: docs/review/cross-filter-dashboard.html (2026)
---

# D3 Genealogy: From phosphene to The Foundry

## The Prior

**Repository:** [`phosphene/react-d3-hotload-test-demo`](https://github.com/phosphene/react-d3-hotload-test-demo)
**Year:** 2014
**Stack:** React + d3act + dc.js + webpack + react-hot-loader + mobx + Babel (ES6/ES7) + ESLint (airbnb preset)
**Testing:** Karma + Jasmine + Enzyme (shallow/mount/render)

### What it established

The 2014 repo demonstrated a **test-informed development environment** for D3: write the spec first, then build the component to pass it. The test file `Counter-test.js` used Jasmine BDD style (`describe`/`it`/`expect`) with Enzyme for DOM assertions:

```js
xdescribe("A suite", function() {
  it("contains spec with an expectation", function() {
    expect(shallow(<Counter store={this.props.appState}/>).find('h2').length).toBe(1);
  });
});
```

The dashboards themselves — `BarSingleSelectDC`, `HeatMapFilteringDC`, `NasDashDC`, `NasDashDCBubble`, `NasDashDCTimeSeries`, `VcDashboardDC`, `ThrashDashDC`, `ThrashDashDCBubble` — were cross-filtered dc.js dashboards: brush one chart, watch the others react. This was the pattern before "linked views" became a D3 community standard.

### Key methodological commitments

1. **Spec-first:** The test describes expected behavior before implementation exists
2. **Pure functions where possible:** Data transformations testable in isolation
3. **Design from the outside in:** The API is shaped by what the caller needs, not what the implementer finds convenient
4. **Hot-loading:** Changes appear without browser reload — the test informs the implementation in real time

## The Descendant

**Repository:** [`phosphene/monograph-review`](https://github.com/phosphene/monograph-review)
**Year:** 2026
**Stack:** Vanilla D3 v7 + ES Modules + Jasmine 5 standalone (no React, no webpack, no build step)
**Testing:** Jasmine BDD — 38 specs across 10 describe blocks

### What it inherited

The cross-filter dashboard at `docs/review/cross-filter-dashboard.html` and its implementation module `docs/review/js/cross-filter.js` trace a direct lineage to the 2014 phosphene repo:

| Trait | phosphene (2014) | the foundry (2026) |
|-------|-----------------|-------------------|
| Spec style | Jasmine `describe`/`it`/`expect` | Jasmine `describe`/`it`/`expect` |
| Test file naming | `Component-test.js` | `d3-dashboard.spec.js` |
| DOM assertions | Enzyme `shallow`/`mount`/`render` | `querySelectorAll` + `getAttribute` |
| Cross-filtering | dc.js linked charts | D3 v7 brush + click with `Set`-based selection |
| Pure functions | mobx stores | `getAllDataPoints`, `filterBySeeds`, `computeOpacity`, `getSelectedSeeds`, `generateTrajectory` |
| Hot-loading | react-hot-loader + webpack | ES modules + deferred `<script type="module">` (browser-native) |
| Dashboard pattern | BarSelect, HeatMapFilter, NasDash, VcDashboard, ThrashDash | Scatter (brush), Bars (click), Trajectories (click), R² (reactive) |

### What evolved

1. **No build step.** The 2014 repo required webpack + Babel + react-hot-loader. The 2026 version uses native ES modules — the browser handles loading. The test runner loads the real module via `<script type="module">`, which resolves before Jasmine's `window.onload` boot. No race, no copy, no drift.

2. **No framework.** React + d3act → vanilla D3. The cross-filter orchestration is 15 lines of `updateAll()`. The pure functions have zero DOM dependency — testable from Node, browser, or any harness.

3. **The spec tests the real module.** The 2014 Karma config ran tests against webpack-bundled code. The 2026 runner loads `docs/review/js/cross-filter.js` directly — if the module drifts from the spec, the runner fails. The test runner is live at `https://phosphene.github.io/monograph-review/test-runner.html`.

4. **Domain-agnostic filtering.** The 2014 dashboards were hard-coded to financial data (NASDAQ, VC, beer). The 2026 pure functions operate on keyed data points — swap `seed` for `ticker` or `date` and you have a financial instrument explorer. The cross-filter logic doesn't care what the data represents.

## The Genealogy

```
phosphene/react-d3-hotload-test-demo (2014)
├── dc.js dashboards (BarSelect, HeatMapFilter, NasDash, VcDashboard, ThrashDash)
├── Karma + Jasmine + Enzyme testing
├── React hot-loading pattern
└── Spec-first development methodology
        │
        ▼
phosphene/monograph-review (2026)
├── D3 v7 cross-filter dashboard (scatter, bars, trajectories, R²)
├── Jasmine 5 standalone (38 specs, real module under test)
├── ES modules + deferred loading (browser-native hot reload)
└── Test-informed development (spec → implementation → pass)
```

## The Pattern Transfer

The methodological inheritance is not the technology stack — that changed entirely. It's the **discipline**:

1. Write the spec first. The spec describes what the thing should do, not how to build it.
2. Design the API from the outside in. What does the caller need? What functions exist?
3. Isolate pure functions from DOM effects. Data transformations should be testable without a browser.
4. The test runner tests the real artifact, not a copy. If the module drifts, the runner breaks.

This is the phosphene tradition: test-informed, not test-driven. The spec doesn't verify after the fact — it informs the design before the fact. The 2014 insight holds: writing the spec first forces you to think about the interface before the implementation, and that thinking produces better code.

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| Implementation module | `docs/review/js/cross-filter.js` | ES module: pure functions + D3 renderers |
| Dashboard page | `docs/review/cross-filter-dashboard.html` | Live interactive dashboard |
| Spec file | `test/d3-dashboard.spec.js` | 38 Jasmine BDD specs |
| Spec copy (GH Pages) | `docs/d3-dashboard.spec.js` | Same spec, served from docs/ |
| Test runner | `docs/test-runner.html` | Jasmine standalone, loads real module |
| Interactive explorer | `docs/review/interactive-simulation.html` | Slider-based bi-exponential explorer |
| Simulation review (R) | `scripts/render_simulation_review.R` | ggplot2 + patchwork figures |
| Python export | `lib/python/grn/scripts/export_grn_results.py` | JSON data pipeline |

## Prior Repository

The 2014 phosphene repo is public at:
`https://github.com/phosphene/react-d3-hotload-test-demo`

It contains:
- `src/components/charts/` — 8 dc.js dashboard components
- `src/components/wraps/` — d3act React wrappers
- `test/` — Jasmine + Enzyme specs with Karma runner
- `karma.conf.js` — webpack + babel + phantomjs/chrome configuration
- `server.js` — express dev server with react-hot-loader

The repo is MIT licensed and preserved as-is from 2014.

---

*This document is part of the Foundry genealogy series — tracing the lineage of ideas, methods, and code through the projects that shaped them.*
