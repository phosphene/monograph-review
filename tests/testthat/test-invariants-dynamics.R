# test-invariants-dynamics.R — Property-based / invariant tests for the
# dynamics module (autocatalytic sets, cusp catastrophe, economics).
#
# DFT axioms: A1 (pure math, no I/O), A2 (determinism via seeded RNG),
# A6 (structured proof / result objects). Invariants are held across
# ~100 random parameter draws per family.
#
# NOTE (testthat 3.3.2): use expect_true() with info= rather than
# expect_lt()/expect_gt() (which do not accept info), and never pass
# info= to test_that().

library(testthat)

context("Dynamics Module Invariants")

# ==============================================================================
# CUSP CATASTROPHE INVARIANTS
# ==============================================================================

test_that("Invariant: a>0 cusp never bifurcates and loop area = 0", {
  withr::with_seed(42, {
    for (i in seq_len(100)) {
      a <- runif(1, 1e-3, 5)
      b <- runif(1, -5, 5)

      proof <- prove_cusp_bifurcation(a, b)
      expect_true(isTRUE(proof$verified),
        info = sprintf("iter %d: a=%.4f b=%.4f expected 1 real root", i, a, b))
      expect_true(proof$numeric_check == 1L,
        info = sprintf("iter %d: a>0 gave %d roots", i, proof$numeric_check))

      area <- prove_hysteresis_loop_area(a, c(-2, 2), n = 100)$numeric_check
      expect_true(isTRUE(area == 0),
        info = sprintf("iter %d: a>0 loop area=%.5f (expect 0)", i, area))

      eq <- make_cusp_equilibrium_fn(a = a)
      cv <- seq(-2, 2, length.out = 80)
      hres <- cusp_hysteresis_check(cv, eq, seed = 42L)
      expect_true(isFALSE(hres$values$has_hysteresis),
        info = sprintf("iter %d: a>0 must have no hysteresis", i))
      cres <- as_valence_cusp_result(hres)
      expect_true(isFALSE(cres$values$has_hysteresis),
        info = sprintf("iter %d: classed cusp must have has_hysteresis=FALSE", i))
      expect_true(cres$values$loop_area == 0,
        info = sprintf("iter %d: classed cusp loop_area=0 when no hysteresis", i))
    }
  })
})

test_that("Invariant: a<0, |b|<threshold cusp bifurcates with positive loop area", {
  withr::with_seed(43, {
    for (i in seq_len(100)) {
      a <- -runif(1, 0.1, 3)
      bcrit <- (2 / (3 * sqrt(3))) * (-a)^(3 / 2)
      b <- runif(1, -0.9 * bcrit, 0.9 * bcrit)

      proof <- prove_cusp_bifurcation(a, b)
      expect_true(isTRUE(proof$verified),
        info = sprintf("iter %d: a=%.4f b=%.4f expected 3 real roots", i, a, b))
      expect_true(proof$numeric_check == 3L,
        info = sprintf("iter %d: cusp regime gave %d roots", i, proof$numeric_check))

      eq <- make_cusp_equilibrium_fn(a = a)
      bcrit <- (2 / (3 * sqrt(3))) * (-a)^(3 / 2)
      # Sweep must densely cross the bistable band [-b_crit, b_crit]; a wide
      # fixed range misses narrow cusps (small |a|) on a coarse grid.
      cv <- seq(-1.5 * bcrit, 1.5 * bcrit, length.out = 150)
      hres <- cusp_hysteresis_check(cv, eq, seed = 42L)
      expect_true(hres$values$has_hysteresis,
        info = sprintf("iter %d: a<0 cusp must show hysteresis", i))
      area <- hysteresis_loop_area(cv, eq, seed = 42L)$values$loop_area
      expect_true(isTRUE(area > 0),
        info = sprintf("iter %d: loop area %.5f must be > 0 when hysteresis", i, area))
    }
  })
})

test_that("Invariant: loop area > 0 iff hysteresis exists (class-level)", {
  withr::with_seed(44, {
    for (i in seq_len(100)) {
      a <- -runif(1, 0.2, 2.5)
      eq <- make_cusp_equilibrium_fn(a = a)
      cv <- seq(-2, 2, length.out = 64)
      area <- hysteresis_loop_area(cv, eq, seed = 42L)$values$loop_area
      has_hyst <- isTRUE(area > 0)

      cres <- valence_cusp_result(
        has_hysteresis = has_hyst,
        max_difference = if (has_hyst) area else 0,
        loop_area = area,
        equilibria = seq(-2, 2, length.out = 10),
        bifurcation_set = (2 / (3 * sqrt(3))) * (-a)^(3 / 2)
      )
      expect_true(cres$values$loop_area > 0,
        info = sprintf("iter %d: loop_area>0 when hysteresis", i))
      expect_true(inherits(cres, "valence_cusp_result"),
        info = sprintf("iter %d: cusp result class set", i))
      expect_true(inherits(cres, "valence_dynamics_result"),
        info = sprintf("iter %d: cusp result inherits base class", i))

      df <- summary(cres)
      expect_true(is.data.frame(df) && nrow(df) == 1L,
        info = sprintf("iter %d: summary returns 1-row data.frame", i))
    }
  })
})

# ==============================================================================
# AUTOCATALYTIC SET INVARIANTS
# ==============================================================================

test_that("Invariant: per-capita rate is monotonically increasing for N>0", {
  withr::with_seed(45, {
    for (i in seq_len(100)) {
      r <- runif(1, 0.1, 3)
      K <- runif(1, 1, 30)
      proof <- prove_dd_sign(r, K, N_max = 100, n_grid = 100)
      expect_true(isTRUE(proof$verified),
        info = sprintf("iter %d: r=%.4f K=%.4f monotone increasing", i, r, K))
      expect_true(isTRUE(proof$numeric_check > 0),
        info = sprintf("iter %d: min df/dN=%.6g must be > 0", i, proof$numeric_check))
    }
  })
})

test_that("Invariant: autocatalytic growth is bounded (no blow-up)", {
  withr::with_seed(46, {
    for (i in seq_len(100)) {
      r <- runif(1, 0.1, 3)
      K <- runif(1, 1, 50)
      proof <- prove_autocatalytic_growth_rate(r, K, N_max = 5000, n_grid = 100)
      expect_true(isTRUE(proof$verified),
        info = sprintf("iter %d: r=%.4f K=%.4f bounded growth", i, r, K))
      expect_true(isTRUE(proof$numeric_check <= r),
        info = sprintf("iter %d: rate %.6g must not exceed asymptote %.6g",
                       i, proof$numeric_check, r))
    }
  })
})

test_that("Invariant: DD sign positive for bounded autocatalytic, negative for logistic", {
  NN <- seq(1, 100, length.out = 50)

  # Autocatalytic: per-capita rate rises with diversity -> positive DD.
  pc_auto <- 0.5 + 0.5 * NN / (NN + 10)
  res_auto <- valence_autocatalytic_result(
    diversity_dependence_sign = "positive",
    per_capita_rate = pc_auto,
    n_species = length(NN),
    time_series = cumsum(c(1, pc_auto))
  )
  expect_true(all(diff(res_auto$values$per_capita_rate) > 0),
    info = "autocatalytic per-capita rate must increase with N")
  expect_true(res_auto$values$diversity_dependence_sign == "positive",
    info = "autocatalytic DD sign must be positive")
  expect_true(inherits(res_auto, "valence_autocatalytic_result"),
    info = "autocatalytic result class set")

  # Logistic: per-capita rate falls with diversity -> negative DD.
  pc_log <- 1 - NN / 100
  res_log <- valence_autocatalytic_result(
    diversity_dependence_sign = "negative",
    per_capita_rate = pc_log,
    n_species = length(NN),
    time_series = cumsum(c(1, pc_log))
  )
  expect_true(all(diff(res_log$values$per_capita_rate) < 0),
    info = "logistic per-capita rate must decrease with N")
  expect_true(res_log$values$diversity_dependence_sign == "negative",
    info = "logistic DD sign must be negative")

  # A genuine diversity_dependence_sign run on autocatalytic counts (with an
  # increasing per-capita rate) is positive across random draws.
  for (k in seq_len(10)) {
    withr::with_seed(42 + k, {
      n_t <- 30L
      counts_auto <- numeric(n_t)
      counts_auto[1] <- 1
      p <- seq(0.5, 4, length.out = n_t)   # per-capita rate increasing with N
      for (t in seq_len(n_t - 1L)) {
        counts_auto[t + 1L] <- counts_auto[t] + counts_auto[t] * p[t]
      }
      dd_auto <- diversity_dependence_sign(counts_auto, seed = 42L)
      expect_true(dd_auto$values$diversity_dependence_sign == "positive",
        info = sprintf("auto counts draw %d must yield positive DD sign", k))
    })
  }
})

# ==============================================================================
# ECONOMICS INVARIANTS
# ==============================================================================

test_that("Invariant: stochastic CDI paths stay bounded in [0, 1]", {
  withr::with_seed(47, {
    for (i in seq_len(100)) {
      mu0 <- runif(1, 0.05, 0.9)
      sigma0 <- runif(1, 0.02, 0.3)
      cdi_init <- runif(1, 0, 0.3)
      res <- stochastic_cdi(mu0 = mu0, sigma0 = sigma0, cdi_init = cdi_init,
                            n_steps = 50L)
      path <- res$metadata$path
      expect_true(all(path >= 0 & path <= 1),
        info = sprintf("iter %d: CDI path entries outside [0,1]", i))
    }
  })
})

test_that("Invariant: CDI in [0, 1] and option value decreases with CDI", {
  withr::with_seed(48, {
    for (i in seq_len(100)) {
      cdi <- runif(1, 0.05, 0.95)
      k <- runif(1, 0.5, 3)

      # Option value as commitment rises: exponential decay in CDI.
      cdi_grid <- seq(0, 1, length.out = 30)
      option_value <- exp(-k * cdi_grid)
      expect_true(all(option_value <= 1 & option_value >= 0),
        info = sprintf("iter %d: option value must stay in [0,1]", i))
      expect_true(all(diff(option_value) <= 0),
        info = sprintf("iter %d: option value must be non-increasing in CDI", i))

      econ <- valence_economics_result(
        cdi = cdi_grid,
        option_value = option_value,
        stochastic_paths = matrix(rep(cdi_grid, 3), ncol = 3),
        threshold_disruption = cdi > 0.8
      )
      expect_true(all(econ$values$cdi >= 0 & econ$values$cdi <= 1),
        info = sprintf("iter %d: CDI must be in [0,1]", i))
      expect_true(inherits(econ, "valence_economics_result"),
        info = sprintf("iter %d: economics result class set", i))

      s <- summary(econ)
      expect_true(is.data.frame(s) && nrow(s) == 1L,
        info = sprintf("iter %d: economics summary is 1-row data.frame", i))
    }
  })
})