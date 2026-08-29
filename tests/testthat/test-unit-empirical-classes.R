# test-unit-empirical-classes.R — Unit tests for the empirical S3 result
# classes and the test registry.
# DFT A1 (pure functions) + A6 (check-result): the S3 classes follow the
# constructor -> validator -> helper pattern; every class must round-trip
# through print/summary/as.data.frame without state change.

library(testthat)

# ============================================================================
# Helpers
# ============================================================================

# Build a valid base result quickly.
make_base_result <- function(statistic = 1.5, p_value = 0.02) {
  valence_test_result(
    test_name = "demo_test",
    statistic = statistic,
    p_value = p_value,
    valence_prediction = "some prediction",
    discriminating = TRUE,
    values = list(rho = 0.8),
    metadata = list(n = 10)
  )
}

# ============================================================================
# Base class: constructor + validator
# ============================================================================

test_that("base constructor validates and returns a typed object", {
  x <- make_base_result()
  expect_s3_class(x, "valence_test_result")
  expect_equal(x$test_name, "demo_test")
  expect_equal(x$statistic, 1.5)
  expect_equal(x$p_value, 0.02)
  expect_true(x$discriminating)
  # status derived from p_value
  expect_equal(x$status, "significant")
})

test_that("status defaults follow p_value thresholds", {
  expect_equal(valence_test_result("t", p_value = 0.001)$status, "significant")
  expect_equal(valence_test_result("t", p_value = 0.5)$status, "not_significant")
  expect_equal(valence_test_result("t", p_value = NA_real_)$status, "n/a")
})

test_that("validator rejects missing or wrong-typed fields", {
  # wrong class entirely
  expect_error(
    valence.foundry:::validate_valence_test_result(list()),
    "class 'valence_test_result'"
  )
  # stripped of required fields
  bad <- valence.foundry:::new_valence_test_result("t", 1, 0.1, "", FALSE, "n/a", list(), list())
  bad$test_name <- NULL
  expect_error(
    valence.foundry:::validate_valence_test_result(bad),
    "Missing required fields"
  )
  # non-numeric statistic
  bad2 <- valence.foundry:::new_valence_test_result("t", 1, 0.1, "", FALSE, "n/a", list(), list())
  bad2$statistic <- "not a number"
  expect_error(valence.foundry:::validate_valence_test_result(bad2), "statistic")
  # p_value out of range
  bad3 <- valence.foundry:::new_valence_test_result("t", 1, 2.0, "", FALSE, "n/a", list(), list())
  expect_error(valence.foundry:::validate_valence_test_result(bad3), "p_value")
  # invalid status
  bad4 <- valence.foundry:::new_valence_test_result("t", 1, 0.1, "", FALSE, "maybe", list(), list())
  expect_error(valence.foundry:::validate_valence_test_result(bad4), "status")
})

test_that("NULL fields coerce to NA via the or_na helper", {
  expect_equal(valence.foundry:::.valence_or_na(NULL), NA)
  expect_equal(valence.foundry:::.valence_or_na(3), 3)
})

test_that("print/summary/as.data.frame are pure and correct", {
  x <- make_base_result()
  # summary returns a one-row data.frame with canonical columns
  s <- summary(x)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), 1)
  expect_equal(s$test_name, "demo_test")
  expect_equal(s$status, "significant")
  # as.data.frame matches summary
  expect_equal(as.data.frame(x), s)
  # print is invisible-returning and does not mutate (it does emit to stdout)
  p <- capture.output(print(x))
  expect_true(length(p) > 0) # prints a header block
  expect_s3_class(x, "valence_test_result") # unchanged
  expect_identical(print(x), x)
})

# ============================================================================
# PGLS class (T1/T2)
# ============================================================================

test_that("pgls class constructor + summary carry extra fields", {
  x <- valence_pgls_result(
    test_name = "pgls_test", statistic = -0.8, p_value = 0.01,
    valence_prediction = "negative beta", discriminating = FALSE,
    beta = -0.8, r_squared = 0.6, aic = 10, n = 48
  )
  expect_s3_class(x, "valence_pgls_result")
  expect_s3_class(x, "valence_test_result")
  expect_equal(x$beta, -0.8)
  expect_equal(x$r_squared, 0.6)
  expect_equal(x$n, 48)
  s <- summary(x)
  expect_equal(s$beta, -0.8)
  expect_equal(s$r_squared, 0.6)
  expect_equal(s$n, 48)
  expect_equal(as.data.frame(x), s)
})

test_that("pgls validator rejects non-numeric extras", {
  bad <- valence.foundry:::new_valence_pgls_result("t", 1, 0.1, "", FALSE, "n/a", list(), list(),
    beta = "x", r_squared = 0.6, aic = 10, n = 5
  )
  expect_error(valence.foundry:::validate_valence_pgls_result(bad), "beta")
})

# ============================================================================
# Niche vs Ne class (T4)
# ============================================================================

test_that("niche_ne class constructor + summary", {
  x <- valence_niche_ne_result(
    test_name = "niche_test", statistic = 0.5, p_value = 0.03,
    discriminating = TRUE, niche_r_squared = 0.7, ne_r_squared = 0.2,
    delta_aic = -12
  )
  expect_s3_class(x, "valence_niche_ne_result")
  expect_equal(x$niche_r_squared, 0.7)
  expect_equal(x$ne_r_squared, 0.2)
  expect_equal(x$delta_aic, -12)
  s <- summary(x)
  expect_equal(s$niche_r_squared, 0.7)
  expect_equal(s$ne_r_squared, 0.2)
})

test_that("niche_ne validator rejects non-numeric", {
  bad <- valence.foundry:::new_valence_niche_ne_result("t", 1, 0.1, "", FALSE, "n/a", list(), list(),
    niche_r_squared = "x", ne_r_squared = 0.2,
    delta_aic = -12
  )
  expect_error(valence.foundry:::validate_valence_niche_ne_result(bad), "niche_r_squared")
})

# ============================================================================
# Fluidity class (T5)
# ============================================================================

test_that("fluidity class constructor + summary", {
  x <- valence_fluidity_result(
    test_name = "fluid_test", statistic = 0.4, p_value = 0.04,
    discriminating = TRUE, lifestyle_r_squared = 0.8, ne_r_squared = 0.1
  )
  expect_s3_class(x, "valence_fluidity_result")
  expect_equal(x$lifestyle_r_squared, 0.8)
  expect_equal(x$ne_r_squared, 0.1)
  s <- summary(x)
  expect_equal(s$lifestyle_r_squared, 0.8)
})

# ============================================================================
# Ordering class (T6)
# ============================================================================

test_that("ordering class constructor + summary carry rho and permutations", {
  x <- valence_ordering_result(
    test_name = "ord_test", statistic = 0.9, p_value = 0.001,
    discriminating = TRUE, rho = 0.9, p_value2 = 0.001, n_permutations = 1000
  )
  expect_s3_class(x, "valence_ordering_result")
  expect_equal(x$rho, 0.9)
  expect_equal(x$n_permutations, 1000)
  s <- summary(x)
  expect_equal(s$rho, 0.9)
  expect_equal(s$n_permutations, 1000)
})

test_that("ordering validator rejects non-numeric rho", {
  bad <- valence.foundry:::new_valence_ordering_result("t", 1, 0.1, "", FALSE, "n/a", list(), list(),
    rho = "x", p_value2 = 0.1, n_permutations = 100
  )
  expect_error(valence.foundry:::validate_valence_ordering_result(bad), "rho")
})

# ============================================================================
# Transfer class (L3)
# ============================================================================

test_that("transfer class constructor + summary", {
  x <- valence_transfer_result(
    test_name = "transfer_test", statistic = 0.7, p_value = 0.01,
    discriminating = TRUE, rho = 0.7, p_value2 = 0.01, n_null_draws = 1000
  )
  expect_s3_class(x, "valence_transfer_result")
  expect_equal(x$rho, 0.7)
  expect_equal(x$n_null_draws, 1000)
  s <- summary(x)
  expect_equal(s$rho, 0.7)
})

# ============================================================================
# Co-segregation class (T7)
# ============================================================================

test_that("cosegregation class constructor + summary", {
  x <- valence_cosegregation_result(
    test_name = "coseg_test", statistic = 0.6, p_value = 0.0001,
    discriminating = TRUE, observed_pct = 36.4, expected_pct = 61.7,
    depletion_ratio = 0.59
  )
  expect_s3_class(x, "valence_cosegregation_result")
  expect_equal(x$observed_pct, 36.4)
  expect_equal(x$expected_pct, 61.7)
  expect_equal(x$depletion_ratio, 0.59)
  s <- summary(x)
  expect_equal(s$depletion_ratio, 0.59)
})

# ============================================================================
# Significance-star helper
# ============================================================================

test_that("p-stars helper maps thresholds correctly", {
  expect_equal(valence.foundry:::.valence_p_stars(0.0005), "***")
  expect_equal(valence.foundry:::.valence_p_stars(0.005), "**")
  expect_equal(valence.foundry:::.valence_p_stars(0.03), "*")
  expect_equal(valence.foundry:::.valence_p_stars(0.2), "")
  expect_equal(valence.foundry:::.valence_p_stars(NA_real_), "")
})

# ============================================================================
# Registry: register_test validation
# ============================================================================

test_that("register_test validates its arguments", {
  expect_error(register_test(name = "", fn = function() NULL), "name")
  expect_error(register_test(name = "x", fn = "not a function"), "fn")
  expect_error(
    register_test(name = "x", fn = function() NULL, class = "bogus_class"),
    "Unknown result class"
  )
})

# ============================================================================
# Section: the registry API (run_test, run_all_tests, list_tests)
# ============================================================================

test_that("run_test wraps raw output into the declared S3 class", {
  # Register a small discriminating ordering test on the fly.
  fake <- function(...) {
    list(
      values = list(
        spearman_rho = 0.88, permutation_p = 0.01,
        n_permutations = 500
      ),
      metadata = list(n = 20)
    )
  }
  register_test(
    name = "unit_demo_ordering", fn = fake,
    data_required = character(0), discriminating = TRUE,
    expected_fields = c("spearman_rho", "permutation_p"),
    class = "valence_ordering_result", statistic_key = "spearman_rho",
    valence_prediction = "ordering demo"
  )
  res <- run_test("unit_demo_ordering")
  expect_s3_class(res, "valence_ordering_result")
  expect_equal(res$rho, 0.88)
  expect_equal(res$statistic, 0.88)
  expect_equal(res$status, "significant")
  expect_equal(res$n_permutations, 500)
})

test_that("run_test errors on unknown names", {
  expect_error(run_test("no_such_test"), "Unknown test")
})

test_that("run_all_tests collects a suite with summary", {
  suite <- run_all_tests()
  expect_s3_class(suite, "valence_test_suite")
  expect_true(suite$n_tests >= 18) # 18 built-ins at load + our demo
  expect_true("unit_demo_ordering" %in% names(suite$results))
  s <- summary(suite)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), suite$n_tests)
  # print is callable without error
  expect_silent(invisible(capture.output(print(suite))))
})

test_that("list_tests filters discriminating-only", {
  all_df <- list_tests()
  disc_df <- list_tests(discriminating_only = TRUE)
  expect_true(all(all_df$name %in% c("unit_demo_ordering", all_df$name)))
  expect_true(all(disc_df$discriminating))
  expect_lt(nrow(disc_df), nrow(all_df))
})

# ============================================================================
# Registry: .build_valence_result routing across classes
# ============================================================================

test_that("result builder routes to the correct S3 class", {
  base_entry <- list(
    name = "routed_base", class = "valence_test_result",
    valence_prediction = "p", discriminating = FALSE
  )
  base_out <- valence.foundry:::.build_valence_result(
    base_entry,
    list(values = list(r2 = 0.5), metadata = list())
  )
  expect_s3_class(base_out, "valence_test_result")

  pg <- valence.foundry:::.build_valence_result(
    list(name = "pg", class = "valence_pgls_result", valence_prediction = "p"),
    list(
      values = list(beta = -0.5, r_squared = 0.4, aic = 5, n = 30),
      metadata = list()
    )
  )
  expect_s3_class(pg, "valence_pgls_result")
  expect_equal(pg$beta, -0.5)

  co <- valence.foundry:::.build_valence_result(
    list(
      name = "co", class = "valence_cosegregation_result",
      valence_prediction = "p"
    ),
    list(values = list(
      observed_pct = 40, expected_pct = 60,
      depletion_ratio = 0.67
    ), metadata = list())
  )
  expect_s3_class(co, "valence_cosegregation_result")
  expect_equal(co$depletion_ratio, 0.67)

  tr <- valence.foundry:::.build_valence_result(
    list(name = "tr", class = "valence_transfer_result", valence_prediction = "p"),
    list(
      values = list(bird_rho = 0.6, null_p = 0.04, n_null = 100),
      metadata = list()
    )
  )
  expect_s3_class(tr, "valence_transfer_result")
  expect_equal(tr$rho, 0.6)
})

test_that("p-value extraction prefers p_value then permutation_p then null_p", {
  entry <- list(name = "pv", class = "valence_test_result", valence_prediction = "p")
  r1 <- valence.foundry:::.build_valence_result(entry, list(values = list(p_value = 0.02), metadata = list()))
  expect_equal(r1$p_value, 0.02)
  r2 <- valence.foundry:::.build_valence_result(entry, list(values = list(permutation_p = 0.03), metadata = list()))
  expect_equal(r2$p_value, 0.03)
  r3 <- valence.foundry:::.build_valence_result(entry, list(values = list(null_p = 0.04), metadata = list()))
  expect_equal(r3$p_value, 0.04)
  r4 <- valence.foundry:::.build_valence_result(entry, list(values = list(anything = 1), metadata = list()))
  expect_true(is.na(r4$p_value))
})

# ============================================================================
# Cleanup: remove the demo entry so we leave the registry as we found it
# ============================================================================

test_that("demo registry entry is removed after the suite", {
  rm(list = "unit_demo_ordering", envir = valence.foundry:::.valence_test_registry)
  expect_null(valence.foundry:::.valence_test_registry[["unit_demo_ordering"]])
})
