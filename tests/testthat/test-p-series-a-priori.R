# test-p-series-a-priori.R — P-series a priori integration-depth gate
#
# Pre-registration discipline: score files frozen in data/a-priori-scores/
# BEFORE outcome merge. Each stage consumes a frozen score file, merges the
# documented outcome, and returns an A6 proof object.

library(testthat)
library(valence.foundry)

has_pkg <- function(p) requireNamespace(p, quietly = TRUE)
ap <- function(...) testthat::test_path("..", "..", "data", "a-priori-scores", ...)

test_that("P1: Buchnera two-component — A6 proof object with both components", {
  f <- ap("p1_buchnera_scores.tsv")
  skip_if_not(file.exists(f), "p1 score file not bundled")
  s <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  r <- p1_buchnera_two_component(s)
  expect_true(validate_result(r))
  expect_true(all(c("beta_B", "p_B", "beta_A", "p_A", "pseudo_r2_AB") %in% names(r$values)))
  expect_true(is.numeric(r$values$beta_B_AB))
})

test_that("P2: LTEE niche FBA — A6 proof object, timing outcome present", {
  f <- ap("p2_ltee_scores.tsv")
  skip_if_not(file.exists(f), "p2 score file not bundled")
  s <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  expect_true("first_gen" %in% names(s), info = "outcome merged at registration")
  r <- p2_ltee_niche_fba(s)
  expect_true(validate_result(r))
  expect_true(all(c("median_first_gen_high_mismatch", "median_first_gen_low_mismatch", "p_earlier_high_mismatch") %in% names(r$values)))
})

test_that("P3: Plastid erosion order — A6 proof object with a priori dependency", {
  f <- testthat::test_path("..", "..", "data", "orobanchaceae_retention_matrix.tsv")
  skip_if_not(file.exists(f), "retention matrix not bundled")
  s <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  r <- p3_plastid_erosion_order(s)
  expect_true(validate_result(r))
  expect_true(all(c("mean_species_rho", "n_species_with_signal", "beta_dependency", "p_dependency") %in% names(r$values)))
})

test_that("P4: Echolocation centrality — a priori contrast, predicted direction", {
  f <- ap("p4_echolocation_symbols.tsv")
  skip_if_not(file.exists(f), "p4 symbol file not bundled")
  cf <- testthat::test_path("..", "..", "data", "raw", "echolocation", "string_centralities.json")
  mf <- testthat::test_path("..", "..", "data", "raw", "echolocation", "string_maps.json")
  skip_if_not(file.exists(cf) && file.exists(mf), "p4 string data not bundled")
  s <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  centralities <- jsonlite::fromJSON(cf, simplifyVector = FALSE)
  maps <- jsonlite::fromJSON(mf, simplifyVector = FALSE)
  r <- p4_echolocation_centrality(s, centralities, maps$sym_to_prot)
  expect_true(validate_result(r))
  expect_true(r$values$n_convergent > 100, info = "most convergent genes mapped")
  # the framework's prediction: convergent < conserved in the domain. Degree is the primary metric.
  expect_true(r$values$deg$conv_mean < r$values$deg$cons_mean)
  expect_true(r$values$deg$p_conv_less < 0.05, info = "signed prediction holds for degree")
})

test_that("P5: C4 syndrome — invariant elements high in integration hierarchy", {
  f <- ap("p5_c4_syndrome.tsv")
  skip_if_not(file.exists(f), "p5 syndrome file not bundled")
  s <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  s <- s[s$level != "Niche", ]  # environmental context, not organismal trait
  r <- p5_c4_integration_depth(s)
  expect_true(validate_result(r))
  # Structural: invariant elements all in the upper half of the hierarchy
  expect_true(r$values$n_invariant_lower == 0)
  expect_true(r$values$rho_depth_invariance > 0, info = "integration depth positively correlates with invariance")
})
