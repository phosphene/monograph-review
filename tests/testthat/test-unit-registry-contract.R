# test-unit-registry-contract.R — Contract tests for R/test_registry.R
#
# E1 coverage ticket: test_registry.R was at 64.1%. These tests pin the
# registry internals (.valence_register, .valence_class_for, .val_or_na,
# %||%), the public API edge cases (register/list/run), the suite S3 methods
# (print/summary/plot), and the built-in registration hook.

library(testthat)
library(valence.foundry)

# ============================================================================
# Registry internals
# ============================================================================

test_that("registry is a bounded env with print method", {
  expect_s3_class(valence.foundry:::.valence_test_registry, "valence_test_registry_env")
  out <- capture.output(print(valence.foundry:::.valence_test_registry))
  expect_true(any(grepl("registered tests", out)))
  expect_true(length(out) >= 2)
})

test_that(".valence_register writes and .valence_class_for reads", {
  entry <- list(
    name = "unit_internal_probe", fn = function() NULL,
    class = "valence_ordering_result", discriminating = TRUE
  )
  valence.foundry:::.valence_register(entry)
  on.exit(
    rm("unit_internal_probe", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  expect_equal(
    valence.foundry:::.valence_class_for("unit_internal_probe"),
    "valence_ordering_result"
  )
  # unknown name -> default class
  expect_equal(
    valence.foundry:::.valence_class_for("no_such_test_zzz"),
    "valence_test_result"
  )
  # entry without class -> default class
  valence.foundry:::.valence_register(list(name = "unit_internal_nocl", fn = function() NULL))
  on.exit(
    rm("unit_internal_nocl", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  expect_equal(
    valence.foundry:::.valence_class_for("unit_internal_nocl"),
    "valence_test_result"
  )
})

test_that(".val_or_na returns value, fallback, or NA", {
  lst <- list(a = 1, b = NULL)
  expect_equal(valence.foundry:::.val_or_na(lst, "a"), 1)
  expect_equal(valence.foundry:::.val_or_na(lst, "b", fallback = 7), 7)
  expect_equal(valence.foundry:::.val_or_na(lst, "missing"), NA_real_)
  # fallback can be pulled from another list
  expect_equal(
    valence.foundry:::.val_or_na(list(n = 5), "n", valence.foundry:::.val_or_na(list(x = 1), "x")),
    5
  )
})

test_that("%||% coalesces NULL and NA but keeps other values", {
  `%||%` <- valence.foundry:::`%||%`
  expect_null(NULL %||% NULL)
  expect_equal(1 %||% 2, 1)
  expect_equal(NA_real_ %||% 2, 2)
  expect_equal("x" %||% "y", "x")
  expect_equal(c(1, 2) %||% 9, c(1, 2))
})

# ============================================================================
# register_test public API
# ============================================================================

test_that("register_test validates and returns the entry invisibly", {
  f <- function() NULL
  r <- register_test(
    name = "unit_probe_ok", fn = f,
    data_required = "data", discriminating = TRUE,
    expected_fields = c("rho"), class = "valence_ordering_result"
  )
  on.exit(
    rm("unit_probe_ok", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  expect_true(is.list(r))
  expect_equal(r$name, "unit_probe_ok")
  expect_equal(r$data_required, "data")
  expect_true(r$discriminating)
  expect_equal(r$class, "valence_ordering_result")
})

test_that("register_test rejects bad arguments", {
  expect_error(register_test(name = "", fn = function() NULL), "name")
  expect_error(register_test(name = "x", fn = "nope"), "fn")
  expect_error(register_test(name = "x", fn = function() NULL, class = 1), "class")
  expect_error(
    register_test(name = "x", fn = function() NULL, class = "bogus_class"),
    "Unknown result class"
  )
})

test_that("list_tests returns empty frame when registry is empty and filters", {
  env <- valence.foundry:::.valence_test_registry
  saved <- as.list.environment(env, all.names = TRUE)  # snapshot entries (objects)
  saved_names <- ls(env)
  on.exit({
    rm(list = ls(env), envir = env)
    for (nm in saved_names) assign(nm, saved[[nm]], envir = env)
  }, add = TRUE)
  rm(list = saved_names, envir = env)
  empty <- list_tests()
  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0)
  expect_true(all(c("name", "function_name", "data_required",
                    "discriminating", "expected_fields", "class") %in% names(empty)))
})

test_that("list_tests sorts names and reports discriminating flag", {
  all_df <- list_tests()
  expect_true(is.unsorted(all_df$name) == FALSE)
  disc_df <- list_tests(discriminating_only = TRUE)
  expect_true(all(disc_df$discriminating))
  # every registered test appears
  reg_names <- sort(ls(valence.foundry:::.valence_test_registry))
  expect_true(all(reg_names %in% all_df$name))
})

# ============================================================================
# Registry public execution paths
# ============================================================================

test_that("run_test wraps raw output via statistic_key and class routing", {
  register_test(
    name = "unit_probe_run", fn = function() {
      list(values = list(unique_stat = 0.77, permutation_p = 0.01),
           metadata = list(n = 10))
    },
    class = "valence_ordering_result", statistic_key = "unique_stat",
    valence_prediction = "probe", discriminating = TRUE
  )
  on.exit(
    rm("unit_probe_run", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  res <- run_test("unit_probe_run")
  expect_s3_class(res, "valence_ordering_result")
  expect_equal(res$statistic, 0.77)
  expect_equal(res$p_value, 0.01)
  expect_equal(res$status, "significant")
  expect_equal(res$test_name, "unit_probe_run")
})

test_that("run_test passes ... to the test function", {
  register_test(
    name = "unit_probe_args", fn = function(seed, scale = 1) {
      list(values = list(seed_out = seed, stat = scale * 0.5), metadata = list())
    },
    class = "valence_test_result", statistic_key = "stat"
  )
  on.exit(
    rm("unit_probe_args", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  res <- run_test("unit_probe_args", seed = 7, scale = 3)
  expect_equal(res$values$seed_out, 7)
  expect_equal(res$statistic, 1.5)
})

test_that("run_test errors on unknown name", {
  expect_error(run_test("unit_does_not_exist"), "Unknown test")
})

test_that("run_all_tests captures failing tests as n/a entries", {
  register_test(name = "unit_failer", fn = function() stop("boom"), class = "valence_test_result")
  register_test(
    name = "unit_good", fn = function() {
      list(values = list(stat = 2.0, p_value = 0.001), metadata = list())
    },
    class = "valence_test_result", statistic_key = "stat"
  )
  on.exit({
    rm("unit_failer", envir = valence.foundry:::.valence_test_registry)
    rm("unit_good", envir = valence.foundry:::.valence_test_registry)
  }, add = TRUE)
  suite <- run_all_tests()
  expect_s3_class(suite, "valence_test_suite")
  expect_true(suite$n_failed >= 1)
  expect_true(suite$n_tests >= 2)
  expect_equal(suite$results$unit_failer$status, "n/a")
  expect_true(isTRUE(suite$results$unit_failer$metadata$failed))
  expect_equal(suite$results$unit_good$status, "significant")
})

# ============================================================================
# Suite S3 methods
# ============================================================================

test_that("print/summary/plot suite methods are callable and correct", {
  register_test(
    name = "unit_suite_probe", fn = function() {
      list(values = list(stat = 1.5, p_value = 0.02), metadata = list(n = 8))
    },
    class = "valence_test_result", statistic_key = "stat"
  )
  on.exit(
    rm("unit_suite_probe", envir = valence.foundry:::.valence_test_registry),
    add = TRUE
  )
  suite <- run_all_tests()
  out <- capture.output(print(suite))
  expect_true(any(grepl("valence_test_suite", out)))
  s <- summary(suite)
  expect_s3_class(s, "data.frame")
  expect_true(nrow(s) >= 1)
  expect_true(all(c("class", "n") %in% names(s)))
  # plot is pure: returns a ggplot without error when stats present
  skip_if_not_installed("ggplot2")
  p <- tryCatch(plot(suite), error = function(e) NULL)
  expect_false(is.null(p))
  # plot with zero tests errors loudly
  empty <- structure(
    list(results = list(), ran_at = Sys.time(), n_tests = 0,
         n_significant = 0, n_failed = 0),
    class = "valence_test_suite"
  )
  expect_error(plot(empty), "No tests to plot")
})

# ============================================================================
# Built-in registration hook
# ============================================================================

test_that(".valence_register_builtin registers the expected built-ins", {
  invisible(valence.foundry:::.valence_register_builtin())
  reg <- valence.foundry:::.valence_test_registry
  # the canonical empirical + a priori + cultural tests are present
  expect_true("ltee_cosegregation" %in% ls(reg))
  expect_true("niche_vs_ne" %in% ls(reg))
  expect_true("gene_loss_ordering" %in% ls(reg))
  expect_true("p1_buchnera_two_component" %in% ls(reg))
  expect_true("transfer_test" %in% ls(reg))
  expect_true("sign_reversal" %in% ls(reg))
  # each entry carries a class and a function
  for (nm in c("ltee_cosegregation", "p1_buchnera_two_component", "sign_reversal")) {
    expect_true(is.character(reg[[nm]]$class))
    expect_true(is.function(reg[[nm]]$fn))
  }
})
