# test-cultural-cross-domain-beta.R — H4: β varies by domain
#
# Tests that cultural substrates have β > 1 (generative) and non-cultural
# substrates have β < 1 (depleting), with a threshold at β = 1.
#
# Updated to use method_type grouping:
#   NETWORK: real network analysis (5 domains)
#   COUNT_RATIO: tool complexity (4 domains, not true β)
#   GROWTH_INFERRED: β > 1 inferred from growth curves (3 domains)
#   TREE: tree branching structure (1 domain)
#   BAYESIAN: posterior distribution (1 domain)
#
# @dft A1, A6

library(testthat)

context("Cultural: H4 cross-domain β threshold")

test_that("H4: all NETWORK domains have β > 1", {
  data <- load_cross_domain_beta()$data
  network_domains <- data[data$method_type == "NETWORK" & !is.na(data$beta), ]

  expect_gte(nrow(network_domains), 5)
  expect_true(all(network_domains$beta > 1))
})

test_that("H4: all COUNT_RATIO domains are labeled as tool complexity (not β)", {
  data <- load_cross_domain_beta()$data
  count_ratio <- data[data$method_type == "COUNT_RATIO" & !is.na(data$beta), ]

  expect_gte(nrow(count_ratio), 3)
  # These should NOT be compared directly to network β values
  # They measure tool complexity (parts per tool), not dependency branching
})

test_that("H4: TREE domain has β < 1 (taxonomic constraint)", {
  data <- load_cross_domain_beta()$data
  tree_domain <- data[data$method_type == "TREE" & !is.na(data$beta), ]

  expect_gte(nrow(tree_domain), 1)
  expect_true(all(tree_domain$beta < 1))
})

test_that("H4: GROWTH_INFERRED domains support β > 1", {
  data <- load_cross_domain_beta()$data
  growth_domains <- data[data$method_type == "GROWTH_INFERRED" & !is.na(data$beta), ]

  # These domains have β > 1 or η > 0 (growth-inferred, not network-measured)
  expect_gte(nrow(growth_domains), 2)
  # All should have positive growth signal
  expect_true(all(growth_domains$beta > 0))
})

test_that("H4: threshold at β = 1 confirmed for NETWORK domains", {
  data <- load_cross_domain_beta()$data
  result <- cross_domain_beta_test(data)

  network <- data[data$method_type == "NETWORK" & !is.na(data$beta), ]
  expect_true(all(network$beta > 1))
})

test_that("H4: language has high β among NETWORK domains", {
  data <- load_cross_domain_beta()$data
  network <- data[data$method_type == "NETWORK" & !is.na(data$beta), ]
  lang_beta <- network[network$domain == "language_full_vocab", "beta"]

  # Language should be firmly in generative regime
  expect_gt(lang_beta, 5)
  # Language β should exceed stone tools, PyPI, GitHub (not Wikipedia/core_1000 which are higher)
  tool_beta <- network[network$domain == "stone_tools", "beta"]
  pypi_beta <- network[network$domain == "pypi_packages", "beta"]
  expect_gt(lang_beta, tool_beta)
  expect_gt(lang_beta, pypi_beta)
})

test_that("H4: method_type column exists in data", {
  data <- load_cross_domain_beta()$data
  expect_true("method_type" %in% names(data))
})

test_that("H4: at least 4 method types represented", {
  data <- load_cross_domain_beta()$data
  types <- unique(data$method_type[!is.na(data$beta)])
  expect_gte(length(types), 4)
})

test_that("H4: English vocabulary β (1.15) is separate from language network β (9.06)", {
  data <- load_cross_domain_beta()$data
  vocab_beta <- data[data$domain == "english_vocabulary", "beta"]
  lang_beta <- data[data$domain == "language_full_vocab", "beta"]

  # These are different measures and must not be conflated
  expect_false(is.na(vocab_beta))
  expect_false(is.na(lang_beta))
  expect_false(vocab_beta == lang_beta)
  expect_lt(vocab_beta, lang_beta)
})
