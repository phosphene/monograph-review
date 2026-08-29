#' Fit a Heaviside step function to (theta, rho) data
#'
#' Searches for the breakpoint θ* that minimizes residual sum of squares
#' between a two-level step function and the data. Estimates ρ_sat as the
#' mean of post-breakpoint values. Compares the step model against the best
#' sigmoid (logistic function) on AIC.
#'
#' This is the core fitter for the original the framework formula ρ(θ) = ρ_sat · H(θ − θ*).
#' The successor relaxation formula — dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) —
#' is implemented in `fit_biexp.R` (bi-exponential time-series fitter) and
#' `relaxation_model.R` (ODE simulation). Both fitters are preserved:
#' the step function for cross-sectional (theta, rho) data, the bi-exponential
#' for temporal (t, rho) data.
#'
#' It is extracted from `test-simulacrum-step-recovery.R` to satisfy the
#' separation-of-concerns requirement (design-spec.md): Layer 2 fitters
#' live in `R/`, Layer 3 tests live in `tests/testthat/`.
#'
#' @param theta Numeric vector. Provision depth (θ).
#' @param rho Numeric vector. Retention correlation (ρ).
#'
#' @return List with elements:
#'   \describe{
#'     \item{step}{List: theta_star, rho_sat, rss, aic}
#'     \item{sigmoid}{List: k, x0, rho_sat, rss, aic}
#'     \item{best_model}{Character: "step" or "sigmoid"}
#'     \item{delta_aic}{Numeric: sigmoid AIC minus step AIC (positive = step wins)}
#'   }
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure function, no I/O
#' - A2 (determinism): deterministic given inputs
#' - A6 (check-result): returns structured list with model diagnostics
#'
#' @export
#' @examples
#' theta <- seq(-1, 1, length.out = 20)
#' rho <- ifelse(theta < 0, 0.05, 0.35) + rnorm(20, 0, 0.01)
#' fit_step(theta, rho)
fit_step <- function(theta, rho) {
  n <- length(theta)
  ord <- order(theta)
  theta_s <- theta[ord]
  rho_s <- rho[ord]

  # --- Step model: search breakpoint ---
  best_rss <- Inf
  best_bp <- 0
  best_post <- 0
  best_pre <- 0

  for (bp in theta_s) {
    post <- rho_s[theta_s >= bp]
    pre <- rho_s[theta_s < bp]
    post_mean <- if (length(post) > 0) mean(post) else 0
    pre_mean <- if (length(pre) > 0) mean(pre) else 0
    pred <- ifelse(theta_s < bp, pre_mean, post_mean)
    rss <- sum((rho_s - pred)^2)
    if (rss < best_rss) {
      best_rss <- rss
      best_bp <- bp
      best_post <- post_mean
      best_pre <- pre_mean
    }
  }

  # Also test bp = 0 explicitly (formula prediction: θ* = 0)
  rho_post0 <- mean(rho_s[theta_s >= 0])
  rho_pre0 <- mean(rho_s[theta_s < 0])
  pred_0 <- ifelse(theta_s < 0, rho_pre0, rho_post0)
  rss_0 <- sum((rho_s - pred_0)^2)
  if (rss_0 <= best_rss * 1.1) {
    best_bp <- 0
    best_rss <- rss_0
    best_pre <- rho_pre0
    best_post <- rho_post0
  }

  k_step <- 2
  aic_step <- n * log(best_rss / n) + 2 * k_step

  # --- Sigmoid model: ρ = ρ_sat / (1 + exp(-k(θ - x0))) ---
  rho_sat_est <- max(rho_s, na.rm = TRUE)
  best_sig_rss <- Inf
  best_sig_k <- 1
  best_sig_x0 <- 0
  for (k in c(0.5, 1, 2, 5, 10, 20, 50, 100)) {
    for (x0 in seq(min(theta_s), max(theta_s), length.out = 50)) {
      pred <- rho_sat_est / (1 + exp(-k * (theta_s - x0)))
      rss <- sum((rho_s - pred)^2)
      if (rss < best_sig_rss) {
        best_sig_rss <- rss
        best_sig_k <- k
        best_sig_x0 <- x0
      }
    }
  }
  k_sig <- 3
  aic_sig <- n * log(best_sig_rss / n) + 2 * k_sig

  list(
    step = list(theta_star = best_bp, rho_sat = best_post, rss = best_rss, aic = aic_step),
    sigmoid = list(k = best_sig_k, x0 = best_sig_x0, rho_sat = rho_sat_est, rss = best_sig_rss, aic = aic_sig),
    best_model = if (aic_step < aic_sig) "step" else "sigmoid",
    delta_aic = aic_sig - aic_step
  )
}
