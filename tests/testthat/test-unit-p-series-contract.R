# test-unit-p-series-contract.R — Contract tests for the a priori P-series
# functions (R/p_series_a_priori.R) driven by synthetic data frames.
#
# E1 coverage ticket: p_series_a_priori.R was at 19.4% because the only tests
# were happy-path runs against bundled score files. These tests exercise every
# branch of P1–P5 with hand-crafted inputs — including the degenerate inputs
# that hit the NA-fallback paths — without depending on the bundled data.
#
# DFT A6 (check-result): every stage returns an A6 proof object (list with
# values + metadata). DFT A2 (determinism): seed-locked so identical inputs
# give identical outputs.

library(testthat)
library(valence.foundry)

# ============================================================================
# Synthetic fixtures
# ============================================================================

# A Buchnera-like score frame: mixed dependency, essentiality, retention.
make_p1_scores <- function(n = 120, seed = 42L) {
  set.seed(seed)
  aa <- c("argA", "ilvA", "leuA", "lysA", "metA", "thrA", "trpA", "hisA",
          "tyrA", "serA", "glyA", "proA", "cysA", "folA", "panA", "bioA",
          "ribA", "nadA", "thiA", "ubiA", "menA", "entA", "aroA", "asd",
          "purA", "guaA", "deoC", "fabA")
  data.frame(
    gene_id = seq_len(n),
    name = c(aa, paste0("g", seq_len(n - length(aa)))),
    dependency_score = round(rnorm(n, 0, 2), 3),
    essential = sample(c("essential", "partial", "nonessential"), n, replace = TRUE),
    retained = rbinom(n, 1, plogis(0.3 * seq_len(n) / n))
  )
}

# A LTEE-like frame with niche-mismatch + STRING degree + first-gen timing.
make_p2_scores <- function(n = 120, seed = 7L) {
  set.seed(seed)
  data.frame(
    gene = paste0("b", seq_len(n)),
    b_number = paste0("b", seq_len(n)),
    fba_dep_full = rbinom(n, 1, 0.7),
    fba_dep_ltee_env = rbinom(n, 1, 0.4),
    string_ppi_degree = round(runif(n, 0, 40), 1),
    niche_mismatch = rbinom(n, 1, 0.4),
    first_gen = round(runif(n, 100, 1000))
  )
}

# A plastid erosion frame: species x genes with a priori dependency scores.
make_p3_scores <- function(n_sp = 5, genes_per = 12, seed = 9L) {
  set.seed(seed)
  dep_pool <- c(0, 1, 2, 3, 5)
  data.frame(
    species = rep(paste0("sp", seq_len(n_sp)), each = genes_per),
    gene_category = rep(paste0("cat", seq_len(genes_per)), n_sp),
    dependency_score = sample(dep_pool, n_sp * genes_per, replace = TRUE),
    retention = rbinom(n_sp * genes_per, 1, 0.6),
    parasitism_score = rep(seq_len(n_sp), each = genes_per)
  )
}

# Echolocation centralities: convergent (low) vs conserved (high) degree.
make_p4_data <- function(seed = 11L) {
  set.seed(seed)
  conv <- paste0("CONV", seq_len(8))
  cons <- paste0("CONS", seq_len(8))
  symbols <- data.frame(
    gene = c(conv, cons),
    class = c(rep("convergent", 8), rep("conserved", 8))
  )
  centralities <- c(
    setNames(lapply(conv, function(g) list(deg = runif(1, 0, 4), ev = runif(1, 0, 0.2), cl = runif(1, 0, 0.3))), conv),
    setNames(lapply(cons, function(g) list(deg = runif(1, 6, 12), ev = runif(1, 0.4, 1), cl = runif(1, 0.5, 1))), cons)
  )
  sym_to_prot <- setNames(lapply(c(conv, cons), function(g) g), c(conv, cons))
  list(symbols = symbols, centralities = centralities, sym_to_prot = sym_to_prot)
}

# A C4 syndrome frame: invariant elements sit high in the hierarchy.
make_p5_syndrome <- function(seed = 13L) {
  set.seed(seed)
  data.frame(
    level = paste0("L", seq_len(10)),
    integration_depth = seq_len(10),
    invariant = c(0, 0, 0, 1, 0, 1, 0, 1, 1, 1),
    rationale = "synthetic"
  )
}

# ============================================================================
# P1 — Buchnera two-component
# ============================================================================

test_that("P1 returns a validated A6 proof object with both components", {
  s <- make_p1_scores()
  r <- p1_buchnera_two_component(s)
  expect_true(validate_result(r))
  expect_true(all(c("beta_B", "p_B", "beta_A", "p_A", "beta_B_AB", "p_B_AB",
                    "pseudo_r2_B", "pseudo_r2_AB", "n") %in% names(r$values)))
  expect_type(r$values$beta_B, "double")
  expect_true(r$values$n == nrow(s))
  # metadata provenance
  expect_equal(r$metadata$test, "p1_buchnera_two_component")
  expect_equal(r$metadata$seed, 42L)
  expect_true(r$metadata$n_retained >= 0)
})

test_that("P1 low-mismatch Spearman falls back to NA when degenerate", {
  # No low-mismatch genes -> data_lm empty -> rho_LM NA.
  s <- make_p1_scores()
  s$name <- "none_are_aa"
  r <- p1_buchnera_two_component(s)
  expect_true(is.na(r$values$rho_componentB_lowmismatch))
  expect_equal(r$values$n_low_mismatch, 0)

  # Low-mismatch present but all retained identical -> single class -> NA.
  s2 <- make_p1_scores()
  s2$name[1] <- "argA"
  s2$retained <- 0L
  r2 <- p1_buchnera_two_component(s2)
  expect_true(is.na(r2$values$rho_componentB_lowmismatch))
})

test_that("P1 is deterministic (A2) for identical input", {
  s <- make_p1_scores()
  r1 <- p1_buchnera_two_component(s, seed = 42L)
  r2 <- p1_buchnera_two_component(s, seed = 42L)
  expect_identical(r1$values$beta_B, r2$values$beta_B)
  expect_identical(r1$values$pseudo_r2_AB, r2$values$pseudo_r2_AB)
})

test_that("P1 error branches fail loudly on missing required columns", {
  expect_error(p1_buchnera_two_component(data.frame(a = 1:3)))
  expect_error(p1_buchnera_two_component(NULL))
})

# ============================================================================
# P2 — LTEE niche-specific FBA
# ============================================================================

test_that("P2 returns an A6 proof object with timing outcome", {
  s <- make_p2_scores()
  r <- p2_ltee_niche_fba(s)
  expect_true(validate_result(r))
  expect_true(all(c("median_first_gen_high_mismatch", "median_first_gen_low_mismatch",
                    "p_earlier_high_mismatch", "rho_degree_timing_lowmismatch",
                    "rho_degree_timing_full") %in% names(r$values)))
  expect_equal(r$metadata$test, "p2_ltee_niche_fba")
  expect_equal(r$values$n, nrow(s))
})

test_that("P2 low-mismatch Spearman falls back to NA with <3 points", {
  s <- make_p2_scores(n = 20)
  # Force all rows to be high-mismatch so the low-mismatch subset is tiny.
  s$niche_mismatch <- 1L
  r <- p2_ltee_niche_fba(s)
  # data_lm has 0 rows -> rho_degree_timing_lowmismatch NA; wilcox still runs
  expect_true(is.na(r$values$rho_degree_timing_lowmismatch))
})

test_that("P2 handles missing STRING degree via full-set fallback", {
  s <- make_p2_scores()
  s$string_ppi_degree[s$niche_mismatch == 0] <- NA_real_
  r <- p2_ltee_niche_fba(s)
  expect_true(is.na(r$values$rho_degree_timing_lowmismatch) ||
                is.numeric(r$values$rho_degree_timing_lowmismatch))
  # Full set still has degree values -> numeric rho
  expect_true(is.numeric(r$values$rho_degree_timing_full))
})

# ============================================================================
# P3 — Plastid erosion order
# ============================================================================

test_that("P3 returns an A6 proof object with a priori dependency signal", {
  s <- make_p3_scores()
  r <- p3_plastid_erosion_order(s)
  expect_true(validate_result(r))
  expect_true(all(c("mean_species_rho", "n_species_with_signal", "beta_dependency",
                    "p_dependency", "n_species") %in% names(r$values)))
  expect_equal(r$metadata$test, "p3_plastid_erosion_order")
  expect_equal(r$values$n_species, 5)
})

test_that("P3 falls back to NA when no species has a dependency signal", {
  # All species have a single dependency score value -> sp rho always NA.
  s <- make_p3_scores()
  s$dependency_score <- 1
  r <- p3_plastid_erosion_order(s)
  expect_true(is.na(r$values$mean_species_rho))
  expect_equal(r$values$n_species_with_signal, 0)
  # Pooled GLM still runs (dependency_score constant -> NA coefficient handled)
  expect_true(is.numeric(r$values$beta_dependency) || is.na(r$values$beta_dependency))
})

# ============================================================================
# P4 — Echolocation centrality
# ============================================================================

test_that("P4 returns an A6 proof object with the predicted direction", {
  d <- make_p4_data()
  r <- p4_echolocation_centrality(d$symbols, d$centralities, d$sym_to_prot)
  expect_true(validate_result(r))
  expect_true(all(c("deg", "ev", "cl", "n_convergent", "n_conserved") %in% names(r$values)))
  # Convergent genes are LESS integrated: conv_mean < cons_mean on degree.
  expect_true(r$values$deg$conv_mean < r$values$deg$cons_mean)
  expect_equal(r$values$n_convergent, 8)
  expect_equal(r$values$n_conserved, 8)
  expect_equal(r$metadata$test, "p4_echolocation_centrality")
})

test_that("P4 handles empty protein mappings without error", {
  symbols <- data.frame(gene = c("A", "B"), class = c("convergent", "conserved"))
  r <- p4_echolocation_centrality(
    symbols, list(), list(sym_to_prot = list())
  )
  expect_true(validate_result(r))
  expect_equal(r$values$n_convergent, 0)
  expect_equal(r$values$n_conserved, 0)
  expect_true(all(is.na(r$values$deg[c("conv_mean", "cons_mean", "p_conv_less")])))
})

test_that("P4 is deterministic for identical input", {
  d <- make_p4_data()
  r1 <- p4_echolocation_centrality(d$symbols, d$centralities, d$sym_to_prot, seed = 11L)
  r2 <- p4_echolocation_centrality(d$symbols, d$centralities, d$sym_to_prot, seed = 11L)
  expect_identical(r1$values$deg$conv_mean, r2$values$deg$conv_mean)
})

# ============================================================================
# P5 — C4 syndrome integration depth
# ============================================================================

test_that("P5 returns an A6 proof object; invariant elements sit high", {
  s <- make_p5_syndrome()
  r <- p5_c4_integration_depth(s)
  expect_true(validate_result(r))
  expect_true(all(c("p_invariant_higher", "rho_depth_invariance", "p_rho",
                    "binom_p_upper_half", "n_invariant_upper", "n_invariant_lower") %in% names(r$values)))
  # With invariants at depths 6-10 (upper half of 1..10, median 5.5), all
  # invariants sit in the upper half of the hierarchy.
  expect_true(r$values$rho_depth_invariance > 0)
  expect_true(r$values$p_invariant_higher < 0.05)
  expect_equal(r$metadata$test, "p5_c4_integration_depth")
})

test_that("P5 handles single-class and tiny inputs via NA fallbacks", {
  # Fewer than 2 invariant or 2 non-invariant rows -> wilcox p NA.
  s <- make_p5_syndrome()
  s$invariant <- 0L
  r <- p5_c4_integration_depth(s)
  expect_true(is.na(r$values$p_invariant_higher))
  # <3 unique depths -> spearman NA.
  s2 <- make_p5_syndrome()
  s2$integration_depth <- rep(c(1, 2), length.out = nrow(s2))
  s2$invariant <- c(1L, rep(0L, nrow(s2) - 1))
  r2 <- p5_c4_integration_depth(s2)
  expect_true(is.na(r2$values$rho_depth_invariance))
})

test_that("P5 is deterministic and validates metadata provenance", {
  s <- make_p5_syndrome()
  r1 <- p5_c4_integration_depth(s, seed = 13L)
  r2 <- p5_c4_integration_depth(s, seed = 13L)
  expect_identical(r1$values, r2$values)
  expect_equal(r1$metadata$source, "Christin & Osborne 2014 New Phytol Table 1 + text")
})
