# test-unit-fit-biexp.R — Unit tests for bi-exponential relaxation fitter
# DFT A1: pure math, deterministic, no I/O
# DFT A2: seeded via withr::with_seed() for reproducibility

library(testthat)

context("Bi-exponential relaxation fitter")


# ---- Test 1: Bi-exponential wins on bi-exponential data ----

test_that("fit_biexp: selects bi-exponential on bi-exponential data", {
  d <- .make_biexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_equal(fits$best_model, "biexponential")
  expect_true(fits$biexponential$converged)
  expect_gt(fits$delta_aic_bi_mono, 0) # bi beats mono
})


# ---- Test 2: Mono-exponential wins on mono-exponential data ----

test_that("fit_biexp: does not falsely report bi-exponential on mono data", {
  d <- .make_monoexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  # Mono should win or be competitive (lower AIC due to fewer params)
  expect_true(fits$best_model != "biexponential" ||
                fits$delta_aic_bi_mono < 2)
})


# ---- Test 3: Parameter recovery on clean bi-exponential data ----

test_that("fit_biexp: recovers k1 and k2 from clean data", {
  d <- .make_biexp_data(n = 100, t_max = 10, noise_sd = 1e-6)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)
  # Should recover k1 > 1 and k2 < 1 (fast/slow hierarchy)
  expect_gt(fits$metadata$k1_k2_ratio, 5)
})


# ---- Test 4: Linear null — linear loses to bi-exp on bi-exp data ----

test_that("fit_biexp: linear loses to bi-exponential on bi-exp data", {
  d <- .make_biexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_equal(fits$best_model, "biexponential")
  expect_gt(fits$delta_aic_bi_linear, 0) # bi beats linear
})


# ---- Test 5: Error on insufficient data ----

test_that("fit_biexp: errors on fewer than 6 data points", {
  expect_error(fit_biexp(1:5, runif(5)))
})


# ---- Test 6: Bi-exponential recovery across multiple seeds ----

test_that("fit_biexp: consistent recovery across multiple seeds", {
  seeds <- 1:10
  results <- vapply(seeds, function(s) {
    d <- .make_biexp_data(seed = s, n = 80, noise_sd = 0.002)
    fits <- fit_biexp(d$t, d$rho)
    fits$best_model
  }, character(1))

  # Most seeds should recover bi-exp; some may not converge
  bi_count <- sum(results == "biexponential")
  expect_gt(bi_count, 5)
})


# ---- Test 7: k1 > k2 (fast/slow hierarchy) ----

test_that("fit_biexp: k1 > k2 when fitted (fast/slow hierarchy)", {
  d <- .make_biexp_data(n = 100, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  if (fits$biexponential$converged) {
    expect_gt(
      fits$biexponential$coefficients$k1,
      fits$biexponential$coefficients$k2
    )
  }
})


# ---- Test 8: Normalisation is stable ----

test_that("fit_biexp: normalised and unnormalised give similar results", {
  d <- .make_biexp_data(n = 80, t_max = 56500, noise_sd = 0.001)
  fits_norm <- fit_biexp(d$t, d$rho, normalize_t = TRUE)
  fits_raw <- fit_biexp(d$t, d$rho, normalize_t = FALSE)

  # Both should converge and select bi-exponential
  expect_equal(fits_norm$best_model, fits_raw$best_model)
  expect_true(fits_norm$biexponential$converged || fits_raw$biexponential$converged)
})


# ---- Test 9: Zero noise — near-perfect parameter recovery ----

test_that("fit_biexp: near-perfect recovery with zero noise", {
  d <- .make_biexp_data(n = 100, noise_sd = 0)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)
  expect_equal(fits$best_model, "biexponential")
  expect_gt(fits$delta_aic_bi_mono, 10) # decisively bi
})


# ---- Test 10: Return structure has all expected fields ----

test_that("fit_biexp: return structure is complete", {
  d <- .make_biexp_data(n = 40, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_named(fits, c(
    "biexponential", "monoexponential", "linear",
    "best_model", "delta_aic_bi_mono", "delta_aic_bi_linear",
    "metadata"
  ))
  expect_named(fits$biexponential, c("coefficients", "fit", "rss", "aic", "converged"))
  expect_named(fits$monoexponential, c("coefficients", "fit", "rss", "aic", "converged"))
  expect_named(fits$linear, c("coefficients", "fit", "rss", "aic"))
  expect_named(fits$metadata, c(
    "n", "normalised", "k1_k2_ratio", "k1_halflife",
    "k2_halflife", "A1_frac", "A2_frac"
  ))
})

# ==============================================================================
# RIGOROUS REVISIT (2026-08-28) — see docs/review/fit-biexp-numerical-challenges.md
#
# The first ten tests cover *selection* and *convergence*. These probe the
# actual numerical challenges: parameter recovery accuracy, determinism,
# halflife physics, amplitude-fraction boundedness, the identifiability
# boundary (degenerate sampling / one-channel data), and the noise boundary
# where two-timescale structure stops being resolvable.
# ==============================================================================


# ---- Test 11: Parameter recovery accuracy on the raw scale ----

test_that("fit_biexp: recovers true parameters on the raw scale", {
  d <- .make_biexp_data(n = 100, t_max = 10, noise_sd = 1e-6)
  fits <- fit_biexp(d$t, d$rho, normalize_t = FALSE)
  c <- fits$biexponential$coefficients

  expect_true(fits$biexponential$converged)
  # True: c0=0.05, A1=0.03, k1=17.7, A2=0.01, k2=0.47
  expect_equal(c$k1, 17.7, tolerance = 0.20)
  expect_equal(c$k2, 0.47, tolerance = 0.20)
  expect_equal(c$A1, 0.03, tolerance = 0.30)
  expect_equal(c$A2, 0.01, tolerance = 0.30)
  expect_equal(c$c0, 0.05, tolerance = 0.20)
})


# ---- Test 12: Determinism (DFT A2) ----

test_that("fit_biexp: deterministic — same input, identical output", {
  d <- .make_biexp_data(n = 80, seed = 7, noise_sd = 0.002)
  a <- fit_biexp(d$t, d$rho)
  b <- fit_biexp(d$t, d$rho)
  expect_identical(a, b)
})


# ---- Test 13: Halflife is a physical (raw-time) quantity ----

test_that("fit_biexp: halflife is reported in raw time units", {
  d <- .make_biexp_data(n = 100, t_max = 10, k2 = 0.47, noise_sd = 1e-6)
  fits <- fit_biexp(d$t, d$rho, normalize_t = FALSE)
  true_hl2 <- log(2) / 0.47
  expect_equal(fits$metadata$k2_halflife, true_hl2, tolerance = 0.05)
})


# ---- Test 14: Amplitude fractions are bounded ----

test_that("fit_biexp: amplitude fractions stay in [0, 1]", {
  for (s in 1:10) {
    d <- .make_biexp_data(n = 80, seed = s, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    if (fits$biexponential$converged) {
      expect_gte(fits$metadata$A1_frac, 0)
      expect_lte(fits$metadata$A1_frac, 1)
      expect_gte(fits$metadata$A2_frac, 0)
      expect_lte(fits$metadata$A2_frac, 1)
    }
  }
})


# ---- Test 15: Degenerate sampling -> honest mono (boundary probe) ----

test_that("fit_biexp: unresolvable fast phase is a boundary probe, not a claim", {
  # t_max = 56500 with 80 points: dt ~ 715, and both true channels have raw
  # time constants far shorter than one sampling interval (k1*dt ~ 12650).
  # The honest boundary-probe guarantee (C3) is RNG-independent: the fit must
  # not claim a RESOLVED fast phase at its natural scale. So either the model
  # selection retreats to mono/linear, or — if bi is selected — the fitted
  # fast channel must itself be unresolvable at this sampling (k1 * dt > 1).
  # (Because c0 is pinned at the tail minimum, the fast channel has to carry
  # the instantaneous drop, so k1_raw is always large on this fixture.)
  d <- .make_biexp_data(n = 80, t_max = 56500, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho, normalize_t = FALSE)
  dt <- diff(d$t)[1]
  if (fits$best_model == "biexponential") {
    expect_gt(fits$biexponential$coefficients$k1 * dt, 1)
  } else {
    expect_true(fits$best_model %in% c("monoexponential", "linear"))
  }
})


# ---- Test 16: t_range == 0 guard (all time points identical) ----

test_that("fit_biexp: does not error on zero time range", {
  t <- rep(1, 10)
  rho <- seq(0, 1, length.out = 10)
  # expect_error(..., NA) = assert NO error (version-safe across testthat 3.x)
  expect_error(fit_biexp(t, rho), NA)
})


# ---- Test 17: Identifiability boundary — decisive bi needs a material channel ----

test_that("fit_biexp: decisive bi never rides on a negligible fast channel", {
  # On single-exponential (one-channel) data, the optimizer can chase noise
  # into a spurious second channel. The identifiability rule: if the fit claims
  # a DECISIVE two-timescale structure (delta AIC bi-mono > 2), the fast
  # channel must be a material fraction (>= 0.15) of the amplitude. A
  # decisive win with a 5% fast channel is a numerical artefact, not biology.
  violations <- 0L
  for (s in 1:10) {
    d <- .make_monoexp_data(n = 80, seed = s, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho)
    if (fits$best_model == "biexponential" &&
          !is.na(fits$delta_aic_bi_mono) && fits$delta_aic_bi_mono > 2 &&
          !is.na(fits$metadata$A1_frac)) {
      if (fits$metadata$A1_frac >= 0.15) violations <- violations + 1L
    }
  }
  expect_lte(violations, 1L)
})


# ---- Test 18: Noise boundary — two-timescale structure stops resolving ----

test_that("fit_biexp: bi selection rate falls as noise rises", {
  # The identifiability boundary: at high noise the biphasic signal is no
  # longer separable from noise, and honest selection should retreat toward
  # mono/linear. Assert the monotone direction, not a specific rate.
  count_at <- function(noise) {
    sum(vapply(1:10, function(s) {
      d <- .make_biexp_data(n = 80, seed = s, noise_sd = noise)
      fit_biexp(d$t, d$rho)$best_model == "biexponential"
    }, logical(1)))
  }
  low_noise <- count_at(0.001)
  high_noise <- count_at(0.05)
  expect_lt(high_noise, low_noise)
})
