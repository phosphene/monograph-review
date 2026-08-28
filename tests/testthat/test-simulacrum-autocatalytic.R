# test-simulacrum-autocatalytic.R — STDD diversity-dependence test
#
# Simulacrum 4: Autocatalytic Set. Synthetic data with KNOWN autocatalytic
# closure properties tests parameter recovery of diversity_dependence_sign()
# and autocatalytic_closure().
#
# @section Theoretical Context:
#
# valence Prediction: positive diversity-dependence (superlinear growth). The
# Autocatalytic model predicts superlinear slope, good fit, positive sign.
# Null control (linear, no feedback) should not be superlinear.
#
# @dft A2 (stochastic-determination): all RNG wrapped in withr::with_seed()
#     with Mersenne-Twister + Inversion
# @dft A6 (check-result): returns structured proof object
#
# @section Canonical Source:
# The generator function generate_autocatalytic_set() is defined in
# inst/simulacra/generate_autocatalytic.R. This test sources it for
# consistency with the simulacrum infrastructure.

library(testthat)

context("Simulacrum: Autocatalytic set")

# Source the simulacrum generator from the package's installed extras
# In development, testthat runs from package root so inst/ is accessible
source_if_available <- function(file) {
  # Try system.file first (installed package), then relative path (dev)
  installed <- system.file("simulacra", basename(file), package = "valence.foundry")
  if (nzchar(installed)) {
    source(installed)
  } else {
    source(file.path("inst", "simulacra", basename(file)))
  }
}

# ---- Test 1: Autocatalytic growth detection (A6 proof object) ----

test_that("autocatalytic simulacrum: diversity_dependence_sign detects superlinear growth", {
  source_if_available("generate_autocatalytic.R")

  # Generate autocatalytic data with known parameters
  # DFT A2: all RNG wrapped in withr::with_seed() with Mersenne-Twister + Inversion
  sim <- withr::with_seed(42,
    {
      generate_autocatalytic_set(
        n_steps = 20,
        innovation_rate = 0.3,
        capacity = 30,
        n_innovations = 10,
        seed = 42
      )
    },
    .rng_kind = "Mersenne-Twister",
    .rng_normal_kind = "Inversion"
  )

  # Run diversity_dependence_sign on the time series
  dd_result <- diversity_dependence_sign(
    sim$values$innovation_counts,
    seed = 42
  )

  # Assert: growth_direction = "positive" (increasing diversity)
  expect_equal(dd_result$values[["growth_direction"]], "positive")

  # Assert: is_superlinear = TRUE (log-log slope > 1, autocatalytic)
  expect_true(dd_result$values[["is_superlinear"]])

  # Assert: GENUINE positive diversity-dependence (per-capita rate increases
  # with N — the Homo inversion signature). The generator is bounded
  # autocatalytic, so this must read positive (unlike logistic growth, which
  # is negatively diversity-dependent).
  expect_equal(dd_result$values[["diversity_dependence_sign"]], "positive")

  # Assert: R^2 > 0.8 (good fit — autocatalytic growth is strongly monotonic)
  expect_gt(dd_result$values[["growth_r_squared"]], 0.8)

  # Run autocatalytic_closure on the catalyst matrix
  ac_result <- autocatalytic_closure(
    sim$values$innovations,
    sim$values$catalyst_matrix
  )

  # Check closure achievement
  expect_true(ac_result$values[["achieves_closure"]])

  # Validate result structure (A6)
  expect_true(validate_result(sim))
  expect_true(validate_result(dd_result))
  expect_true(validate_result(ac_result))

  # A6 proof object: return structured results for verification
  proof <- list(
    values = c(
      test_passed = TRUE,
      sim_achieves_closure = as.numeric(sim$values$achieves_closure),
      dd_growth_direction = as.numeric(dd_result$values[["growth_direction"]] == "positive"),
      dd_superlinear = as.numeric(dd_result$values[["is_superlinear"]]),
      dd_positive_dependence = as.numeric(dd_result$values[["diversity_dependence_sign"]] == "positive"),
      dd_r_squared = dd_result$values[["growth_r_squared"]],
      ac_closure = as.numeric(ac_result$values[["achieves_closure"]]),
      ac_closure_fraction = ac_result$values[["closure_fraction"]]
    ),
    metadata = list(
      test = "test-simulacrum-autocatalytic",
      simulacrum = "autocatalytic_set",
      seed = 42,
      n_steps = 20,
      innovation_rate = 0.3,
      capacity = 30,
      n_innovations = 10,
      rng_kind = "Mersenne-Twister",
      rng_normal_kind = "Inversion",
      converged = TRUE
    )
  )

  expect_true(validate_result(proof))
})

# ---- Test 2: Null control — non-autocatalytic data ----

test_that("null control: non-autocatalytic data gives is_superlinear = FALSE", {
  # Generate NON-autocatalytic data: strictly linear growth (count = k*t).
  # Deterministic so the log-log slope is exactly 1.0 and is_superlinear is
  # deterministically FALSE — a noisy random walk can drift above 1.0 and
  # flake the null control.
  null_data <- 3 * seq_len(20)

  # Run diversity_dependence_sign on null data
  dd_null <- diversity_dependence_sign(null_data, seed = 42)

  # Assert: is_superlinear = FALSE (linear, not autocatalytic)
  # Linear growth has log-log slope ~ 1, not > 1
  expect_false(dd_null$values[["is_superlinear"]])

  # Assert: GENUINE diversity-dependence is NEGATIVE (linear growth has
  # per-capita rate k/N decreasing with N — niche-filling, not the Homo
  # inversion). The null must NOT read positive diversity-dependence.
  expect_equal(dd_null$values[["diversity_dependence_sign"]], "negative")

  # Validate result structure (A6)
  expect_true(validate_result(dd_null))

  # A6 proof object for null control
  null_proof <- list(
    values = c(
      test_passed = TRUE,
      dd_superlinear = as.numeric(dd_null$values[["is_superlinear"]]),
      dd_log_log_slope = dd_null$values[["log_log_slope"]],
      dd_r_squared = dd_null$values[["growth_r_squared"]],
      dd_growth_direction = as.numeric(dd_null$values[["growth_direction"]] == "positive"),
      dd_positive_dependence = as.numeric(dd_null$values[["diversity_dependence_sign"]] == "positive")
    ),
    metadata = list(
      test = "null-control-autocatalytic",
      null_model = "linear_constant_rate",
      seed = 42,
      n_steps = 20,
      rng_kind = "Mersenne-Twister",
      rng_normal_kind = "Inversion",
      converged = TRUE
    )
  )

  expect_true(validate_result(null_proof))
})

# ---- Test 3: generate_autocatalytic_set returns A6-compliant output ----

test_that("autocatalytic simulacrum generator returns A6 proof object", {
  source_if_available("generate_autocatalytic.R")

  sim <- withr::with_seed(42,
    {
      generate_autocatalytic_set(
        n_steps = 20,
        innovation_rate = 0.3,
        capacity = 30,
        seed = 42
      )
    },
    .rng_kind = "Mersenne-Twister",
    .rng_normal_kind = "Inversion"
  )

  # A6: validate_result passes
  expect_true(validate_result(sim))

  # values is a list with required fields
  expect_true(is.list(sim$values))
  expect_true(is.list(sim$metadata))

  # metadata contains seed and n
  expect_equal(sim$metadata$seed, 42)
  expect_equal(sim$metadata$n, 20)
  expect_equal(sim$metadata$model, "autocatalytic_growth")

  # innovation_counts has correct length
  expect_equal(length(sim$values$innovation_counts), 20)

  # Catalyst matrix is 10x10
  expect_equal(dim(sim$values$catalyst_matrix), c(10, 10))

  # Closure is achieved (forced by construction)
  expect_true(sim$values$achieves_closure)
})
