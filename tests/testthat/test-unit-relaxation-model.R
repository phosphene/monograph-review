# test-unit-relaxation-model.R — Unit tests for relaxation formula model
# DFT A1: pure math, deterministic, no I/O
# DFT A2: deterministic (no RNG in analytical solution)

library(testthat)

context("Relaxation model")


# === relaxation_analytical ===

test_that("relaxation_analytical: returns rho0 at t = 0", {
  result <- relaxation_analytical(t = 0, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                                   rho1 = 0.3, rho2 = 0.3)
  expect_equal(result, 1.0)
})

test_that("relaxation_analytical: approaches equilibrium as t → ∞", {
  t <- seq(0, 1000, length.out = 100)
  result <- relaxation_analytical(t, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                                   rho1 = 0.3, rho2 = 0.3)
  # Equilibrium: (k1 * rho1 + k2 * rho2) / (k1 + k2)
  # = (0.5 * 0.3 + 0.02 * 0.3) / 0.52 = 0.156 / 0.52 = 0.3
  expect_equal(result[length(result)], 0.3, tolerance = 1e-6)
})

test_that("relaxation_analytical: monotonic decreasing for rho0 > rho_star", {
  t <- seq(0, 100, length.out = 50)
  result <- relaxation_analytical(t, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                                   rho1 = 0.3, rho2 = 0.3)
  # Check monotonic decrease
  expect_true(all(diff(result) <= 0))
})

test_that("relaxation_analytical: handles k2 = 0 (single channel)", {
  result <- relaxation_analytical(t = c(0, 1, 10), rho0 = 1.0, k1 = 0.5, k2 = 0,
                                   rho1 = 0.3, rho2 = 0.3)
  # Single channel: k = 0.5, rho_star = 0.3
  expect_equal(result[1], 1.0)
  expect_gt(result[2], 0.3)
  expect_equal(result[3], relaxation_analytical(10, 1.0, 0.5, 0, 0.3, 0.3))
})

test_that("relaxation_analytical: faster k1 + k2 gives faster decay", {
  t <- 10
  slow <- relaxation_analytical(t, rho0 = 1.0, k1 = 0.1, k2 = 0.01,
                                 rho1 = 0.3, rho2 = 0.3)
  fast <- relaxation_analytical(t, rho0 = 1.0, k1 = 1.0, k2 = 0.1,
                                 rho1 = 0.3, rho2 = 0.3)
  expect_lt(fast, slow)
})

test_that("relaxation_analytical: different rho1, rho2 produce different equilibrium", {
  t <- 1000
  a <- relaxation_analytical(t, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                              rho1 = 0.3, rho2 = 0.3)
  b <- relaxation_analytical(t, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                              rho1 = 0.5, rho2 = 0.1)
  expect_false(isTRUE(all.equal(a, b)))
})


# === relaxation_simulate ===

test_that("relaxation_simulate: returns expected structure", {
  result <- relaxation_simulate(times = seq(0, 100, 1), rho0 = 1.0,
                                 k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3)
  expect_named(result, c("times", "rho", "rho0", "k", "rho_star",
                          "k1", "k2", "rho1", "rho2", "method"))
  expect_equal(length(result$times), length(result$rho))
  expect_equal(result$method, "analytical")
})

test_that("relaxation_simulate: analytical matches closed form", {
  times <- seq(0, 50, 0.5)
  result <- relaxation_simulate(times, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
                                 rho1 = 0.3, rho2 = 0.3)
  expected <- relaxation_analytical(times, 1.0, 0.5, 0.02, 0.3, 0.3)
  expect_equal(result$rho, expected)
})

test_that("relaxation_simulate: errors on fewer than 2 time points", {
  expect_error(relaxation_simulate(times = 1, rho0 = 1.0, k1 = 0.5,
                                    k2 = 0.02, rho1 = 0.3, rho2 = 0.3))
})

test_that("relaxation_simulate: equilibrium is correctly computed", {
  result <- relaxation_simulate(times = c(0, 1000), rho0 = 1.0,
                                 k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3)
  expected_rho_star <- (0.5 * 0.3 + 0.02 * 0.3) / (0.5 + 0.02)
  expect_equal(result$rho_star, expected_rho_star)
  expect_equal(result$rho[length(result$rho)], expected_rho_star, tolerance = 1e-6)
})


# === generate_relaxation_data ===

test_that("generate_relaxation_data: returns expected structure", {
  d <- generate_relaxation_data(seq(0, 10, 0.1), rho0 = 1.0,
                                 k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3,
                                 noise_sd = 0.01, seed = 42)
  expect_named(d, c("data", "params"))
  expect_named(d$data, c("t", "rho_true", "rho_obs"))
  expect_equal(nrow(d$data), 101)
})

test_that("generate_relaxation_data: rho_true is deterministic", {
  d1 <- generate_relaxation_data(seq(0, 10, 0.1), rho0 = 1.0,
                                  k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3,
                                  noise_sd = 0, seed = 42)
  d2 <- generate_relaxation_data(seq(0, 10, 0.1), rho0 = 1.0,
                                  k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3,
                                  noise_sd = 0, seed = 42)
  expect_equal(d1$data$rho_true, d2$data$rho_true)
})

test_that("generate_relaxation_data: noisy data differs from true", {
  d <- generate_relaxation_data(seq(0, 10, 0.1), rho0 = 1.0,
                                 k1 = 0.5, k2 = 0.02, rho1 = 0.3, rho2 = 0.3,
                                 noise_sd = 0.05, seed = 42)
  expect_false(isTRUE(all.equal(d$data$rho_true, d$data$rho_obs)))
})


# === relaxation_phase_analysis ===

test_that("relaxation_phase_analysis: errors on non-biexp result", {
  expect_error(relaxation_phase_analysis(list(not_a_biexp = TRUE)))
})

test_that("relaxation_phase_analysis: returns expected structure", {
  d <- .make_biexp_data(n = 100, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  analysis <- relaxation_phase_analysis(fits)

  expect_named(analysis, c("phase1_rate", "phase2_rate", "rate_ratio",
                            "biphasic", "transition_time", "phase1_amplitude",
                            "phase2_amplitude", "halflife_phase1", "halflife_phase2"))
})

test_that("relaxation_phase_analysis: detects biphasic pattern with k1 >> k2", {
  d <- .make_biexp_data(n = 100, k1 = 17.7, k2 = 0.47, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  analysis <- relaxation_phase_analysis(fits)

  if (fits$biexponential$converged) {
    expect_true(analysis$biphasic)
    expect_gt(analysis$rate_ratio, 2)
  }
})

test_that("relaxation_phase_analysis: phase1 amplitude > phase2 amplitude", {
  d <- .make_biexp_data(n = 100, A1 = 0.03, A2 = 0.01, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  analysis <- relaxation_phase_analysis(fits)

  if (fits$biexponential$converged) {
    expect_gt(analysis$phase1_amplitude, analysis$phase2_amplitude)
  }
})

# ==============================================================================
# RIGOROUS REVISIT (2026-08-28) — biphasic-flag integrity
# See docs/review/fit-biexp-numerical-challenges.md. The biphasic flag must
# not contradict the model-selection layer, must not fire on a spurious
# low-amplitude fast channel, and must still fire on genuine two-channel data.
# ==============================================================================


# ---- biphasic: never contradicts model selection ----

test_that("relaxation_phase_analysis: biphasic requires mono to be rejected", {
  # If the mono model wins on AIC (delta <= 0), the data does not support two
  # timescales and biphasic must be FALSE — even if the fitted ratio exceeds 2.
  for (s in 1:10) {
    d <- .make_monoexp_data(n = 80, seed = s, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    analysis <- relaxation_phase_analysis(fits)
    if (!is.na(fits$delta_aic_bi_mono) && fits$delta_aic_bi_mono <= 0) {
      expect_false(analysis$biphasic)
    }
  }
})


# ---- biphasic: FALSE on one-channel data (spurious fast channel) ----

test_that("relaxation_phase_analysis: no biphasic claim on one-channel data", {
  # Single-exponential data is the negative control. A rate-ratio-only rule
  # fired biphasic=TRUE on ~25% of one-channel seeds (spurious fast channel).
  # The guarded rule should fire on at most a couple in a fixed seed sweep.
  n_biphasic <- 0L
  for (s in 1:10) {
    d <- .make_monoexp_data(n = 80, seed = s, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    analysis <- relaxation_phase_analysis(fits)
    if (isTRUE(analysis$biphasic)) n_biphasic <- n_biphasic + 1L
  }
  expect_lte(n_biphasic, 2L)
})


# ---- biphasic: TRUE on genuine two-channel data ----

test_that("relaxation_phase_analysis: detects genuine biphasic relaxation", {
  # The guarded rule must not suppress real two-timescale structure.
  n_biphasic <- 0L
  for (s in 1:10) {
    d <- .make_biexp_data(n = 100, seed = s, k1 = 17.7, k2 = 0.47, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    analysis <- relaxation_phase_analysis(fits)
    if (isTRUE(analysis$biphasic)) n_biphasic <- n_biphasic + 1L
  }
  expect_gte(n_biphasic, 8L)
})


# ---- phase amplitudes bounded ----

test_that("relaxation_phase_analysis: phase amplitudes bounded in [0, 1]", {
  for (s in 1:10) {
    d <- .make_biexp_data(n = 80, seed = s, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    analysis <- relaxation_phase_analysis(fits)
    if (fits$biexponential$converged) {
      expect_gte(analysis$phase1_amplitude, 0)
      expect_lte(analysis$phase1_amplitude, 1)
      expect_gte(analysis$phase2_amplitude, 0)
      expect_lte(analysis$phase2_amplitude, 1)
    }
  }
})
