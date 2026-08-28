#' Measure ρ_sat across Wright-Fisher parameter grid
#'
#' Tests whether the valence paper's claim of ρ_sat ≈ 0.35 holds
#' under realistic Wright-Fisher simulation.

source("inst/genealogy/generate_drift_selection.R")

# Parameter grid
Ns <- c(100L, 500L, 1000L)
delta_ranges <- list(c(0, 0.01), c(0, 0.05), c(0, 0.1))
n_reps <- 5000L

results <- list()

cat("=== ρ_sat Measurement Grid ===\n")
cat(sprintf("n_reps = %d, n_delta = 20, generations = 100\n\n", n_reps))

idx <- 1
for (N in Ns) {
  for (dr in delta_ranges) {
    cat(sprintf("Running N=%d, delta_range=[%g, %g]...", N, dr[1], dr[2]))
    flush.console()

    t_start <- Sys.time()
    out <- generate_drift_selection(
      seed = 42L, N = N, n_reps = n_reps,
      n_delta = 20L, delta_range = dr
    )
    t_elapsed <- difftime(Sys.time(), t_start, units = "secs")

    rho <- out$values$rho_sat
    data <- out$metadata$data

    # Also compute per-delta retention
    cat(sprintf(" ρ_sat = %.4f (%.1fs)\n", rho, t_elapsed))

    results[[idx]] <- list(
      N = N, delta_min = dr[1], delta_max = dr[2],
      rho_sat = rho, data = data, elapsed = t_elapsed
    )
    idx <- idx + 1
  }
}

cat("\n=== Summary ===\n\n")
cat(sprintf("%-5s %-12s %-12s %-8s %-10s\n",
            "N", "delta_min", "delta_max", "rho_sat", "time(s)"))
cat(paste(rep("-", 55), collapse = ""), "\n")

for (r in results) {
  cat(sprintf("%-5d %-12g %-12g %-8.4f %-10.1f\n",
              r$N, r$delta_min, r$delta_max,
              r$rho_sat, r$elapsed))
}

# Findings text
cat("\n=== Findings ===\n\n")
claimed_rho <- 0.35
for (r in results) {
  diff_val <- abs(r$rho_sat - claimed_rho)
  if (diff_val < 0.05) {
    verdict <- "MATCHES 0.35 claim"
  } else if (diff_val < 0.10) {
    verdict <- "NEAR 0.35 but imprecise"
  } else {
    verdict <- "DOES NOT MATCH 0.35 claim"
  }
  cat(sprintf("N=%d, delta=[%g,%g]: ρ_sat=%.4f — %s\n",
              r$N, r$delta_min, r$delta_max, r$rho_sat, verdict))
}

# Save results for later test
saveRDS(results, file = "inst/genealogy/rho_sat_measurements.rds")
cat("\nResults saved to inst/genealogy/rho_sat_measurements.rds\n")