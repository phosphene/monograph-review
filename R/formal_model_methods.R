#' S3 Methods for Formal Model Result Classes
#'
#' Implements standard S3 generics: print(), summary(), plot(), as.data.frame()
#' for all formal model result types. Follows Phosphene R Standards §7.
#'
#' @section Theoretical Context:
#'
#' - `print()` — human-readable console output for quick inspection
#' - `summary()` — tidy data.frame for programmatic access
#' - `plot()` — ggplot2 object (never draws directly; caller controls display)
#' - `as.data.frame()` — converts to data frame for downstream piping
#'
#' All methods follow DFT A1 (pure-io-separation): no side effects, return values only.
#'
#' @name formal_model_methods
NULL

# ==============================================================================
# VI_THRESHOLD_RESULT METHODS
# ==============================================================================

#' Print valence_threshold_result Object
#'
#' Human-readable console output showing:
#' - Parameter summary
#' - Trait counts (protected vs unprotected)
#' - Biphasicity metrics
#' - Retention trajectory statistics
#'
#' @param x valence_threshold_result object.
#' @param ... Ignored (standard print argument).
#'
#' @return Invisibly returns x.
#' @export
#' @examples
#' \dontrun{
#' result <- threshold_model(
#'   depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
#'   m0 = 10, alpha = 0.05, time = 100
#' )
#' print(result)
#' }
print.valence_threshold_result <- function(x, ...) {
  cat("valence_threshold_result\n")
  cat("===================\n\n")

  # Parameters
  params <- x$metadata$params
  cat("Parameters:\n")
  cat(sprintf("  λ (shedding rate):       %.4f\n", params$lambda))
  cat(sprintf("  θ (threshold):           %.4f\n", params$theta))
  cat(sprintf("  M₀ (initial mismatch):   %.4f\n", params$m0))
  cat(sprintf("  α (decay rate):          %.4f\n", params$alpha))
  cat(sprintf("  T (time):                %.4f\n", params$time))
  cat("\n")

  # Trait counts
  meta <- x$metadata
  cat("Simulation Summary:\n")
  cat(sprintf("  Total traits:            %d\n", meta$n_traits))
  cat(sprintf("  Protected (d ≥ θ):       %d (%.1f%%)\n",
              meta$n_protected, 100 * meta$n_protected / meta$n_traits))
  cat(sprintf("  Unprotected (d < θ):     %d (%.1f%%)\n",
              meta$n_unprotected, 100 * meta$n_unprotected / meta$n_traits))
  cat(sprintf("  Integration steps:       %d (dt = %.6f)\n",
              meta$n_steps, meta$dt))
  cat(sprintf("  Method:                  %s\n", meta$method))
  cat(sprintf("  Converged:               %s\n", ifelse(meta$converged, "yes", "no")))
  cat("\n")

  # Results
  vals <- x$values
  cat("Results:\n")
  cat(sprintf("  Phase 1 rate:            %.6f\n", vals$phase1_rate))
  cat(sprintf("  Phase 2 rate:            %.6f\n", vals$phase2_rate))
  cat(sprintf("  Early/late ratio:        %.4f\n", vals$early_late_displacement_ratio))
  cat(sprintf("  Threshold biphasicity:   %.6f\n", vals$threshold_biphasicity))
  cat("\n")

  # Retention overview
  prot_idx <- which(x$metadata$params$theta <= x$values$final_retention)
  unprot_idx <- which(x$metadata$params$theta > x$values$final_retention)

  if (length(unprot_idx) > 0) {
    cat(sprintf("  Unprotected retention:\n"))
    cat(sprintf("    Mean:      %.6f\n", mean(x$values$final_retention[unprot_idx])))
    cat(sprintf("    SD:        %.6f\n", sd(x$values$final_retention[unprot_idx])))
    cat(sprintf("    Range:     [%.6f, %.6f]\n",
                min(x$values$final_retention[unprot_idx]),
                max(x$values$final_retention[unprot_idx])))
  }

  if (length(prot_idx) > 0) {
    cat(sprintf("  Protected retention:\n"))
    cat(sprintf("    Mean:      %.6f\n", mean(x$values$final_retention[prot_idx])))
    cat(sprintf("    Range:     [%.6f, %.6f]\n",
                min(x$values$final_retention[prot_idx]),
                max(x$values$final_retention[prot_idx])))
  }

  invisible(x)
}

#' Summary of the framework_threshold_result Object
#'
#' Returns a tidy data.frame summarizing key metrics. Useful for programmatic
#' access and comparison across multiple simulations.
#'
#' @param object valence_threshold_result object.
#' @param ... Ignored.
#'
#' @return data.frame with columns:
#'   \item{lambda}{shedding rate}
#'   \item{theta}{protection threshold}
#'   \item{m0}{initial mismatch}
#'   \item{alpha}{decay rate}
#'   \item{time}{simulation duration}
#'   \item{n_traits}{total traits}
#'   \item{n_protected}{number protected}
#'   \item{n_unprotected}{number unprotected}
#'   \item{phase1_rate}{rate during first 10%}
#'   \item{phase2_rate}{rate during last 90%}
#'   \item{biphasicity}{threshold gap}
#'   \item{retention_mean}{mean retention overall}
#'   \item{retention_sd}{SD of retention}
#'
#' @export
#' @examples
#' \dontrun{
#' result <- threshold_model(c(0,1,2,3,5), 0.15, 2.5, 10, 0.05, 100)
#' summary(result)
#' }
summary.valence_threshold_result <- function(object, ...) {
  params <- object$metadata$params
  meta <- object$metadata
  vals <- object$values
  ret <- object$values$final_retention

  data.frame(
    lambda = params$lambda,
    theta = params$theta,
    m0 = params$m0,
    alpha = params$alpha,
    time = params$time,
    n_traits = meta$n_traits,
    n_protected = meta$n_protected,
    n_unprotected = meta$n_unprotected,
    phase1_rate = vals$phase1_rate,
    phase2_rate = vals$phase2_rate,
    biphasicity = vals$threshold_biphasicity,
    retention_mean = mean(ret),
    retention_sd = sd(ret),
    row.names = NULL
  )
}

#' Plot valence_threshold_result Object
#'
#' Returns a patchwork ggplot2 composition with:
#' 1. Left: retention trajectory over time (all traits)
#' 2. Right: threshold gate visualization (depth vs retention)
#'
#' @param x valence_threshold_result object.
#' @param ... Ignored.
#'
#' @return patchwork of two ggplot2 objects.
#' @export
#' @examples
#' \dontrun{
#' result <- threshold_model(c(0,1,2,3,5), 0.15, 2.5, 10, 0.05, 100)
#' plot(result)
#' }
plot.valence_threshold_result <- function(x, ...) {
  library(ggplot2)
  library(patchwork)

  params <- x$metadata$params
  meta <- x$metadata
  history <- x$metadata$retention_history
  depths <- seq_len(ncol(history))  # trait indices as proxy for depths

  # Left panel: Trajectory over time
  time_points <- seq(0, params$time, length.out = nrow(history))
  traj_df <- do.call(rbind, lapply(seq_len(ncol(history)), function(i) {
    data.frame(
      time = time_points,
      retention = history[, i],
      trait_id = factor(i),
      protected = (i >= params$theta)
    )
  }))

  p1 <- ggplot(traj_df, aes(x = time, y = retention, color = protected)) +
    geom_line(alpha = 0.6, size = 0.5) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.3) +
    scale_color_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#ff7f0e"),
                       labels = c("Protected", "Unprotected")) +
    labs(title = "Retention Trajectory",
         subtitle = sprintf("λ=%.2f, θ=%.2f, M₀=%.2f, α=%.3f, T=%g",
                           params$lambda, params$theta, params$m0, params$alpha, params$time),
         x = "Time",
         y = "Retention Probability",
         color = "Trait Type") +
    theme_minimal(base_size = 10) +
    theme(legend.position = "right",
          legend.title = element_text(size = 8),
          legend.text = element_text(size = 8))

  # Right panel: Threshold gate (depth vs final retention)
  depth_vals <- 1:nrow(history)
  gate_df <- data.frame(
    depth = depth_vals,
    retention = x$values$final_retention,
    protected = depth_vals >= params$theta
  )

  p2 <- ggplot(gate_df, aes(x = depth, y = retention)) +
    geom_point(aes(color = protected), size = 3) +
    geom_hline(yintercept = params$theta, linetype = "dashed", color = "red", alpha = 0.5) +
    annotate("rect", xmin = Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
             fill = "blue", alpha = 0.05, inherit.aes = FALSE) +
    geom_vline(xintercept = params$theta, linetype = "dashed", color = "red") +
    scale_color_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#ff7f0e"),
                       labels = c("Protected", "Unprotected")) +
    labs(title = "Threshold Gate",
         subtitle = sprintf("Gate at θ=%.2f", params$theta),
         x = "Trait Index (proxy for depth)",
         y = "Final Retention",
         color = "Type") +
    theme_minimal(base_size = 10) +
    theme(legend.position = "right",
          legend.title = element_text(size = 8),
          legend.text = element_text(size = 8))

  # Combine with patchwork
  p1 / p2 + plot_layout(guides = "collect") &
    theme(legend.box = "vertical")
}

#' Convert valence_threshold_result to Data Frame
#'
#' Extracts key results into a tidy data.frame for downstream piping
#' or export to CSV/Excel.
#'
#' @param x valence_threshold_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments passed to as.data.frame().
#'
#' @return data.frame with one row per trait plus summary metrics.
#' @export
#' @examples
#' \dontrun{
#' result <- threshold_model(c(0,1,2,3,5), 0.15, 2.5, 10, 0.05, 100)
#' as.data.frame(result)
#' }
as.data.frame.valence_threshold_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  params <- x$metadata$params
  meta <- x$metadata

  # Create per-trait data
  ret_df <- data.frame(
    trait_index = seq_along(x$values$final_retention),
    depth = seq_along(x$values$final_retention),
    retention = x$values$final_retention,
    is_protected = seq_along(x$values$final_retention) >= params$theta
  )

  # Add parameter columns for easy grouping
  ret_df$lambda <- params$lambda
  ret_df$theta <- params$theta
  ret_df$m0 <- params$m0
  ret_df$alpha <- params$alpha
  ret_df$time <- params$time

  # Append summary row
  summary_row <- data.frame(
    trait_index = NA,
    depth = NA,
    retention = mean(x$values$final_retention),
    is_protected = NA,
    lambda = params$lambda,
    theta = params$theta,
    m0 = params$m0,
    alpha = params$alpha,
    time = params$time,
    stringsAsFactors = FALSE
  )
  summary_row$retention_type <- "mean"

  ret_df$retention_type <- "trait"
  ret_df <- rbind(ret_df, summary_row)

  ret_df
}

# ==============================================================================
# VI_GLM_FIT METHODS
# ==============================================================================

#' Print valence_glm_fit Object
#'
#' Human-readable console output showing GLM coefficients, significance,
#' and cross-kingdom validation results.
#'
#' @param x valence_glm_fit object.
#' @param ... Ignored.
#'
#' @return Invisibly returns x.
#' @export
#' @examples
#' \dontrun{
#' plant <- load_retention_matrix()
#' bird <- load_island_birds()
#' fit <- empirical_formal_model(plant$data, bird$data)
#' print(fit)
#' }
print.valence_glm_fit <- function(x, ...) {
  cat("valence_glm_fit: Valence-Ingression Empirical Test\n")
  cat("=============================================\n\n")

  vals <- x$values
  meta <- x$metadata

  cat("Model Specification:\n")
  cat(sprintf("  Formula: retention ~ dependency_score + parasitism_score\n"))
  cat(sprintf("  Family:  quasibinomial (logit link)\n"))
  cat(sprintf("  Observations: %d (species × gene categories)\n", meta$n))
  cat(sprintf("  Species: %d, Gene categories: %d\n", meta$n_species, meta$n_gene_categories))
  cat("\n")

  cat("Coefficients:\n")
  cat(sprintf("  (Intercept):                 %.4f (p = %.4g)\n",
              vals$intercept, vals$dep_p_value))
  cat(sprintf("  dependency_score:            %.4f (p = %.4g) %s\n",
              vals$dep_coefficient, vals$dep_p_value,
              ifelse(vals$dep_positive, "[framework prediction]", "")))
  cat(sprintf("  parasitism_score:            %.4f (p = %.4g) %s\n",
              vals$para_coefficient, vals$para_p_value,
              ifelse(vals$para_negative, "[framework prediction]", "")))
  cat(sprintf("  Pseudo R² (McFadden):        %.4f\n", vals$pseudo_r_squared))
  cat("\n")

  cat("Cross-Kingdom Validation:\n")
  cat(sprintf("  Parasitism level tested:     %g\n", meta$para_for_transfer))
  cat(sprintf("  Spearman ρ vs bird ranks:    %.4f (p = %.4g)\n",
              vals$cross_kingdom_rho, vals$cross_kingdom_p))
  cat("\n")

  cat("framework Confirmation Status:\n")
  cat(sprintf("  dep > 0:                      %s\n", ifelse(vals$dep_positive, "✓ YES", "✗ NO")))
  cat(sprintf("  para < 0:                     %s\n", ifelse(vals$para_negative, "✓ YES", "✗ NO")))
  cat(sprintf("  ρ > 0:                        %s\n", ifelse(vals$cross_kingdom_rho > 0, "✓ YES", "✗ NO")))
  cat(sprintf("  Overall: %s\n", ifelse(vals$valence_confirmed, "CONFIRMED", "NOT CONFIRMED")))

  invisible(x)
}

#' Summary of the framework_glm_fit Object
#'
#' Returns a tidy data.frame of model diagnostics.
#'
#' @param object valence_glm_fit object.
#' @param ... Ignored.
#'
#' @return data.frame with model metrics.
#' @export
summary.valence_glm_fit <- function(object, ...) {
  vals <- object$values
  meta <- object$metadata

  data.frame(
    metric = c("intercept", "dep_coefficient", "dep_p_value",
               "para_coefficient", "para_p_value", "pseudo_r_squared",
               "cross_kingdom_rho", "cross_kingdom_p",
               "observations", "n_species", "n_gene_categories",
               "valence_confirmed"),
    value = c(vals$intercept, vals$dep_coefficient, vals$dep_p_value,
              vals$para_coefficient, vals$para_p_value, vals$pseudo_r_squared,
              vals$cross_kingdom_rho, vals$cross_kingdom_p,
              meta$n, meta$n_species, meta$n_gene_categories,
              as.numeric(vals$valence_confirmed)),
    stringsAsFactors = FALSE
  )
}

#' Plot valence_glm_fit Object
#'
#' Returns a ggplot2 diagnostic plot showing:
#' - Observed vs fitted retention (with confidence band)
#' - Residuals vs fitted
#' - Coefficient bar chart with significance stars
#'
#' @param x valence_glm_fit object.
#' @param ... Ignored.
#'
#' @return patchwork of diagnostic plots.
#' @export
plot.valence_glm_fit <- function(x, ...) {
  library(ggplot2)
  library(patchwork)

  glm_fit <- x$metadata$glm_fit
  data <- glm_fit$model

  # Get predictions
  pred <- predict(glm_fit, type = "response")
  observed <- data$retention

  # Plot 1: Observed vs Fitted
  p1 <- ggplot(data.frame(observed = observed, fitted = pred),
               aes(x = fitted, y = observed)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
    labs(title = "Observed vs Fitted",
         subtitle = sprintf("R² = %.4f", x$values$pseudo_r_squared),
         x = "Fitted Retention",
         y = "Observed Retention") +
    theme_minimal(base_size = 10)

  # Plot 2: Coefficients
  coef_df <- data.frame(
    term = c("dep_score", "para_score"),
    estimate = c(x$values$dep_coefficient, x$values$para_coefficient),
    p_val = c(x$values$dep_p_value, x$values$para_p_value)
  )
  coef_df$significance <- ifelse(coef_df$p_val < 0.001, "***",
                                 ifelse(coef_df$p_val < 0.01, "**",
                                        ifelse(coef_df$p_val < 0.05, "*", "")))

  p2 <- ggplot(coef_df, aes(x = term, y = estimate)) +
    geom_col(fill = "#1f77b4", alpha = 0.8) +
    geom_errorbar(aes(ymin = estimate - 1.96*sqrt(var(glm_fit$coefficients[2])),
                      ymax = estimate + 1.96*sqrt(var(glm_fit$coefficients[2]))),
                  width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_text(aes(label = significance), vjust = -0.5, size = 5) +
    labs(title = "Coefficient Estimates",
         subtitle = "the framework predicts dep > 0, para < 0",
         x = "Predictor",
         y = "Coefficient Estimate") +
    theme_minimal(base_size = 10) +
    coord_flip()

  p1 / p2 + plot_layout(guides = "collect")
}

#' Convert valence_glm_fit to Data Frame
#'
#' Extracts GLM results into tidy format.
#'
#' @param x valence_glm_fit object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#'
#' @return data.frame with coefficients and diagnostics.
#' @export
as.data.frame.valence_glm_fit <- function(x, row.names = NULL, optional = FALSE, ...) {
  vals <- x$values
  meta <- x$metadata

  data.frame(
    coefficient = c("(Intercept)", "dependency_score", "parasitism_score"),
    estimate = c(vals$intercept, vals$dep_coefficient, vals$para_coefficient),
    p_value = c(NA, vals$dep_p_value, vals$para_p_value),  # intercept p not computed
    valence_prediction = c(NA, "dep > 0", "para < 0"),
    consistent = c(NA, vals$dep_positive, vals$para_negative),
    stringsAsFactors = FALSE
  )
}

# ==============================================================================
# VI_EQUILIBRIUM METHODS
# ==============================================================================

#' Print valence_equilibrium Object
#'
#' Concise output showing equilibrium status for a single trait.
#'
#' @param x valence_equilibrium object.
#' @param ... Ignored.
#'
#' @return Invisibly returns x.
#' @export
print.valence_equilibrium <- function(x, ...) {
  cat(sprintf("valence_equilibrium: depth = %.4f\n", x$depth))
  cat(sprintf("  Protected:       %s\n", ifelse(x$is_protected, "YES", "NO")))
  cat(sprintf("  Equilibrium:     %.6f\n", x$value))
  if (!x$is_protected) {
    cat(sprintf("  Integrated MM:   %.6f\n", x$integrated_mismatch))
  }
  invisible(x)
}

#' Summary of the framework_equilibrium Object
#'
#' @param object valence_equilibrium object.
#' @param ... Ignored.
#'
#' @return data.frame with single row.
#' @export
summary.valence_equilibrium <- function(object, ...) {
  data.frame(
    depth = object$depth,
    is_protected = object$is_protected,
    equilibrium = object$value,
    integrated_mismatch = object$integrated_mismatch,
    stringsAsFactors = FALSE
  )
}

#' Plot valence_equilibrium Object
#'
#' Simple dot plot showing position relative to threshold.
#'
#' @param x valence_equilibrium object.
#' @param ... Ignored.
#'
#' @return ggplot2 object.
#' @export
plot.valence_equilibrium <- function(x, ...) {
  library(ggplot2)

  ggplot() +
    geom_point(aes(x = x$depth, y = x$value),
               color = ifelse(x$is_protected, "blue", "orange"),
               size = 4) +
    geom_vline(xintercept = x$params$theta, linetype = "dashed", color = "red") +
    geom_hline(yintercept = ifelse(x$is_protected, 1, exp(-x$params$lambda * x$integrated_mismatch)),
               linetype = "dotted", color = gray(0.5)) +
    labs(title = "Equilibrium at Depth",
         subtitle = sprintf("θ = %.2f, protected = %s", x$params$theta, x$is_protected),
         x = "Integration Depth",
         y = "Retention Probability") +
    theme_minimal(base_size = 10)
}

#' Convert valence_equilibrium to Data Frame
#'
#' @param x valence_equilibrium object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#'
#' @return data.frame with single row.
#' @export
as.data.frame.valence_equilibrium <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    depth = x$depth,
    is_protected = x$is_protected,
    equilibrium = x$value,
    integrated_mismatch = x$integrated_mismatch,
    lambda = x$params$lambda,
    theta = x$params$theta,
    m0 = x$params$m0,
    alpha = x$params$alpha,
    time = x$params$time,
    stringsAsFactors = FALSE
  )
}
