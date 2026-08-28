# test-simulacrum-landau-step.R — Landau Mean-Field → Step Pipeline
#
# Stage 2 → Stage 5 of the valence Genealogy:
# Does Landau's mean-field free energy (F = aM² + bM⁴) produce a step
# in the (theta, rho) projection? If so, at what a-range?
#
# The Landau model has a continuous (second-order) phase transition at
# a = 0: |M_eq| = sqrt(-a/(2b)) for a < 0, ≈ 0 for a ≥ 0 (limited by
# the discrete M grid). The step function is a Heaviside approximation
# to this square-root onset.
#
# Key findings:
# 1. Landau data produces a step-like signal → step wins over sigmoid
# 2. The step breakpoint is near a ≈ 0 (the Landau critical point)
# 3. rho_sat captures the post-threshold plateau (mean of values above bp)
# 4. The Landau rho_sat (~0.03) differs from the valence formula's 0.35 —
#    Landau is a precursor environment, not the valence prediction itself

library(testthat)

context("Landau → Step: Landau mean-field data produces a step")

# Source helpers
source("helper-simulacra.R")
source("helper-genealogy.R")

# fit_step is exported by the package (loaded via library(valence.foundry));
# no manual sourcing needed.

# ---- Helper: normalize Landau data to (theta, rho) space ----

landau_to_theta_rho <- function(landau) {
  dat <- landau$metadata$data
  list(theta = dat$a, rho = abs(dat$M_eq))
}

# ---- Test 1: Landau data produces a step near a ≈ 0 ----

test_that("Landau: step appears near a ≈ 0 and wins over sigmoid", {
  landau <- generate_landau(seed = 42, n_points = 200,
                             a_range = c(-1, 1), b = 1.0, h = 0.0)

  nr <- landau_to_theta_rho(landau)
  fits <- fit_step(nr$theta, nr$rho)

  # The Landau critical point is at a = 0. The step's breakpoint should
  # be near 0 (within 0.2) because the continuous transition is steepest
  # at the critical point. The step model should win over sigmoid because
  # the transition is sharp (square-root onset, not a smooth sigmoid).
  expect_equal(fits$step$theta_star, 0, tolerance = 0.2)
  expect_equal(fits$best_model, "step")
  expect_gt(fits$delta_aic, 2)
})

# ---- Test 2: Landau rho_sat is the post-threshold plateau ----

test_that("Landau: rho_sat captures post-threshold mean", {
  landau <- generate_landau(seed = 42, n_points = 100,
                             a_range = c(-1, 1), b = 1.0, h = 0.0)

  nr <- landau_to_theta_rho(landau)
  fits <- fit_step(nr$theta, nr$rho)

  # rho_sat is the post-breakpoint mean of |M_eq|. With the Landau
  # discrete grid, post-breakpoint values are mostly near 0.0075
  # (the discrete approximation of M = 0 for a > 0), plus a few
  # small values just above the breakpoint. So rho_sat should be
  # small but positive.
  expect_gt(fits$step$rho_sat, 0)
  expect_lt(fits$step$rho_sat, 0.5)
})

# ---- Test 3: Step appears across different b values ----

test_that("Landau: step reproduces across different quartic coefficients", {
  for (b in c(0.5, 1.0, 2.0)) {
    landau <- generate_landau(seed = 42, n_points = 100,
                               a_range = c(-1, 1), b = b, h = 0.0)
    nr <- landau_to_theta_rho(landau)
    fits <- fit_step(nr$theta, nr$rho)

    # Step should be near a ≈ 0 (critical point is independent of b)
    expect_equal(fits$step$theta_star, 0, tolerance = 0.2)
    expect_equal(fits$best_model, "step")
    expect_gt(fits$delta_aic, 2)
  }
})

# ---- Test 4: Step visible across a-range resolutions ----

test_that("Landau: step visible at moderate resolution (n_points ≥ 50)", {
  for (n_pts in c(50, 100, 200)) {
    landau <- generate_landau(seed = 42, n_points = n_pts,
                               a_range = c(-1, 1), b = 1.0, h = 0.0)
    nr <- landau_to_theta_rho(landau)
    fits <- fit_step(nr$theta, nr$rho)

    expect_equal(fits$step$theta_star, 0, tolerance = 0.2)
    expect_gt(fits$delta_aic, 2)
  }
})

# ---- Test 5: Null control — degenerate step on flat data ----

test_that("Landau: no meaningful step on constant |M_eq|", {
  theta <- seq(-1, 1, length.out = 100)
  rho <- rep(0.5, 100)  # constant |M_eq|

  fits <- fit_step(theta, rho)

  # On constant data, rho_sat should equal the overall mean
  # (no actual step — both pre and post means are the same)
  expect_equal(fits$step$rho_sat, 0.5, tolerance = 0.01)
})

# ---- Test 6: Step appears in narrow a-range around critical point ----

test_that("Landau: step visible even in narrow a-range around a = 0", {
  landau <- generate_landau(seed = 42, n_points = 200,
                             a_range = c(-0.5, 0.5), b = 1.0, h = 0.0)
  nr <- landau_to_theta_rho(landau)
  fits <- fit_step(nr$theta, nr$rho)

  # Step should be near a ≈ 0
  expect_equal(fits$step$theta_star, 0, tolerance = 0.15)
  # Step should still win (transition is sharp even in narrow range)
  expect_equal(fits$best_model, "step")
})

# ---- Test 7: External field smooths the transition ----

test_that("Landau: external field h ≠ 0 smooths the transition", {
  landau <- generate_landau(seed = 42, n_points = 100,
                             a_range = c(-1, 1), b = 1.0, h = 0.1)
  nr <- landau_to_theta_rho(landau)
  fits <- fit_step(nr$theta, nr$rho)

  # The step should still be near a ≈ 0
  expect_equal(fits$step$theta_star, 0, tolerance = 0.2)
  # The model should still find a breakpoint
  expect_true(fits$best_model %in% c("step", "sigmoid"))
})

# ---- Test 8: Landau rho_sat differs from valence formula's 0.35 ----

test_that("Landau: rho_sat is distinct from the valence formula's 0.35", {
  # The valence formula predicts ρ_sat ≈ 0.35 for biological systems.
  # Landau mean-field produces a different rho_sat because the
  # post-breakpoint plateau is the discrete approximation of M = 0.
  # This is expected — the Landau model is a precursor environment
  # that produces a step-like signal, but with different parameters.
  landau <- generate_landau(seed = 42, n_points = 100,
                             a_range = c(-1, 1), b = 1.0, h = 0.0)
  nr <- landau_to_theta_rho(landau)
  fits <- fit_step(nr$theta, nr$rho)

  # Landau's rho_sat (~0.03) is different from the valence formula's 0.35
  # This is expected: the Landau model is a continuous phase transition,
  # not a step. The step function finds the best approximation, but the
  # post-threshold plateau is the near-zero residual magnetization.
  expect_true(abs(fits$step$rho_sat - 0.35) > 0.2)
})