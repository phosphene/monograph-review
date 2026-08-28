#' VI ODE growth curve models for cumulative culture
#'
#' Implements the VI coupled system (Equations 1-3 of §9 revised):
#'   dB/dt = ε·β·B·(1 - B/K) - δ_B·B + J(B,t) + I(B,S)
#'   dρ/dt = -k₁(ρ - ρ₁(B)) - k₂(ρ - ρ₂(B))
#'   dS/dt = L_s(ρ)·T·A(B) - μ_s·S
#'
#' For the growth-curve fitting (B only, far from saturation):
#'   dB/dt = r·B·(1 - B/K) - δ·B   [VI ODE: generalized logistic with decay]
#'
#' @section Models fitted:
#'   1. VI ODE (generalized logistic): r·B·(1-B/K) - δ·B
#'   2. Simple exponential: r·B
#'   3. Quadratic (Gabora): γ·B²/2
#'   4. Logistic (standard): r·B·(1-B/K)
#'   5. Double exponential (bi-exponential, VI relaxation form)
#'
#' @dft A1, A2, A6
#'
#' @name valence_ode_models
NULL

#' Analytical solution for VI ODE (generalized logistic with decay)
#'
#' dB/dt = r·B·(1 - B/K) - δ·B = (r-δ)·B - (r/K)·B²
#' This is a logistic with effective growth rate r_eff = r-δ and
#' carrying capacity K_eff = K·(r-δ)/r = K·(1 - δ/r).
#'
#' Solution: B(t) = K_eff / (1 + ((K_eff - B0)/B0)·exp(-r_eff·t))
#'
#' @param t Numeric vector. Time points.
#' @param r Growth rate (ε·β).
#' @param K Carrying capacity.
#' @param delta Decay rate (δ_B).
#' @param B0 Initial B.
#' @return Numeric vector. B(t).
#' @export
valence_ode_solution <- function(t, r, K, delta, B0) {
  r_eff <- r - delta
  if (r_eff <= 0) return(rep(B0, length(t)))
  K_eff <- K * r_eff / r
  ratio <- (K_eff - B0) / B0
  if (ratio <= 0) return(rep(K_eff, length(t)))
  K_eff / (1 + ratio * exp(-r_eff * t))
}

#' Simple exponential solution: B(t) = B0·exp(r·t)
#'
#' @param t Numeric vector.
#' @param B0 Initial value.
#' @param r Growth rate.
#' @export
exp_solution <- function(t, B0, r) {
  B0 * exp(r * t)
}

#' Quadratic (Gabora) solution: B(t) = B0 / (1 - γ·B0·t/2)
#'
#' @param t Numeric vector.
#' @param B0 Initial value.
#' @param gamma Combinatorial rate.
#' @export
quadratic_solution <- function(t, B0, gamma) {
  denom <- 1 - gamma * B0 * t / 2
  if (any(denom <= 0)) return(rep(NA_real_, length(t)))
  B0 / denom
}

#' Standard logistic solution: B(t) = K / (1 + exp(-r·(t-t0)))
#'
#' @param t Numeric vector.
#' @param K Carrying capacity.
#' @param r Growth rate.
#' @param t0 Inflection point.
#' @export
logistic_solution <- function(t, K, r, t0) {
  K / (1 + exp(-r * (t - t0)))
}

#' Double exponential (bi-exponential) solution: A1·exp(-k1·t) + A2·exp(-k2·t) + C
#'
#' This is the VI relaxation form with two timescales.
#'
#' @param t Numeric vector.
#' @param A1 Fast component amplitude.
#' @param k1 Fast decay rate.
#' @param A2 Slow component amplitude.
#' @param k2 Slow decay rate.
#' @param C Asymptote.
#' @export
biexp_solution <- function(t, A1, k1, A2, k2, C) {
  A1 * exp(-k1 * t) + A2 * exp(-k2 * t) + C
}

#' Network topology effective carrying capacity
#'
#' K_eff(C) = K · (1 - η·(1 - C))
#'
#' From Derex & Boyd (2016): partial connectivity preserves β-diversity.
#'
#' @param K Base carrying capacity.
#' @param C Connectivity fraction [0, 1].
#' @param eta Convergence rate (default 0.487 from Derex & Boyd fit).
#' @export
k_eff_topology <- function(K, C, eta = 0.487) {
  K * (1 - eta * (1 - C))
}

#' Mismatch equation: M(t) = ρ_eq(B(t)) - ρ(t)
#'
#' In the exponential cultural regime (β > 1, r_B = ε·β):
#'   M(t) = ρ_eq(B0) · (exp(r_B·t) - exp(k1·t))
#'
#' When r_B > k1: M(t) > 0 and growing (attractor ahead of relaxation)
#' When r_B < k1: M(t) < 0 (relaxation has overshot — not physical, 
#'   means mismatch is negligible, organism tracks environment)
#' When r_B = k1: M(t) = 0 (matched)
#'
#' Use abs(M) for magnitude, or check sign for regime.
#'
#' @param t Numeric vector. Time.
#' @param rho_eq0 Numeric. Initial attractor value.
#' @param r_B Numeric. Cultural acceleration rate (ε·β).
#' @param k1 Numeric. Fast biological relaxation rate.
#' @export
mismatch_equation <- function(t, rho_eq0, r_B, k1) {
  rho_eq0 * (exp(r_B * t) - exp(k1 * t))
}

#' Fit VI ODE and competing models to growth curve data
#'
#' @param t Numeric vector. Time points (0-indexed).
#' @param B Numeric vector. Cumulative counts.
#' @param seed Integer. For reproducibility.
#' @return List (A6: proof object) with values and metadata.
#' @export
fit_valence_ode_models <- function(t, B, seed = 42L) {
  withr::with_seed(seed, {
    results <- list()

    # 1. VI ODE (generalized logistic with decay)
    # Try multiple starting points for robustness
    fit_res <- tryCatch({
      best_fit <- NULL
      best_val <- Inf
      starts <- list(
        c(r = 0.01, K = max(B) * 100, delta = 0.001, B0 = B[1]),
        c(r = 0.1, K = max(B) * 10, delta = 0.001, B0 = B[1]),
        c(r = 0.05, K = max(B) * 50, delta = 0.0001, B0 = B[1])
      )
      for (start in starts) {
        fit <- tryCatch({
          stats::optim(
            par = start,
            fn = function(p) {
              pred <- valence_ode_solution(t, p["r"], p["K"], p["delta"], p["B0"])
              if (any(is.na(pred)) || any(pred <= 0)) return(Inf)
              sum((log(B) - log(pred))^2)
            },
            method = "L-BFGS-B",
            lower = c(1e-10, max(B) * 1.01, 0, 1),
            upper = c(10, 1e15, 1, max(B))
          )
        }, error = function(e) list(par = start, value = Inf))
        if (fit$value < best_val) {
          best_fit <- fit
          best_val <- fit$value
        }
      }
      best_fit
    }, error = function(e) list(par = c(r=NA, K=NA, delta=NA, B0=NA), value = Inf))

    pred_res <- if (!is.infinite(fit_res$value)) {
      valence_ode_solution(t, fit_res$par["r"], fit_res$par["K"],
                      fit_res$par["delta"], fit_res$par["B0"])
    } else rep(NA, length(t))

    rss <- if (!any(is.na(pred_res))) sum((B - pred_res)^2) else NA
    npar <- 4
    aic <- if (!is.na(rss)) {
      n <- length(B)
      n * log(rss / n) + 2 * npar
    } else NA

    # 2. Simple exponential
    exp_fit <- tryCatch({
      stats::optim(
        par = c(B0 = B[1], r = 0.01),
        fn = function(p) {
          pred <- exp_solution(t, p["B0"], p["r"])
          if (any(is.na(pred)) || any(pred <= 0)) return(Inf)
          sum((log(B) - log(pred))^2)
        },
        method = "L-BFGS-B",
        lower = c(1, 1e-10),
        upper = c(max(B), 10)
      )
    }, error = function(e) list(par = rep(NA, 2), value = Inf))

    exp_pred <- if (!is.infinite(exp_fit$value)) {
      exp_solution(t, exp_fit$par["B0"], exp_fit$par["r"])
    } else rep(NA, length(t))

    exp_rss <- if (!any(is.na(exp_pred))) sum((B - exp_pred)^2) else NA
    exp_npar <- 2
    exp_aic <- if (!is.na(exp_rss)) {
      n <- length(B)
      n * log(exp_rss / n) + 2 * exp_npar
    } else NA

    # 3. Quadratic (Gabora)
    quad_fit <- tryCatch({
      stats::optim(
        par = c(B0 = B[1], gamma = 1e-6),
        fn = function(p) {
          pred <- quadratic_solution(t, p["B0"], p["gamma"])
          if (any(is.na(pred)) || any(pred <= 0)) return(Inf)
          sum((log(B) - log(pred))^2)
        },
        method = "L-BFGS-B",
        lower = c(1, 1e-15),
        upper = c(max(B), 1)
      )
    }, error = function(e) list(par = rep(NA, 2), value = Inf))

    quad_pred <- if (!is.infinite(quad_fit$value)) {
      quadratic_solution(t, quad_fit$par["B0"], quad_fit$par["gamma"])
    } else rep(NA, length(t))

    quad_rss <- if (!any(is.na(quad_pred))) sum((B - quad_pred)^2) else NA
    quad_npar <- 2
    quad_aic <- if (!is.na(quad_rss)) {
      n <- length(B)
      n * log(quad_rss / n) + 2 * quad_npar
    } else NA

    # 4. Standard logistic
    log_fit <- tryCatch({
      stats::optim(
        par = c(K = max(B) * 10, r = 0.01, t0 = mean(t)),
        fn = function(p) {
          pred <- logistic_solution(t, p["K"], p["r"], p["t0"])
          if (any(is.na(pred)) || any(pred <= 0)) return(Inf)
          sum((log(B) - log(pred))^2)
        },
        method = "L-BFGS-B",
        lower = c(max(B), 1e-10, 0),
        upper = c(1e15, 10, max(t))
      )
    }, error = function(e) list(par = rep(NA, 3), value = Inf))

    log_pred <- if (!is.infinite(log_fit$value)) {
      logistic_solution(t, log_fit$par["K"], log_fit$par["r"], log_fit$par["t0"])
    } else rep(NA, length(t))

    log_rss <- if (!any(is.na(log_pred))) sum((B - log_pred)^2) else NA
    log_npar <- 3
    log_aic <- if (!is.na(log_rss)) {
      n <- length(B)
      n * log(log_rss / n) + 2 * log_npar
    } else NA

    # 5. Double exponential (bi-exponential, VI relaxation)
    biexp_fit <- tryCatch({
      stats::optim(
        par = c(A1 = max(B)/2, k1 = 0.1, A2 = -max(B), k2 = 0.01, C = max(B)),
        fn = function(p) {
          pred <- biexp_solution(t, p["A1"], p["k1"], p["A2"], p["k2"], p["C"])
          if (any(is.na(pred)) || any(pred <= 0)) return(Inf)
          sum((log(B) - log(pred))^2)
        },
        method = "L-BFGS-B",
        lower = c(-max(B)*10, 1e-10, -max(B)*10, 1e-10, 1),
        upper = c(max(B)*10, 10, max(B)*10, 10, max(B)*100)
      )
    }, error = function(e) list(par = rep(NA, 5), value = Inf))

    biexp_pred <- if (!is.infinite(biexp_fit$value)) {
      biexp_solution(t, biexp_fit$par["A1"], biexp_fit$par["k1"],
                     biexp_fit$par["A2"], biexp_fit$par["k2"],
                     biexp_fit$par["C"])
    } else rep(NA, length(t))

    biexp_rss <- if (!any(is.na(biexp_pred))) sum((B - biexp_pred)^2) else NA
    biexp_npar <- 5
    biexp_aic <- if (!is.na(biexp_rss)) {
      n <- length(B)
      n * log(biexp_rss / n) + 2 * biexp_npar
    } else NA

    # Compile results
    aics <- c(vi = aic, exp = exp_aic, quad = quad_aic,
              logistic = log_aic, biexp = biexp_aic)
    aics <- aics[!is.na(aics)]
    best_model <- names(which.min(aics))
    delta_aic <- aics - min(aics, na.rm = TRUE)

    list(
      values = list(
        # VI ODE
        r = unname(fit_res$par["r"]),
        K = unname(fit_res$par["K"]),
        delta = unname(fit_res$par["delta"]),
        B0 = unname(fit_res$par["B0"]),
        r_eff = unname(fit_res$par["r"] - fit_res$par["delta"]),
        rss = rss,
        aic = aic,
        r2 = if (!is.na(rss) && rss > 0) {
          1 - rss / sum((B - mean(B))^2)
        } else NA,
        # Simple exponential
        exp_r = unname(exp_fit$par["r"]),
        exp_B0 = unname(exp_fit$par["B0"]),
        exp_aic = exp_aic,
        # Quadratic
        quad_gamma = unname(quad_fit$par["gamma"]),
        quad_aic = quad_aic,
        # Logistic
        log_K = unname(log_fit$par["K"]),
        log_r = unname(log_fit$par["r"]),
        log_aic = log_aic,
        # Bi-exponential
        biexp_aic = biexp_aic,
        # Model comparison
        all_aic = aics,
        delta_aic = delta_aic,
        best_model = best_model,
        delta_aic = if ("valence" %in% names(delta_aic)) delta_aic["valence"] else NA,
        beats_exp = !is.na(aic) && !is.na(exp_aic) && aic < exp_aic,
        # Generative regime check
        r_eff_positive = !is.na(rss) &&
          unname(fit_res$par["r"] - fit_res$par["delta"]) > 0,
        # Saturation
        pct_of_K = if (!is.na(fit_res$par["K"]) && fit_res$par["K"] > 0) {
          max(B) / fit_res$par["K"] * 100
        } else NA,
        n = length(B)
      ),
      metadata = list(
        seed = seed,
        test = "VI_ODE_fit",
        valence_prediction = "r_eff > 0 (generative regime); bi-exp wins near saturation",
        discriminating = TRUE,
        models_fitted = c("valence_ode", "exponential", "quadratic", "logistic", "biexponential")
      )
    )
  })
}

#' Bootstrap confidence interval for β (branching factor)
#'
#' Node-resampling bootstrap: resample nodes with replacement,
#' recompute β, repeat n=1000 times.
#'
#' @param degrees Numeric vector. Degree of each node in the network.
#' @param beta_formula Function. Takes degree vector, returns β.
#' @param n_boot Integer. Number of bootstrap iterations.
#' @param seed Integer. For reproducibility.
#' @return List (A6: proof object).
#' @export
bootstrap_beta_ci <- function(degrees, beta_formula = function(k) mean(k) / 2,
                              n_boot = 1000L, seed = 42L) {
  withr::with_seed(seed, {
    n <- length(degrees)
    boot_betas <- numeric(n_boot)

    for (i in seq_len(n_boot)) {
      idx <- sample(seq_len(n), size = n, replace = TRUE)
      boot_betas[i] <- beta_formula(degrees[idx])
    }

    ci <- quantile(boot_betas, probs = c(0.025, 0.975))
    point <- beta_formula(degrees)

    list(
      values = list(
        beta_point = point,
        beta_boot_mean = mean(boot_betas),
        ci_lower = unname(ci[1]),
        ci_upper = unname(ci[2]),
        se = sd(boot_betas),
        bias = mean(boot_betas) - point,
        n_boot = n_boot,
        n_nodes = n,
        ci_above_1 = unname(ci[1]) > 1,
        beta_above_1 = point > 1
      ),
      metadata = list(
        seed = seed,
        test = "bootstrap_beta_ci",
        method = "node resampling bootstrap",
        discriminating = TRUE
      )
    )
  })
}

#' Buildout-failure mismatch test
#'
#' Tests whether the cultural acceleration rate exceeds the
#' biological relaxation rate (mismatch regime).
#'
#' @param r_B Numeric. Cultural acceleration rate (ε·β).
#' @param k1 Numeric. Fast biological relaxation rate.
#' @param k2 Numeric. Slow biological relaxation rate.
#' @return List (A6: proof object).
#' @export
mismatch_regime_test <- function(r_B, k1, k2) {
  regime <- if (r_B > k1) {
    "failure"
  } else if (r_B > k2) {
    "lagged"
  } else {
    "matched"
  }

  list(
    values = list(
      r_B = r_B,
      k1 = k1,
      k2 = k2,
      regime = regime,
      mismatch_grows = r_B > k1,
      r_B_exceeds_k1 = r_B > k1,
      r_B_exceeds_k2 = r_B > k2,
      # Mismatch rate (linear approx for small t)
      mismatch_rate = max(0, r_B - k1)
    ),
    metadata = list(
      test = "buildout_failure_mismatch",
      valence_prediction = "r_B > k1 → mismatch grows (failure regime)",
      discriminating = TRUE
    )
  )
}
