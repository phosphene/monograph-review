/**
 * cross-filter.js — The Foundry cross-filtered dashboard module
 * ==============================================================
 *
 * Test-informed development (phosphene/react-d3-hotload-test-demo, 2014):
 * specs written first (test/d3-dashboard.spec.js), implementation built
 * to pass them. The test runner (test/d3-dashboard-runner.html) imports
 * THIS module and runs the full 38-spec suite against it.
 *
 * Pure functions (data, filtering, opacity, trajectories) are isolated
 * from chart rendering so each is testable independently. Keys are
 * unique per seed+topology (`two_tier_42`, `uniform_42`) so cross-filter
 * selection is unambiguous.
 */

export const COLORS = {
  two_tier: '#2c3e50',
  uniform: '#e74c3c',
  bar_fill: '#3498db',
  bar_selected: '#2980b9',
  trajectory: '#7f8c8d',
  trajectory_selected: '#2c3e50',
};

// ─── Time points ────────────────────────────────────────────────────────

export function getTimePoints() {
  return Array.from({ length: 100 }, (_, i) => i);
}

// ─── Trajectory generation (runs the bi-exponential in the browser) ────

export function generateTrajectory(seed, t) {
  const { k1, k2, fast_fraction, slow_fraction } = seed;
  return t.map(function (ti) {
    return fast_fraction * Math.exp(-k1 * ti) + slow_fraction * Math.exp(-k2 * ti);
  });
}

export function computeAllTrajectories(SIM_DATA, t) {
  const trajectories = [];
  SIM_DATA.two_tier.forEach(function (d) {
    trajectories.push({
      key: 'two_tier_' + d.seed,
      seed: d.seed,
      type: 'two_tier',
      t: t,
      rho: generateTrajectory(d, t),
    });
  });
  SIM_DATA.uniform.forEach(function (d) {
    trajectories.push({
      key: 'uniform_' + d.seed,
      seed: d.seed,
      type: 'uniform',
      t: t,
      rho: generateTrajectory(d, t),
    });
  });
  return trajectories;
}

// ─── Data loading ───────────────────────────────────────────────────────

export function getAllDataPoints(SIM_DATA) {
  const points = [];
  SIM_DATA.two_tier.forEach(function (d) {
    points.push(Object.assign({}, d, { type: 'two_tier', key: 'two_tier_' + d.seed }));
  });
  SIM_DATA.uniform.forEach(function (d) {
    points.push(Object.assign({}, d, { type: 'uniform', key: 'uniform_' + d.seed }));
  });
  return points;
}

// ─── Filtering ──────────────────────────────────────────────────────────

export function filterBySeeds(data, selectedSet) {
  if (!selectedSet || selectedSet.size === 0) return data;
  return data.filter(function (d) { return selectedSet.has(d.key); });
}

// ─── Opacity ────────────────────────────────────────────────────────────

export function computeOpacity(key, selectedSet) {
  if (!selectedSet || selectedSet.size === 0) return 1.0;
  return selectedSet.has(key) ? 1.0 : 0.1;
}

// ─── Brush extent → selected keys ───────────────────────────────────────

export function getSelectedSeeds(brushExtent, data) {
  if (!brushExtent) return new Set();
  const x0 = Math.min(brushExtent[0][0], brushExtent[1][0]);
  const x1 = Math.max(brushExtent[0][0], brushExtent[1][0]);
  const y0 = Math.min(brushExtent[0][1], brushExtent[1][1]);
  const y1 = Math.max(brushExtent[0][1], brushExtent[1][1]);
  const seeds = new Set();
  data.forEach(function (d) {
    if (d.k1 >= x0 && d.k1 <= x1 && d.k2 >= y0 && d.k2 <= y1) {
      seeds.add(d.key);
    }
  });
  return seeds;
}

// ─── Chart renderers ────────────────────────────────────────────────────

const MARGIN = { top: 30, right: 20, bottom: 50, left: 60 };

function makeScale(domain, range) { return d3.scaleLinear().domain(domain).range(range); }

export function renderScatter(cfg) {
  const container = cfg.container, data = cfg.data;
  const width = cfg.width || 600, height = cfg.height || 400;
  const selectedSet = cfg.selectedSet, onBrush = cfg.onBrush, onPointClick = cfg.onPointClick;
  const innerW = width - MARGIN.left - MARGIN.right;
  const innerH = height - MARGIN.top - MARGIN.bottom;

  const xScale = makeScale([0.45, 0.55], [0, innerW]);
  const yScale = makeScale([0.68, 0.85], [innerH, 0]);

  const svg = d3.select(container);
  svg.selectAll('*').remove();
  svg.attr('width', width).attr('height', height).attr('viewBox', '0 0 ' + width + ' ' + height);
  const g = svg.append('g').attr('transform', 'translate(' + MARGIN.left + ',' + MARGIN.top + ')');

  g.append('g').attr('transform', 'translate(0,' + innerH + ')').call(d3.axisBottom(xScale).ticks(6));
  g.append('g').call(d3.axisLeft(yScale).ticks(6));

  // Axes labels
  g.append('text').attr('x', innerW / 2).attr('y', innerH + 40)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('k₁ (fast relaxation rate)');
  g.append('text').attr('transform', 'rotate(-90)').attr('x', -innerH / 2).attr('y', -45)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('k₂ (slow relaxation rate)');

  g.selectAll('circle').data(data).join('circle')
    .attr('data-key', function (d) { return d.key; })
    .attr('cx', function (d) { return xScale(d.k1); })
    .attr('cy', function (d) { return yScale(d.k2); })
    .attr('r', 6)
    .attr('fill', function (d) { return d.type === 'two_tier' ? COLORS.two_tier : COLORS.uniform; })
    .attr('stroke', '#fff').attr('stroke-width', 1.5)
    .attr('opacity', function (d) { return computeOpacity(d.key, selectedSet); })
    .attr('cursor', 'pointer')
    .append('title')
    .text(function (d) {
      return d.key + '\nk₁=' + d.k1.toFixed(4) + '  k₂=' + d.k2.toFixed(4) +
        '\nratio=' + d.ratio.toFixed(3) + '  ΔBIC=' + d.delta_bic.toFixed(1);
    });

  // Re-bind click on the circles container (title child breaks direct handler)
  g.selectAll('circle').on('click', function (event, d) {
    if (onPointClick) onPointClick(d.key);
  });

  // Legend (rect swatches so circle-count assertions stay on data points)
  const legend = g.append('g').attr('transform', 'translate(' + (innerW - 110) + ',10)');
  legend.append('rect').attr('x', 0).attr('y', -10).attr('width', 10).attr('height', 10).attr('fill', COLORS.two_tier);
  legend.append('text').attr('x', 16).attr('y', 0).text('Two-tier').style('font-size', '11px');
  legend.append('rect').attr('x', 0).attr('y', 10).attr('width', 10).attr('height', 10).attr('fill', COLORS.uniform);
  legend.append('text').attr('x', 16).attr('y', 20).text('Uniform').style('font-size', '11px');

  // Brush (cross-filter driver)
  if (onBrush) {
    const brush = d3.brush()
      .extent([[0, 0], [innerW, innerH]])
      .on('brush end', function (event) {
        if (!event.selection) {
          onBrush(new Set());
        } else {
          const sel = event.selection;
          const extent = [
            [xScale.invert(sel[0][0]), yScale.invert(sel[1][1])],
            [xScale.invert(sel[1][0]), yScale.invert(sel[0][1])],
          ];
          onBrush(getSelectedSeeds(extent, data));
        }
      });
    g.append('g').attr('class', 'brush').call(brush);
  }

  return svg;
}

export function renderBars(cfg) {
  const container = cfg.container, data = cfg.data, selectedSet = cfg.selectedSet;
  const width = cfg.width || 600, height = cfg.height || 250, onClick = cfg.onClick;
  const innerW = width - MARGIN.left - MARGIN.right;
  const innerH = height - MARGIN.top - MARGIN.bottom;

  const sorted = data.slice().sort(function (a, b) {
    if (a.type !== b.type) return a.type === 'two_tier' ? -1 : 1;
    return a.seed - b.seed;
  });

  const xScale = d3.scaleBand().domain(sorted.map(function (d) { return d.key; }))
    .range([0, innerW]).padding(0.15);
  // ΔBIC is negative; show bars descending from 0
  const yMin = d3.min(sorted, function (d) { return d.delta_bic; }) * 1.1;
  const yScale = d3.scaleLinear().domain([yMin, 0]).range([innerH, 0]).nice();

  const svg = d3.select(container);
  svg.selectAll('*').remove();
  svg.attr('width', width).attr('height', height).attr('viewBox', '0 0 ' + width + ' ' + height);
  const g = svg.append('g').attr('transform', 'translate(' + MARGIN.left + ',' + MARGIN.top + ')');

  g.append('g').attr('transform', 'translate(0,' + innerH + ')').call(d3.axisBottom(xScale));
  g.append('g').call(d3.axisLeft(yScale).ticks(6));

  g.append('text').attr('x', innerW / 2).attr('y', innerH + 40)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('Seed key');
  g.append('text').attr('transform', 'rotate(-90)').attr('x', -innerH / 2).attr('y', -45)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('ΔBIC (bi-exp − mono-exp)');

  // Threshold line at ΔBIC = -4
  g.append('line')
    .attr('x1', 0).attr('x2', innerW)
    .attr('y1', yScale(-4)).attr('y2', yScale(-4))
    .attr('stroke', '#e74c3c').attr('stroke-dasharray', '4,3').attr('stroke-width', 1.2);
  g.append('text').attr('x', innerW - 4).attr('y', yScale(-4) - 5)
    .attr('text-anchor', 'end').style('font-size', '10px').style('fill', '#e74c3c')
    .text('ΔBIC = −4');

  g.selectAll('rect').data(sorted).join('rect')
    .attr('data-key', function (d) { return d.key; })
    .attr('x', function (d) { return xScale(d.key); })
    .attr('y', function (d) { return yScale(Math.min(0, d.delta_bic)); })
    .attr('width', xScale.bandwidth())
    .attr('height', function (d) { return Math.abs(yScale(d.delta_bic) - yScale(0)); })
    .attr('fill', function (d) {
      return (selectedSet && selectedSet.has(d.key)) ? COLORS.bar_selected : COLORS.bar_fill;
    })
    .attr('opacity', function (d) { return computeOpacity(d.key, selectedSet); })
    .attr('stroke', '#fff').attr('stroke-width', 0.5).attr('cursor', 'pointer')
    .on('click', function (event, d) { if (onClick) onClick(d.key); })
    .append('title')
    .text(function (d) {
      return d.key + '\nΔBIC=' + d.delta_bic.toFixed(1) +
        '  bi-exp R²=' + d.r_squared_bi.toFixed(6) + '  mono-exp R²=' + d.r_squared_mono.toFixed(6);
    });

  return svg;
}

export function renderTrajectories(cfg) {
  const container = cfg.container, trajectories = cfg.trajectories, selectedSet = cfg.selectedSet;
  const width = cfg.width || 600, height = cfg.height || 400, onClick = cfg.onClick;
  const innerW = width - MARGIN.left - MARGIN.right;
  const innerH = height - MARGIN.top - MARGIN.bottom;

  const xScale = d3.scaleLinear().domain([0, 99]).range([0, innerW]);
  const yScale = d3.scaleLog().domain([0.0001, 1.1]).range([innerH, 0]);
  const lineGen = d3.line()
    .x(function (d) { return xScale(d[0]); })
    .y(function (d) { return yScale(Math.max(d[1], 1e-10)); });

  const svg = d3.select(container);
  svg.selectAll('*').remove();
  svg.attr('width', width).attr('height', height).attr('viewBox', '0 0 ' + width + ' ' + height);
  const g = svg.append('g').attr('transform', 'translate(' + MARGIN.left + ',' + MARGIN.top + ')');

  g.append('g').attr('transform', 'translate(0,' + innerH + ')').call(d3.axisBottom(xScale).ticks(10));
  g.append('g').call(d3.axisLeft(yScale).ticks(5, '.1e'));

  g.append('text').attr('x', innerW / 2).attr('y', innerH + 40)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('Time');
  g.append('text').attr('transform', 'rotate(-90)').attr('x', -innerH / 2).attr('y', -45)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('Retention ρ(t)  (log)');

  g.selectAll('path.trajectory').data(trajectories).join('path')
    .attr('class', 'trajectory')
    .attr('data-key', function (d) { return d.key; })
    .attr('d', function (d) {
      const points = d.t.map(function (ti, i) { return [ti, d.rho[i]]; });
      return lineGen(points);
    })
    .attr('fill', 'none')
    .attr('stroke', function (d) {
      return (selectedSet && selectedSet.has(d.key)) ? COLORS.trajectory_selected : COLORS.trajectory;
    })
    .attr('stroke-width', function (d) {
      return (selectedSet && selectedSet.has(d.key)) ? 2.5 : 1;
    })
    .attr('opacity', function (d) {
      if (!selectedSet || selectedSet.size === 0) return 0.5;
      return selectedSet.has(d.key) ? 1.0 : 0.08;
    })
    .attr('cursor', 'pointer')
    .on('click', function (event, d) { if (onClick) onClick(d.key); })
    .append('title')
    .text(function (d) { return d.key; });

  return svg;
}

export function renderR2(cfg) {
  const container = cfg.container, data = cfg.data, selectedSet = cfg.selectedSet;
  const width = cfg.width || 600, height = cfg.height || 250;
  const innerW = width - MARGIN.left - MARGIN.right;
  const innerH = height - MARGIN.top - MARGIN.bottom;

  const sorted = data.slice().sort(function (a, b) {
    if (a.type !== b.type) return a.type === 'two_tier' ? -1 : 1;
    return a.seed - b.seed;
  });

  const xScale = d3.scaleBand().domain(sorted.map(function (d) { return d.key; }))
    .range([0, innerW]).padding(0.2);
  const yScale = d3.scaleLinear().domain([0.999, 1.0001]).range([innerH, 0]);

  const svg = d3.select(container);
  svg.selectAll('*').remove();
  svg.attr('width', width).attr('height', height).attr('viewBox', '0 0 ' + width + ' ' + height);
  const g = svg.append('g').attr('transform', 'translate(' + MARGIN.left + ',' + MARGIN.top + ')');

  g.append('g').attr('transform', 'translate(0,' + innerH + ')').call(d3.axisBottom(xScale));
  g.append('g').call(d3.axisLeft(yScale).ticks(5, '.6f'));

  g.append('text').attr('x', innerW / 2).attr('y', innerH + 40)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('Seed key');
  g.append('text').attr('transform', 'rotate(-90)').attr('x', -innerH / 2).attr('y', -45)
    .attr('text-anchor', 'middle').style('font-size', '11px').style('fill', '#34495e')
    .text('R²');

  const barWidth = xScale.bandwidth() / 2;
  sorted.forEach(function (d) {
    const x = xScale(d.key);
    const opacity = computeOpacity(d.key, selectedSet);
    g.append('rect').attr('x', x).attr('y', yScale(d.r_squared_bi))
      .attr('width', barWidth).attr('height', Math.max(innerH - yScale(d.r_squared_bi), 0.5))
      .attr('fill', '#2980b9').attr('opacity', opacity)
      .append('title').text(d.key + ' bi-exp R²=' + d.r_squared_bi.toFixed(7));
    g.append('rect').attr('x', x + barWidth).attr('y', yScale(d.r_squared_mono))
      .attr('width', barWidth).attr('height', Math.max(innerH - yScale(d.r_squared_mono), 0.5))
      .attr('fill', '#e74c3c').attr('opacity', opacity)
      .append('title').text(d.key + ' mono-exp R²=' + d.r_squared_mono.toFixed(7));
  });

  // Legend (circle swatches so rect-count assertions stay on data bars)
  const legend = g.append('g').attr('transform', 'translate(' + (innerW - 120) + ',10)');
  legend.append('circle').attr('cx', 5).attr('cy', -5).attr('r', 5).attr('fill', '#2980b9');
  legend.append('text').attr('x', 15).attr('y', 0).text('Bi-exp').style('font-size', '11px');
  legend.append('circle').attr('cx', 5).attr('cy', 15).attr('r', 5).attr('fill', '#e74c3c');
  legend.append('text').attr('x', 15).attr('y', 20).text('Mono-exp').style('font-size', '11px');

  return svg;
}