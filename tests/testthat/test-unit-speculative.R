# test-unit-speculative.R — Unit tests for the speculative toy models
#
# Tests the speculative simulation capacity (toy models).
# DFT A1: pure math, no I/O. A2: deterministic (no RNG). A6: proof objects.
#
# This file matches the `unit` filter (run_tests.R unit).

library(testthat)

context("Speculative toy models")

# === sweep_threshold ===

test_that("sweep_threshold returns A6 proof object", {
  result <- sweep_threshold(
    depths = c(0, 1, 2, 3, 5),
    theta_grid = seq(0, 6, by = 0.5)
  )
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("peak_biphasicity" %in% names(result$values))
  expect_true("peak_theta" %in% names(result$values))
})

test_that("sweep_threshold produces one row per theta value", {
  theta_grid <- seq(0, 6, by = 0.5)
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = theta_grid)
  expect_equal(nrow(result$values$sweep), length(theta_grid))
  expect_equal(result$values$sweep$theta, theta_grid)
})

test_that("sweep_threshold handles all-protected edge case (theta=0)", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(0, 2.5, 6))
  # theta=0: all protected, no contrast → biphasicity = 0
  expect_equal(result$values$sweep$threshold_biphasicity[[1]], 0)
  expect_equal(result$values$sweep$n_protected[[1]], 5)
  expect_equal(result$values$sweep$n_unprotected[[1]], 0)
})

test_that("sweep_threshold handles all-unprotected edge case (theta > max)", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(0, 2.5, 6))
  # theta=6: all unprotected, no contrast → biphasicity = 0
  expect_equal(result$values$sweep$threshold_biphasicity[[3]], 0)
  expect_equal(result$values$sweep$n_protected[[3]], 0)
  expect_equal(result$values$sweep$n_unprotected[[3]], 5)
})

test_that("sweep_threshold shows gate opening: biphasicity rises 0 -> 1 -> 0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(depths = depths, theta_grid = seq(0, 6, by = 0.25))
  bp <- result$values$sweep$threshold_biphasicity

  # At theta=0 (all protected): biphasicity ~ 0
  expect_lt(bp[[1]], 0.01)

  # At peak (gate open): biphasicity ~ 1
  expect_gt(result$values$peak_biphasicity, 0.99)

  # At theta > max(depths) (all unprotected): biphasicity ~ 0
  expect_lt(bp[[length(bp)]], 0.01)

  # The peak theta is in the interior (not at the edges)
  expect_gt(result$values$peak_theta, min(depths))
  expect_lt(result$values$peak_theta, max(depths))
})

test_that("sweep_threshold n_protected decreases as theta increases", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(depths = depths, theta_grid = seq(0, 6, by = 1))
  n_prot <- result$values$sweep$n_protected
  # n_protected should be monotonically non-increasing
  expect_true(all(diff(n_prot) <= 0))
})

test_that("sweep_threshold is deterministic (A2 — no RNG)", {
  r1 <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  r2 <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  expect_equal(r1$values$sweep, r2$values$sweep)
})

test_that("sweep_threshold metadata records params and depths", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(
    depths = depths, theta_grid = seq(0, 6, 0.5),
    lambda = 0.2, m0 = 15
  )
  expect_equal(result$metadata$depths, depths)
  expect_equal(result$metadata$n_traits, 5)
  expect_equal(result$metadata$params$lambda, 0.2)
  expect_equal(result$metadata$params$m0, 15)
  expect_equal(result$metadata$method, "threshold_sweep")
})

test_that("sweep_threshold works with skewed dependency architecture", {
  # Skewed: many shallow traits, few deep
  depths_skewed <- c(0, 0, 0, 1, 5, 5)
  result <- sweep_threshold(depths = depths_skewed, theta_grid = seq(0, 6, 0.5))
  expect_true(validate_result(result))
  # Gate should still open and close
  expect_gt(result$values$peak_biphasicity, 0.99)
  expect_lt(result$values$sweep$threshold_biphasicity[[1]], 0.01)
  expect_lt(result$values$sweep$threshold_biphasicity[[nrow(result$values$sweep)]], 0.01)
})

# === plot_threshold_gate ===

test_that("plot_threshold_gate returns ggplot object", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  p <- plot_threshold_gate(result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_threshold_gate maps theta to x and biphasicity to y", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  p <- plot_threshold_gate(result)
  # Check the axis labels (the plot uses .data$ pronoun, so check labels
  # rather than the mapping expression)
  expect_true(grepl("threshold", p$labels$x, ignore.case = TRUE))
  expect_true(grepl("biphasicity", p$labels$y, ignore.case = TRUE))
})

test_that("plot_threshold_gate handles single-point sweep gracefully", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(2.5))
  expect_error(plot_threshold_gate(result), NA)
})

# === hysteresis_loop_area ===

.cusp_cv <- seq(-2, 2, length.out = 100)

.cusp_a_neg1 <- make_cusp_equilibrium_fn(a = -1)
.cusp_a_pos1 <- make_cusp_equilibrium_fn(a = 1)

test_that("hysteresis_loop_area returns A6 proof object", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_true(validate_result(result))
  expect_true("loop_area" %in% names(result$values))
  expect_true("max_difference" %in% names(result$values))
  expect_true("has_hysteresis" %in% names(result$values))
})

test_that("hysteresis_loop_area is 0 for a=1 (no bifurcation)", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_pos1)
  expect_equal(result$values$loop_area, 0, tolerance = 1e-10)
  expect_false(result$values$has_hysteresis)
})

test_that("hysteresis_loop_area is > 0 for a=-1 (cusp region)", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_gt(result$values$loop_area, 0.5)
  expect_true(result$values$has_hysteresis)
})

test_that("hysteresis_loop_area is deterministic (A2)", {
  r1 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  r2 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_equal(r1$values, r2$values)
})

test_that("hysteresis_loop_area is robust to initial_state", {
  # The loop area is the same regardless of which branch you start on
  r0 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = 0)
  r1 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = 1.0)
  r2 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = -1.0)
  expect_equal(r0$values$loop_area, r1$values$loop_area, tolerance = 1e-6)
  expect_equal(r0$values$loop_area, r2$values$loop_area, tolerance = 1e-6)
})

# === sweep_cusp_irreversibility ===

test_that("sweep_cusp_irreversibility returns A6 proof object", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("peak_loop_area" %in% names(result$values))
  expect_true("bifurcation_a" %in% names(result$values))
})

test_that("sweep_cusp_irreversibility produces one row per a value", {
  a_grid <- seq(1, -2, by = -0.5)
  result <- sweep_cusp_irreversibility(a_grid = a_grid, control_values = .cusp_cv)
  expect_equal(nrow(result$values$sweep), length(a_grid))
  expect_equal(result$values$sweep$a, a_grid)
})

test_that("sweep shows loop area = 0 for a >= 0 (no bifurcation)", {
  result <- sweep_cusp_irreversibility(
    a_grid = c(1, 0.5, 0),
    control_values = .cusp_cv
  )
  expect_true(all(result$values$sweep$loop_area < 1e-10))
  expect_false(any(result$values$sweep$has_hysteresis))
})

test_that("sweep shows loop area rising for a < 0 (cusp region)", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.25),
    control_values = .cusp_cv
  )
  df <- result$values$sweep
  # The peak loop area should be at the most negative a
  expect_lt(result$values$peak_a, -1.5)
  # Some a < 0 values should have loop area > 0
  cusp_rows <- df[df$a < -0.5, ]
  expect_true(any(cusp_rows$loop_area > 0.1))
})

test_that("loop area is monotonic in |a| for a < 0", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(-0.1, -2, by = -0.1),
    control_values = .cusp_cv
  )
  df <- result$values$sweep
  # As a becomes more negative (|a| increases), loop area should be
  # monotonically non-decreasing
  expect_true(all(diff(df$loop_area) >= -1e-10))
})

test_that("sweep_cusp_irreversibility is deterministic (A2)", {
  r1 <- sweep_cusp_irreversibility(
    a_grid = seq(1, -1, by = -0.5),
    control_values = .cusp_cv
  )
  r2 <- sweep_cusp_irreversibility(
    a_grid = seq(1, -1, by = -0.5),
    control_values = .cusp_cv
  )
  expect_equal(r1$values$sweep, r2$values$sweep)
})

# === plot_irreversibility_sweep ===

test_that("plot_irreversibility_sweep returns ggplot object", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  p <- plot_irreversibility_sweep(result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_irreversibility_sweep maps a to x and loop_area to y", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  p <- plot_irreversibility_sweep(result)
  expect_true(grepl("a", p$labels$x, ignore.case = TRUE))
  expect_true(grepl("area", p$labels$y, ignore.case = TRUE))
})

# === diversity_dependence_contrast ===

test_that("diversity_dependence_contrast returns A6 proof object", {
  result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  expect_true(validate_result(result))
  expect_true("autocatalytic_dd_slope" %in% names(result$values))
  expect_true("logistic_dd_slope" %in% names(result$values))
  expect_true("contrast" %in% names(result$values))
})

test_that("diversity_dependence_contrast: autocatalytic DD is positive (Homo inversion)", {
  result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  expect_gt(result$values$autocatalytic_dd_slope, 0)
  expect_equal(result$values$autocatalytic_dd_sign, "positive")
})

test_that("diversity_dependence_contrast: logistic DD is negative (niche-filling)", {
  result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  expect_lt(result$values$logistic_dd_slope, 0)
  expect_equal(result$values$logistic_dd_sign, "negative")
})

test_that("diversity_dependence_contrast: contrast is positive (framework signature)", {
  result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  expect_gt(result$values$contrast, 0)
  expect_equal(result$values$contrast_sign, "positive")
})

test_that("diversity_dependence_contrast is deterministic (A2)", {
  r1 <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  r2 <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  expect_equal(r1$values$contrast, r2$values$contrast)
  expect_equal(r1$values$autocatalytic_counts, r2$values$autocatalytic_counts)
})

test_that("generate_dd_series at feedback=1 matches existing autocatalytic generator", {
  # Source the existing generator
  source(system.file("simulacra", "generate_autocatalytic.R", package = "valence.foundry"))
  existing <- generate_autocatalytic_set(
    n_steps = 20, innovation_rate = 0.3,
    capacity = 30, seed = 42L
  )
  new <- valence.foundry:::generate_dd_series(20, 0.3, 30, feedback = 1, seed = 42L)
  expect_equal(existing$values$innovation_counts, new)
})

test_that("generate_dd_series at feedback=0 gives negative DD", {
  counts <- valence.foundry:::generate_dd_series(20, 0.3, 30, feedback = 0, seed = 42L)
  dd <- diversity_dependence_sign(counts, seed = 42L)
  expect_equal(dd$values$diversity_dependence_sign, "negative")
})

# === sweep_endogenous_k ===

test_that("sweep_endogenous_k returns A6 proof object", {
  result <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.1))
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("bifurcation_feedback" %in% names(result$values))
})

test_that("sweep_endogenous_k produces one row per feedback value", {
  fb_grid <- seq(0, 1, by = 0.1)
  result <- sweep_endogenous_k(feedback_grid = fb_grid)
  expect_equal(nrow(result$values$sweep), length(fb_grid))
  expect_equal(result$values$sweep$feedback, fb_grid)
})

test_that("sweep shows DD sign flipping from negative to positive", {
  result <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.05))
  df <- result$values$sweep
  # At low feedback: negative DD (niche-filling)
  expect_equal(df$dd_sign[[1]], "negative")
  # At high feedback: positive DD (Homo inversion)
  expect_equal(df$dd_sign[[nrow(df)]], "positive")
  # There should be a sign flip somewhere in the interior
  signs <- df$dd_sign
  flips <- sum(diff(as.integer(factor(signs, levels = c("negative", "positive")))) != 0)
  expect_gte(flips, 1)
})

test_that("sweep measured bifurcation is close to theoretical (2/3)", {
  result <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.05))
  expect_equal(result$values$bifurcation_feedback, 2 / 3)
  # Measured bifurcation should be close to 2/3 (within 0.1)
  expect_lt(abs(result$values$measured_bifurcation_feedback - 2 / 3), 0.1)
})

test_that("sweep_endogenous_k is deterministic (A2)", {
  r1 <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.1))
  r2 <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.1))
  expect_equal(r1$values$sweep, r2$values$sweep)
})

# === plot_dd_contrast ===

test_that("plot_dd_contrast returns a plot object", {
  result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
  p <- plot_dd_contrast(result)
  # patchwork returns a patchwork object; ggplot returns "ggplot"
  expect_true(any(c("ggplot", "patchwork") %in% class(p)))
})

# === glm_transfer ===

test_that("glm_transfer returns A6 proof object", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.05, seed = 42L)
  result <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  expect_true(validate_result(result))
  for (k in c(
    "model_rho", "sign_only_rho", "model_advantage",
    "dep_coefficient", "para_coefficient"
  )) {
    expect_true(k %in% names(result$values))
  }
})

test_that("glm_transfer: model outperforms sign-only at low noise", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.05, seed = 42L)
  result <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  expect_gt(result$values$model_rho, result$values$sign_only_rho)
  expect_gt(result$values$model_advantage, 0)
})

test_that("glm_transfer: dep coefficient is positive (framework signature)", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.05, seed = 42L)
  result <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  expect_gt(result$values$dep_coefficient, 0)
})

test_that("glm_transfer: para coefficient is negative (framework signature)", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.05, seed = 42L)
  result <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  expect_lt(result$values$para_coefficient, 0)
})

test_that("glm_transfer is deterministic (A2)", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.1, seed = 42L)
  r1 <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  r2 <- glm_transfer(d$plant_data, d$bird_data, seed = 42L)
  expect_equal(r1$values, r2$values)
})

test_that("glm_transfer validates plant data", {
  bird <- data.frame(
    structure = "b", dependency_score = 1,
    parasitism_score = 1, observed_rank = 1
  )
  expect_error(glm_transfer(data.frame(), bird), "missing required columns")
})

test_that("generate_transfer_data produces valid retention matrix", {
  d <- valence.foundry:::generate_transfer_data(noise_sd = 0.05, seed = 42L)
  expect_true(validate_retention_data(d$plant_data))
  expect_equal(nrow(d$plant_data), 8 * 6) # 8 species x 6 gene categories
  expect_equal(nrow(d$bird_data), 10)
})

test_that("generate_transfer_data: bird data is independent of plant noise", {
  d0 <- valence.foundry:::generate_transfer_data(noise_sd = 0, seed = 42L)
  d1 <- valence.foundry:::generate_transfer_data(noise_sd = 0.5, seed = 42L)
  expect_identical(d0$bird_data, d1$bird_data)
})

test_that("generate_transfer_data is deterministic (A2)", {
  d1 <- valence.foundry:::generate_transfer_data(noise_sd = 0.1, seed = 42L)
  d2 <- valence.foundry:::generate_transfer_data(noise_sd = 0.1, seed = 42L)
  expect_identical(d1$plant_data, d2$plant_data)
  expect_identical(d1$bird_data, d2$bird_data)
})

# === sweep_transfer_robustness ===

test_that("sweep_transfer_robustness returns A6 proof object", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.1))
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("low_noise_advantage" %in% names(result$values))
})

test_that("sweep produces one row per noise value", {
  grid <- seq(0, 0.3, by = 0.05)
  result <- sweep_transfer_robustness(noise_grid = grid)
  expect_equal(nrow(result$values$sweep), length(grid))
})

test_that("sweep: low-noise advantage is positive (model > sign)", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.05))
  expect_gt(result$values$low_noise_advantage, 0)
})

test_that("sweep: sign-only rho is flat across noise (Issue 7)", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.05))
  # sign_only_rho depends only on the dep sign, which doesn't flip
  sign_rhos <- result$values$sweep$sign_only_rho
  expect_equal(max(sign_rhos) - min(sign_rhos), 0)
})

test_that("sweep: model_advantage decreases as noise increases", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.05))
  advantages <- result$values$sweep$model_advantage
  # The advantage should be monotonically non-increasing
  expect_true(all(diff(advantages) <= 1e-10))
})

test_that("sweep: model and sign converge at high noise", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.05))
  # At the highest noise in the default grid, advantage should be near 0
  last_adv <- tail(result$values$sweep$model_advantage, 1)
  expect_lt(abs(last_adv), 0.05)
})

test_that("sweep is deterministic (A2)", {
  r1 <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.1))
  r2 <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.1))
  expect_equal(r1$values$sweep, r2$values$sweep)
})

# === plot_transfer_breakdown ===

test_that("plot_transfer_breakdown returns a ggplot object", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.1))
  p <- plot_transfer_breakdown(result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_transfer_breakdown maps noise to x and rho to y", {
  result <- sweep_transfer_robustness(noise_grid = seq(0, 0.3, by = 0.1))
  p <- plot_transfer_breakdown(result)
  expect_true(grepl("noise", p$labels$x, ignore.case = TRUE))
  expect_true(grepl("rho", p$labels$y, ignore.case = TRUE))
})
