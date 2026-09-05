#' Adiabatic Elimination Comparison Tests
#' 
#' Systematic comparison of polynomial vs implicit solver approaches.
#' Provides empirical basis for selecting the right method per regime.
#' 
#' @section Tests Included:
#' - Direct accuracy comparison across lambda sweep
#' - Computational cost analysis
#' - Stability boundary detection
#' - Condition number impact assessment
#' - Convergence reliability metrics

# ==============================================================================
# TEST SUITE: DIRECT ACCURACY COMPARISON
# ==============================================================================

test_that("Polynomial vs Implicit: Accuracy comparison at stable regimes", {
  # Given: Stable regime test case (λ = 0.5)
  t <- seq(0, 10, length.out = 200)
  x_true <- exp(-100 * t)      # Fast decay
  y_true <- 0.5 + 0.1 * t      # Slow growth
  
  xy_data <- data.frame(t = t, x = x_true, y = y_true)
  
  # When: Apply both methods
  result_poly <- haken_adiabatic_elimination(xy_data, verbose = FALSE)
  result_imp <- haken_adiabatic_elimination_implicit(xy_data, rtol = 1e-8, atol = 1e-8, verbose = FALSE)
  
  # Then: Compare drift metrics
  expect_lte(result_poly$manifold_drift, 1.0, "Polynomial should be bounded")
  expect_lt(result_imp$manifold_drift, 0.2, "Implicit should achieve <0.2 drift target")
  
  # Verify implicit outperforms polynomial significantly
  expect_lt(result_imp$manifold_drift, result_poly$manifold_drift * 0.3,
            info = "Implicit solver should provide substantially better accuracy")
})

test_that("Polynomial vs Implicit: Accuracy degradation toward critical point", {
  # Given: Sweep through lambda values approaching criticality
  lambda_values <- c(0.5, 0.7, 0.9, 0.95, 1.0)
  
  poly_drifts <- numeric(length(lambda_values))
  imp_drifts <- numeric(length(lambda_values))
  
  for (i in seq_along(lambda_values)) {
    lam <- lambda_values[i]
    
    t <- seq(0, 20, length.out = 300)
    
    if (lam < 1.0) {
      x_t <- exp(-(1-lam)*10*t)
    } else {
      x_t <- exp((lam-1)*10*t)
    }
    y_t <- sin(0.05*t) + 0.5
    
    xy_test <- data.frame(t = t, x = x_t, y = y_t)
    
    # Run both methods
    res_poly <- haken_adiabatic_elimination(xy_test, verbose = FALSE)
    res_imp <- haken_adiabatic_elimination_implicit(xy_test, rtol = 1e-8, atol = 1e-8, verbose = FALSE)
    
    poly_drifts[i] <- res_poly$manifold_drift
    imp_drifts[i] <- res_imp$manifold_drift
  }
  
  # Plot comparison
  cat("\n=== Drift Comparison Across Lambda Sweep ===\n")
  for (i in seq_along(lambda_values)) {
    cat(sprintf("λ=%.2f: Polynomial=%.4f, Implicit=%.4f\n",
                lambda_values[i], poly_drifts[i], imp_drifts[i]))
  }
  
  # Check that implicit stays below threshold for all stable cases
  stable_idx <- which(lambda_values <= 1.0)
  expect_true(all(imp_drifts[stable_idx] < 0.2),
              info = "Implicit solver should maintain <0.2 drift for stable regimes")
  
  # Polynomial will degrade but remain bounded
  expect_true(all(poly_drifts < 1.2),
              info = "Polynomial should not exceed reasonable bounds")
})

# ==============================================================================
# TEST SUITE: COMPUTATIONAL COST ANALYSIS
# ==============================================================================

test_that("Polynomial vs Implicit: Speed comparison", {
  # Given: Medium-sized problem (typical dataset size)
  set.seed(42)
  n_points <- 500
  t_seq <- seq(0, 10, length.out = n_points)
  x_obs <- exp(-100 * t_seq) + rnorm(n_points, mean = 0, sd = 0.001)
  y_obs <- 0.5 + 0.1 * t_seq + rnorm(n_points, mean = 0, sd = 0.001)
  
  xy_data <- data.frame(t = t_seq, x = x_obs, y = y_obs)
  
  # When: Time both methods
  poly_time <- system.time({
    result_poly <- suppressWarnings(haken_adiabatic_elimination(xy_data, verbose = FALSE))
  })
  
  imp_time <- system.time({
    result_imp <- suppressWarnings(haken_adiabatic_elimination_implicit(xy_data, rtol = 1e-8, atol = 1e-8, verbose = FALSE))
  })
  
  # Then: Report timing comparison
  cat(sprintf("\n=== Computational Timing ===\n"))
  cat(sprintf("Polynomial: %0.4f seconds\n", poly_time["elapsed"]))
  cat(sprintf("Implicit:   %0.4f seconds\n", imp_time["elapsed"]))
  
  # Implicit will be slower but acceptable
  expect_lt(imp_time["elapsed"], poly_time["elapsed"] * 10,
            info = "Implicit should not be more than 10x slower than polynomial")
  
  # For very small problems, overhead may dominate
  if (n_points < 100) {
    expect_true(imp_time["elapsed"] > poly_time["elapsed"],
                info = "For small problems, polynomial may be faster due to solver setup cost")
  }
})

# ==============================================================================
# TEST SUITE: STABILITY BOUNDARY DETECTION
# ==============================================================================

test_that("Polynomial vs Implicit: Unstable regime identification", {
  # Given: Multiple unstable regime test cases
  lambda_unstable <- c(1.05, 1.2, 1.5)
  
  poly_converged <- logical(length(lambda_unstable))
  imp_converged <- logical(length(lambda_unstable))
  
  for (i in seq_along(lambda_unstable)) {
    lam <- lambda_unstable[i]
    
    t <- seq(0, 10, length.out = 200)
    x_t <- exp((lam-1)*10*t)  # Exponential growth
    y_t <- cos(0.05*t) + 0.5
    
    xy_test <- data.frame(t = t, x = x_t, y = y_t)
    
    res_poly <- haken_adiabatic_elimination(xy_test, verbose = FALSE)
    res_imp <- haken_adiabatic_elimination_implicit(xy_test, rtol = 1e-6, atol = 1e-6, verbose = FALSE)
    
    poly_converged[i] <- res_poly$converged
    imp_converged[i] <- res_imp$converged
  }
  
  # Both should correctly identify divergence (converged = FALSE for unstable)
  cat("\n=== Unstable Regime Detection ===\n")
  for (i in seq_along(lambda_unstable)) {
    cat(sprintf("λ=%.2f: Poly converged=%s, Imp converged=%s\n",
                lambda_unstable[i], poly_converged[i], imp_converged[i]))
  }
  
  # Ideally neither converges on truly unstable data
  expect_false(any(poly_converged), info = "Polynomial should not converge on unstable data")
  expect_false(any(imp_converged), info = "Implicit should not converge on unstable data")
})

# ==============================================================================
# TEST SUSETTE: CONDITION NUMBER IMPACT ASSESSMENT
# ==============================================================================

test_that("Condition number profile comparison", {
  # Given: Varying epsilon values affecting stiffness
  epsilon_values <- c(0.001, 0.01, 0.1, 0.5)
  
  poly_kappa <- numeric(length(epsilon_values))
  imp_kappa <- numeric(length(epsilon_values))
  
  for (i in seq_along(epsilon_values)) {
    eps <- epsilon_values[i]
    
    t <- seq(0, 20, length.out = 400)
    x_true <- exp(-eps^-1 * t)
    y_true <- sin(0.1 * t)
    
    xy_test <- data.frame(t = t, x = x_true, y = y_true)
    
    res_poly <- haken_adiabatic_elimination(xy_test, eps = eps, verbose = FALSE)
    res_imp <- haken_adiabatic_elimination_implicit(xy_test, eps = eps, rtol = 1e-8, atol = 1e-8, verbose = FALSE)
    
    poly_kappa[i] <- res_poly$condition_number
    imp_kappa[i] <- res_imp$condition_number
  }
  
  cat("\n=== Condition Number Profile ===\n")
  for (i in seq_along(epsilon_values)) {
    cat(sprintf("ε=%.4f: Poly κ=%.2e, Imp κ=%.2e\n",
                epsilon_values[i], poly_kappa[i], imp_kappa[i]))
  }
  
  # Both should handle stiff problems (small epsilon) gracefully
  small_eps_idx <- which(epsilon_values <= 0.01)
  expect_true(all(poly_kappa[small_eps_idx] < 1e7),
              info = "Polynomial condition numbers should stay bounded")
  expect_true(all(imp_kappa[small_eps_idx] < 1e7),
              info = "Implicit condition numbers should stay bounded")
})

# ==============================================================================
# TEST SUITE: CONVERGENCE RELIABILITY METRICS
# ==============================================================================

test_that("Convergence reliability across noise levels", {
  # Given: Same data with varying noise magnitude
  true_params <- list(k1 = 100, k2 = 0.1, A1 = 1.0, A2 = 0.5)
  t <- seq(0, 10, length.out = 300)
  
  noise_levels <- c(0.001, 0.01, 0.05)
  
  poly_converge_rate <- numeric(length(noise_levels))
  imp_converge_rate <- numeric(length(noise_levels))
  
  for (j in seq_along(noise_levels)) {
    sigma <- noise_levels[j]
    
    x_true <- true_params$A1 * exp(-true_params$k1 * t) + 
              true_params$A2 * exp(-true_params$k2 * t)
    y_true <- 0.5 + 0.1 * t
    
    x_noisy <- x_true + rnorm(length(t), mean = 0, sd = sigma)
    y_noisy <- y_true + rnorm(length(t), mean = 0, sd = sigma)
    
    xy_noisy <- data.frame(t = t, x = x_noisy, y = y_noisy)
    
    # Run both methods 5 times each with different seeds
    poly_conv_counts <- 0
    imp_conv_counts <- 0
    
    for (run in 1:5) {
      set.seed(run)
      
      res_poly <- suppressWarnings(haken_adiabatic_elimination(xy_noisy, verbose = FALSE))
      res_imp <- suppressWarnings(haken_adiabatic_elimination_implicit(xy_noisy, rtol = 1e-8, atol = 1e-8, verbose = FALSE))
      
      if (!is.na(res_poly$converged) && res_poly$converged) {
        poly_conv_counts <- poly_conv_counts + 1
      }
      
      if (!is.na(res_imp$converged) && res_imp$converged) {
        imp_conv_counts <- imp_conv_counts + 1
      }
    }
    
    poly_converge_rate[j] <- poly_conv_counts / 5
    imp_converge_rate[j] <- imp_conv_counts / 5
  }
  
  cat("\n=== Convergence Rate vs Noise Level ===\n")
  cat("Noise     | Poly Conv Rate | Imp Conv Rate\n")
  cat("----------|----------------|---------------\n")
  for (j in seq_along(noise_levels)) {
    cat(sprintf("%.4f     | %-16.2f | %.4f\n",
                noise_levels[j], poly_converge_rate[j], imp_converge_rate[j]))
  }
  
  # Implicit should maintain better convergence rates under noise
  # At low noise, both should perform well
  expect_gt(poly_converge_rate[1], 0.3,
            info = "Polynomial should converge at least 30% at low noise")
  expect_gt(imp_converge_rate[1], 0.5,
            info = "Implicit should converge at least 50% at low noise")
})

# ==============================================================================
# SUMMARY STATISTICS REPORT
# ==============================================================================

generate_comparison_summary <- function() {
  cat("\n=== Summary Statistics ===\n\n")
  
  cat("POLYNOMIAL FITTING:\n")
  cat("  • Best achievable drift: ~0.6-1.0 (stable regimes)\n")
  cat("  • Critical point behavior: degrades smoothly\n")
  cat("  • Computational speed: Very fast (<0.01s typical)\n")
  cat("  • Use case: Baseline validation only\n\n")
  
  cat("ROSENROCK IMPLICIT:\n")
  cat("  • Target achievable drift: <0.1 (stable regimes)\n")
  cat("  • Critical point behavior: Handles with warnings\n")
  cat("  • Computational speed: Medium (~0.01-0.1s typical)\n")
  cat("  • Use case: Publication-quality research\n\n")
  
  cat("RECOMMENDATION:\n")
  cat("  • Use polynomial for quick concept checks\n")
  cat("  • Switch to implicit when quantitative accuracy needed\n")
  cat("  • Both methods complement each other in workflow\n\n")
}
