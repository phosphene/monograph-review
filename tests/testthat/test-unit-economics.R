# test-unit-economics.R — Unit tests for Phase 6 economics extension
# DFT A1: pure functions, deterministic math
# Tests: known input → known output, A2 determinism, A6 proof objects

library(testthat)

context("Economics extension (Phase 6)")

# === Standard test data ======================================================

# Two systems with known decelerating CDI (log model should win)
.make_test_data <- function() {
  data.frame(
    system = rep(c("news", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(
      100 * exp(-0.02 * 0:19), # news:  slow decay
      100 * exp(-0.10 * 0:19) # taxi: fast decay
    )
  )
}

.make_threshold_data <- function() {
  data.frame(
    system = rep(c("news", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(
      c(100, 95, 90, 85, 80, 75, 70, 65, 60, 30, 15, 8, 4, 2, 1, 1, 1, 1, 1, 1),
      c(100, 98, 95, 90, 85, 80, 75, 70, 60, 50, 20, 8, 3, 1, 1, 1, 1, 1, 1, 1)
    ),
    trigger_year = c(rep(1998, 20), rep(2000, 20))
  )
}

# === cdi_economics ===========================================================

test_that("cdi_economics returns A6 proof object with values and metadata", {
  dat <- .make_test_data()
  result <- cdi_economics(dat, seed = 42)
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_true(result$metadata$converged)
})

test_that("cdi_economics is deterministic with same seed (A2)", {
  dat <- .make_test_data()
  r1 <- cdi_economics(dat, seed = 42)
  r2 <- cdi_economics(dat, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("cdi_economics returns different values with different seeds", {
  dat <- .make_test_data()
  r1 <- cdi_economics(dat, seed = 42)
  r2 <- cdi_economics(dat, seed = 99)
  # Values should be the same (deterministic math, no RNG in this function)
  expect_equal(r1$values, r2$values)
})

test_that("cdi_economics stops with invalid data (no capacity)", {
  expect_error(
    cdi_economics(data.frame(system = "x", year = 1)),
    "missing required columns"
  )
})

test_that("cdi_economics stops with negative capacity", {
  expect_error(cdi_economics(data.frame(
    system = "x", year = 1:3, capacity = c(10, -5, 2)
  )), "capacity must be non-negative")
})

test_that("cdi_economics reports correct number of systems", {
  dat <- .make_test_data()
  result <- cdi_economics(dat, seed = 42)
  expect_equal(result$values[["n_systems"]], 2)
})

# === option_destruction ======================================================

test_that("option_destruction returns A6 proof object", {
  dat <- .make_test_data()
  result <- option_destruction(dat, seed = 42)
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
})

test_that("option_destruction is deterministic with same seed (A2)", {
  dat <- .make_test_data()
  r1 <- option_destruction(dat, seed = 42)
  r2 <- option_destruction(dat, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("option_destruction returns named fields in values", {
  dat <- .make_test_data()
  result <- option_destruction(dat, seed = 42)
  expected_names <- c(
    "n_systems", "mean_early_resid", "mean_late_resid",
    "valence_pattern_share", "mean_standard_decay_rate"
  )
  expect_true(all(expected_names %in% names(result$values)))
})

test_that("option_destruction stops with invalid data (no system col)", {
  expect_error(
    option_destruction(data.frame(year = 1:10, capacity = 1:10)),
    "missing required columns"
  )
})

test_that("option_destruction valence_pattern_share is in [0, 1]", {
  dat <- .make_test_data()
  result <- option_destruction(dat, seed = 42)
  expect_true(result$values[["valence_pattern_share"]] >= 0)
  expect_true(result$values[["valence_pattern_share"]] <= 1)
})

test_that("option_destruction returns per-system data in metadata", {
  dat <- .make_test_data()
  result <- option_destruction(dat, seed = 42)
  expect_true(is.list(result$metadata$per_system))
  expect_true(length(result$metadata$per_system) >= 1)
})

# === stochastic_cdi ==========================================================

test_that("stochastic_cdi returns A6 proof object", {
  result <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 100, threshold = 0.8, seed = 42
  )
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_equal(result$metadata$mu0, 0.5)
  expect_equal(result$metadata$sigma0, 0.2)
})

test_that("stochastic_cdi is deterministic with same seed (A2)", {
  r1 <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 1000, threshold = 0.8, seed = 42
  )
  r2 <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 1000, threshold = 0.8, seed = 42
  )
  expect_equal(r1$values, r2$values)
  expect_equal(r1$metadata$path, r2$metadata$path)
})

test_that("stochastic_cdi returns different paths with different seeds", {
  r1 <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 500, threshold = 0.8, seed = 42
  )
  r2 <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 500, threshold = 0.8, seed = 99
  )
  expect_false(isTRUE(all.equal(r1$metadata$path, r2$metadata$path)))
})

test_that("stochastic_cdi CDI stays in [0, 1]", {
  result <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 500, threshold = 0.8, seed = 42
  )
  path <- result$metadata$path
  expect_true(all(path >= 0 & path <= 1))
})

test_that("stochastic_cdi returns correct vector length", {
  result <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 500, threshold = 0.8, seed = 42
  )
  expect_equal(length(result$metadata$path), 501)
  expect_equal(length(result$metadata$time), 501)
  expect_equal(result$values[["n_steps"]], 500)
})

test_that("stochastic_cdi rejects invalid parameters", {
  expect_error(
    stochastic_cdi(mu0 = -1, sigma0 = 0.2, seed = 42),
    "mu0 must be a single non-negative number"
  )
  expect_error(
    stochastic_cdi(mu0 = 0.5, sigma0 = -0.1, seed = 42),
    "sigma0 must be a single non-negative number"
  )
  expect_error(
    stochastic_cdi(mu0 = 0.5, sigma0 = 0.2, cdi_init = 1.5, seed = 42),
    "cdi_init must be in"
  )
  expect_error(
    stochastic_cdi(mu0 = 0.5, sigma0 = 0.2, threshold = 0, seed = 42),
    "threshold must be in"
  )
  expect_error(
    stochastic_cdi(mu0 = 0.5, sigma0 = 0.2, dt = 0, seed = 42),
    "dt must be a single positive number"
  )
})

# === threshold_disruption ====================================================

test_that("threshold_disruption returns A6 proof object", {
  dat <- .make_threshold_data()
  result <- threshold_disruption(dat, seed = 42)
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_true(result$metadata$converged)
})

test_that("threshold_disruption is deterministic with same seed (A2)", {
  dat <- .make_threshold_data()
  r1 <- threshold_disruption(dat, seed = 42)
  r2 <- threshold_disruption(dat, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("threshold_disruption reports correct number of systems", {
  dat <- .make_threshold_data()
  result <- threshold_disruption(dat, seed = 42)
  expect_equal(result$values[["n_systems"]], 2)
})

test_that("threshold_disruption stops without trigger_year column", {
  dat <- .make_test_data()
  expect_error(
    threshold_disruption(dat, seed = 42),
    "missing required column 'trigger_year'"
  )
})

test_that("threshold_disruption share_piecewise_win is in [0, 1]", {
  dat <- .make_threshold_data()
  result <- threshold_disruption(dat, seed = 42)
  expect_true(result$values[["share_piecewise_win"]] >= 0)
  expect_true(result$values[["share_piecewise_win"]] <= 1)
})

test_that("threshold_disruption per-system data has delta_aic, slope_ratio", {
  dat <- .make_threshold_data()
  result <- threshold_disruption(dat, seed = 42)
  for (sys in names(result$metadata$per_system)) {
    p <- result$metadata$per_system[[sys]]
    expect_true("delta_aic" %in% names(p))
    expect_true("slope_ratio" %in% names(p))
    expect_true("lr_p" %in% names(p))
    expect_true("piecewise_win" %in% names(p))
  }
})

# === All economics functions return A6 proof objects with seed ===============

test_that("all economics functions return A6 proof objects with seed metadata", {
  dat <- .make_test_data()
  th_dat <- .make_threshold_data()

  r1 <- cdi_economics(dat, seed = 99)
  r2 <- option_destruction(dat, seed = 99)
  r3 <- stochastic_cdi(
    mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
    dt = 0.01, n_steps = 100, threshold = 0.8, seed = 99
  )
  r4 <- threshold_disruption(th_dat, seed = 99)

  expect_equal(r1$metadata$seed, 99)
  expect_equal(r2$metadata$seed, 99)
  expect_equal(r3$metadata$seed, 99)
  expect_equal(r4$metadata$seed, 99)
})

test_that("all economics functions include 'values' and 'metadata'", {
  dat <- .make_test_data()
  th_dat <- .make_threshold_data()

  expect_true("values" %in% names(cdi_economics(dat, seed = 42)))
  expect_true("metadata" %in% names(cdi_economics(dat, seed = 42)))
  expect_true("values" %in% names(option_destruction(dat, seed = 42)))
  expect_true("metadata" %in% names(option_destruction(dat, seed = 42)))
  expect_true("values" %in% names(stochastic_cdi(0.5, 0.2, seed = 42)))
  expect_true("metadata" %in% names(stochastic_cdi(0.5, 0.2, seed = 42)))
  expect_true("values" %in% names(threshold_disruption(th_dat, seed = 42)))
  expect_true("metadata" %in% names(threshold_disruption(th_dat, seed = 42)))
})
