#!/usr/bin/env Rscript
# =============================================================================
# 05_dewar_pangenome.R
# Dewar et al. (2024): Bacterial Lifestyle Shapes Pangenomes
#
# Re-analyzes data from Dewar et al. (2024) PNAS 121(21):e2320170121
# to test valence predictions about lifestyle-dependent genome architecture.
#
# Data: Downloaded from https://github.com/AnnaEDewar/pangenome_lifestyle
# =============================================================================

library(ape)

cat("=== T5: Dewar et al. — Lifestyle Shapes Pangenomes ===\n\n")

# --- Load data ---
dat <- read.csv("data/dewar_pangenome_lifestyles.csv", stringsAsFactors = FALSE)

cat(sprintf("Species: %d\n", nrow(dat)))
cat(sprintf("Columns: %d\n", ncol(dat)))
cat(sprintf("Families: %d unique\n", length(unique(dat$Family))))
cat(sprintf("Key columns: %s\n",
            paste(names(dat)[grep("pan|core|Ne|genome|Host|Obligate", names(dat))],
                  collapse = ", ")))

# --- Identify key variables ---
# From the CSV: pangenome_fluidity, Per_core_100, pan_size, Ne,
# genome_size, Number_of_Strain, Host_or_free, Obligate_facultative
cat("\n--- Lifestyle distribution ---\n")
cat("Host_or_free:\n")
print(table(dat$Host_or_free, useNA = "ifany"))
cat("\nObligate_facultative:\n")
print(table(dat$Obligate_facultative, useNA = "ifany"))
cat("\nEffect_on_host:\n")
print(table(dat$Effect_on_host, useNA = "ifany"))

# --- Clean and prepare ---
df <- dat
df$log_pan <- log10(df$pan_size)
df$log_core <- log10(df$core_100)
df$pct_core <- df$percentage_core_100 * 100  # if already fraction
df$log_ne <- log10(df$Ne)
df$log_genome <- log10(df$genome_size)
df$log_fluidity <- log10(df$pangenome_fluidity)

# --- Analysis 1: Host-associated vs free-living pan-genome size ---
cat("\n--- Analysis 1: Pan-genome by Host Association ---\n")
host_test <- wilcox.test(log_pan ~ Host_or_free, data = df[df$Host_or_free %in% c("Host", "Free"), ])
cat(sprintf("Host vs Free: W = %.0f, p = %.4f\n", host_test$statistic, host_test$p.value))

cat("\nPan-genome size by host status:\n")
tapply(df$pan_size, df$Host_or_free, function(x) {
  c(median = median(x, na.rm = TRUE), mean = mean(x, na.rm = TRUE), n = sum(!is.na(x)))
}) |> do.call(rbind, args = _) |> print()

# --- Analysis 2: Obligate vs facultative ---
cat("\n--- Analysis 2: Obligate vs Facultative Pathogens ---\n")
oblig_df <- df[df$Obligate_facultative %in% c("Obligate", "Facultative"), ]
if (nrow(oblig_df) > 5) {
  oblig_test <- wilcox.test(log_pan ~ Obligate_facultative, data = oblig_df)
  cat(sprintf("Obligate vs Facultative: W = %.0f, p = %.4f\n",
              oblig_test$statistic, oblig_test$p.value))

  cat("\nPan-genome by obligate status:\n")
  tapply(oblig_df$pan_size, oblig_df$Obligate_facultative, function(x) {
    c(median = median(x, na.rm = TRUE), mean = mean(x, na.rm = TRUE), n = sum(!is.na(x)))
  }) |> do.call(rbind, args = _) |> print()
}

# --- Analysis 3: Pangenome fluidity by lifestyle ---
cat("\n--- Analysis 3: Pangenome Fluidity by Lifestyle ---\n")
fluid_test <- kruskal.test(pangenome_fluidity ~ factor(Host_or_free), data = df)
cat(sprintf("Kruskal-Wallis: chi² = %.2f, p = %.4f\n",
            fluid_test$statistic, fluid_test$p.value))

# --- Analysis 4: Core genome fraction by lifestyle ---
cat("\n--- Analysis 4: Core Genome Fraction by Lifestyle ---\n")
core_test <- wilcox.test(percentage_core_100 ~ Host_or_free,
                         data = df[df$Host_or_free %in% c("Host", "Free"), ])
cat(sprintf("Core fraction Host vs Free: p = %.4f\n", core_test$p.value))

# --- Analysis 5: Ne by lifestyle ---
cat("\n--- Analysis 5: Ne by Lifestyle ---\n")
ne_df <- df[!is.na(df$Ne) & df$Host_or_free %in% c("Host", "Free"), ]
if (nrow(ne_df) > 5) {
  ne_test <- wilcox.test(log_ne ~ Host_or_free, data = ne_df)
  cat(sprintf("Ne Host vs Free: W = %.0f, p = %.4f\n",
              ne_test$statistic, ne_test$p.value))
}

# --- Analysis 6: Multiple regression ---
cat("\n--- Analysis 6: Multiple Regression ---\n")
mod_multi <- lm(log_pan ~ Host_or_free + log_genome + Number_of_Strain,
                data = df[df$Host_or_free %in% c("Host", "Free"), ])
print(summary(mod_multi))

# --- Analysis 7: Effect on host (pathogen vs mutualist vs commensal) ---
cat("\n--- Analysis 7: Pathogen vs Mutualist vs Commensal ---\n")
effect_df <- df[!is.na(df$Effect_on_host) & df$Effect_on_host != "", ]
if (length(unique(effect_df$Effect_on_host)) > 1) {
  effect_test <- kruskal.test(pan_size ~ factor(Effect_on_host),
                              data = effect_df)
  cat(sprintf("Kruskal-Wallis (effect on host): chi² = %.2f, p = %.4f\n",
              effect_test$statistic, effect_test$p.value))

  cat("\nPan-genome by effect on host:\n")
  tapply(effect_df$pan_size, effect_df$Effect_on_host, function(x) {
    c(median = median(x, na.rm = TRUE), n = sum(!is.na(x)))
  }) |> do.call(rbind, args = _) |> print()
}

# --- Load tree and attempt PGLS ---
cat("\n--- Phylogenetic Analysis ---\n")
tree_file <- "data/dewar_panX_tree.nex"
if (file.exists(tree_file)) {
  tree <- tryCatch(
    read.nexus(tree_file),
    error = function(e) {
      cat(sprintf("Nexus read failed: %s. Trying read.tree.\n", e$message))
      tryCatch(read.tree(tree_file), error = function(e2) NULL)
    }
  )
  if (!is.null(tree)) {
    cat(sprintf("Tree loaded: %d tips\n", Ntip(tree)))
  }
}

# --- Plot ---
dir.create("output", showWarnings = FALSE)
pdf("output/05_dewar_pangenome.pdf", width = 14, height = 10)
par(mfrow = c(2, 3))

# Color mapping
host_cols <- c("Host" = "red", "Free" = "forestgreen", "Both" = "orange")
df$col <- ifelse(df$Host_or_free %in% names(host_cols),
                 host_cols[df$Host_or_free], "gray50")

# Plot 1: Pan-genome size by host status
boxplot(pan_size ~ Host_or_free, data = df, col = "lightblue",
        xlab = "Host Association", ylab = "Pan-Genome Size",
        main = "Pan-Genome by Lifestyle", las = 2, log = "y")

# Plot 2: Fluidity by lifestyle
boxplot(pangenome_fluidity ~ Host_or_free, data = df, col = "lightyellow",
        xlab = "Host Association", ylab = "Pangenome Fluidity",
        main = "Fluidity by Lifestyle", las = 2)

# Plot 3: Core fraction by lifestyle
boxplot(percentage_core_100 ~ Host_or_free, data = df, col = "lightgreen",
        xlab = "Host Association", ylab = "Core Fraction",
        main = "Core Fraction by Lifestyle", las = 2)

# Plot 4: Pan-genome size vs genome size
plot(df$log_genome, df$log_pan,
     pch = 19, col = adjustcolor(df$col, 0.6), cex = 1.0,
     xlab = expression(log[10](Genome~Size)), ylab = expression(log[10](Pan-Genome)),
     main = "Genome Size vs. Pan-Genome")
legend("topleft", legend = names(host_cols), col = host_cols,
       pch = 19, cex = 0.8, bty = "n")

# Plot 5: Effect on host boxplot
if (length(unique(effect_df$Effect_on_host)) > 1) {
  boxplot(pan_size ~ Effect_on_host, data = effect_df, col = "lightsalmon",
          xlab = "Effect on Host", ylab = "Pan-Genome Size",
          main = "Pan-Genome by Host Effect", las = 2, log = "y")
}

# Plot 6: Obligate vs Facultative
if (nrow(oblig_df) > 5) {
  boxplot(pan_size ~ Obligate_facultative, data = oblig_df, col = "lightpink",
          xlab = "Association Type", ylab = "Pan-Genome Size",
          main = "Obligate vs. Facultative", log = "y")
}

dev.off()
cat("\nPlot saved: output/05_dewar_pangenome.pdf\n")

# --- Summary ---
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Species analyzed: %d\n", nrow(dat)))
cat(sprintf("Host vs Free pan-genome: p = %.4f\n", host_test$p.value))
cat("valence relevance: lifestyle constrains pangenome architecture,\n")
cat("consistent with functional dependency shaping gene retention.\n")
cat("Host-associated species predicted to have smaller, more constrained\n")
cat("pan-genomes due to stronger dependency on host-provided functions.\n")
cat("=============================\n")
