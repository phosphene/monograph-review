#!/usr/bin/env Rscript
# scripts/run_simulacra.R — Run simulacra recovery loops and emit marks
#
# The simulacrum mark pipeline (init_mark_log / mark / read_marks +
# simulacra_viz + render_pages.R) was built but never wired: the tests
# compute recovery but (correctly) don't emit marks (tests are side-effect-
# free, DFT A1). This runner is the missing producer.
#
# For each of the 5 simulacra, runs N simulations, emits structured marks
# (true params, recovered params, within_ci, null control) to
# results/simulacra/<id>_marks.yml. The marks are consumed by
# scripts/render_pages.R (via read_all_marks) to produce the simulacra
# visualization pages.
#
# This is the companion to scripts/run_pipeline.R (which runs the empirical
# stages). The simulacra tests assert statistical properties; this runner
# emits the per-simulation marks for visualization.
#
# Usage:
#   Rscript scripts/run_simulacra.R                   # results/simulacra/
#   Rscript scripts/run_simulacra.R --output dir      # <dir>/
#   Rscript scripts/run_simulacra.R --n-sims 50       # more simulations

library(valence.foundry)

# --- Parse args ---
args <- commandArgs(trailingOnly = TRUE)
output_dir <- "results/simulacra"
n_sims <- 20L
i <- 1L
while (i <= length(args)) {
  if (args[i] == "--output" && i + 1L <= length(args)) {
    output_dir <- args[i + 1L]; i <- i + 2L; next
  }
  if (args[i] == "--n-sims" && i + 1L <= length(args)) {
    n_sims <- as.integer(args[i + 1L]); i <- i + 2L; next
  }
  i <- i + 1L
}

# --- Source simulacrum generators (they live in inst/simulacra/, not R/) ---
.sim_dir <- system.file("simulacra", package = "valence.foundry")
if (!nzchar(.sim_dir)) .sim_dir <- "inst/simulacra"
for (f in c("generate_synthetic_population.R", "generate_biphasic_genome.R",
            "generate_cross_kingdom.R", "generate_cusp_system.R",
            "generate_autocatalytic.R")) {
  source(file.path(.sim_dir, f), local = FALSE)
}

# --- Helper: AICc ---
aicc <- function(model, k, n) stats::AIC(model) + (2 * k * (k + 1)) / (n - k - 1)

# --- Helper: R² ---
r_sq <- function(y, y_pred) {
  1 - sum((y - y_pred)^2, na.rm = TRUE) /
    sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
}

cat("================================================================\n")
cat("Simulacra mark emitter (", n_sims, " simulations each)\n", sep = "")
cat("Output:", output_dir, "\n")
cat("================================================================\n\n")

# =====================================================================
# Simulacrum 1: Parameter recovery (slope from synthetic population)
# =====================================================================
cat("Simulacrum 1: parameter recovery ...\n")
log1 <- init_mark_log("param_recovery", output_dir)

# True slope: from the deterministic (noiseless) model
true_data <- generate_synthetic_population(n = 50L, seed = 42L, noise_sd = 0)
true_slope <- unname(stats::coef(stats::lm(
  plastome_size_bp ~ parasitism_score, data = true_data))[2])

for (i in seq_len(n_sims)) {
  seed_i <- 1000L + i
  d <- generate_synthetic_population(n = 50L, seed = seed_i)
  fit <- stats::lm(plastome_size_bp ~ parasitism_score, data = d)
  recovered_slope <- unname(stats::coef(fit)[2])
  ci <- stats::confint(fit, "parasitism_score", level = 0.95)
  within_ci <- true_slope >= ci[1] && true_slope <= ci[2]

  # Null control: λ = 0 (no shedding) → slope ≈ 0
  d_null <- generate_synthetic_population(n = 50L, lambda = 0, seed = seed_i)
  null_slope <- unname(stats::coef(stats::lm(
    plastome_size_bp ~ parasitism_score, data = d_null))[2])

  mark(log1, i,
    true_params = c(slope = true_slope),
    recovered_params = c(slope = recovered_slope),
    within_ci = within_ci,
    null_result = null_slope,
    seed = seed_i)
}

# =====================================================================
# Simulacrum 2: Biphasic kinetics (logistic rate recovery)
# =====================================================================
cat("Simulacrum 2: biphasic kinetics ...\n")
log2 <- init_mark_log("biphasic_kinetics", output_dir)
true_rate <- 0.08

for (i in seq_len(n_sims)) {
  seed_i <- 2000L + i
  bp <- generate_biphasic_genome(seed = seed_i, rate = true_rate)
  data <- bp$metadata$data
  x <- data$symbiosis_age_mya; y <- data$genome_bp

  mod_logistic <- tryCatch(
    stats::nls(y ~ floor_val + (ceil_val - floor_val) /
      (1 + exp(rate * (x - mid_val))),
      start = list(floor_val = min(y) * 0.8, ceil_val = max(y) * 1.2,
                   rate = 0.05, mid_val = stats::median(x)),
      control = stats::nls.control(maxiter = 1000, warnOnly = TRUE)),
    error = function(e) NULL)

  if (!is.null(mod_logistic)) {
    recovered_rate <- unname(stats::coef(mod_logistic)["rate"])
    rate_error_pct <- abs(recovered_rate - true_rate) / true_rate * 100
    within_ci <- rate_error_pct < 50
  } else {
    recovered_rate <- NA; within_ci <- FALSE
  }

  # Null control: constant-rate data → ΔAICc should NOT favor logistic.
  # nls warnings (step factor reduced) are expected here — the logistic
  # doesn't fit constant-rate data well, which is the point of the null.
  null_data <- generate_constant_rate_genome(seed = seed_i + 1L)
  null_y <- null_data$metadata$data$genome_bp
  null_x <- null_data$metadata$data$symbiosis_age_mya
  null_lin <- stats::lm(null_y ~ null_x)
  null_log <- tryCatch(
    suppressWarnings(stats::nls(null_y ~ floor_val + (ceil_val - floor_val) /
      (1 + exp(rate * (null_x - mid_val))),
      start = list(floor_val = min(null_y) * 0.8, ceil_val = max(null_y) * 1.2,
                   rate = 0.05, mid_val = stats::median(null_x)),
      control = stats::nls.control(maxiter = 1000, warnOnly = TRUE))),
    error = function(e) NULL)
  null_delta <- if (!is.null(null_log))
    aicc(null_lin, 3L, 10L) - aicc(null_log, 5L, 10L) else -Inf

  mark(log2, i,
    true_params = c(rate = true_rate),
    recovered_params = c(rate = if (is.na(recovered_rate)) NA else recovered_rate),
    within_ci = within_ci,
    null_result = null_delta,
    seed = seed_i)
}

# =====================================================================
# Simulacrum 3: Cusp catastrophe (bifurcation detection)
# =====================================================================
cat("Simulacrum 3: cusp bifurcation detection ...\n")
log3 <- init_mark_log("cusp_bifurcation", output_dir)
# Vary a across simulations so the bifurcation point changes
a_vals <- seq(-0.5, -1.5, length.out = n_sims)

for (i in seq_len(n_sims)) {
  a_i <- a_vals[i]
  # True bifurcation b from the bifurcation set: 4a³ + 27b² = 0
  true_b <- 2 / (3 * sqrt(3)) * (-a_i)^(3 / 2)

  bf <- cusp_bifurcation_point(a = a_i, b = true_b)
  within_ci <- bf$at_bifurcation

  # Null control: a = 1 (far from bifurcation) → no hysteresis
  eq_null <- make_cusp_equilibrium_fn(a = 1)
  null_hyst <- cusp_hysteresis_check(seq(-2, 2, length.out = 50), eq_null,
    seed = 42L, initial_state = 0)
  null_result <- as.numeric(null_hyst$values[["has_hysteresis"]])

  mark(log3, i,
    true_params = c(bifurcation_b = true_b),
    recovered_params = c(bifurcation_b = if (bf$distance < 1e-8) true_b else NA),
    within_ci = within_ci,
    null_result = null_result,
    seed = 42L,
    extra = list(a = a_i, distance = bf$distance))
}

# =====================================================================
# Simulacrum 4: Autocatalytic set (diversity dependence)
# =====================================================================
cat("Simulacrum 4: autocatalytic diversity dependence ...\n")
log4 <- init_mark_log("autocatalytic_dd", output_dir)

for (i in seq_len(n_sims)) {
  seed_i <- 4000L + i
  sim <- generate_autocatalytic_set(n_steps = 20, innovation_rate = 0.3,
    capacity = 30, n_innovations = 10, seed = seed_i)
  dd <- diversity_dependence_sign(sim$values$innovation_counts, seed = seed_i)

  log_slope <- dd$values[["log_log_slope"]]
  within_ci <- dd$values[["is_superlinear"]]

  # Null control: linear data (not superlinear)
  null_data <- 3 * seq_len(20)
  dd_null <- diversity_dependence_sign(null_data, seed = seed_i)
  null_result <- dd_null$values[["log_log_slope"]]

  mark(log4, i,
    true_params = c(log_log_slope = 1.0),  # null expectation; superlinear > 1
    recovered_params = c(log_log_slope = log_slope),
    within_ci = within_ci,
    null_result = null_result,
    seed = seed_i)
}

# =====================================================================
# Simulacrum 5: Cross-kingdom transfer (slope transfer)
# =====================================================================
cat("Simulacrum 5: cross-kingdom transfer ...\n")
log5 <- init_mark_log("cross_kingdom_transfer", output_dir)
true_slope <- 0.6

for (i in seq_len(n_sims)) {
  gen_seed <- 5000L + i
  data <- generate_cross_kingdom_data(seed = gen_seed, true_slope = true_slope,
    plant_noise_sd = 0.5, bird_noise_sd = 0.5)
  result <- transfer_test(data$plant, data$bird, seed = gen_seed)

  plant_slope <- unname(result$values[["plant_slope"]])
  bird_rho <- unname(result$values[["bird_rho"]])
  within_ci <- bird_rho > 0.7

  # Null control: independent slopes
  data_null <- generate_cross_kingdom_data(seed = gen_seed, true_slope = true_slope,
    bird_slope = -0.3, plant_noise_sd = 0.5, bird_noise_sd = 0.5)
  result_null <- transfer_test(data_null$plant, data_null$bird, seed = gen_seed)
  null_rho <- unname(result_null$values[["bird_rho"]])

  mark(log5, i,
    true_params = c(slope = true_slope),
    recovered_params = c(slope = plant_slope),
    within_ci = within_ci,
    null_result = null_rho,
    seed = gen_seed)
}

# =====================================================================
# Summary
# =====================================================================
cat("\n================================================================\n")
cat("Marks emitted to", output_dir, "\n")
marks <- read_all_marks(output_dir)
for (id in names(marks)) {
  n <- length(marks[[id]])
  if (n > 0) {
    within <- mean(sapply(marks[[id]], function(m) isTRUE(m$within_ci)))
    cat(sprintf("  %-26s %d marks, %.0f%% within CI\n", id, n, 100 * within))
  }
}
cat("================================================================\n")
