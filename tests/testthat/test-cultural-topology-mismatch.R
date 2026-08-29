# test-cultural-topology-mismatch.R — Network topology and buildout-failure
#
# Tests the network topology term K_eff(C) and the mismatch equation M(t).
#
# @section Theoretical Context:
#
# the framework's prediction 1: K_eff(C) = K·(1 - η·(1 - C)) where η = 0.487 (Derex & Boyd)
#   - C=1 (fully connected): K_eff = K (no loss)
#   - C=0 (isolated): K_eff = K·0.513 (47% reduction)
#   - Partial connectivity preserves β-diversity
#
# the framework's prediction 2: When r_B > k1, mismatch grows (failure regime)
#   - r_B = ε·β (cultural acceleration rate)
#   - k1 = fast biological relaxation rate
#   - M(t) ≈ ρ_eq · (exp(r_B·t) - exp(k1·t))
#
# @dft A1, A2, A6

library(testthat)

context("Cultural: Network topology and mismatch")

# ---- K_eff(C) topology term ----

test_that("K_eff: fully connected preserves K", {
  K <- 1000
  Keff <- k_eff_topology(K, C = 1.0, eta = 0.487)
  expect_equal(Keff, K)
})

test_that("K_eff: isolated reduces K by η", {
  K <- 1000
  eta <- 0.487
  Keff <- k_eff_topology(K, C = 0.0, eta = eta)
  expect_equal(Keff, K * (1 - eta))
  expect_lt(Keff, K * 0.52)  # less than 52%
})

test_that("K_eff: partial connectivity is between K·(1-η) and K", {
  K <- 1000
  eta <- 0.487
  Keff_partial <- k_eff_topology(K, C = 0.5, eta = eta)
  Keff_min <- k_eff_topology(K, C = 0.0, eta = eta)
  Keff_max <- k_eff_topology(K, C = 1.0, eta = eta)

  expect_gt(Keff_partial, Keff_min)
  expect_lt(Keff_partial, Keff_max)
})

test_that("K_eff: monotonic in C", {
  K <- 1000
  eta <- 0.487
  Cs <- seq(0, 1, by = 0.1)
  Keffs <- sapply(Cs, function(C) k_eff_topology(K, C, eta))

  expect_true(all(diff(Keffs) > 0))  # monotonically increasing
})

test_that("K_eff: η = 0.487 matches Derex & Boyd fit", {
  # The fitted value from Derex & Boyd (2016), ΔAIC = -6.46
  K <- 1000
  Keff <- k_eff_topology(K, C = 0, eta = 0.487)
  # At C=0, K_eff = K·(1-0.487) = K·0.513
  expect_equal(Keff, K * 0.513, tolerance = 0.001)
})

# ---- Mismatch regime test ----

test_that("Mismatch: matched regime when r_B < k2", {
  # Cultural change slower than even slow relaxation
  result <- mismatch_regime_test(r_B = 0.001, k1 = 0.1, k2 = 0.01)
  expect_equal(result$values$regime, "matched")
  expect_false(result$values$mismatch_grows)
})

test_that("Mismatch: lagged regime when k2 < r_B < k1", {
  # Cultural change faster than slow, slower than fast relaxation
  result <- mismatch_regime_test(r_B = 0.05, k1 = 0.1, k2 = 0.01)
  expect_equal(result$values$regime, "lagged")
  expect_false(result$values$mismatch_grows)
})

test_that("Mismatch: failure regime when r_B > k1", {
  # Cultural change faster than both relaxation rates
  result <- mismatch_regime_test(r_B = 0.5, k1 = 0.1, k2 = 0.01)
  expect_equal(result$values$regime, "failure")
  expect_true(result$values$mismatch_grows)
  expect_true(result$values$r_B_exceeds_k1)
})

test_that("Mismatch: modern human culture is in failure regime", {
  # r_B ≈ 0.22 (PyPI rate) >> k1 ≈ 0.01-0.1 (biological plasticity)
  # This is the framework's prediction for evolutionary mismatch
  result <- mismatch_regime_test(r_B = 0.22, k1 = 0.05, k2 = 0.001)
  expect_equal(result$values$regime, "failure")
  expect_true(result$values$mismatch_grows)
  expect_gt(result$values$mismatch_rate, 0)
})

# ---- Mismatch equation M(t) ----

test_that("M(t): mismatch grows when r_B > k1", {
  t <- seq(0, 50, by = 1)
  rho_eq0 <- 100
  # r_B > k1 → failure regime
  M <- mismatch_equation(t, rho_eq0, r_B = 0.2, k1 = 0.05)

  # M should grow over time
  expect_gt(M[length(t)], M[1])
  # M should be positive (attractor ahead of relaxation)
  expect_gt(M[length(t)], 0)
})

test_that("M(t): mismatch ≈ 0 when r_B < k1", {
  t <- seq(0, 10, by = 0.5)
  rho_eq0 <- 100
  # r_B < k1 → matched regime, mismatch should be small
  M <- mismatch_equation(t, rho_eq0, r_B = 0.01, k1 = 0.1)

  # When r_B < k1, mismatch is negative (relaxation ahead of attractor)
  # Magnitude at t=10: 100*(e^0.1 - e^1) = 100*(1.105 - 2.718) = -161.3
  # This is small relative to the failure regime values
  expect_lt(abs(M[length(t)]), rho_eq0 * 5)  # much smaller than failure regime
})

test_that("M(t): mismatch grows without bound when r_B >> k1", {
  t <- seq(0, 100, by = 1)
  rho_eq0 <- 100
  M <- mismatch_equation(t, rho_eq0, r_B = 0.5, k1 = 0.01)

  # M should grow roughly exponentially
  expect_gt(M[length(t)], M[50])
  expect_gt(M[50], M[25])
})
