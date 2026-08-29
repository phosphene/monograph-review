# test-simulacrum-step-recovery.R — Simulacrum 6: Step Function Recovery
#
# Tests whether the pipeline can:
# 1. Recover rho_sat = 0.35 from noisy step data
# 2. Recover theta_star ~ 0 from noisy step data
# 3. Distinguish a step from a steep sigmoid (discrimination)
# 4. Not produce false positives on null data
# 5. Percolation threshold = 0 on connected networks

library(testthat)

context("Simulacrum 6: Step function recovery")

source_simulacrum("generate_step.R")
source_simulacrum("generate_sigmoid.R")
source_simulacrum("generate_null_rho.R")
source_simulacrum("generate_percolation.R")

# fit_step is exported by the package (loaded via library(valence.foundry))
# and needs no manual sourcing — the relative source below broke under
# covr / installed-package test directories.

# ---- Test 1: Recover rho_sat from clean step data ----

test_that("step recovery: recovers rho_sat from clean step data", {
  sim <- generate_step_function(
    seed = 42, n_pre = 10, n_post = 10,
    rho_sat = 0.35, theta_star = 0, noise_sd = 0
  )
  fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)

  expect_equal(fits$step$rho_sat, 0.35, tolerance = 1e-6)
  expect_lte(abs(fits$step$theta_star), 0.02)
  expect_equal(fits$best_model, "step")
  expect_gt(fits$delta_aic, 0)
})

# ---- Test 2: Recover rho_sat from noisy step data ----

test_that("step recovery: recovers rho_sat from noisy step data", {
  sim <- generate_step_function(
    seed = 42, n_pre = 15, n_post = 15,
    rho_sat = 0.35, theta_star = 0, noise_sd = 0.02
  )
  fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)

  expect_equal(fits$step$rho_sat, 0.35, tolerance = 0.05)
  expect_equal(fits$best_model, "step")
  expect_gt(fits$delta_aic, 0)
})

# ---- Test 3: Distinguish step from steep sigmoid ----

test_that("discrimination: step wins decisively on step data", {
  step_sim <- generate_step_function(
    seed = 42, n_pre = 15, n_post = 15,
    rho_sat = 0.35, noise_sd = 0.01
  )
  step_fits <- fit_step(step_sim$metadata$data$theta, step_sim$metadata$data$rho)

  expect_equal(step_fits$best_model, "step")
  expect_gt(step_fits$delta_aic, 2)
})

# ---- Test 4: Null control — no false positives on flat data ----

test_that("null control: no false step detection on flat data", {
  sim <- generate_null_rho(seed = 42, n = 30, rho_baseline = 0.35, noise_sd = 0.05)
  fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)

  # On flat data, the step's rho_sat (post - pre difference) should be small
  step_effect <- abs(fits$step$rho_sat - mean(sim$metadata$data$rho))
  expect_lt(step_effect, 0.1)
})

# ---- Test 5: Percolation threshold on connected network ----
# FINDING: The percolation threshold is NOT at zero for a general connected
# network. The zero-dependency set Z is empty until provision covers a
# node's entire neighborhood (min degree). This means the proof sketch
# in the genealogy docs has a gap: "connected" does not imply theta* = 0.
# The threshold depends on network structure (min degree, density).

test_that("percolation: threshold is NOT at zero for general connected network", {
  sim <- generate_percolation_network(
    seed = 42, n_nodes = 100,
    p_edge = 0.1, n_provision_levels = 20
  )

  # First provision (1 node) should NOT create non-empty Z
  # because no node's entire neighborhood fits in a 1-node set
  expect_equal(sim$values$first_provision_Z, 0)

  # Z should become non-zero at some provision fraction > 0
  data <- sim$metadata$data
  first_nonzero <- which(data$rho > 0)[1]
  expect_true(!is.na(first_nonzero))
  expect_gt(data$theta[first_nonzero], 0)
})

# ---- Test 6: Percolation threshold varies with network structure ----

test_that("percolation: threshold varies with network density", {
  # Dense network (more edges) should have HIGHER threshold
  # because nodes have more neighbors, need more provision to cover them
  sparse <- generate_percolation_network(
    seed = 42, n_nodes = 50,
    p_edge = 0.05, n_provision_levels = 50
  )
  dense <- generate_percolation_network(
    seed = 42, n_nodes = 50,
    p_edge = 0.3, n_provision_levels = 50
  )

  # Find first non-zero Z for each
  sparse_data <- sparse$metadata$data
  dense_data <- dense$metadata$data
  sparse_first <- sparse_data$theta[which(sparse_data$rho > 0)[1]]
  dense_first <- dense_data$theta[which(dense_data$rho > 0)[1]]

  expect_gt(sparse_first, 0)
  expect_gt(dense_first, 0)
  # Dense network should need more provision (higher threshold)
  expect_gte(dense_first, sparse_first)
})

# ---- Test 7: rho_sat recovery across multiple systems ----

test_that("rho_sat recovery: consistent across multiple synthetic systems", {
  rho_sats <- replicate(10, {
    sim <- generate_step_function(
      seed = sample(1:1000, 1),
      n_pre = 10, n_post = 10,
      rho_sat = 0.35, noise_sd = 0.02
    )
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    fits$step$rho_sat
  })

  mean_rho_sat <- mean(rho_sats)
  expect_equal(mean_rho_sat, 0.35, tolerance = 0.03)
})

# ---- Test 8: Step still wins with moderate noise ----

test_that("discrimination: step wins with moderate noise", {
  sim <- generate_step_function(
    seed = 42, n_pre = 20, n_post = 20,
    rho_sat = 0.35, noise_sd = 0.05
  )
  fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
  expect_equal(fits$best_model, "step")
})
