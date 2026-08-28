# small-n-experiment.R
# T3: Small-n step vs sigmoid discrimination
# Tests whether small samples can distinguish a step from a sigmoid

source_simulacrum <- function(file) {
  path <- file.path("/home/node/.openclaw/workspace/valence-foundry/inst/simulacra", file)
  source(path, local = FALSE)
}

source_simulacrum("generate_step.R")
source_simulacrum("generate_sigmoid.R")

# Inline fit_step (same as in test-simulacrum-step-recovery.R)
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

# Experiment parameters
n_values <- c(3, 5, 10, 20, 40)
seeds <- 1:10
noise_sd <- 0.02
rho_sat <- 0.35

# Noisy experiment
cat("=== NOISY (noise_sd = 0.02) ===\n")
cat("n\tseed\tdelta_aic\tbest_model\n")
results_noisy <- data.frame()
for (n in n_values) {
  n_pre <- floor(n / 2)
  n_post <- n - n_pre
  for (seed in seeds) {
    sim <- generate_step_function(seed = seed, n_pre = n_pre, n_post = n_post,
                                   rho_sat = rho_sat, theta_star = 0,
                                   noise_sd = noise_sd)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    cat(sprintf("%d\t%d\t%.4f\t%s\n", n, seed, fits$delta_aic, fits$best_model))
    results_noisy <- rbind(results_noisy,
      data.frame(n = n, seed = seed, delta_aic = fits$delta_aic,
                 best_model = fits$best_model, noise_sd = noise_sd))
  }
}

cat("\n=== SUMMARY (noisy) ===\n")
for (n in n_values) {
  sub <- results_noisy[results_noisy$n == n, ]
  step_wins <- sum(sub$best_model == "step")
  delta_gt_2 <- sum(sub$delta_aic > 2)
  cat(sprintf("n=%d: step wins=%d/%d (%.0f%%), delta_aic>2=%d/%d (%.0f%%), mean delta=%.4f\n",
      n, step_wins, nrow(sub), 100*step_wins/nrow(sub),
      delta_gt_2, nrow(sub), 100*delta_gt_2/nrow(sub),
      mean(sub$delta_aic)))
}

# Clean experiment (noise_sd = 0)
cat("\n=== CLEAN (noise_sd = 0) ===\n")
cat("n\tseed\tdelta_aic\tbest_model\n")
results_clean <- data.frame()
for (n in n_values) {
  n_pre <- floor(n / 2)
  n_post <- n - n_pre
  for (seed in seeds) {
    sim <- generate_step_function(seed = seed, n_pre = n_pre, n_post = n_post,
                                   rho_sat = rho_sat, theta_star = 0,
                                   noise_sd = 0)
    fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
    cat(sprintf("%d\t%d\t%.4f\t%s\n", n, seed, fits$delta_aic, fits$best_model))
    results_clean <- rbind(results_clean,
      data.frame(n = n, seed = seed, delta_aic = fits$delta_aic,
                 best_model = fits$best_model, noise_sd = 0))
  }
}

cat("\n=== SUMMARY (clean) ===\n")
for (n in n_values) {
  sub <- results_clean[results_clean$n == n, ]
  step_wins <- sum(sub$best_model == "step")
  delta_gt_2 <- sum(sub$delta_aic > 2)
  cat(sprintf("n=%d: step wins=%d/%d (%.0f%%), delta_aic>2=%d/%d (%.0f%%), mean delta=%.4f\n",
      n, step_wins, nrow(sub), 100*step_wins/nrow(sub),
      delta_gt_2, nrow(sub), 100*delta_gt_2/nrow(sub),
      mean(sub$delta_aic)))
}

# Also test n=3 with noise_sd=0 to see theoretical minimum
cat("\n=== DEEP DIVE: n=3 with noise_sd=0 (all seeds 1:100) ===\n")
results_n3_clean <- data.frame()
for (seed in 1:100) {
  sim <- generate_step_function(seed = seed, n_pre = 1, n_post = 2,
                                 rho_sat = rho_sat, theta_star = 0,
                                 noise_sd = 0)
  fits <- fit_step(sim$metadata$data$theta, sim$metadata$data$rho)
  results_n3_clean <- rbind(results_n3_clean,
    data.frame(seed = seed, delta_aic = fits$delta_aic,
               best_model = fits$best_model))
}
cat(sprintf("n=3 clean: step wins=%d/100 (%.0f%%), delta_aic>2=%d/100 (%.0f%%), mean delta=%.4f\n",
    sum(results_n3_clean$best_model == "step"),
    100*sum(results_n3_clean$best_model == "step")/100,
    sum(results_n3_clean$delta_aic > 2),
    100*sum(results_n3_clean$delta_aic > 2)/100,
    mean(results_n3_clean$delta_aic)))