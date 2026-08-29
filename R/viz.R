#' The Foundry visualizations — production-grade ggplot2 plots
#'
#' Produces publication-quality ggplot2 visualizations for each empirical
#' test (T1–T7), the formal dynamical model, cusp catastrophe, autocatalytic
#' set, cross-kingdom parameter transfer (L3), and the baseline oracle.
#'
#' Every function is a pure function (DFT A1): data in, ggplot2 object out.
#' No side effects, no file I/O, no global state modification. Every function
#' returns a structured, inspectable, printable ggplot2 object (DFT A6).
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): data in, ggplot2 object out — no side effects
#' - A6 (check-result): returns structured ggplot2 object (inspectable, printable)
#'
#' @name viz
NULL

#' T1: Plot PGLS regression with phylogenetic tree overlay
#'
#' Scatter plot of plastome size vs parasitism score with PGLS regression
#' line and confidence ribbon. A phylogenetic tree is rendered on the left
#' margin using ape::plot.phylo.
#'
#' @param data Data frame. Must contain species, plastome_size_kb, and
#'   parasitism_score columns.
#' @param tree An ape::phylo object. Pruned to match data species before
#'   calling.
#' @param result List. Result from pgls_orobanchaceae() — must contain
#'   values (beta, r_squared, p_value, n_species) and metadata.
#'
#' @return A ggplot2 object (patchwork assembly: tree + scatter).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction D5: plastome size correlates with parasitism level —
#' organisms committing to deeper parasitic niches lose plastome capacity
#' in proportion to commitment depth. The PGLS lambda parameter corrects
#' for phylogenetic non-independence. Competitor: relaxed selection
#' (Lahti et al. 2009) predicts the same gradient through a different
#' mechanism.
#'
#' What supports the framework: significant negative beta (parasitism -> smaller plastome).
#' What refutes the framework: no correlation, or positive correlation.
#' This test does NOT distinguish the framework from relaxed selection.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' loaded <- load_orobanchaceae()
#' tree <- ape::read.tree(text = loaded$tree)
#' result <- pgls_orobanchaceae(loaded$data, loaded$tree, seed = 42)
#' plot_pgls_with_phylogeny(loaded$data, tree, result)
#' }
plot_pgls_with_phylogeny <- function(data, tree, result) {
  # Validate inputs
  stopifnot(is.data.frame(data))
  stopifnot(inherits(tree, "phylo"))
  stopifnot(is.list(result), "values" %in% names(result))

  beta <- unname(result$values[["beta"]])
  r2 <- unname(result$values[["r_squared"]])
  pval <- unname(result$values[["p_value"]])
  n_sp <- unname(result$values[["n_species"]])

  # --- Panel A: Phylogenetic tree (left margin) ---
  # Use grid::viewport via a custom ggplot annotation
  tree_plot <- ggplot2::ggplot() +
    ggplot2::annotation_custom(
      grid::grid.grabExpr({
        old_par <- graphics::par(mar = c(4, 0.5, 4, 0.5), no.readonly = TRUE)
        on.exit(graphics::par(old_par))
        ape::plot.phylo(tree,
          show.tip.label = TRUE, cex = 0.6,
          direction = "rightwards", x.lim = NULL
        )
        ape::add.scale.bar(length = 0.1)
      })
    ) +
    ggplot2::labs(title = "A: Phylogeny") +
    ggplot2::theme_void()

  # --- Panel B: PGLS scatter ---
  # Compute regression line from model result
  pred_df <- data.frame(
    parasitism_score = seq(min(data$parasitism_score, na.rm = TRUE),
      max(data$parasitism_score, na.rm = TRUE),
      length.out = 100
    )
  )
  mean_x <- mean(data$parasitism_score, na.rm = TRUE)
  mean_y <- mean(data$plastome_size_kb, na.rm = TRUE)
  pred_df$plastome_pred <- mean_y + beta * (pred_df$parasitism_score - mean_x)

  # Standard error of prediction (approximate from PGLS)
  # Use simple residual standard error as proxy
  resid_se <- stats::sd(data$plastome_size_kb - pred_df$plastome_pred[seq_len(nrow(data))], na.rm = TRUE)
  se_x <- stats::sd(data$parasitism_score, na.rm = TRUE)
  ss_x <- sum((data$parasitism_score - mean_x)^2, na.rm = TRUE)
  se_factor <- sqrt(1 / n_sp + (pred_df$parasitism_score - mean_x)^2 / ss_x)
  pred_df$se <- resid_se * se_factor
  pred_df$lower <- pred_df$plastome_pred - 1.96 * pred_df$se
  pred_df$upper <- pred_df$plastome_pred + 1.96 * pred_df$se

  scatter <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data$parasitism_score, y = .data$plastome_size_kb
  )) +
    ggplot2::geom_ribbon(
      data = pred_df,
      ggplot2::aes(
        y = .data$plastome_pred,
        ymin = .data$lower, ymax = .data$upper
      ),
      fill = "#3498db", alpha = 0.2
    ) +
    ggplot2::geom_line(
      data = pred_df,
      ggplot2::aes(y = .data$plastome_pred),
      color = "#2c3e50", linewidth = 1
    ) +
    ggplot2::geom_point(size = 3, alpha = 0.7, color = "#2980b9") +
    ggplot2::labs(
      title = "B: PGLS: Plastome Size ~ Parasitism",
      subtitle = sprintf(
        "beta = %.2f, R\u00b2 = %.3f, p = %.2e, n = %d",
        beta, r2, pval, n_sp
      ),
      x = "Parasitism score",
      y = "Plastome size (kb)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.subtitle = ggplot2::element_text(size = 9, face = "italic"))

  # Assemble with patchwork
  tree_plot + scatter + patchwork::plot_layout(widths = c(1, 3))
}


#' T2: Faceted within-family regression
#'
#' Faceted scatter plot, one panel per parasitic plant family, each with
#' a within-family regression line showing the plastome size ~ parasitism
#' gradient.
#'
#' @param data Data frame. Must contain family, plastome_size_kb, and
#'   parasitism_score columns.
#'
#' @return A ggplot2 object (faceted scatter).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction D5: the gene-loss gradient replicates across independent
#' parasitic plant families. Competitor: stochastic gene loss / relaxed
#' selection — both predict the same pattern. This test does NOT distinguish
#' the framework from competitors.
#'
#' What supports the framework: consistent negative slope across families.
#' What refutes the framework: slopes vary in sign or are zero.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' loaded <- load_cross_family_plastomes()
#' plot_faceted_family_regression(loaded$data)
#' }
plot_faceted_family_regression <- function(data) {
  stopifnot(is.data.frame(data))
  stopifnot(all(c("family", "plastome_size_kb", "parasitism_score") %in% names(data)))

  p <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data$parasitism_score, y = .data$plastome_size_kb
  )) +
    ggplot2::geom_point(size = 2, alpha = 0.6, color = "#2980b9") +
    ggplot2::geom_smooth(
      method = "lm", se = TRUE, color = "#e74c3c",
      fill = "#e74c3c", alpha = 0.15, linewidth = 0.8
    ) +
    ggplot2::facet_wrap(~family, scales = "free", ncol = 3) +
    ggplot2::labs(
      title = "Cross-family plastome replication",
      subtitle = "Within-family regression: plastome size ~ parasitism",
      x = "Parasitism score",
      y = "Plastome size (kb)"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      strip.background = ggplot2::element_rect(fill = "#ecf0f1", color = NA),
      strip.text = ggplot2::element_text(face = "italic", size = 8)
    )

  p
}


#' T3: Biphasic model comparison
#'
#' Three-panel visualization: (A) scatter of genome size vs symbiosis age
#' with three fitted curves (linear, exponential, logistic), (B) residuals
#' for each model, (C) AICc bar chart comparing model fit.
#'
#' @param data Data frame. Must contain symbiosis_age_mya and genome_bp
#'   columns.
#' @param mod_linear A lm object. Linear model.
#' @param mod_exp An nls object. Exponential decay model, or NULL.
#' @param mod_logistic An nls object. Logistic/saturation model, or NULL.
#'
#' @return A ggplot2 object (patchwork 3-panel: A / (B | C)).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: biphasic kinetics (fast Phase 1, slow Phase 2) — the
#' logistic/saturation model should fit best. Competitors: constant rate
#' (Lynch 2007, linear model), accelerating (Muller's ratchet, exponential).
#' The biphasic shape is unique to the framework's threshold-gated model. This test
#' DOES distinguish the framework from constant-rate and ratchet models.
#'
#' What supports the framework: logistic model has lowest AICc and highest R^2.
#' What refutes the framework: linear or exponential models fit better.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' loaded <- load_endosymbionts()
#' genus_means <- aggregate(cbind(genome_bp, symbiosis_age_mya) ~ genus,
#'   data = loaded$data, FUN = mean
#' )
#' x <- genus_means$symbiosis_age_mya
#' y <- genus_means$genome_bp
#' m_lin <- lm(y ~ x)
#' m_exp <- nls(y ~ a * exp(-b * x), start = list(a = max(y), b = 0.005))
#' m_log <- nls(y ~ fl + (cl - fl) / (1 + exp(rate * (x - mid))),
#'   start = list(
#'     fl = min(y) * 0.8, cl = max(y) * 1.2,
#'     rate = 0.02, mid = mean(x)
#'   )
#' )
#' plot_model_comparison(genus_means, m_lin, m_exp, m_log)
#' }
plot_model_comparison <- function(data, mod_linear, mod_exp, mod_logistic) {
  stopifnot(is.data.frame(data))
  stopifnot(inherits(mod_linear, "lm"))
  stopifnot(is.null(mod_exp) || inherits(mod_exp, "nls"))
  stopifnot(is.null(mod_logistic) || inherits(mod_logistic, "nls"))

  x <- data$symbiosis_age_mya
  y <- data$genome_bp
  x_seq <- seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = 200)

  # Panel A: Scatter with fitted curves
  curves <- data.frame(x = x_seq)
  curves$linear <- stats::predict(mod_linear, newdata = data.frame(symbiosis_age_mya = x_seq))

  if (!is.null(mod_exp)) {
    curves$exp <- stats::predict(mod_exp, newdata = data.frame(symbiosis_age_mya = x_seq))
  } else {
    curves$exp <- NA_real_
  }

  if (!is.null(mod_logistic)) {
    curves$logistic <- stats::predict(mod_logistic,
      newdata = data.frame(symbiosis_age_mya = x_seq)
    )
  } else {
    curves$logistic <- NA_real_
  }

  curves_long <- stats::reshape(
    curves,
    varying = c("linear", "exp", "logistic"),
    v.names = "genome_pred",
    timevar = "model",
    times = c("Linear", "Exponential", "Logistic"),
    direction = "long"
  )
  curves_long <- curves_long[!is.na(curves_long$genome_pred), ]
  rownames(curves_long) <- NULL

  panel_a <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data$symbiosis_age_mya,
    y = .data$genome_bp
  )) +
    ggplot2::geom_point(size = 3, alpha = 0.7, color = "#2c3e50") +
    ggplot2::geom_line(
      data = curves_long,
      ggplot2::aes(
        x = .data$x, y = .data$genome_pred,
        color = .data$model, linetype = .data$model
      ),
      linewidth = 1
    ) +
    ggplot2::scale_color_manual(
      values = list(
        "Linear" = "#e74c3c", "Exponential" = "#f39c12",
        "Logistic" = "#2ecc71"
      )
    ) +
    ggplot2::scale_linetype_manual(
      values = list(
        "Linear" = "dashed", "Exponential" = "dotted",
        "Logistic" = "solid"
      )
    ) +
    ggplot2::labs(
      title = "A: Model Comparison",
      x = "Symbiosis age (mya)",
      y = "Genome size (bp)",
      color = "Model",
      linetype = "Model"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")

  # Panel B: Residuals
  resids <- data.frame(
    x = x,
    linear = stats::residuals(mod_linear)
  )
  if (!is.null(mod_exp)) {
    resids$exp <- stats::residuals(mod_exp)
  } else {
    resids$exp <- NA_real_
  }
  if (!is.null(mod_logistic)) {
    resids$logistic <- stats::residuals(mod_logistic)
  } else {
    resids$logistic <- NA_real_
  }

  resids_long <- stats::reshape(
    resids,
    varying = c("linear", "exp", "logistic"),
    v.names = "residual",
    timevar = "model",
    times = c("Linear", "Exponential", "Logistic"),
    direction = "long"
  )
  resids_long <- resids_long[!is.na(resids_long$residual), ]
  rownames(resids_long) <- NULL

  panel_b <- ggplot2::ggplot(resids_long, ggplot2::aes(
    x = .data$x, y = .data$residual, color = .data$model
  )) +
    ggplot2::geom_hline(
      yintercept = 0, linetype = "dashed", color = "grey50",
      linewidth = 0.5
    ) +
    ggplot2::geom_point(size = 2, alpha = 0.7) +
    ggplot2::scale_color_manual(
      values = list(
        "Linear" = "#e74c3c", "Exponential" = "#f39c12",
        "Logistic" = "#2ecc71"
      )
    ) +
    ggplot2::labs(
      title = "B: Residuals",
      x = "Symbiosis age (mya)",
      y = "Residual"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "none")

  # Panel C: AICc bar chart
  aic_values <- stats::AIC(mod_linear)
  n_obs <- length(stats::residuals(mod_linear))

  # AICc = AIC + 2k(k+1)/(n-k-1)
  k_lin <- length(stats::coef(mod_linear))
  aicc_linear <- aic_values + (2 * k_lin * (k_lin + 1)) / (n_obs - k_lin - 1)

  aicc_df <- data.frame(
    model = "Linear",
    aicc = aicc_linear,
    stringsAsFactors = FALSE
  )

  if (!is.null(mod_exp)) {
    k_exp <- length(stats::coef(mod_exp))
    aic_exp <- stats::AIC(mod_exp)
    aicc_exp <- aic_exp + (2 * k_exp * (k_exp + 1)) / (n_obs - k_exp - 1)
    aicc_df <- rbind(aicc_df, data.frame(
      model = "Exponential", aicc = aicc_exp,
      stringsAsFactors = FALSE
    ))
  }
  if (!is.null(mod_logistic)) {
    k_log <- length(stats::coef(mod_logistic))
    aic_log <- stats::AIC(mod_logistic)
    aicc_log <- aic_log + (2 * k_log * (k_log + 1)) / (n_obs - k_log - 1)
    aicc_df <- rbind(aicc_df, data.frame(
      model = "Logistic", aicc = aicc_log,
      stringsAsFactors = FALSE
    ))
  }

  min_aicc <- min(aicc_df$aicc, na.rm = TRUE)
  aicc_df$delta_aicc <- aicc_df$aicc - min_aicc
  aicc_df$model <- factor(aicc_df$model, levels = c("Linear", "Exponential", "Logistic"))

  panel_c <- ggplot2::ggplot(aicc_df, ggplot2::aes(
    x = .data$model, y = .data$delta_aicc, fill = .data$model
  )) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::scale_fill_manual(
      values = list(
        "Linear" = "#e74c3c", "Exponential" = "#f39c12",
        "Logistic" = "#2ecc71"
      )
    ) +
    ggplot2::labs(
      title = "C: \u0394AICc",
      x = NULL,
      y = "\u0394AICc"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "none")

  # Assemble: A on top, B|C on bottom
  panel_a / (panel_b + panel_c) + patchwork::plot_layout(heights = c(2, 1))
}


#' T4: Partial residual plots for niche vs Ne regression
#'
#' Two-panel partial residual plots side by side: (A) genome size vs Ne,
#' (B) genome size vs niche breadth. Each panel shows the partial residuals
#' (adjusted for the other predictor) with the model's marginal effect line.
#'
#' @param data Data frame. Must contain genome size, Ne, and niche/lifestyle
#'   columns.
#' @param mod_ne A lm object. Model of genome size ~ Ne.
#' @param mod_niche A lm object. Model of genome size ~ niche breadth.
#'
#' @return A ggplot2 object (patchwork: two panels side by side).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction D3: niche breadth predicts gene loss better than Ne alone.
#' Competitor: drift (Lynch 2007) predicts Ne is the primary driver. This
#' test DOES distinguish the framework from drift.
#'
#' What supports the framework: niche panel shows stronger slope and tighter residuals
#' than Ne panel. What refutes the framework: Ne panel dominates.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' loaded <- load_bobay_ochman()
#' ne_col <- grep("Ne", names(loaded$data), value = TRUE)[1]
#' size_col <- grep("genome_size|pan_size|Genome_Size", names(loaded$data),
#'   value = TRUE, ignore.case = TRUE
#' )[1]
#' d <- loaded$data[!is.na(loaded$data[[ne_col]]), ]
#' mod_ne <- lm(as.numeric(d[[size_col]]) ~ as.numeric(d[[ne_col]]))
#' mod_niche <- lm(as.numeric(d[[size_col]]) ~ as.numeric(factor(d$lifestyle)))
#' plot_partial_residuals(d, mod_ne, mod_niche)
#' }
plot_partial_residuals <- function(data, mod_ne, mod_niche) {
  stopifnot(is.data.frame(data))
  stopifnot(inherits(mod_ne, "lm"), inherits(mod_niche, "lm"))

  # Extract predictor names
  ne_col <- all.vars(stats::formula(mod_ne))[2]
  niche_col <- all.vars(stats::formula(mod_niche))[2]

  # Panel A: Ne partial residuals
  ne_pred <- stats::predict(mod_ne)
  ne_resid <- stats::residuals(mod_ne)
  ne_partial <- ne_resid + stats::coef(mod_ne)[2] * data[[ne_col]]

  panel_a_df <- data.frame(
    predictor = as.numeric(data[[ne_col]]),
    partial = as.numeric(ne_partial)
  )
  panel_a <- ggplot2::ggplot(panel_a_df, ggplot2::aes(
    x = .data$predictor,
    y = .data$partial
  )) +
    ggplot2::geom_hline(
      yintercept = 0, linetype = "dashed", color = "grey50",
      linewidth = 0.5
    ) +
    ggplot2::geom_point(size = 2, alpha = 0.5, color = "#3498db") +
    ggplot2::geom_smooth(
      method = "lm", se = TRUE, color = "#e74c3c",
      fill = "#e74c3c", alpha = 0.15, linewidth = 0.8
    ) +
    ggplot2::labs(
      title = "A: Partial Residuals: Ne",
      x = "Effective population size (Ne)",
      y = "Partial residual (genome size | niche)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  # Panel B: Niche partial residuals
  niche_pred <- stats::predict(mod_niche)
  niche_resid <- stats::residuals(mod_niche)
  niche_partial <- niche_resid + stats::coef(mod_niche)[2] * as.numeric(data[[niche_col]])

  panel_b_df <- data.frame(
    predictor = as.numeric(data[[niche_col]]),
    partial = as.numeric(niche_partial)
  )
  panel_b <- ggplot2::ggplot(panel_b_df, ggplot2::aes(
    x = .data$predictor,
    y = .data$partial
  )) +
    ggplot2::geom_hline(
      yintercept = 0, linetype = "dashed", color = "grey50",
      linewidth = 0.5
    ) +
    ggplot2::geom_point(size = 2, alpha = 0.5, color = "#2ecc71") +
    ggplot2::geom_smooth(
      method = "lm", se = TRUE, color = "#e74c3c",
      fill = "#e74c3c", alpha = 0.15, linewidth = 0.8
    ) +
    ggplot2::labs(
      title = "B: Partial Residuals: Niche",
      x = "Niche breadth",
      y = "Partial residual (genome size | Ne)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  panel_a + panel_b
}


#' T5: Pan-genome fluidity by lifestyle
#'
#' Box plot of pangenome fluidity grouped by lifestyle category, with
#' jittered individual data points. Lifestyle categories are ordered
#' from free-living to obligate (increasing host dependence).
#'
#' @param data Data frame. Must contain pangenome_fluidity and a lifestyle
#'   column.
#'
#' @return A ggplot2 object (box plot with jitter).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: pan-genome openness tracks lifestyle — free-living
#' bacteria have more open pan-genomes than obligate intracellular
#' symbionts. Competitor: Ne-only model predicts Ne drives pan-genome
#' size regardless of lifestyle. This test DOES distinguish the framework from
#' the Ne-only model.
#'
#' What supports the framework: fluidity decreases from free-living to obligate.
#' What refutes the framework: no trend or reverse trend.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' loaded <- load_dewar_pangenome()
#' plot_fluidity_by_lifestyle(loaded$data)
#' }
plot_fluidity_by_lifestyle <- function(data) {
  stopifnot(is.data.frame(data))
  stopifnot("pangenome_fluidity" %in% names(data))

  # Find lifestyle column
  lifestyle_col <- grep("lifestyle|Life|Host_or_free|Obligate",
    names(data),
    value = TRUE, ignore.case = TRUE
  )[1]
  stopifnot(!is.na(lifestyle_col))

  # Create ordered factor: free-living -> obligate
  lifestyle_order <- c(
    "free_living", "free-living", "Free-living",
    "Free living", "commensal", "Commensal",
    "facultative", "Facultative",
    "obligate_intracellular", "obligate",
    "Obligate", "Obligate intracellular"
  )
  data$.lifestyle <- factor(data[[lifestyle_col]],
    levels = intersect(
      lifestyle_order,
      unique(data[[lifestyle_col]])
    ),
    ordered = TRUE
  )

  # If no matches, make ordered by appearance and reverse
  if (all(is.na(data$.lifestyle))) {
    data$.lifestyle <- factor(data[[lifestyle_col]], ordered = TRUE)
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data$.lifestyle, y = .data$pangenome_fluidity
  )) +
    ggplot2::geom_boxplot(
      outlier.shape = NA, fill = "#bdc3c7",
      alpha = 0.4, width = 0.6
    ) +
    ggplot2::geom_jitter(
      width = 0.15, size = 2, alpha = 0.6,
      color = "#2980b9"
    ) +
    ggplot2::labs(
      title = "Pan-genome fluidity by lifestyle",
      subtitle = "Ordered: free-living to obligate intracellular",
      x = "Lifestyle",
      y = "Pan-genome fluidity"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))

  p
}


#' T6: Rank-rank heatmap of gene-loss ordering
#'
#' Heatmap with rows = gene categories ordered by dependency score (highest
#' at top), columns = lineages. Cell color encodes loss rank (1 = first to
#' lose, dark = lost early). Dendrogram optionally shown on column margins.
#'
#' @param data Data frame. Must contain category, dependency_score, and
#'   at least one *_loss_rank column.
#' @param show_dendrogram Logical. If TRUE, display a column dendrogram
#'   (requires stats::hclust). Default FALSE.
#'
#' @return A ggplot2 object (heatmap with optional dendrogram).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: integration depth determines gene-loss order — deeply
#' integrated functions (high dependency score) are retained longer.
#' Competitor: random loss predicts no ordering. This test DOES distinguish
#' the framework from random loss.
#'
#' What supports the framework: high Spearman rho (deeply integrated -> retained).
#' What refutes the framework: rho near zero (no ordering).
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
#'   dependency_score = c(0, 1, 1, 2, 3, 5),
#'   orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6),
#'   cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6)
#' )
#' plot_rank_rank_heatmap(data)
#' }
plot_rank_rank_heatmap <- function(data, show_dendrogram = FALSE) {
  stopifnot(is.data.frame(data))
  stopifnot(all(c("category", "dependency_score") %in% names(data)))

  # Find loss rank columns
  loss_cols <- grep("_loss_rank$", names(data), value = TRUE)
  stopifnot(length(loss_cols) >= 1L)

  # Order rows by dependency score (highest at top)
  data <- data[order(data$dependency_score, decreasing = TRUE), ]
  data$category <- factor(data$category,
    levels = rev(unique(data$category)),
    ordered = TRUE
  )

  # Reshape to long format for heatmap
  heat_data <- stats::reshape(
    data[, c("category", "dependency_score", loss_cols)],
    varying = loss_cols,
    v.names = "loss_rank",
    timevar = "lineage",
    times = gsub("_loss_rank$", "", loss_cols),
    direction = "long"
  )
  rownames(heat_data) <- NULL

  # Clean lineage names
  heat_data$lineage <- gsub("_", " ", heat_data$lineage)
  heat_data$lineage <- gsub(" orobanchaceae", "", heat_data$lineage,
    ignore.case = TRUE
  )
  heat_data$lineage <- gsub(" cuscuta", "", heat_data$lineage,
    ignore.case = TRUE
  )
  heat_data$lineage <- tools::toTitleCase(heat_data$lineage)

  # Add dependency score label for rows
  heat_data$category_label <- sprintf(
    "%s (d=%.0f)", heat_data$category,
    heat_data$dependency_score
  )

  p <- ggplot2::ggplot(heat_data, ggplot2::aes(
    x = .data$lineage, y = .data$category_label, fill = .data$loss_rank
  )) +
    ggplot2::geom_tile(color = "white", linewidth = 1) +
    ggplot2::scale_fill_gradient2(
      low = "#e74c3c", mid = "#f39c12", high = "#2ecc71",
      midpoint = median(data$dependency_score, na.rm = TRUE),
      name = "Loss rank\n(1 = first)"
    ) +
    ggplot2::labs(
      title = "Gene-loss ordering across lineages",
      subtitle = "Rows ordered by dependency score (highest at top)",
      x = "Lineage",
      y = "Gene category"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      panel.grid = ggplot2::element_blank()
    )

  if (show_dendrogram && length(loss_cols) >= 3) {
    # Compute column dendrogram from loss ranks
    rank_matrix <- as.matrix(data[, loss_cols])
    colnames(rank_matrix) <- gsub("_loss_rank$", "", loss_cols)
    hc <- stats::hclust(stats::dist(t(rank_matrix)))
    # Add dendrogram ordering to factor levels
    heat_data$lineage <- factor(heat_data$lineage,
      levels = colnames(rank_matrix)[hc$order],
      ordered = TRUE
    )
    p <- p + ggplot2::aes(x = .data$lineage)
  }

  p
}


#' T7: Observed vs expected co-segregation bar chart
#'
#' Bar chart comparing observed vs expected proportion of metabolically
#' lost functions that co-segregate with beneficial mutations. Confidence
#' interval whiskers shown for the observed proportion.
#'
#' @param observed Numeric. Observed proportion (0-1 or 0-100).
#' @param expected Numeric. Expected proportion under null.
#' @param ci Numeric vector of length 2. Lower and upper confidence bounds
#'   for the observed proportion.
#'
#' @return A ggplot2 object (bar chart with CI whiskers).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: function-loss mutations co-segregate with beneficial
#' mutations (passive drift in unused genes). Competitor: independent
#' assortment predicts 61.7% co-segregation. Reported as suggestive due
#' to hitchhiking confound.
#'
#' What supports the framework: observed co-segregation is significantly lower than
#' expected by chance. What refutes the framework: observed rate equals or exceeds
#' expected rate.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' plot_observed_vs_expected_bar(
#'   observed = 36.4, expected = 61.7, ci = c(30.2, 42.6)
#' )
#' }
plot_observed_vs_expected_bar <- function(observed, expected, ci) {
  stopifnot(is.numeric(observed), length(observed) == 1)
  stopifnot(is.numeric(expected), length(expected) == 1)
  stopifnot(is.numeric(ci), length(ci) == 2)

  # Normalize if proportions (0-1) were passed
  if (observed < 1 && observed >= 0 && expected < 1 && expected >= 0) {
    observed <- observed * 100
    expected <- expected * 100
    ci <- ci * 100
  }

  bar_df <- data.frame(
    type = c("Observed", "Expected (chance)"),
    proportion = c(observed, expected),
    lower = c(ci[1], NA),
    upper = c(ci[2], NA),
    stringsAsFactors = FALSE
  )
  bar_df$type <- factor(bar_df$type, levels = c("Expected (chance)", "Observed"))

  p <- ggplot2::ggplot(bar_df, ggplot2::aes(
    x = .data$type, y = .data$proportion, fill = .data$type
  )) +
    ggplot2::geom_col(width = 0.5) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
      width = 0.15, linewidth = 0.8, na.rm = TRUE
    ) +
    ggplot2::scale_fill_manual(
      values = list("Observed" = "#3498db", "Expected (chance)" = "#e74c3c")
    ) +
    ggplot2::labs(
      title = "LTEE: function-loss co-segregation",
      subtitle = sprintf("Observed: %.1f%% vs Expected: %.1f%%", observed, expected),
      x = NULL,
      y = "Co-segregation proportion (%)"
    ) +
    ggplot2::ylim(0, max(100, ci[2] * 1.2)) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "none")

  p
}


#' Formal model: Retention trajectory over time
#'
#' Plots retention probability C_i(t) over time for traits at different
#' integration depths. Lines are colored by depth gradient. The phase
#' boundary (time of transition from fast to slow phase) is marked with
#' a vertical dashed line.
#'
#' @param model_result List. Return value from threshold_model().
#' @param depths Numeric vector. Integration depths used in the model.
#'   Default taken from model_result metadata if available.
#'
#' @return A ggplot2 object (retention trajectories with phase boundary).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' rapidly at rate proportional to lambda * M0), slow Phase 2 (protected
#' traits remain at 1.0). The phase boundary occurs when mismatch decays
#' below the threshold fraction.
#'
#' What supports the framework: clear inflection point between steep and shallow
#' retention decline. What refutes the framework: constant-rate decline.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' result <- threshold_model(
#'   depths = c(0, 1, 2, 3, 5),
#'   lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 100
#' )
#' plot_retention_trajectory(result)
#' }
plot_retention_trajectory <- function(model_result, depths = NULL) {
  stopifnot(is.list(model_result))
  stopifnot("values" %in% names(model_result))
  stopifnot("metadata" %in% names(model_result))

  meta <- model_result$metadata
  if (is.null(depths) && !is.null(meta$params)) {
    # For a single-param run, we need to reconstruct
    depths <- seq_len(meta$n_traits)
  }
  stopifnot(!is.null(depths))

  # Reconstruct retention history by re-running the model
  # The model_result only stores the final values vector
  # We need to analyze the phase structure
  params <- meta$params
  lambda <- params$lambda
  theta <- params$theta
  m0 <- params$m0
  alpha <- params$alpha
  time <- params$time
  n_steps <- 500L
  dt <- time / n_steps

  # Simulate retention over time for each depth
  step_times <- seq(0, time, length.out = n_steps + 1)
  retention_matrix <- matrix(1.0, nrow = n_steps + 1, ncol = length(depths))

  for (step in seq_len(n_steps)) {
    t_current <- step * dt
    m_t <- m0 * exp(-alpha * t_current)
    for (i in seq_along(depths)) {
      if (depths[i] < theta) {
        d_c <- -lambda * m_t * retention_matrix[step, i] * dt
        retention_matrix[step + 1, i] <- max(0, retention_matrix[step, i] + d_c)
      }
      # Protected traits stay at 1.0
    }
  }

  # Reshape to long format
  traj_list <- lapply(seq_along(depths), function(i) {
    data.frame(
      time = step_times,
      retention = retention_matrix[, i],
      depth = depths[i],
      protected = depths[i] >= theta,
      stringsAsFactors = FALSE
    )
  })
  traj_df <- do.call(rbind, traj_list)
  traj_df$depth_label <- sprintf(
    "d = %.1f%s", traj_df$depth,
    ifelse(traj_df$protected, " (protected)", "")
  )

  # Compute phase boundary
  phase_time <- -log(0.1) / alpha

  # Extract biphasic metrics for annotation. early_late_displacement_ratio
  # is a temporal displacement ratio (descriptive); threshold_biphasicity is
  # the genuine biphasic signal (protected − unprotected retention). Fall
  # back gracefully if a field is absent (older proof objects).
  displacement <- if (!is.null(model_result$values[["early_late_displacement_ratio"]])) {
    unname(model_result$values[["early_late_displacement_ratio"]])
  } else {
    NA_real_
  }
  biphasicity <- if (!is.null(model_result$values[["threshold_biphasicity"]])) {
    unname(model_result$values[["threshold_biphasicity"]])
  } else {
    NA_real_
  }

  p <- ggplot2::ggplot(traj_df, ggplot2::aes(
    x = .data$time, y = .data$retention,
    color = .data$depth_label, linetype = .data$protected
  )) +
    ggplot2::geom_hline(
      yintercept = 1.0, linetype = "dotted", color = "grey70",
      linewidth = 0.5
    ) +
    ggplot2::geom_vline(
      xintercept = phase_time, linetype = "dashed",
      color = "#e74c3c", linewidth = 0.8
    ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_viridis_d(
      option = "D", end = 0.9,
      name = "Integration depth"
    ) +
    ggplot2::scale_linetype_manual(
      values = list("TRUE" = "solid", "FALSE" = "dashed"),
      guide = "none"
    ) +
    ggplot2::annotate("text",
      x = phase_time * 1.05, y = 0.1,
      label = sprintf("Phase\nboundary\nt = %.1f", phase_time),
      hjust = 0, size = 3, color = "#e74c3c"
    ) +
    ggplot2::annotate("text",
      x = time * 0.9, y = 0.95,
      label = sprintf("threshold biphasicity = %.2f", biphasicity),
      hjust = 1, size = 3.5, color = "grey30"
    ) +
    ggplot2::labs(
      title = "Retention probability over time",
      subtitle = sprintf(
        "lambda = %.2f, theta = %.1f, M\u2080 = %.0f, alpha = %.3f",
        lambda, theta, m0, alpha
      ),
      x = "Time",
      y = "Retention probability C\u1d62(t)"
    ) +
    ggplot2::ylim(0, 1.05) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "right")

  p
}


#' Cusp catastrophe: Bifurcation contour and hysteresis loop
#'
#' Panel A: 2D contour of the cusp potential over the (a, b) control
#' parameter space, with the bifurcation set |b| = 2*(a/3)^(3/2) / 27^(1/2)
#' marked as a dashed line. Panel B: hysteresis loop showing the forward
#' path (increasing commitment) vs reverse path (decreasing commitment).
#'
#' @param a_range Numeric vector of length 2. Range of a (splitting factor).
#' @param b_range Numeric vector of length 2. Range of b (normal factor).
#' @param grid_size Integer. Resolution of the contour grid. Default 50.
#'
#' @return A ggplot2 object (patchwork: A | B).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: irreversibility — substrate-shift creates a bifurcation
#' that is difficult to reverse. The cusp catastrophe models this: smooth
#' changes in control parameters produce sudden, irreversible jumps.
#' Competitor: gradual reversibility (standard quantitative genetics
#' predicts smooth recovery when selection pressure is removed).
#'
#' What supports the framework: clear bifurcation region and hysteresis loop.
#' What refutes the framework: no bifurcation (smooth transitions everywhere).
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' plot_cusp_bifurcation(a_range = c(-5, 5), b_range = c(-5, 5))
#' }
plot_cusp_bifurcation <- function(a_range, b_range, grid_size = 50L) {
  stopifnot(is.numeric(a_range), length(a_range) == 2)
  stopifnot(is.numeric(b_range), length(b_range) == 2)

  a_seq <- seq(a_range[1], a_range[2], length.out = grid_size)
  b_seq <- seq(b_range[1], b_range[2], length.out = grid_size)
  grid <- expand.grid(a = a_seq, b = b_seq)

  # Cusp potential: V(x) = x^4/4 + a*x^2/2 + b*x
  # Equilibrium condition: x^3 + a*x + b = 0
  # Bifurcation set: 4*a^3 + 27*b^2 = 0
  grid$bifurcation <- 4 * grid$a^3 + 27 * grid$b^2
  grid$bifurcation_set <- abs(grid$bifurcation) < 1e-6

  # Count real roots of the cubic
  # Discriminant determines root count
  grid$delta <- (grid$b / 2)^2 + (grid$a / 3)^3
  grid$n_roots <- ifelse(grid$delta < 0, 3,
    ifelse(abs(grid$delta) < 1e-6, 2, 1)
  )

  panel_a <- ggplot2::ggplot(grid, ggplot2::aes(x = .data$a, y = .data$b)) +
    ggplot2::geom_raster(ggplot2::aes(fill = factor(.data$n_roots)),
      alpha = 0.7
    ) +
    ggplot2::geom_contour(ggplot2::aes(z = .data$bifurcation),
      breaks = 0, color = "#e74c3c", linewidth = 1,
      linetype = "dashed"
    ) +
    ggplot2::scale_fill_manual(
      values = list("1" = "#bdc3c7", "2" = "#f39c12", "3" = "#3498db"),
      name = "Equilibria",
      labels = c("1" = "1 stable", "2" = "2 (fold)", "3" = "3 (bistable)")
    ) +
    ggplot2::labs(
      title = "A: Bifurcation set",
      subtitle = "4a\u00b3 + 27b\u00b2 = 0 (dashed)",
      x = "a (splitting factor)",
      y = "b (normal factor)"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")

  # Panel B: Hysteresis loop. Uses the SAME branch-following contract as
  # cusp_hysteresis_check(): the reverse sweep starts from the forward sweep's
  # FINAL state (ramp up, then ramp down from the top), so the two paths can
  # settle to different branches in the bistable region. Previously both
  # sweeps started from x=0, which produced a loop for the wrong reason
  # (different starting points, not path dependence).
  n_pts <- 100
  a_fixed <- -0.5
  b_seq_path <- seq(b_range[1], b_range[2], length.out = n_pts)

  # Newton solver for the nearest real root of x^3 + a*x + b = 0
  solve_nearest <- function(b_val, x_guess, a) {
    for (iter in 1:50) {
      fx <- x_guess^3 + a * x_guess + b_val
      fpx <- 3 * x_guess^2 + a
      if (abs(fpx) < 1e-10) break
      x_new <- x_guess - fx / fpx
      if (abs(x_new - x_guess) < 1e-8) break
      x_guess <- x_new
    }
    x_guess
  }

  # Forward sweep: increasing b, state threaded from x=0
  forward_states <- numeric(n_pts)
  x_guess <- 0
  for (i in seq_len(n_pts)) {
    x_guess <- solve_nearest(b_seq_path[i], x_guess, a_fixed)
    forward_states[i] <- x_guess
  }

  # Reverse sweep: decreasing b, starting from the forward sweep's FINAL
  # state (standard hysteresis protocol).
  reverse_states <- numeric(n_pts)
  for (i in seq_len(n_pts)) {
    x_guess <- solve_nearest(rev(b_seq_path)[i], x_guess, a_fixed)
    reverse_states[i] <- x_guess
  }

  hysteresis_df <- data.frame(
    b = b_seq_path,
    forward = forward_states,
    reverse = rev(reverse_states)
  )

  # Only show hysteresis if paths differ
  hysteresis_long <- rbind(
    data.frame(
      b = hysteresis_df$b, state = hysteresis_df$forward,
      path = "Forward", stringsAsFactors = FALSE
    ),
    data.frame(
      b = hysteresis_df$b, state = hysteresis_df$reverse,
      path = "Reverse", stringsAsFactors = FALSE
    )
  )

  panel_b <- ggplot2::ggplot(
    hysteresis_long,
    ggplot2::aes(
      x = .data$b, y = .data$state,
      color = .data$path
    )
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(
      values = list("Forward" = "#2ecc71", "Reverse" = "#e74c3c")
    ) +
    ggplot2::labs(
      title = "B: Hysteresis loop",
      subtitle = sprintf("a = %.1f (bistable region)", a_fixed),
      x = "b (normal factor)",
      y = "State x",
      color = "Path"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")

  panel_a + panel_b
}


#' Autocatalytic growth: log-log plot and catalyst network
#'
#' Panel A: log-log plot of innovation counts over time with slope
#' annotation. A slope > 1 indicates superlinear (autocatalytic) growth.
#' Panel B: catalyst network graph showing which innovations catalyze
#' which.
#'
#' @param counts Numeric vector. Innovation counts over time.
#' @param catalyst_matrix Optional logical matrix. catalyst_matrix[i,j] =
#'   TRUE if innovation i catalyzes innovation j. If provided, Panel B
#'   renders a network graph.
#' @param innovation_names Optional character vector. Names of innovations
#'   for the network graph.
#'
#' @return A ggplot2 object (patchwork: A | B).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: positive diversity-dependence in the cultural substrate
#' (the Homo inversion). Competitor: standard niche-filling predicts
#' negatively diversity-dependent (logistic) growth. This test DOES
#' distinguish the framework from niche-filling.
#'
#' What supports the framework: log-log slope > 1 (superlinear growth).
#' What refutes the framework: log-log slope <= 1 (linear or sublinear).
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' # Exponential growth example
#' counts <- 10 * exp(0.1 * 1:50)
#' plot_loglog_growth(counts)
#' }
plot_loglog_growth <- function(counts, catalyst_matrix = NULL,
                               innovation_names = NULL) {
  stopifnot(is.numeric(counts), length(counts) >= 5)

  n <- length(counts)
  time <- seq_len(n)

  # Log-log data
  log_df <- data.frame(
    log_time = log(time[time > 0]),
    log_count = log(pmax(counts[time > 0], 1))
  )

  # Fit log-log slope
  log_mod <- stats::lm(log_count ~ log_time, data = log_df)
  log_slope <- unname(stats::coef(log_mod)[2])
  log_r2 <- summary(log_mod)$r.squared

  panel_a <- ggplot2::ggplot(log_df, ggplot2::aes(
    x = .data$log_time, y = .data$log_count
  )) +
    ggplot2::geom_point(size = 2.5, alpha = 0.6, color = "#2c3e50") +
    ggplot2::geom_smooth(
      method = "lm", se = TRUE, color = "#e74c3c",
      fill = "#e74c3c", alpha = 0.15, linewidth = 0.8
    ) +
    ggplot2::annotate("text",
      x = max(log_df$log_time) * 0.7,
      y = max(log_df$log_count) * 0.9,
      label = sprintf(
        "slope = %.3f\nR\u00b2 = %.3f\n%s",
        log_slope, log_r2,
        ifelse(log_slope > 1,
          "Superlinear!",
          "Sublinear"
        )
      ),
      hjust = 0, size = 3.5, color = "grey30"
    ) +
    ggplot2::labs(
      title = "A: Log-log growth",
      subtitle = "Slope > 1 = autocatalytic (superlinear)",
      x = "log(Time)",
      y = "log(Innovation count)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  # Panel B: Catalyst network (if matrix provided)
  if (!is.null(catalyst_matrix)) {
    n_innov <- nrow(catalyst_matrix)
    if (is.null(innovation_names)) {
      innovation_names <- paste0("I", seq_len(n_innov))
    }

    # Build edge list
    edges <- which(catalyst_matrix, arr.ind = TRUE)
    edges <- as.data.frame(edges)
    colnames(edges) <- c("from", "to")

    # Simple circular layout
    angles <- seq(0, 2 * pi * (1 - 1 / n_innov), length.out = n_innov)
    node_pos <- data.frame(
      node = innovation_names,
      x = sin(angles),
      y = cos(angles),
      stringsAsFactors = FALSE
    )

    edges$x <- node_pos$x[edges$from]
    edges$y <- node_pos$y[edges$from]
    edges$xend <- node_pos$x[edges$to]
    edges$yend <- node_pos$y[edges$to]

    # Count how many innovations each catalyzes
    node_pos$catalyzes <- sapply(seq_len(n_innov), function(i) {
      sum(edges$from == i)
    })
    node_pos$catalyzed_by <- sapply(seq_len(n_innov), function(i) {
      sum(edges$to == i)
    })

    panel_b <- ggplot2::ggplot() +
      ggplot2::geom_segment(
        data = edges,
        ggplot2::aes(
          x = .data$x, y = .data$y,
          xend = .data$xend, yend = .data$yend
        ),
        arrow = ggplot2::arrow(length = ggplot2::unit(0.08, "inches")),
        color = "grey60", alpha = 0.5, linewidth = 0.5
      ) +
      ggplot2::geom_point(
        data = node_pos,
        ggplot2::aes(x = .data$x, y = .data$y, size = .data$catalyzes),
        color = "#3498db", alpha = 0.8
      ) +
      ggplot2::geom_text(
        data = node_pos,
        ggplot2::aes(
          x = .data$x * 1.15, y = .data$y * 1.15,
          label = .data$node
        ),
        size = 3, check_overlap = TRUE
      ) +
      ggplot2::scale_size_continuous(name = "Catalyzes") +
      ggplot2::labs(
        title = "B: Catalyst network",
        subtitle = sprintf(
          "Closure: %d/%d catalyzed",
          sum(node_pos$catalyzed_by > 0), n_innov
        )
      ) +
      ggplot2::coord_fixed() +
      ggplot2::theme_void() +
      ggplot2::theme(legend.position = "bottom")
  } else {
    # If no matrix, show a placeholder
    panel_b <- ggplot2::ggplot() +
      ggplot2::annotate("text",
        x = 0.5, y = 0.5,
        label = "No catalyst matrix provided",
        size = 4, color = "grey50"
      ) +
      ggplot2::labs(title = "B: Catalyst network") +
      ggplot2::theme_void()
  }

  panel_a + panel_b
}


#' L3: Cross-kingdom rank concordance
#'
#' Two-panel comparison: (A) plant data scatter with fitted slope
#' (dependency score vs loss rank), (B) bird data scatter with the
#' plant-derived slope overlaid (predicting morphological change
#' ordering from integration depth).
#'
#' @param plant_data Data frame. Must contain dependency_score and a
#'   *_loss_rank column.
#' @param bird_data Data frame. Must contain dependency_score and
#'   observed_rank.
#' @param plant_slope Numeric. Slope from fit_plant_model()$values["slope"].
#'
#' @return A ggplot2 object (patchwork: two panels side by side).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: integration-depth parameters transfer across kingdoms.
#' Competitor: substrates are independent — no parameter transfer. This
#' test DOES distinguish the framework. This is the strongest test in the monograph.
#'
#' What supports the framework: bird ordering predicted by plant-derived slope matches
#' observed ordering (high Spearman rho). What refutes the framework: no match
#' (rho near zero).
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' plant_data <- data.frame(
#'   category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
#'   dependency_score = c(0, 1, 1, 2, 3, 5),
#'   orobanchaceae_loss_rank = 1:6
#' )
#' bird_data <- .fixture_bird_morphology
#' result <- fit_plant_model(plant_data)
#' plot_cross_kingdom_concordance(
#'   plant_data, bird_data,
#'   result$values["slope"]
#' )
#' }
plot_cross_kingdom_concordance <- function(plant_data, bird_data, plant_slope) {
  stopifnot(is.data.frame(plant_data))
  stopifnot(is.data.frame(bird_data))
  stopifnot(is.numeric(plant_slope), length(plant_slope) == 1)

  # Plant panel
  loss_col <- grep("_loss_rank$", names(plant_data), value = TRUE)[1]
  stopifnot(!is.na(loss_col))

  plant_fit <- stats::lm(plant_data[[loss_col]] ~ plant_data$dependency_score)
  plant_r2 <- summary(plant_fit)$r.squared

  panel_a <- ggplot2::ggplot(plant_data, ggplot2::aes(
    x = .data$dependency_score, y = .data[[loss_col]]
  )) +
    ggplot2::geom_smooth(
      method = "lm", se = TRUE, color = "#2ecc71",
      fill = "#2ecc71", alpha = 0.15, linewidth = 0.8
    ) +
    ggplot2::geom_point(size = 3, alpha = 0.7, color = "#27ae60") +
    ggplot2::labs(
      title = "A: Plant (Orobanchaceae)",
      subtitle = sprintf("slope = %.3f, R\u00b2 = %.3f", plant_slope, plant_r2),
      x = "Dependency score",
      y = "Loss rank"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  # Bird panel: plant-derived slope overlaid
  # Predicted ordering from plant slope
  bird_predicted <- plant_slope * bird_data$dependency_score
  bird_predicted_rank <- rank(bird_predicted, ties.method = "average")

  # Compute bird correlation
  bird_cor <- stats::cor.test(bird_predicted_rank, bird_data$observed_rank,
    method = "spearman"
  )

  panel_b <- ggplot2::ggplot(bird_data, ggplot2::aes(
    x = .data$dependency_score, y = .data$observed_rank
  )) +
    # Plant-derived slope (no intercept, ordering only)
    ggplot2::geom_abline(
      slope = plant_slope, intercept = 0,
      color = "#e74c3c", linewidth = 1, linetype = "dashed"
    ) +
    ggplot2::geom_point(size = 3, alpha = 0.7, color = "#2980b9") +
    ggplot2::labs(
      title = "B: Bird (island flight-loss)",
      subtitle = sprintf(
        "Plant slope applied: \u03c1 = %.3f, p = %.3f",
        unname(bird_cor$estimate), bird_cor$p.value
      ),
      x = "Dependency score",
      y = "Observed morphological change rank",
      caption = "Red dashed = plant-derived slope (no refit)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  panel_a + panel_b
}


#' Baseline oracle: Forest plot of all results
#'
#' Forest plot with one row per oracle result. Expected value shown as a
#' dot, observed value as a diamond, and the tolerance band as a whisker.
#' Rows are colored green (pass) or red (fail) based on whether the
#' observed value falls within the tolerance band of the expected value.
#'
#' @param oracle_results Data frame. Must contain columns: test_name,
#'   expected, observed, tolerance, supports_framework (logical), and
#'   distinguishes (logical).
#'
#' @return A ggplot2 object (forest plot).
#'
#' @section Theoretical Context:
#'
#' The baseline oracle is the ground truth — every manuscript-reported
#' result. The pipeline must reproduce these within numerical tolerance.
#' This plot communicates at a glance which tests pass and which fail.
#'
#' The forest plot layout is the standard meta-analysis forest plot:
#' dots for expected values, diamonds for observed, whiskers for tolerance.
#' This is a well-known format in systematic reviews.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (structured, inspectable)
#'
#' @export
#' @examples
#' \dontrun{
#' oracle <- data.frame(
#'   test_name = c("T1: beta", "T1: R2", "T3: R2", "T6: rho"),
#'   expected = c(-23.5, 0.652, 0.920, 0.955),
#'   observed = c(-23.5, 0.652, 0.920, 0.955),
#'   tolerance = c(0.001, 0.001, 0.01, 0.001),
#'   supports_framework = c(TRUE, TRUE, TRUE, TRUE),
#'   distinguishes = c(FALSE, FALSE, TRUE, TRUE)
#' )
#' plot_forest_oracle(oracle)
#' }
plot_forest_oracle <- function(oracle_results) {
  stopifnot(is.data.frame(oracle_results))
  required_cols <- c(
    "test_name", "expected", "observed", "tolerance",
    "supports_framework", "distinguishes"
  )
  missing <- setdiff(required_cols, names(oracle_results))
  stopifnot(length(missing) == 0L)

  # Compute pass/fail
  oracle_results$pass <- abs(oracle_results$observed - oracle_results$expected) <=
    oracle_results$tolerance
  oracle_results$lower <- oracle_results$expected - oracle_results$tolerance
  oracle_results$upper <- oracle_results$expected + oracle_results$tolerance

  # Create row order (reverse for top-to-bottom forest plot)
  oracle_results <- oracle_results[rev(seq_len(nrow(oracle_results))), ]
  oracle_results$row_id <- factor(seq_len(nrow(oracle_results)),
    labels = oracle_results$test_name,
    ordered = TRUE
  )

  # Add label column
  oracle_results$label <- sprintf(
    "%s\n%s",
    ifelse(oracle_results$pass, "\u2713 Pass", "\u2717 Fail"),
    ifelse(oracle_results$distinguishes, "Distinguishes", "Non-distinguishing")
  )

  p <- ggplot2::ggplot(oracle_results, ggplot2::aes(y = .data$row_id)) +
    # Tolerance band
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$lower, xend = .data$upper, yend = .data$row_id),
      color = "grey60", linewidth = 1.5, na.rm = TRUE
    ) +
    # Expected dot
    ggplot2::geom_point(
      ggplot2::aes(x = .data$expected),
      shape = 19, size = 4,
      color = "#2c3e50"
    ) +
    # Observed diamond
    ggplot2::geom_point(
      ggplot2::aes(
        x = .data$observed,
        color = .data$pass
      ),
      shape = 18, size = 5
    ) +
    # Color by pass/fail
    ggplot2::scale_color_manual(
      values = list("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
      labels = c("TRUE" = "Pass", "FALSE" = "Fail"),
      name = "Status"
    ) +
    # Reference line
    ggplot2::geom_vline(
      xintercept = 0, linetype = "dotted", color = "grey50",
      linewidth = 0.5
    ) +
    # Annotations
    ggplot2::geom_text(
      data = oracle_results,
      ggplot2::aes(x = .data$upper, label = .data$label),
      hjust = -0.1, size = 2.8, color = "grey40"
    ) +
    ggplot2::labs(
      title = "Baseline oracle: regression check",
      subtitle = "Dots = expected, diamonds = observed, bars = tolerance",
      x = "Value",
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      axis.text.y = ggplot2::element_text(size = 9)
    ) +
    # Expand right margin for labels
    ggplot2::coord_cartesian(
      xlim = c(
        min(oracle_results$lower, na.rm = TRUE) * 1.1,
        max(oracle_results$upper, na.rm = TRUE) * 1.8
      )
    )

  p
}
