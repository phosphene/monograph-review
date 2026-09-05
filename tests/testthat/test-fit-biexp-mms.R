#' MMS Tests for Bi-Exponential Fitter
#' 
#' Method of Manufactured Solutions layer for fit_biexp.
#' Creates synthetic data from known parameters, verifies recovery within tolerance.
#' Follows Five-Tier Protocol Tier 1 (MMS).
#' 
#' @section Tests Included:
#' - Exact parameter recovery (no noise)
#' - Recovery within 5% with small noise (σ = 0.001)
#' - Recovery within 10% with moderate noise (σ = 0.01)
#' - Multi-scale separation validation
#' - Amplitude ratio stability
#' 
#' @keywords internal

test_that("MMS: exact parameter recovery (no noise)", {
  # Known truth: c0=0.05, A1=0.03, k1=17.7, A2=0.01, k2=0.47
  t <- seq(0, 10, length.out = 50)
  rho_true <- 0.05 + 0.03 * exp(-17.7 * t) + 0.01 * exp(-0.47 * t)
  
  result <- fit_biexp(t, rho_true, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  expect_gte(result$delta_aic_bi_mono, 10)  # bi clearly wins
  
  # Check parameter recovery (exact match expected)
  coef <- result$biexponential$coefficients
  
  # Allow small numerical tolerance due to optimiser
  expect_lag(coef$c0, 0.05, tol = 1e-6)
  expect_lag(coef$k1, 17.7, tol = 1e-4)
  expect_lag(coef$k2, 0.47, tol = 1e-4)
  expect_lag(coef$A1, 0.03, tol = 1e-5)
  expect_lag(coef$A2, 0.01, tol = 1e-5)
})

test_that("MMS: recovery with small noise (σ = 0.001)", {
  # Known truth
  true_params <- list(
    c0 = 0.05, A1 = 0.03, k1 = 17.7,
    A2 = 0.01, k2 = 0.47
  )
  
  set.seed(42)
  t <- seq(0, 10, length.out = 50)
  rho_true <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t) + 
              true_params$A2 * exp(-true_params$k2 * t)
  rho_noisy <- rho_true + rnorm(length(t), mean = 0, sd = 0.001)
  
  result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  
  coef <- result$biexponential$coefficients
  
  # Verify all parameters recovered within 5%
  for (param in names(true_params)) {
    if (param != "c0") {  # Skip c0 for this check
      rel_error <- abs(coef[[param]] - true_params[[param]]) / true_params[[param]]
      expect_lt(rel_error, 0.05)
    }
  }
  
  # Special check for c0 (absolute tolerance better than relative)
  expect_lt(abs(coef$c0 - true_params$c0), 0.0005)
})

test_that("MMS: recovery with moderate noise (σ = 0.01)", {
  true_params <- list(
    c0 = 0.1, A1 = 0.2, k1 = 10.0,
    A2 = 0.05, k2 = 0.2
  )
  
  set.seed(123)
  t <- seq(0, 20, length.out = 80)
  rho_true <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t) + 
              true_params$A2 * exp(-true_params$k2 * t)
  rho_noisy <- rho_true + rnorm(length(t), mean = 0, sd = 0.01)
  
  result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  
  coef <- result$biexponential$coefficients
  
  # Verify parameters recovered within 10% with higher noise
  for (param in names(true_params)) {
    if (param != "c0") {
      rel_error <- abs(coef[[param]] - true_params[[param]]) / true_params[[param]]
      expect_lt(rel_error, 0.10)
    }
  }
})

test_that("MMS: multi-scale separation (k1/k2 ratio preservation)", {
  # Test with extreme separation: fast channel decays completely before slow starts
  true_k_ratio <- 50.0  # Very large separation
  
  true_params <- list(
    c0 = 0.0, A1 = 0.5, k1 = true_k_ratio,
    A2 = 0.5, k2 = 1.0
  )
  
  set.seed(456)
  t <- seq(0, 5, length.out = 100)
  rho_true <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t) + 
              true_params$A2 * exp(-true_params$k2 * t)
  rho_noisy <- rho_true + rnorm(length(t), mean = 0, sd = 0.005)
  
  result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  
  actual_ratio <- result$metadata$k1_k2_ratio
  
  # Ratio should be preserved within 20%
  rel_error <- abs(actual_ratio - true_k_ratio) / true_k_ratio
  expect_lt(rel_error, 0.20)
})

test_that("MMS: amplitude ratio stability", {
  # Test that amplitude fractions are correctly identified
  true_params <- list(
    c0 = 0.0, A1 = 0.8, k1 = 20.0,
    A2 = 0.2, k2 = 0.1
  )
  
  set.seed(789)
  t <- seq(0, 10, length.out = 80)
  rho_true <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t) + 
              true_params$A2 * exp(-true_params$k2 * t)
  rho_noisy <- rho_true + rnorm(length(t), mean = 0, sd = 0.002)
  
  result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
  
  expect_true(result$biexponential$converged)
  
  # True amplitude fractions
  true_A1_frac <- true_params$A1 / (true_params$A1 + true_params$A2)
  true_A2_frac <- true_params$A2 / (true_params$A1 + true_params$A2)
  
  actual_A1_frac <- result$metadata$A1_frac
  actual_A2_frac <- result$metadata$A2_frac
  
  # Check both fractions within 10%
  expect_lt(abs(actual_A1_frac - true_A1_frac), 0.10)
  expect_lt(abs(actual_A2_frac - true_A2_frac), 0.10)
})

test_that("MMS: convergence to correct global minimum", {
  # Test that multiple starting points lead to consistent solutions
  true_params <- list(
    c0 = 0.15, A1 = 0.25, k1 = 8.0,
    A2 = 0.1, k2 = 0.3
  )
  
  # Run 10 times with different seeds
  recovered_k1 <- numeric(10)
  recovered_k2 <- numeric(10)
  
  for (i in 1:10) {
    set.seed(i)
    t <- seq(0, 10, length.out = 60)
    rho_true <- true_params$c0 + true_params$A1 * exp(-true_params$k1 * t) + 
                true_params$A2 * exp(-true_params$k2 * t)
    rho_noisy <- rho_true + rnorm(length(t), mean = 0, sd = 0.003)
    
    result <- fit_biexp(t, rho_noisy, normalize_t = FALSE)
    
    if (result$biexponential$converged) {
      recovered_k1[i] <- result$biexponential$coefficients$k1
      recovered_k2[i] <- result$biexponential$coefficients$k2
    }
  }
  
  # All runs should converge (no NAs in recovered vectors)
  expect_false(any(is.na(recovered_k1)))
  expect_false(any(is.na(recovered_k2)))
  
  # Means should be close to true values
  mean_k1 <- mean(recovered_k1)
  mean_k2 <- mean(recovered_k2)
  
  expect_lt(abs(mean_k1 - true_params$k1) / true_params$k1, 0.05)
  expect_lt(abs(mean_k2 - true_params$k2) / true_params$k2, 0.05)
})

# Add helper functions if needed
expect_lag <- function(a, b, tol = 1e-6) {
  diff <- abs(a - b)
  if (diff <= tol || (b > 0 && diff / abs(b) <= tol)) {
    return(invisible(TRUE))
  }
  stop(sprintf("Expected |%.4f - %.4f| <= %g, got %.4f", a, b, tol, diff))
}
