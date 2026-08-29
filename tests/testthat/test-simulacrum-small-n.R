# test-simulacrum-small-n.R — T3: Small-n step vs sigmoid discrimination
#
# Tests the minimum n required to reliably distinguish a step function
# from a steep sigmoid using AIC comparison.
#
# Findings:
#   - With noise_sd=0.02: minimum n = 5 for >80% reliable delta_AIC > 2
#   - With noise_sd=0 (clean): n = 3 already gives perfect discrimination
#   - At n=3 with noise: discrimination is marginal, often favors sigmoid
#     (consistent with the manuscript's delta_AIC = -1.55 on 3 points)
#
# Inference: The manuscript's AIC comparison (-11.01 vs -9.46, delta = -1.55)
# on 3 data points is inconclusive — the small sample size cannot reliably
# distinguish a step from a sigmoid. A minimum of n=5 is needed.

library(testthat)

context("Simulacrum T3: Small-n step vs sigmoid discrimination")

source_simulacrum("generate_step.R")
source_simulacrum("generate_sigmoid.R")

# ---- Inline fit_step (same as test-simulacrum-step-recovery.R) ----

fit_step <- function(theta, rho) {
  n <- length(theta)
  ord <- order(theta)
  theta_s <- theta[ord]
  rho_s <- rho[ord]

  best_rss <- Inf
  best_bp <- 0
  best_post <- 0
  best_pre <- 0

  for (bp in theta_s) {
    post <- rho_s[theta_s >= bp]
    pre <- rho_s[theta_s < bp]
    post_mean <- if (length(post) > 0) mean(post) else 0
    pre_mean <- if (length(pre) > 0) mean(pre) else 0
    pred <- ifelse(theta_s < bp, pre_mean, post_mean)
    rss <- sum((rho_s - pred)^2)
    if (rss < best_rss) {
      best_rss <- rss
      best_bp <- bp
      best_post <- post_mean
      best_pre <- pre_mean
    }
  }

  # Also test bp = 0 explicitly
  rho_post0 <- mean(rho_s[theta_s >= 0])
  rho_pre0 <- mean(rho_s[theta_s < 0])
  pred_0 <- ifelse(theta_s < 0, rho_pre0, rho_post0)
  rss_0 <- sum((rho_s - pred_0)^2)
  if (rss_0 <= best_rss * 1.1) {
    best_bp <- 0
    best_rss <- rss_0
    best_pre <- rho_pre0
    best_post <- rho_post0
  }

  k_step <- 2
  aic_step <- n * log(best_rss / n) + 2 * k_step

  rho_sat_est <- max(rho_s, na.rm = TRUE)
  best_sig_rss <- Inf
  best_sig_k <- 1
  best_sig_x0 <- 0
  for (k in c(0.5, 1, 2, 5, 10, 20, 50, 100)) {
    for (x0 in seq(min(theta_s), max(theta_s), length.out = 50)) {
      pred <- rho_sat_est / (1 + exp(-k * (theta_s - x0)))
      rss <- sum((rho_s - pred)^2)
      if (rss < best_sig_rss) {
        best_sig_rss <- rss
        best_sig_k <- k
        best_sig_x0 <- x0
      }
    }
  }
  k_sig <- 3
  aic_sig <- n * log(best_sig_rss / n) + 2 * k_sig

  list(
    step = list(theta_star = best_bp, rho_sat = best_post, rss = best_rss, aic = aic_step),
    sigmoid = list(k = best_sig_k, x0 = best_sig_x0, rho_sat = rho_sat_est, rss = best_sig_rss, aic = aic_sig),
    best_model = if (aic_step < aic_sig) "step" else "sigmoid",
    delta_aic = aic_sig - aic_step
  )
}

# ---- Test parameters ----

RHO_SAT <- 0.35
THETA_STAR <- 0
NOISE_SD <- 0.02
SEEDS <- 1:10
N_VALUES <- c(3, 5, 10, 20, 40)

# ---- Test 1: n=3 — marginal discrimination (noisy) ----

test_that("small-n: n=3 discrimination is marginal with noise", {
  step_wins <- 0
  for (seed in SEEDS) {
    sim <- generate_step_function(seed = seed, n_pre = 1, n_post = 2,
                                   rho_sat = RHO_SAT, theta_star = THETA_STAR,
                                   noise_sd = NOISE_SD)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    if (fits$best_model == "step") step_wins <- step_wins + 1
  }
  # At n=3, step should NOT win >80% (it's marginal)
  expect_lt(step_wins / length(SEEDS), 0.8)
})

# ---- Test 2: n=5 — reliable discrimination (noisy) ----

test_that("small-n: n=5 reliably discriminates step from sigmoid with noise", {
  for (seed in SEEDS) {
    sim <- generate_step_function(seed = seed, n_pre = 2, n_post = 3,
                                   rho_sat = RHO_SAT, theta_star = THETA_STAR,
                                   noise_sd = NOISE_SD)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    expect_equal(fits$best_model, "step")
    # delta_AIC should be decisively > 2 (rule of thumb for strong evidence)
    # The fitter can produce very large delta_AIC values; we just check > 2
    expect_gt(fits$delta_aic, 2)
  }
})

# ---- Test 3: n=5 — clean data gives perfect discrimination ----

test_that("small-n: n=5 with clean data discriminates perfectly", {
  for (seed in SEEDS) {
    sim <- generate_step_function(seed = seed, n_pre = 2, n_post = 3,
                                   rho_sat = RHO_SAT, theta_star = THETA_STAR,
                                   noise_sd = 0)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    expect_equal(fits$best_model, "step")
    # Clean data: step fits perfectly, sigmoid never can
    expect_true(is.infinite(fits$delta_aic) || fits$delta_aic > 10)
  }
})

# ---- Test 4: n=3 — clean data gives perfect discrimination ----

test_that("small-n: n=3 with clean data still discriminates", {
  step_wins <- 0
  delta_gt_2 <- 0
  for (seed in 1:100) {
    sim <- generate_step_function(seed = seed, n_pre = 1, n_post = 2,
                                   rho_sat = RHO_SAT, theta_star = THETA_STAR,
                                   noise_sd = 0)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    if (fits$best_model == "step") step_wins <- step_wins + 1
    if (is.infinite(fits$delta_aic) || fits$delta_aic > 2) delta_gt_2 <- delta_gt_2 + 1
  }
  # With clean data, even n=3 works perfectly
  expect_equal(step_wins, 100)
  expect_equal(delta_gt_2, 100)
})

# ---- Test 5: n=10, 20, 40 are all trivially discriminable ----

test_that("small-n: n >= 10 reliably discriminates with noise", {
  for (n in c(10, 20, 40)) {
    n_pre <- floor(n / 2)
    n_post <- n - n_pre
    for (seed in SEEDS) {
      sim <- generate_step_function(seed = seed, n_pre = n_pre, n_post = n_post,
                                     rho_sat = RHO_SAT, theta_star = THETA_STAR,
                                     noise_sd = NOISE_SD)
      fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
      expect_equal(fits$best_model, "step")
      expect_gt(fits$delta_aic, 2)
    }
  }
})