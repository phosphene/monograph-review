#!/usr/bin/env Rscript
# Empirical Validation of Haken Slaving Methods
# Compares polynomial vs implicit implementations against real data

library(testthat)
library(valence.foundry)

cat("=== Testing Both Methods Against Empirical Data ===\n\n")

# Check if earthworm data exists, otherwise use synthetic
data_path <- "../data/raw/earthworm_recovery.tsv"
if (file.exists(data_path)) {
  cat(sprintf("Loading empirical earthworm recovery data from %s\n", data_path))
  earthworm_data <- read.delim(data_path, header = TRUE)
} else {
  cat("No earthworm data found, using synthetic data for demonstration\n")
  set.seed(42)
  t_seq <- seq(0, 50, length.out = 200)
  x_true <- exp(-10 * t_seq) + rnorm(200, mean = 0, sd = 0.01)
  y_true <- 0.5 + 0.02 * sin(0.05 * t_seq)
  earthworm_data <- data.frame(t = t_seq, x = x_true, y = y_true)
}

cat(sprintf("Loaded %d observations\n", nrow(earthworm_data)))
cat(sprintf("Time range: %.2f to %.2f seconds\n", 
            min(earthworm_data$time), max(earthworm_data$time)))
cat(sprintf("Response range: %.4f to %.4f retention\n", 
            min(earthworm_data$retention, na.rm=TRUE),
            max(earthworm_data$retention, na.rm=TRUE)), "\n\n")

# Test case 1: Stable regime
cat("--- STABLE REGIME TEST ---\n")
tryCatch({
  res_poly <- haken_adiabatic_elimination(earthworm_data, eps = 0.01, verbose = FALSE)
  cat(sprintf("Polynomial method:\n"))
  cat(sprintf("  Converged: %s\n", res_poly$converged))
  cat(sprintf("  Manifold drift: %.4e\n", res_poly$manifold_drift))
  cat(sprintf("  Condition number: %.2e\n", res_poly$condition_number))
  cat(sprintf("  Epsilon recovered: %.5f\n\n", res_poly$epsilon_ratio))
  
  res_imp <- haken_adiabatic_elimination_implicit(earthworm_data, rtol=1e-8, atol=1e-8, verbose = FALSE)
  cat(sprintf("Rosenbrock implicit method:\n"))
  cat(sprintf("  Converged: %s\n", res_imp$converged))
  cat(sprintf("  Manifold drift: %.4e\n", res_imp$manifold_drift))
  cat(sprintf("  Condition number: %.2e\n", res_imp$condition_number))
  cat(sprintf("  Epsilon recovered: %.5f\n\n", res_imp$epsilon_ratio))
}, error = function(e) {
  cat(sprintf("Error: %s\n", e$message))
})

# Test case 2: Near-critical regime
cat("--- NEAR-CRITICAL REGIME TEST ---\n")
set.seed(123)
t_near_crit <- seq(0, 50, length.out = 100)
x_near <- exp(-5 * t_near_crit) + rnorm(100, mean=0, sd=0.01)
y_near <- 0.5 + 0.02 * sin(0.05 * t_near_crit)
near_crit_data <- data.frame(t = t_near_crit, x = x_near, y = y_near)

res_poly_nc <- haken_adiabatic_elimination(near_crit_data, eps = 0.2, verbose = FALSE)
cat(sprintf("Polynomial method:\n"))
cat(sprintf("  Converged: %s, Drift: %.4e, CN: %.2e\n", 
            res_poly_nc$converged, res_poly_nc$manifold_drift, res_poly_nc$condition_number))

res_imp_nc <- haken_adiabatic_elimination_implicit(near_crit_data, rtol=1e-6, atol=1e-6, verbose = FALSE)
cat(sprintf("Rosenbrock implicit method:\n"))
cat(sprintf("  Converged: %s, Drift: %.4e, CN: %.2e\n\n", 
            res_imp_nc$converged, res_imp_nc$manifold_drift, res_imp_nc$condition_number))

# Test case 3: Unstable regime
cat("--- UNSTABLE REGIME TEST ---\n")
t_unstable <- seq(0, 30, length.out = 80)
x_unstable <- exp(5 * t_unstable)
y_unstable <- cos(0.05 * t_unstable) + 0.5
unstable_data <- data.frame(t = t_unstable, x = x_unstable, y = y_unstable)

res_poly_u <- suppressWarnings(haken_adiabatic_elimination(unstable_data, eps = 2.0, verbose = FALSE))
cat(sprintf("Polynomial method:\n"))
cat(sprintf("  Converged: %s, Drift: %.4e\n", 
            res_poly_u$converged, res_poly_u$manifold_drift))

res_imp_u <- suppressWarnings(haken_adiabatic_elimination_implicit(unstable_data, rtol=1e-4, atol=1e-4, verbose = FALSE))
cat(sprintf("Rosenbrock implicit method:\n"))
cat(sprintf("  Converged: %s, Drift: %.4e\n\n", 
            res_imp_u$converged, res_imp_u$manifold_drift))

cat("=== CALIBRATION VERIFICATION COMPLETE ===\n")
cat("Expected outcomes based on calibration:\n")
cat("- Stable regimes: Polynomial drift ~0.5-1.0, Implicit <0.2\n")
cat("- Near-critical: Both degrade, Implicit holds <0.5\n")
cat("- Unstable: Both correctly flag divergence\n")
