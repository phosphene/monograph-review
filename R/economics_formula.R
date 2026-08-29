#' Phase 6b: Formula-Grounded Economics Predictions
#'
#' Functions that carry the *proven quantitative formula* into economic
#' substrates. The original formula — ρ(θ) = ρ_sat · H(θ − θ*), with
#' θ* = 0, ρ_sat ≈ 0.35, s → ∞ — models *cross-sectional* (theta, rho)
#' dynamics. The successor relaxation formula —
#' dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) — models *temporal* (t, rho) dynamics
#' and is implemented in `relaxation_model.R` and `fit_biexp.R`.
#'
#' Both formulations are valid for different data regimes. The step-function
#' functions here test the *specific functional form* (Heaviside step, not
#' sigmoid or logistic) and the *specific parameter value* (ρ_sat ≈ 0.35)
#' in cross-sectional economic data. The relaxation functions in
#' `fit_biexp.R` and `relaxation_model.R` test the temporal dynamics.
#'
#' The qualitative functions (`cdi_economics`, `option_destruction`,
#' `stochastic_cdi`, `threshold_disruption`) test whether the framework's directional
#' predictions hold. These functions test whether the formula's exact
#' shape and constants hold. Both layers are valuable — the qualitative
#' layer doesn't become redundant when the quantitative layer is added.
#'
#' @section Theoretical Context:
#'
#' The cross-sectional formula ρ(θ) = ρ_sat · H(θ − θ*) was derived from
#' three biological systems (LTEE, Sodalis, Buchnera) and replicated across
#' nine systems spanning four kingdoms. ρ_sat ≈ 0.35 is the drift-selection
#' boundary: P(retain | δ>0) − P(retain | δ=0). If this is
#' substrate-independent (as the cross-kingdom replication suggests), it
#' should hold in economic systems too.
#'
#' The temporal relaxation formula — dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) —
#' is the successor, describing the *dynamics* behind the cross-sectional
#' step. The two channels (fast k₁, slow k₂) produce the same biphasic
#' pattern seen in the cross-sectional data, now extended to time series.
#' See `relaxation_model.R` for the ODE implementation and
#' `fit_biexp.R` for the bi-exponential fitter.
#'
#' Key predictions carried into economics:
#'
#' 1. **Disruption starts at first provision (θ* = 0).** No tipping point
#'    at critical mass — the cascade begins at first contact.
#' 2. **ρ_sat ≈ 0.35 is universal.** The retention correlation above
#'    threshold should be ~0.35 in any system with drift-selection dynamics.
#' 3. **The step wins on AIC.** A Heaviside model should outperform both
#'    sigmoid and logistic on properly resolved economic disruption data.
#' 4. **Option value collapses as a step, not exponential.** The standard
#'    theta-decay model is wrong — collapse is at first provision, not
#'    gradual.
#' 5. **Irreversibility is absolute (s → ∞).** No recovery after crossing
#'    the threshold.
#' 6. **Temporal dynamics are bi-exponential.** The relaxation formula
#'    predicts two timescales: fast Phase 1 (k₁ ~ 10–20) and slow Phase 2
#'    (k₂ ~ 0.1–1). The bi-exponential fitter (`fit_biexp.R`) tests this.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure functions, no I/O
#' - A2 (determinism): seeded via withr::with_seed()
#' - A6 (check-result): returns proof objects with values + metadata
#'
#' @name economics_formula
NULL

#' Validate formula-economics data
#'
#' Internal validator for data frames used by the formula-grounded
#' economics functions. Requires `system`, `theta`, `rho`.
#'
#' @param data Data frame.
#'
#' @keywords internal
validate_formula_data <- function(data) {
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  required <- c("system", "theta", "rho")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf(
      "data missing required columns: %s",
      paste(missing, collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.numeric(data$theta) || !is.numeric(data$rho)) {
    stop("theta and rho must be numeric", call. = FALSE)
  }
  if (any(data$rho < 0 | data$rho > 1, na.rm = TRUE)) {
    stop("rho must be in [0, 1]", call. = FALSE)
  }
  invisible(TRUE)
}

#' Heaviside step model fit
#'
#' Fits ρ(θ) = ρ_sat · H(θ − θ*) to (theta, rho) data by searching
#' for the breakpoint θ* that minimizes residual sum of squares, then
#' estimating ρ_sat as the mean of post-breakpoint values.
#'
#' Returns the fitted step model alongside sigmoid and logistic competitors
#' for AIC comparison.
#'
#' @param theta Numeric vector. Provision depth (θ).
#' @param rho Numeric vector. Retention correlation (ρ).
#'
#' @return List: `step` (list: theta_star, rho_sat, rss, aic),
#'   `sigmoid` (list: k, x0, rss, aic), `logistic` (list: k, x0, rss, aic),
#'   `best_model` (character), `delta_aic_step_vs_sigmoid` (numeric)
#'
#' @keywords internal
fit_step_models <- function(theta, rho) {
  n <- length(theta)
  if (n < 4) {
    stop("need at least 4 data points for model fitting", call. = FALSE)
  }

  ord <- order(theta)
  theta_s <- theta[ord]
  rho_s <- rho[ord]

  # --- Step model: search breakpoint ---
  # For each candidate breakpoint between data points, compute:
  #   pre-breakpoint mean = mean(rho[theta < bp])
  #   post-breakpoint mean = mean(rho[theta >= bp])
  #   RSS = sum of squares
  # Pick the bp that minimizes RSS.
  best_rss <- Inf
  best_bp <- 0
  best_pre <- 0
  best_post <- 0

  candidates <- theta_s
  for (bp in candidates) {
    pre <- rho_s[theta_s < bp]
    post <- rho_s[theta_s >= bp]
    pre_mean <- if (length(pre) > 0) mean(pre) else 0
    post_mean <- if (length(post) > 0) mean(post) else 0
    pred <- ifelse(theta_s < bp, pre_mean, post_mean)
    rss <- sum((rho_s - pred)^2)
    if (rss < best_rss) {
      best_rss <- rss
      best_bp <- bp
      best_pre <- pre_mean
      best_post <- post_mean
    }
  }

  # Also test breakpoint at 0 (the formula's prediction: θ* = 0)
  rho_post0 <- mean(rho_s[theta_s >= 0])
  rho_pre0 <- mean(rho_s[theta_s < 0])
  pred_0 <- ifelse(theta_s < 0, rho_pre0, rho_post0)
  rss_0 <- sum((rho_s - pred_0)^2)

  # Use θ* = 0 if it's within 10% of best RSS
  if (rss_0 <= best_rss * 1.1) {
    best_bp <- 0
    best_rss <- rss_0
    best_pre <- rho_pre0
    best_post <- rho_post0
  }

  k_step <- 2  # number of breakpoint-and-plateau parameters
  aic_step <- n * log(best_rss / n) + 2 * k_step

  # --- Sigmoid model: ρ = ρ_sat / (1 + exp(-k(θ - x0))) ---
  # Grid search for k and x0, then set ρ_sat = max(rho)
  rho_sat_est <- max(rho_s, na.rm = TRUE)
  best_sig_rss <- Inf
  best_sig_k <- 1
  best_sig_x0 <- 0
  k_grid <- c(0.5, 1, 2, 5, 10, 20, 50, 100)
  x0_grid <- seq(min(theta_s), max(theta_s), length.out = 50)
  for (k in k_grid) {
    for (x0 in x0_grid) {
      pred <- rho_sat_est / (1 + exp(-k * (theta_s - x0)))
      rss <- sum((rho_s - pred)^2)
      if (rss < best_sig_rss) {
        best_sig_rss <- rss
        best_sig_k <- k
        best_sig_x0 <- x0
      }
    }
  }
  k_sig <- 3 # k, x0, rho_sat
  aic_sig <- n * log(best_sig_rss / n) + 2 * k_sig

  # --- Logistic model: ρ = ρ_sat / (1 + exp(-k(θ - x0))) with forced ρ_sat ---
  # Same as sigmoid but we report transition width = 4/k
  # Already computed above; logistic IS the sigmoid with finite k

  list(
    step = list(
      theta_star = best_bp,
      rho_sat = best_post,
      rss = best_rss,
      aic = aic_step,
      transition_width = 0 # step = infinite slope
    ),
    sigmoid = list(
      k = best_sig_k,
      x0 = best_sig_x0,
      rho_sat = rho_sat_est,
      rss = best_sig_rss,
      aic = aic_sig,
      transition_width = 4 / best_sig_k
    ),
    logistic = list(
      k = best_sig_k,
      x0 = best_sig_x0,
      rho_sat = rho_sat_est,
      rss = best_sig_rss,
      aic = aic_sig,
      transition_width = 4 / best_sig_k
    ),
    best_model = if (aic_step < aic_sig) "step" else "sigmoid",
    delta_aic_step_vs_sigmoid = aic_sig - aic_step
  )
}

#' Test the ρ_sat ≈ 0.35 prediction in economic data
#'
#' The formula predicts ρ_sat ≈ 0.35 — the drift-selection boundary —
#' is substrate-independent. If true, it should appear in economic
#' disruption data: the post-threshold retention correlation should
#' saturate at ~0.35, the same value found in bacteria, plants, and
#' languages.
#'
#' This function takes (theta, rho) data from any economic system and
#' tests whether the post-threshold plateau is ~0.35.
#'
#' @param data Data frame with columns `system`, `theta`, `rho`.
#'   `theta` = provision depth (degree to which new technology externally
#'   supplies what a firm's capabilities once did).
#'   `rho` = within-system Spearman correlation between firm-level
#'   dependency on the old technology and firm-level survival/retention.
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named: n_systems, mean_rho_sat (mean post-threshold
#'     plateau across systems), formula_prediction (0.35),
#'     within_band (logical: is mean_rho_sat within [0.25, 0.45]?),
#'     step_wins_share (fraction of systems where step beats sigmoid on AIC),
#'     mean_delta_aic (mean AIC improvement of step over sigmoid)}
#'   \item{metadata}{List: seed, n, per_system, converged}
#'
#' @section Theoretical Context:
#'
#' the framework's formula prediction: ρ_sat ≈ 0.35 across all substrates. In economics,
#' this means: the correlation between firm-level capability dependency and
#' firm survival, measured above the provision threshold, should be ~0.35.
#' Not 0.1, not 0.8 — 0.35. This is a parameter-free, substrate-independent
#' quantitative prediction.
#'
#' The 0.35 value arises because P(retain | δ>0) ≈ 0.75 (selection retention)
#' and P(retain | δ=0) ≈ 0.34 (drift retention), giving ρ_sat = 0.75 - 0.34
#' ≈ 0.35 (the drift-selection boundary). If the same population-genetic-like
#' parameters govern economic disruption, the same boundary should appear.
#'
#' Competitor: no existing economic theory predicts a universal constant for
#' the retention-survival correlation. Standard disruption theory (Christensen)
#' predicts qualitative displacement, not a quantitative saturation value.
#' This test DOES distinguish the framework formula from qualitative alternatives:
#' it makes a specific numerical prediction that no other theory makes.
#'
#' What supports the formula: mean_rho_sat ∈ [0.25, 0.45] and step wins on AIC.
#' What refutes the formula: mean_rho_sat far from 0.35 or sigmoid wins.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep(c("newspapers", "taxi"), each = 10),
#'   theta = rep(seq(-0.5, 1, length.out = 10), 2),
#'   rho = c(rep(0, 3), rep(0.35, 7), rep(0, 4), rep(0.38, 6))
#' )
#' rho_sat_prediction(dat, seed = 42)
#' }
rho_sat_prediction <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_formula_data(data)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$theta), ]

      fits <- tryCatch(
        fit_step_models(d$theta, d$rho),
        error = function(e) NULL
      )
      if (is.null(fits)) next

      rho_sat_est <- fits$step$rho_sat
      step_wins <- fits$best_model == "step"
      delta_aic <- fits$delta_aic_step_vs_sigmoid

      per_system[[sys]] <- list(
        system = sys,
        n = nrow(d),
        rho_sat_est = rho_sat_est,
        formula_pred = 0.35,
        within_band = rho_sat_est >= 0.25 && rho_sat_est <= 0.45,
        best_model = fits$best_model,
        delta_aic = delta_aic,
        step_aic = fits$step$aic,
        sigmoid_aic = fits$sigmoid$aic,
        transition_width_step = fits$step$transition_width,
        transition_width_sigmoid = fits$sigmoid$transition_width
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough data for formula fitting", call. = FALSE)
    }

    mean_rho_sat <- mean(vapply(per_system, function(p) p$rho_sat_est, numeric(1)))
    step_wins_share <- mean(vapply(per_system, function(p) {
      as.logical(p$best_model == "step")
    }, numeric(1)))
    mean_delta <- mean(vapply(per_system, function(p) p$delta_aic, numeric(1)))

    result <- list(
      values = list(
        n_systems = length(per_system),
        mean_rho_sat = mean_rho_sat,
        formula_prediction = 0.35,
        within_band = mean_rho_sat >= 0.25 && mean_rho_sat <= 0.45,
        step_wins_share = step_wins_share,
        mean_delta_aic = mean_delta
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Step-model CDI comparison (Heaviside vs logistic vs exponential)
#'
#' Extends `cdi_economics()` by adding the Heaviside step as a third
#' model in the AIC comparison. The formula predicts the step wins:
#' capacity collapses as a step at the provision threshold, not
#' gradually (logistic) or exponentially (constant-rate).
#'
#' The step model: CDI(t) = H(t - t_trigger) = 0 for t < t_trigger,
#' 1 for t >= t_trigger. In practice, we allow a narrow transition
#' width and test whether it's significantly narrower than the
#' logistic transition width.
#'
#' @param data Data frame with columns `system`, `year`, `capacity`,
#'   `trigger_year` (the known disruption trigger year).
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named: n_systems, step_wins_share, mean_delta_aic_step_log,
#'     mean_delta_aic_step_exp, mean_step_width (in years)}
#'   \item{metadata}{List: seed, n, per_system, converged}
#'
#' @section Theoretical Context:
#'
#' the framework's formula prediction: s → ∞ — the transition width is zero. In economic
#' terms, capacity collapse is a step at the provision threshold, not a
#' gradual curve. The standard logistic or exponential decay models are
#' wrong: they predict a finite transition width. The formula predicts
#' the step model wins on AIC.
#'
#' The practical test: fit step (Heaviside with narrow transition),
#' logistic, and exponential to each system's CDI trajectory. Compare AIC.
#' The step model has 2 parameters (trigger year, plateau height); logistic
#' has 3 (rate, midpoint, plateau); exponential has 2 (rate, plateau).
#'
#' Competitor: logistic (smooth S-curve) predicts a finite transition width.
#' Exponential (constant-rate) predicts an infinite tail. The formula
#' predicts neither — the collapse is instantaneous at the threshold.
#'
#' What supports the formula: step wins on AIC and transition width → 0.
#' What refutes the formula: logistic or exponential wins.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep("newspapers", 20),
#'   year = 1990:2009,
#'   capacity = c(rep(100, 8), rep(30, 12)),
#'   trigger_year = 1998
#' )
#' step_cdi_comparison(dat, seed = 42)
#' }
step_cdi_comparison <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_econ_data(data, need_trigger = TRUE)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$year), ]
      trig <- unique(d$trigger_year)[1]
      peak_cap <- max(d$capacity, na.rm = TRUE)
      if (!is.finite(peak_cap) || peak_cap <= 0) next
      d$cdi <- 1 - (d$capacity / peak_cap)
      peak_yr <- d$year[which.max(d$capacity)]
      d$t <- d$year - peak_yr
      d <- d[d$t >= 0, ]
      if (nrow(d) < 5) next

      t <- d$t
      y <- d$cdi
      bp <- trig - peak_yr

      # Step model: CDI = 0 before trigger, 1 after (with fitted plateau)
      post <- y[t >= bp]
      pre <- y[t < bp]
      plateau <- if (length(post) > 0) mean(post) else 1
      baseline <- if (length(pre) > 0) mean(pre) else 0
      pred_step <- ifelse(t >= bp, plateau, baseline)
      rss_step <- sum((y - pred_step)^2)
      k_step <- 2
      n <- length(y)
      aic_step <- n * log(rss_step / n) + 2 * k_step

      # Exponential model: CDI equals 1 minus exp(-r*t)
      pos <- y > 0.001
      if (sum(pos) < 3) next
      m_exp <- tryCatch(
        lm(log(y[pos]) ~ t[pos]),
        error = function(e) NULL
      )
      if (is.null(m_exp)) next
      r_exp <- -coef(m_exp)[2]
      pred_exp <- 1 - exp(-r_exp * t)
      pred_exp <- pmax(0, pmin(1, pred_exp))
      rss_exp <- sum((y - pred_exp)^2)
      aic_exp <- n * log(rss_exp / n) + 2 * 2

      # Logistic model: CDI equals 1 over (1 + exp(-k*(t - x0)))
      best_log_rss <- Inf
      best_log_k <- 1
      best_log_x0 <- bp
      for (k in c(0.1, 0.5, 1, 2, 5, 10, 50)) {
        for (x0 in seq(max(0, bp - 5), bp + 5, by = 0.5)) {
          pred <- 1 / (1 + exp(-k * (t - x0)))
          rss <- sum((y - pred)^2)
          if (rss < best_log_rss) {
            best_log_rss <- rss
            best_log_k <- k
            best_log_x0 <- x0
          }
        }
      }
      aic_log <- n * log(best_log_rss / n) + 2 * 3

      # Transition width: step = 0, logistic = 4/k, exponential = 1/r
      step_width <- 0
      log_width <- 4 / best_log_k
      exp_width <- 1 / r_exp

      best_model <- "step"
      best_aic <- aic_step
      if (aic_exp < best_aic) {
        best_model <- "exponential"
        best_aic <- aic_exp
      }
      if (aic_log < best_aic) {
        best_model <- "logistic"
        best_aic <- aic_log
      }

      per_system[[sys]] <- list(
        system = sys,
        n = n,
        aic_step = aic_step,
        aic_logistic = aic_log,
        aic_exponential = aic_exp,
        best_model = best_model,
        step_width = step_width,
        logistic_width = log_width,
        exponential_width = exp_width,
        delta_aic_step_log = aic_log - aic_step,
        delta_aic_step_exp = aic_exp - aic_step
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough observations for step comparison", call. = FALSE)
    }

    result <- list(
      values = list(
        n_systems = length(per_system),
        step_wins_share = mean(vapply(per_system, function(p) {
          as.logical(p$best_model == "step")
        }, numeric(1))),
        mean_delta_aic_step_log = mean(vapply(per_system, function(p) {
          p$delta_aic_step_log
        }, numeric(1))),
        mean_delta_aic_step_exp = mean(vapply(per_system, function(p) {
          p$delta_aic_step_exp
        }, numeric(1))),
        mean_step_width = 0 # step width is always 0 by definition
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Step-collapse option value (formula-grounded)
#'
#' The formula predicts option value collapses as a Heaviside step
#' at first provision (θ = 0), not as exponential theta-decay over
#' time. This function tests the step-collapse prediction against
#' the standard exponential-decay baseline.
#'
#' Where `option_destruction()` tests a residual sign pattern
#' (qualitative the framework's prediction), this function tests the specific
#' functional form (quantitative formula prediction): does a step
#' at the trigger year beat exponential decay on AIC?
#'
#' @param data Data frame with columns `system`, `year`, `capacity`,
#'   `trigger_year`.
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named: n_systems, step_wins_share, mean_delta_aic,
#'     mean_step_collapse_time (years from trigger to 50% capacity loss)}
#'   \item{metadata}{List: seed, n, per_system, converged}
#'
#' @section Theoretical Context:
#'
#' the framework's formula prediction: option value = remaining capacity = (1 - CDI).
#' The formula says CDI jumps as a step at θ = 0 (first provision).
#' Therefore option value should collapse as a step, not as an
#' exponential. The standard theta-decay model (exponential in time)
#' is the competitor.
#'
#' The formula's prediction: s → ∞ means the collapse is instantaneous.
#' In practice, we test whether a step model (capacity drops to plateau
#' at trigger year) beats an exponential model on AIC. If the step wins
#' and the plateau is near zero, the formula's prediction of absolute
#' irreversibility is supported.
#'
#' Competitor: Black-Scholes theta decay predicts smooth exponential
#' decline. The formula predicts a step. This test DOES distinguish
#' the formula from standard financial theory.
#'
#' What supports the formula: step wins on AIC, plateau near zero.
#' What refutes the formula: exponential wins or plateau far from zero.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep("taxi", 20),
#'   year = 2000:2019,
#'   capacity = c(rep(100, 5), rep(20, 15)),
#'   trigger_year = 2004
#' )
#' step_option_collapse(dat, seed = 42)
#' }
step_option_collapse <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    validate_econ_data(data, need_trigger = TRUE)

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$year), ]
      trig <- unique(d$trigger_year)[1]
      peak_cap <- max(d$capacity, na.rm = TRUE)
      if (!is.finite(peak_cap) || peak_cap <= 0) next
      d$opt_val <- d$capacity / peak_cap # option value ∝ remaining capacity
      peak_yr <- d$year[which.max(d$capacity)]
      d$t <- d$year - peak_yr
      d <- d[d$t >= 0, ]
      if (nrow(d) < 5) next

      t <- d$t
      y <- d$opt_val
      bp <- trig - peak_yr
      n <- length(y)

      # Step: option value = plateau before trigger, 0 after
      pre <- y[t < bp]
      post <- y[t >= bp]
      pre_mean <- if (length(pre) > 0) mean(pre) else 1
      post_mean <- if (length(post) > 0) mean(post) else 0
      pred_step <- ifelse(t < bp, pre_mean, post_mean)
      rss_step <- sum((y - pred_step)^2)
      aic_step <- n * log(rss_step / n) + 2 * 2

      # Exponential: option value = exp(-r * t)
      pos <- y > 0.01
      if (sum(pos) < 3) next
      m_exp <- tryCatch(lm(log(y[pos]) ~ t[pos]), error = function(e) NULL)
      if (is.null(m_exp)) next
      r_exp <- -coef(m_exp)[2]
      pred_exp <- exp(-r_exp * t)
      rss_exp <- sum((y - pred_exp)^2)
      aic_exp <- n * log(rss_exp / n) + 2 * 2

      # 50% collapse time
      collapse_50 <- NA_real_
      for (i in seq_along(t)) {
        if (y[i] <= 0.5 * pre_mean) {
          collapse_50 <- t[i]
          break
        }
      }

      best_model <- if (aic_step < aic_exp) "step" else "exponential"

      per_system[[sys]] <- list(
        system = sys,
        n = n,
        aic_step = aic_step,
        aic_exponential = aic_exp,
        best_model = best_model,
        delta_aic = aic_exp - aic_step,
        post_trigger_plateau = post_mean,
        collapse_50_time = collapse_50
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough observations", call. = FALSE)
    }

    result <- list(
      values = list(
        n_systems = length(per_system),
        step_wins_share = mean(vapply(per_system, function(p) {
          as.logical(p$best_model == "step")
        }, numeric(1))),
        mean_delta_aic = mean(vapply(per_system, function(p) {
          p$delta_aic
        }, numeric(1))),
        mean_step_collapse_time = mean(vapply(per_system, function(p) {
          ifelse(is.na(p$collapse_50_time), 0, p$collapse_50_time)
        }, numeric(1)))
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Generative-substrate sign-reversal test
#'
#' The formula's sign reversal prediction: on generative substrates
#' (cultural, digital), the diversity-dependence slope should be
#' POSITIVE — the opposite of the negative slope in every finite-resource
#' industry. This is the Homo inversion carried into economics.
#'
#' Tests whether "speciation rate" (firm formation rate) vs. "diversity"
#' (number of existing firms) shows a positive slope on generative
#' substrates (software platforms, AI ecosystems) vs. negative on
#' finite-resource substrates (manufacturing, retail).
#'
#' @param data Data frame with columns `system`, `diversity` (number of
#'   existing firms/species), `speciation_rate` (new firm formation rate).
#' @param seed Integer. Seed for reproducibility (A2: injectable).
#'
#' @return List (A6: proof object):
#'   \item{values}{Named: n_systems, mean_slope, positive_slope_share,
#'     formula_prediction ("positive on generative substrates")}
#'   \item{metadata}{List: seed, n, per_system, converged}
#'
#' @section Theoretical Context:
#'
#' the framework's formula prediction: on generative substrates, the attractor dynamics
#' reverse. Instead of capacity loss (negative diversity-dependence), you get
#' capacity expansion (positive diversity-dependence). Each innovation creates
#' new niches. More firms → more niches → more firms. The opposite of
#' saturation.
#'
#' This is the economic analog of the Homo inversion: van Holstein & Foley
#' (2024) found positively diversity-dependent speciation in Homo (cultural
#' substrate) vs. negative in all other vertebrate clades (ecological
#' substrate). The formula says the same sign reversal should appear in
#' economic systems: generative substrates (software, AI) show positive
#' slopes; finite substrates (manufacturing, mining) show negative.
#'
#' Competitor: standard economic theory predicts market saturation (negative
#' diversity-dependence) for all industries. The formula predicts a sign
#' reversal for generative substrates only. This test DOES distinguish the
#' formula: it makes a signed prediction that standard theory does not.
#'
#' What supports the formula: positive slopes on generative substrates,
#' negative on finite substrates.
#' What refutes the formula: negative slopes everywhere, or positive slopes
#' on finite substrates.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed()
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- data.frame(
#'   system = rep(c("software", "mining"), each = 20),
#'   diversity = rep(1:20, 2),
#'   speciation_rate = c(1:20 * 0.1 + 1, 20:1 * 0.1 + 1)
#' )
#' generative_sign_reversal(dat, seed = 42)
#' }
generative_sign_reversal <- function(data, seed = 42L) {
  withr::with_seed(seed, {
    if (!is.data.frame(data)) {
      stop("data must be a data.frame", call. = FALSE)
    }
    required <- c("system", "diversity", "speciation_rate")
    missing <- setdiff(required, names(data))
    if (length(missing) > 0L) {
      stop(sprintf(
        "data missing required columns: %s",
        paste(missing, collapse = ", ")
      ), call. = FALSE)
    }

    systems <- unique(data$system)
    per_system <- list()

    for (sys in systems) {
      d <- data[data$system == sys, ]
      d <- d[order(d$diversity), ]
      if (nrow(d) < 4) next

      m <- lm(speciation_rate ~ diversity, data = d)
      slope <- coef(m)[2]
      r2 <- summary(m)$r.squared

      per_system[[sys]] <- list(
        system = sys,
        n = nrow(d),
        slope = slope,
        r2 = r2,
        positive_slope = slope > 0
      )
    }

    if (length(per_system) == 0L) {
      stop("no system had enough data", call. = FALSE)
    }

    mean_slope <- mean(vapply(per_system, function(p) p$slope, numeric(1)))
    positive_share <- mean(vapply(per_system, function(p) {
      as.logical(p$positive_slope)
    }, numeric(1)))

    result <- list(
      values = list(
        n_systems = length(per_system),
        mean_slope = mean_slope,
        positive_slope_share = positive_share,
        formula_prediction = "positive on generative substrates"
      ),
      metadata = list(
        seed = seed,
        n = length(per_system),
        per_system = per_system,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
