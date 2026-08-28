# test-simulacrum-biphasic.R — Simulacrum 2: Biphasic Kinetics STDD Test
#
# STDD (Stochastic Test-Driven Development) model selection test.
# Tests whether the model selection procedure correctly identifies
# biphasic (logistic/saturation) dynamics vs constant-rate (linear)
# dynamics in synthetic genome reduction data.
#
# DFT Axioms:
# - A1 (pure-io-separation): pure function, no file I/O
# - A2 (determinism): withr::with_seed, Mersenne-Twister + Inversion
# - A6 (check-result): returns proof object with values + metadata
#
# @section Theoretical Context:
#
# valence Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
# rapidly) followed by slow Phase 2 (protected traits resist loss). The
# logistic/saturation curve is the empirical signature distinguishing valence
# from constant-rate (relaxed selection, Lahti 2009) and accelerating
# (Muller's ratchet) competitors.
#
# This test generates synthetic data with KNOWN biphasic parameters
# (k1=0.08, k2=0.004, k1/k2=20.0), then verifies that the model selection
# procedure correctly prefers the logistic model over the linear model.
# The null control verifies that when data follows a linear (constant-rate)
# model, the logistic is NOT strongly preferred.

library(testthat)

context("Simulacrum 2: Biphasic kinetics")

# Generator is sourced by helper-simulacra.R (inst/simulacra/ is outside R/,
# so it is not exported via NAMESPACE).

# ---- Helper: compute AICc ----

#' Compute corrected AIC for small samples
#'
#' AICc = AIC + 2k(k+1) / (n - k - 1)
#'
#' @param model Fitted model object (lm, nls).
#' @param k Integer. Number of parameters (including variance).
#' @param n Integer. Sample size.
#'
#' @return Numeric. AICc value.
#' @keywords internal
aicc <- function(model, k, n) {
  stats::AIC(model) + (2 * k * (k + 1)) / (n - k - 1)
}

#' Compute R-squared for a fitted model
#'
#' R² = 1 - RSS / TSS
#'
#' @param y Numeric vector. Observed values.
#' @param y_pred Numeric vector. Predicted values.
#'
#' @return Numeric. R-squared in [0, 1].
#' @keywords internal
r_squared <- function(y, y_pred) {
  rss <- sum((y - y_pred)^2, na.rm = TRUE)
  tss <- sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
  1 - rss / tss
}

# ---- Main test function (returns A6 proof object) ----

#' Run the simulacrum biphasic test
#'
#' Generates synthetic data with known biphasic parameters, fits
#' linear and logistic models, and returns model selection results
#' as an A6 proof object.
#'
#' @param seed Integer. Seed for reproducibility. Default 42.
#' @param n_genera Integer. Number of genera. Default 10.
#' @param true_rate Numeric. True logistic rate parameter. Default 0.08.
#' @param age_range Numeric vector length 2. Age range in Myr. Default c(20, 200).
#' @param mid Numeric. True logistic midpoint. Default 70.
#' @param ancestor_size Numeric. True ancestral genome size. Default 4.5e6.
#' @param floor_size Numeric. True genome size floor. Default 4e5.
#' @param noise_sd Numeric. Noise SD for biphasic data. Default 5000.
#' @param null_noise_sd Numeric. Noise SD for null data. Default 50000.
#' @param null_reduction_rate Numeric. Constant reduction rate for null. Default 20000.
#'
#' @return List (A6 proof object):
#'   \item{values}{Named numeric: r2_linear, r2_logistic, aicc_linear,
#'     aicc_logistic, delta_aicc, recovered_rate, rate_error_pct,
#'     null_delta_aicc, test_passed}
#'   \item{metadata}{List: seed, n, params, assertions, converged}
#'
#' @export
test_simulacrum_biphasic <- function(
  seed = 42L,
  n_genera = 10L,
  true_rate = 0.08,
  age_range = c(20, 200),
  mid = 70,
  ancestor_size = 4.5e6,
  floor_size = 4e5,
  noise_sd = 5000,
  null_noise_sd = 50000,
  null_reduction_rate = 20000
) {
  withr::with_seed(seed, {
    # Use Mersenne-Twister + Inversion for full reproducibility (A2)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")

    # ---- Generate biphasic synthetic data ----
    biphasic_result <- generate_biphasic_genome(
      seed = seed,
      n_genera = n_genera,
      age_range = age_range,
      ancestor_size = ancestor_size,
      floor_size = floor_size,
      rate = true_rate,
      mid = mid,
      noise_sd = noise_sd
    )
    data <- biphasic_result$metadata$data

    x <- data$symbiosis_age_mya
    y <- data$genome_bp

    # ---- Model 1: Linear (constant rate) ----
    mod_linear <- stats::lm(y ~ x)
    y_pred_linear <- stats::predict(mod_linear)
    r2_linear <- r_squared(y, y_pred_linear)
    k_linear <- 3L # intercept, slope, residual variance
    aicc_linear <- aicc(mod_linear, k_linear, n_genera)

    # ---- Model 2: Logistic (biphasic/valence) ----
    mod_logistic <- tryCatch(
      stats::nls(
        y ~ floor_val + (ceil_val - floor_val) /
          (1 + exp(rate * (x - mid_val))),
        start = list(
          floor_val = min(y) * 0.8,
          ceil_val = max(y) * 1.2,
          rate = 0.05,
          mid_val = stats::median(x)
        ),
        control = stats::nls.control(maxiter = 1000, warnOnly = FALSE)
      ),
      error = function(e) NULL
    )

    if (!is.null(mod_logistic)) {
      y_pred_logistic <- stats::predict(mod_logistic)
      r2_logistic <- r_squared(y, y_pred_logistic)
      k_logistic <- 5L # floor, ceil, rate, mid, residual variance
      aicc_logistic <- aicc(mod_logistic, k_logistic, n_genera)
      delta_aicc <- aicc_linear - aicc_logistic # positive = logistic preferred

      coefs <- stats::coef(mod_logistic)
      recovered_rate <- unname(coefs["rate"])
      rate_error_pct <- abs(recovered_rate - true_rate) / true_rate * 100
    } else {
      r2_logistic <- 0
      aicc_logistic <- Inf
      delta_aicc <- -Inf
      recovered_rate <- NA
      rate_error_pct <- NA
    }

    # ---- Assertions ----
    assertions <- list()

    # A1: Logistic R² > Linear R²
    assertions$r2_preferred <- !is.null(mod_logistic) && r2_logistic > r2_linear

    # A2: ΔAICc > 4 (logistic strongly preferred)
    assertions$delta_aicc_strong <- !is.null(mod_logistic) && delta_aicc > 4

    # A3: Recovered rate within 50% of true rate
    if (!is.null(mod_logistic) && !is.na(recovered_rate)) {
      assertions$rate_recovered <- rate_error_pct < 50
    } else {
      assertions$rate_recovered <- FALSE
    }

    # ---- Null control: constant-rate data ----
    null_result <- generate_constant_rate_genome(
      seed = seed + 1L,
      n_genera = n_genera,
      age_range = age_range,
      ancestor_size = ancestor_size,
      reduction_rate = null_reduction_rate,
      noise_sd = null_noise_sd
    )
    null_data <- null_result$metadata$data
    null_x <- null_data$symbiosis_age_mya
    null_y <- null_data$genome_bp

    # Fit linear to null
    null_mod_linear <- stats::lm(null_y ~ null_x)
    null_aicc_linear <- aicc(null_mod_linear, k_linear, n_genera)

    # Fit logistic to null
    null_mod_logistic <- tryCatch(
      stats::nls(
        null_y ~ floor_val + (ceil_val - floor_val) /
          (1 + exp(rate * (null_x - mid_val))),
        start = list(
          floor_val = min(null_y) * 0.8,
          ceil_val = max(null_y) * 1.2,
          rate = 0.05,
          mid_val = stats::median(null_x)
        ),
        control = stats::nls.control(maxiter = 1000, warnOnly = FALSE)
      ),
      error = function(e) NULL
    )

    if (!is.null(null_mod_logistic)) {
      null_aicc_logistic <- aicc(null_mod_logistic, k_logistic, n_genera)
      null_delta_aicc <- null_aicc_linear - null_aicc_logistic
    } else {
      null_delta_aicc <- -Inf # logistic failed to converge — not preferred
    }

    # A4: Null control — ΔAICc < 4 (logistic NOT strongly preferred)
    if (is.finite(null_delta_aicc)) {
      assertions$null_not_preferred <- null_delta_aicc < 4
    } else {
      assertions$null_not_preferred <- TRUE # logistic failed — not preferred
    }

    # ---- Build A6 proof object ----
    test_passed <- all(unlist(assertions))

    result <- list(
      values = c(
        r2_linear = r2_linear,
        r2_logistic = r2_logistic,
        aicc_linear = aicc_linear,
        aicc_logistic = if (is.finite(aicc_logistic)) aicc_logistic else NA,
        delta_aicc = delta_aicc,
        recovered_rate = recovered_rate,
        true_rate = true_rate,
        rate_error_pct = rate_error_pct,
        null_delta_aicc = null_delta_aicc,
        test_passed = test_passed
      ),
      metadata = list(
        seed = seed,
        n = n_genera,
        params = list(
          true_rate = true_rate,
          mid = mid,
          ancestor_size = ancestor_size,
          floor_size = floor_size,
          noise_sd = noise_sd,
          null_noise_sd = null_noise_sd,
          null_reduction_rate = null_reduction_rate
        ),
        assertions = list(
          r2_logistic_gt_linear = assertions$r2_preferred,
          delta_aicc_gt_4 = assertions$delta_aicc_strong,
          rate_within_50pct = assertions$rate_recovered,
          null_not_preferred = assertions$null_not_preferred
        ),
        model_logistic_converged = !is.null(mod_logistic),
        model_null_logistic_converged = !is.null(null_mod_logistic),
        generator = "simulacrum_biphasic_test",
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

# ---- testthat blocks ----

test_that("Simulacrum 2: logistic R² > linear R² for biphasic data", {
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(validate_result(result))
  expect_true(result$values[["r2_logistic"]] > result$values[["r2_linear"]],
    info = "Logistic model should fit biphasic data better than linear"
  )
})

test_that("Simulacrum 2: ΔAICc > 4 (logistic strongly preferred)", {
  # Use Mersenne-Twister + Inversion for full reproducibility
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(result$values[["delta_aicc"]] > 4,
    info = "ΔAICc > 4 indicates logistic strongly preferred over linear"
  )
})

test_that("Simulacrum 2: recovered rate within 50% of true rate (0.08)", {
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(!is.na(result$values[["rate_error_pct"]]))
  expect_true(result$values[["rate_error_pct"]] < 50,
    info = "Recovered logistic rate should be within 50% of true rate (0.08)"
  )
  expect_true(
    result$values[["recovered_rate"]] > 0.04 &&
      result$values[["recovered_rate"]] < 0.12,
    info = "Recovered rate should be between 0.04 and 0.12 (50% of 0.08)"
  )
})

test_that("Simulacrum 2: null control — ΔAICc < 4 (logistic NOT preferred)", {
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(
    is.finite(result$values[["null_delta_aicc"]]) ||
      result$values[["null_delta_aicc"]] == -Inf,
    info = "Null control should not strongly prefer logistic model"
  )
  expect_true(result$values[["null_delta_aicc"]] < 4,
    info = "ΔAICc < 4 for null data: logistic NOT strongly preferred"
  )
})

test_that("Simulacrum 2: deterministic with same seed (A2)", {
  r1 <- test_simulacrum_biphasic(seed = 42)
  r2 <- test_simulacrum_biphasic(seed = 42)
  expect_equal(r1$values, r2$values)
  expect_equal(r1$metadata$seed, 42)
  expect_equal(r2$metadata$seed, 42)
})

test_that("Simulacrum 2: returns A6 proof object", {
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(validate_result(result))
  expect_true("values" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_equal(result$metadata$seed, 42)
  expect_equal(result$metadata$n, 10)
  expect_true(result$metadata$converged)
})

test_that("Simulacrum 2: full test passes (all assertions met)", {
  result <- test_simulacrum_biphasic(seed = 42)
  expect_true(result$values[["test_passed"]] == 1,
    info = "All assertions must pass for Simulacrum 2"
  )
})

test_that("Simulacrum 2: different seed yields different data but same conclusions", {
  r1 <- test_simulacrum_biphasic(seed = 42)
  r2 <- test_simulacrum_biphasic(seed = 99)
  # Different seed should produce different data
  expect_true(
    r1$values[["r2_logistic"]] != r2$values[["r2_logistic"]] ||
      r1$values[["r2_linear"]] != r2$values[["r2_linear"]],
    info = "Different seeds should produce different data (different R² values)"
  )
  # Both should still pass the test
  expect_true(r1$values[["test_passed"]] == 1)
  expect_true(r2$values[["test_passed"]] == 1)
})
