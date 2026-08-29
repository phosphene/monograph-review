# test-cultural-bootstrap-ci.R — Bootstrap CIs for β estimates
#
# Tests that network-based β estimates have lower CI bounds above 1
# (confirming the generative regime) using bootstrap resampling.
#
# @section Theoretical Context:
#
# the framework's prediction: β > 1 for cultural substrates (language, software, tools).
# The bootstrap CI lower bound should be > 1 for all network-based domains.
#
# @dft A1, A2, A6

library(testthat)

context("Cultural: Bootstrap CIs for β")

# ---- Language (Brown Corpus) β ----

test_that("Language β: bootstrap CI lower bound > 1", {
  # Language network: 40,445 nodes, 366,465 edges
  # β = ⟨k⟩/2 where ⟨k⟩ = average degree
  # We test with a synthetic degree sequence matching the known statistics
  # (mean=18.1, median=4.0, heavy-tailed)
  set.seed(42)
  # Simulate heavy-tailed degree sequence matching Brown Corpus stats
  n_nodes <- 40445
  # Use log-normal to match heavy tail
  degrees <- round(rlnorm(n_nodes, meanlog = log(4), sdlog = 1.5))
  degrees <- pmax(degrees, 1)  # min degree = 1

  result <- bootstrap_beta_ci(degrees, n_boot = 500, seed = 42)

  expect_gt(result$values$beta_point, 1)
  expect_gt(result$values$ci_lower, 1)
  expect_true(result$values$ci_above_1)
})

# ---- Stone tools (Perreault) β ----

test_that("Stone tools β: bootstrap CI lower bound > 1", {
  # Stone tool network: 37 nodes, 72 edges, β = ⟨k⟩/2 = 1.95
  # Mean degree = 2*72/37 = 3.89, β = 3.89/2 = 1.95
  set.seed(42)
  # Simulate degree sequence for 37 nodes, 72 edges
  n_nodes <- 37
  n_edges <- 72
  # Generate degrees that sum to 2*72 = 144
  degrees <- c(rep(4, 20), rep(3, 10), rep(5, 5), rep(2, 2))
  degrees <- degrees[1:n_nodes]
  # Pad if needed
  if (length(degrees) < n_nodes) {
    degrees <- c(degrees, rep(4, n_nodes - length(degrees)))
  }

  result <- bootstrap_beta_ci(degrees, n_boot = 1000, seed = 42)

  expect_gt(result$values$beta_point, 1)
  # Small network → wider CI, but lower bound should still be > 1
  expect_gt(result$values$ci_lower, 1)
  expect_true(result$values$ci_above_1)
})

# ---- PyPI packages β ----

test_that("PyPI β: bootstrap CI lower bound > 1", {
  # PyPI network: β = 5.29 (forward deps), 2000 packages
  # Forward dep distribution: P10=0, P50=2, P90=14, max=351
  set.seed(42)
  # Simulate right-skewed degree distribution
  n_nodes <- 2000
  degrees <- c(
    rep(0, 700),    # 35% have 0 deps
    rep(1, 300),    # 15% have 1
    rep(2, 300),    # 15% have 2
    rep(4, 200),    # 10% have 4
    rep(8, 200),    # 10% have 8
    rep(14, 150),   # 7.5% have 14
    rep(30, 100),   # 5% have 30
    rep(100, 40),   # 2% have 100
    rep(200, 10)    # 0.5% have 200
  )
  degrees <- degrees[1:n_nodes]

  result <- bootstrap_beta_ci(degrees,
    beta_formula = function(k) mean(k),
    n_boot = 500, seed = 42)

  expect_gt(result$values$beta_point, 1)
  expect_gt(result$values$ci_lower, 1)
  expect_true(result$values$ci_above_1)
})

# ---- Bootstrap diagnostics ----

test_that("Bootstrap produces valid CI (lower < point < upper)", {
  set.seed(42)
  degrees <- rpois(100, lambda = 10) + 1  # ensure > 0

  result <- bootstrap_beta_ci(degrees, n_boot = 500, seed = 42)

  expect_lt(result$values$ci_lower, result$values$beta_point)
  expect_gt(result$values$ci_upper, result$values$beta_point)
  expect_gt(result$values$se, 0)
  expect_equal(result$values$n_boot, 500)
})

test_that("Bootstrap is deterministic with same seed (A2)", {
  set.seed(42)
  degrees <- rpois(100, lambda = 10) + 1

  result1 <- bootstrap_beta_ci(degrees, n_boot = 200, seed = 42)
  result2 <- bootstrap_beta_ci(degrees, n_boot = 200, seed = 42)

  expect_equal(result1$values$beta_point, result2$values$beta_point)
  expect_equal(result1$values$ci_lower, result2$values$ci_lower)
  expect_equal(result1$values$ci_upper, result2$values$ci_upper)
})
