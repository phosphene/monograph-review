# test-unit-formal-model.R — Unit tests for formal model
# DFT A1: pure math, deterministic, no I/O, no RNG (A2 not needed)

library(testthat)

context("Formal model")

# === equilibrium_retention ===

test_that("equilibrium_retention returns 1.0 for protected traits (depth >= theta)", {
  expect_equal(equilibrium_retention(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05), 1.0)
  expect_equal(equilibrium_retention(depth = 2.5, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05), 1.0)
})

test_that("equilibrium_retention returns < 1.0 for unprotected traits", {
  val <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_lt(val, 1.0)
  expect_gt(val, 0)
})

test_that("equilibrium_retention decreases with higher lambda", {
  low_lambda <- equilibrium_retention(depth = 0, lambda = 0.01, theta = 2.5, m0 = 10, alpha = 0.05)
  high_lambda <- equilibrium_retention(depth = 0, lambda = 0.5, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_lt(high_lambda, low_lambda)
})

test_that("equilibrium_retention decreases with higher mismatch", {
  low_m0 <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 1, alpha = 0.05)
  high_m0 <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 100, alpha = 0.05)
  expect_lt(high_m0, low_m0)
})

# === retention_at_time ===

test_that("retention_at_time returns 1.0 for protected traits at any time", {
  expect_equal(retention_at_time(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 50), 1.0)
  expect_equal(retention_at_time(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 1000), 1.0)
})

test_that("retention_at_time decreases over time for unprotected traits", {
  early <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 10)
  late <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  expect_lt(late, early)
})

test_that("retention_at_time approaches equilibrium as time → infinity", {
  t_large <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 10000)
  eq <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_equal(t_large, eq, tolerance = 0.01)
})

# === threshold_model (full numerical integration) ===

test_that("threshold_model returns A6 proof object", {
  result <- threshold_model(
    depths = c(0, 1, 2, 3, 5), lambda = 0.15,
    theta = 2.5, m0 = 10, alpha = 0.05, time = 100
  )
  expect_true(validate_result(result))
  expect_equal(result$metadata$n_traits, 5)
  expect_true(result$metadata$converged)
})

test_that("threshold_model protects deep traits at 1.0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- threshold_model(
    depths = depths, lambda = 0.15, theta = 2.5,
    m0 = 10, alpha = 0.05, time = 100
  )
  # Traits at depth 3 and 5 should be protected (>= theta=2.5)
  retention <- result$values[["final_retention"]]
  expect_equal(length(retention), 5)
  # Protected traits (depth 3, 5 → indices 4, 5) should be 1.0
  expect_gte(retention[[4]], 0.99)
  expect_gte(retention[[5]], 0.99)
})

test_that("threshold_model sheds unprotected traits below 1.0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- threshold_model(
    depths = depths, lambda = 0.15, theta = 2.5,
    m0 = 10, alpha = 0.05, time = 100
  )
  retention <- result$values[["final_retention"]]
  # Trait at depth 0 should be most shed
  expect_lt(retention[[1]], 0.9)
})

test_that("threshold_model produces biphasic kinetics (threshold_biphasicity ~ 1)", {
  result <- threshold_model(
    depths = c(0, 1, 2, 3, 5), lambda = 0.15,
    theta = 2.5, m0 = 10, alpha = 0.05, time = 100
  )
  # The real biphasic signal: protected traits retain at 1.0, unprotected shed
  # to ~0, so the difference of means is ~1.0.
  expect_equal(result$values[["threshold_biphasicity"]], 1.0, tolerance = 1e-6)
  # The displacement ratio is descriptive (large when decay finishes early).
  expect_gt(result$values[["early_late_displacement_ratio"]], 1)
})

test_that("threshold_model is fully deterministic (A2 — no RNG)", {
  r1 <- threshold_model(
    depths = c(0, 1, 2, 3, 5), lambda = 0.15,
    theta = 2.5, m0 = 10, alpha = 0.05, time = 100
  )
  r2 <- threshold_model(
    depths = c(0, 1, 2, 3, 5), lambda = 0.15,
    theta = 2.5, m0 = 10, alpha = 0.05, time = 100
  )
  expect_equal(r1$values, r2$values)
})

# === phase_transition_time ===

test_that("phase_transition_time returns positive time", {
  t <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.1)
  expect_gt(t, 0)
})

test_that("phase_transition_time decreases with higher alpha", {
  slow <- phase_transition_time(m0 = 10, alpha = 0.01, threshold_fraction = 0.1)
  fast <- phase_transition_time(m0 = 10, alpha = 0.1, threshold_fraction = 0.1)
  expect_lt(fast, slow)
})

test_that("phase_transition_time increases with smaller threshold fraction", {
  loose <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.5)
  tight <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.01)
  expect_gt(tight, loose)
})

# === empirical_formal_model (corrected additive GLM, Remark R7) ===

# Synthetic retention matrix where dep clearly increases retention and
# para clearly decreases it — tests the function without bundled data.
.synthetic_retention <- data.frame(
  species = rep(c("A", "B", "C", "D", "E"), 4),
  parasitism_score = rep(c(0, 1, 2, 3, 4), 4),
  gene_category = rep(c("g0", "g1", "g2", "g3"), each = 5),
  dependency_score = rep(c(0, 1, 2, 3), each = 5),
  retention = c(
    1, 0.8, 0.5, 0.3, 0.1,  # dep=0: shed fast
    1, 0.9, 0.7, 0.5, 0.3,  # dep=1: shed slower
    1, 0.95, 0.85, 0.7, 0.5,  # dep=2: shed slower still
    1, 1, 0.95, 0.9, 0.8  # dep=3: barely sheds
  ),
  stringsAsFactors = FALSE
)

.synthetic_bird <- data.frame(
  structure = c("t1", "t2", "t3", "t4", "t5", "t6"),
  dependency_score = c(0, 1, 2, 3, 1, 2),
  observed_rank = c(1, 3, 4, 6, 2, 5),
  stringsAsFactors = FALSE
)

test_that("empirical_formal_model returns A6 proof object", {
  result <- empirical_formal_model(.synthetic_retention, .synthetic_bird)
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
})

test_that("empirical_formal_model recovers positive dep on synthetic data", {
  result <- empirical_formal_model(.synthetic_retention, .synthetic_bird)
  expect_gt(result$values$dep_coefficient, 0)  # the framework predicts dep > 0
  expect_true(result$values$dep_positive)
})

test_that("empirical_formal_model recovers negative para on synthetic data", {
  result <- empirical_formal_model(.synthetic_retention, .synthetic_bird)
  expect_lt(result$values$para_coefficient, 0)  # the framework predicts para < 0
  expect_true(result$values$para_negative)
})

test_that("empirical_formal_model is deterministic (A2 — no RNG)", {
  r1 <- empirical_formal_model(.synthetic_retention, .synthetic_bird)
  r2 <- empirical_formal_model(.synthetic_retention, .synthetic_bird)
  expect_equal(r1$values, r2$values)
})

test_that("empirical_formal_model confirms the framework on real retention matrix", {
  skip_if_not(
    has_bundled_data("orobanchaceae_retention_matrix.tsv"),
    "Retention matrix not bundled"
  )
  skip_if_not(
    has_bundled_data("island_bird_morphology.csv"),
    "Bird data not bundled"
  )

  plant <- load_retention_matrix()
  bird <- load_island_birds()
  result <- empirical_formal_model(plant$data, bird$data)

  # the framework's predictions (Remark R7): corrected flattening gives the right signs
  expect_gt(result$values$dep_coefficient, 0)
  expect_lt(result$values$para_coefficient, 0)
  expect_gt(result$values$cross_kingdom_rho, 0)
  expect_true(result$values$valence_confirmed)
  expect_gt(result$values$pseudo_r_squared, 0.4)
  expect_equal(result$metadata$n, 48)                # 8 species x 6 genes
})

test_that("empirical_formal_model errors on invalid data", {
  bad_plant <- .synthetic_retention
  bad_plant$retention <- NULL
  expect_error(empirical_formal_model(bad_plant, .synthetic_bird), "missing required columns")

  bad_bird <- .synthetic_bird
  bad_bird$observed_rank <- NULL
  expect_error(empirical_formal_model(.synthetic_retention, bad_bird), "missing required columns")
})
