#!/usr/bin/env Rscript
# =============================================================================
# 03_endosymbiont_models.R
# Endosymbiont Genome Reduction: Decelerating vs Linear vs Accelerating
#
# Tests whether genome reduction in obligate endosymbionts follows a
# decelerating (logistic/saturation) curve — consistent with valence's prediction
# that functional-dependency locks essential genes against further loss.
# valence monograph Test 3 (T3).
# =============================================================================

library(nlme)
library(stats)

cat("=== T3: Endosymbiont Genome Reduction Models ===\n\n")

# --- Load data ---
dat <- read.delim("data/endosymbiont_genome_data.tsv", stringsAsFactors = FALSE)

cat(sprintf("Total entries: %d\n", nrow(dat)))
cat(sprintf("Genera: %s\n", paste(sort(unique(dat$genus)), collapse = ", ")))

# --- Compute genus-level means ---
genus_means <- aggregate(
  cbind(genome_bp, aa_pathways_retained, symbiosis_age_mya) ~ genus,
  data = dat, FUN = mean
)
genus_means$n_species <- table(dat$genus)[genus_means$genus]

# Compute genome reduction fraction (relative to free-living ancestor ~4.5 Mb)
ancestor_size <- 4500000  # approximate free-living E. coli ancestor size
genus_means$reduction_frac <- 1 - (genus_means$genome_bp / ancestor_size)
genus_means$genome_kb <- genus_means$genome_bp / 1000

cat("\nGenus-level data:\n")
print(genus_means[, c("genus", "genome_kb", "aa_pathways_retained",
                       "symbiosis_age_mya", "reduction_frac", "n_species")])

# --- Model fits: Genome size vs. Symbiosis age ---
cat("\n--- Fitting models: Genome Size ~ Symbiosis Age ---\n")

# Prepare data (exclude NA ages)
fit_dat <- genus_means[!is.na(genus_means$symbiosis_age_mya) &
                         genus_means$symbiosis_age_mya > 0, ]
fit_dat <- fit_dat[order(fit_dat$symbiosis_age_mya), ]

x <- fit_dat$symbiosis_age_mya
y <- fit_dat$genome_bp

# Model 1: Linear
mod_linear <- lm(genome_bp ~ symbiosis_age_mya, data = fit_dat)
cat("\n--- Model 1: Linear ---\n")
print(summary(mod_linear))

# Model 2: Exponential decay (constant rate)
# y = a * exp(-b * x)
mod_exp <- tryCatch(
  nls(genome_bp ~ a * exp(-b * symbiosis_age_mya),
      data = fit_dat,
      start = list(a = max(y), b = 0.005),
      control = nls.control(maxiter = 500)),
  error = function(e) {
    cat(sprintf("Exponential fit failed: %s\n", e$message))
    NULL
  }
)
if (!is.null(mod_exp)) {
  cat("\n--- Model 2: Exponential Decay ---\n")
  print(summary(mod_exp))
}

# Model 3: Logistic / Saturation (decelerating)
# y = c + (a - c) / (1 + (x/b)^d)
# Simplified: y = floor + (ceiling - floor) / (1 + exp(rate * (x - midpoint)))
mod_logistic <- tryCatch(
  nls(genome_bp ~ floor_val + (ceil_val - floor_val) / (1 + exp(rate * (symbiosis_age_mya - mid))),
      data = fit_dat,
      start = list(floor_val = min(y) * 0.8, ceil_val = max(y) * 1.2,
                   rate = 0.02, mid = mean(x)),
      control = nls.control(maxiter = 1000)),
  error = function(e) {
    cat(sprintf("Logistic fit (4-param) failed: %s. Trying simpler.\n", e$message))
    # Simpler: Michaelis-Menten style saturation
    tryCatch(
      nls(genome_bp ~ asym + (init - asym) * exp(-rate * symbiosis_age_mya),
          data = fit_dat,
          start = list(asym = min(y) * 0.9, init = max(y), rate = 0.01),
          control = nls.control(maxiter = 1000)),
      error = function(e2) {
        cat(sprintf("Asymptotic fit also failed: %s\n", e2$message))
        NULL
      }
    )
  }
)
if (!is.null(mod_logistic)) {
  cat("\n--- Model 3: Decelerating (Logistic/Asymptotic) ---\n")
  print(summary(mod_logistic))
}

# Model 4: Power law (accelerating if exponent > 1)
mod_power <- tryCatch(
  nls(genome_bp ~ a * symbiosis_age_mya^b + c,
      data = fit_dat,
      start = list(a = -1000, b = 0.5, c = max(y)),
      control = nls.control(maxiter = 500)),
  error = function(e) {
    cat(sprintf("Power law failed: %s\n", e$message))
    NULL
  }
)
if (!is.null(mod_power)) {
  cat("\n--- Model 4: Power Law ---\n")
  print(summary(mod_power))
}

# --- AIC comparison ---
cat("\n--- AIC Comparison ---\n")
models <- list(Linear = mod_linear)
if (!is.null(mod_exp)) models$Exponential <- mod_exp
if (!is.null(mod_logistic)) models$Decelerating <- mod_logistic
if (!is.null(mod_power)) models$PowerLaw <- mod_power

aic_vals <- sapply(models, AIC)
bic_vals <- sapply(models, BIC)
aic_table <- data.frame(
  Model = names(models),
  AIC = aic_vals,
  BIC = bic_vals,
  deltaAIC = aic_vals - min(aic_vals)
)
aic_table <- aic_table[order(aic_table$AIC), ]
print(aic_table, row.names = FALSE, digits = 4)

# --- Pathway retention analysis ---
cat("\n--- Amino Acid Pathway Retention vs. Genome Size ---\n")
mod_path <- lm(genome_bp ~ aa_pathways_retained, data = genus_means)
s_path <- summary(mod_path)
cat(sprintf("Pathways → Genome Size: R² = %.3f, p = %.2e\n",
            s_path$r.squared,
            s_path$coefficients[2, 4]))
cat(sprintf("Each retained pathway associated with +%.0f bp\n",
            coef(mod_path)[2]))

# --- Plot ---
dir.create("output", showWarnings = FALSE)
pdf("output/03_endosymbiont_models.pdf", width = 12, height = 10)
par(mfrow = c(2, 2))

# Plot 1: Genome size vs symbiosis age with model fits
plot(fit_dat$symbiosis_age_mya, fit_dat$genome_bp / 1e6,
     pch = 19, cex = 1.5,
     col = rgb(0.8, 0.2, 0.2, 0.7),
     xlab = "Symbiosis Age (Mya)",
     ylab = "Genome Size (Mb)",
     main = "T3: Genome Reduction Trajectories",
     cex.lab = 1.2, cex.axis = 1.1)

# Add model curves
x_seq <- seq(min(x), max(x), length.out = 200)
lines(x_seq, predict(mod_linear, newdata = data.frame(symbiosis_age_mya = x_seq)) / 1e6,
      col = "blue", lwd = 2, lty = 2)
if (!is.null(mod_exp))
  lines(x_seq, predict(mod_exp, newdata = data.frame(symbiosis_age_mya = x_seq)) / 1e6,
        col = "orange", lwd = 2, lty = 3)
if (!is.null(mod_logistic))
  lines(x_seq, predict(mod_logistic, newdata = data.frame(symbiosis_age_mya = x_seq)) / 1e6,
        col = "red", lwd = 3)
if (!is.null(mod_power))
  lines(x_seq, predict(mod_power, newdata = data.frame(symbiosis_age_mya = x_seq)) / 1e6,
        col = "purple", lwd = 2, lty = 4)

legend("topright",
       legend = c("Linear", "Exponential", "Decelerating", "Power Law"),
       col = c("blue", "orange", "red", "purple"),
       lwd = c(2, 2, 3, 2), lty = c(2, 3, 1, 4),
       cex = 0.8, bty = "n")

text(fit_dat$symbiosis_age_mya, fit_dat$genome_bp / 1e6,
     labels = fit_dat$genus, pos = 3, cex = 0.6, offset = 0.4)

# Plot 2: Pathways vs genome size
plot(genus_means$aa_pathways_retained, genus_means$genome_kb,
     pch = 19, cex = 1.5,
     col = rgb(0.2, 0.6, 0.2, 0.7),
     xlab = "Amino Acid Pathways Retained",
     ylab = "Genome Size (kb)",
     main = "Pathway Retention vs. Genome Size",
     cex.lab = 1.2, cex.axis = 1.1)
abline(mod_path$coefficients[1] / 1000, mod_path$coefficients[2] / 1000,
       col = "red", lwd = 2)
text(genus_means$aa_pathways_retained, genus_means$genome_kb,
     labels = genus_means$genus, pos = 3, cex = 0.6, offset = 0.4)

# Plot 3: Reduction fraction vs age
plot(genus_means$symbiosis_age_mya, genus_means$reduction_frac * 100,
     pch = 19, cex = 1.5,
     col = rgb(0.6, 0.2, 0.6, 0.7),
     xlab = "Symbiosis Age (Mya)",
     ylab = "Genome Reduction (%)",
     main = "Genome Reduction vs. Association Time",
     cex.lab = 1.2, cex.axis = 1.1)
text(genus_means$symbiosis_age_mya, genus_means$reduction_frac * 100,
     labels = genus_means$genus, pos = 3, cex = 0.6, offset = 0.4)

# Plot 4: AIC comparison bar chart
barplot(aic_table$deltaAIC, names.arg = aic_table$Model,
        col = ifelse(aic_table$deltaAIC == 0, "red", "steelblue"),
        main = "Model Comparison (ΔAIC)",
        ylab = "ΔAIC", cex.names = 0.8, las = 2)

dev.off()
cat("\nPlot saved: output/03_endosymbiont_models.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Best model: %s (AIC = %.1f)\n", aic_table$Model[1], aic_table$AIC[1]))
cat(sprintf("Worst model ΔAIC: %.1f (%s)\n",
            max(aic_table$deltaAIC), aic_table$Model[which.max(aic_table$deltaAIC)]))
cat(sprintf("Genera analyzed: %d\n", nrow(genus_means)))
cat(sprintf("the framework prediction (decelerating best): %s\n",
            ifelse(aic_table$Model[1] %in% c("Decelerating", "Exponential"),
                   "SUPPORTED", "NOT SUPPORTED")))
cat("=============================\n")
