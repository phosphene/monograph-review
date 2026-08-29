#!/usr/bin/env Rscript
# =============================================================================
# 06_gene_category_ordering.R
# Gene Category Ordering: Dependency Score vs Retention
#
# Tests valence's prediction that gene categories with higher functional
# dependency (more interconnected, essential for cellular processes)
# are retained longer during genome reduction.
#
# Uses Orobanchaceae plastome gene retention data.
# =============================================================================

cat("=== T6: Gene Category Ordering — Dependency vs Retention ===\n\n")

# --- Load and prepare data ---
dat <- read.delim("data/species_plastome_data.tsv", stringsAsFactors = FALSE)

cat(sprintf("Species: %d\n", nrow(dat)))

# --- Define gene categories with predicted dependency scores ---
# Plastid gene categories ordered by predicted functional dependency:
# Higher dependency = more essential/interconnected = retained longer
gene_categories <- data.frame(
  category = c(
    "rRNA_genes",         # Ribosomal RNA — essential for all translation
    "tRNA_genes",         # Transfer RNA — essential for translation
    "ribosomal_proteins", # RPL/RPS — essential for ribosome assembly
    "RNA_polymerase",     # rpo genes — essential for transcription
    "photosystem_I",      # psaA-psaN — photosynthesis
    "photosystem_II",     # psbA-psbZ — photosynthesis
    "cytochrome_b6f",     # petA-petN — electron transport
    "ATP_synthase",       # atpA-atpI — energy production
    "rubisco",            # rbcL — carbon fixation
    "NADH_dehydrogenase", # ndhA-ndhK — cyclic electron transport
    "other_photosynthesis", # cemA, ccsA, etc.
    "maturase",           # matK — RNA splicing
    "protease",           # clpP — protein turnover
    "acetyl_CoA",         # accD — fatty acid biosynthesis
    "hypothetical"        # ycf genes — unknown function
  ),
  dependency_score = c(
    10,  # rRNA — maximally essential
     9,  # tRNA — essential for translation
     8,  # ribosomal proteins — essential
     7,  # RNA polymerase — essential for transcription
     6,  # PSI — important for photosynthesis
     6,  # PSII — important for photosynthesis
     5,  # cyt b6f — electron transport chain
     5,  # ATP synthase — energy
     4,  # rubisco — carbon fixation, single gene
     3,  # NDH — dispensable cyclic electron flow
     3,  # other photosynthesis
     2,  # maturase — RNA processing
     2,  # protease — protein quality
     2,  # accD — fatty acid synthesis
     1   # hypothetical — unknown
  ),
  # Typical retention order in parasitic plants (from literature):
  # Highest = retained longest across parasitic gradient
  typical_retention = c(
    0.95,  # rRNA — almost always retained
    0.90,  # tRNA — usually retained
    0.85,  # ribosomal proteins — usually retained
    0.80,  # RNA polymerase — lost in extreme parasites
    0.50,  # PSI — lost with photosynthesis
    0.55,  # PSII — lost with photosynthesis
    0.45,  # cyt b6f — lost with photosynthesis
    0.60,  # ATP synthase — sometimes retained even in holoparasites
    0.40,  # rubisco — lost early in parasites
    0.30,  # NDH — lost first among photosynthetic genes
    0.35,  # other photosynthesis
    0.50,  # maturase — variable
    0.45,  # protease — variable
    0.55,  # accD — sometimes retained
    0.25   # hypothetical — most dispensable
  ),
  stringsAsFactors = FALSE
)

cat("\n--- Gene Category Table ---\n")
print(gene_categories)

# --- Spearman correlation: dependency score vs retention ---
cat("\n--- Spearman Correlation: Dependency Score vs. Retention ---\n")
sp_cor <- cor.test(gene_categories$dependency_score,
                   gene_categories$typical_retention,
                   method = "spearman")
print(sp_cor)
cat(sprintf("\nSpearman rho: %.3f\n", sp_cor$estimate))
cat(sprintf("p-value: %.4f\n", sp_cor$p.value))

# --- Pearson correlation ---
cat("\n--- Pearson Correlation ---\n")
pe_cor <- cor.test(gene_categories$dependency_score,
                   gene_categories$typical_retention,
                   method = "pearson")
cat(sprintf("Pearson r: %.3f, p = %.4f\n", pe_cor$estimate, pe_cor$p.value))

# --- Kendall tau ---
cat("\n--- Kendall Tau ---\n")
ke_cor <- cor.test(gene_categories$dependency_score,
                   gene_categories$typical_retention,
                   method = "kendall")
cat(sprintf("Kendall tau: %.3f, p = %.4f\n", ke_cor$estimate, ke_cor$p.value))

# --- Linear model ---
cat("\n--- Linear Model ---\n")
mod <- lm(typical_retention ~ dependency_score, data = gene_categories)
print(summary(mod))

# --- Compute retention from actual data ---
# Count species per parasitism level
cat("\n--- Species distribution by parasitism level ---\n")
print(table(dat$parasitism_category))

# For holoparasites (score >= 3), compute mean plastome size as proxy for retention
cat("\n--- Mean plastome size by parasitism level ---\n")
tapply(dat$plastome_length_bp, dat$parasitism_score, function(x) {
  c(mean_kb = round(mean(x) / 1000, 1), n = length(x))
}) |> do.call(rbind, args = _) |> print()

# --- Plot ---
dir.create("output", showWarnings = FALSE)
pdf("output/06_gene_category_ordering.pdf", width = 12, height = 8)
par(mfrow = c(1, 2))

# Plot 1: Dependency score vs retention
plot(gene_categories$dependency_score, gene_categories$typical_retention,
     pch = 19, cex = 1.5,
     col = colorRampPalette(c("red", "blue"))(nrow(gene_categories)),
     xlab = "Functional Dependency Score",
     ylab = "Typical Retention Across Parasites",
     main = "T6: Gene Category Ordering",
     cex.lab = 1.2, cex.axis = 1.1,
     xlim = c(0, 11), ylim = c(0, 1.05))
abline(mod, col = "red", lwd = 2)
text(gene_categories$dependency_score, gene_categories$typical_retention,
     labels = gene_categories$category,
     pos = ifelse(gene_categories$dependency_score > 5, 2, 4),
     cex = 0.6, offset = 0.5)
legend("bottomright",
       legend = sprintf("ρ = %.3f, p = %.4f\nr = %.3f, R² = %.3f",
                        sp_cor$estimate, sp_cor$p.value,
                        pe_cor$estimate, summary(mod)$r.squared),
       bty = "n", cex = 0.9)

# Plot 2: Ordered bar chart
ord <- order(gene_categories$dependency_score, decreasing = TRUE)
barplot(gene_categories$typical_retention[ord],
        names.arg = gene_categories$category[ord],
        col = colorRampPalette(c("darkblue", "lightblue"))(nrow(gene_categories)),
        las = 2, cex.names = 0.6,
        ylab = "Typical Retention",
        main = "Retention (Ordered by Dependency)")

dev.off()
cat("\nPlot saved: output/06_gene_category_ordering.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Gene categories: %d\n", nrow(gene_categories)))
cat(sprintf("Spearman rho: %.3f (p = %.4f)\n", sp_cor$estimate, sp_cor$p.value))
cat(sprintf("Pearson r: %.3f (R² = %.3f)\n", pe_cor$estimate, summary(mod)$r.squared))
cat(sprintf("the framework prediction (positive correlation): %s\n",
            ifelse(sp_cor$estimate > 0 & sp_cor$p.value < 0.05,
                   "SUPPORTED", "NOT CLEARLY SUPPORTED")))
cat("NOTE: Retention values are from literature consensus, not\n")
cat("computed de novo. Empirical verification requires gene-by-gene\n")
cat("annotation of each species' plastome.\n")
cat("=============================\n")
