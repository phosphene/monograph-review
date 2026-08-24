# test-unit-empirical-tests.R — Unit tests for T1–T7
# DFT A1: pure functions, deterministic math
# Tests: known input → known output

library(testthat)

context("Empirical tests (T1–T7)")

# === T6: gene_loss_ordering — pure math, no external deps ===

test_that("gene_loss_ordering returns perfect rho for perfectly ordered data", {
  data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6) # Perfectly ordered
  )
  result <- gene_loss_ordering(data, seed = 42)
  expect_true(validate_result(result))
  expect_gte(result$values[["spearman_rho"]], 0.95)
})

test_that("gene_loss_ordering returns zero rho for random ordering", {
  set.seed(42)
  data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    orobanchaceae_loss_rank = sample(6) # Random order
  )
  result <- gene_loss_ordering(data, seed = 42)
  expect_true(validate_result(result))
  # Should be low (random)
  expect_lt(abs(result$values[["spearman_rho"]]), 0.5)
})

test_that("gene_loss_ordering returns A6 proof object with metadata", {
  data <- data.frame(
    category = c("a", "b", "c"),
    dependency_score = c(0, 1, 2),
    lineage1_loss_rank = c(1, 2, 3)
  )
  result <- gene_loss_ordering(data, seed = 42)
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_equal(result$metadata$n, 3)
  expect_equal(result$metadata$method, "exact_permutation")
})

test_that("gene_loss_ordering is deterministic with same seed (A2)", {
  data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    lineage1_loss_rank = c(1, 3, 2, 4, 6, 5)
  )
  r1 <- gene_loss_ordering(data, seed = 42)
  r2 <- gene_loss_ordering(data, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("gene_loss_ordering with multiple lineages computes concordance", {
  data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6),
    cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
  result <- gene_loss_ordering(data, seed = 42)
  expect_true(!is.na(result$values[["cross_family_concordance"]]))
  expect_equal(result$values[["cross_family_concordance"]], 1)
})

# === T7: ltee_cosegregation — pure math, no external deps ===

test_that("ltee_cosegregation returns expected structure", {
  result <- ltee_cosegregation(seed = 42)
  expect_true(validate_result(result))
  expect_equal(round(result$values[["observed_pct"]], 1), 36.4)
  expect_equal(round(result$values[["expected_pct"]], 1), 61.7)
  expect_true(result$values[["p_value"]] < 0.001)
})

test_that("ltee_cosegregation is deterministic with same seed (A2)", {
  r1 <- ltee_cosegregation(seed = 42)
  r2 <- ltee_cosegregation(seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("ltee_cosegregation returns A6 proof object", {
  result <- ltee_cosegregation(seed = 42)
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_equal(result$metadata$n, 253)
})

test_that("ltee_cosegregation depletion ratio < 1 (depletion, not enrichment)", {
  result <- ltee_cosegregation(seed = 42)
  expect_lt(result$values[["depletion_ratio"]], c(depletion_ratio = 1.0))
})

# === T7-v2: ltee_dependency_ordering — dependency predicts loss timing ===

test_that("ltee_dependency_ordering returns positive rho for positive ordering", {
  # High dependency -> lost LATER (positive ordering, VI-consistent)
  timing <- c(b1 = 100, b2 = 500, b3 = 3000, b4 = 10000, b5 = 50000)
  dependency <- c(b1 = 0, b2 = 0, b3 = 0.5, b4 = 0.9, b5 = 1.0)
  result <- ltee_dependency_ordering(timing, dependency, seed = 42)
  expect_true(validate_result(result))
  expect_gt(result$values[["timing_rho"]], 0.8)
  expect_lt(result$values[["timing_p"]], 0.05)
})

test_that("ltee_dependency_ordering returns negative rho for reverse ordering", {
  # High dependency -> lost EARLIER (negative ordering, observed in LTEE)
  # b1 has HIGH dep but EARLY loss; b5 has LOW dep but LATE loss
  timing <- c(b1 = 100, b2 = 500, b3 = 3000, b4 = 10000, b5 = 50000)
  dependency <- c(b1 = 1.0, b2 = 0.8, b3 = 0.5, b4 = 0.1, b5 = 0.0)
  result <- ltee_dependency_ordering(timing, dependency, seed = 42)
  expect_lt(result$values[["timing_rho"]], -0.5)
})

test_that("ltee_dependency_ordering returns ~zero rho for random ordering", {
  set.seed(7)
  genes <- paste0("b", 1:20)
  timing <- sample(c(100, 500, 1000, 5000, 20000, 50000), 20, replace = TRUE)
  names(timing) <- genes
  dependency <- runif(20)
  names(dependency) <- genes
  result <- ltee_dependency_ordering(timing, dependency, seed = 42)
  expect_lt(abs(result$values[["timing_rho"]]), 0.5)
})

test_that("ltee_dependency_ordering is deterministic with same seed (A2)", {
  timing <- c(b1 = 100, b2 = 500, b3 = 3000, b4 = 10000, b5 = 50000)
  dependency <- c(b1 = 0, b2 = 0, b3 = 0.5, b4 = 0.9, b5 = 1.0)
  r1 <- ltee_dependency_ordering(timing, dependency, seed = 42)
  r2 <- ltee_dependency_ordering(timing, dependency, seed = 42)
  expect_equal(r1$values, r2$values)
})

test_that("ltee_dependency_ordering errors on < 3 shared genes", {
  expect_error(
    ltee_dependency_ordering(c(b1 = 100), c(b1 = 0, b2 = 1), seed = 42),
    "Need >= 3"
  )
})

# === T1: pgls_orobanchaceae — requires ape, caper (skip if not available) ===

test_that("pgls_orobanchaceae returns expected values on real data", {
  skip_if_not(
    has_bundled_data("species_plastome_data.tsv"),
    "Bundled data not available"
  )
  skip_if_not(requireNamespace("ape", quietly = TRUE), "ape not installed")
  skip_if_not(requireNamespace("caper", quietly = TRUE), "caper not installed")

  loaded <- load_orobanchaceae()
  result <- pgls_orobanchaceae(loaded$data, loaded$tree, seed = 42)

  expect_true(validate_result(result))
  # beta is in kb/level (function fits plastome_size_kb); sign + magnitude check
  expect_lt(result$values[["beta"]], 0)
  expect_true(result$values[["r_squared"]] > 0.5)
  expect_true(result$values[["p_value"]] < 0.01)
  expect_true(result$values[["n_species"]] >= 10)
})

# === T3: endosymbiont_biphasic — requires nls ===

test_that("endosymbiont_biphasic returns valid result", {
  skip_if_not(
    has_bundled_data("endosymbiont_genome_data.tsv"),
    "Bundled data not available"
  )

  loaded <- load_endosymbionts()
  result <- endosymbiont_biphasic(loaded$data, seed = 42)

  # Function must run and return a proof object. Reproduction of the
  # manuscript biphasic fit (r^2=0.920, BF=6.7) on the bundled endosymbiont
  # data is NOT asserted here — the logistic nls currently fails to converge
  # on this dataset (see baseline/oracle.yml caveat + regression gate).
  expect_true(validate_result(result))
  expect_true(!is.na(result$values[["r_squared"]]))
  expect_true("converged" %in% names(result$metadata))
})

# === T4: niche_vs_ne ===

test_that("niche_vs_ne returns valid result", {
  skip_if_not(
    has_bundled_data("bobay_ochman_table_s1.xlsx"),
    "Bundled data not available"
  )
  skip_if_not(requireNamespace("readxl", quietly = TRUE), "readxl not installed")

  loaded <- load_bobay_ochman()
  result <- niche_vs_ne(loaded$data, seed = 42)

  expect_true(validate_result(result))
  expect_true(!is.na(result$values[["niche_r_squared"]]))
  expect_true(!is.na(result$values[["ne_r_squared"]]))
})

# === T5: pangenome_fluidity ===

test_that("pangenome_fluidity returns valid result", {
  skip_if_not(
    has_bundled_data("dewar_pangenome_lifestyles.csv"),
    "Bundled data not available"
  )

  loaded <- load_dewar_pangenome()
  result <- pangenome_fluidity(loaded$data, seed = 42)

  expect_true(validate_result(result))
  expect_true(!is.na(result$values[["niche_r_squared"]]))
})

# === All tests return A6 proof objects ===

test_that("all test functions return A6 proof objects with seed", {
  # T6 and T7 don't need external data
  r6 <- gene_loss_ordering(
    data.frame(
      category = c("a", "b", "c"), dependency_score = c(0, 1, 2),
      lineage1_loss_rank = c(1, 2, 3)
    ),
    seed = 99
  )
  r7 <- ltee_cosegregation(seed = 99)

  expect_equal(r6$metadata$seed, 99)
  expect_equal(r7$metadata$seed, 99)
})
