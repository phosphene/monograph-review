# test-unit-formal-model-classes.R — Contract tests for R/formal_model_classes.R
#
# E1 coverage ticket: formal_model_classes.R was at 50.6%. The three result
# classes (valence_threshold_result, valence_glm_fit, valence_equilibrium)
# follow the constructor -> validator -> helper pattern; these tests pin the
# validator contracts (valid objects pass, each invalid shape is rejected)
# and the helper round-trip for each class.
#
# DFT A1 (pure math, no I/O) + A6 (check-result with values + metadata).

library(testthat)
library(valence.foundry)

# ============================================================================
# Valid fixtures
# ============================================================================

make_threshold_values <- function() {
  list(
    final_retention = c(0.9, 0.85, 0.8),
    phase1_rate = 0.05,
    phase2_rate = 0.02,
    early_late_displacement_ratio = 2.5,
    threshold_biphasicity = 0.3
  )
}

make_threshold_metadata <- function() {
  list(
    params = list(lambda = 0.1, theta = 2.5),
    n_traits = 50, n_unprotected = 30, n_protected = 20,
    n_steps = 1000, dt = 0.01, method = "euler",
    converged = TRUE,
    retention_history = matrix(runif(10), nrow = 2)
  )
}

make_glm_values <- function() {
  list(
    intercept = 0.5, dep_coefficient = -0.3, dep_p_value = 0.01,
    para_coefficient = 0.2, para_p_value = 0.02, pseudo_r_squared = 0.4,
    cross_kingdom_rho = 0.7, cross_kingdom_p = 0.001,
    dep_positive = FALSE, para_negative = TRUE, valence_confirmed = TRUE
  )
}

make_glm_metadata <- function() {
  x <- rnorm(20)
  y <- rbinom(20, 1, 0.5)
  list(
    n = 20, n_species = 10, n_gene_categories = 4, method = "glm",
    seed = 42L, para_for_transfer = 1.5, converged = TRUE,
    glm_fit = glm(y ~ x, family = binomial)
  )
}

# ============================================================================
# valence_threshold_result
# ============================================================================

test_that("threshold result: helper validates and round-trips", {
  x <- valence_threshold_result(
    make_threshold_values(), make_threshold_metadata()
  )
  expect_s3_class(x, "valence_threshold_result")
  expect_equal(x$values$early_late_displacement_ratio, 2.5)
  expect_equal(x$metadata$n_traits, 50)
  # bare constructor produces unvalidated object of the right class
  raw <- valence.foundry:::new_valence_threshold_result(
    make_threshold_values(), make_threshold_metadata()
  )
  expect_s3_class(raw, "valence_threshold_result")
  expect_silent(valence.foundry:::validate_valence_threshold_result(raw))
})

test_that("threshold validator rejects invalid structure", {
  expect_error(
    valence.foundry:::validate_valence_threshold_result(42),
    "must be a list"
  )
  v <- make_threshold_values()
  v$final_retention <- "x"
  expect_error(
    valence_threshold_result(v, make_threshold_metadata()),
    "final_retention"
  )
  v2 <- make_threshold_values()
  v2$phase1_rate <- "x"
  expect_error(
    valence_threshold_result(v2, make_threshold_metadata()),
    "phase rates"
  )
  v3 <- make_threshold_values()
  v3$threshold_biphasicity <- NULL
  expect_error(
    valence_threshold_result(v3, make_threshold_metadata()),
    "biphasicity must be numeric"
  )
  v4 <- make_threshold_values()
  v4$early_late_displacement_ratio <- NULL
  expect_error(
    valence_threshold_result(v4, make_threshold_metadata()),
    "early_late_displacement_ratio must be numeric"
  )
  m <- make_threshold_metadata()
  m$converged <- "yes"
  expect_error(
    valence_threshold_result(make_threshold_values(), m),
    "converged"
  )
  m2 <- make_threshold_metadata()
  m2$retention_history <- NULL
  expect_error(
    valence_threshold_result(make_threshold_values(), m2),
    "retention_history"
  )
  m3 <- make_threshold_metadata()
  m3$n_steps <- "x"
  expect_error(
    valence_threshold_result(make_threshold_values(), m3),
    "Count fields"
  )
})

# ============================================================================
# valence_glm_fit
# ============================================================================

test_that("glm_fit result: helper validates and round-trips", {
  x <- valence_glm_fit(make_glm_values(), make_glm_metadata())
  expect_s3_class(x, "valence_glm_fit")
  expect_equal(x$values$dep_coefficient, -0.3)
  expect_false(x$values$dep_positive)
  expect_true(x$values$valence_confirmed)
  raw <- valence.foundry:::new_valence_glm_fit(
    make_glm_values(), make_glm_metadata()
  )
  expect_s3_class(raw, "valence_glm_fit")
  expect_silent(valence.foundry:::validate_valence_glm_fit(raw))
})

test_that("glm_fit validator rejects invalid structure", {
  expect_error(valence.foundry:::validate_valence_glm_fit(42), "must be a list")
  v <- make_glm_values()
  v$dep_p_value <- "x"
  expect_error(
    valence_glm_fit(v, make_glm_metadata()),
    "dep_p_value must be numeric"
  )
  v2 <- make_glm_values()
  v2$dep_positive <- 1
  expect_error(
    valence_glm_fit(v2, make_glm_metadata()),
    "dep_positive must be logical"
  )
  m <- make_glm_metadata()
  m$n_species <- NULL
  expect_error(
    valence_glm_fit(make_glm_values(), m),
    "Missing required metadata"
  )
  m2 <- make_glm_metadata()
  m2$glm_fit <- "not a fit"
  expect_error(
    valence_glm_fit(make_glm_values(), m2),
    "glm_fit"
  )
  m3 <- make_glm_metadata()
  m3$seed <- NULL
  expect_error(
    valence_glm_fit(make_glm_values(), m3),
    "Missing required metadata"
  )
})

# ============================================================================
# valence_equilibrium
# ============================================================================

test_that("equilibrium result: helper validates and round-trips", {
  x <- valence_equilibrium(
    value = 0.85, is_protected = FALSE,
    params = list(lambda = 0.1, theta = 2.5, m0 = 10, alpha = 0.05, time = 100),
    depth = 1.2, integrated_mismatch = 1.5
  )
  expect_s3_class(x, "valence_equilibrium")
  expect_equal(x$value, 0.85)
  expect_false(x$is_protected)
  expect_equal(x$depth, 1.2)
  raw <- valence.foundry:::new_valence_equilibrium(
    0.85, FALSE, list(), 1.2, 1.5
  )
  expect_s3_class(raw, "valence_equilibrium")
  expect_silent(valence.foundry:::validate_valence_equilibrium(raw))
})

test_that("equilibrium validator rejects invalid structure", {
  expect_error(valence.foundry:::validate_valence_equilibrium(42), "must be a list")
  expect_error(
    valence_equilibrium(1.2, FALSE, list(), 1.2, 1.5),
    "value must be in \\[0, 1\\]"
  )
  expect_error(
    valence_equilibrium(0.5, "no", list(), 1.2, 1.5),
    "is_protected"
  )
  expect_error(
    valence_equilibrium(0.5, FALSE, list(), "x", 1.5),
    "depth"
  )
  expect_error(
    valence_equilibrium(0.5, FALSE, "x", 1.2, 1.5),
    "params must be a list"
  )
  expect_error(
    valence_equilibrium(0.5, FALSE, list(), 1.2, "x"),
    "integrated_mismatch"
  )
})
