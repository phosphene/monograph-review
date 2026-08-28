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
#' The two-timescale fit is notoriously ill-conditioned: the fast channel
#' decays within the first few sampling intervals, so naive starting values
#' routinely fail to converge or collapse both channels onto the slow rate.
#' Three defences are layered here:
#'
#' \enumerate{
#'   \item \strong{Exponential peeling} produces data-derived starting
#'     values. The slow phase \eqn{(c_0, A_2, k_2)} is estimated by a
#'     log-linear regression on the tail (where the fast channel is dead),
#'     then the fast channel \eqn{(A_1, k_1)} is estimated from the early
#'     residual. This puts the optimizer in the correct basin on any time
#'     scale, including after \eqn{t}-normalisation.
#'   \item \strong{Log-rate reparameterisation}: the fit is performed on
#'     \eqn{(\log k_1, \log k_2)} so rates are structurally positive and the
#'     Jacobian never degenerates from negative-rate drift. Coefficients are
#'     reported on the natural scale.
#'   \item \strong{Convention fix}: after fitting, the channels are labelled
#'     so that \eqn{k_1 \ge k_2} (fast/slow hierarchy) regardless of which
#'     basin the optimizer found.
#' }
#'
#' \code{nlsLM} (Levenberg-Marquardt from \code{minpack.lm}) is used when
#' available; otherwise \code{stats::nls} with the log-rate
#' parameterisation, which is far more robust than fitting raw rates.
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
  # Log-rate parameterisation: logk is free, k = exp(logk) is positive.
  mono_fit <- NULL
  mono_rss <- Inf
  mono_aic <- Inf
  mono_coef <- list(c0 = NA_real_, A = NA_real_, k = NA_real_)
  mono_converged <- FALSE

  rho_range <- max(rho_s, na.rm = TRUE) - min(rho_s, na.rm = TRUE)
  c0_guess <- min(rho_s, na.rm = TRUE)
  A_guess <- rho_range
  k_guess <- 1.0

  mono_start <- list(c0 = c0_guess, A = A_guess, logk = log(k_guess))

  if (requireNamespace("minpack.lm", quietly = TRUE)) {
    mono_fit <- tryCatch({
      minpack.lm::nlsLM(rho_s ~ c0 + A * exp(-exp(logk) * t_s),
                        start = mono_start,
                        control = minpack.lm::nls.lm.control(
                          maxiter = 500, ftol = 1e-8, ptol = 1e-8))
    }, error = function(e) NULL)
  } else {
    mono_fit <- tryCatch({
      stats::nls(rho_s ~ c0 + A * exp(-exp(logk) * t_s),
                 start = mono_start,
                 control = stats::nls.control(
                   maxiter = 500, minFactor = 1e-8))
    }, error = function(e) NULL)
  }

  if (!is.null(mono_fit)) {
    raw_coef <- stats::coef(mono_fit)
    mono_rss <- sum(stats::residuals(mono_fit)^2)
    mono_aic <- aic_val(mono_rss, 4, n)
    mono_coef <- list(c0 = unname(raw_coef[["c0"]]),
                      A = unname(raw_coef[["A"]]),
                      k = unname(exp(raw_coef[["logk"]])))
    mono_converged <- TRUE
  }

  # --- Bi-exponential: rho = c0 + A1 * exp(-k1 * t) + A2 * exp(-k2 * t) ---
  bi_fit <- NULL
  bi_rss <- Inf
  bi_aic <- Inf
  bi_coef <- list(c0 = NA_real_, A1 = NA_real_, k1 = NA_real_,
                  A2 = NA_real_, k2 = NA_real_)
  bi_converged <- FALSE

  # --- Data-derived start via exponential peeling (see Fitting Strategy) ---
  peel <- .peel_biexp_starts(t_s, rho_s)

  # Grid of fallback starts. Pattern: k1 is fast (large), k2 is slow (small).
  grid <- list(
    list(c0 = c0_guess, A1 = rho_range * 0.7, k1 = 2, A2 = rho_range * 0.3, k2 = 0.05),
    list(c0 = c0_guess, A1 = rho_range * 0.8, k1 = 5, A2 = rho_range * 0.2, k2 = 0.1),
    list(c0 = c0_guess, A1 = rho_range * 0.6, k1 = 10, A2 = rho_range * 0.4, k2 = 0.5),
    list(c0 = c0_guess, A1 = rho_range * 0.5, k1 = 1, A2 = rho_range * 0.5, k2 = 0.01),
    list(c0 = c0_guess, A1 = rho_range * 0.9, k1 = 20, A2 = rho_range * 0.1, k2 = 1),
    list(c0 = c0_guess, A1 = rho_range * 0.75, k1 = 3, A2 = rho_range * 0.25, k2 = 0.02)
  )
  starts <- c(list(peel), grid)

  for (st in starts) {
    fit <- NULL
    nls_start <- list(
      c0 = st$c0,
      A1 = st$A1,
      logk1 = log(max(st$k1, 1e-9)),
      A2 = st$A2,
      logk2 = log(max(st$k2, 1e-9))
    )
    if (requireNamespace("minpack.lm", quietly = TRUE)) {
      fit <- tryCatch({
        minpack.lm::nlsLM(
          rho_s ~ c0 + A1 * exp(-exp(logk1) * t_s) + A2 * exp(-exp(logk2) * t_s),
          start = nls_start,
          control = minpack.lm::nls.lm.control(
            maxiter = 500, ftol = 1e-8, ptol = 1e-8))
      }, error = function(e) NULL)
    } else {
      fit <- tryCatch({
        stats::nls(
          rho_s ~ c0 + A1 * exp(-exp(logk1) * t_s) + A2 * exp(-exp(logk2) * t_s),
          start = nls_start,
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
    raw_coef <- stats::coef(bi_fit)
    bi_aic <- aic_val(bi_rss, 6, n)
    bi_coef <- list(
      c0 = unname(raw_coef[["c0"]]),
      A1 = unname(raw_coef[["A1"]]),
      k1 = unname(exp(raw_coef[["logk1"]])),
      A2 = unname(raw_coef[["A2"]]),
      k2 = unname(exp(raw_coef[["logk2"]]))
    )
    # Fast/slow convention: k1 >= k2 (swap channels if the optimizer
    # converged to the mirror-image basin).
    if (bi_coef$k1 < bi_coef$k2) {
      tmp_k <- bi_coef$k1; tmp_A <- bi_coef$A1
      bi_coef$k1 <- bi_coef$k2; bi_coef$A1 <- bi_coef$A2
      bi_coef$k2 <- tmp_k; bi_coef$A2 <- tmp_A
    }
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

#' Exponential peeling starting values for bi-exponential fitting
#'
#' Estimates \eqn{(c_0, A_2, k_2)} from the tail of the decay (where the
#' fast channel has fully decayed) via log-linear regression, then estimates
#' \eqn{(A_1, k_1)} from the early residual after removing the slow channel.
#'
#' Pure function of the (already ordered, already scaled) data — DFT A1/A2.
#'
#' @param t_s Numeric vector. Ordered, scaled time points (first is the
#'   minimum).
#' @param rho_s Numeric vector. Response ordered with \code{t_s}.
#' @return List with components \code{c0}, \code{A1}, \code{k1}, \code{A2},
#'   \code{k2} on the fit scale.
#' @keywords internal
.peel_biexp_starts <- function(t_s, rho_s) {
  n <- length(t_s)
  c0 <- min(rho_s)
  y <- pmax(rho_s - c0, 1e-12)

  # Noise estimate from the plateau (last 20% of points)
  plateau <- max(floor(n * 0.8), 1):n
  noise_hat <- stats::sd(rho_s[plateau])
  if (is.na(noise_hat) || noise_hat == 0) noise_hat <- 1e-9
  thr <- max(3 * noise_hat, 1e-9)

  # Slow channel: tail points above the noise floor, t_s >= 0.15
  k2 <- 0.5
  A2 <- 0.3 * max(y)
  tail_idx <- which(y > thr & t_s >= 0.15)
  if (length(tail_idx) >= 5) {
    tail_fit <- tryCatch(
      stats::lm(log(y[tail_idx]) ~ t_s[tail_idx]),
      error = function(e) NULL)
    if (!is.null(tail_fit)) {
      slope <- stats::coef(tail_fit)[[2]]
      intercept <- stats::coef(tail_fit)[[1]]
      k2_hat <- -unname(slope)
      A2_hat <- exp(unname(intercept))
      if (is.finite(k2_hat) && k2_hat > 0 &&
          is.finite(A2_hat) && A2_hat > 0) {
        k2 <- k2_hat
        A2 <- min(A2_hat, max(y) * 1.5)
      }
    }
  }

  # Fast channel: early residual after removing the slow channel
  res <- y - A2 * exp(-k2 * t_s)
  k1 <- k2 * 10
  A1 <- max(max(res), max(y) * 0.5)
  early_idx <- which(t_s <= 0.25)
  pos <- early_idx[res[early_idx] > thr]
  if (length(pos) >= 2) {
    res_fit <- tryCatch(
      stats::lm(log(res[pos]) ~ t_s[pos]),
      error = function(e) NULL)
    if (!is.null(res_fit)) {
      slope <- stats::coef(res_fit)[[2]]
      intercept <- stats::coef(res_fit)[[1]]
      k1_hat <- -unname(slope)
      A1_hat <- exp(unname(intercept))
      if (is.finite(k1_hat) && k1_hat > k2 &&
          is.finite(A1_hat) && A1_hat > 0) {
        k1 <- k1_hat
        A1 <- min(A1_hat, max(y) * 1.5)
      }
    }
  } else if (length(pos) == 1 && n > 1) {
    # Two-point estimate: t_s[1] == 0, so rho_s[1] - c0 == res at t = 0
    r0 <- res[1]
    p1 <- pos[1]
    if (r0 > thr && res[p1] > 0 && (t_s[p1] - t_s[1]) > 0) {
      k1_hat <- -log(res[p1] / r0) / (t_s[p1] - t_s[1])
      if (is.finite(k1_hat) && k1_hat > k2) {
        k1 <- k1_hat
        A1 <- r0
      }
    }
  }

  list(c0 = c0, A1 = A1, k1 = k1, A2 = A2, k2 = k2)
}