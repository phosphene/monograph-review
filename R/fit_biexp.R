#' Fit a bi-exponential relaxation function to (t, rho) data
#'
#' Fits the bi-exponential model:
#' \deqn{\rho(t) = c_0 + A_1 e^{-k_1 t} + A_2 e^{-k_2 t}}
#' and compares it against the mono-exponential baseline:
#' \deqn{\rho(t) = c_0 + A e^{-k t}}
#' and a linear null model on AIC.
#'
#' This is the relaxation-formula fitter, complementing the step-function
#' fitter in \code{fit_step.R}. The bi-exponential model captures the
#' two-timescale relaxation dynamics predicted by the valence relaxation formula
#' \eqn{d\rho/dt = -k_1(\rho - \rho_1) - k_2(\rho - \rho_2)}.
#'
#' The step-function fitter (\code{fit_step.R}) is preserved for
#' reproducibility — the relaxation formula is the successor, not a
#' replacement. Both fitters are valid for different data regimes:
#' the step function for (theta, rho) cross-sectional data, the
#' bi-exponential for (t, rho) time-series data.
#'
#' @section Fitting Strategy:
#'
#' Uses \code{nlsLM} (Levenberg-Marquardt from \code{minpack.lm}) if
#' available, which is more robust than \code{nls} for exponential models.
#' Falls back to \code{nls} with multiple starting-value attempts.
#'
#' @param t Numeric vector. Time points.
#' @param rho Numeric vector. Retention correlation or response variable.
#' @param normalize_t Logical. If \code{TRUE} (default), normalise t to
#'   [0, 1] before fitting. This improves numerical stability.
#'
#' @return List with elements:
#'   \describe{
#'     \item{biexponential}{List: \code{coefficients} (c0, A1, k1, A2, k2),
#'       \code{fit} (nls object or NULL), \code{rss}, \code{aic},
#'       \code{converged} (logical)}
#'     \item{monoexponential}{List: \code{coefficients} (c0, A, k),
#'       \code{fit}, \code{rss}, \code{aic}, \code{converged}}
#'     \item{linear}{List: \code{coefficients} (intercept, slope),
#'       \code{fit}, \code{rss}, \code{aic}}
#'     \item{best_model}{Character: \code{"biexponential"},
#'       \code{"monoexponential"}, or \code{"linear"}}
#'     \item{delta_aic_bi_mono}{Numeric: mono AIC minus bi AIC
#'       (positive = bi wins)}
#'     \item{delta_aic_bi_linear}{Numeric: linear AIC minus bi AIC
#'       (positive = bi wins)}
#'     \item{metadata}{List: n, normalised, k1_k2_ratio, k1_halflife,
#'       k2_halflife, A1_frac, A2_frac}
#'   }
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure function, no I/O
#' - A2 (determinism): deterministic given inputs
#' - A6 (check-result): returns structured list with model diagnostics
#'
#' @export
#' @examples
#' \dontrun{
#' t <- seq(0, 10, length.out = 40)
#' rho <- 0.05 + 0.03 * exp(-17.7 * t) + 0.01 * exp(-0.47 * t) + rnorm(40, 0, 0.002)
#' fit_biexp(t, rho)
#' }
fit_biexp <- function(t, rho, normalize_t = TRUE) {
  n <- length(t)
  if (n < 6) {
    stop("need at least 6 data points for bi-exponential model fitting",
         call. = FALSE)
  }

  # Normalise time to [0, 1] for numerical stability
  t_scale <- if (normalize_t) {
    t_range <- max(t, na.rm = TRUE) - min(t, na.rm = TRUE)
    if (t_range == 0) t_range <- 1
    (t - min(t, na.rm = TRUE)) / t_range
  } else {
    t
  }

  ord <- order(t_scale)
  t_s <- t_scale[ord]
  rho_s <- rho[ord]

  # --- Helper: approximate AIC ---
  aic_val <- function(rss, k, n) {
    if (rss <= 0 || is.infinite(rss) || is.na(rss)) return(Inf)
    n * log(rss / n) + 2 * k
  }

  # --- Linear model (null) ---
  lm_fit <- stats::lm(rho_s ~ t_s)
  lm_rss <- sum(stats::residuals(lm_fit)^2)
  lm_aic <- aic_val(lm_rss, 3, n)

  # --- Mono-exponential: rho = c0 + A * exp(-k * t) ---
  mono_fit <- NULL
  mono_rss <- Inf
  mono_aic <- Inf
  mono_coef <- list(c0 = NA_real_, A = NA_real_, k = NA_real_)
  mono_converged <- FALSE

  # Try nlsLM if available, else nls
  rho_range <- max(rho_s, na.rm = TRUE) - min(rho_s, na.rm = TRUE)
  c0_guess <- min(rho_s, na.rm = TRUE)
  A_guess <- rho_range
  k_guess <- 1.0

  mono_start <- list(c0 = c0_guess, A = A_guess, k = k_guess)

  if (requireNamespace("minpack.lm", quietly = TRUE)) {
    mono_fit <- tryCatch({
      minpack.lm::nlsLM(rho_s ~ c0 + A * exp(-k * t_s),
                        start = mono_start,
                        control = minpack.lm::nls.lm.control(
                          maxiter = 200, ftol = 1e-8, ptol = 1e-8))
    }, error = function(e) NULL)
  } else {
    mono_fit <- tryCatch({
      stats::nls(rho_s ~ c0 + A * exp(-k * t_s),
                 start = mono_start,
                 control = stats::nls.control(
                   maxiter = 200, minFactor = 1e-6))
    }, error = function(e) NULL)
  }

  if (!is.null(mono_fit)) {
    mono_rss <- sum(stats::residuals(mono_fit)^2)
    mono_aic <- aic_val(mono_rss, 4, n)
    mono_coef <- as.list(stats::coef(mono_fit))
    mono_converged <- TRUE
  }

  # --- Bi-exponential: rho = c0 + A1 * exp(-k1 * t) + A2 * exp(-k2 * t) ---
  bi_fit <- NULL
  bi_rss <- Inf
  bi_aic <- Inf
  bi_coef <- list(c0 = NA_real_, A1 = NA_real_, k1 = NA_real_,
                  A2 = NA_real_, k2 = NA_real_)
  bi_converged <- FALSE

  # Multiple starting-value attempts
  # Pattern: k1 is fast (large), k2 is slow (small)
  starts <- list(
    list(c0 = c0_guess, A1 = rho_range * 0.7, k1 = 2, A2 = rho_range * 0.3, k2 = 0.05),
    list(c0 = c0_guess, A1 = rho_range * 0.8, k1 = 5, A2 = rho_range * 0.2, k2 = 0.1),
    list(c0 = c0_guess, A1 = rho_range * 0.6, k1 = 10, A2 = rho_range * 0.4, k2 = 0.5),
    list(c0 = c0_guess, A1 = rho_range * 0.5, k1 = 1, A2 = rho_range * 0.5, k2 = 0.01),
    list(c0 = c0_guess, A1 = rho_range * 0.9, k1 = 20, A2 = rho_range * 0.1, k2 = 1),
    list(c0 = c0_guess, A1 = rho_range * 0.75, k1 = 3, A2 = rho_range * 0.25, k2 = 0.02)
  )

  for (st in starts) {
    fit <- NULL
    if (requireNamespace("minpack.lm", quietly = TRUE)) {
      fit <- tryCatch({
        minpack.lm::nlsLM(rho_s ~ c0 + A1 * exp(-k1 * t_s) + A2 * exp(-k2 * t_s),
                          start = st,
                          control = minpack.lm::nls.lm.control(
                            maxiter = 500, ftol = 1e-8, ptol = 1e-8))
      }, error = function(e) NULL)
    } else {
      fit <- tryCatch({
        stats::nls(rho_s ~ c0 + A1 * exp(-k1 * t_s) + A2 * exp(-k2 * t_s),
                   start = st,
                   control = stats::nls.control(
                     maxiter = 500, minFactor = 1e-8))
      }, error = function(e) NULL)
    }

    if (!is.null(fit)) {
      rss <- sum(stats::residuals(fit)^2)
      if (rss < bi_rss) {
        bi_rss <- rss
        bi_fit <- fit
      }
    }
  }

  if (!is.null(bi_fit)) {
    bi_aic <- aic_val(bi_rss, 6, n)
    bi_coef <- as.list(stats::coef(bi_fit))
    bi_converged <- TRUE
  }

  # --- Determine best model ---
  aics <- c(biexponential = bi_aic, monoexponential = mono_aic, linear = lm_aic)
  # Filter out non-finite AICs
  aics <- aics[is.finite(aics)]
  best_model <- if (length(aics) > 0) names(which.min(aics)) else "none"

  # --- Compute metadata ---
  delta_bi_mono <- if (is.finite(mono_aic) && is.finite(bi_aic)) {
    mono_aic - bi_aic
  } else {
    NA_real_
  }
  delta_bi_linear <- if (is.finite(lm_aic) && is.finite(bi_aic)) {
    lm_aic - bi_aic
  } else {
    NA_real_
  }

  # Halflife and amplitude fraction from bi-exponential coefficients
  k1 <- abs(bi_coef$k1)
  k2 <- abs(bi_coef$k2)
  k1_k2_ratio <- if (is.finite(k1) && is.finite(k2) && k2 > 0) {
    k1 / k2
  } else {
    NA_real_
  }
  k1_halflife <- if (is.finite(k1) && k1 > 0) {
    log(2) / k1 * (max(t) - min(t))
  } else {
    NA_real_
  }
  k2_halflife <- if (is.finite(k2) && k2 > 0) {
    log(2) / k2 * (max(t) - min(t))
  } else {
    NA_real_
  }
  A1 <- abs(bi_coef$A1)
  A2 <- abs(bi_coef$A2)
  A_total <- A1 + A2
  A1_frac <- if (is.finite(A_total) && A_total > 0) A1 / A_total else NA_real_
  A2_frac <- if (is.finite(A_total) && A_total > 0) A2 / A_total else NA_real_

  list(
    biexponential = list(
      coefficients = bi_coef,
      fit = bi_fit,
      rss = bi_rss,
      aic = bi_aic,
      converged = bi_converged
    ),
    monoexponential = list(
      coefficients = mono_coef,
      fit = mono_fit,
      rss = mono_rss,
      aic = mono_aic,
      converged = mono_converged
    ),
    linear = list(
      coefficients = list(intercept = stats::coef(lm_fit)[[1]],
                          slope = stats::coef(lm_fit)[[2]]),
      fit = lm_fit,
      rss = lm_rss,
      aic = lm_aic
    ),
    best_model = best_model,
    delta_aic_bi_mono = delta_bi_mono,
    delta_aic_bi_linear = delta_bi_linear,
    metadata = list(
      n = n,
      normalised = normalize_t,
      k1_k2_ratio = k1_k2_ratio,
      k1_halflife = k1_halflife,
      k2_halflife = k2_halflife,
      A1_frac = A1_frac,
      A2_frac = A2_frac
    )
  )
}