/**
 * d3-dashboard.spec.js — Jasmine BDD specs for the The Foundry cross-filter dashboard
 * ====================================================================================
 *
 * Test-informed development: specs describe EXPECTED behavior.
 * Pure functions tested first; chart rendering tested via DOM assertions.
 *
 * Runs in jasmine-standalone (CDN) or Karma/Playwright.
 */

/* ─── Spec Suite ──────────────────────────────────────────────── */

describe('The Foundry Cross-Filter Dashboard', () => {

  // ─── Mock Data ────────────────────────────────────────────────

  let SIM_DATA;
  let allPoints;

  beforeEach(() => {
    // Minimal representative data for testing
    SIM_DATA = {
      two_tier: [
        { seed: 42, k1: 0.5146, k2: 0.8062, ratio: 2.2478, delta_bic: -476.27,
          r_squared_bi: 0.999999, r_squared_mono: 0.999635, preferred_model: 'biexponential',
          fast_fraction: 0.8062, slow_fraction: 0.1938 },
        { seed: 43, k1: 0.4760, k2: 0.8227, ratio: 2.4127, delta_bic: -457.23,
          r_squared_bi: 0.999999, r_squared_mono: 0.999532, preferred_model: 'biexponential',
          fast_fraction: 0.8227, slow_fraction: 0.1773 },
      ],
      uniform: [
        { seed: 42, k1: 0.5139, k2: 0.7073, ratio: 1.7566, delta_bic: -546.64,
          r_squared_bi: 0.999999, r_squared_mono: 0.999827, preferred_model: 'biexponential',
          fast_fraction: 0.7073, slow_fraction: 0.2927 },
        { seed: 43, k1: 0.5154, k2: 0.7035, ratio: 1.7547, delta_bic: -540.64,
          r_squared_bi: 0.999999, r_squared_mono: 0.999827, preferred_model: 'biexponential',
          fast_fraction: 0.7035, slow_fraction: 0.2965 },
      ],
    };

    allPoints = getAllDataPoints(SIM_DATA);
  });

  // ─── 1. Data Loading ──────────────────────────────────────────

  describe('Data loading', () => {

    it('should parse SIM_DATA with two_tier and uniform arrays', () => {
      expect(SIM_DATA.two_tier).toBeDefined();
      expect(SIM_DATA.uniform).toBeDefined();
      expect(SIM_DATA.two_tier.length).toBe(2);
      expect(SIM_DATA.uniform.length).toBe(2);
    });

    it('should flatten both groups into annotated data points', () => {
      expect(allPoints.length).toBe(4);
      const keys = allPoints.map(d => d.key);
      expect(keys).toContain('two_tier_42');
      expect(keys).toContain('two_tier_43');
      expect(keys).toContain('uniform_42');
      expect(keys).toContain('uniform_43');
    });

    it('should annotate each point with a unique key', () => {
      const keys = allPoints.map(d => d.key);
      const unique = new Set(keys);
      expect(unique.size).toBe(keys.length);
    });

    it('should preserve all numeric fields on flattened points', () => {
      const point = allPoints[0];
      expect(typeof point.k1).toBe('number');
      expect(typeof point.k2).toBe('number');
      expect(typeof point.delta_bic).toBe('number');
      expect(typeof point.r_squared_bi).toBe('number');
      expect(typeof point.r_squared_mono).toBe('number');
      expect(typeof point.fast_fraction).toBe('number');
      expect(typeof point.slow_fraction).toBe('number');
    });

  });

  // ─── 2. Filtering Logic ───────────────────────────────────────

  describe('filterBySeeds', () => {

    it('should return all data when selectedSet is empty', () => {
      const result = filterBySeeds(allPoints, new Set());
      expect(result.length).toBe(4);
    });

    it('should return all data when selectedSet is null', () => {
      const result = filterBySeeds(allPoints, null);
      expect(result.length).toBe(4);
    });

    it('should filter to only matching keys', () => {
      const selected = new Set(['two_tier_42']);
      const result = filterBySeeds(allPoints, selected);
      expect(result.length).toBe(1);
      expect(result[0].key).toBe('two_tier_42');
    });

    it('should return multiple matching seeds', () => {
      const selected = new Set(['two_tier_42', 'uniform_43']);
      const result = filterBySeeds(allPoints, selected);
      expect(result.length).toBe(2);
      const keys = result.map(d => d.key).sort();
      expect(keys).toEqual(['two_tier_42', 'uniform_43']);
    });

    it('should return empty array when no keys match', () => {
      const selected = new Set(['nonexistent']);
      const result = filterBySeeds(allPoints, selected);
      expect(result.length).toBe(0);
    });

  });

  // ─── 3. Opacity Computation ───────────────────────────────────

  describe('computeOpacity', () => {

    it('should return 1.0 when no selection is active', () => {
      expect(computeOpacity('two_tier_42', null)).toBe(1.0);
      expect(computeOpacity('two_tier_42', new Set())).toBe(1.0);
    });

    it('should return 1.0 for a selected key', () => {
      const selected = new Set(['two_tier_42']);
      expect(computeOpacity('two_tier_42', selected)).toBe(1.0);
    });

    it('should return 0.1 for a non-selected key', () => {
      const selected = new Set(['two_tier_42']);
      expect(computeOpacity('uniform_42', selected)).toBe(0.1);
    });

    it('should handle multiple selected keys', () => {
      const selected = new Set(['two_tier_42', 'uniform_42']);
      expect(computeOpacity('two_tier_42', selected)).toBe(1.0);
      expect(computeOpacity('uniform_42', selected)).toBe(1.0);
      expect(computeOpacity('two_tier_43', selected)).toBe(0.1);
    });

  });

  // ─── 4. Brush Selection ───────────────────────────────────────

  describe('getSelectedSeeds', () => {

    it('should return empty set when extent is null', () => {
      const result = getSelectedSeeds(null, allPoints);
      expect(result.size).toBe(0);
    });

    it('should return seeds within the brush extent', () => {
      // Extent that covers all data
      const extent = [[0.45, 0.68], [0.55, 0.85]];
      const result = getSelectedSeeds(extent, allPoints);
      expect(result.size).toBe(4);
    });

    it('should return empty set when extent encloses no data', () => {
      // Extent with no data
      const extent = [[0.4, 0.4], [0.45, 0.45]];
      const result = getSelectedSeeds(extent, allPoints);
      expect(result.size).toBe(0);
    });

    it('should handle extent in reverse order (x0 > x1)', () => {
      const extent = [[0.55, 0.68], [0.45, 0.85]];
      const result = getSelectedSeeds(extent, allPoints);
      expect(result.size).toBe(4);
    });

    it('should return correct keys for a partial selection', () => {
      // Only select two-tier seeds (k1 ~0.48-0.52, k2 ~0.8-0.83)
      const extent = [[0.46, 0.79], [0.53, 0.84]];
      const result = getSelectedSeeds(extent, allPoints);
      const keys = Array.from(result);
      expect(keys.length).toBeGreaterThan(0);
      keys.forEach(key => {
        expect(key.startsWith('two_tier')).toBeTrue();
      });
    });

  });

  // ─── 5. Trajectory Generation ─────────────────────────────────

  describe('getTimePoints', () => {

    it('should return 100 time points', () => {
      const t = getTimePoints();
      expect(t.length).toBe(100);
    });

    it('should start at 0 and end at 99', () => {
      const t = getTimePoints();
      expect(t[0]).toBe(0);
      expect(t[99]).toBe(99);
    });

    it('should contain sequential integers', () => {
      const t = getTimePoints();
      for (let i = 1; i < t.length; i++) {
        expect(t[i] - t[i - 1]).toBe(1);
      }
    });

  });

  describe('generateTrajectory', () => {

    it('should return the correct number of points', () => {
      const seed = { k1: 0.5, k2: 0.8, fast_fraction: 0.8, slow_fraction: 0.2 };
      const t = [0, 1, 2, 3, 4];
      const rho = generateTrajectory(seed, t);
      expect(rho.length).toBe(5);
    });

    it('should return 1.0 at t=0 (fast_fraction + slow_fraction = 1.0)', () => {
      const seed = { k1: 0.5, k2: 0.8, fast_fraction: 0.8, slow_fraction: 0.2 };
      const t = [0];
      const rho = generateTrajectory(seed, t);
      expect(rho[0]).toBeCloseTo(1.0, 10);
    });

    it('should produce strictly decreasing values for positive rates', () => {
      const seed = { k1: 0.5, k2: 0.8, fast_fraction: 0.8, slow_fraction: 0.2 };
      const t = [0, 1, 2, 5, 10];
      const rho = generateTrajectory(seed, t);
      for (let i = 1; i < rho.length; i++) {
        expect(rho[i]).toBeLessThan(rho[i - 1]);
      }
    });

    it('should produce different trajectories for different seeds', () => {
      const seedA = { k1: 0.5, k2: 0.8, fast_fraction: 0.8, slow_fraction: 0.2 };
      const seedB = { k1: 0.51, k2: 0.7, fast_fraction: 0.7, slow_fraction: 0.3 };
      const t = [1, 10, 50];
      const rhoA = generateTrajectory(seedA, t);
      const rhoB = generateTrajectory(seedB, t);
      // Different parameters must produce measurably different trajectories
      const diffSum = rhoA.reduce((sum, v, i) => sum + Math.abs(v - rhoB[i]), 0);
      expect(diffSum).toBeGreaterThan(0);
      // And the difference must be driven by the rate/fraction parameters
      expect(rhoA[0]).not.toBeCloseTo(rhoB[0], 3);
    });

  });

  describe('computeAllTrajectories', () => {

    it('should generate a trajectory for every seed', () => {
      const t = getTimePoints();
      const trajectories = computeAllTrajectories(SIM_DATA, t);
      expect(trajectories.length).toBe(4); // 2 two-tier + 2 uniform
    });

    it('should annotate each trajectory with type and key', () => {
      const t = getTimePoints();
      const trajectories = computeAllTrajectories(SIM_DATA, t);
      trajectories.forEach(tr => {
        expect(tr.key).toMatch(/^(two_tier|uniform)_\d+$/);
        expect(tr.t.length).toBe(100);
        expect(tr.rho.length).toBe(100);
      });
    });

    it('should start each trajectory at rho ≈ 1.0', () => {
      const t = getTimePoints();
      const trajectories = computeAllTrajectories(SIM_DATA, t);
      trajectories.forEach(tr => {
        expect(tr.rho[0]).toBeCloseTo(1.0, 5);
      });
    });

  });

  // ─── 6. Chart Rendering ───────────────────────────────────────

  describe('Chart rendering', () => {

    let container;

    beforeEach(() => {
      // Create a lightweight DOM container for SVG rendering tests
      container = document.createElement('div');
      container.id = 'test-chart';
      document.body.appendChild(container);
    });

    afterEach(() => {
      document.body.removeChild(container);
    });

    it('should render scatter plot with correct number of points', () => {
      renderScatter({
        container: '#test-chart',
        data: allPoints,
        width: 600,
        height: 400,
      });
      const circles = container.querySelectorAll('circle');
      expect(circles.length).toBe(4);
    });

    it('should render scatter points with correct color coding by type', () => {
      renderScatter({
        container: '#test-chart',
        data: allPoints,
        width: 600,
        height: 400,
      });
      const circles = container.querySelectorAll('circle');
      const twoTierCircles = Array.from(circles).filter(c =>
        c.getAttribute('fill') === '#2c3e50'
      );
      const uniformCircles = Array.from(circles).filter(c =>
        c.getAttribute('fill') === '#e74c3c'
      );
      expect(twoTierCircles.length).toBe(2);
      expect(uniformCircles.length).toBe(2);
    });

    it('should apply dim opacity to non-selected scatter points', () => {
      renderScatter({
        container: '#test-chart',
        data: allPoints,
        selectedSet: new Set(['two_tier_42']),
        width: 600,
        height: 400,
      });
      const circles = container.querySelectorAll('circle[data-key]');
      expect(circles.length).toBe(4);
      circles.forEach(c => {
        const key = c.getAttribute('data-key');
        const opacity = parseFloat(c.getAttribute('opacity'));
        if (key === 'two_tier_42') {
          expect(opacity).toBe(1.0);
        } else {
          expect(opacity).toBe(0.1);
        }
      });
    });

    it('should render bars with correct count', () => {
      renderBars({
        container: '#test-chart',
        data: allPoints,
        width: 600,
        height: 250,
      });
      const rects = container.querySelectorAll('rect');
      expect(rects.length).toBe(4);
    });

    it('should highlight bars matching selected seeds', () => {
      renderBars({
        container: '#test-chart',
        data: allPoints,
        selectedSet: new Set(['two_tier_42']),
        width: 600,
        height: 250,
        onClick: () => {},
      });
      const rects = container.querySelectorAll('rect');
      let selectedBars = 0;
      let dimmedBars = 0;
      rects.forEach(r => {
        const opacity = parseFloat(r.getAttribute('opacity'));
        if (opacity === 1.0) selectedBars++;
        if (opacity === 0.1) dimmedBars++;
      });
      expect(selectedBars).toBe(1);
      expect(dimmedBars).toBe(3);
    });

    it('should render trajectory lines for all seeds', () => {
      const t = getTimePoints();
      const trajectories = computeAllTrajectories(SIM_DATA, t);
      renderTrajectories({
        container: '#test-chart',
        trajectories,
        width: 600,
        height: 400,
      });
      const paths = container.querySelectorAll('path.trajectory');
      expect(paths.length).toBe(4);
    });

    it('should render R² comparison chart', () => {
      renderR2({
        container: '#test-chart',
        data: allPoints,
        width: 600,
        height: 250,
      });
      const rects = container.querySelectorAll('rect');
      // 4 seeds × 2 bars (bi-exp + mono-exp) = 8 bars
      expect(rects.length).toBe(8);
    });

  });

  // ─── 7. Cross-filter Integration ──────────────────────────────

  describe('Cross-filter integration', () => {

    it('should apply dim opacity across all charts when a selection is active', () => {
      const selected = new Set(['two_tier_42']);
      const allNonSelected = allPoints.filter(d => !selected.has(d.key));
      allNonSelected.forEach(d => {
        expect(computeOpacity(d.key, selected)).toBe(0.1);
      });
    });

    it('should return full opacity when selection is cleared', () => {
      allPoints.forEach(d => {
        expect(computeOpacity(d.key, new Set())).toBe(1.0);
        expect(computeOpacity(d.key, null)).toBe(1.0);
      });
    });

    it('should produce consistent key space across all functions', () => {
      const t = getTimePoints();
      const trajectories = computeAllTrajectories(SIM_DATA, t);
      const pointKeys = new Set(allPoints.map(d => d.key));
      const trajKeys = new Set(trajectories.map(d => d.key));
      expect(pointKeys).toEqual(trajKeys);
    });

  });

});