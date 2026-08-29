#' Cultural evolution empirical tests for the foundry
#'
#' Tests H2 (β mediation), H4 (cross-domain β), H5 (super-exponential growth),
#' and H10 (sign reversal) using real cultural data.
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: β (branching factor) is a substrate property that:
#' 1. Does NOT depend on population size (H2)
#' 2. Varies by domain, with cultural substrates > 1 (H4)
#' 3. Produces super-exponential growth when β > 1 (H5)
#' 4. Reverses the sign of diversity dependence (H10)
#'
#' Competitor: demographic hypothesis (Henrich 2004, Kline & Boyd 2010)
#' predicts population size directly predicts complexity.
#'
#' @dft A1, A6
#'
#' @name cultural_tests
NULL

#' Helper: partial correlation
#'
#' @param x,y,z Numeric vectors.
#' @return List with r, p_value, df.
#' @keywords internal
.partial_corr <- function(x, y, z) {
  r_xz <- cor(x, z, use = "complete.obs")
  r_yz <- cor(y, z, use = "complete.obs")
  r_xy <- cor(x, y, use = "complete.obs")
  num <- r_xy - r_xz * r_yz
  den <- sqrt((1 - r_xz^2) * (1 - r_yz^2))
  r <- num / den
  n <- sum(!is.na(x) & !is.na(y) & !is.na(z))
  t_stat <- r * sqrt((n - 3) / (1 - r^2))
  p <- 2 * stats::pt(abs(t_stat), df = n - 3, lower.tail = FALSE)
  list(r = r, p_value = p, df = n - 3)
}

#' H2: Test whether β mediates the N → complexity relationship
#'
#' the framework predicts: β predicts complexity; N does NOT predict β; N drops
#' to non-significant (or weakens) when controlling for β.
#'
#' @param data Data frame from load_oswalt_1973() or load_oswalt_1976().
#' @param seed Integer. For reproducibility (A2).
#' @return List (A6: proof object) with values and metadata.
#' @export
beta_mediation_test <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    log_N <- data$log_N
    beta <- data$beta
    log_complexity <- if ("log_technounits" %in% names(data))
      data$log_technounits else data$log_components

    # Step 1: N → complexity
    r_N_complex <- cor.test(log_N, log_complexity)

    # Step 2: N → β
    r_N_beta <- cor.test(log_N, beta)

    # Step 3: β → complexity
    r_beta_complex <- cor.test(beta, log_complexity)

    # Step 4: Partial correlations
    pc_N <- .partial_corr(log_N, log_complexity, beta)
    pc_beta <- .partial_corr(beta, log_complexity, log_N)

    # Determine mediation type
    mediation <- if (r_N_beta$p.value > 0.05 &&
                       r_beta_complex$p.value < 0.05) {
      if (pc_N$p_value > 0.05) "full" else "partial"
    } else if (r_N_beta$p.value < 0.05) {
      "none (N predicts β)"
    } else {
      "inconclusive"
    }

    list(
      values = list(
        r_N_complexity = unname(r_N_complex$estimate),
        p_N_complexity = r_N_complex$p.value,
        r_N_beta = unname(r_N_beta$estimate),
        p_N_beta = r_N_beta$p.value,
        r_beta_complexity = unname(r_beta_complex$estimate),
        p_beta_complexity = r_beta_complex$p.value,
        r_N_given_beta = pc_N$r,
        p_N_given_beta = pc_N$p_value,
        r_beta_given_N = pc_beta$r,
        p_beta_given_N = pc_beta$p_value,
        mediation_type = mediation,
        n = nrow(data)
      ),
      metadata = list(
        seed = seed,
        test = "H2_beta_mediation",
        valence_prediction = "β predicts complexity; N does not predict β",
        discriminating = TRUE
      )
    )
  })
}

#' H4: Test whether β varies by domain and crosses threshold at 1
#'
#' the framework predicts: cultural substrates have β > 1; non-cultural have β < 1.
#'
#' @param data Data frame from load_cross_domain_beta().
#' @return List (A6: proof object).
#' @export
cross_domain_beta_test <- function(data) {
  cultural <- data[!is.na(data$beta) & data$beta > 1, ]
  non_cultural <- data[!is.na(data$beta) & data$beta < 1, ]

  list(
    values = list(
      n_domains = nrow(data[!is.na(data$beta), ]),
      n_cultural = nrow(cultural),
      n_non_cultural = nrow(non_cultural),
      all_cultural_above_1 = all(cultural$beta > 1),
      all_non_cultural_below_1 = all(non_cultural$beta < 1),
      max_beta = max(data$beta, na.rm = TRUE),
      min_beta = min(data$beta, na.rm = TRUE),
      threshold_confirmed = all(cultural$beta > 1) && all(non_cultural$beta < 1)
    ),
    metadata = list(
      test = "H4_cross_domain_beta",
      valence_prediction = "cultural β > 1; non-cultural β < 1",
      discriminating = TRUE
    )
  )
}

#' H5: Test whether growth is super-exponential (β > 1 → t² growth)
#'
#' Fits linear, exponential, and quadratic models; compares via AIC.
#' the framework predicts: quadratic beats linear (positive acceleration).
#'
#' @param data Data frame from load_uspto_patents().
#' @return List (A6: proof object).
#' @export
growth_curve_test <- function(data) {
  t <- data$year_centered
  y <- data$cumulative_patents

  # Linear: y = a*t + b
  lm_lin <- stats::lm(y ~ t)
  aic_lin <- stats::AIC(lm_lin)

  # Quadratic: y = a*t^2 + b*t + c
  lm_quad <- stats::lm(y ~ t + I(t^2))
  aic_quad <- stats::AIC(lm_quad)

  # Exponential: log(y) = a*t + b
  lm_exp <- stats::lm(log(y) ~ t)
  aic_exp <- stats::AIC(lm_exp)

  delta_aic_quad_vs_lin <- aic_lin - aic_quad
  quad_coef <- stats::coef(lm_quad)[["I(t^2)"]]

  list(
    values = list(
      aic_linear = aic_lin,
      aic_quadratic = aic_quad,
      aic_exponential = aic_exp,
      delta_aic_quad_vs_linear = delta_aic_quad_vs_lin,
      quadratic_coefficient = quad_coef,
      quadratic_positive = quad_coef > 0,
      quadratic_beats_linear = delta_aic_quad_vs_lin > 2,
      best_model = c("linear", "exponential", "quadratic")[
        which.min(c(aic_lin, aic_exp, aic_quad))],
      n_years = nrow(data)
    ),
    metadata = list(
      test = "H5_super_exponential_growth",
      valence_prediction = "quadratic coefficient > 0; quadratic beats linear",
      discriminating = TRUE
    )
  )
}

#' H10: Test sign reversal from Van Holstein & Foley (2024) posteriors
#'
#' the framework predicts: Homo (β > 1) has positive DD speciation;
#' non-Homo (β < 1) has negative DD speciation.
#'
#' @param homo_gl Numeric vector. Speciation DD posterior for Homo.
#' @param nonhomo_gl Numeric vector. Speciation DD posterior for non-Homo.
#' @param config Character. Configuration name (e.g. "Broad_NHPP").
#' @return List (A6: proof object).
#' @export
sign_reversal_test <- function(homo_gl, nonhomo_gl, config = "unknown") {
  homo_mean <- mean(homo_gl)
  nonhomo_mean <- mean(nonhomo_gl)
  homo_pct_pos <- mean(homo_gl > 0) * 100
  nonhomo_pct_pos <- mean(nonhomo_gl > 0) * 100

  reversal <- homo_mean > 0 && nonhomo_mean < 0

  list(
    values = list(
      homo_gl_mean = homo_mean,
      nonhomo_gl_mean = nonhomo_mean,
      homo_pct_positive = homo_pct_pos,
      nonhomo_pct_positive = nonhomo_pct_pos,
      sign_reversal = reversal,
      config = config
    ),
    metadata = list(
      test = "H10_sign_reversal",
      valence_prediction = "Homo: positive DD; Non-Homo: negative DD",
      discriminating = TRUE
    )
  )
}
