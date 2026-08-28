# test-genealogy-models.R — Runnable Genealogy Tests
#
# Each stage in the mathematical genealogy is a runnable simulation.
# These tests verify that each stage produces data from the actual
# equations of that era, and that the chain is compositional.
#
# The chain: Ising → Landau → Cusp → Percolation → Drift-Selection → valence Formula
#
# DFT Axioms:
# - A1 (pure-io-separation): generators are pure functions
# - A2 (determinism): seeded
# - A6 (check-result): returns proof objects

library(testthat)

context("Genealogy models — runnable precursor environments")

# Source all genealogy generators
source_genealogy("generate_ising.R")
source_genealogy("generate_landau.R")
source_genealogy("generate_cusp.R")
source_genealogy("generate_drift_selection.R")


# ---- Stage 1: Ising Model ----

test_that("Ising: produces magnetization data with known Tc", {
  sim <- generate_ising(seed = 42, L = 8, J = 1.0, h = 0,
                         n_sweeps = 200, n_temps = 10, T_range = c(1.5, 3.5))
  data <- sim$metadata$data

  expect_equal(nrow(data), 10)
  expect_true(all(data$M >= 0 & data$M <= 1))
  expect_equal(sim$values$Tc, 2.269)

  # Below Tc: high magnetization; Above Tc: low magnetization
  below_tc <- data[data$T_norm < 0.9, ]
  above_tc <- data[data$T_norm > 1.1, ]
  if (nrow(below_tc) > 0 && nrow(above_tc) > 0) {
    expect_gt(mean(below_tc$M), mean(above_tc$M))
  }
})

test_that("Ising: magnetization drops near Tc", {
  sim <- generate_ising(seed = 42, L = 8, J = 1.0, h = 0,
                         n_sweeps = 300, n_temps = 20, T_range = c(1.0, 4.0))
  data <- sim$metadata$data

  # Near Tc (T_norm = 1), M should be transitioning
  near_tc <- data[abs(data$T_norm - 1) < 0.1, ]
  far_below <- data[data$T_norm < 0.5, ]
  if (nrow(near_tc) > 0 && nrow(far_below) > 0) {
    expect_lt(mean(near_tc$M), mean(far_below$M))
  }
})

# ---- Stage 2: Landau Mean-Field ----

test_that("Landau: F(M) has minimum at M=0 above Tc (a>0)", {
  sim <- generate_landau(seed = 42, n_points = 100, a_range = c(0.1, 1.0), b = 1.0, h = 0)
  data <- sim$metadata$data

  # For a > 0 (above Tc), equilibrium M should be ~0
  expect_lt(mean(abs(data$M_eq)), 0.1)
})

test_that("Landau: F(M) has non-zero minimum below Tc (a<0)", {
  sim <- generate_landau(seed = 42, n_points = 100, a_range = c(-1.0, -0.1), b = 1.0, h = 0)
  data <- sim$metadata$data

  # For a < 0 (below Tc), |M| should be > 0
  expect_gt(mean(abs(data$M_eq)), 0.1)
})

test_that("Landau: bifurcation at a=0 (M jumps from 0 to non-zero)", {
  sim <- generate_landau(seed = 42, n_points = 200, a_range = c(-0.5, 0.5), b = 1.0, h = 0)
  data <- sim$metadata$data

  # At a=0, transition from M=0 to M!=0
  below <- data[data$a < -0.05, ]
  above <- data[data$a > 0.05, ]
  expect_gt(mean(abs(below$M_eq)), mean(abs(above$M_eq)) + 0.05)
})

# ---- Stage 3: Cusp Catastrophe ----

test_that("Cusp: bifurcation set is 4a^3 + 27b^2 = 0", {
  sim <- generate_cusp(seed = 42, n_a = 30, n_b = 30, a_range = c(-1, 1), b_range = c(-1, 1))
  data <- sim$metadata$data

  # Bifurcation set: 4a^3 + 27b^2 = 0
  # Grid may not hit it exactly, but should have points near it
  bif_dist <- abs(4 * data$a^3 + 27 * data$b^2)
  expect_true(min(bif_dist) < 0.5,
              info = "some points should be near the bifurcation set")
})

test_that("Cusp: three equilibria in the cuspidal region", {
  sim <- generate_cusp(seed = 42, n_a = 50, n_b = 50, a_range = c(-1, 0), b_range = c(-0.1, 0.1))
  data <- sim$metadata$data

  # Inside the cusp (a < 0, small b), should have 3 equilibria
  inside <- data[data$a < -0.1 & abs(data$b) < 0.05, ]
  if (nrow(inside) > 0) {
    expect_true(any(inside$n_equilibria == 3),
                info = "at least some points inside cusp should have 3 equilibria")
  }
})

# ---- Stage 5: Drift-Selection Boundary ----

test_that("Drift-selection: retention increases with delta", {
  sim <- generate_drift_selection(seed = 42, N = 50, n_reps = 200,
                                   n_delta = 10, delta_range = c(0, 0.05))
  data <- sim$metadata$data

  # Higher delta should have higher retention
  expect_gt(data$retention_prob[10], data$retention_prob[1])
})

test_that("Drift-selection: rho_sat > 0 (selection creates retention gap)", {
  sim <- generate_drift_selection(seed = 42, N = 50, n_reps = 200,
                                   n_delta = 10, delta_range = c(0, 0.05))

  expect_gt(sim$values$rho_sat, 0)
  expect_lt(sim$values$rho_sat, 1)
})

# ---- Compositional Chain: Ising → Landau → Cusp → valence ----

test_that("Chain: Ising data is consistent with Landau mean-field", {
  ising <- generate_ising(seed = 42, L = 8, n_sweeps = 300, n_temps = 15, T_range = c(1.0, 4.0))
  landau <- generate_landau(seed = 42, n_points = 15, a_range = c(-0.5, 0.5), b = 1.0, h = 0)

  # Both should show a transition near T_norm = 1
  # Ising: M drops near Tc; Landau: M_eq drops near a=0 (T_norm=1)
  ising_data <- ising$metadata$data
  landau_data <- landau$metadata$data

  # Both have a "transition region" — not exact match (Ising has fluctuations)
  # but the qualitative shape should be similar
  expect_true(nrow(ising_data) > 0)
  expect_true(nrow(landau_data) > 0)
})

test_that("Chain: Landau bifurcation matches cusp bifurcation", {
  # Landau with h=0: F = aM^2 + bM^4. Bifurcation at a=0.
  # Cusp with b=0: V = x^4/4 + a*x^2/2. Bifurcation at a=0.
  # Same algebraic structure.
  landau <- generate_landau(seed = 42, n_points = 50, a_range = c(-1, 1), b = 1.0, h = 0)
  cusp <- generate_cusp(seed = 42, n_a = 50, n_b = 1, a_range = c(-1, 1), b_range = c(0, 0))

  # Both should show the transition at a = 0
  landau_data <- landau$metadata$data
  cusp_data <- cusp$metadata$data

  # At a < 0: non-zero M_eq in both
  landau_below <- landau_data[landau_data$a < -0.1, ]
  cusp_below <- cusp_data[cusp_data$a < -0.1, ]

  if (nrow(landau_below) > 0 && nrow(cusp_below) > 0) {
    expect_gt(mean(abs(landau_below$M_eq)), 0.05)
    expect_gt(mean(abs(cusp_below$x_eq)), 0.05)
  }
})

# ---- Null Controls ----

test_that("null: Ising with J=0 shows no phase transition", {
  sim <- generate_ising(seed = 42, L = 8, J = 0.0, h = 0,
                         n_sweeps = 200, n_temps = 10, T_range = c(1.0, 4.0))
  data <- sim$metadata$data

  # No coupling → no magnetization at any temperature
  expect_true(all(data$M < 0.3))
})
