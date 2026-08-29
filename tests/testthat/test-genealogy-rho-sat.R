#' Test: ρ_sat from Wright-Fisher Drift-Selection Simulation
#'
#' Verifies that the Wright-Fisher simulation produces ρ_sat values
#' consistent with known population genetics theory.
#'
#' Key finding: ρ_sat is NOT a constant ~0.35. It depends strongly on
#' population size N and the range of selection coefficients tested.
#' The classical drift-selection boundary is at δ ≈ 1/(2N).
#'
#' This test captures the actual observed values so any future changes
#' to the simulation that alter these values are detected.

library(testthat)

# Source generator (path resolved by helper-genealogy.R via source_genealogy)
source_genealogy("generate_drift_selection.R")

test_that("ρ_sat varies with N and delta_range as expected", {
  skip_on_cran()

  # Test parameters: a subset of the full grid
  test_cases <- list(
    list(N = 100L,  delta_range = c(0, 0.01), n_reps = 5000L,
         rho_lower = 0.05, rho_upper = 0.20,
         label = "N=100, δ∈[0,0.01]: drift-dominated, small ρ_sat"),
    list(N = 100L,  delta_range = c(0, 0.05), n_reps = 5000L,
         rho_lower = 0.60, rho_upper = 0.90,
         label = "N=100, δ∈[0,0.05]: mixed regime, moderate ρ_sat"),
    list(N = 100L,  delta_range = c(0, 0.1),  n_reps = 5000L,
         rho_lower = 0.85, rho_upper = 0.99,
         label = "N=100, δ∈[0,0.1]: selection-dominated, high ρ_sat"),
    list(N = 500L,  delta_range = c(0, 0.01), n_reps = 5000L,
         rho_lower = 0.00, rho_upper = 0.02,
         label = "N=500, δ∈[0,0.01]: drift-dominated, near-zero ρ_sat"),
    list(N = 500L,  delta_range = c(0, 0.05), n_reps = 5000L,
         rho_lower = 0.35, rho_upper = 0.65,
         label = "N=500, δ∈[0,0.05]: intermediate ρ_sat"),
    list(N = 500L,  delta_range = c(0, 0.1),  n_reps = 5000L,
         rho_lower = 0.95, rho_upper = 1.00,
         label = "N=500, δ∈[0,0.1]: near-fixation ρ_sat"),
    list(N = 1000L, delta_range = c(0, 0.01), n_reps = 5000L,
         rho_lower = 0.00, rho_upper = 0.01,
         label = "N=1000, δ∈[0,0.01]: drift-dominated, ρ_sat ≈ 0"),
    list(N = 1000L, delta_range = c(0, 0.05), n_reps = 5000L,
         rho_lower = 0.15, rho_upper = 0.35,
         label = "N=1000, δ∈[0,0.05]: weak-moderate ρ_sat"),
    list(N = 1000L, delta_range = c(0, 0.1),  n_reps = 5000L,
         rho_lower = 0.93, rho_upper = 1.00,
         label = "N=1000, δ∈[0,0.1]: selection-dominated, high ρ_sat")
  )

  for (tc in test_cases) {
    out <- generate_drift_selection(
      seed = 42L, N = tc$N, n_reps = tc$n_reps,
      n_delta = 20L, delta_range = tc$delta_range
    )
    rho <- out$values$rho_sat

    expect_true(
      rho >= tc$rho_lower && rho <= tc$rho_upper,
      label = sprintf(
        "%s: expected ρ_sat in [%.3f, %.3f], got %.4f",
        tc$label, tc$rho_lower, tc$rho_upper, rho
      )
    )
  }
})

test_that("Baseline retention (δ=0) decreases with population size", {
  skip_on_cran()

  Ns <- c(100L, 500L, 1000L)
  base_retentions <- numeric(length(Ns))

  for (i in seq_along(Ns)) {
    N <- Ns[i]
    out <- generate_drift_selection(
      seed = 42L, N = N, n_reps = 5000L,
      n_delta = 3L, delta_range = c(0, 0.01)
    )
    base_retentions[i] <- out$metadata$data$retention_prob[1]
  }

  # Larger N should have lower (or equal) baseline retention
  expect_true(base_retentions[1] >= base_retentions[2],
              label = "Baseline retention should decrease with N (100→500)")
  expect_true(base_retentions[2] >= base_retentions[3],
              label = "Baseline retention should decrease with N (500→1000)")
})

test_that("ρ_sat is not a fixed constant ~0.35", {
  skip_on_cran()

  # This test documents the finding that ρ_sat varies with N and δ_range.
  # The the manuscript's claim of ρ_sat ≈ 0.35 as a universal constant is
  # NOT supported by the Wright-Fisher simulation.

  out_small <- generate_drift_selection(
    seed = 42L, N = 100L, n_reps = 5000L,
    n_delta = 20L, delta_range = c(0, 0.1)
  )
  out_large <- generate_drift_selection(
    seed = 42L, N = 1000L, n_reps = 5000L,
    n_delta = 20L, delta_range = c(0, 0.05)
  )
  out_tiny <- generate_drift_selection(
    seed = 42L, N = 1000L, n_reps = 5000L,
    n_delta = 20L, delta_range = c(0, 0.01)
  )

  # These span a wide range, not clustering near 0.35
  rho_values <- c(out_small$values$rho_sat,
                  out_large$values$rho_sat,
                  out_tiny$values$rho_sat)
  rho_range <- diff(range(rho_values))

  expect_true(rho_range > 0.5,
              label = sprintf(
                "ρ_sat varies widely (range=%.3f), not ~0.35 constant",
                rho_range
              ))
})