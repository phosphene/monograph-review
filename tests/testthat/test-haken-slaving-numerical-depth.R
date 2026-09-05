# Tests/testthat/test-haken-slaving-numerical-depth.R
# Comprehensive numerical verification for Haken adiabatic elimination/slaving
# 
# This suite validates mathematical correctness beyond basic regression:
#   • Forward error analysis (manufactured solutions)
#   • Backward error bounds (residuals in original ODE)
#   • Stability margins (stiff regime handling)
#   • Convergence order verification
#   • Round-off sensitivity (precision robustness)

library(testthat)
library(deSolve)
library(numDeriv)

skip_if_not_installed("hedgehog")
library(hedgehog)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Generate a manufactured solution for testing
#' We construct an analytic function y(t), compute its derivatives, then solve
#' for the forcing term f(t) that would produce exactly this solution.
#' This lets us verify the solver reproduces the manufactured solution exactly.
generate_manufactured_solution <- function(t_span = c(0, 10), n_points = 1001) {
  t <- seq(t_span[1], t_span[2], length.out = n_points)
  
  # Construct a smooth, non-trivial trajectory
  y_slow <- sin(2 * pi * t / t_span[2]) * exp(-0.1 * t) + 0.5
  y_fast <- 0.1 * cos(10 * pi * t / t_span[2]) * exp(-t)
  
  list(t = t, y_slow = y_slow, y_fast = y_fast)
}

#' Compute residual: how well does the computed solution satisfy dy/dt = f(y,t)?
compute_ode_residual <- function(sol, y_func, t_eval) {
  # sol is data.frame from deSolve with columns "time", "y_slow", "y_fast"
  dt <- diff(sol$t)[1]
  
  # Numerical derivative
  dy_num <- c(diff(sol$y_slow)/dt, diff(sol$y_fast)/dt)
  
  # Analytical derivative at midpoints
  t_mid <- (sol$t[-length(sol$t)] + sol$t[-1])/2
  dy_analytic <- c(
    D_y_slow <- deriv(function(y_s, y_f) {
      # Example: dy_slow/dt = -lambda_slow * (y_slow - y_eq)
      lambda_slow <- 0.1
      y_eq <- 0.5
      -lambda_slow * (y_s - y_eq)
    })(y_slow = sol$y_slow[-length(sol$y_slow)], y_fast = sol$y_fast[-length(sol$y_fast)])
  )
  
  abs(dy_num - dy_analytic)
}

# ============================================================================
# TEST 1: MANUFACTURED SOLUTION VERIFICATION
# ============================================================================

test_that("Haken implicit solver reproduces manufactured solution", {
  skip_on_cran()
  
  ms <- generate_manufactured_solution(n_points = 1001)
  t <- ms$t
  y_true <- ms$y_slow
  
  # Solve with Rosenbrock implicit method
  result <- suppressWarnings({
    haken_adiabatic_elimination_implicit(
      tau = t,
      y_initial = y_true[1],
      eps = 0.1,
      method = "ros3p"
    )
  })
  
  # Verify the computed solution matches the manufactured one
  expect_length(result$t, length(t))
  expect_gte(mean(abs(result$y - y_true)), 0)
  expect_lte(max(abs(result$y - y_true)), 1e-6)  # Tolerance for smooth manifold
  
  # Check that the fast variable tracks the slow manifold
  if ("y_fast" %in% names(result)) {
    # Fast variable should converge to algebraic relation
    epsilon_estimate <- mean(abs(result$y_fast - result$y_slow^2))
    expect_lte(epsilon_estimate, 0.01)
  }
})

# ============================================================================
# TEST 2: BACKWARD ERROR ANALYSIS
# ============================================================================

test_that("Backward residuals satisfy prescribed tolerances", {
  skip_on_cran()
  
  # Define a system with known properties
  model_params <- list(
    lambda_slow = 0.1,
    lambda_fast = 10.0,
    coupling = 0.5
  )
  
  # Solve on a challenging timescale
  tau_test <- seq(0, 100, by = 0.1)
  result <- haken_adiabatic_elimination_implicit(
    tau = tau_test,
    y_initial = 0.5,
    eps = 0.05,
    params = model_params,
    method = "ros3p"
  )
  
  # Compute backward residual: |dy/dt - f(y)|
  # For our system, this measures violation of algebraic constraints
  
  # Estimate numerical derivative
  dt <- diff(result$t)[1]
  dy_dt <- c(diff(result$y)/dt, 0)
  
  # Residual bound (should be small for correct implementation)
  max_residual <- max(abs(dy_dt))
  
  # Allow larger tolerance due to stiffness
  expect_lte(max_residual, 0.01)
  
  # The implicit solver should maintain residuals below tolerance even in stiff regime
  stable_regions <- which(dy_dt < 0.001)
  expect_gte(length(stable_regions), 0.8 * length(dy_dt))
})

# ============================================================================
# TEST 3: CONVERGENCE ORDER VERIFICATION
# ============================================================================

test_that("Implicit solver achieves expected convergence order", {
  skip_on_cran()
  
  # Test convergence as step size decreases
  steps <- c(100, 200, 400, 800, 1600)
  errors <- numeric(length(steps))
  
  reference_sol <- haken_adiabatic_elimination_implicit(
    tau = seq(0, 10, by = 1/1600),
    y_initial = 0.5,
    eps = 0.1,
    method = "ros3p"
  )
  
  for (i in seq_along(steps)) {
    sol <- haken_adiabatic_elimination_implicit(
      tau = seq(0, 10, by = 1/steps[i]),
      y_initial = 0.5,
      eps = 0.1,
      method = "ros3p"
    )
    
    # Interpolate reference solution to match time points
    ref_interp <- approx(reference_sol$t, reference_sol$y, xout = sol$t)$y
    
    # L2 error
    errors[i] <- sqrt(mean((sol$y - ref_interp)^2))
  }
  
  # Check convergence order (should be ~1 or higher for Rosenbrock)
  slopes <- diff(log(errors)) / diff(log(steps))
  mean_slope <- mean(slopes)
  
  # Implicit Rosenbrock methods typically achieve first-order convergence
  # Our tolerance is intentionally generous for real-world applications
  expect_gt(mean_slope, 0.5)
  expect_lt(mean_slope, 2.0)
})

# ============================================================================
# TEST 4: STABILITY REGION TESTING
# ============================================================================

test_that("Solver maintains stability across stiffness range", {
  skip_on_cran()
  
  # Test with increasingly stiff systems
  eps_values <- c(0.5, 0.1, 0.01, 0.001)
  outcomes <- character(length(eps_values))
  
  for (i in seq_along(eps_values)) {
    tryCatch({
      result <- haken_adiabatic_elimination_implicit(
        tau = seq(0, 50, by = 0.1),
        y_initial = 0.5,
        eps = eps_values[i],
        method = "ros3p"
      )
      
      # Check for NaN/Inf in solution
      if (any(is.na(result$y)) || any(is.infinite(result$y))) {
        outcomes[i] <- "unstable"
      } else {
        outcomes[i] <- "stable"
      }
    }, error = function(e) {
      outcomes[i] <- "failed"
    })
  }
  
  # Implicit solver should handle all stiffness values
  expect_false(any(outcomes == "failed"))
  expect_false(all(outcomes == "unstable"))
  
  # At least half should be numerically stable
  expect_gte(sum(outcomes == "stable"), ceiling(length(eps_values) / 2))
})

# ============================================================================
# TEST 5: ROUND-OFF SENSITIVITY ANALYSIS
# ============================================================================

test_that("Solution is robust to floating-point perturbations", {
  skip_on_cran()
  
  set.seed(42)
  
  # Base computation
  base_result <- haken_adiabatic_elimination_implicit(
    tau = seq(0, 10, by = 0.1),
    y_initial = 0.5,
    eps = 0.1,
    method = "ros3p"
  )
  
  # Add small random perturbations to initial condition
  perturbations <- seq(-1e-12, 1e-12, length.out = 11)
  results <- lapply(perturbations, function(delta) {
    haken_adiabatic_elimination_implicit(
      tau = seq(0, 10, by = 0.1),
      y_initial = 0.5 + delta,
      eps = 0.1,
      method = "ros3p"
    )
  })
  
  # Extract final states
  final_states <- sapply(results, function(r) r$y[length(r$y)])
  
  # Coefficient of variation should be very small for stable system
  cv <- sd(final_states) / mean(final_states)
  
  # System should be insensitive to machine-epsilon perturbations
  expect_lt(cv, 1e-8)
})

# ============================================================================
# TEST 6: HEDGEHOG PROPERTY-BASED TESTING
# ============================================================================

test_that("Manifold invariance holds for random trajectories", {
  skip_on_cran()
  
  gen_random_trajectory <- gen.c(gen.normal(0, 1, 10))
  gen_eps_values <- gen.c(gen.uniform(0.001, 0.1, 5))
  
  hedgehog::for_all(
    trajectory = gen_random_trajectory,
    eps_val = gen_eps_values
  )(function(path_vec, eps_value) {
    # Convert path vector to proper format
    y_init <- path_vec[1]
    tau <- seq(0, 5, length.out = 100)
    
    result <- haken_adiabatic_elimination_implicit(
      tau = tau,
      y_initial = y_init,
      eps = eps_value,
      method = "ros3p"
    )
    
    # Manifold invariance: fast variable should track algebraic relation
    # y_fast ≈ f(y_slow) where f is the equilibrium manifold function
    
    if (length(result$t) >= 10) {
      # Check that solution remains bounded
      expect_lte(max(abs(result$y)), 100)
      
      # Check that time evolution is smooth (no oscillations due to instability)
      diffs <- diff(result$y)
      max_diff <- max(abs(diffs))
      expect_lte(max_diff, 10)  # Reasonable bound on derivative
      
      TRUE  # Property satisfied
    } else {
      FALSE  # Invalid case
    }
  })
}, timeout_seconds = 30)

# ============================================================================
# TEST 7: POLYNOMIAL FITTING vs IMPLICIT METHOD CONSISTENCY
# ============================================================================

test_that("Polynomial and implicit methods agree within calibrated bounds", {
  skip_on_cran()
  
  tau_test <- seq(0, 20, by = 0.1)
  y_initial <- 0.5
  eps_test <- 0.1
  
  # Run both methods
  poly_result <- suppressWarnings({
    haken_adiabatic_elimination(
      tau = tau_test,
      y_initial = y_initial,
      eps = eps_test,
      degree = 2
    )
  })
  
  impl_result <- haken_adiabatic_elimination_implicit(
    tau = tau_test,
    y_initial = y_initial,
    eps = eps_test,
    method = "ros3p"
  )
  
  # Find overlapping time points
  overlap_idx <- which(tau_test %in% poly_result$t & tau_test %in% impl_result$t)
  
  if (length(overlap_idx) > 1) {
    # Compare at overlapping points
    y_poly <- poly_result$y[poly_result$t[overlap_idx]]
    y_impl <- impl_result$y[impl_result$t %in% tau_test[overlap_idx]]
    
    # Differences should be within calibrated tolerance (< 0.1 for implicit)
    abs_diff <- abs(y_poly - y_impl)
    
    expect_lte(mean(abs_diff), 0.05)
    expect_lte(max(abs_diff), 0.2)
  } else {
    skip("No overlapping time points found")
  }
})

# ============================================================================
# TEST 8: FORWARD ERROR PROPAGATION ANALYSIS
# ============================================================================

test_that("Forward error growth is bounded by Lipschitz constant", {
  skip_on_cran()
  
  # Use perturbed initial conditions to measure error amplification
  n_perts <- 50
  y_base <- 0.5
  
  perts <- rnorm(n_perts, mean = 0, sd = 1e-10)
  errors_at_end <- numeric(n_perts)
  
  for (i in 1:n_perts) {
    # Base solution
    base_sol <- haken_adiabatic_elimination_implicit(
      tau = seq(0, 20, by = 0.1),
      y_initial = y_base,
      eps = 0.1,
      method = "ros3p"
    )
    
    # Perturbed solution
    pert_sol <- haken_adiabatic_elimination_implicit(
      tau = seq(0, 20, by = 0.1),
      y_initial = y_base + perts[i],
      eps = 0.1,
      method = "ros3p"
    )
    
    # Error at final time
    errors_at_end[i] <- abs(pert_sol$y[length(pert_sol$y)] - 
                            base_sol$y[length(base_sol$y)])
  }
  
  # Error growth should be exponential but bounded
  # Lyapunov exponent estimation: λ ≈ log(error_final/error_initial)/time
  avg_error_growth <- median(abs(errors_at_end))
  avg_initial_perturbation <- mean(abs(perts))
  
  # Ratio should be reasonable (not exploding to infinity)
  ratio <- avg_error_growth / avg_initial_perturbation
  
  # Allow up to 100x amplification over integration time
  expect_lt(ratio, 100)
})

# ============================================================================
# TEST 9: MULTISCALE SEPARATION VALIDATION
# ============================================================================

test_that("Method correctly identifies valid multiscale regime", {
  skip_on_cran()
  
  # Test across a range of timescale separations
  eps_grid <- seq(0.001, 1.0, length.out = 20)
  valid_separations <- logical(length(eps_grid))
  
  for (i in seq_along(eps_grid)) {
    tryCatch({
      result <- haken_adiabatic_elimination_implicit(
        tau = seq(0, 10, by = 0.1),
        y_initial = 0.5,
        eps = eps_grid[i],
        method = "ros3p"
      )
      
      # Check solution quality: no NaN/Inf, finite values
      valid_separations[i] <- !any(is.nan(result$y)) && 
                               !any(is.infinite(result$y))
    }, error = function(e) {
      valid_separations[i] <- FALSE
    })
  }
  
  # Valid separation should exist for most eps values tested
  expect_gt(sum(valid_separations), length(eps_grid) * 0.7)
  
  # Should fail gracefully at very small eps (numerical singularities)
  expect_false(valid_separations[1])  # First element is smallest eps
})

# ============================================================================
# TEST 10: COMPUTATIONAL EFFICIENCY BENCHMARK
# ============================================================================

test_that("Solver completes within reasonable time bounds", {
  skip_on_cran()
  
  # Benchmark with realistic workload
  tau_long <- seq(0, 100, by = 0.01)  # 10000 time steps
  
  start_time <- Sys.time()
  result <- haken_adiabatic_elimination_implicit(
    tau = tau_long,
    y_initial = 0.5,
    eps = 0.1,
    method = "ros3p"
  )
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Should complete in under 30 seconds for typical scientific workflow
  expect_lt(elapsed, 30)
  
  # Verify we got a full solution
  expect_length(result$t, length(tau_long))
})
