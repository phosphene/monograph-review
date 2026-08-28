#!/usr/bin/env Rscript
# valence Framework: R-based Enhancements to Quantitative Tests
# Uses R 4.4.3 with ape, nlme, brms

library(stats)

cat("================================================================\n")
cat("R ENHANCEMENT 1: Exact Permutation Test — Cross-Family Concordance\n")
cat("================================================================\n\n")

# With only 6 categories, we can enumerate all 720 possible orderings
# and compute the exact probability of ρ ≥ 0.941 by chance

observed_oro <- c(1, 2, 2, 2, 3, 4)  # ndh, rpo, psa, psb, atp, rpl/rps
observed_cus <- c(1, 2, 3, 4, 5, 6)

# Observed Spearman ρ
obs_rho <- cor(observed_oro, observed_cus, method = "spearman")
cat(sprintf("Observed cross-family Spearman ρ = %.4f\n", obs_rho))

# Generate all 720 permutations of 6 items manually
generate_perms <- function(v) {
  if (length(v) == 1) return(list(v))
  result <- list()
  for (i in seq_along(v)) {
    rest <- generate_perms(v[-i])
    for (r in rest) result <- c(result, list(c(v[i], r)))
  }
  result
}

all_perms <- generate_perms(1:6)
rho_dist <- sapply(all_perms, function(perm) cor(observed_oro, perm, method = "spearman"))
p_exact <- mean(rho_dist >= obs_rho)
cat(sprintf("Exact permutation test (all %d permutations of 6 items):\n", length(all_perms)))
cat(sprintf("  P(ρ ≥ %.4f) = %.6f\n", obs_rho, p_exact))
cat(sprintf("  P(ρ ≥ %.4f) = %d / %d\n", obs_rho, sum(rho_dist >= obs_rho), length(all_perms)))
cat(sprintf("  This is the EXACT probability, not an approximation.\n\n"))

cat("================================================================\n")
cat("R ENHANCEMENT 2: Buchnera Sensitivity Check\n")
cat("================================================================\n\n")

# Re-run endosymbiont model comparison with only 1 Buchnera strain
# to verify result isn't driven by triplicate data from one lineage

# Full dataset
t_full <- c(0, 40, 65, 80, 100, 220, 220, 220, 180, 200, 240, 270, 270)
y_full <- c(1.0, 0.240, 0.254, 0.167, 0.045, 0.233, 0.225, 0.208, 0.109, 0.058, 0.075, 0.103, 0.057)
names_full <- c("Ancestor", "Blochmannia", "Wigglesworthia", "Moranella", "Tremblaya",
                "Buchnera_APS", "Buchnera_Sg", "Buchnera_Bp", "Portiera", "Hodgkinia",
                "Carsonella", "Sulcia", "Nasuia")

# Reduced: keep only Buchnera APS, remove Sg and Bp
keep <- !(names_full %in% c("Buchnera_Sg", "Buchnera_Bp"))
t_red <- t_full[keep]
y_red <- y_full[keep]

cat("Full dataset: n =", length(t_full), "\n")
cat("Reduced (1 Buchnera): n =", length(t_red), "\n\n")

# Fit single exponential
fit_se_full <- nls(y ~ exp(-k * t), data = data.frame(t = t_full, y = y_full),
                   start = list(k = 0.01), lower = list(k = 0), algorithm = "port")
fit_se_red <- nls(y ~ exp(-k * t), data = data.frame(t = t_red, y = y_red),
                  start = list(k = 0.01), lower = list(k = 0), algorithm = "port")

# Fit logistic
fit_log_full <- nls(y ~ cmin + (1 - cmin) / (1 + exp(k * (t - tmid))),
                    data = data.frame(t = t_full, y = y_full),
                    start = list(cmin = 0.05, k = 0.05, tmid = 50),
                    lower = list(cmin = 0, k = 0.001, tmid = 5),
                    upper = list(cmin = 0.5, k = 1, tmid = 300),
                    algorithm = "port")
fit_log_red <- nls(y ~ cmin + (1 - cmin) / (1 + exp(k * (t - tmid))),
                   data = data.frame(t = t_red, y = y_red),
                   start = list(cmin = 0.05, k = 0.05, tmid = 50),
                   lower = list(cmin = 0, k = 0.001, tmid = 5),
                   upper = list(cmin = 0.5, k = 1, tmid = 300),
                   algorithm = "port")

# AICc function
AICc <- function(fit) {
  n <- length(residuals(fit))
  k <- length(coef(fit))
  aic <- AIC(fit)
  aic + (2 * k * (k + 1)) / (n - k - 1)
}

cat("FULL DATASET:\n")
cat(sprintf("  Single Exp AICc: %.2f\n", AICc(fit_se_full)))
cat(sprintf("  Logistic AICc:   %.2f\n", AICc(fit_log_full)))
cat(sprintf("  Δ(SE - Log):      %.2f\n", AICc(fit_se_full) - AICc(fit_log_full)))
cat("\n")

cat("REDUCED DATASET (1 Buchnera only):\n")
cat(sprintf("  Single Exp AICc: %.2f\n", AICc(fit_se_red)))
cat(sprintf("  Logistic AICc:   %.2f\n", AICc(fit_log_red)))
cat(sprintf("  Δ(SE - Log):      %.2f\n", AICc(fit_se_red) - AICc(fit_log_red)))
cat("\n")

cat("SENSITIVITY: If ΔAICc is similar in both → result not Buchnera-driven.\n")
cat("If ΔAICc changes substantially → result was dependent on Buchnera replicates.\n\n")

cat("================================================================\n")
cat("R ENHANCEMENT 3: Bootstrap CI on Plant Gene-Loss Correlations\n")
cat("================================================================\n\n")

# Bootstrap CI on Spearman ρ for biochemistry-predicted vs. observed
set.seed(42)
n_boot <- 10000

pred_scores <- c(0, 1, 1, 2, 3, 5)  # ndh, rpo, psa, psb, atp, rpl/rps
oro_ranks <- c(1, 2, 2, 2, 3, 4)
cus_ranks <- c(1, 2, 3, 4, 5, 6)

# Bootstrap by resampling gene categories with replacement
boot_rho_oro <- replicate(n_boot, {
  idx <- sample(1:6, 6, replace = TRUE)
  cor(pred_scores[idx], oro_ranks[idx], method = "spearman")
})

boot_rho_cus <- replicate(n_boot, {
  idx <- sample(1:6, 6, replace = TRUE)
  cor(pred_scores[idx], cus_ranks[idx], method = "spearman")
})

boot_rho_cross <- replicate(n_boot, {
  idx <- sample(1:6, 6, replace = TRUE)
  cor(oro_ranks[idx], cus_ranks[idx], method = "spearman")
})

cat("Bootstrap 95% CIs (10,000 resamples):\n\n")
cat(sprintf("  Predicted → Oro:  ρ = %.3f, 95%% CI [%.3f, %.3f]\n",
    cor(pred_scores, oro_ranks, method = "spearman"),
    quantile(boot_rho_oro, 0.025, na.rm = TRUE),
    quantile(boot_rho_oro, 0.975, na.rm = TRUE)))

cat(sprintf("  Predicted → Cus:  ρ = %.3f, 95%% CI [%.3f, %.3f]\n",
    cor(pred_scores, cus_ranks, method = "spearman"),
    quantile(boot_rho_cus, 0.025, na.rm = TRUE),
    quantile(boot_rho_cus, 0.975, na.rm = TRUE)))

cat(sprintf("  Cross-family:     ρ = %.3f, 95%% CI [%.3f, %.3f]\n",
    cor(oro_ranks, cus_ranks, method = "spearman"),
    quantile(boot_rho_cross, 0.025, na.rm = TRUE),
    quantile(boot_rho_cross, 0.975, na.rm = TRUE)))

cat("\nIf lower CI bound > 0.5, the correlation is robust to resampling.\n\n")

cat("================================================================\n")
cat("R ENHANCEMENT 4: Bayesian Model Comparison — Endosymbiont\n")
cat("================================================================\n\n")

# Use brms for Bayesian nonlinear regression if feasible
# For now, use BIC comparison as a Bayesian approximation

cat("BIC comparison (Bayesian analogue of AICc):\n")
cat(sprintf("  Full data — Single Exp BIC: %.2f\n", BIC(fit_se_full)))
cat(sprintf("  Full data — Logistic BIC:   %.2f\n", BIC(fit_log_full)))
cat(sprintf("  Δ(SE - Log):                %.2f\n", BIC(fit_se_full) - BIC(fit_log_full)))
cat("\n")
cat("BIC penalizes model complexity more than AIC.\n")
cat("If logistic still preferred (or indistinguishable), the result is robust\n")
cat("to the choice of information criterion.\n\n")

cat("================================================================\n")
cat("R ENHANCEMENT 5: Nonlinear Mixed-Effects — Endosymbiont with Lineage\n")
cat("================================================================\n\n")

# The endosymbiont data has multiple lineages (Buchnera, Blochmannia, etc.)
# Each lineage may have its own rate. NLME can model this.

library(nlme)

df <- data.frame(
  t = c(0, 40, 65, 80, 100, 220, 180, 200, 240, 270, 270),
  y = c(1.0, 0.240, 0.254, 0.167, 0.045, 0.233, 0.109, 0.058, 0.075, 0.103, 0.057),
  lineage = c("ancestor", "Blochmannia", "Wigglesworthia", "Moranella", "Tremblaya",
              "Buchnera", "Portiera", "Hodgkinia", "Carsonella", "Sulcia", "Nasuia")
)

# Simple fixed-effects NLS for the logistic (as baseline)
fit_logistic <- nls(y ~ cmin + (1 - cmin) / (1 + exp(k * (t - tmid))),
                    data = df,
                    start = list(cmin = 0.05, k = 0.05, tmid = 50),
                    lower = list(cmin = 0, k = 0.001, tmid = 5),
                    upper = list(cmin = 0.5, k = 1, tmid = 300),
                    algorithm = "port")

cat("Logistic fit (single Buchnera, n=11):\n")
cat(sprintf("  cmin = %.4f, k = %.4f, tmid = %.1f\n", coef(fit_logistic)[1], 
    coef(fit_logistic)[2], coef(fit_logistic)[3]))
cat(sprintf("  R² = %.4f\n", 1 - sum(residuals(fit_logistic)^2) / sum((df$y - mean(df$y))^2)))
cat(sprintf("  Residual SE = %.4f\n", summary(fit_logistic)$sigma))
cat("\nParameter confidence intervals:\n")
print(confint(fit_logistic))

cat("\n================================================================\n")
cat("SUMMARY OF R ENHANCEMENTS\n")
cat("================================================================\n\n")
cat("1. Exact/MC permutation test: precise p-value for cross-family concordance\n")
cat("2. Buchnera sensitivity: verify result isn't driven by triplicate data\n")
cat("3. Bootstrap CIs: confidence intervals on all three correlations\n")
cat("4. BIC comparison: Bayesian-adjacent robustness check on model selection\n")
cat("5. Parameter CIs from NLS: confidence bounds on logistic floor estimate\n")
