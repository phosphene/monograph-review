# test-unit-dynamics-classes.R — Contract tests for R/dynamics_classes.R
#
# E1 coverage ticket: dynamics_classes.R was at 49.7%. These tests pin down
# the constructor -> validator -> helper pattern for the dynamics module result
# classes (base dynamics, autocatalytic, cusp, economics, proof) plus the
# coercion helpers and S3 methods — the untested bulk of the file.
#
# DFT A1 (pure) + A6 (check-result): validators reject malformed objects,
# helpers return validated objects, and print/summary/as.data.frame are pure.

library(testthat)
library(valence.foundry)

# ============================================================================
# Base valence_dynamics_result
# ============================================================================

test_that("base dynamics result: helper validates and round-trips", {
  x <- valence_dynamics_result(
    values = list(rho = 0.8), metadata = list(n = 10),
    test_name = "demo", discriminating = TRUE, status = "pass"
  )
  expect_s3_class(x, "valence_dynamics_result")
  expect_equal(x$test_name, "demo")
  expect_true(x$discriminating)
  expect_equal(x$status, "pass")
  # print / summary / as.data.frame are pure and correct
  s <- summary(x)
  expect_s3_class(s, "data.frame")
  expect_equal(s$test_name, "demo")
  expect_equal(s$rho, 0.8)
  expect_equal(as.data.frame(x), s)
  p <- capture.output(print(x))
  expect_true(length(p) > 0)
  expect_identical(x, x)
})

test_that("base dynamics validator rejects malformed objects", {
  expect_error(
    valence.foundry:::validate_valence_dynamics_result(42),
    "must be a list"
  )
  bad <- valence.foundry:::new_valence_dynamics_result(
    list(), list(), "t", TRUE, "pass"
  )
  bad$test_name <- NULL
  expect_error(
    valence.foundry:::validate_valence_dynamics_result(bad),
    "Missing required fields"
  )
  bad2 <- valence.foundry:::new_valence_dynamics_result(
    list(), list(), "t", TRUE, "pass"
  )
  bad2$values <- 1
  expect_error(valence.foundry:::validate_valence_dynamics_result(bad2), "values")
  bad3 <- valence.foundry:::new_valence_dynamics_result(
    list(), list(), 1, TRUE, "pass"
  )
  expect_error(valence.foundry:::validate_valence_dynamics_result(bad3), "test_name")
  bad4 <- valence.foundry:::new_valence_dynamics_result(
    list(), list(), "t", "yes", "pass"
  )
  expect_error(valence.foundry:::validate_valence_dynamics_result(bad4), "discriminating")
  bad5 <- valence.foundry:::new_valence_dynamics_result(
    list(), list(), "t", TRUE, 1
  )
  expect_error(valence.foundry:::validate_valence_dynamics_result(bad5), "status")
})

# ============================================================================
# Autocatalytic result class
# ============================================================================

test_that("autocatalytic result: helper validates typed object", {
  x <- valence_autocatalytic_result(
    diversity_dependence_sign = "positive",
    per_capita_rate = c(0.2, 0.3, 0.4),
    n_species = 3,
    time_series = c(1, 2, 4),
    metadata = list(seed = 42L)
  )
  expect_s3_class(x, "valence_autocatalytic_result")
  expect_s3_class(x, "valence_dynamics_result")
  expect_equal(x$values$diversity_dependence_sign, "positive")
  expect_equal(x$values$n_species, 3)
})

test_that("autocatalytic validator rejects wrong sign / types", {
  expect_error(
    valence_autocatalytic_result("sideways", c(0.2), 1, c(1), metadata = list()),
    "diversity_dependence_sign"
  )
  expect_error(
    valence_autocatalytic_result("positive", "x", 1, c(1), metadata = list()),
    "per_capita_rate"
  )
  expect_error(
    valence_autocatalytic_result("positive", c(0.2), "x", c(1), metadata = list()),
    "n_species"
  )
  expect_error(
    valence_autocatalytic_result("positive", c(0.2), 1, "x", metadata = list()),
    "time_series"
  )
})

test_that("as_valence_autocatalytic_result coerces raw output with counts", {
  raw <- list(
    values = list(
      innovation_counts = c(1, 2, 4, 8, 16),
      diversity_dependence_sign = "negative"
    ),
    metadata = list(seed = 42L)
  )
  x <- as_valence_autocatalytic_result(raw)
  expect_s3_class(x, "valence_autocatalytic_result")
  expect_equal(x$values$diversity_dependence_sign, "negative")
  # per-capita rate computed from successive counts: (N_{t+1}-N_t)/N_t
  expect_equal(x$values$per_capita_rate[1], 1.0)
  expect_equal(x$values$n_species, 5)
  expect_equal(x$metadata$seed, 42L)
})

test_that("as_valence_autocatalytic_result handles time_series alias and defaults", {
  # time_series alias (no innovation_counts)
  x <- as_valence_autocatalytic_result(
    list(values = list(time_series = c(1, 3)), metadata = list())
  )
  expect_equal(x$values$diversity_dependence_sign, "inconclusive")
  expect_equal(x$values$per_capita_rate, 2.0)
  # single point -> NA per-capita rate
  x2 <- as_valence_autocatalytic_result(
    list(values = list(time_series = 5), metadata = list())
  )
  expect_true(is.na(x2$values$per_capita_rate))
  # missing series -> error
  expect_error(
    as_valence_autocatalytic_result(list(values = list(), metadata = list())),
    "innovation_counts or time_series"
  )
  # non-list input -> error
  expect_error(as_valence_autocatalytic_result(42), "list with a 'values'")
})

# ============================================================================
# Cusp result class
# ============================================================================

test_that("cusp result: helper validates typed object", {
  x <- valence_cusp_result(
    has_hysteresis = TRUE, max_difference = 0.4, loop_area = 0.2,
    equilibria = c(-1, 0, 1), bifurcation_set = 0.5,
    metadata = list(a = -2)
  )
  expect_s3_class(x, "valence_cusp_result")
  expect_s3_class(x, "valence_dynamics_result")
  expect_true(x$values$has_hysteresis)
  expect_equal(x$values$loop_area, 0.2)
})

test_that("cusp validator rejects malformed values", {
  expect_error(
    valence_cusp_result("yes", 0.4, 0.2, c(-1, 1), 0.5, metadata = list()),
    "has_hysteresis"
  )
  expect_error(
    valence_cusp_result(TRUE, "x", 0.2, c(-1, 1), 0.5, metadata = list()),
    "max_difference"
  )
  expect_error(
    valence_cusp_result(TRUE, 0.4, "x", c(-1, 1), 0.5, metadata = list()),
    "loop_area"
  )
  expect_error(
    valence_cusp_result(TRUE, 0.4, 0.2, c("a"), 0.5, metadata = list()),
    "equilibria"
  )
  expect_error(
    valence_cusp_result(TRUE, 0.4, 0.2, c(-1, 1), "x", metadata = list()),
    "bifurcation_set"
  )
})

test_that("as_valence_cusp_result maps forward_states and control values", {
  raw <- list(
    values = list(
      has_hysteresis = TRUE, max_difference = 0.5, loop_area = 0.3,
      forward_states = c(-1, 0, 1), control_values = c(-1, 0, 1)
    ),
    metadata = list()
  )
  x <- as_valence_cusp_result(raw)
  expect_s3_class(x, "valence_cusp_result")
  expect_equal(x$values$equilibria, c(-1, 0, 1))
  # no meta$a -> bifurcation from median control abs
  expect_equal(x$values$bifurcation_set, 0)
  # with meta$a < 0 -> analytic bifurcation threshold
  raw$metadata <- list(a = -2)
  x2 <- as_valence_cusp_result(raw)
  expect_equal(x2$values$bifurcation_set, (2 / (3 * sqrt(3))) * 2^(3 / 2))
})

test_that("as_valence_cusp_result falls back to safe defaults", {
  # equilibria only (no forward_states)
  x <- as_valence_cusp_result(
    list(values = list(equilibria = c(0, 1)), metadata = list(a = -2))
  )
  expect_equal(x$values$equilibria, c(0, 1))
  # neither -> empty equilibria; no cv and no a -> NA bifurcation
  x2 <- as_valence_cusp_result(list(values = list(), metadata = list()))
  expect_equal(x2$values$equilibria, numeric(0))
  expect_true(is.na(x2$values$bifurcation_set))
  # defaults for missing scalars
  x3 <- as_valence_cusp_result(
    list(values = list(equilibria = c(0)), metadata = list(a = -2))
  )
  expect_false(x3$values$has_hysteresis)
  expect_equal(x3$values$max_difference, 0)
  expect_equal(x3$values$loop_area, 0)
  # non-list input must error
  expect_error(as_valence_cusp_result(NULL), "list with a 'values'")
})

# ============================================================================
# Economics result class
# ============================================================================

test_that("economics result: helper validates typed object", {
  x <- valence_economics_result(
    cdi = c(0.1, 0.3, 0.6), option_value = c(1, 0.8, 0.5),
    stochastic_paths = matrix(runif(6), 2, 3),
    threshold_disruption = FALSE, metadata = list()
  )
  expect_s3_class(x, "valence_economics_result")
  expect_s3_class(x, "valence_dynamics_result")
  expect_equal(x$values$cdi[1], 0.1)
})

test_that("economics validator rejects malformed values", {
  expect_error(
    valence_economics_result("x", c(1), matrix(1), FALSE, metadata = list()),
    "cdi"
  )
  expect_error(
    valence_economics_result(c(1), "x", matrix(1), FALSE, metadata = list()),
    "option_value"
  )
  expect_error(
    valence_economics_result(c(1), c(1), "x", FALSE, metadata = list()),
    "stochastic_paths"
  )
})

# ============================================================================
# S3 methods on the base class
# ============================================================================

test_that("print/summary handle long vectors, matrices, and non-numeric values", {
  x <- valence_dynamics_result(
    values = list(
      long = 1:10, mat = matrix(as.character(1:6), 2, 3), label = "hello"
    ),
    metadata = list(), test_name = "t", discriminating = TRUE, status = "pass"
  )
  p <- capture.output(print(x))
  expect_true(any(grepl("10 values", p)))
  expect_true(any(grepl("2 x 3 matrix", p)))
  expect_true(any(grepl("hello", p)))
  # summary only keeps numeric scalar fields
  s <- summary(x)
  expect_equal(s$test_name, "t")
  expect_false("label" %in% names(s))
  expect_false("mat" %in% names(s))
})

test_that("fmt_num formats NA and numbers without error", {
  expect_equal(valence.foundry:::fmt_num(NA_real_), "NA")
  expect_equal(valence.foundry:::fmt_num(0.1234567), "0.12346")
})

# ============================================================================
# Proof result class
# ============================================================================

test_that("proof result: helper validates and methods round-trip", {
  x <- valence_proof(
    statement = "P => Q", derivation = "line1\nline2",
    result = "QED", verified = TRUE, numeric_check = 0.999
  )
  expect_s3_class(x, "valence_proof")
  expect_true(x$verified)
  s <- summary(x)
  expect_s3_class(s, "data.frame")
  expect_equal(s$statement, "P => Q")
  expect_equal(s$verified, TRUE)
  expect_equal(as.data.frame(x), s)
  p <- capture.output(print(x))
  expect_true(any(grepl("THEOREM", p)))
  expect_true(any(grepl("VERIFIED", p)))
})

test_that("proof validator rejects malformed objects", {
  expect_error(valence.foundry:::validate_valence_proof(42), "must be a list")
  bad <- valence.foundry:::new_valence_proof("s", "d", "QED", TRUE, 1)
  bad$statement <- NULL
  expect_error(valence.foundry:::validate_valence_proof(bad), "Missing required fields")
  bad2 <- valence.foundry:::new_valence_proof("s", "d", "QED", TRUE, 1)
  bad2$derivation <- 1
  expect_error(valence.foundry:::validate_valence_proof(bad2), "derivation")
  bad3 <- valence.foundry:::new_valence_proof("s", "d", "QED", TRUE, 1)
  bad3$verified <- "yes"
  expect_error(valence.foundry:::validate_valence_proof(bad3), "verified")
  bad4 <- valence.foundry:::new_valence_proof("s", "d", "QED", TRUE, "x")
  expect_error(valence.foundry:::validate_valence_proof(bad4), "numeric_check")
})
