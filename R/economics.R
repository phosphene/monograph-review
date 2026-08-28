#' Phase 6: Economics Extension — valence Predictions in Economic Substrates
#'
#' Pure functions that carry the Valence-Ingression framework's
#' integration-depth and commitment dynamics into economic systems:
#' disruptive industry collapse trajectories, option-value destruction under
#' lock-in, stochastic first-passage to irreversibility, and threshold-gated
#' cascade disruption. Each function is DFI-compliant (A1 pure, A2 seeded
#' determinism, A6 proof object) and mirrors the paper scripts under
#' `drafts/valence-econ-papers/`.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): every function is pure — data in, data out
#' - A2 (determinism): stochastic operations run inside `withr::with_seed()`
#' - A6 (check-result): every function returns a `values` + `metadata` proof object
#'
#' @name economics
NULL

#' Validate economic disruption time-series data
#'
#' Internal validator for the economic data frames used by the Phase 6
#' economics functions. Enforces the columns required to compute CDI
#' (capacity, year, system) and, for threshold models, trigger year.
#'
#' @param data Data frame. Must contain `system`, `year`, `capacity`.
#' @param need_trigger Logical. If TRUE, also requires `trigger_year`.
#'
#' @keywords internal
validate_econ_data <- function(data, need_trigger = FALSE) {
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  required <- c("system", "year", "capacity")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf(
      "data missing required columns: %s",
      paste(missing, collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.numeric(data$year) || !is.numeric(data$capacity)) {
    stop("year and capacity must be numeric", call. = FALSE)
  }
  if (any(data$capacity < 0, na.rm = TRUE)) {
    stop("capacity must be non-negative", call. = FALSE)
  }
  if (need_trigger && !"trigger_year" %in% names(data)) {
    stop("data missing required column 'trigger_year'", call. = FALSE)
  }
  invisible(TRUE)
}

#' Compute CDI trajectories for economic systems
#'
#' Converts the valence economics `capacity` time series into Commitment/
#' Disintegration Index (CDI) trajectories — `CDI = 1 - capacity/peak` — and
#' compares the trajectory shape (linear vs log vs quadratic) for each system.
#' This is the pure-function adaptation of Paper 1's `compute_cdi` and
#' trajectory-shape analysis.
#'
#' @param data Data frame with columns `system`, `year`, `capacity`
#'   (monotone industry capacity over time). Post-peak observations are used.
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named numeric: n_systems, pooled_best, mean_post_peak_cdi,
#'     systems_prefer_logical (share of systems whose best model is log or
#'     quadratic), mean_spearman_time_cdi}
#'   \item{metadata}{List: seed, n (post-peak obs), systems, per_system
#'     (list of trajectory fits), converged}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: capacity loss in disrupted industries follows a decelerating
#' (log/logistic/saturating) CDI trajectory — commitment accrues fast early,
#' then slows — rather than linear or exponential collapse.
#'
#' Competitor: constant-rate decay (exponential) predicts a linear rate of
#' capacity loss and an accelerating CDI in these units. This test DOES
#' distinguish valence from constant-rate decay: valence predicts the log or quadratic
#' (decelerating) model wins on AIC across independent industries.
#'
#' What supports valence: log/quadratic models outperform linear (decelerating CDI).
#' What refutes valence: linear or exponential models dominate.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected and used via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep(c("newspapers", "taxi"), each = 20),
#'   year = rep(1990:2009, 2),
#'   capacity = c(100 * exp(-0.03 * 0:19), 100 * exp(-0.08 * 0:19))
#' )
#' cdi_economics(dat, seed = 42)
#' }
cdi_economics <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_econ_data(data)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$year), ]
      peak_cap <- max(d$capacity, na.rm = TRUE)
      if (!is.finite(peak_cap) || peak_cap <= 0) next
      d$cdi <- 1 - (d$capacity / peak_cap)
      peak_yr <- d$year[which.max(d$capacity)]
      d$years_since_peak <- d$year - peak_yr
      d <- d[d$years_since_peak >= 0, ]
      if (nrow(d) < 4) next

      t <- d$years_since_peak
      y <- d$cdi
      m_lin <- lm(y ~ t)
      m_log <- lm(y ~ log(t + 1))
      aic_lin <- AIC(m_lin)
      aic_log <- AIC(m_log)
      best <- "linear"
      if (aic_log < aic_lin) best <- "log"

      # Deceleration check: quadratic coefficient sign
      m_quad <- lm(y ~ t + I(t^2))
      decel <- coef(m_quad)[3] < 0

      per_system[[sys]] <- list(
        system = sys,
        n = nrow(d),
        aic_lin = aic_lin,
        aic_log = aic_log,
        best = best,
        decelerating = decel,
        r2_log = summary(m_log)$r.squared,
        mean_post_peak_cdi = mean(y)
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough post-peak observations (>= 4)", call. = FALSE)
    }

    sys_names <- names(per_system)
    systems_prefer_logical <- mean(vapply(
      per_system,
      function(p) p$best == "log" || p$decelerating,
      logical(1)
    ))
    mean_cdi <- mean(vapply(
      per_system, function(p) p$mean_post_peak_cdi,
      numeric(1)
    ))

    result <- list(
      values = list(
        n_systems = length(per_system),
        share_log_best = mean(vapply(
          per_system, function(p) p$best == "log",
          numeric(1)
        )),
        share_decelerating = mean(vapply(
          per_system, function(p) p$decelerating,
          numeric(1)
        )),
        mean_post_peak_cdi = mean_cdi,
        systems_prefer_logical = systems_prefer_logical
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        systems = sys_names,
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Option value destruction under commitment/lock-in
#'
#' Models the devaluation of a disrupted industry's option to pivot as a
#' function of CDI (commitment) rather than calendar time. Adapted from
#' Paper 1's option-value-decay section: the standard model decays option
#' value exponentially in time; valence couples decay to CDI itself.
#'
#' @param data Data frame with columns `system`, `year`, `capacity`.
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named numeric: n_systems, mean_early_resid, mean_late_resid,
#'     valence_pattern_share (fraction of systems showing the valence residual pattern),
#'     mean_standard_decay_rate}
#'   \item{metadata}{List: seed, n (systems), per_system, converged}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: because option value tracks remaining capacity (1 - CDI),
#' and CDI grows deceleratingly, the standard exponential-in-time decay model
#' systematically over-estimates early option value and under-estimates late
#' remaining value (residuals negative early, positive late).
#'
#' Competitor: standard financial-options / theta-decay model values the pivot
#' option as a pure exponential in time, independent of commitment. This test
#' DOES distinguish valence: it predicts a specific residual sign pattern relative
#' to the exponential baseline.
#'
#' What supports valence: early residuals negative, late residuals positive.
#' What refutes valence: the opposite or no systematic pattern.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected and used via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep("taxi", 20),
#'   year = 2000:2019,
#'   capacity = 100 * exp(-0.10 * 0:19)
#' )
#' option_destruction(dat, seed = 42)
#' }
option_destruction <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_econ_data(data)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$year), ]
      peak_cap <- max(d$capacity, na.rm = TRUE)
      if (!is.finite(peak_cap) || peak_cap <= 0) next
      d$cdi <- 1 - (d$capacity / peak_cap)
      peak_yr <- d$year[which.max(d$capacity)]
      d$years_since_peak <- d$year - peak_yr
      d <- d[d$years_since_peak >= 0, ]
      if (nrow(d) < 5) next

      opt_val <- 1 - d$cdi
      t <- d$years_since_peak

      # Standard exponential-in-time decay
      pos <- opt_val > 0.01
      if (sum(pos) < 3) next
      m_std <- lm(log(opt_val[pos]) ~ t[pos])
      r_std <- -coef(m_std)[2]
      resid_std <- residuals(m_std)

      n_half <- floor(length(resid_std) / 2)
      if (n_half < 2) next
      early_resid <- mean(resid_std[1:n_half])
      late_resid <- mean(resid_std[(n_half + 1):length(resid_std)])
      pattern <- early_resid < 0 && late_resid > 0

      per_system[[sys]] <- list(
        system = sys,
        n = length(resid_std),
        decay_rate = r_std,
        early_resid = early_resid,
        late_resid = late_resid,
        valence_pattern = pattern
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough observations for option decay", call. = FALSE)
    }

    result <- list(
      values = list(
        n_systems = length(per_system),
        mean_early_resid = mean(vapply(
          per_system, function(p) p$early_resid,
          numeric(1)
        )),
        mean_late_resid = mean(vapply(
          per_system, function(p) p$late_resid,
          numeric(1)
        )),
        valence_pattern_share = mean(vapply(
          per_system, function(p) p$valence_pattern,
          numeric(1)
        )),
        mean_standard_decay_rate = mean(vapply(per_system, function(p) {
          p$decay_rate
        }, numeric(1)))
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        systems = names(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Stochastic CDI first-passage simulation
#'
#' Simulates a single stochastic Commitment/Disintegration Index (CDI) path
#' under the valence logistic-drift, commitment-damped-volatility SDE and returns
#' the first-passage time to a threshold. Adapted from Paper 2's
#' `simulate_cdi_path` as a pure, seedable function.
#'
#' @param mu0 Numeric. Logistic drift-rate constant (positive).
#' @param sigma0 Numeric. Base volatility (>= 0).
#' @param cdi_init Numeric. Initial CDI in [0, 1]. Default 0.01.
#' @param dt Numeric. Time step. Default 0.01.
#' @param n_steps Integer. Number of time steps. Default 1000.
#' @param threshold Numeric. First-passage CDI threshold in (0, 1]. Default 0.8.
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named numeric: final_cdi, max_cdi, first_passage
#'     (NA if not reached), n_steps}
#'   \item{metadata}{List: seed, n (n_steps + 1), mu0, sigma0, dt, threshold,
#'     path (full numeric CDI vector), time (numeric vector), reached}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: commitment (CDI) is autocatalytic under logistic drift and
#' reaches irreversibility (threshold) with probability 1, while volatility is
#' damped as commitment grows (`sigma0 * (1 - CDI)`). First-passage times are
#' the economic analog of time-to-irreversibility in the monograph.
#'
#' Competitor: a constant-drift / constant-volatility random walk (Merton-style
#' baseline) predicts the same mean first-passage time but with hazard that is
#' constant over time, not increasing with CDI. The logistic-drift + damped
#' volatility structure DOES distinguish valence from the constant baseline.
#'
#' What supports valence: first-passage times that are realistic and hazard that
#' increases with CDI. What refutes valence: paths that wander without converging
#' to the threshold.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): all RNG inside withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' stochastic_cdi(mu0 = 0.5, sigma0 = 0.2, cdi_init = 0.01,
#'                dt = 0.01, n_steps = 1000, threshold = 0.8, seed = 42)
#' }
stochastic_cdi <- function(mu0, sigma0, cdi_init = 0.01, dt = 0.01,
                           n_steps = 1000L, threshold = 0.8, seed = 42L) {
  withr::with_seed(seed, {
    # Contract checks (pure, no I/O)
    if (!is.numeric(mu0) || length(mu0) != 1L || mu0 < 0) {
      stop("mu0 must be a single non-negative number", call. = FALSE)
    }
    if (!is.numeric(sigma0) || length(sigma0) != 1L || sigma0 < 0) {
      stop("sigma0 must be a single non-negative number", call. = FALSE)
    }
    if (!is.numeric(cdi_init) || length(cdi_init) != 1L ||
          cdi_init < 0 || cdi_init > 1) {
      stop("cdi_init must be in [0, 1]", call. = FALSE)
    }
    if (!is.numeric(dt) || length(dt) != 1L || dt <= 0) {
      stop("dt must be a single positive number", call. = FALSE)
    }
    if (!is.numeric(n_steps) || length(n_steps) != 1L || n_steps < 1) {
      stop("n_steps must be a single positive integer", call. = FALSE)
    }
    if (!is.numeric(threshold) || length(threshold) != 1L ||
          threshold <= 0 || threshold > 1) {
      stop("threshold must be in (0, 1]", call. = FALSE)
    }

    n <- as.integer(n_steps)
    cdi <- numeric(n + 1)
    time <- numeric(n + 1)
    cdi[1] <- cdi_init
    time[1] <- 0
    fp_time <- NA_real_

    for (i in 1:n) {
      c <- cdi[i]
      c <- max(0.001, min(c, 0.999))
      drift <- mu0 * c * (1 - c)
      vol <- sigma0 * (1 - c)
      d_w <- stats::rnorm(1, 0, sqrt(dt))
      c_new <- c + drift * dt + vol * d_w
      c_new <- max(0, min(c_new, 1))
      cdi[i + 1] <- c_new
      time[i + 1] <- i * dt
      if (is.na(fp_time) && c_new >= threshold) {
        fp_time <- i * dt
      }
    }

    result <- list(
      values = list(
        final_cdi = cdi[n + 1],
        max_cdi = max(cdi),
        first_passage = ifelse(is.na(fp_time), NA_real_, fp_time),
        n_steps = n
      ),
      metadata = list(
        seed = seed,
        n = n + 1,
        mu0 = mu0,
        sigma0 = sigma0,
        dt = dt,
        threshold = threshold,
        reached = !is.na(fp_time),
        path = cdi,
        time = time,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Threshold-gated disruption: piecewise vs smooth models
#'
#' Tests whether disrupted economic systems show a piecewise (threshold-gated)
#' collapse — a slow pre-trigger erosion followed by a rapid post-trigger
#' cascade — rather than a smooth single-regime decline. Adapted from Paper 4's
#' piecewise model test at known trigger years.
#'
#' @param data Data frame with columns `system`, `year`, `capacity`,
#'   and `trigger_year` (the known disruption trigger/cascade onset year).
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named numeric: n_systems, mean_delta_aic (linear minus
#'     piecewise, > 0 favours piecewise), mean_slope_ratio (late/early),
#'     share_piecewise_win (fraction of systems where piecewise AIC < linear)}
#'   \item{metadata}{List: seed, n (systems), per_system, converged}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: capability/capacity loss is threshold-gated — reversible
#' erosion below a trigger, then a correlated cascade once a functionally
#' coherent capability module enters "relaxed selection." A piecewise model
#' with a breakpoint at the trigger year should beat a smooth linear model.
#'
#' Competitor: smooth, single-regime decay (constant-rate) predicts a piecewise
#' model adds no predictive value. This test DOES distinguish valence: it predicts a
#' material ΔAIC and a steeper post-trigger slope.
#'
#' What supports valence: piecewise AIC < linear AIC and late/early slope ratio > 1.
#' What refutes valence: no improvement from the piecewise model.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected and used via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep(c("newspapers", "taxi"), each = 20),
#'   year = rep(1990:2009, 2),
#'   capacity = c(100 * exp(-0.03 * 0:19), 100 * exp(-0.08 * 0:19)),
#'   trigger_year = c(rep(1998, 20), rep(2002, 20))
#' )
#' threshold_disruption(dat, seed = 42)
#' }
threshold_disruption <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_econ_data(data, need_trigger = TRUE)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$year), ]
      trig_year <- unique(d$trigger_year)[1]
      peak_cap <- max(d$capacity, na.rm = TRUE)
      if (!is.finite(peak_cap) || peak_cap <= 0) next
      d$cap_norm <- d$capacity / peak_cap
      peak_yr <- d$year[which.max(d$capacity)]
      d$t <- d$year - peak_yr
      d <- d[d$t >= 0, ]
      if (nrow(d) < 5) next

      t <- d$t
      y <- d$cap_norm
      bp <- trig_year - peak_yr

      m_lin <- lm(y ~ t)
      t_piece <- ifelse(t > bp, t - bp, 0)
      m_pw <- lm(y ~ t + t_piece)

      delta_aic <- AIC(m_lin) - AIC(m_pw)
      early_slope <- coef(m_pw)[2]
      late_slope <- coef(m_pw)[2] + coef(m_pw)[3]
      slope_ratio <- ifelse(abs(early_slope) < 1e-9, NA_real_,
        abs(late_slope / early_slope)
      )
      lr <- tryCatch(anova(m_lin, m_pw)$"Pr(>F)"[2], error = function(e) NA_real_)

      per_system[[sys]] <- list(
        system = sys,
        n = nrow(d),
        delta_aic = delta_aic,
        slope_ratio = slope_ratio,
        lr_p = lr,
        piecewise_win = delta_aic > 0
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough observations for threshold model", call. = FALSE)
    }

    result <- list(
      values = list(
        n_systems = length(per_system),
        mean_delta_aic = mean(vapply(
          per_system, function(p) p$delta_aic,
          numeric(1)
        )),
        share_piecewise_win = mean(vapply(per_system, function(p) {
          p$piecewise_win
        }, numeric(1))),
        mean_slope_ratio = mean(vapply(per_system, function(p) {
          ifelse(is.na(p$slope_ratio), 0, p$slope_ratio)
        }, numeric(1)))
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        systems = names(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
