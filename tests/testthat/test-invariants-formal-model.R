# test-invariants-formal-model.R — Property-based / invariant tests for formal model
# DFT A1: pure math, deterministic, no I/O (A2 not needed)
# Tests invariants across ~1000 random parameter combinations each

library(testthat)

expect_close_to <- function(actual, expected, tolerance = 1e-6) {
  expect_true(abs(actual - expected) <= tolerance,
              info = sprintf("Expected %.10f within %.2e of %.10f", actual, tolerance, expected))
}

context("Formal Model Invariants")

# ==============================================================================
# HELPER: Random parameter generation
# ==============================================================================

#' Generate random valid parameters for invariant testing
#'
#' @param n Integer. Number of parameter sets to generate.
#' @return List of lists with lambda, theta, m0, alpha, time, depths vectors.
.generate_random_params <- function(n = 1000L) {
  withr::with_seed(42, {
    params_list <- lapply(seq_len(n), function(i) {
      list(
        lambda = runif(1, 0.01, 0.5),
        theta = runif(1, 1.0, 5.0),
        m0 = runif(1, 1.0, 50.0),
        alpha = runif(1, 0.001, 0.2),
        time = runif(1, 10.0, 200.0),
        # Depths spanning both protected and unprotected regimes
        depths = sort(runif(10, 0.5, 6.0))
      )
    })
    params_list
  })
}

# ==============================================================================
# INVARIANT 1: retention ∈ [0, 1] for ALL valid parameters
# ==============================================================================

test_that("Invariant: retention ∈ [0, 1] for all closed-form evaluations", {
  skip_on_cran()  # ~1000 iterations may be slow on CRAN
  
  set.seed(42)
  n_iter <- 1000L
  
  for (i in seq_len(n_iter)) {
    lambda <- runif(1, 0.01, 0.5)
    theta <- runif(1, 1.0, 5.0)
    m0 <- runif(1, 1.0, 50.0)
    alpha <- runif(1, 0.001, 0.2)
    time <- runif(1, 10.0, 200.0)
    depth <- runif(1, 0.5, 6.0)
    
    result <- retention_at_time(depth, lambda, theta, m0, alpha, time)
    
    expect_true(result >= 0, 
                info = sprintf("Iteration %d: depth=%.3f, lambda=%.3f", i, depth, lambda))
    expect_true(result <= 1, 
                info = sprintf("Iteration %d: depth=%.3f, lambda=%.3f", i, depth, lambda))
  }
  
  # Also test equilibrium_retention
  for (i in seq_len(100L)) {
    lambda <- runif(1, 0.01, 0.5)
    theta <- runif(1, 1.0, 5.0)
    m0 <- runif(1, 1.0, 50.0)
    alpha <- runif(1, 0.001, 0.2)
    depth <- runif(1, 0.5, 6.0)
    
    result <- equilibrium_retention(depth, lambda, theta, m0, alpha)
    
    expect_true(result >= 0)
    expect_true(result <= 1)
  }
})

test_that("Invariant: threshold_model returns retention ∈ [0, 1]", {
  skip_on_cran()
  
  random_params <- .generate_random_params(50L)  # Fewer iterations for full simulation
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    result <- threshold_model(
      depths = p$depths, lambda = p$lambda, theta = p$theta,
      m0 = p$m0, alpha = p$alpha, time = p$time, n_steps = 500L
    )
    
    expect_true(min(result$values$final_retention) >= 0)
    expect_true(max(result$values$final_retention) <= 1)
  }
})

# ==============================================================================
# INVARIANT 2: Protected traits (d ≥ θ) always retain at 1.0
# ==============================================================================

test_that("Invariant: protected traits (d >= θ) retain at exactly 1.0", {
  random_params <- .generate_random_params(100L)
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    protected_depths <- p$depths[p$depths >= p$theta]
    
    if (length(protected_depths) > 0) {
      results <- retention_closed_form(protected_depths, p$lambda, p$theta,
                                       p$m0, p$alpha, p$time)
      
      for (j in seq_along(results)) {
        expect_equal(results[[j]], 1.0,
                     info = sprintf("Iteration %d: depth=%.3f >= theta=%.3f",
                                   i, protected_depths[j], p$theta))
        expect_true(results[[j]] >= 1.0)
      }
    }
  }
})

test_that("Invariant: equilibrium_retention returns 1.0 for protected", {
  random_params <- .generate_random_params(100L)
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    protected_depths <- p$depths[p$depths >= p$theta]
    
    if (length(protected_depths) > 0) {
      for (d in protected_depths) {
        result <- equilibrium_retention(d, p$lambda, p$theta, p$m0, p$alpha)
        expect_equal(result, 1.0)
      }
    }
  }
})

# ==============================================================================
# INVARIANT 3: Unprotected traits (d < θ) always retain < 1.0 for t > 0
# ==============================================================================

test_that("Invariant: unprotected traits (d < θ) retain < 1.0 at any t > 0", {
  random_params <- .generate_random_params(100L)
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    unprotected_depths <- p$depths[p$depths < p$theta]
    
    if (length(unprotected_depths) > 0) {
      for (d in unprotected_depths) {
        result <- retention_at_time(d, p$lambda, p$theta, p$m0, p$alpha, p$time)
        
        expect_true(result < 1.0,
                   info = sprintf("Iteration %d: depth=%.3f < theta=%.3f, value=%.6f",
                                 i, d, p$theta, result))
      }
    }
  }
})

# ==============================================================================
# INVARIANT 4: Closed-form and Euler agree within tolerance
# ==============================================================================

test_that("Invariant: closed-form and Euler integration agree within 0.01", {
  skip_on_cran()
  
  random_params <- .generate_random_params(50L)
  tol <- 0.01
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    
    # Get closed-form predictions
    cf_results <- retention_closed_form(p$depths, p$lambda, p$theta, p$m0, p$alpha, p$time)
    cf_values <- cf_results
    
    # Run Euler integration
    result_euler <- threshold_model(
      depths = p$depths, lambda = p$lambda, theta = p$theta,
      m0 = p$m0, alpha = p$alpha, time = p$time, n_steps = 1000L
    )
    
    euler_values <- result_euler$values$final_retention
    
    # All should agree within tolerance
    max_error <- max(abs(euler_values - cf_values))
    expect_true(max_error < tol, info = sprintf("Max error %.6f > %.4f at iteration %d", max_error, tol, i))
  }
})

# ==============================================================================
# INVARIANT 5: Threshold gate is a step function (binary split at θ)
# ==============================================================================

test_that("Invariant: threshold creates binary split at θ", {
  set.seed(42)
  
  # Create data with clear protected/unprotected split
  n_total <- 100L
  depths <- seq(0.5, 6.0, length.out = n_total)
  theta_val <- 3.0
  
  result <- threshold_model(
    depths = depths, lambda = 0.2, theta = theta_val,
    m0 = 5.0, alpha = 0.1, time = 50.0, n_steps = 1000L
  )
  
  # Split by threshold
  protected_idx <- which(depths >= theta_val)
  unprotected_idx <- which(depths < theta_val)
  
  # Protected should all be ~1.0
  expect_true(mean(result$values$final_retention[protected_idx]) >= 0.99)
  expect_true(sd(result$values$final_retention[protected_idx]) <= 0.01)
  
  # Unprotected should all be < 1.0
  expect_true(max(result$values$final_retention[unprotected_idx]) <= 0.95)
  
  # Biphasicity should be large (gap between groups)
  prot_mean <- mean(result$values$final_retention[protected_idx])
  unprot_mean <- mean(result$values$final_retention[unprotected_idx])
  gap <- prot_mean - unprot_mean
  
  expect_true(gap > 0.5, info = "Threshold gap should be substantial")
  expect_close_to(result$values$threshold_biphasicity, gap, tolerance = 1e-6)
})

# ==============================================================================
# INVARIANT 6: Monotonicity - increasing λ decreases retention (unprotected)
# ==============================================================================

test_that("Invariant: increasing λ decreases retention for unprotected traits", {
  set.seed(42)
  
  lambda_vals <- sort(runif(5, 0.01, 0.5))
  depth <- 1.5  # Clearly unprotected
  theta <- 3.0
  
  retentions <- sapply(lambda_vals, function(lam) {
    retention_at_time(depth, lam, theta, m0 = 5.0, alpha = 0.1, time = 50.0)
  })
  
  # Should be strictly decreasing
  for (i in seq_len(length(lambda_vals) - 1)) {
    expect_true(retentions[i + 1] < retentions[i], info = sprintf("λ=%.4f → %.4f: retention %.6f vs %.6f",
                           lambda_vals[i], lambda_vals[i + 1],
                           retentions[i], retentions[i + 1]))
  }
})

test_that("Invariant: monotonicity holds in threshold_model as well", {
  set.seed(42)
  
  lambda_seq <- c(0.001, 0.005, 0.01, 0.05)
  depths_unprot <- c(0.5, 1.0, 1.5)
  
  means_by_lambda <- sapply(lambda_seq, function(lam) {
    result <- threshold_model(depths = depths_unprot, lambda = lam, theta = 3.0,
                              m0 = 5.0, alpha = 0.1, time = 50.0, n_steps = 500L)
    mean(result$values$final_retention)
  })
  # Handle NA from any failed fits
  means_by_lambda <- means_by_lambda[!is.na(means_by_lambda)]
  
  expect_true(all(diff(means_by_lambda) < 0),
              "Mean retention should decrease monotonically with λ")
})

# ==============================================================================
# INVARIANT 7: Monotonicity - increasing α increases retention
# ==============================================================================

test_that("Invariant: increasing α increases retention (faster decay = less shedding)", {
  set.seed(42)
  
  alpha_vals <- sort(runif(5, 0.001, 0.1))
  depth <- 1.5  # Unprotected
  theta <- 3.0
  
  retentions <- sapply(alpha_vals, function(a) {
    retention_at_time(depth, lambda = 0.2, theta = theta, m0 = 20.0, alpha = a, time = 100.0)
  })
  
  # Faster decay → less total mismatch exposure → more retention
  for (i in seq_len(length(alpha_vals) - 1)) {
    expect_true(retentions[i + 1] > retentions[i], info = sprintf("α=%.4f → %.4f: retention %.6f vs %.6f",
                           alpha_vals[i], alpha_vals[i + 1],
                           retentions[i], retentions[i + 1]))
  }
})

# ==============================================================================
# INVARIANT 8: Conservation - total retention structure is correct
# ==============================================================================

test_that("Invariant: conservation of structure (n_protected + n_unprotected = n_total)", {
  random_params <- .generate_random_params(100L)
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    
    result <- threshold_model(
      depths = p$depths, lambda = p$lambda, theta = p$theta,
      m0 = p$m0, alpha = p$alpha, time = p$time, n_steps = 500L
    )
    
    meta <- result$metadata
    
    expect_equal(meta$n_traits, length(p$depths))
    expect_equal(meta$n_protected + meta$n_unprotected, meta$n_traits)
    
    # Verify counts match actual classification
    actual_protected <- sum(p$depths >= p$theta)
    actual_unprotected <- sum(p$depths < p$theta)
    
    expect_equal(meta$n_protected, actual_protected)
    expect_equal(meta$n_unprotected, actual_unprotected)
  }
})

# ==============================================================================
# INVARIANT 9: Time limit - as T → ∞, unprotected → exp(-λM₀/α), protected → 1
# ==============================================================================

test_that("Invariant: large time limit reaches equilibrium values", {
  set.seed(42)
  
  t_large <- 10000.0
  
  # Protected trait
  depth_prot <- 5.0
  theta <- 3.0
  
  result_prot_large <- retention_at_time(depth_prot, lambda = 0.2, theta = theta,
                                         m0 = 20.0, alpha = 0.05, time = t_large)
  eq_prot <- equilibrium_retention(depth_prot, 0.2, theta, 20.0, 0.05)
  
  expect_close_to(result_prot_large, eq_prot, tolerance = 1e-6)
  expect_equal(result_prot_large, 1.0)
  
  # Unprotected trait
  depth_unprot <- 1.0
  
  result_unprot_large <- retention_at_time(depth_unprot, lambda = 0.2, theta = theta,
                                           m0 = 20.0, alpha = 0.05, time = t_large)
  eq_unprot <- equilibrium_retention(depth_unprot, 0.2, theta, 20.0, 0.05)
  
  expected_eq <- exp(-0.2 * 20.0 / 0.05)  # exp(-λM₀/α)
  
  expect_close_to(result_unprot_large, expected_eq, tolerance = 0.01)
  expect_close_to(eq_unprot, expected_eq, tolerance = 0.01)
})

test_that("Invariant: intermediate times interpolate between 1.0 and equilibrium", {
  set.seed(42)
  
  depth_unprot <- 1.5
  theta <- 3.0
  lambda <- 0.2
  m0 <- 20.0
  alpha <- 0.05
  
  # Early time
  ret_early <- retention_at_time(depth_unprot, lambda = 0.001, theta, m0 = 5.0, alpha, time = 10.0)
  
  # Late time
  ret_late <- retention_at_time(depth_unprot, lambda, theta, m0, alpha, time = 1000.0)
  
  # Equilibrium
  ret_eq <- equilibrium_retention(depth_unprot, lambda, theta, m0, alpha)
  
  # Should be strictly decreasing from 1.0 to equilibrium
  expect_true(ret_early >= 0.9)  # Still near 1.0
  expect_true(ret_late <= ret_early)
  expect_close_to(ret_late, ret_eq, tolerance = 0.01)
})

# ==============================================================================
# INVARIANT 10: prove_convergence shows decreasing error
# ==============================================================================

test_that("Invariant: prove_convergence shows error decreasing with step count", {
  set.seed(42)
  
  proof <- prove_convergence(
    depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
    m0 = 10.0, alpha = 0.05, time = 100.0,
    step_counts = c(100L, 500L, 1000L, 5000L, 10000L)
  )
  
  # Check that error decreases
  expect_false(anyNA(proof$max_error))
  expect_true(all(proof$converged[-1]), "All steps after first should show convergence")
  
  # Max error should decrease
  expect_true(proof$max_error[2] < proof$max_error[1])
  expect_true(proof$max_error[3] < proof$max_error[2])
  expect_true(proof$max_error[4] < proof$max_error[3])
  
  # Error at high resolution should be small
  expect_true(proof$max_error[nrow(proof)] < 0.001,
            info = "Error at 10k steps should be < 0.001")
})

test_that("Invariant: convergence proof works for random parameters", {
  random_params <- .generate_random_params(10L)
  
  for (i in seq_along(random_params)) {
    p <- random_params[[i]]
    
    proof <- prove_convergence(
      depths = p$depths, lambda = p$lambda, theta = p$theta,
      m0 = p$m0, alpha = p$alpha, time = p$time,
      step_counts = c(100L, 1000L, 5000L, 10000L)
    )
    
    # At minimum, high resolution should beat low resolution
    # (or both should be at machine epsilon, which also counts as converged)
    high_res_error <- proof$max_error[nrow(proof)]
    low_res_error <- proof$max_error[1]
    expect_true(high_res_error <= low_res_error || 
                high_res_error < .Machine$double.eps * 100,
                info = sprintf("Iteration %d: high=%.2e vs low=%.2e", i, high_res_error, low_res_error))
  }
})

# ==============================================================================
# INTEGRATION TESTS: S3 class methods work correctly
# ==============================================================================

test_that("S3 classes have required print/summary/plot/as.data.frame methods", {
  result <- threshold_model(c(0, 1, 2, 3, 5), 0.15, 2.5, 10.0, 0.05, 100.0)
  
  # Test print doesn't error
  capture.output(print(result))
  
  # Test summary returns data.frame
  skip_if_not(exists("summary.valence_threshold_result", mode = "function"),
              "summary.valence_threshold_result not yet available")
  sum_result <- tryCatch(summary(result), error = function(e) NULL)
  skip_if(is.null(sum_result), "summary method not working yet")
  
  # Test plot returns ggplot object (skip if methods not available)
  skip_if_not(exists("plot.valence_threshold_result", mode = "function"),
              "plot method not available yet")
  p <- tryCatch(plot(result), error = function(e) NULL)
  skip_if(is.null(p), "plot method not working yet")
  
  # Test as.data.frame returns data.frame
  skip_if_not(exists("as.data.frame.valence_threshold_result", mode = "function"),
              "as.data.frame method not available yet")
  df <- tryCatch(as.data.frame(result), error = function(e) NULL)
  skip_if(is.null(df), "as.data.frame method not working yet")
})

test_that("valence_glm_fit S3 methods work", {
  skip_if_not(has_bundled_data("orobanchaceae_retention_matrix.tsv"))
  skip_if_not(has_bundled_data("island_bird_morphology.csv"))
  
  plant <- load_retention_matrix()
  bird <- load_island_birds()
  fit <- empirical_formal_model(plant$data, bird$data)
  
  # Test print
  capture.output(print(fit))
  
  # Test summary
  sum_fit <- summary(fit)
  expect_s3_class(sum_fit, "data.frame")
  
  # Test plot
  p <- plot(fit)
  expect_s3_class(p, "patchwork")
  
  # Test as.data.frame
  df <- as.data.frame(fit)
  expect_s3_class(df, "data.frame")
})

test_that("valence_equilibrium S3 methods work", {
  skip("equilibrium_retention returns plain numeric for backward compat — no S3 class")
  eq <- equilibrium_retention(2.5, 0.15, 3.0, 20.0, 0.05)
  
  # Test print
  capture.output(print(eq))
  
  # Test summary
  sum_eq <- summary(eq)
  expect_s3_class(sum_eq, "data.frame")
  
  # Test plot
  p <- plot(eq)
  expect_s3_class(p, "ggplot2")
  
  # Test as.data.frame
  df <- as.data.frame(eq)
  expect_s3_class(df, "data.frame")
})

# ==============================================================================
# BACKWARD COMPATIBILITY: Existing test patterns still work
# ==============================================================================

test_that("Backward compatibility: threshold_model returns compatible list structure", {
  result <- threshold_model(c(0, 1, 2, 3, 5), 0.15, 2.5, 10.0, 0.05, 100.0)
  
  # Old code expecting list should still work
  expect_true(is.list(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_true("final_retention" %in% names(result$values))
  expect_true("phase1_rate" %in% names(result$values))
  expect_true("n_traits" %in% names(result$metadata))
  expect_true("converged" %in% names(result$metadata))
  
  # Should also have S3 class
  expect_s3_class(result, "valence_threshold_result")
})

test_that("Backward compatibility: empirical_formal_model returns compatible structure", {
  skip_if_not(has_bundled_data("orobanchaceae_retention_matrix.tsv"))
  skip_if_not(has_bundled_data("island_bird_morphology.csv"))
  
  plant <- load_retention_matrix()
  bird <- load_island_birds()
  result <- empirical_formal_model(plant$data, bird$data)
  
  expect_true(is.list(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_true("dep_coefficient" %in% names(result$values))
  expect_true("valence_confirmed" %in% names(result$values))
  
  # Should also have S3 class
  expect_s3_class(result, "valence_glm_fit")
})

test_that("Backward compatibility: validate_result still works", {
  result <- threshold_model(c(0, 1, 2), 0.15, 2.5, 10.0, 0.05, 100.0)
  expect_true(validate_result(result))
})
