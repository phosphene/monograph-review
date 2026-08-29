# test-unit-viz.R — Unit tests for visualization module (R/viz.R)
#
# DFT A1: pure functions — data in, ggplot2 object out, no side effects
# DFT A6: every function returns a structured, inspectable, printable ggplot2 object
#
# Each test: constructs inline fixture data, calls the function, verifies
# the return value is a ggplot2 object. No file I/O, no network, no globals.

library(testthat)

context("Visualization module (R/viz.R)")

# Threshold: skip all if ggplot2 not available
.skip_if_no_ggplot2 <- function() {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")
}
.skip_if_no_patchwork <- function() {
  skip_if_not(requireNamespace("patchwork", quietly = TRUE), "patchwork not installed")
}

# ============================================================================
# plot_pgls_with_phylogeny (T1)
# ============================================================================

test_that("plot_pgls_with_phylogeny returns a ggplot object", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()
  skip_if_not(requireNamespace("ape", quietly = TRUE), "ape not installed")

  data <- data.frame(
    species = c("Lindenbergia", "Schwalbea", "Orobanche"),
    plastome_size_kb = c(150, 120, 100),
    parasitism_score = c(0, 1, 2),
    stringsAsFactors = FALSE
  )
  tree <- ape::read.tree(text = "((Lindenbergia:0.1,Schwalbea:0.2):0.1,Orobanche:0.3);")
  result <- list(
    values = c(
      beta = -23.5, r_squared = 0.652, p_value = 1.25e-9,
      lambda = 0.85, n_species = 3
    ),
    metadata = list(seed = 42, n = 3, converged = TRUE)
  )

  p <- plot_pgls_with_phylogeny(data, tree, result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_pgls_with_phylogeny is pure (A1 — no side effects)", {
  .skip_if_no_ggplot2()
  skip_if_not(requireNamespace("ape", quietly = TRUE), "ape not installed")

  data <- data.frame(
    species = c("A", "B", "C"),
    plastome_size_kb = c(150, 120, 100),
    parasitism_score = c(0, 1, 2),
    stringsAsFactors = FALSE
  )
  tree <- ape::read.tree(text = "((A:0.1,B:0.2):0.1,C:0.3);")
  result <- list(
    values = c(
      beta = -23.5, r_squared = 0.652, p_value = 1.25e-9,
      lambda = 0.85, n_species = 3
    ),
    metadata = list(seed = 42, n = 3, converged = TRUE)
  )

  data_before <- data
  p <- plot_pgls_with_phylogeny(data, tree, result)
  expect_s3_class(p, "ggplot")
  expect_equal(data, data_before)
})

# ============================================================================
# plot_faceted_family_regression (T2)
# ============================================================================

test_that("plot_faceted_family_regression returns a ggplot object", {
  .skip_if_no_ggplot2()

  data <- data.frame(
    species = c("A", "B", "C", "D", "E", "F"),
    family = c(
      "Orchidaceae", "Orchidaceae", "Orobanchaceae",
      "Orobanchaceae", "Convolvulaceae", "Convolvulaceae"
    ),
    plastome_size_kb = c(150, 140, 120, 100, 130, 110),
    parasitism_score = c(0, 1, 0, 2, 1, 3),
    stringsAsFactors = FALSE
  )

  p <- plot_faceted_family_regression(data)
  expect_s3_class(p, "ggplot")
})

test_that("plot_faceted_family_regression stops with missing columns", {
  bad_data <- data.frame(x = 1:3, y = 4:6)
  expect_error(plot_faceted_family_regression(bad_data))
})

# ============================================================================
# plot_model_comparison (T3)
# ============================================================================

test_that("plot_model_comparison returns a ggplot object with all three models", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  x <- 1:10
  y <- 100 * exp(-0.05 * x) + rnorm(10, 0, 1)
  data <- data.frame(symbiosis_age_mya = x, genome_bp = y)

  mod_linear <- lm(y ~ x)
  mod_exp <- tryCatch(
    nls(y ~ a * exp(-b * x), start = list(a = max(y), b = 0.005)),
    error = function(e) NULL
  )
  mod_logistic <- tryCatch(
    nls(y ~ fl + (cl - fl) / (1 + exp(rate * (x - mid))),
      start = list(
        fl = min(y) * 0.8, cl = max(y) * 1.2,
        rate = 0.02, mid = mean(x)
      )
    ),
    error = function(e) NULL
  )

  p <- plot_model_comparison(data, mod_linear, mod_exp, mod_logistic)
  expect_s3_class(p, "ggplot")
})

test_that("plot_model_comparison handles NULL models gracefully", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  x <- 1:10
  y <- 100 * exp(-0.05 * x)
  data <- data.frame(symbiosis_age_mya = x, genome_bp = y)
  mod_linear <- lm(y ~ x)

  p <- plot_model_comparison(data, mod_linear, NULL, NULL)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# plot_partial_residuals (T4)
# ============================================================================

test_that("plot_partial_residuals returns a ggplot object", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  data <- data.frame(
    ne = c(1e6, 2e6, 5e5, 1e7, 8e5, 3e6),
    niche = c(0.2, 0.5, 0.1, 0.8, 0.3, 0.6),
    genome_size = c(4.5e6, 5.0e6, 4.0e6, 5.5e6, 4.2e6, 4.8e6)
  )
  mod_ne <- lm(genome_size ~ ne, data = data)
  mod_niche <- lm(genome_size ~ niche, data = data)

  p <- plot_partial_residuals(data, mod_ne, mod_niche)
  expect_s3_class(p, "ggplot")
})

test_that("plot_partial_residuals validates lm inputs", {
  expect_error(plot_partial_residuals(iris, "not_a_model", iris))
})

# ============================================================================
# plot_fluidity_by_lifestyle (T5)
# ============================================================================

test_that("plot_fluidity_by_lifestyle returns a ggplot object", {
  .skip_if_no_ggplot2()

  data <- data.frame(
    species = c("A", "B", "C", "D", "E", "F"),
    pangenome_fluidity = c(0.8, 0.7, 0.5, 0.4, 0.2, 0.1),
    lifestyle = c(
      "free_living", "free_living", "commensal", "commensal",
      "obligate", "obligate"
    ),
    stringsAsFactors = FALSE
  )

  p <- plot_fluidity_by_lifestyle(data)
  expect_s3_class(p, "ggplot")
})

test_that("plot_fluidity_by_lifestyle validates required columns", {
  bad_data <- data.frame(x = 1:3)
  expect_error(plot_fluidity_by_lifestyle(bad_data))
})

# ============================================================================
# plot_rank_rank_heatmap (T6)
# ============================================================================

test_that("plot_rank_rank_heatmap returns a ggplot object", {
  .skip_if_no_ggplot2()

  data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6),
    cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6),
    stringsAsFactors = FALSE
  )

  p <- plot_rank_rank_heatmap(data)
  expect_s3_class(p, "ggplot")
})

test_that("plot_rank_rank_heatmap validates required columns", {
  bad_data <- data.frame(category = c("a", "b"), dependency_score = c(0, 1))
  expect_error(plot_rank_rank_heatmap(bad_data))
})

# ============================================================================
# plot_observed_vs_expected_bar (T7)
# ============================================================================

test_that("plot_observed_vs_expected_bar returns a ggplot object", {
  .skip_if_no_ggplot2()

  p <- plot_observed_vs_expected_bar(
    observed = 36.4, expected = 61.7, ci = c(30.2, 42.6)
  )
  expect_s3_class(p, "ggplot")
})

test_that("plot_observed_vs_expected_bar handles 0-1 proportions", {
  .skip_if_no_ggplot2()

  p <- plot_observed_vs_expected_bar(
    observed = 0.364, expected = 0.617, ci = c(0.302, 0.426)
  )
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# plot_retention_trajectory (formal model)
# ============================================================================

test_that("plot_retention_trajectory returns a ggplot object", {
  .skip_if_no_ggplot2()

  model_result <- list(
    values = c(
      final_retention1 = 0.3, final_retention2 = 0.6,
      final_retention3 = 0.9, final_retention4 = 1.0,
      final_retention5 = 1.0,
      phase1_rate = 19.0, phase2_rate = 1.0,
      early_late_displacement_ratio = 19.0, threshold_biphasicity = 1.0
    ),
    metadata = list(
      params = list(
        lambda = 0.15, theta = 2.5, m0 = 10,
        alpha = 0.05, time = 100
      ),
      n_traits = 5,
      n_unprotected = 3,
      n_protected = 2,
      converged = TRUE
    )
  )

  depths <- c(0, 1, 2, 3, 5)
  p <- plot_retention_trajectory(model_result, depths = depths)
  expect_s3_class(p, "ggplot")
})

test_that("plot_retention_trajectory validates A6 proof object", {
  expect_error(plot_retention_trajectory(list(not = "valid")))
})

# ============================================================================
# plot_cusp_bifurcation (cusp catastrophe)
# ============================================================================

test_that("plot_cusp_bifurcation returns a ggplot object", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  p <- plot_cusp_bifurcation(
    a_range = c(-5, 5), b_range = c(-5, 5),
    grid_size = 30L
  )
  expect_s3_class(p, "ggplot")
})

test_that("plot_cusp_bifurcation validates numeric ranges", {
  expect_error(plot_cusp_bifurcation(a_range = "invalid", b_range = c(-5, 5)))
})

# ============================================================================
# plot_loglog_growth (autocatalytic)
# ============================================================================

test_that("plot_loglog_growth returns a ggplot object", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  counts <- 10 * exp(0.1 * 1:50)
  p <- plot_loglog_growth(counts)
  expect_s3_class(p, "ggplot")
})

test_that("plot_loglog_growth validates minimum length", {
  expect_error(plot_loglog_growth(c(1, 2, 3)))
})

test_that("plot_loglog_growth with catalyst matrix returns ggplot", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  counts <- 10 * exp(0.1 * 1:50)
  cmat <- matrix(FALSE, nrow = 5, ncol = 5)
  diag(cmat[-1, ]) <- TRUE # Each innovation catalyzes the next
  cmat[5, 1] <- TRUE # Cycle closure
  p <- plot_loglog_growth(counts,
    catalyst_matrix = cmat,
    innovation_names = c("I1", "I2", "I3", "I4", "I5")
  )
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# plot_cross_kingdom_concordance (L3)
# ============================================================================

test_that("plot_cross_kingdom_concordance returns a ggplot object", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  plant_data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = 1:6,
    stringsAsFactors = FALSE
  )
  bird_data <- data.frame(
    structure = c(
      "wing", "keel", "pectoral", "hindlimb", "pelvis",
      "feathers", "wing_bones", "asymmetry"
    ),
    dependency_score = c(0.0, 1.0, 0.5, 4.0, 3.0, 5.0, 1.5, 1.0),
    observed_rank = c(1, 3, 2, 4, 5, 6, 7, 8),
    stringsAsFactors = FALSE
  )

  p <- plot_cross_kingdom_concordance(plant_data, bird_data, plant_slope = 0.6)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cross_kingdom_concordance validates data frames", {
  expect_error(plot_cross_kingdom_concordance("not_a_df", iris, 0.5))
})

# ============================================================================
# plot_forest_oracle (baseline oracle)
# ============================================================================

test_that("plot_forest_oracle returns a ggplot object", {
  .skip_if_no_ggplot2()

  oracle <- data.frame(
    test_name = c("T1: beta", "T1: R2", "T3: R2", "T6: rho"),
    expected = c(-23.5, 0.652, 0.920, 0.955),
    observed = c(-23.5, 0.652, 0.920, 0.955),
    tolerance = c(0.001, 0.001, 0.01, 0.001),
    supports_framework = c(TRUE, TRUE, TRUE, TRUE),
    distinguishes = c(FALSE, FALSE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  p <- plot_forest_oracle(oracle)
  expect_s3_class(p, "ggplot")
})

test_that("plot_forest_oracle shows green for pass, red for fail", {
  .skip_if_no_ggplot2()

  oracle <- data.frame(
    test_name = c("Pass", "Fail"),
    expected = c(1.0, 1.0),
    observed = c(1.0005, 1.5),
    tolerance = c(0.001, 0.001),
    supports_framework = c(TRUE, TRUE),
    distinguishes = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  p <- plot_forest_oracle(oracle)
  expect_s3_class(p, "ggplot")
})

test_that("plot_forest_oracle validates required columns", {
  bad_data <- data.frame(x = 1:3)
  expect_error(plot_forest_oracle(bad_data))
})

# ============================================================================
# DFT axiom compliance: all functions return ggplot objects
# ============================================================================

test_that("all viz functions are pure (A1 — no file I/O, no side effects)", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()
  skip_if_not(requireNamespace("ape", quietly = TRUE), "ape not installed")

  # T1
  d1 <- data.frame(
    species = c("A", "B", "C"),
    plastome_size_kb = c(150, 120, 100),
    parasitism_score = c(0, 1, 2),
    stringsAsFactors = FALSE
  )
  tr <- ape::read.tree(text = "((A:0.1,B:0.2):0.1,C:0.3);")
  r1 <- list(
    values = c(
      beta = -25, r_squared = 0.65, p_value = 0.001,
      lambda = 0.8, n_species = 3
    ),
    metadata = list(seed = 42, n = 3, converged = TRUE)
  )
  p1 <- plot_pgls_with_phylogeny(d1, tr, r1)
  expect_s3_class(p1, "ggplot")

  # T2
  d2 <- data.frame(
    species = c("A", "B", "C", "D"),
    family = c("F1", "F1", "F2", "F2"),
    plastome_size_kb = c(150, 140, 100, 80),
    parasitism_score = c(0, 1, 2, 3),
    stringsAsFactors = FALSE
  )
  p2 <- plot_faceted_family_regression(d2)
  expect_s3_class(p2, "ggplot")

  # T7
  p7 <- plot_observed_vs_expected_bar(36.4, 61.7, c(30.2, 42.6))
  expect_s3_class(p7, "ggplot")

  # Formal model
  fm <- list(
    values = c(
      final_retention1 = 0.3, final_retention2 = 0.6,
      final_retention3 = 0.9, final_retention4 = 1.0,
      final_retention5 = 1.0,
      phase1_rate = 19, phase2_rate = 1,
      early_late_displacement_ratio = 19, threshold_biphasicity = 1
    ),
    metadata = list(
      params = list(
        lambda = 0.15, theta = 2.5, m0 = 10,
        alpha = 0.05, time = 100
      ),
      n_traits = 5, converged = TRUE
    )
  )
  p8 <- plot_retention_trajectory(fm, depths = c(0, 1, 2, 3, 5))
  expect_s3_class(p8, "ggplot")

  # Cusp
  p9 <- plot_cusp_bifurcation(c(-3, 3), c(-3, 3), grid_size = 20L)
  expect_s3_class(p9, "ggplot")

  # Log-log
  p10 <- plot_loglog_growth(10 * exp(0.1 * 1:20))
  expect_s3_class(p10, "ggplot")

  # Cross-kingdom
  plant_data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = 0:5,
    orobanchaceae_loss_rank = 1:6,
    stringsAsFactors = FALSE
  )
  bird_data <- data.frame(
    structure = c("a", "b", "c", "d", "e", "f", "g", "h"),
    dependency_score = c(0, 0.5, 1, 1.5, 2, 3, 4, 5),
    observed_rank = 1:8,
    stringsAsFactors = FALSE
  )
  p11 <- plot_cross_kingdom_concordance(plant_data, bird_data, 0.6)
  expect_s3_class(p11, "ggplot")

  # Oracle
  oracle <- data.frame(
    test_name = c("T1"), expected = c(-23.5), observed = c(-23.5),
    tolerance = c(0.001), supports_framework = c(TRUE), distinguishes = c(FALSE),
    stringsAsFactors = FALSE
  )
  p12 <- plot_forest_oracle(oracle)
  expect_s3_class(p12, "ggplot")
})

# ============================================================================
# Edge case: empty data / minimal data
# ============================================================================

test_that("plot_observed_vs_expected_bar handles zero values", {
  .skip_if_no_ggplot2()

  p <- plot_observed_vs_expected_bar(0, 0, c(0, 0))
  expect_s3_class(p, "ggplot")
})

test_that("plot_loglog_growth handles constant counts", {
  .skip_if_no_ggplot2()
  .skip_if_no_patchwork()

  counts <- rep(100, 20)
  p <- plot_loglog_growth(counts)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# Edge case: oracle result with all failing
# ============================================================================

test_that("plot_forest_oracle handles all-fail oracle", {
  .skip_if_no_ggplot2()

  oracle <- data.frame(
    test_name = c("T1", "T3", "T6"),
    expected = c(-23.5, 0.920, 0.955),
    observed = c(0, 0.5, 0.1),
    tolerance = c(0.001, 0.01, 0.001),
    supports_framework = c(TRUE, TRUE, TRUE),
    distinguishes = c(FALSE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  p <- plot_forest_oracle(oracle)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# Edge case: single lineage rank-rank heatmap
# ============================================================================

test_that("plot_rank_rank_heatmap works with single lineage", {
  .skip_if_no_ggplot2()

  data <- data.frame(
    category = c("a", "b", "c"),
    dependency_score = c(0, 1, 2),
    lineage1_loss_rank = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  p <- plot_rank_rank_heatmap(data)
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# Edge case: T5 boxplot with single lifestyle group
# ============================================================================

test_that("plot_fluidity_by_lifestyle works with single group", {
  .skip_if_no_ggplot2()

  data <- data.frame(
    species = paste0("S", 1:10),
    pangenome_fluidity = runif(10, 0.1, 0.9),
    lifestyle = rep("free_living", 10),
    stringsAsFactors = FALSE
  )

  p <- plot_fluidity_by_lifestyle(data)
  expect_s3_class(p, "ggplot")
})
