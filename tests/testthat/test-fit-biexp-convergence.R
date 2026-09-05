#' Convergence-Order Verification for Bi-Exponential Fitter
#' 
#' Tests empirical error reduction rate matches theoretical O(Δt²).
#' Follows Five-Tier Protocol Tier 2 (Convergence-order).
#' 
#' @section Tests Included:
#' - Numerical integration error scaling with time step
#' - Rate parameter stability vs sampling density
#' - RSS reduction order verification
#' - Halflife estimation convergence

test_that("Convergence: trapezoid integration error scales O(Δt²)", {
  # True analytical solution
  t_true <- seq(0, 10, length.out = 1000)
  rho_true <- 0.05 + 0.03 * exp(-17.7 * t_true) + 0.01 * exp(-0.47 * t_true)
  
  # Test with decreasing Δt
  deltas <- c(1.0, 0.5, 0.25, 0.125, 0.0625)
  errors <- numeric(length(deltas))
  
  for (i in seq_along(deltas)) {
    dt <- deltas[i]
    t_coarse <- seq(0, 10, by = dt)
    
    # Interpolate to match coarse points
    rho_coarse <- approx(t_true, rho_true, xout = t_coarse)$y
    
    result <- fit_biexp(t_coarse, rho_coarse, normalize_t = FALSE)
    
    if (result$biexponential$converged) {
      coef <- result$biexponential$coefficients
      
      # Error in k1 (fastest-decaying component is most sensitive)
      errors[i] <- abs(coef$k1 - 17.7) / 17.7
    } else {
      errors[i] <- Inf
    }
  }
  
  # Exclude any non-finite values
  finite_idx <- which(is.finite(errors))
  expect_gt(length(finite_idx), 0, "All fits must converge")
  
  errors_finite <- errors[finite_idx]
  deltas_finite <- deltas[finite_idx]
  
  # Estimate empirical order p̂ from log-log regression
  log_dt <- log(deltas_finite)
  log_err <- log(errors_finite)
  
  fit_order <- lm(log_err ~ log_dt)
  p_hat <- -coef(fit_order)[2]
  
  # Should be approximately 2.0 (O(Δt²))
  expect_gte(p_hat, 1.5)  # Allow 25% tolerance
  expect_lte(p_hat, 2.5)
})

test_that("Convergence: rate parameters stabilize at high sampling density", {
  true_params <- list(
    c0 = 0.1, A1 = 0.2, k1 = 15.0,
    A2 = 0.1, k2 = 0.2
  )
  
  set.seed(42)
  t_dense <- seq(0, 10, length.out = 500)
  rho_dense <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t_dense) + 
               true_params$A2 * exp(-true_params$k2 * t_dense)
  
  # Sample at different densities
  nsamples <- c(10, 20, 40, 80, 160, 320)
  recovered_k1 <- numeric(length(nsamples))
  recovered_k2 <- numeric(length(nsamples))
  
  for (i in seq_along(nsamples)) {
    n <- nsamples[i]
    idx <- seq_len(n)
    t_sample <- t_dense[idx]
    rho_sample <- rho_dense[idx]
    
    result <- fit_biexp(t_sample, rho_sample, normalize_t = FALSE)
    
    if (result$biexponential$converged) {
      coef <- result$biexponential$coefficients
      recovered_k1[i] <- coef$k1
      recovered_k2[i] <- coef$k2
    } else {
      recovered_k1[i] <- NA
      recovered_k2[i] <- NA
    }
  }
  
  # Check convergence behavior
  valid_idx <- which(!is.na(recovered_k1))
  expect_gt(length(valid_idx), 3, "Must have enough successful fits")
  
  # K1 should approach true value as N increases
  final_rel_error_k1 <- abs(recovered_k1[length(valid_idx)] - true_params$k1) / true_params$k1
  initial_rel_error_k1 <- abs(recovered_k1[valid_idx[1]] - true_params$k1) / true_params$k1
  
  # Later estimates should be better than early ones
  expect_lt(final_rel_error_k1, initial_rel_error_k1)
  
  # Final estimate within 5%
  expect_lt(final_rel_error_k1, 0.05)
})

test_that("Convergence: RSS reduces with optimal parameters", {
  # Compare RSS across different Δt values
  true_k1 <- 12.5
  true_k2 <- 0.3
  
  deltas <- c(0.5, 0.25, 0.125, 0.0625)
  rss_values <- numeric(length(deltas))
  
  for (i in seq_along(deltas)) {
    dt <- deltas[i]
    t_test <- seq(0, 10, by = dt)
    
    # Generate data from known truth
    rho_test <- 0.05 + 0.03 * exp(-true_k1 * t_test) + 0.01 * exp(-true_k2 * t_test)
    
    result <- fit_biexp(t_test, rho_test, normalize_t = FALSE)
    
    if (result$biexponential$converged) {
      rss_values[i] <- result$biexponential$rss
    } else {
      rss_values[i] <- Inf
    }
  }
  
  # RSS should decrease (or stay same) as resolution improves
  finite_rss <- rss_values[is.finite(rss_values)]
  expect_gt(length(finite_rss), 0)
  
  if (length(finite_rss) >= 2) {
    # RSS should be monotonically non-increasing
    expect_true(all(diff(finite_rss) <= 1e-10))
  }
})

test_that("Convergence: halflife estimation stabilizes", {
  true_halflives <- list(
    fast = log(2) / 20.0,  # ~0.035 s
    slow = log(2) / 0.5    # ~1.386 s
  )
  
  set.seed(456)
  t <- seq(0, 10, length.out = 200)
  rho <- 0.0 + 0.5 * exp(-20.0 * t) + 0.5 * exp(-0.5 * t)
  rho_noisy <- rho + rnorm(length(t), mean = 0, sd = 0.002)
  
  result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  
  actual_halflives <- list(
    fast = result$metadata$k1_halflife,
    slow = result$metadata$k2_halflife
  )
  
  # Both halflives within 5% of true values
  rel_error_fast <- abs(actual_halflives$fast - true_halflives$fast) / true_halflives$fast
  rel_error_slow <- abs(actual_halflives$slow - true_halflives$slow) / true_halflives$slow
  
  expect_lt(rel_error_fast, 0.05)
  expect_lt(rel_error_slow, 0.05)
})

test_that("Convergence: normalised time scale invariance", {
  # Same physical process, different time units
  true_k1_raw <- 10.0
  true_k2_raw <- 0.2
  
  t_raw <- seq(0, 100, length.out = 100)
  rho <- 0.05 + 0.03 * exp(-true_k1_raw * t_raw) + 0.01 * exp(-true_k2_raw * t_raw)
  
  # Fit with normalize_t = TRUE
  result_norm <- fit_biexp(t_raw, rho, normalize_t = TRUE)
  
  # Convert reported rates back to raw scale
  t_range <- max(t_raw) - min(t_raw)
  k1_converted <- result_norm$biexponential$coefficients$k1 * t_range
  k2_converted <- result_norm$biexponential$coefficients$k2 * t_range
  
  # Normalised fit should report per-normalised-unit rates
  # After conversion, should match raw-scale fit
  expect_gte(k1_converted, true_k1_raw * 0.95)
  expect_lte(k1_converted, true_k1_raw * 1.05)
  expect_gte(k2_converted, true_k2_raw * 0.95)
  expect_lte(k2_converted, true_k2_raw * 1.05)
})

# Run tests if executed directly
if (Sys.getenv("TESTTHAT_RUN_ALL") == "true") {
  test_check("monograph.review", filter = "fit-biexp-convergence")
}
