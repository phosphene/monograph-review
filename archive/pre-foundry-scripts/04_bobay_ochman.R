#!/usr/bin/env Rscript
# =============================================================================
# 04_bobay_ochman.R
# Bobay & Ochman (2018): Ne, Lifestyle, and Pan-Genome Evolution
#
# Re-analyzes Bobay & Ochman's data on effective population size (Ne),
# ecological lifestyle, and pan-genome size in 153 prokaryotic species.
# Tests valence prediction: Ne (as proxy for drift barrier) should correlate
# with pan-genome size — larger Ne → more efficient selection → smaller
# pan-genomes (fewer weakly deleterious accessory genes retained).
#
# Data: Table S1 from BMC Evol Biol 18:153 (10.1186/s12862-018-1272-4)
# =============================================================================

library(readxl)

cat("=== T4: Bobay & Ochman — Ne, Lifestyle, Pan-Genome ===\n\n")

# --- Load data ---
# The XLSX from BMC supplementary has headers in rows 1-2
dat <- tryCatch({
  d <- read_excel("data/bobay_ochman_table_s1.xlsx", skip = 1)
  # Standardize column names
  names(d) <- make.names(names(d))
  d
}, error = function(e) {
  cat(sprintf("Error reading XLSX: %s\n", e$message))
  cat("Attempting with col_names specified...\n")
  read_excel("data/bobay_ochman_table_s1.xlsx",
             col_names = c("Species", "Strains", "Genome_Size_Mb", "Lifestyle",
                           "GC_pct", "hm_univ", "rm_univ", "dnds_01_03_univ",
                           "dnds_all_univ", "Ne_univ",
                           "hm_core", "rm_core", "dnds_01_03_core",
                           "dnds_all_core", "Ne_core", "Pan_genome_adj"),
             skip = 2)
})

cat(sprintf("Rows loaded: %d\n", nrow(dat)))
cat(sprintf("Columns: %s\n", paste(names(dat), collapse = ", ")))

# --- Data cleaning ---
# Identify the key columns (may vary with Excel formatting)
# We need: Species, Lifestyle, Ne (universal genes), Pan-genome (adjusted)
# Try to identify columns by position if names are messy
if (ncol(dat) >= 16) {
  col_species <- 1
  col_strains <- 2
  col_genome_size <- 3
  col_lifestyle <- 4
  col_gc <- 5
  col_ne_univ <- 10
  col_ne_core <- 15
  col_pan <- 16

  df <- data.frame(
    species = as.character(dat[[col_species]]),
    strains = as.numeric(dat[[col_strains]]),
    genome_size_mb = as.numeric(dat[[col_genome_size]]),
    lifestyle = as.character(dat[[col_lifestyle]]),
    gc_pct = as.numeric(dat[[col_gc]]),
    ne_universal = as.numeric(dat[[col_ne_univ]]),
    ne_core = as.numeric(dat[[col_ne_core]]),
    pan_genome = as.numeric(dat[[col_pan]]),
    stringsAsFactors = FALSE
  )
} else {
  cat("Warning: unexpected column count. Printing first rows:\n")
  print(head(dat))
  df <- data.frame()
}

# Remove NAs
df <- df[complete.cases(df[, c("ne_universal", "pan_genome", "lifestyle")]), ]
cat(sprintf("Complete cases: %d\n", nrow(df)))
cat(sprintf("Lifestyles: %s\n", paste(sort(unique(df$lifestyle)), collapse = ", ")))

# Log-transform Ne and pan-genome
df$log_ne <- log10(df$ne_universal)
df$log_pan <- log10(df$pan_genome)
df$log_genome <- log10(df$genome_size_mb)

# --- Analysis 1: Ne vs Pan-genome size ---
cat("\n--- Analysis 1: Ne vs. Pan-genome Size ---\n")
mod_ne_pan <- lm(log_pan ~ log_ne, data = df)
s1 <- summary(mod_ne_pan)
print(s1)
cat(sprintf("R² = %.3f, p = %.2e\n", s1$r.squared, s1$coefficients[2, 4]))

# --- Analysis 2: Lifestyle vs Ne ---
cat("\n--- Analysis 2: Lifestyle vs. Ne ---\n")
aov_lifestyle_ne <- aov(log_ne ~ lifestyle, data = df)
print(summary(aov_lifestyle_ne))

cat("\nLifestyle Ne means:\n")
tapply(df$log_ne, df$lifestyle, function(x) {
  c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE), n = length(x))
}) |> do.call(rbind, args = _) |> print()

# --- Analysis 3: Lifestyle vs Pan-genome ---
cat("\n--- Analysis 3: Lifestyle vs. Pan-genome Size ---\n")
aov_lifestyle_pan <- aov(log_pan ~ lifestyle, data = df)
print(summary(aov_lifestyle_pan))

# --- Analysis 4: Multiple regression ---
cat("\n--- Analysis 4: Multiple Regression (Pan-genome ~ Ne + Genome Size + Lifestyle) ---\n")
mod_multi <- lm(log_pan ~ log_ne + log_genome + lifestyle, data = df)
print(summary(mod_multi))

# --- Analysis 5: Spearman correlations ---
cat("\n--- Analysis 5: Spearman Correlations ---\n")
sp_ne_pan <- cor.test(df$ne_universal, df$pan_genome, method = "spearman")
cat(sprintf("Ne vs. Pan-genome: rho = %.3f, p = %.2e\n",
            sp_ne_pan$estimate, sp_ne_pan$p.value))

sp_genome_pan <- cor.test(df$genome_size_mb, df$pan_genome, method = "spearman")
cat(sprintf("Genome Size vs. Pan-genome: rho = %.3f, p = %.2e\n",
            sp_genome_pan$estimate, sp_genome_pan$p.value))

# --- Plot ---
dir.create("output", showWarnings = FALSE)
pdf("output/04_bobay_ochman.pdf", width = 14, height = 10)
par(mfrow = c(2, 3))

# Color by lifestyle
lifestyle_cols <- c(
  "free_living" = "forestgreen",
  "obligate" = "red",
  "facultative" = "orange",
  "commensal" = "blue"
)
# Map colors (handle unknown lifestyles)
df$col <- ifelse(df$lifestyle %in% names(lifestyle_cols),
                 lifestyle_cols[df$lifestyle], "gray50")

# Plot 1: Ne vs pan-genome
plot(df$log_ne, df$log_pan,
     pch = 19, col = adjustcolor(df$col, 0.6), cex = 1.2,
     xlab = expression(log[10](N[e])),
     ylab = expression(log[10](Pan-genome~size)),
     main = "Ne vs. Pan-Genome Size")
abline(mod_ne_pan, col = "red", lwd = 2)
legend("topleft",
       legend = sprintf("R²=%.3f, p=%.2e", s1$r.squared, s1$coefficients[2, 4]),
       bty = "n")

# Plot 2: Lifestyle boxplot (Ne)
boxplot(log_ne ~ lifestyle, data = df, col = "lightblue",
        xlab = "Lifestyle", ylab = expression(log[10](N[e])),
        main = "Ne by Lifestyle", las = 2)

# Plot 3: Lifestyle boxplot (pan-genome)
boxplot(log_pan ~ lifestyle, data = df, col = "lightyellow",
        xlab = "Lifestyle", ylab = expression(log[10](Pan-genome)),
        main = "Pan-Genome by Lifestyle", las = 2)

# Plot 4: Genome size vs pan-genome
plot(df$log_genome, df$log_pan,
     pch = 19, col = adjustcolor(df$col, 0.6), cex = 1.2,
     xlab = expression(log[10](Genome~Size~Mb)),
     ylab = expression(log[10](Pan-genome~size)),
     main = "Genome Size vs. Pan-Genome")
abline(lm(log_pan ~ log_genome, data = df), col = "blue", lwd = 2)

# Plot 5: Ne vs Genome Size
plot(df$log_ne, df$log_genome,
     pch = 19, col = adjustcolor(df$col, 0.6), cex = 1.2,
     xlab = expression(log[10](N[e])),
     ylab = expression(log[10](Genome~Size~Mb)),
     main = "Ne vs. Genome Size")
abline(lm(log_genome ~ log_ne, data = df), col = "purple", lwd = 2)

# Legend
plot.new()
legend("center",
       legend = names(lifestyle_cols),
       col = lifestyle_cols, pch = 19, cex = 1.2,
       title = "Lifestyle")

dev.off()
cat("\nPlot saved: output/04_bobay_ochman.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Species analyzed: %d\n", nrow(df)))
cat(sprintf("Ne → Pan-genome: R² = %.3f, p = %.2e\n",
            s1$r.squared, s1$coefficients[2, 4]))
cat(sprintf("Direction: %s (log-log slope = %.3f)\n",
            ifelse(coef(mod_ne_pan)[2] > 0, "POSITIVE (larger Ne → larger pan)", 
                   "NEGATIVE (larger Ne → smaller pan)"),
            coef(mod_ne_pan)[2]))
cat("valence prediction: drift barrier (Ne) shapes pan-genome architecture\n")
cat("=============================\n")
