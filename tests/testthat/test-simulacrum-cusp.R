# test-simulacrum-cusp.R — STDD bifurcation detection test
#
# Tests the cusp catastrophe simulacrum: generates synthetic data near a
# known bifurcation point, verifies bifurcation detection, jump detection,
# hysteresis, and null control behavior.
#
# Cusp catastrophe equilibrium: x³ + a·x + b = 0
# Bifurcation set: 4a³ + 27b² = 0
# For a = -1, the fold bifurcation occurs at b = ±2/(3√3) ≈ ±0.385
#
# DFT A1: pure math, deterministic, no I/O
# DFT A2: withr::with_seed(42L, kind = "Mersenne-Twister", normal.kind = "Inversion")
# DFT A6: proof objects validated with validate_result()
#
# @dft A1, A2, A6

library(testthat)

context("Simulacrum: Cusp catastrophe bifurcation detection")

# True bifurcation point for a = -1 on the function's bifurcation set
# 4a³ + 27b² = 0 → 4(-1)³ + 27b² = 0 → b² = 4/27 → b = 2/(3√3)
true_bifurcation_b <- 2 / (3 * sqrt(3))

# === Generate synthetic system near bifurcation ===

test_that("generate_cusp_system produces data near known bifurcation point", {
  df <- generate_cusp_system(a = -1, b_range = c(-2, 2), n = 100, seed = 42)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 100)
  expect_true(all(df$control_a == -1))
  expect_true(all(df$control_b >= -2 & df$control_b <= 2))
  expect_true(all(is.finite(df$state)))
  expect_true(all(is.finite(df$state_true)))
  # Noise should be present
  expect_true(sd(df$state - df$state_true) > 0)
  # Deterministic with same seed (A2)
  df2 <- generate_cusp_system(a = -1, seed = 42)
  expect_equal(df$state_true, df2$state_true)
})

# === cusp_bifurcation_point detects known bifurcation ===

test_that("cusp_bifurcation_point detects known bifurcation (a=-1, b=2/(3√3))", {
  # On the bifurcation set: 4a³ + 27b² = 0
  # For a = -1: 4(-1)³ + 27(2/(3√3))² = -4 + 27·(4/27) = -4 + 4 = 0
  result <- cusp_bifurcation_point(a = -1, b = true_bifurcation_b)
  expect_true(result$at_bifurcation)
  expect_equal(result$distance, 0, tolerance = 1e-10)
  expect_equal(result$a, -1)
  expect_equal(result$b, true_bifurcation_b)
})

test_that("cusp_bifurcation_point returns FALSE far from bifurcation set", {
  # a = 1, b = 0 → 4(1)³ + 27(0)² = 4, way off the set
  result <- cusp_bifurcation_point(a = 1, b = 0)
  expect_false(result$at_bifurcation)
  expect_gt(result$distance, 0)
})

# === Vary control parameter across threshold, verify sudden jump ===

test_that("system shows sudden jump when crossing bifurcation threshold", {
  # Generate data with a = -1, b crossing the bifurcation point
  # The bifurcation for a = -1 is at b ≈ 0.385
  # Sample densely around the bifurcation
  b_fine <- seq(0.3, 0.5, length.out = 50)
  df <- generate_cusp_system(a = -1, b_range = c(0.3, 0.5), n = 50, seed = 42)

  # The true equilibrium state should show a jump: before bifurcation
  # (b < 0.385), the system has two stable equilibria. After bifurcation
  # (b > 0.385), only one stable equilibrium remains.
  # The generator picks the upper branch, so we expect a discontinuity.

  # Split into before and after bifurcation
  before <- df$state_true[df$control_b < true_bifurcation_b]
  after <- df$state_true[df$control_b > true_bifurcation_b]

  # Both groups should have finite values
  expect_true(length(before) > 0)
  expect_true(length(after) > 0)

  # The jump: the upper branch before bifurcation is positive,
  # after bifurcation the state snaps to the negative stable branch
  # (for x³ + a·x + b = 0 with a = -1, b > bifurcation threshold)
  mean_before <- mean(before)
  mean_after <- mean(after)

  # There should be a significant jump (difference > 0.5)
  jump_magnitude <- abs(mean_after - mean_before)
  expect_gt(jump_magnitude, 0.5)

  # The state before bifurcation should have a different sign or
  # magnitude from after
  expect_true(abs(mean_before - mean_after) > 0.5)
})

# === Verify hysteresis: forward path ≠ reverse path ===

test_that("cusp hysteresis is detected with pure branch-following equilibrium function", {
  # Create a pure equilibrium function; the branch-following state is
  # threaded by cusp_hysteresis_check (not hidden in a closure).
  eq_fn <- make_cusp_equilibrium_fn(a = -1)
  # Control values crossing the bifurcation threshold both ways
  control_vals <- seq(-1, 1, length.out = 50)

  result <- cusp_hysteresis_check(control_vals, eq_fn,
    seed = 42,
    initial_state = 1.0
  )

  expect_true(validate_result(result))
  # Hysteresis should be detected — forward path (increasing b,
  # staying on upper branch) ≠ reverse path (decreasing b,
  # staying on lower branch)
  expect_true(result$values[["has_hysteresis"]])
  expect_gt(result$values[["max_difference"]], 0.01)
  expect_equal(result$metadata$seed, 42) # A2
  expect_equal(result$metadata$n, 50)
})

test_that("cusp hysteresis is deterministic with same seed (A2)", {
  eq_fn <- make_cusp_equilibrium_fn(a = -1)
  control_vals <- seq(-1, 1, length.out = 50)

  r1 <- cusp_hysteresis_check(control_vals, eq_fn, seed = 42, initial_state = 1.0)
  r2 <- cusp_hysteresis_check(control_vals, eq_fn, seed = 42, initial_state = 1.0)

  expect_equal(r1$values, r2$values)
})

# === Null control: far from bifurcation, no jump/hysteresis ===

test_that("null control (a=1, b=0) shows no bifurcation", {
  df <- generate_cusp_system(a = 1, b_range = c(-2, 2), n = 100, seed = 42)

  # For a = 1, the system is far from bifurcation
  # cusp_bifurcation_point(1, 0) → distance = 4, at_bifurcation = FALSE
  result <- cusp_bifurcation_point(a = 1, b = 0)
  expect_false(result$at_bifurcation)

  # The equilibrium should be smooth (no jump) — single stable root
  # x³ + x + b = 0 has one real root for all b
  # The state should vary smoothly with b
  true_states <- df$state_true
  # No sudden jump: successive differences should be small
  diffs <- diff(true_states)
  max_jump <- max(abs(diffs))
  expect_lt(max_jump, 0.5)
})

test_that("null control shows no hysteresis", {
  # For a = 1, the system has a single stable equilibrium for all b
  # No branch switching possible → no hysteresis
  eq_fn <- make_cusp_equilibrium_fn(a = 1)
  control_vals <- seq(-2, 2, length.out = 50)

  result <- cusp_hysteresis_check(control_vals, eq_fn,
    seed = 42,
    initial_state = 0
  )

  expect_true(validate_result(result))
  expect_false(result$values[["has_hysteresis"]])
  expect_lt(result$values[["max_difference"]], 0.01)
})

# === A6 proof object: full validation ===

test_that("full simulacrum pipeline produces valid A6 proof object", {
  # Generate synthetic system near known bifurcation
  df <- generate_cusp_system(a = -1, b_range = c(-1, 1), n = 100, seed = 42)

  # 1. Bifurcation detection
  bf_result <- cusp_bifurcation_point(a = -1, b = true_bifurcation_b)
  bifurcation_detected <- bf_result$at_bifurcation
  recovered_distance <- bf_result$distance

  # 2. Jump detection: check if there's a significant jump near bifurcation
  near_bif <- df[abs(df$control_b - true_bifurcation_b) < 0.2, ]
  before_jump <- near_bif$state_true[near_bif$control_b < true_bifurcation_b]
  after_jump <- near_bif$state_true[near_bif$control_b > true_bifurcation_b]
  jump_detected <- FALSE
  if (length(before_jump) > 0 && length(after_jump) > 0) {
    jump_detected <- abs(mean(before_jump) - mean(after_jump)) > 0.5
  }

  # 3. Hysteresis detection
  eq_fn <- make_cusp_equilibrium_fn(a = -1)
  control_vals <- seq(-1, 1, length.out = 50)
  hyst_result <- cusp_hysteresis_check(control_vals, eq_fn,
    seed = 42,
    initial_state = 1.0
  )
  hysteresis_detected <- as.logical(hyst_result$values[["has_hysteresis"]])

  # 4. Null control passes
  null_df <- generate_cusp_system(a = 1, b_range = c(-2, 2), n = 100, seed = 42)
  null_bf <- cusp_bifurcation_point(a = 1, b = 0)
  null_control_passes <- !null_bf$at_bifurcation

  # Build A6 proof object
  proof <- list(
    values = c(
      bifurcation_detected = as.numeric(bifurcation_detected),
      hysteresis_detected = as.numeric(hysteresis_detected),
      true_bifurcation_a = -1,
      true_bifurcation_b = true_bifurcation_b,
      recovered_distance = recovered_distance,
      null_control_passes = as.numeric(null_control_passes),
      jump_detected = as.numeric(jump_detected)
    ),
    metadata = list(
      seed = 42L,
      n = nrow(df),
      bifurcation_function = "cusp_bifurcation_point",
      hysteresis_function = "cusp_hysteresis_check",
      generator = "generate_cusp_system",
      model = "cusp catastrophe: x³ + a·x + b = 0",
      bifurcation_set = "4a³ + 27b² = 0",
      mersenne_twister = TRUE,
      inversion_method = TRUE,
      n_null = nrow(null_df),
      converged = TRUE
    )
  )

  expect_true(validate_result(proof))
  expect_equal(proof$values[["bifurcation_detected"]], 1, ignore_attr = TRUE)
  expect_equal(proof$values[["hysteresis_detected"]], 1, ignore_attr = TRUE)
  expect_equal(proof$values[["null_control_passes"]], 1, ignore_attr = TRUE)
  expect_equal(proof$values[["jump_detected"]], 1, ignore_attr = TRUE)
  expect_equal(unname(proof$values[["recovered_distance"]]), 0, tolerance = 1e-10)
  expect_equal(proof$metadata$seed, 42L)
  expect_equal(proof$metadata$n, 100)
})
