#' Adiabatic Elimination for Haken Single-Direction Slaving
#' 
#' Simplified implementation per Haken (Synergetics §3.4).
#' Uses polynomial manifold fitting for stable regimes.
#' 
#' @param xy_data Data.frame with columns: t, x, y (time series)
#' @param eps Timescale separation ε = τ₁/τ₂ (default: auto-estimate)
#' @param verbose Logical. Print debug info (default: FALSE)
#' 
#' @return List with elements:
#'   \item{x_slaved}{Numeric. Estimated fast variable decay onto slow manifold}
#'   \item{y_effective}{Numeric. Effective slow variable dynamics}
#'   \item{epsilon_ratio}{Numeric. Estimated timescale separation}
#'   \item{manifold_drift}{Numeric. Max drift between true and slaved x}
#'   \item$converged}{Logical. Whether elimination converged successfully}
#'   \item{condition_number}{Numeric. Peak Jacobian condition number}
#' 
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure function, no I/O
#' - A2 (determinism): deterministic given inputs
#' - A6 (check-result): returns structured object with diagnostics
#' 
#' @export
haken_adiabatic_elimination <- function(xy_data, eps = NULL, verbose = FALSE) {
  if (!all(c("t", "x", "y") %in% names(xy_data))) {
    stop("xy_data must contain columns: t, x, y", call. = FALSE)
  }
  
  n <- nrow(xy_data)
  if (n < 20) {
    stop("Need at least 20 data points for adiabatic elimination", call. = FALSE)
  }
  
  # Auto-estimate epsilon if not provided
  if (is.null(eps)) {
    eps <- estimate_epsilon(xy_data$x, xy_data$t)
  }
  
  # Safety check
  eps_safe <- pmax(pmin(eps, 0.99), 0.0001)
  
  if (verbose) {
    cat(sprintf("Processing: n=%d, eps=%.4f\n", n, eps_safe))
  }
  
  # Extract variables
  t <- xy_data$t
  x_observed <- xy_data$x
  y_observed <- xy_data$y
  
  # === POLYNOMIAL MANIFOLD FITTING ===
  # Fit linear manifold: x ≈ c0 + c1*y (simple but robust)
  tryCatch({
    lm_fit <- lm(x ~ y, data = xy_data)
    c0 <- coef(lm_fit)[1]
    c1 <- coef(lm_fit)[2]
    
    # Predict slaved x values
    x_slaved <- predict(lm_fit, newdata = xy_data)
  }, error = function(e) {
    # Fallback: constant manifold
    x_slaved <- rep(mean(x_observed, na.rm = TRUE), n)
  })
  
  # Compute manifold drift
  manifold_drift <- max(abs(x_observed - x_slaved), na.rm = TRUE)
  
  # Condition number estimation
  cond_num <- compute_jacobian_condition_number(t, x_slaved, y_observed, eps_safe)
  
  # Convergence criterion
  signal_scale <- sd(x_observed, na.rm = TRUE)
  if (signal_scale < 1e-10) signal_scale <- max(abs(x_observed), na.rm = TRUE)
  
  convergence_threshold <- min(0.5, 0.25 * signal_scale)
  converged <- manifold_drift < convergence_threshold || cond_num < 1e6
  
  list(
    x_slaved = x_slaved,
    y_effective = y_observed,
    epsilon_ratio = eps_safe,
    k1_recovery_correlation = NA,
    k2_recovery_correlation = NA,
    manifold_drift = manifold_drift,
    converged = converged,
    condition_number = cond_num
  )
}

#' Estimate timescale separation ε from data
#' @param x Numeric. Fast variable time series
#' @param t_numeric Numeric. Time points
#' @return Numeric. Estimated ε = τ₁/τ₂
estimate_epsilon <- function(x, t_numeric) {
  n <- length(x)
  if (n < 10) return(0.1)
  
  tryCatch({
    valid_idx <- which(x > 0 & !is.na(x) & is.finite(x))
    if (length(valid_idx) < 5) return(0.1)
    
    early_idx <- valid_idx[seq_len(floor(min(10, length(valid_idx)/2)))]
    early_t <- t_numeric[early_idx]
    early_x <- x[early_idx]
    
    log_x <- log(early_x)
    fit <- lm(log_x ~ early_t)
    k_fast <- abs(coef(fit)[2])
    
    k_slow_approx <- 0.1
    epsilon_est <- k_slow_approx / max(k_fast, 0.01)
    
    pmax(pmin(epsilon_est, 0.99), 0.0001)
    
  }, error = function(e) 0.1)
}

#' Compute Jacobian condition number profile
compute_jacobian_condition_number <- function(t, x, y, eps) {
  n <- length(t)
  if (n < 3) return(Inf)
  
  kappa_vals <- numeric(n - 1)
  
  for (i in seq_len(n - 1)) {
    fx_x <- -eps^-1
    fx_y <- 0
    
    dt_i <- t[i+1] - t[i]
    if (dt_i == 0) dt_i <- 1e-10
    dy_dx_approx <- (y[i+1] - y[i]) / dt_i
    
    J_mat <- matrix(c(fx_x, fx_y,
                      0, dy_dx_approx),
                    nrow = 2)
    
    svd_res <- suppressWarnings(svd(J_mat))
    if (svd_res$d[2] == 0 || !is.finite(svd_res$d[1])) {
      kappa_vals[i] <- Inf
    } else {
      kappa_vals[i] <- svd_res$d[1] / max(svd_res$d[2], 1e-15)
    }
  }
  
  max_kappa <- max(kappa_vals[kappa_vals < 1e12], na.rm = TRUE)
  if (is.infinite(max_kappa) || is.nan(max_kappa)) max_kappa <- Inf
  
  max_kappa
}
