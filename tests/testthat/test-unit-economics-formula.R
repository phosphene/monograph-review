# Tests for Phase 6b: Formula-Grounded Economics Predictions
# Tests the quantitative formula predictions:
#   rho(theta) = rho_sat * H(theta - theta*), with theta* = 0, rho_sat ~ 0.35, s -> Inf

library(testthat)

# Helper: generate synthetic step-formula data
make_step_data <- function(n_pre = 5, n_post = 5, rho_sat = 0.35,
                           noise = 0.01, seed = 42) {
  set.seed(seed)
  theta <- c(
    seq(-0.5, -0.05, length.out = n_pre),
    seq(0, 1, length.out = n_post)
  )
  rho <- c(
    rep(0, n_pre) + rnorm(n_pre, 0, noise),
    rep(rho_sat, n_post) + rnorm(n_post, 0, noise)
  )
  data.frame(system = "test", theta = theta, rho = pmax(0, rho))
}

make_cdi_step_data <- function(peak = 100, post_cap = 20, noise = 0,
                               n_pre = 8, n_post = 12,
                               trigger = 1998, seed = 42) {
  set.seed(seed)
  years_pre <- seq(trigger - n_pre, trigger - 1)
  years_post <- seq(trigger, trigger + n_post - 1)
  cap_pre <- rep(peak, n_pre) + if (noise > 0) rnorm(n_pre, 0, peak * 0.01) else 0
  cap_post <- rep(post_cap, n_post) + if (noise > 0) rnorm(n_post, 0, post_cap * 0.05) else 0
  data.frame(
    system = "test",
    year = c(years_pre, years_post),
    capacity = pmax(0, c(cap_pre, cap_post)),
    trigger_year = trigger
  )
}

# rho_sat_prediction

test_that("rho_sat_prediction returns correct proof object structure", {
  dat <- make_step_data(n_pre = 5, n_post = 5, rho_sat = 0.35)
  result <- rho_sat_prediction(dat, seed = 42)
  expect_true(is.list(result))
  expect_true(all(c("values", "metadata") %in% names(result)))
  expect_true(all(c(
    "n_systems", "mean_rho_sat", "formula_prediction",
    "within_band", "step_wins_share", "mean_delta_aic"
  ) %in%
    names(result$values)))
  expect_equal(result$values$formula_prediction, 0.35, tolerance = 1e-6)
  expect_equal(result$values$n_systems, 1)
  expect_true(is.logical(result$values$within_band))
  expect_true(result$metadata$converged)
})

test_that("rho_sat_prediction detects rho_sat ~ 0.35 in clean step data", {
  dat <- make_step_data(n_pre = 10, n_post = 10, rho_sat = 0.35, noise = 0)
  result <- rho_sat_prediction(dat, seed = 42)
  expect_true(result$values$within_band)
  expect_gt(result$values$step_wins_share, 0.5)
  expect_gt(result$values$mean_delta_aic, 0)
})

test_that("rho_sat_prediction detects deviation from 0.35", {
  dat <- make_step_data(n_pre = 5, n_post = 5, rho_sat = 0.80, noise = 0)
  result <- rho_sat_prediction(dat, seed = 42)
  expect_false(result$values$within_band)
})

test_that("rho_sat_prediction handles multiple systems", {
  dat1 <- make_step_data(n_pre = 5, n_post = 5, rho_sat = 0.35, seed = 1)
  dat2 <- make_step_data(n_pre = 5, n_post = 5, rho_sat = 0.33, seed = 2)
  dat1$system <- "newspapers"
  dat2$system <- "taxi"
  dat <- rbind(dat1, dat2)
  result <- rho_sat_prediction(dat, seed = 42)
  expect_equal(result$values$n_systems, 2)
  expect_true(result$values$within_band)
})

test_that("rho_sat_prediction rejects bad data", {
  expect_error(rho_sat_prediction("not a data frame"))
  expect_error(rho_sat_prediction(data.frame(system = "x", theta = 1)))
  expect_error(rho_sat_prediction(data.frame(system = "x", theta = 1, rho = 1.5)))
})

# step_cdi_comparison

test_that("step_cdi_comparison returns correct proof object structure", {
  dat <- make_cdi_step_data()
  result <- step_cdi_comparison(dat, seed = 42)
  expect_true(all(c("values", "metadata") %in% names(result)))
  expect_true(all(c(
    "n_systems", "step_wins_share", "mean_delta_aic_step_log",
    "mean_delta_aic_step_exp", "mean_step_width"
  ) %in%
    names(result$values)))
  expect_equal(result$values$mean_step_width, 0)
  expect_equal(result$values$n_systems, 1)
})

test_that("step_cdi_comparison detects step in clean step data", {
  dat <- make_cdi_step_data(peak = 100, post_cap = 20, n_pre = 10, n_post = 15)
  result <- step_cdi_comparison(dat, seed = 42)
  expect_gt(result$values$step_wins_share, 0.5)
  expect_gt(result$values$mean_delta_aic_step_log, 0)
  expect_gt(result$values$mean_delta_aic_step_exp, 0)
})

test_that("step_cdi_comparison handles gradual (logistic) data", {
  set.seed(42)
  t <- 0:19
  cdi <- 1 / (1 + exp(-0.5 * (t - 8)))
  cap <- 100 * (1 - cdi)
  dat <- data.frame(
    system = "gradual",
    year = 1990:2009,
    capacity = cap,
    trigger_year = 1998
  )
  result <- step_cdi_comparison(dat, seed = 42)
  expect_lte(result$values$step_wins_share, 0.5)
})

test_that("step_cdi_comparison handles multiple systems", {
  dat1 <- make_cdi_step_data(trigger = 1998, seed = 1)
  dat2 <- make_cdi_step_data(trigger = 2004, seed = 2)
  dat1$system <- "newspapers"
  dat2$system <- "taxi"
  dat <- rbind(dat1, dat2)
  result <- step_cdi_comparison(dat, seed = 42)
  expect_equal(result$values$n_systems, 2)
})

test_that("step_cdi_comparison rejects bad data", {
  expect_error(step_cdi_comparison("not a data frame"))
  expect_error(step_cdi_comparison(data.frame(
    system = "x", year = 1, capacity = 1
  )))
})

# step_option_collapse

test_that("step_option_collapse returns correct proof object structure", {
  dat <- make_cdi_step_data()
  result <- step_option_collapse(dat, seed = 42)
  expect_true(all(c("values", "metadata") %in% names(result)))
  expect_true(all(c(
    "n_systems", "step_wins_share", "mean_delta_aic",
    "mean_step_collapse_time"
  ) %in% names(result$values)))
  expect_equal(result$values$n_systems, 1)
})

test_that("step_option_collapse detects step collapse in clean data", {
  dat <- make_cdi_step_data(peak = 100, post_cap = 5, n_pre = 8, n_post = 15)
  result <- step_option_collapse(dat, seed = 42)
  expect_gt(result$values$step_wins_share, 0.5)
  expect_gt(result$values$mean_delta_aic, 0)
})

test_that("step_option_collapse handles gradual decay data", {
  set.seed(42)
  t <- 0:19
  cap <- 100 * exp(-0.15 * t)
  dat <- data.frame(
    system = "gradual",
    year = 2000:2019,
    capacity = cap,
    trigger_year = 2004
  )
  result <- step_option_collapse(dat, seed = 42)
  expect_lte(result$values$step_wins_share, 0.5)
})

test_that("step_option_collapse handles multiple systems", {
  dat1 <- make_cdi_step_data(trigger = 2004, seed = 1)
  dat2 <- make_cdi_step_data(trigger = 1998, seed = 2)
  dat1$system <- "taxi"
  dat2$system <- "newspapers"
  dat <- rbind(dat1, dat2)
  result <- step_option_collapse(dat, seed = 42)
  expect_equal(result$values$n_systems, 2)
})

# generative_sign_reversal

test_that("generative_sign_reversal returns correct proof object structure", {
  dat <- data.frame(
    system = "software",
    diversity = 1:20,
    speciation_rate = 1:20 * 0.1 + 1
  )
  result <- generative_sign_reversal(dat, seed = 42)
  expect_true(all(c("values", "metadata") %in% names(result)))
  expect_true(all(c(
    "n_systems", "mean_slope", "positive_slope_share",
    "formula_prediction"
  ) %in% names(result$values)))
  expect_equal(result$values$n_systems, 1)
})

test_that("generative_sign_reversal detects positive slope (generative)", {
  set.seed(42)
  dat <- data.frame(
    system = "software",
    diversity = 1:20,
    speciation_rate = 1:20 * 0.15 + rnorm(20, 0, 0.1)
  )
  result <- generative_sign_reversal(dat, seed = 42)
  expect_gt(result$values$mean_slope, 0)
  expect_equal(result$values$positive_slope_share, 1)
})

test_that("generative_sign_reversal detects negative slope (finite)", {
  set.seed(42)
  dat <- data.frame(
    system = "mining",
    diversity = 1:20,
    speciation_rate = -1:-(20) * 0.15 + 20 + rnorm(20, 0, 0.1)
  )
  result <- generative_sign_reversal(dat, seed = 42)
  expect_lt(result$values$mean_slope, 0)
  expect_equal(result$values$positive_slope_share, 0)
})

test_that("generative_sign_reversal handles contrast between substrates", {
  set.seed(42)
  gen_dat <- data.frame(
    system = "software",
    diversity = 1:20,
    speciation_rate = 1:20 * 0.1 + rnorm(20, 0, 0.05)
  )
  fin_dat <- data.frame(
    system = "mining",
    diversity = 1:20,
    speciation_rate = -1:-(20) * 0.1 + 20 + rnorm(20, 0, 0.05)
  )
  dat <- rbind(gen_dat, fin_dat)
  result <- generative_sign_reversal(dat, seed = 42)
  expect_equal(result$values$n_systems, 2)
  expect_equal(result$values$positive_slope_share, 0.5)
})

test_that("generative_sign_reversal rejects bad data", {
  expect_error(generative_sign_reversal("not a data frame"))
  expect_error(generative_sign_reversal(data.frame(system = "x", diversity = 1)))
})

# Cross-function consistency

test_that("old economics.R functions still work unchanged", {
  dat <- data.frame(
    system = rep(c("newspapers", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(100 * exp(-0.03 * 0:19), 100 * exp(-0.08 * 0:19))
  )
  result <- cdi_economics(dat, seed = 42)
  expect_true(result$metadata$converged)
  expect_equal(result$values$n_systems, 2)

  trig_dat <- data.frame(
    system = rep(c("newspapers", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(100 * exp(-0.03 * 0:19), 100 * exp(-0.08 * 0:19)),
    trigger_year = c(rep(1998, 20), rep(2002, 20))
  )
  result2 <- threshold_disruption(trig_dat, seed = 42)
  expect_true(result2$metadata$converged)
})

test_that("formula functions are distinct from qualitative functions", {
  dat <- make_cdi_step_data(peak = 100, post_cap = 20, n_pre = 10, n_post = 15)
  qual <- cdi_economics(dat, seed = 42)
  expect_true(qual$metadata$converged)
  quant <- step_cdi_comparison(dat, seed = 42)
  expect_true(quant$metadata$converged)
  expect_gt(quant$values$step_wins_share, 0.5)
})
