#!/usr/bin/env Rscript
# =============================================================================
# 01_orobanchaceae_pgls.R
# Orobanchaceae PGLS: Parasitism → Plastome Size
# 
# Tests whether parasitism level predicts plastome size reduction in
# Orobanchaceae, controlling for phylogenetic non-independence.
# valence monograph Test 1 (T1).
# =============================================================================

library(ape)
library(caper)
library(phytools)

cat("=== T1: Orobanchaceae PGLS — Parasitism → Plastome Size ===\n\n")

# --- Load data ---
dat <- read.delim("data/species_plastome_data.tsv", stringsAsFactors = FALSE)
tree <- read.tree("data/orobanchaceae_tree.nwk")

# Clean species names to match tree tip labels
dat$tip_label <- gsub(" ", "_", dat$species)

# Filter to species present in tree
dat <- dat[dat$tip_label %in% tree$tip.label, ]
tree <- drop.tip(tree, tree$tip.label[!tree$tip.label %in% dat$tip_label])

cat(sprintf("Species in analysis: %d\n", nrow(dat)))
cat(sprintf("Tree tips: %d\n", Ntip(tree)))
cat(sprintf("Parasitism score range: %d–%d\n", min(dat$parasitism_score), max(dat$parasitism_score)))
cat(sprintf("Plastome size range: %s–%s bp\n",
            format(min(dat$plastome_length_bp), big.mark=","),
            format(max(dat$plastome_length_bp), big.mark=",")))

# --- Prepare comparative data ---
# Use genus means for species with multiple entries
genus_means <- aggregate(
  cbind(plastome_length_bp, parasitism_score) ~ tip_label,
  data = dat, FUN = mean
)

# Create comparative.data object
rownames(genus_means) <- genus_means$tip_label
comp_dat <- comparative.data(
  phy = tree,
  data = genus_means,
  names.col = tip_label,
  vcv = TRUE,
  na.omit = FALSE,
  warn.dropped = TRUE
)

cat(sprintf("\nSpecies in comparative dataset: %d\n", nrow(comp_dat$data)))

# --- Model 1: Continuous PGLS (parasitism_score as continuous) ---
cat("\n--- Model 1: Continuous PGLS (ML lambda) ---\n")
mod_continuous <- pgls(
  plastome_length_bp ~ parasitism_score,
  data = comp_dat,
  lambda = "ML"
)
s1 <- summary(mod_continuous)
print(s1)

cat(sprintf("\nLambda (ML): %.4f\n", mod_continuous$param["lambda"]))
cat(sprintf("R² (adjusted): %.4f\n", s1$adj.r.squared))
cat(sprintf("F-statistic: %.2f on %d and %d df, p = %.2e\n",
            s1$fstatistic[1], s1$fstatistic[2], s1$fstatistic[3],
            pf(s1$fstatistic[1], s1$fstatistic[2], s1$fstatistic[3], lower.tail = FALSE)))

# --- Model 2: Lambda fixed at 1 (Brownian motion) ---
cat("\n--- Model 2: PGLS with lambda = 1 (Brownian motion) ---\n")
mod_bm <- pgls(
  plastome_length_bp ~ parasitism_score,
  data = comp_dat,
  lambda = 1
)
print(summary(mod_bm))

# --- Model 3: Lambda fixed at 0 (OLS, no phylogenetic signal) ---
cat("\n--- Model 3: OLS (lambda = 0) ---\n")
mod_ols <- pgls(
  plastome_length_bp ~ parasitism_score,
  data = comp_dat,
  lambda = 0
)
print(summary(mod_ols))

# --- Model comparison ---
cat("\n--- AIC Comparison ---\n")
aic_table <- data.frame(
  Model = c("PGLS (ML lambda)", "PGLS (BM, lambda=1)", "OLS (lambda=0)"),
  Lambda = c(mod_continuous$param["lambda"], 1, 0),
  AIC = c(AIC(mod_continuous), AIC(mod_bm), AIC(mod_ols)),
  logLik = c(logLik(mod_continuous), logLik(mod_bm), logLik(mod_ols))
)
aic_table$deltaAIC <- aic_table$AIC - min(aic_table$AIC)
print(aic_table, digits = 4, row.names = FALSE)

# --- Binary recoding robustness ---
cat("\n--- Robustness: Binary recoding (parasite vs non-parasite) ---\n")
genus_means$is_parasite <- as.integer(genus_means$parasitism_score > 0)
comp_dat_bin <- comparative.data(
  phy = tree,
  data = genus_means,
  names.col = tip_label,
  vcv = TRUE, na.omit = FALSE, warn.dropped = TRUE
)

mod_binary <- pgls(
  plastome_length_bp ~ is_parasite,
  data = comp_dat_bin,
  lambda = "ML"
)
s_bin <- summary(mod_binary)
cat(sprintf("Binary parasite effect: %.0f bp (SE %.0f), p = %.2e\n",
            coef(mod_binary)[2],
            s_bin$coefficients[2, 2],
            s_bin$coefficients[2, 4]))

# --- Jackknife: Leave-one-out ---
cat("\n--- Robustness: Leave-one-out jackknife ---\n")
species_list <- comp_dat$phy$tip.label
jack_slopes <- numeric(length(species_list))
jack_pvals <- numeric(length(species_list))

for (i in seq_along(species_list)) {
  sp <- species_list[i]
  sub_data <- genus_means[genus_means$tip_label != sp, ]
  sub_tree <- drop.tip(tree, sp)
  sub_comp <- tryCatch(
    comparative.data(
      phy = sub_tree, data = sub_data,
      names.col = tip_label, vcv = TRUE,
      na.omit = FALSE, warn.dropped = TRUE
    ),
    error = function(e) NULL
  )
  if (!is.null(sub_comp)) {
    sub_mod <- tryCatch(
      pgls(plastome_length_bp ~ parasitism_score,
           data = sub_comp, lambda = "ML"),
      error = function(e) NULL
    )
    if (!is.null(sub_mod)) {
      jack_slopes[i] <- coef(sub_mod)[2]
      jack_pvals[i] <- summary(sub_mod)$coefficients[2, 4]
    }
  }
}

jack_slopes <- jack_slopes[jack_slopes != 0]
jack_pvals <- jack_pvals[jack_pvals != 0]

cat(sprintf("Jackknife slope range: %.0f to %.0f\n", min(jack_slopes), max(jack_slopes)))
cat(sprintf("Jackknife p-value range: %.2e to %.2e\n", min(jack_pvals), max(jack_pvals)))
cat(sprintf("Proportion significant (p < 0.05): %.1f%%\n",
            100 * mean(jack_pvals < 0.05)))

# --- Bootstrap ---
cat("\n--- Robustness: Bootstrap (1000 replicates) ---\n")
set.seed(42)
n_boot <- 1000
boot_slopes <- numeric(n_boot)

for (b in 1:n_boot) {
  idx <- sample(nrow(genus_means), replace = TRUE)
  boot_data <- genus_means[idx, ]
  boot_data$tip_label <- make.unique(boot_data$tip_label)
  # Simple OLS bootstrap (can't easily re-fit phylo with resampled tips)
  boot_mod <- lm(plastome_length_bp ~ parasitism_score, data = boot_data)
  boot_slopes[b] <- coef(boot_mod)[2]
}

cat(sprintf("Bootstrap slope: mean = %.0f, 95%% CI = [%.0f, %.0f]\n",
            mean(boot_slopes),
            quantile(boot_slopes, 0.025),
            quantile(boot_slopes, 0.975)))
cat(sprintf("Proportion negative slopes: %.1f%%\n",
            100 * mean(boot_slopes < 0)))

# --- Save plot ---
pdf("output/01_orobanchaceae_pgls.pdf", width = 10, height = 8)

par(mfrow = c(2, 2))

# Plot 1: Main PGLS scatter
plot(genus_means$parasitism_score, genus_means$plastome_length_bp / 1000,
     pch = 19, col = rgb(0.2, 0.4, 0.8, 0.6),
     xlab = "Parasitism Score", ylab = "Plastome Size (kb)",
     main = "T1: Orobanchaceae PGLS",
     cex = 1.2, cex.lab = 1.2, cex.axis = 1.1)
abline(coef(mod_continuous)[1] / 1000, coef(mod_continuous)[2] / 1000,
       col = "red", lwd = 2)
legend("topright",
       legend = sprintf("PGLS: R²=%.3f, p=%.2e\nλ=%.3f",
                        s1$adj.r.squared,
                        s1$coefficients[2, 4],
                        mod_continuous$param["lambda"]),
       bty = "n", cex = 0.9)

# Plot 2: Residuals
plot(fitted(mod_continuous), residuals(mod_continuous),
     pch = 19, col = rgb(0.2, 0.4, 0.8, 0.5),
     xlab = "Fitted values", ylab = "Residuals",
     main = "PGLS Residuals")
abline(h = 0, lty = 2, col = "gray50")

# Plot 3: Lambda profile
if (requireNamespace("caper", quietly = TRUE)) {
  pg_profile <- pgls.profile(mod_continuous, which = "lambda")
  plot(pg_profile, main = "Lambda Profile Likelihood")
}

# Plot 4: Jackknife slope distribution
hist(jack_slopes, breaks = 30, col = "steelblue",
     main = "Jackknife Slope Distribution",
     xlab = "Slope (bp per parasitism unit)")
abline(v = coef(mod_continuous)[2], col = "red", lwd = 2)
abline(v = 0, lty = 2, col = "gray50")

dev.off()
cat("\nPlot saved: output/01_orobanchaceae_pgls.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Direction: %s (slope = %.0f bp per parasitism unit)\n",
            ifelse(coef(mod_continuous)[2] < 0, "NEGATIVE (as predicted)", "POSITIVE"),
            coef(mod_continuous)[2]))
cat(sprintf("Significance: p = %.2e\n", s1$coefficients[2, 4]))
cat(sprintf("Effect size: R² = %.3f (adjusted)\n", s1$adj.r.squared))
cat(sprintf("Phylogenetic signal: λ = %.3f\n", mod_continuous$param["lambda"]))
cat(sprintf("Robust to jackknife: %s\n",
            ifelse(mean(jack_pvals < 0.05) > 0.95, "YES", "PARTIAL")))
cat("=============================\n")
