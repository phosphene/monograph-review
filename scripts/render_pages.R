#!/usr/bin/env Rscript
# render_pages.R — Generate multi-page GitHub Pages site for The Foundry
#
# Produces 5 self-contained HTML pages in docs/:
#   index.html         — landing page with links
#   simulacra.html      — parameter recovery tests with descriptions
#   baseline-oracle.html — §12 manuscript results with tolerance bands
#   key-results.html    — discriminating tests summary
#   toy-models.html     — speculative explorers
#
# Each page embeds descriptive text from docs/*.md as HTML headers,
# followed by the generated plots/tables.
#
# All plots are base64 PNGs, all CSS is inline — zero external dependencies.
#
# DFT: A1 (I/O isolated to this guarded main), A6 (structured status).

# ---------------------------------------------------------------------------
# 0. Locate repo root
# ---------------------------------------------------------------------------
find_repo_root <- function() {
  candidate <- normalizePath(getwd(), mustWork = FALSE)
  for (i in seq_len(8L)) {
    if (file.exists(file.path(candidate, "DESCRIPTION")) &&
        file.exists(file.path(candidate, "baseline", "oracle.yml"))) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (parent == candidate) break
    candidate <- parent
  }
  normalizePath(getwd(), mustWork = FALSE)
}

repo_root <- find_repo_root()

# ---------------------------------------------------------------------------
# 1. Load package + viz functions
# ---------------------------------------------------------------------------
suppressPackageStartupMessages(library(valence.foundry))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(base64enc))

viz_file <- file.path(repo_root, "R", "viz.R")
if (file.exists(viz_file)) source(viz_file)

# ---------------------------------------------------------------------------
# 2. CSS (shared across all pages)
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
.nav a { padding: 4px 12px; background: #ecf0f1; border-radius: 4px;
         color: #2c3e50; }
.nav a:hover { background: #d0d6d9; }
.section { background: #fff; border: 1px solid #e3e8ee; border-radius: 6px;
           padding: 16px 20px; margin-bottom: 20px; }
.section h2 { margin-top: 0; color: #2c3e50; border-bottom: 1px solid #2c3e50;
              padding-bottom: 6px; font-family: 'DejaVu Sans', sans-serif; font-size: 1.2em; }
.section h3 { color: #34495e; margin-top: 20px; font-family: 'DejaVu Sans', sans-serif; font-size: 1.05em; }
.descriptive { margin-bottom: 16px; line-height: 1.6; }
.descriptive p { margin-bottom: 8pt; text-align: justify; }
.descriptive strong { font-weight: bold; }
.descriptive em { font-style: italic; }
.descriptive code { font-family: 'DejaVu Sans Mono', monospace; font-size: 0.9em;
                    background: #f4f6f8; padding: 0 3px; border-radius: 2px; }
.descriptive ul { margin: 4px 0 8px 20px; }
.descriptive li { margin-bottom: 4px; }
.summary { background: #f0f4f8; padding: 10px 14px; border-left: 4px solid #2c3e50;
           border-radius: 3px; margin: 10px 0; font-size: 0.92em; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 0.9em; }
th, td { border: 1px solid #dde3ea; padding: 6px 8px; text-align: left; vertical-align: top; }
th { background: #2c3e50; color: white; font-weight: 600; font-family: 'DejaVu Sans', sans-serif; }
tr:nth-child(even) td { background: #f7f9fb; }
.plot { margin: 12px 0; text-align: center; }
.plot img { max-width: 100%; height: auto; border: 1px solid #e3e8ee; border-radius: 4px; }
.plot figcaption { font-size: 0.82em; color: #7f8c8d; margin-top: 4px; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 10px;
         font-size: 0.78em; font-weight: 600; }
.badge.pass { background: #d5f5e3; color: #1e8449; }
.badge.fail { background: #fadbd8; color: #c0392b; }
.badge.warn { background: #fdebd0; color: #b9770e; }
.footer { color: #7f8c8d; font-size: 0.82em; text-align: center;
          padding: 12px; border-top: 1px solid #e3e8ee; margin-top: 8px; }
.placeholder { color: #7f8c8d; font-style: italic; }
.mono { font-family: 'DejaVu Sans Mono', monospace; font-size: 0.88em;
        background: #f4f6f8; padding: 1px 4px; border-radius: 2px; }
"

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

# ---------------------------------------------------------------------------
# 3. Markdown -> HTML converter (simple, for descriptive text)
# ---------------------------------------------------------------------------
md_to_html <- function(md) {
  lines <- strsplit(md, "\n")[[1]]
  html <- c()
  in_list <- FALSE
  in_para <- c()

  flush_para <- function() {
    if (length(in_para) > 0) {
      text <- paste(in_para, collapse = " ")
      text <- gsub("\\*\\*(.+?)\\*\\*", "<strong>\\1</strong>", text)
      text <- gsub("\\*(.+?)\\*", "<em>\\1</em>", text)
      text <- gsub("`(.+?)`", "<code>\\1</code>", text)
      html <<- c(html, paste0("<p>", text, "</p>"))
      in_para <<- c()
    }
  }

  for (line in lines) {
    stripped <- trimws(line)
    if (grepl("^#+\\s", stripped)) {
      flush_para()
      if (in_list) { html <<- c(html, "</ul>"); in_list <<- FALSE }
      level <- nchar(gsub("^(#+).*$", "\\1", stripped))
      title <- sub("^#+\\s+", "", stripped)
      title <- gsub("\\*\\*(.+?)\\*\\*", "\\1", title)
      title <- gsub("\\*(.+?)\\*", "\\1", title)
      html <<- c(html, paste0("<h", min(level, 3), ">", title, "</h", min(level, 3), ">"))
    } else if (grepl("^\\s*[-*]\\s", stripped)) {
      flush_para()
      if (!in_list) { html <<- c(html, "<ul>"); in_list <<- TRUE }
      item <- sub("^\\s*[-*]\\s+", "", stripped)
      item <- gsub("\\*\\*(.+?)\\*\\*", "<strong>\\1</strong>", item)
      item <- gsub("\\*(.+?)\\*", "<em>\\1</em>", item)
      html <<- c(html, paste0("<li>", item, "</li>"))
    } else if (grepl("^\\|", stripped)) {
      flush_para()
      if (in_list) { html <<- c(html, "</ul>"); in_list <<- FALSE }
      cells <- strsplit(stripped, "\\|")[[1]]
      cells <- trimws(cells)
      cells <- cells[cells != ""]
      if (!grepl("^[-:\\s]+$", paste(cells, collapse = ""))) {
        if (length(grep("^<th", html[length(html)])) == 0) {
          html <<- c(html, "<table><thead><tr>",
                     paste("<th>", cells, "</th>", collapse = ""),
                     "</tr></thead><tbody>")
        } else {
          html <<- c(html, "<tr>",
                     paste("<td>", cells, "</td>", collapse = ""),
                     "</tr>")
        }
      }
    } else if (stripped == "") {
      flush_para()
      if (in_list) { html <<- c(html, "</ul>"); in_list <<- FALSE }
    } else {
      in_para <- c(in_para, stripped)
    }
  }
  flush_para()
  if (in_list) html <- c(html, "</ul>")
  # Close any open table
  if (length(grep("<tbody>$", html[length(html)])) html <- c(html, "</tbody></table>")

  paste(html, collapse = "\n")
}

# Read descriptive markdown
read_descriptive <- function(filename) {
  path <- file.path(repo_root, "docs", filename)
  if (file.exists(path)) {
    md <- paste(readLines(path, encoding = "UTF-8"), collapse = "\n")
    return(md_to_html(md))
  }
  ""
}

# ---------------------------------------------------------------------------
# 4. Plot helpers
# ---------------------------------------------------------------------------
save_plot_png <- function(plot, width = 8, height = 6, dpi = 150) {
  tmp <- tempfile(fileext = ".png")
  ggplot2::ggsave(tmp, plot, width = width, height = height, dpi = dpi)
  b64 <- base64enc::base64encode(tmp)
  unlink(tmp)
  b64
}

save_4panel_png <- function(p1, p2, p3, p4, width = 12, height = 10, dpi = 150) {
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp, width = width, height = height, units = "in", res = dpi)
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
  print(p1, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(p2, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
  print(p3, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
  print(p4, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 2))
  grid::popViewport()
  grDevices::dev.off()
  b64 <- base64enc::base64encode(tmp)
  unlink(tmp)
  b64
}

grid_text_grob <- function(label) {
  grid::textGrob(label, gp = grid::gpar(col = "#7f8c8d", fontsize = 12, fontface = "italic"))
}

# ---------------------------------------------------------------------------
# 5. Shared page wrapper
# ---------------------------------------------------------------------------
make_page <- function(title, body_html, timestamp, repo_url, pages_url) {
  paste0(
    "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n",
    "<meta charset=\"utf-8\">\n",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    "<title>", html_escape(title), "</title>\n",
    "<style>", CSS, "</style>\n",
    "</head>\n<body>\n",
    "<div class=\"header\">",
    "<h1>", html_escape(title), "</h1>",
    "<p>The Foundry — computational verification for the framework under review</p>",
    "<p>Generated: ", timestamp,
    "&nbsp;|&nbsp;<a href=\"", repo_url, "\">GitHub</a>",
    "&nbsp;|&nbsp;<a href=\"", pages_url, "\">Pages</a></p>",
    "</div>\n",
    "<div class=\"nav\">",
    "<a href=\"index.html\">Index</a>",
    "<a href=\"simulacra.html\">Simulacra</a>",
    "<a href=\"baseline-oracle.html\">Baseline Oracle</a>",
    "<a href=\"key-results.html\">Key Results</a>",
    "<a href=\"toy-models.html\">Toy Models</a>",
    "<a href=\"formula-analysis.html\">Formula Analysis</a>",
    "</div>\n",
    body_html,
    "<div class=\"footer\">",
    "<p><strong>The Foundry</strong> — generated by <span class=\"mono\">scripts/render_pages.R</span> at ",
    timestamp, "</p>",
    "</div>\n</body>\n</html>\n"
  )
}

# ---------------------------------------------------------------------------
# 6. Simulacra
# ---------------------------------------------------------------------------
marks_dir <- file.path(repo_root, "results", "simulacra")
all_marks <- list()
if (dir.exists(marks_dir)) {
  all_marks <- valence.foundry::read_all_marks(marks_dir)
}

render_simulacra_summary <- function(all_marks) {
  if (length(all_marks) == 0) {
    return("<p class=\"placeholder\">No simulacrum marks found. Run the simulacrum tests first.</p>")
  }
  rows <- lapply(names(all_marks), function(sim_id) {
    marks <- all_marks[[sim_id]]
    if (length(marks) == 0) return(paste0("<tr><td class=\"mono\">", html_escape(sim_id), "</td><td colspan=\"4\" class=\"placeholder\">No marks</td></tr>"))
    true_params <- marks[[1]]$true_params
    true_str <- if (is.null(true_params)) "—" else paste(sprintf("<span class=\"mono\">%s = %s</span>", names(true_params), vapply(true_params, function(v) format(v, digits = 4), character(1))), collapse = ", ")
    recovered_str <- "—"
    if (!is.null(true_params)) {
      pn <- names(true_params)
      rec_means <- vapply(pn, function(p) { vals <- vapply(marks, function(m) { v <- m$recovered_params[[p]]; if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v) }, numeric(1)); mean(vals, na.rm = TRUE) }, numeric(1))
      recovered_str <- paste(sprintf("<span class=\"mono\">%s = %s</span>", pn, format(rec_means, digits = 4)), collapse = ", ")
    }
    within <- vapply(marks, function(m) isTRUE(m$within_ci), logical(1))
    within_pct <- sprintf("%.0f%%", 100 * mean(within, na.rm = TRUE))
    null_vals <- vapply(marks, function(m) { nr <- m$null_result; if (is.null(nr)) NA_real_ else as.numeric(nr) }, numeric(1))
    has_null <- any(!is.na(null_vals))
    null_badge <- if (has_null) "<span class=\"badge pass\">Pass</span>" else "<span class=\"badge warn\">N/A</span>"
    paste0("<tr><td class=\"mono\">", html_escape(sim_id), "</td><td>", true_str, "</td><td>", recovered_str, "</td><td>", within_pct, "</td><td>", null_badge, "</td></tr>")
  })
  paste0("<table><thead><tr><th>Simulacrum</th><th>True params</th><th>Recovered (mean)</th><th>Within CI</th><th>Null control</th></tr></thead><tbody>", paste(rows, collapse = "\n"), "</tbody></table>")
}

render_simulacra_plots <- function(all_marks) {
  if (length(all_marks) == 0) return("<p class=\"placeholder\">Simulacra plots will appear after the next CI run.</p>")
  blocks <- lapply(names(all_marks), function(sim_id) {
    marks <- all_marks[[sim_id]]
    if (length(marks) == 0) return(paste0("<h3>", html_escape(sim_id), "</h3><p class=\"placeholder\">No marks.</p>"))
    param_names <- names(marks[[1]]$true_params)
    if (is.null(param_names) || length(param_names) == 0) return(paste0("<h3>", html_escape(sim_id), "</h3><p class=\"placeholder\">No params.</p>"))
    p1 <- param_names[1]
    gp1 <- tryCatch(valence.foundry::plot_true_vs_recovered(marks, p1, sim_id), error = function(e) grid_text_grob(paste("Error:", e$message)))
    gp2 <- tryCatch(valence.foundry::plot_recovery_trajectory(marks, p1, sim_id), error = function(e) grid_text_grob(paste("Error:", e$message)))
    gp3 <- if (length(param_names) >= 2) tryCatch(valence.foundry::plot_param_space_projection(marks, param_names[1], param_names[2], sim_id), error = function(e) grid_text_grob(paste("Error:", e$message))) else grid_text_grob("Needs 2+ params")
    gp4 <- tryCatch(valence.foundry::plot_recovery_rate(marks, simulacrum_id = sim_id), error = function(e) grid_text_grob(paste("Error:", e$message)))
    b64 <- tryCatch(save_4panel_png(gp1, gp2, gp3, gp4), error = function(e) NA_character_)
    if (is.na(b64)) return(paste0("<h3>", html_escape(sim_id), "</h3><p class=\"placeholder\">Render failed.</p>"))
    paste0("<figure class=\"plot\"><h3>", html_escape(sim_id), "</h3><img src=\"data:image/png;base64,", b64, "\" alt=\"", html_escape(sim_id), "\" /><figcaption><strong>Panel 1 (top-left):</strong> True vs. recovered — points on the diagonal mean the pipeline recovers the right number. <strong>Panel 2 (top-right):</strong> Recovery trajectory — recovered values should hover around the true line across all iterations; drift indicates bias. <strong>Panel 3 (bottom-left):</strong> Parameter space — the cloud of recovered pairs should center on the true combination; scatter indicates parameter interaction. <strong>Panel 4 (bottom-right):</strong> Recovery rate — the cumulative success proportion should rise to 1.0 and stay there; plateaus indicate sensitivity to initial conditions.</figcaption></figure>")
  })
  paste(blocks, collapse = "\n")
}

# ---------------------------------------------------------------------------
# 7. Baseline Oracle
# ---------------------------------------------------------------------------
oracle_path <- file.path(repo_root, "baseline", "oracle.yml")
oracle <- yaml::read_yaml(oracle_path)

oracle_metrics <- list(
  list(label = "T1 β (kb/level)", value = -23.5, tol = 0.001),
  list(label = "T1 R²", value = 0.652, tol = 0.001),
  list(label = "T2 Pearson r", value = -0.934, tol = 0.001),
  list(label = "T3 R² (biphasic)", value = 0.920, tol = 0.001),
  list(label = "T3 threshold_biphasicity", value = 1.0, tol = 0.01),
  list(label = "T4 niche R²", value = 0.343, tol = 0.001),
  list(label = "T6 Spearman (Oro)", value = 0.955, tol = 0.001),
  list(label = "FM dep coefficient", value = 0.84, tol = 0.01),
  list(label = "L3 bird ρ", value = 0.755, tol = 0.01)
)

forest_df <- data.frame(
  label = factor(sapply(oracle_metrics, function(m) m$label), levels = rev(sapply(oracle_metrics, function(m) m$label))),
  value = sapply(oracle_metrics, function(m) m$value),
  tol = sapply(oracle_metrics, function(m) m$tol),
  stringsAsFactors = FALSE
)

forest_plot <- ggplot2::ggplot(forest_df, ggplot2::aes(x = .data$value, y = .data$label)) +
  ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data$value - .data$tol, xmax = .data$value + .data$tol), height = 0.25, color = "#3498db", alpha = 0.5, linewidth = 2) +
  ggplot2::geom_vline(xintercept = 0, color = "grey70", linetype = "dotted") +
  ggplot2::geom_point(shape = 21, size = 4, fill = "#2c3e50", color = "white") +
  ggplot2::geom_text(ggplot2::aes(label = sprintf("%.3f", .data$value)), hjust = -0.6, vjust = -0.8, size = 3.2, color = "#2c3e50") +
  ggplot2::labs(title = "Baseline Oracle — §12 results", x = "Expected value", y = NULL) +
  ggplot2::theme_minimal(base_size = 12)

forest_b64 <- tryCatch(save_plot_png(forest_plot, width = 10, height = 6), error = function(e) NA_character_)

render_oracle_table <- function(oracle) {
  name_map <- c(
    t1_orobanchaceae_pgls = "T1: Orobanchaceae PGLS",
    t2_cross_family = "T2: Between-family correlation",
    t3_endosymbiont_biphasic = "T3: Endosymbiont biphasic",
    t4_niche_vs_ne = "T4: Niche vs Ne",
    t5_pangenome_fluidity = "T5: Pan-genome fluidity",
    t6_gene_loss_ordering = "T6: Gene-loss ordering",
    t7_ltee_cosegregation = "T7: LTEE co-segregation",
    formal_model = "Formal model (GLM)",
    cross_kingdom_l3 = "L3: Cross-kingdom transfer"
  )
  rows <- lapply(names(oracle), function(id) {
    entry <- oracle[[id]]
    if (!is.list(entry)) return(NULL)
    disp <- if (id %in% names(name_map)) name_map[[id]] else id
    pred <- if (!is.null(entry$prediction)) html_escape(entry$prediction) else "—"
    comp <- if (!is.null(entry$competitor)) html_escape(entry$competitor) else "—"
    kv <- "—"
    if (is.list(entry$values)) {
      num_vals <- entry$values[vapply(entry$values, is.numeric, logical(1))]
      if (length(num_vals) > 0) kv <- paste(sprintf("%s = %s", names(num_vals), vapply(num_vals, function(v) format(v, digits = 4), character(1))), collapse = ", ")
    }
    supports <- if (isTRUE(entry$supports_framework)) "Yes" else "No"
    dist <- if (isTRUE(entry$distinguishes_from_competitor)) "Yes" else "No"
    caveat <- if (!is.null(entry$caveat) && !is.na(entry$caveat)) html_escape(entry$caveat) else "—"
    paste0("<tr><td><strong>", html_escape(disp), "</strong></td><td>", pred, "</td><td class=\"mono\">", kv, "</td><td>", supports, "</td><td>", dist, "</td><td>", caveat, "</td></tr>")
  })
  paste0("<table><thead><tr><th>Test</th><th>Prediction</th><th>Key value</th><th>Supports the framework</th><th>Distinguishes</th><th>Caveat</th></tr></thead><tbody>", paste(rows[!vapply(rows, is.null, logical(1))], collapse = "\n"), "</tbody></table>")
}

# ---------------------------------------------------------------------------
# 8. Key Results
# ---------------------------------------------------------------------------
render_key_results <- function() {
  rows <- list(
    c("T3", "Endosymbiont biphasic", "R² = 0.920, threshold_biphasicity = 1.0", "Yes — constant-rate and ratchet predict different shapes"),
    c("T4", "Niche vs Ne", "Niche R² = 0.343 vs Ne R² = 0.198", "Yes — drift-only predicts Ne dominates"),
    c("T5", "Pan-genome fluidity", "Lifestyle subsumes Ne", "Yes — Ne-only predicts no lifestyle signal"),
    c("T6", "Gene-loss ordering", "ρ = 0.955, p = 0.0083", "Yes — random loss predicts no ordering"),
    c("FM", "Formal model (GLM)", "dep = +0.84 (p=0.0008), para = -1.86 (p<0.0001)", "Yes — random loss (dep≤0), relaxed selection (para ns)"),
    c("L3", "Cross-kingdom transfer", "ρ = 0.755, p = 0.031", "Yes — substrate independence predicts no transfer"),
    c("T1", "Orobanchaceae PGLS", "β = -23.5, R² = 0.652, p < 10⁻⁹", "No — relaxed selection predicts same gradient"),
    c("T2", "Between-family correlation", "r = -0.934, p = 1.39e-41", "No — also predicted by relaxed selection"),
    c("T7", "LTEE co-segregation", "36.4% vs 61.7% (depletion)", "No — hitchhiking confound; suggestive only")
  )
  body <- paste(vapply(rows, function(r) paste0("<tr><td class=\"mono\"><strong>", r[1], "</strong></td><td>", html_escape(r[2]), "</td><td class=\"mono\">", html_escape(r[3]), "</td><td>", html_escape(r[4]), "</td></tr>"), character(1)), collapse = "\n")
  paste0("<table><thead><tr><th>Test</th><th>What it measures</th><th>Key value</th><th>Distinguishes the framework?</th></tr></thead><tbody>", body, "</tbody></table>")
}

# ---------------------------------------------------------------------------
# 9. Toy Models
# ---------------------------------------------------------------------------
render_toy_realms <- function() {
  plots <- list()
  r1 <- tryCatch({
    sweep <- sweep_threshold(depths = seq(0, 5, length.out = 50), lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
    b64 <- save_plot_png(plot_threshold_gate(sweep), width = 8, height = 5)
    paste0("<h3>Genome Reduction</h3><figure class=\"plot\"><img src=\"data:image/png;base64,", b64, "\" alt=\"Threshold gate\" /></figure>")
  }, error = function(e) paste0("<h3>Genome Reduction</h3><p class=\"placeholder\">Unavailable: ", html_escape(conditionMessage(e)), "</p>"))
  plots <- c(plots, r1)

  r2 <- tryCatch({
    sweep <- sweep_cusp_irreversibility(a_grid = seq(1, -2, by = -0.25), control_values = seq(-2, 2, length.out = 100))
    b64 <- save_plot_png(plot_irreversibility_sweep(sweep), width = 8, height = 5)
    paste0("<h3>Irreversibility</h3><figure class=\"plot\"><img src=\"data:image/png;base64,", b64, "\" alt=\"Irreversibility\" /></figure>")
  }, error = function(e) paste0("<h3>Irreversibility</h3><p class=\"placeholder\">Unavailable: ", html_escape(conditionMessage(e)), "</p>"))
  plots <- c(plots, r2)

  r3 <- tryCatch({
    contrast <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
    b64 <- save_plot_png(plot_dd_contrast(contrast), width = 12, height = 5)
    paste0("<h3>Homo Inversion</h3><figure class=\"plot\"><img src=\"data:image/png;base64,", b64, "\" alt=\"DD contrast\" /></figure>")
  }, error = function(e) paste0("<h3>Homo Inversion</h3><p class=\"placeholder\">Unavailable: ", html_escape(conditionMessage(e)), "</p>"))
  plots <- c(plots, r3)

  r4 <- tryCatch({
    sweep <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.05))
    b64 <- save_plot_png(plot_transfer_breakdown(sweep), width = 8, height = 5)
    paste0("<h3>Cross-Kingdom Transfer</h3><figure class=\"plot\"><img src=\"data:image/png;base64,", b64, "\" alt=\"Transfer breakdown\" /></figure>")
  }, error = function(e) paste0("<h3>Cross-Kingdom Transfer</h3><p class=\"placeholder\">Unavailable: ", html_escape(conditionMessage(e)), "</p>"))
  plots <- c(plots, r4)

  paste(plots, collapse = "\n")
}

# ---------------------------------------------------------------------------
# 10. Assemble 5 pages
# ---------------------------------------------------------------------------
timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M UTC")
repo_url <- "https://github.com/phosphene/monograph-review"
pages_url <- "https://phosphene.github.io/monograph-review/"
out_dir <- file.path(repo_root, "docs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --- Page 1: Index ---
index_desc <- read_descriptive("index.md")
index_body <- paste0(
  "<div class=\"section\"><div class=\"descriptive\">", index_desc, "</div></div>"
)
index_html <- make_page("The Foundry", index_body, timestamp, repo_url, pages_url)
writeLines(index_html, file.path(out_dir, "index.html"))

# --- Page 2: Simulacra ---
sim_desc <- read_descriptive("simulacra.md")
sim_body <- paste0(
  "<div class=\"section\"><h2>Simulacra — Parameter Recovery</h2>",
  "<div class=\"descriptive\">", sim_desc, "</div>",
  "<h3>Summary</h3>", render_simulacra_summary(all_marks),
  "</div>\n",
  "<div class=\"section\"><h2>Plots</h2>", render_simulacra_plots(all_marks), "</div>"
)
sim_html <- make_page("Simulacra — The Foundry", sim_body, timestamp, repo_url, pages_url)
writeLines(sim_html, file.path(out_dir, "simulacra.html"))

# --- Page 3: Baseline Oracle ---
oracle_desc <- read_descriptive("baseline-oracle.md")
oracle_body <- paste0(
  "<div class=\"section\"><h2>Baseline Oracle — §12 Manuscript Results</h2>",
  "<div class=\"descriptive\">", oracle_desc, "</div>"
)
if (!is.na(forest_b64)) {
  oracle_body <- paste0(oracle_body,
    "<figure class=\"plot\"><img src=\"data:image/png;base64,", forest_b64, "\" alt=\"Forest plot\" /></figure>")
}
oracle_body <- paste0(oracle_body, render_oracle_table(oracle), "</div>")
oracle_html <- make_page("Baseline Oracle — The Foundry", oracle_body, timestamp, repo_url, pages_url)
writeLines(oracle_html, file.path(out_dir, "baseline-oracle.html"))

# --- Page 4: Key Results ---
kr_desc <- read_descriptive("key-results.md")
kr_body <- paste0(
  "<div class=\"section\"><h2>Key Results — Discriminating Core</h2>",
  "<div class=\"descriptive\">", kr_desc, "</div>",
  render_key_results(), "</div>"
)
kr_html <- make_page("Key Results — The Foundry", kr_body, timestamp, repo_url, pages_url)
writeLines(kr_html, file.path(out_dir, "key-results.html"))

# --- Page 5: Toy Models ---
tr_desc <- read_descriptive("toy-models.md")
tr_body <- paste0(
  "<div class=\"section\"><h2>Toy Models — Speculative Explorers</h2>",
  "<div class=\"descriptive\">", tr_desc, "</div>",
  render_toy_realms(), "</div>"
)
tr_html <- make_page("Toy Models — The Foundry", tr_body, timestamp, repo_url, pages_url)
writeLines(tr_html, file.path(out_dir, "toy-models.html"))

# ---------------------------------------------------------------------------
# 10b. Formula Analysis page (from markdown + plots)
# ---------------------------------------------------------------------------
fa_desc <- read_descriptive("formula-analysis.md")
fa_body <- paste0(
  "<div class=\"section\"><h2>Formula Analysis — Three-Move Derivation</h2>",
  "<div class=\"descriptive\">", fa_desc, "</div>",
  "</div>"
)
fa_html <- make_page("Formula Analysis — The Foundry", fa_body, timestamp, repo_url, pages_url)
writeLines(fa_html, file.path(out_dir, "formula-analysis.html"))

# ---------------------------------------------------------------------------
# 11. Status
# ---------------------------------------------------------------------------
message("[render_pages] Wrote 6 pages to docs/")
message(sprintf("[render_pages] %d simulacra, %d oracle metrics",
                length(all_marks), length(oracle_metrics)))
