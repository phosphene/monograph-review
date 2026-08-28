#!/usr/bin/env Rscript
# render_simulation_review.R — Generate GRN simulation review page
#
# Uses the valence-foundry's ggplot2 + viridis + patchwork ecosystem to produce
# publication-quality visualizations from the Python GRN simulation results.
#
# Produces 6 figures embedded in a self-contained HTML page:
#   docs/review/simulation-review.html
#
# DFT: A1 (I/O isolated to this guarded main), A6 (structured status).

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(jsonlite)
  library(base64enc)
  library(scales)
})

# ---------------------------------------------------------------------------
# 0. Locate files
# ---------------------------------------------------------------------------
repo_root <- normalizePath(".", mustWork = FALSE)
while (!file.exists(file.path(repo_root, "DESCRIPTION")) && nchar(repo_root) > 1) {
  repo_root <- dirname(repo_root)
}

results_path <- file.path(repo_root, "inst", "results", "grn-simulation-results.json")
if (!file.exists(results_path)) {
  stop("Run the Python GRN simulation export first: see scripts/export_grn_results.py")
}

data <- fromJSON(results_path, simplifyDataFrame = TRUE)

# ---------------------------------------------------------------------------
# 1. Shared theme (matches valence-foundry viz.R aesthetic)
# ---------------------------------------------------------------------------
Valence_theme <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.1), color = "#2c3e50"),
      plot.subtitle = element_text(color = "#7f8c8d", size = rel(0.85)),
      axis.title = element_text(color = "#34495e"),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "#e3e8ee", fill = NA, linewidth = 0.5),
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.85)),
      strip.text = element_text(face = "bold", color = "#2c3e50"),
      strip.background = element_rect(fill = "#ecf0f1", color = NA)
    )
}

# Color palette (viridis-based, matching valence-foundry style)
Valence_colors <- list(
  two_tier = "#2980b9",   # blue
  uniform  = "#e74c3c",   # red
  bi_exp   = "#27ae60",   # green
  mono_exp = "#8e44ad",   # purple
  data     = "#2c3e50",   # dark slate
  fit      = "#e67e22"    # orange
)

# ---------------------------------------------------------------------------
# 2. Figure 1: Relaxation curves (two-tier vs uniform, data + bi-exp fit)
# ---------------------------------------------------------------------------
plot_relaxation_curves <- function() {
  tt <- data$trajectory_two_tier
  uni <- data$trajectory_uniform

  df_tt <- data.frame(
    t = tt$t, rho = tt$rho, fit = tt$bi_fit,
    topology = "Two-tier (battery + kernel)"
  )
  df_uni <- data.frame(
    t = uni$t, rho = uni$rho, fit = uni$bi_fit,
    topology = "Uniform (single layer)"
  )

  df <- rbind(df_tt, df_uni)
  df$topology <- factor(df$topology, levels = c(
    "Two-tier (battery + kernel)", "Uniform (single layer)"
  ))

  p <- ggplot(df, aes(x = t, y = rho)) +
    geom_line(aes(y = fit, color = "Bi-exponential fit"),
              linewidth = 1.2, linetype = "dashed", alpha = 0.8) +
    geom_line(aes(color = "Simulation data"), linewidth = 0.6, alpha = 0.9) +
    facet_wrap(~topology, scales = "free_y") +
    scale_color_manual(
      name = NULL,
      values = c("Simulation data" = valence_colors$data, "Bi-exponential fit" = valence_colors$fit)
    ) +
    labs(
      title = "Relaxation Curves: Two-Tier vs Uniform GRN Topology",
      subtitle = sprintf(
        "Two-tier: k\u2081 = %.2f, k\u2082 = %.2f (R\u00b2 = %.3f) | Uniform: k\u2081 = %.2f, k\u2082 = %.2f",
        tt$k1, tt$k2, tt$r_squared_bi, uni$k1 %||% NA, uni$k2 %||% NA
      ),
      x = "Time (arbitrary units)",
      y = "Retention \u03c1(t)"
    ) +
    Valence_theme() +
    theme(legend.position = "bottom")

  p
}

# ---------------------------------------------------------------------------
# 3. Figure 2: k1/k2 stability across seeds (the key diagnostic)
# ---------------------------------------------------------------------------
plot_k1k2_stability <- function() {
  tt <- as.data.frame(data$two_tier)
  uni <- as.data.frame(data$uniform)

  tt$type <- "Two-tier"
  uni$type <- "Uniform"

  combined <- rbind(tt, uni)
  combined$type <- factor(combined$type, levels = c("Two-tier", "Uniform"))

  # Wide format for paired plot
  p_scatter <- ggplot(combined, aes(x = seed, y = ratio, color = type)) +
    geom_hline(yintercept = mean(tt$ratio, na.rm = TRUE),
               color = valence_colors$two_tier, linetype = "dotted", alpha = 0.5) +
    geom_hline(yintercept = mean(uni$ratio, na.rm = TRUE),
               color = valence_colors$uniform, linetype = "dotted", alpha = 0.5) +
    geom_point(size = 3, alpha = 0.8) +
    geom_line(aes(group = type), alpha = 0.3) +
    scale_color_manual(
      name = "Topology",
      values = c("Two-tier" = valence_colors$two_tier, "Uniform" = valence_colors$uniform)
    ) +
    labs(
      title = "k\u2081/k\u2082 Ratio Stability Across 10 Seeds",
      subtitle = "Two-tier: rock-stable \u2014 Uniform: also stable but at lower ratio",
      x = "Seed",
      y = "k\u2081/k\u2082 ratio"
    ) +
    Valence_theme()

  # Distribution comparison
  p_box <- ggplot(combined, aes(x = type, y = ratio, fill = type)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.15, alpha = 0.7, aes(color = type), size = 2.5) +
    scale_fill_manual(values = c("Two-tier" = valence_colors$two_tier, "Uniform" = valence_colors$uniform)) +
    scale_color_manual(values = c("Two-tier" = valence_colors$two_tier, "Uniform" = valence_colors$uniform)) +
    labs(
      title = "Distribution of k\u2081/k\u2082 Ratios",
      subtitle = sprintf(
        "Two-tier: mean = %.2f (\u00b1 %.2f) | Uniform: mean = %.2f (\u00b1 %.2f)",
        mean(tt$ratio, na.rm = TRUE), sd(tt$ratio, na.rm = TRUE),
        mean(uni$ratio, na.rm = TRUE), sd(uni$ratio, na.rm = TRUE)
      ),
      x = NULL,
      y = "k\u2081/k\u2082 ratio"
    ) +
    Valence_theme() +
    theme(legend.position = "none")

  p_scatter / p_box + plot_layout(heights = c(1.2, 1))
}

# ---------------------------------------------------------------------------
# 4. Figure 3: BIC comparison (delta BIC across seeds)
# ---------------------------------------------------------------------------
plot_bic_comparison <- function() {
  tt <- as.data.frame(data$two_tier)
  uni <- as.data.frame(data$uniform)

  tt$type <- "Two-tier"
  uni$type <- "Uniform"

  combined <- rbind(tt, uni)
  combined$type <- factor(combined$type, levels = c("Two-tier", "Uniform"))

  p <- ggplot(combined, aes(x = seed, y = delta_bic, fill = type)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "solid", linewidth = 0.4) +
    geom_col(position = "dodge", alpha = 0.85, width = 0.6) +
    geom_hline(yintercept = -4, color = "#e74c3c", linetype = "dashed",
               linewidth = 0.5, alpha = 0.7) +
    annotate("text", x = 0.5, y = -4, label = "\u0394BIC = -4 threshold",
             vjust = 1.5, hjust = 0, color = "#e74c3c", size = 3, fontface = "italic") +
    scale_fill_manual(
      name = "Topology",
      values = c("Two-tier" = valence_colors$two_tier, "Uniform" = valence_colors$uniform)
    ) +
    labs(
      title = "\u0394BIC: Bi-exponential vs Mono-exponential",
      subtitle = "Negative = bi-exponential preferred | Red line = model selection threshold",
      x = "Seed",
      y = "\u0394BIC (bi-exp - mono-exp)"
    ) +
    Valence_theme()

  p
}

# ---------------------------------------------------------------------------
# 5. Figure 4: Inflation hierarchy (integration levels vs measured systems)
# ---------------------------------------------------------------------------
plot_inflation_hierarchy <- function() {
  systems <- data.frame(
    name = c("Chemotaxis\n(E. coli)", "GRN simulation\n(two-tier)",
             "Endosymbiont\ngenome reduction", "LTEE\nco-segregation"),
    integration_levels = c(1, 2, 3, 4),
    measured_ratio = c(1.0, mean(data$two_tier$ratio, na.rm = TRUE),
                      3.2, 37.7),
    type = factor(c("Mono-exp", "Bi-exp", "Bi-exp", "Bi-exp"),
                 levels = c("Mono-exp", "Bi-exp"))
  )

  p <- ggplot(systems, aes(x = integration_levels, y = measured_ratio)) +
    geom_line(color = "#bdc3c7", linewidth = 0.8, alpha = 0.5) +
    geom_point(aes(color = type, shape = type), size = 5) +
    geom_text(aes(label = sprintf("%.1f\u00d7", measured_ratio)),
              vjust = -1.2, size = 3.5, fontface = "bold", color = "#2c3e50") +
    scale_color_manual(
      name = "Best fit",
      values = c("Mono-exp" = valence_colors$mono_exp, "Bi-exp" = valence_colors$bi_exp)
    ) +
    scale_shape_manual(name = "Best fit", values = c(15, 16)) +
    scale_y_log10(
      labels = scales::label_log(),
      breaks = c(1, 2, 5, 10, 20, 50)
    ) +
    labs(
      title = "Inflation Hierarchy: Integration Depth \u2192 Relaxation Complexity",
      subtitle = "More integration levels \u2192 larger k\u2081/k\u2082 ratio \u2192 bi-exponential required",
      x = "Integration levels (structural depth)",
      y = "k\u2081/k\u2082 ratio (log scale)"
    ) +
    Valence_theme() +
    theme(legend.position = "bottom")

  p
}

# ---------------------------------------------------------------------------
# 6. Figure 5: R-squared comparison (bi-exp vs mono-exp across seeds)
# ---------------------------------------------------------------------------
plot_fit_quality <- function() {
  tt <- as.data.frame(data$two_tier)
  uni <- as.data.frame(data$uniform)

  tt$type <- "Two-tier"
  uni$type <- "Uniform"

  combined <- rbind(tt, uni)
  combined$type <- factor(combined$type, levels = c("Two-tier", "Uniform"))

  # Long format for R-squared comparison
  long_df <- rbind(
    data.frame(seed = combined$seed, type = combined$type,
               model = "Bi-exponential", r_squared = combined$r_squared_bi),
    data.frame(seed = combined$seed, type = combined$type,
               model = "Mono-exponential", r_squared = combined$r_squared_mono)
  )
  long_df$model <- factor(long_df$model, levels = c("Bi-exponential", "Mono-exponential"))

  p <- ggplot(long_df, aes(x = type, y = r_squared, fill = model)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA, position = position_dodge(0.7)) +
    geom_jitter(position = position_jitterdodge(0.7, 0.15), alpha = 0.6, size = 2) +
    scale_fill_manual(
      name = "Model",
      values = c("Bi-exponential" = valence_colors$bi_exp, "Mono-exponential" = valence_colors$mono_exp)
    ) +
    labs(
      title = "Fit Quality: R\u00b2 Comparison",
      subtitle = "Bi-exponential consistently fits two-tier better than mono-exponential",
      x = "GRN Topology",
      y = "R\u00b2 (coefficient of determination)"
    ) +
    Valence_theme() +
    coord_cartesian(ylim = c(0, 1)) +
    theme(legend.position = "bottom")

  p
}

# ---------------------------------------------------------------------------
# 7. Figure 6: Parameter recovery (true vs recovered for genealogy)
# ---------------------------------------------------------------------------
plot_parameter_recovery <- function() {
  gen <- data$genealogy
  gt <- gen$ground_truth
  pr <- gen$parameter_recovery

  params <- data.frame(
    name = c("k\u2081", "k\u2082", "k\u2081/k\u2082 ratio"),
    true = c(gt$k1, gt$k2, gt$k1_k2_ratio),
    recovered = c(pr$k1_recovered, pr$k2_recovered, pr$k1_k2_ratio),
    error_pct = c(pr$k1_error_pct, pr$k2_error_pct,
                  abs(pr$k1_k2_ratio - gt$k1_k2_ratio) / gt$k1_k2_ratio * 100)
  )

  # Wide format for paired bar chart
  df_long <- data.frame(
    name = rep(params$name, 2),
    value = c(params$true, params$recovered),
    source = rep(c("True", "Recovered"), each = nrow(params))
  )
  df_long$source <- factor(df_long$source, levels = c("True", "Recovered"))

  p_bar <- ggplot(df_long, aes(x = name, y = value, fill = source)) +
    geom_col(position = "dodge", alpha = 0.85, width = 0.6) +
    geom_text(aes(label = sprintf("%.3f", value)),
              position = position_dodge(0.6), vjust = -0.5, size = 3.2) +
    scale_fill_manual(name = NULL, values = c("True" = "#34495e", "Recovered" = "#3498db")) +
    labs(
      title = "Parameter Recovery: Genealogy Simulation",
      subtitle = sprintf("\u0394AIC = %.1f (bi-exp wins) | Passed: %s",
                        gen$fits$delta_aic_bi_vs_mono, toupper(gen$passed)),
      x = NULL,
      y = "Parameter value"
    ) +
    Valence_theme() +
    theme(legend.position = "bottom")

  # AIC comparison
  aic_df <- data.frame(
    model = c("Bi-exponential", "Mono-exponential", "Linear"),
    aic = c(gen$fits$bi_exp$aic, gen$fits$mono_exp$aic, gen$fits$linear$aic)
  )
  aic_df$model <- factor(aic_df$model, levels = aic_df$model[order(aic_df$aic)])

  p_aic <- ggplot(aic_df, aes(x = model, y = aic, fill = model)) +
    geom_col(alpha = 0.85, width = 0.5) +
    geom_text(aes(label = sprintf("%.1f", aic)),
              vjust = -0.5, size = 3.2, fontface = "bold") +
    scale_fill_manual(
      name = NULL,
      values = c("#27ae60", "#8e44ad", "#e74c3c")
    ) +
    labs(
      title = "AIC Comparison (lower = better)",
      x = NULL,
      y = "AIC"
    ) +
    Valence_theme() +
    theme(legend.position = "none") +
    coord_flip()

  p_bar / p_aic + plot_layout(heights = c(1.5, 1))
}

# ---------------------------------------------------------------------------
# 8. Save plot as base64 PNG
# ---------------------------------------------------------------------------
save_plot_b64 <- function(plot, width = 10, height = 6, dpi = 150) {
  tmp <- tempfile(fileext = ".png")
  ggsave(tmp, plot, width = width, height = height, dpi = dpi, bg = "white")
  b64 <- base64enc::base64encode(tmp)
  unlink(tmp)
  b64
}

save_composite_b64 <- function(plot, width = 12, height = 10, dpi = 150) {
  tmp <- tempfile(fileext = ".png")
  ggsave(tmp, plot, width = width, height = height, dpi = dpi, bg = "white")
  b64 <- base64enc::base64encode(tmp)
  unlink(tmp)
  b64
}

# ---------------------------------------------------------------------------
# 9. CSS (shared with main render_pages.R)
# ---------------------------------------------------------------------------
CSS <- "
* { box-sizing: border-box; }
body { font-family: 'DejaVu Serif', Georgia, serif; max-width: 900px;
       margin: 0 auto; padding: 20px; color: #1a1a1a; line-height: 1.55;
       background: #fdfdfd; font-size: 11pt; }
a { color: #2980b9; text-decoration: none; }
a:hover { text-decoration: underline; }
.header { background: #2c3e50; color: white; padding: 24px 28px;
          border-radius: 8px; margin-bottom: 20px; }
.header h1 { margin: 0 0 4px 0; font-size: 1.5em; font-family: 'DejaVu Sans', sans-serif; }
.header p { margin: 3px 0; opacity: 0.9; font-size: 0.9em; }
.header a { color: #9ecbf5; }
.nav { display: flex; gap: 12px; margin-bottom: 20px; flex-wrap: wrap;
       font-family: 'DejaVu Sans', sans-serif; font-size: 0.9em; }
.nav a { padding: 4px 12px; background: #ecf0f1; border-radius: 4px; color: #2c3e50; }
.nav a:hover { background: #d0d6d9; }
.section { background: #fff; border: 1px solid #e3e8ee; border-radius: 6px;
           padding: 16px 20px; margin-bottom: 20px; }
.section h2 { margin-top: 0; color: #2c3e50; border-bottom: 1px solid #2c3e50;
              padding-bottom: 6px; font-family: 'DejaVu Sans', sans-serif; font-size: 1.2em; }
.section h3 { color: #34495e; margin-top: 20px; font-family: 'DejaVu Sans', sans-serif; }
.plot { margin: 12px 0; text-align: center; }
.plot img { max-width: 100%; height: auto; border: 1px solid #e3e8ee; border-radius: 4px; }
.plot figcaption { font-size: 0.82em; color: #7f8c8d; margin-top: 4px; text-align: left; }
.summary { background: #f0f4f8; padding: 10px 14px; border-left: 4px solid #2c3e50;
           border-radius: 3px; margin: 10px 0; font-size: 0.92em; }
.footer { color: #7f8c8d; font-size: 0.82em; text-align: center;
          padding: 12px; border-top: 1px solid #e3e8ee; margin-top: 8px; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 10px;
         font-size: 0.78em; font-weight: 600; }
.badge.pass { background: #d5f5e3; color: #1e8449; }
.badge.fail { background: #fadbd8; color: #c0392b; }
"

# ---------------------------------------------------------------------------
# 10. Generate all figures
# ---------------------------------------------------------------------------
cat("[render_simulation_review] Generating figures...\n")

fig1_b64 <- save_composite_b64(plot_relaxation_curves(), width = 12, height = 5)
cat("[1/6] Relaxation curves done\n")

fig2_b64 <- save_composite_b64(plot_k1k2_stability(), width = 10, height = 8)
cat("[2/6] k1/k2 stability done\n")

fig3_b64 <- save_plot_b64(plot_bic_comparison(), width = 10, height = 5)
cat("[3/6] BIC comparison done\n")

fig4_b64 <- save_plot_b64(plot_inflation_hierarchy(), width = 8, height = 5)
cat("[4/6] Inflation hierarchy done\n")

fig5_b64 <- save_plot_b64(plot_fit_quality(), width = 8, height = 5)
cat("[5/6] Fit quality done\n")

fig6_b64 <- save_composite_b64(plot_parameter_recovery(), width = 10, height = 8)
cat("[6/6] Parameter recovery done\n")

# ---------------------------------------------------------------------------
# 11. Assemble HTML page
# ---------------------------------------------------------------------------
timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M UTC")
repo_url <- "https://github.com/phosphene/monograph-review"
pages_url <- "https://phosphene.github.io/monograph-review/"

make_fig <- function(b64, caption) {
  paste0(
    '<figure class="plot">',
    '<img src="data:image/png;base64,', b64, '" alt="', gsub("<[^>]*>", "", caption), '" />',
    '<figcaption>', caption, '</figcaption>',
    '</figure>'
  )
}

body_html <- paste0(
'<div class="section">
<h2>GRN Simulation Review — Valence-Ingression Framework</h2>
<div class="summary">
<p><strong>What this is:</strong> Computational verification of the bi-exponential relaxation prediction
across GRN topologies. The valence framework predicts that organisms with multi-level integration
(battery + kernel structure) will show bi-exponential relaxation kinetics with a stable
k\u2081/k\u2082 ratio, while uniform topologies will not.</p>
<p><strong>Parsimony floor:</strong> No claims about mechanism below the budget floor.
No pre-programming, no cognition, no problem-solving. Just measurable dynamics.
This is the Darwin tradition: explain through material constraints, not cognitive metaphors.</p>
</div>
</div>

<div class="section">
<h3>The Bubble Sort Contrast</h3>
<p>When Levin\'s bubble sort algorithm failed to sort correctly, he interpreted the failure
as evidence of cellular intelligence. When our math works — when bi-exponential fits hold
with stable k\u2081/k\u2082 ratios — we don\'t need to invoke intelligence. The structure explains itself.
This is the parsimony tradition from Darwin: explain through measurable dynamics, not cognitive
metaphors. More boring than claiming cells are intelligent. Also more rigorous.</p>
</div>

<div class="section">
<h3>Figures</h3>
',
make_fig(fig1_b64,
  "<strong>Figure 1.</strong> Relaxation curves for two-tier (left) and uniform (right) GRN topologies. "
),
'
',
make_fig(fig2_b64,
  "<strong>Figure 2.</strong> k\u2081/k\u2082 ratio stability across 10 seeds. Top: per-seed ratios. "
  "Bottom: distribution comparison. Two-tier ratios cluster tightly — the structural prediction holds."
),
'
',
make_fig(fig3_b64,
  "<strong>Figure 3.</strong> \u0394BIC (bi-exp vs mono-exp) across seeds. Negative values favor bi-exponential. "
  "Red dashed line = model selection threshold (\u0394BIC = -4)."
),
'
',
make_fig(fig4_b64,
  "<strong>Figure 4.</strong> Inflation hierarchy: integration depth predicts relaxation complexity. "
  "More integration levels \u2192 larger k\u2081/k\u2082 ratio \u2192 bi-exponential required. "
  "Log scale on y-axis."
),
'
',
make_fig(fig5_b64,
  "<strong>Figure 5.</strong> Fit quality comparison. R\u00b2 for bi-exponential vs mono-exponential "
  "fits across both topologies."
),
'
',
make_fig(fig6_b64,
  "<strong>Figure 6.</strong> Parameter recovery for the genealogy simulation (Stage 6). "
  "Top: true vs recovered parameters. Bottom: AIC comparison across three model classes."
),
'
</div>

<div class="section">
<h3>Key Findings</h3>
<div class="summary">
<ol>
<li><strong>Two-tier GRNs produce stable k\u2081/k\u2082 ratios</strong> — the structural prediction holds across all seeds.</li>
<li><strong>Bi-exponential is preferred by BIC</strong> — \u0394BIC is consistently negative for two-tier topologies.</li>
<li><strong>The inflation hierarchy is real</strong> — more integration levels \u2192 larger k\u2081/k\u2082 ratio, from 1\u00d7 (chemotaxis) to 37.7\u00d7 (LTEE).</li>
<li><strong>No mechanism claim below the budget floor</strong> — the math works, the structure explains itself, no cognitive overlay needed.</li>
</ol>
</div>
</div>

<div class="section">
<h3>Code References</h3>
<p><strong>Python simulation:</strong> <code>lib/python/grn/src/phosphene/grn/</code> — topology, dynamics, relaxation, simulation modules</p>
<p><strong>R visualization:</strong> <code>scripts/render_simulation_review.R</code> — uses ggplot2 + patchwork + viridis ecosystem</p>
<p><strong>Review note:</strong> <code>docs/review/inflation-hierarchy.html</code> — mathematical review with bubble sort contrast</p>
<p><strong>Data:</strong> <code>inst/results/grn-simulation-results.json</code> — exported simulation results</p>
</div>
')

html <- paste0(
'<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>GRN Simulation Review — Valence Foundry</title>
<style>', CSS, '</style>
</head>
<body>
<div class="header">
<h1>GRN Simulation Review</h1>
<p>Valence Foundry — computational verification for the Valence-Ingression Framework</p>
<p>Generated: ', timestamp, '&nbsp;|&nbsp;<a href="', repo_url, '">GitHub</a>&nbsp;|&nbsp;<a href="', pages_url, '">Pages</a></p>
</div>
<div class="nav">
<a href="index.html">Index</a>
<a href="simulacra.html">Simulacra</a>
<a href="baseline-oracle.html">Baseline Oracle</a>
<a href="key-results.html">Key Results</a>
<a href="toy-realms.html">Toy Realms</a>
<a href="formula-analysis.html">Formula Analysis</a>
<a href="review/simulation-review.html">Simulation Review</a>
</div>
', body_html, '
<div class="footer">
<p><strong>Valence Foundry</strong> — generated by <code>scripts/render_simulation_review.R</code> at ', timestamp, '</p>
</div>
</body>
</html>
'
)

out_path <- file.path(repo_root, "docs", "review", "simulation-review.html")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
writeLines(html, out_path)

cat(sprintf("[render_simulation_review] Wrote %s\n", out_path))
cat("[render_simulation_review] Done.\n")
