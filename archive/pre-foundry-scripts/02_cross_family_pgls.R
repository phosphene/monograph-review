#!/usr/bin/env Rscript
# =============================================================================
# 02_cross_family_pgls.R
# Cross-Family PGLS: Parasitism → Plastome Size across angiosperm families
#
# Tests whether the parasitism–plastome relationship holds across
# independently evolved parasitic plant lineages using family-level means.
# valence monograph Test 2 (T2).
# =============================================================================

library(ape)
library(caper)
library(phytools)

cat("=== T2: Cross-Family PGLS — Parasitism → Plastome Size ===\n\n")

# --- Load data ---
dat <- read.delim("data/cross_family_plastome_data.tsv", stringsAsFactors = FALSE)

cat(sprintf("Total species: %d\n", nrow(dat)))
cat(sprintf("Families: %s\n", paste(sort(unique(dat$family)), collapse = ", ")))
cat(sprintf("Parasitism levels: %s\n", paste(sort(unique(dat$parasitism_level)), collapse = ", ")))

# --- Construct family-level APG IV topology ---
# We construct a synthetic family-level tree based on APG IV relationships.
# Branch lengths are approximate divergence times (Mya) from molecular dating.
cat("\n--- Constructing APG IV family-level tree ---\n")

# Family means
fam_means <- aggregate(
  cbind(plastome_bp, parasitism_score) ~ family,
  data = dat, FUN = mean
)
fam_means$n_species <- table(dat$family)[fam_means$family]

cat("Family-level means:\n")
print(fam_means)

# Build tree from APG IV topology
# Approximate relationships for these parasitic plant families:
# ((((Loranthaceae,Santalaceae):70,
#    (Krameriaceae,Zygophyllaceae):85):90,
#   ((Aristolochiaceae,Hydnoraceae):100,
#    (Boraginaceae,Lennoaceae):80)):110,
#   ((Euphorbiaceae,Rafflesiaceae):95,
#    (Saxifragaceae,Cynomoriaceae):100)):120;

families_in_data <- sort(unique(dat$family))
n_fam <- length(families_in_data)

# Use a simpler star tree with family divergence times if complex topology fails
# Or construct Newick manually
newick_str <- paste0(
  "(((",
  "(Loranthaceae:70,Santalaceae:70):20,",
  "(Krameriaceae:85,Zygophyllaceae:85):5):10,",
  "(",
  "(Aristolochiaceae:100,Hydnoraceae:100):5,",
  "(Boraginaceae:80,Lennoaceae:80):25):5):10,",
  "(",
  "(Euphorbiaceae:95,Rafflesiaceae:95):15,",
  "(Saxifragaceae:100,Cynomoriaceae:100):10):5):0;")

fam_tree <- tryCatch(
  read.tree(text = newick_str),
  error = function(e) {
    cat("Warning: Complex tree failed, using star tree\n")
    # Fallback: star tree with branch length 100
    stree(n_fam, tip.label = families_in_data)
  }
)

# Filter to families actually in our data
fam_tree <- drop.tip(fam_tree, fam_tree$tip.label[!fam_tree$tip.label %in% fam_means$family])
fam_means <- fam_means[fam_means$family %in% fam_tree$tip.label, ]

cat(sprintf("\nFamilies in PGLS: %d\n", nrow(fam_means)))
cat(sprintf("Tree tips: %d\n", Ntip(fam_tree)))

# --- PGLS ---
rownames(fam_means) <- fam_means$family
fam_means$tip_label <- fam_means$family

comp_fam <- tryCatch(
  comparative.data(
    phy = fam_tree,
    data = fam_means,
    names.col = tip_label,
    vcv = TRUE, na.omit = FALSE, warn.dropped = TRUE
  ),
  error = function(e) {
    cat(sprintf("Error creating comparative data: %s\n", e$message))
    NULL
  }
)

if (!is.null(comp_fam)) {
  cat("\n--- Model 1: Family-level PGLS (ML lambda) ---\n")
  mod_fam <- tryCatch(
    pgls(plastome_bp ~ parasitism_score,
         data = comp_fam, lambda = "ML"),
    error = function(e) {
      cat(sprintf("ML lambda failed: %s. Trying fixed lambda=1.\n", e$message))
      pgls(plastome_bp ~ parasitism_score,
           data = comp_fam, lambda = 1)
    }
  )
  s_fam <- summary(mod_fam)
  print(s_fam)

  cat(sprintf("\nLambda: %.4f\n", mod_fam$param["lambda"]))
  cat(sprintf("R² (adjusted): %.4f\n", s_fam$adj.r.squared))
  cat(sprintf("Slope: %.0f bp per parasitism unit\n", coef(mod_fam)[2]))

  # --- OLS comparison ---
  cat("\n--- Model 2: OLS (non-phylogenetic) ---\n")
  mod_ols <- lm(plastome_bp ~ parasitism_score, data = fam_means)
  s_ols <- summary(mod_ols)
  print(s_ols)

  # --- Correlation ---
  cat("\n--- Spearman rank correlation ---\n")
  sp_cor <- cor.test(fam_means$parasitism_score, fam_means$plastome_bp,
                     method = "spearman")
  print(sp_cor)
}

# --- Also: species-level OLS with family as random effect (mixed model) ---
cat("\n--- Mixed model: species-level with family random effect ---\n")
if (requireNamespace("nlme", quietly = TRUE)) {
  library(nlme)
  mod_mixed <- lme(plastome_bp ~ parasitism_score,
                   random = ~1|family,
                   data = dat)
  s_mixed <- summary(mod_mixed)
  print(s_mixed)
  cat(sprintf("\nFixed effect (parasitism): %.0f (SE %.0f), p = %.4f\n",
              s_mixed$tTable[2, 1],
              s_mixed$tTable[2, 2],
              s_mixed$tTable[2, 5]))
}

# --- Save plot ---
dir.create("output", showWarnings = FALSE)
pdf("output/02_cross_family_pgls.pdf", width = 12, height = 6)
par(mfrow = c(1, 2))

# Plot 1: Family means
cols <- c("0" = "forestgreen", "1" = "gold3", "2" = "orange",
          "3" = "red3", "4" = "darkred")
plot(fam_means$parasitism_score, fam_means$plastome_bp / 1000,
     pch = 19, cex = 2,
     col = cols[as.character(round(fam_means$parasitism_score))],
     xlab = "Mean Parasitism Score", ylab = "Mean Plastome Size (kb)",
     main = "T2: Cross-Family PGLS",
     cex.lab = 1.2, cex.axis = 1.1)
text(fam_means$parasitism_score, fam_means$plastome_bp / 1000,
     labels = fam_means$family,
     pos = 3, cex = 0.7, offset = 0.5)
if (!is.null(comp_fam)) {
  abline(coef(mod_fam)[1] / 1000, coef(mod_fam)[2] / 1000,
         col = "red", lwd = 2)
}

# Plot 2: Species-level scatter colored by family
fam_cols <- rainbow(length(unique(dat$family)))
names(fam_cols) <- sort(unique(dat$family))
plot(dat$parasitism_score, dat$plastome_bp / 1000,
     pch = 19, cex = 0.8,
     col = adjustcolor(fam_cols[dat$family], alpha.f = 0.6),
     xlab = "Parasitism Score", ylab = "Plastome Size (kb)",
     main = "Species-Level Data by Family",
     cex.lab = 1.2, cex.axis = 1.1)
legend("topright", legend = names(fam_cols), col = fam_cols,
       pch = 19, cex = 0.6, ncol = 2)

dev.off()
cat("\nPlot saved: output/02_cross_family_pgls.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Families analyzed: %d\n", nrow(fam_means)))
cat(sprintf("Species total: %d\n", nrow(dat)))
if (!is.null(comp_fam)) {
  cat(sprintf("Direction: %s (slope = %.0f bp per unit)\n",
              ifelse(coef(mod_fam)[2] < 0, "NEGATIVE (as predicted)", "POSITIVE"),
              coef(mod_fam)[2]))
  cat(sprintf("Significance: p = %.4f\n", s_fam$coefficients[2, 4]))
  cat(sprintf("R² (adjusted): %.3f\n", s_fam$adj.r.squared))
}
cat("NOTE: Small N (families) limits statistical power.\n")
cat("=============================\n")
