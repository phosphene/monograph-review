# test-unit-cross-kingdom.R — Unit tests for cross-kingdom parameter transfer

library(testthat)

context("Cross-kingdom transfer")

# === fit_plant_model ===

test_that("fit_plant_model returns valid result on fixture data", {
  data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
  result <- fit_plant_model(data, seed = 42)
  expect_true(validate_result(result))
  expect_gt(result$values[["slope"]], 0) # Positive: deeper = retained longer
  expect_gte(result$values[["r_squared"]], 0.9)
})

test_that("fit_plant_model is deterministic with same seed (A2)", {
  data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    lineage1_loss_rank = c(1, 3, 2, 4, 6, 5)
  )
  r1 <- fit_plant_model(data, seed = 42)
  r2 <- fit_plant_model(data, seed = 42)
  expect_equal(r1$values, r2$values)
})

# === predict_bird_ordering ===

test_that("predict_bird_ordering returns ranks matching dependency ordering", {
  bird_data <- data.frame(
    structure = c(
      "wing", "keel", "pectoral", "hindlimb", "pelvis",
      "feathers", "wing_bones", "asymmetry"
    ),
    dependency_score = c(0.0, 1.0, 0.5, 4.0, 3.0, 5.0, 1.5, 1.0),
    observed_rank = c(1, 2, 3, 4, 5, 6, 7, 8)
  )
  predicted <- predict_bird_ordering(bird_data, plant_slope = 0.6)
  expect_length(predicted, 8)
  # A positive plant slope transfers the dependency ordering DIRECTLY
  # (predicted = plant_slope * dep, rank 1 = first to change). The whole
  # ordering-concordance contract is monotonicity: predicted rank is
  # non-decreasing in dependency_score (high dep -> changes late -> high
  # rank). The sign-error bug inverted this; assert the full ordering.
  expect_gt(
    predicted[which(bird_data$dependency_score == 5)],
    predicted[which(bird_data$dependency_score == 0)]
  )
  # Monotone: order of predicted ranks equals order of dependency scores
  # (handles ties correctly — the two dep=1.0 entries get average rank 2.5)
  expect_identical(order(predicted), order(bird_data$dependency_score))
  # Rank range sanity: values span 1..n (average-rank ties allowed)
  expect_equal(min(predicted), 1)
  expect_equal(max(predicted), length(predicted))
})

test_that("predict_bird_ordering validates bird morphology (contract)", {
  bird_data <- data.frame(
    structure = c("a", "b"),
    dependency_score = c(0, 1),
    observed_rank = c(1, 2)
  )
  expect_error(predict_bird_ordering(bird_data, 0.5), "need >= 5")
})

# === transfer_test (full pipeline) ===

test_that("transfer_test returns A6 proof object with plant slope and bird rho", {
  plant_data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
  bird_data <- data.frame(
    structure = c(
      "wing", "keel", "pectoral", "hindlimb", "pelvis",
      "feathers", "wing_bones", "asymmetry"
    ),
    dependency_score = c(0.0, 1.0, 0.5, 4.0, 3.0, 5.0, 1.5, 1.0),
    observed_rank = c(1, 3, 2, 4, 5, 6, 7, 8)
  )
  result <- transfer_test(plant_data, bird_data, seed = 42)
  expect_true(validate_result(result))
  expect_true("plant_slope" %in% names(result$values))
  expect_true("bird_rho" %in% names(result$values))
  expect_true("null_rho" %in% names(result$values))
})

test_that("transfer_test is deterministic with same seed (A2)", {
  plant_data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    lineage1_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
  bird_data <- data.frame(
    structure = c("a", "b", "c", "d", "e", "f", "g", "h"),
    dependency_score = c(0, 0.5, 1, 1.5, 2, 3, 4, 5),
    observed_rank = c(1, 2, 3, 4, 5, 6, 7, 8)
  )
  r1 <- transfer_test(plant_data, bird_data, seed = 42)
  r2 <- transfer_test(plant_data, bird_data, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("transfer_test null control has a null p-value from a distribution", {
  # With perfectly ordered plant data and correlated bird data,
  # the plant slope should predict bird ordering better than random.
  # The null is now a 1000-draw distribution (not a single random slope).
  plant_data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    lineage1_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
  bird_data <- data.frame(
    structure = c("a", "b", "c", "d", "e", "f", "g", "h"),
    dependency_score = c(0, 0.5, 1, 1.5, 2, 3, 4, 5),
    observed_rank = c(1, 2, 3, 4, 5, 6, 7, 8)
  )
  result <- transfer_test(plant_data, bird_data, seed = 42)
  expect_true(is.finite(result$values[["bird_rho"]]))
  # null_p is a proper p-value from a null distribution, in [0, 1]
  expect_true(is.numeric(result$values[["null_p"]]))
  expect_gte(result$values[["null_p"]], 0)
  expect_lte(result$values[["null_p"]], 1)
  expect_true(is.numeric(result$values[["null_rho"]]))
})
