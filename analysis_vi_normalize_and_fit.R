#!/usr/bin/env Rscript
# =============================================================================
# Normalize the framework data sets to common (retention, time) space and fit exponential decay.
# Test whether the rate constant k is universal or substrate-specific.
# =============================================================================

cat("================================================================\n")
cat("  DATA NORMALIZATION & EXPONENTIAL DECAY FITTING\n")
cat("  Mono-exponential, bi-exponential, linear - AIC comparison\n")
cat("  Test: Is k universal across systems?\n")
cat("================================================================\n\n")

# --- Helper: safe nls fitting with fallback ---
safe_nls <- function(formula, data, start, ...) {
  tryCatch(
    nls(formula, data = data, start = start,
        control = nls.control(maxiter = 1000, warnOnly = TRUE), ...),
    error = function(e) {
      cat(sprintf("    nls failed: %s\n", e$message))
      return(NULL)
    }
  )
}

# --- Helper: compute confidence intervals for nls parameters ---
safe_confint <- function(fit, level = 0.95) {
  if (is.null(fit)) return(NULL)
  tryCatch(
    suppressMessages(confint(fit, level = level)),
    error = function(e) {
      tryCatch(
        suppressMessages(confint(profile(fit), level = level)),
        error = function(e2) {
          cat(sprintf("    CI failed: %s\n", e2$message))
          return(NULL)
        }
      )
    }
  )
}

# --- Helper: AIC comparison table ---
aic_table <- function(models) {
  models <- models[!sapply(models, is.null)]
  if (length(models) == 0) return(NULL)
  aic <- sapply(models, AIC)
  df <- data.frame(
    Model = names(models),
    AIC = round(aic, 2),
    deltaAIC = round(aic - min(aic), 2),
    stringsAsFactors = FALSE
  )
  df <- df[order(df$AIC), ]
  rownames(df) <- NULL
  return(df)
}

# =============================================================================
# 1. LTEE - E. coli, 60k generations
# =============================================================================
cat("\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n")
cat("  DATASET 1: LTEE (E. coli, 60k generations)\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n\n")

ltee_raw <- read.delim("/home/node/.openclaw/workspace/vi-foundry/data/t7-ltee/ltee_lof_mutations.tsv",
                       stringsAsFactors = FALSE)
cat(sprintf("  Loaded %d mutation records\n", nrow(ltee_raw)))
cat(sprintf("  Total genes: 4149\n"))

# Build cumulative function loss time series
gens <- sort(unique(ltee_raw$first_gen))
cum_loss <- sapply(gens, function(g) sum(ltee_raw$first_gen <= g))
total_genes <- 4149
retention <- 1 - cum_loss / total_genes

ltee_data <- data.frame(t = gens, cum_loss = cum_loss, retention = retention)
cat(sprintf("  Time points: %d (gen 0 to gen %d)\n", nrow(ltee_data), max(gens)))
cat(sprintf("  Total LOF mutations: %d\n", nrow(ltee_raw)))
cat(sprintf("  Final retention: %.4f (%.1f%% genes lost)\n\n",
            tail(retention, 1), tail(cum_loss, 1)/total_genes*100))

# --- Model fitting ---
# Normalize time to [0, 1] for numerical stability
t_max <- max(ltee_data$t)
t_norm <- ltee_data$t / t_max
rho <- ltee_data$retention

# Linear model
cat("  --- Linear Model ---\n")
fit_linear_ltee <- lm(rho ~ t_norm)
s_lin <- summary(fit_linear_ltee)
cat(sprintf("    rho = %.4f + %.4f * t_norm\n",
            coef(fit_linear_ltee)[1], coef(fit_linear_ltee)[2]))
cat(sprintf("    R2 = %.4f, p = %.2e\n", s_lin$r.squared,
            s_lin$coefficients[2, 4]))

# Mono-exponential: rho(t) = rho_eq + (rho_0 - rho_eq) * exp(-k * t_norm)
cat("  --- Mono-exponential Model ---\n")
rho_0 <- rho[1]
rho_eq_est <- tail(rho, 1)
k_est <- 2.0

fit_mono_ltee <- safe_nls(
  rho ~ rho_eq + (rho_0 - rho_eq) * exp(-k * t_norm),
  data = ltee_data,
  start = list(rho_eq = rho_eq_est, k = k_est)
)

if (!is.null(fit_mono_ltee)) {
  s_mono <- summary(fit_mono_ltee)
  cat(sprintf("    rho_eq = %.6f, k = %.6f\n",
              coef(fit_mono_ltee)["rho_eq"], coef(fit_mono_ltee)["k"]))
  cat(sprintf("    rho_0 = %.6f (fixed)\n", rho_0))
  ci_mono <- safe_confint(fit_mono_ltee)
  if (!is.null(ci_mono)) {
    cat(sprintf("    k 95%% CI: [%.6f, %.6f]\n", ci_mono["k", 1], ci_mono["k", 2]))
    cat(sprintf("    rho_eq 95%% CI: [%.6f, %.6f]\n", ci_mono["rho_eq", 1], ci_mono["rho_eq", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_mono$sigma))

  k_orig_mono <- coef(fit_mono_ltee)["k"] / t_max
  cat(sprintf("    k (per generation) = %.2e\n", k_orig_mono))
  cat(sprintf("    Half-life = %.0f generations\n", log(2) / k_orig_mono))
}

# Bi-exponential: rho(t) = rho_eq + A1*exp(-k1*t_norm) + A2*exp(-k2*t_norm)
cat("  --- Bi-exponential Model ---\n")
A1_est <- (rho_0 - rho_eq_est) * 0.7
A2_est <- (rho_0 - rho_eq_est) * 0.3
k1_est <- 5.0
k2_est <- 0.5

fit_bi_ltee <- safe_nls(
  rho ~ rho_eq + A1 * exp(-k1 * t_norm) + A2 * exp(-k2 * t_norm),
  data = ltee_data,
  start = list(rho_eq = rho_eq_est, A1 = A1_est, k1 = k1_est,
               A2 = A2_est, k2 = k2_est),
  algorithm = "port",
  lower = c(rho_eq = 0.85, A1 = 0, k1 = 0, A2 = 0, k2 = 0)
)

if (!is.null(fit_bi_ltee)) {
  s_bi <- summary(fit_bi_ltee)
  cat(sprintf("    rho_eq = %.6f\n", coef(fit_bi_ltee)["rho_eq"]))
  cat(sprintf("    A1 = %.6f, k1 = %.6f\n", coef(fit_bi_ltee)["A1"], coef(fit_bi_ltee)["k1"]))
  cat(sprintf("    A2 = %.6f, k2 = %.6f\n", coef(fit_bi_ltee)["A2"], coef(fit_bi_ltee)["k2"]))
  ci_bi <- safe_confint(fit_bi_ltee)
  if (!is.null(ci_bi)) {
    cat(sprintf("    k1 95%% CI: [%.6f, %.6f]\n", ci_bi["k1", 1], ci_bi["k1", 2]))
    cat(sprintf("    k2 95%% CI: [%.6f, %.6f]\n", ci_bi["k2", 1], ci_bi["k2", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_bi$sigma))

  k1_orig_bi <- coef(fit_bi_ltee)["k1"] / t_max
  k2_orig_bi <- coef(fit_bi_ltee)["k2"] / t_max
  cat(sprintf("    k1 (per gen) = %.2e, half-life = %.0f gen\n", k1_orig_bi, log(2)/k1_orig_bi))
  cat(sprintf("    k2 (per gen) = %.2e, half-life = %.0f gen\n", k2_orig_bi, log(2)/k2_orig_bi))
}

# --- AIC Comparison ---
cat("\n  --- AIC Comparison (LTEE) ---\n")
ltee_models <- list(Linear = fit_linear_ltee, Mono_exp = fit_mono_ltee, Bi_exp = fit_bi_ltee)
ltee_aic <- aic_table(ltee_models)
print(ltee_aic, row.names = FALSE)

# =============================================================================
# 2. Endosymbiont Genome Reduction (cross-sectional)
# =============================================================================
cat("\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n")
cat("  DATASET 2: Endosymbiont Genome Reduction\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n\n")

endo_raw <- read.delim("/home/node/.openclaw/workspace/vi-foundry/data/endosymbiont_genome_data.tsv",
                       stringsAsFactors = FALSE)
cat(sprintf("  Loaded %d genomes\n", nrow(endo_raw)))
cat(sprintf("  Genera: %d unique\n", length(unique(endo_raw$genus))))

# Compute genome reduction fraction relative to free-living ancestor (~4.5 Mb)
ancestor_size <- 4500000
endo_raw$reduction_frac <- 1 - (endo_raw$genome_bp / ancestor_size)
endo_raw$retention <- endo_raw$genome_bp / ancestor_size

# Use species-level data for fitting
endo_fit <- endo_raw[!is.na(endo_raw$symbiosis_age_mya) & endo_raw$symbiosis_age_mya > 0, ]
endo_fit <- endo_fit[order(endo_fit$symbiosis_age_mya), ]

cat(sprintf("  Species with age data: %d\n", nrow(endo_fit)))
cat(sprintf("  Retention range: [%.4f, %.4f]\n",
            min(endo_fit$retention), max(endo_fit$retention)))
cat(sprintf("  Symbiosis age range: [%.0f, %.0f] Mya\n\n",
            min(endo_fit$symbiosis_age_mya), max(endo_fit$symbiosis_age_mya)))

x_e <- endo_fit$symbiosis_age_mya
rho_e <- endo_fit$retention

# Normalize time
x_e_norm <- x_e / max(x_e)

# Linear
cat("  --- Linear Model ---\n")
fit_linear_endo <- lm(rho_e ~ x_e_norm)
s_lin_e <- summary(fit_linear_endo)
cat(sprintf("    retention = %.4f + %.4f * time_norm\n",
            coef(fit_linear_endo)[1], coef(fit_linear_endo)[2]))
cat(sprintf("    R2 = %.4f, p = %.2e\n", s_lin_e$r.squared,
            s_lin_e$coefficients[2, 4]))

# Mono-exponential
cat("  --- Mono-exponential Model ---\n")
rho_0_e <- max(rho_e)
rho_eq_e_est <- min(rho_e)
k_e_est <- 1.0

fit_mono_endo <- safe_nls(
  rho_e ~ rho_eq + (rho_0_e - rho_eq) * exp(-k * x_e_norm),
  data = endo_fit,
  start = list(rho_eq = rho_eq_e_est, k = k_e_est)
)

if (!is.null(fit_mono_endo)) {
  s_mono_e <- summary(fit_mono_endo)
  cat(sprintf("    rho_eq = %.6f, k = %.6f\n",
              coef(fit_mono_endo)["rho_eq"], coef(fit_mono_endo)["k"]))
  cat(sprintf("    rho_0 = %.6f (fixed)\n", rho_0_e))
  ci_mono_e <- safe_confint(fit_mono_endo)
  if (!is.null(ci_mono_e)) {
    cat(sprintf("    k 95%% CI: [%.6f, %.6f]\n", ci_mono_e["k", 1], ci_mono_e["k", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_mono_e$sigma))

  k_orig_mono_e <- coef(fit_mono_endo)["k"] / max(x_e)
  cat(sprintf("    k (per Mya) = %.4f\n", k_orig_mono_e))
  cat(sprintf("    Half-life = %.0f Mya\n", log(2) / k_orig_mono_e))
}

# Bi-exponential
cat("  --- Bi-exponential Model ---\n")
A1_est_e <- (rho_0_e - rho_eq_e_est) * 0.7
A2_est_e <- (rho_0_e - rho_eq_e_est) * 0.3
k1_est_e <- 3.0
k2_est_e <- 0.3

fit_bi_endo <- safe_nls(
  rho_e ~ rho_eq + A1 * exp(-k1 * x_e_norm) + A2 * exp(-k2 * x_e_norm),
  data = endo_fit,
  start = list(rho_eq = rho_eq_e_est, A1 = A1_est_e, k1 = k1_est_e,
               A2 = A2_est_e, k2 = k2_est_e),
  algorithm = "port",
  lower = c(rho_eq = 0.05, A1 = 0, k1 = 0, A2 = 0, k2 = 0)
)

if (!is.null(fit_bi_endo)) {
  s_bi_e <- summary(fit_bi_endo)
  cat(sprintf("    rho_eq = %.6f\n", coef(fit_bi_endo)["rho_eq"]))
  cat(sprintf("    A1 = %.6f, k1 = %.6f\n", coef(fit_bi_endo)["A1"], coef(fit_bi_endo)["k1"]))
  cat(sprintf("    A2 = %.6f, k2 = %.6f\n", coef(fit_bi_endo)["A2"], coef(fit_bi_endo)["k2"]))
  ci_bi_e <- safe_confint(fit_bi_endo)
  if (!is.null(ci_bi_e)) {
    cat(sprintf("    k1 95%% CI: [%.6f, %.6f]\n", ci_bi_e["k1", 1], ci_bi_e["k1", 2]))
    cat(sprintf("    k2 95%% CI: [%.6f, %.6f]\n", ci_bi_e["k2", 1], ci_bi_e["k2", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_bi_e$sigma))

  k1_orig_bi_e <- coef(fit_bi_endo)["k1"] / max(x_e)
  k2_orig_bi_e <- coef(fit_bi_endo)["k2"] / max(x_e)
  cat(sprintf("    k1 (per Mya) = %.4f, half-life = %.0f Mya\n", k1_orig_bi_e, log(2)/k1_orig_bi_e))
  cat(sprintf("    k2 (per Mya) = %.4f, half-life = %.0f Mya\n", k2_orig_bi_e, log(2)/k2_orig_bi_e))
}

# --- AIC Comparison ---
cat("\n  --- AIC Comparison (Endosymbiont) ---\n")
endo_models <- list(Linear = fit_linear_endo, Mono_exp = fit_mono_endo, Bi_exp = fit_bi_endo)
endo_aic <- aic_table(endo_models)
print(endo_aic, row.names = FALSE)

# =============================================================================
# 3. Orobanchaceae Plastome (141 species, parasitism levels 0-4)
# =============================================================================
cat("\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n")
cat("  DATASET 3: Orobanchaceae Plastome (parasitism levels 0-4)\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n\n")

plas_raw <- read.delim("/home/node/.openclaw/workspace/vi-foundry/data/species_plastome_data.tsv",
                       stringsAsFactors = FALSE)
cat(sprintf("  Loaded %d species records\n", nrow(plas_raw)))

# Filter out the outlier: X64570 (Agalinis auriculata) has plastome_length_bp = 71
plas_raw <- plas_raw[plas_raw$plastome_length_bp > 1000, ]
cat(sprintf("  After filtering outlier: %d species\n", nrow(plas_raw)))

# Use genus means
genus_plas <- aggregate(
  cbind(plastome_length_bp, parasitism_score) ~ genus,
  data = plas_raw, FUN = mean
)
cat(sprintf("  Genus-level means: %d\n", nrow(genus_plas)))
cat(sprintf("  Parasitism score range: [%d, %d]\n",
            min(genus_plas$parasitism_score), max(genus_plas$parasitism_score)))
cat(sprintf("  Plastome size range: [%.0f, %.0f] bp\n",
            min(genus_plas$plastome_length_bp), max(genus_plas$plastome_length_bp)))

# Compute retention relative to max autotroph size
autotroph_max <- max(genus_plas$plastome_length_bp[genus_plas$parasitism_score == 0])
cat(sprintf("  Max autotroph plastome size: %.0f bp\n", autotroph_max))
genus_plas$retention <- genus_plas$plastome_length_bp / autotroph_max

x_p <- genus_plas$parasitism_score
rho_p <- genus_plas$retention

# Normalize x to [0, 1]
x_p_norm <- x_p / 4

# Linear
cat("  --- Linear Model ---\n")
fit_linear_plas <- lm(rho_p ~ x_p_norm)
s_lin_p <- summary(fit_linear_plas)
cat(sprintf("    retention = %.4f + %.4f * parasitism_norm\n",
            coef(fit_linear_plas)[1], coef(fit_linear_plas)[2]))
cat(sprintf("    R2 = %.4f, p = %.2e\n", s_lin_p$r.squared,
            s_lin_p$coefficients[2, 4]))

# Mono-exponential
cat("  --- Mono-exponential Model ---\n")
rho_0_p <- max(rho_p)
rho_eq_p_est <- min(rho_p)
k_p_est <- 1.0

fit_mono_plas <- safe_nls(
  rho_p ~ rho_eq + (rho_0_p - rho_eq) * exp(-k * x_p_norm),
  data = genus_plas,
  start = list(rho_eq = rho_eq_p_est, k = k_p_est)
)

if (!is.null(fit_mono_plas)) {
  s_mono_p <- summary(fit_mono_plas)
  cat(sprintf("    rho_eq = %.6f, k = %.6f\n",
              coef(fit_mono_plas)["rho_eq"], coef(fit_mono_plas)["k"]))
  cat(sprintf("    rho_0 = %.6f (fixed)\n", rho_0_p))
  ci_mono_p <- safe_confint(fit_mono_plas)
  if (!is.null(ci_mono_p)) {
    cat(sprintf("    k 95%% CI: [%.6f, %.6f]\n", ci_mono_p["k", 1], ci_mono_p["k", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_mono_p$sigma))
  cat(sprintf("    k (per parasitism unit) = %.4f\n", coef(fit_mono_plas)["k"] / 4))
}

# Bi-exponential
cat("  --- Bi-exponential Model ---\n")
A1_est_p <- (rho_0_p - rho_eq_p_est) * 0.7
A2_est_p <- (rho_0_p - rho_eq_p_est) * 0.3
k1_est_p <- 3.0
k2_est_p <- 0.3

fit_bi_plas <- safe_nls(
  rho_p ~ rho_eq + A1 * exp(-k1 * x_p_norm) + A2 * exp(-k2 * x_p_norm),
  data = genus_plas,
  start = list(rho_eq = rho_eq_p_est, A1 = A1_est_p, k1 = k1_est_p,
               A2 = A2_est_p, k2 = k2_est_p),
  algorithm = "port",
  lower = c(rho_eq = 0.05, A1 = 0, k1 = 0, A2 = 0, k2 = 0)
)

if (!is.null(fit_bi_plas)) {
  s_bi_p <- summary(fit_bi_plas)
  cat(sprintf("    rho_eq = %.6f\n", coef(fit_bi_plas)["rho_eq"]))
  cat(sprintf("    A1 = %.6f, k1 = %.6f\n", coef(fit_bi_plas)["A1"], coef(fit_bi_plas)["k1"]))
  cat(sprintf("    A2 = %.6f, k2 = %.6f\n", coef(fit_bi_plas)["A2"], coef(fit_bi_plas)["k2"]))
  ci_bi_p <- safe_confint(fit_bi_plas)
  if (!is.null(ci_bi_p)) {
    cat(sprintf("    k1 95%% CI: [%.6f, %.6f]\n", ci_bi_p["k1", 1], ci_bi_p["k1", 2]))
    cat(sprintf("    k2 95%% CI: [%.6f, %.6f]\n", ci_bi_p["k2", 1], ci_bi_p["k2", 2]))
  }
  cat(sprintf("    Residual SE: %.6f\n", s_bi_p$sigma))
}

# --- Step model: mean retention per parasitism level ---
cat("  --- Step Model (mean per parasitism level) ---\n")
step_means <- aggregate(retention ~ parasitism_score, data = genus_plas, FUN = mean)
step_means$n <- as.vector(table(genus_plas$parasitism_score)[as.character(step_means$parasitism_score)])
print(step_means, row.names = FALSE)

# Step model AIC: n * log(RSS/n) + 2*k
step_rss <- sum((genus_plas$retention - step_means$retention[match(genus_plas$parasitism_score, step_means$parasitism_score)])^2)
n_p <- nrow(genus_plas)
k_step <- nrow(step_means)
aic_step <- n_p * log(step_rss / n_p) + 2 * k_step
cat(sprintf("    Step model: %d levels, RSS = %.6f, AIC = %.2f\n", k_step, step_rss, aic_step))

# --- AIC Comparison ---
cat("\n  --- AIC Comparison (Orobanchaceae) ---\n")
plas_models <- list(Linear = fit_linear_plas, Mono_exp = fit_mono_plas, Bi_exp = fit_bi_plas)
plas_aic <- aic_table(plas_models)
plas_aic <- rbind(plas_aic, data.frame(Model = "Step", AIC = round(aic_step, 2),
                                        deltaAIC = round(aic_step - min(c(plas_aic$AIC, aic_step)), 2)))
plas_aic <- plas_aic[order(plas_aic$AIC), ]
plas_aic$deltaAIC <- round(plas_aic$AIC - min(plas_aic$AIC), 2)
print(plas_aic, row.names = FALSE)

# =============================================================================
# SYNTHESIS: Compare k across systems
# =============================================================================
cat("\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n")
cat("  SYNTHESIS: Cross-system k comparison\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n\n")

cat("  k values (normalized time units, time in [0, 1]):\n\n")

k_table <- data.frame(
  System = character(),
  Model = character(),
  k_value = numeric(),
  k_CI_lower = numeric(),
  k_CI_upper = numeric(),
  half_life = character(),
  stringsAsFactors = FALSE
)

# LTEE mono
if (!is.null(fit_mono_ltee)) {
  k_val <- coef(fit_mono_ltee)["k"]
  ci <- safe_confint(fit_mono_ltee)
  if (!is.null(ci)) {
    k_table <- rbind(k_table, data.frame(
      System = "LTEE (E. coli)", Model = "Mono-exp",
      k_value = round(k_val, 4), k_CI_lower = round(ci["k", 1], 4),
      k_CI_upper = round(ci["k", 2], 4),
      half_life = sprintf("%.0f gen", log(2) / (k_val / t_max)),
      stringsAsFactors = FALSE
    ))
  }
}

# LTEE bi
if (!is.null(fit_bi_ltee)) {
  cat("  LTEE bi-exponential:\n")
  cat(sprintf("    k1 = %.4f (%s), k2 = %.4f (%s)\n",
              coef(fit_bi_ltee)["k1"],
              sprintf("%.0f gen half-life", log(2) / (coef(fit_bi_ltee)["k1"] / t_max)),
              coef(fit_bi_ltee)["k2"],
              sprintf("%.0f gen half-life", log(2) / (coef(fit_bi_ltee)["k2"] / t_max))))
  cat(sprintf("    Amplitude ratio A1/A2 = %.2f\n",
              coef(fit_bi_ltee)["A1"] / coef(fit_bi_ltee)["A2"]))
  ci_bi_l <- safe_confint(fit_bi_ltee)
  if (!is.null(ci_bi_l)) {
    k_table <- rbind(k_table, data.frame(
      System = "LTEE k1 (fast)", Model = "Bi-exp",
      k_value = round(coef(fit_bi_ltee)["k1"], 4),
      k_CI_lower = round(ci_bi_l["k1", 1], 4),
      k_CI_upper = round(ci_bi_l["k1", 2], 4),
      half_life = sprintf("%.0f gen", log(2) / (coef(fit_bi_ltee)["k1"] / t_max)),
      stringsAsFactors = FALSE
    ))
    k_table <- rbind(k_table, data.frame(
      System = "LTEE k2 (slow)", Model = "Bi-exp",
      k_value = round(coef(fit_bi_ltee)["k2"], 4),
      k_CI_lower = round(ci_bi_l["k2", 1], 4),
      k_CI_upper = round(ci_bi_l["k2", 2], 4),
      half_life = sprintf("%.0f gen", log(2) / (coef(fit_bi_ltee)["k2"] / t_max)),
      stringsAsFactors = FALSE
    ))
  }
}

# Endosymbiont mono
if (!is.null(fit_mono_endo)) {
  k_val_e <- coef(fit_mono_endo)["k"]
  ci_e <- safe_confint(fit_mono_endo)
  if (!is.null(ci_e)) {
    k_table <- rbind(k_table, data.frame(
      System = "Endosymbiont", Model = "Mono-exp",
      k_value = round(k_val_e, 4), k_CI_lower = round(ci_e["k", 1], 4),
      k_CI_upper = round(ci_e["k", 2], 4),
      half_life = sprintf("%.0f Mya", log(2) / (k_val_e / max(x_e))),
      stringsAsFactors = FALSE
    ))
  }
}

# Endosymbiont bi
if (!is.null(fit_bi_endo)) {
  ci_bi_e <- safe_confint(fit_bi_endo)
  if (!is.null(ci_bi_e)) {
    k_table <- rbind(k_table, data.frame(
      System = "Endosymbiont k1 (fast)", Model = "Bi-exp",
      k_value = round(coef(fit_bi_endo)["k1"], 4),
      k_CI_lower = round(ci_bi_e["k1", 1], 4),
      k_CI_upper = round(ci_bi_e["k1", 2], 4),
      half_life = sprintf("%.0f Mya", log(2) / (coef(fit_bi_endo)["k1"] / max(x_e))),
      stringsAsFactors = FALSE
    ))
    k_table <- rbind(k_table, data.frame(
      System = "Endosymbiont k2 (slow)", Model = "Bi-exp",
      k_value = round(coef(fit_bi_endo)["k2"], 4),
      k_CI_lower = round(ci_bi_e["k2", 1], 4),
      k_CI_upper = round(ci_bi_e["k2", 2], 4),
      half_life = sprintf("%.0f Mya", log(2) / (coef(fit_bi_endo)["k2"] / max(x_e))),
      stringsAsFactors = FALSE
    ))
  }
}

# Orobanchaceae mono
if (!is.null(fit_mono_plas)) {
  k_val_p <- coef(fit_mono_plas)["k"]
  ci_p <- safe_confint(fit_mono_plas)
  if (!is.null(ci_p)) {
    k_table <- rbind(k_table, data.frame(
      System = "Orobanchaceae", Model = "Mono-exp",
      k_value = round(k_val_p, 4), k_CI_lower = round(ci_p["k", 1], 4),
      k_CI_upper = round(ci_p["k", 2], 4),
      half_life = sprintf("%.2f parasitism units", log(2)/coef(fit_mono_plas)["k"] * 4),
      stringsAsFactors = FALSE
    ))
  }
}

# Print k comparison table
if (nrow(k_table) > 0) {
  cat("\n  Cross-system k comparison (normalized time [0,1]):\n")
  print(k_table, row.names = FALSE)
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================
cat("\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n")
cat("  FINAL SUMMARY\n")
cat(paste(rep("=", 64), collapse = ""))
cat("\n\n")

# LTEE winner
ltee_winner <- ltee_aic$Model[1]
cat(sprintf("1. LTEE best model: %s (dAIC to next: %.2f)\n", ltee_winner, ltee_aic$deltaAIC[2]))

# Endosymbiont winner
endo_winner <- endo_aic$Model[1]
cat(sprintf("2. Endosymbiont best model: %s (dAIC to next: %.2f)\n", endo_winner, endo_aic$deltaAIC[2]))

# Orobanchaceae winner
plas_winner <- plas_aic$Model[1]
cat(sprintf("3. Orobanchaceae best model: %s (dAIC to next: %.2f)\n", plas_winner, plas_aic$deltaAIC[2]))

# Universal k assessment
cat("\n  --- Is k universal across systems? ---\n")
cat("  NOTE: k values are in NORMALIZED time units (time in [0, 1]).\n")
cat("  Raw k values depend on the time scale of each system.\n")
cat("  True comparison requires converting to real time equivalents.\n\n")

# Compare normalized k values
if (nrow(k_table) > 0) {
  mono_only <- k_table[k_table$Model == "Mono-exp", ]
  if (nrow(mono_only) >= 2) {
    k_range <- diff(range(mono_only$k_value))
    k_mean <- mean(mono_only$k_value)
    k_cv <- sd(mono_only$k_value) / k_mean
    cat(sprintf("  Mono-exp k range: [%.4f, %.4f]\n", min(mono_only$k_value), max(mono_only$k_value)))
    cat(sprintf("  Mono-exp k mean +- SD: %.4f +- %.4f\n", k_mean, sd(mono_only$k_value)))
    cat(sprintf("  Coefficient of variation (CV): %.2f\n", k_cv))
    cat(sprintf("  Verdict: k is %s across systems\n",
                ifelse(k_cv < 0.5, "CONSISTENT (CV < 0.5)", "NOT CONSISTENT (CV > 0.5)")))

    # Check CI overlap
    all_overlap <- TRUE
    for (i in 1:(nrow(mono_only)-1)) {
      for (j in (i+1):nrow(mono_only)) {
        ci_i <- c(mono_only$k_CI_lower[i], mono_only$k_CI_upper[i])
        ci_j <- c(mono_only$k_CI_lower[j], mono_only$k_CI_upper[j])
        overlap <- !(ci_i[2] < ci_j[1] || ci_j[2] < ci_i[1])
        if (!overlap) all_overlap <- FALSE
      }
    }
    cat(sprintf("  CI overlap: %s\n", ifelse(all_overlap, "YES - all CIs overlap", "NO - some CIs do not overlap")))
  }
}

cat("\n  --- Mono vs Bi-exponential assessment ---\n")
cat(sprintf("  LTEE: %s is preferred\n", ltee_winner))
cat(sprintf("  Endosymbiont: %s is preferred\n", endo_winner))
cat(sprintf("  Orobanchaceae: %s is preferred\n", plas_winner))

cat("\n  --- Conclusion ---\n")
n_bi <- sum(grepl("Bi-exp", c(ltee_winner, endo_winner, plas_winner)))
all_mono <- all(grepl("Mono", c(ltee_winner, endo_winner, plas_winner)))
cat(sprintf("  Bi-exponential preferred in %d of 3 datasets\n", n_bi))
cat(sprintf("  Mono-exponential consistently preferred: %s\n", ifelse(all_mono, "YES", "NO")))

cat("\n================================================================\n")