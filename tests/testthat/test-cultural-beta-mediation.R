# test-cultural-beta-mediation.R — H2: β mediates N → complexity
#
# Tests using Oswalt (1973, 1976) data that β (branching factor) is a
# substrate property that predicts complexity, while population size
# does not predict β.
#
# @section Theoretical Context:
#
# the framework's prediction: β is substrate property, not demographic. β predicts
# complexity; N does not predict β. Competitor: demographic hypothesis
# (Henrich, Kline & Boyd) predicts N directly predicts complexity.
#
# @dft A1, A6

library(testthat)

context("Cultural: H2 β mediation (Oswalt 1973 + 1976)")

# ---- H2a: Oswalt 1973 (n=12) — full mediation ----

test_that("H2a Oswalt 1973: N does not predict β", {
  data <- load_oswalt_1973()$data
  result <- beta_mediation_test(data)

  # N → β should NOT be significant
  expect_gt(result$values$p_N_beta, 0.05)
})

test_that("H2a Oswalt 1973: β predicts complexity", {
  data <- load_oswalt_1973()$data
  result <- beta_mediation_test(data)

  # β → complexity should be significant
  expect_lt(result$values$p_beta_complexity, 0.05)
  # Strong correlation
  expect_gt(result$values$r_beta_complexity, 0.7)
})

test_that("H2a Oswalt 1973: full mediation (N drops controlling for β)", {
  data <- load_oswalt_1973()$data
  result <- beta_mediation_test(data)

  # Controlling for β, N should not predict complexity
  expect_gt(result$values$p_N_given_beta, 0.05)
  # Controlling for N, β should still predict complexity
  expect_lt(result$values$p_beta_given_N, 0.05)
  # Mediation type
  expect_equal(result$values$mediation_type, "full")
})

# ---- H2b: Oswalt 1976 (n=29) — partial mediation ----

test_that("H2b Oswalt 1976: N does not predict β", {
  data <- load_oswalt_1976()$data
  result <- beta_mediation_test(data)

  # N → β should NOT be significant
  expect_gt(result$values$p_N_beta, 0.05)
})

test_that("H2b Oswalt 1976: β predicts complexity strongly", {
  data <- load_oswalt_1976()$data
  result <- beta_mediation_test(data)

  # β → complexity should be highly significant
  expect_lt(result$values$p_beta_complexity, 0.001)
  # Strong correlation
  expect_gt(result$values$r_beta_complexity, 0.7)
})

test_that("H2b Oswalt 1976: β is stronger predictor than N (partial mediation)", {
  data <- load_oswalt_1976()$data
  result <- beta_mediation_test(data)

  # β controlling for N should be stronger than N controlling for β
  expect_gt(
    abs(result$values$r_beta_given_N),
    abs(result$values$r_N_given_beta)
  )
  # β still significant controlling for N
  expect_lt(result$values$p_beta_given_N, 0.001)
})

test_that("H2b Oswalt 1976: n >= 25 for adequate power", {
  data <- load_oswalt_1976()$data
  expect_gte(nrow(data), 25)
})
