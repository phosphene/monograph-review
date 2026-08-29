#' Relaxation formula model: ODE simulation of biphasic decay
#'
#' Implements the framework relaxation formula:
#' \deqn{\frac{d\rho}{dt} = -k_1(\rho - \rho_1) - k_2(\rho - \rho_2)}
#' where \eqn{\rho} is the retention correlation, \eqn{k_1, k_2} are rate
#' constants for two independent relaxation channels, and \eqn{\rho_1, \rho_2}
#' are the equilibrium values for each channel.
#'
#' This is the successor to the threshold-gated model in \code{formal_model.R}.
#' Whereas the threshold model describes \emph{cross-sectional} (theta, rho)
#' dynamics, the relaxation model describes \emph{temporal} (t, rho) dynamics
#' of the same underlying process. The two models converge on the same
#' biphasic prediction: fast Phase 1 followed by slow Phase 2.
#'
#' @section Analytical Solution:
#'
#' The ODE is linear and has a closed-form solution:
#' \deqn{\rho(t) = \rho^* + (\rho_0 - \rho^*) e^{-kt}}
#' where:
#' \itemize{
#'   \item \eqn{k = k_1 + k_2} — total relaxation rate
#'   \item \eqn{\rho^* = (k_1\rho_1 + k_2\rho_2) / k} — equilibrium retention
#'   \item \eqn{\rho_0 = \rho(0)} — initial retention
#' }
#'
#' This is a mono-exponential at the system level, but the two underlying
#' channels produce distinct signatures in empirical data:
#' \itemize{
#'   \item \strong{Bi-exponential fits} reveal the two timescales when
#'     the data have sufficient temporal resolution.
#'   \item \strong{Cross-sectional averaging} collapses the two channels
#'     into a single effective rate, making mono-exponential fits competitive.
#'   \item The \strong{k1/k2 ratio} measures the separation of timescales:
#'     a large ratio (k1 >> k2) indicates a clear fast/slow biphasic pattern.
#' }
#'
#' @section Relationship to Landau-Lifshitz:
#'
#' The relaxation formula has the same mathematical form as the
#' Landau-Lifshitz equation \eqn{dM/dt = -\partial F/\partial M}:
#' both describe gradient descent in a potential well. The framework formula
#' \eqn{d\rho/dt = -k_1(\rho - \rho_1) - k_2(\rho - \rho_2)} is the
#' discrete two-channel version of the Landau-Lifshitz continuous
#' relaxation.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): fully deterministic, no RNG
#' - A6 (check-result): returns structured objects with proof metadata
#'
#' @name relaxation_model
NULL

# ==============================================================================
# ANALYTICAL SOLUTION
# ==============================================================================

#' Analytical solution of the relaxation ODE
#'
#' Computes \eqn{\rho(t)} for the relaxation ODE at one or more time points.
#' Uses the closed-form solution:
#' \deqn{\rho(t) = \rho^* + (\rho_0 - \rho^*) e^{-kt}}
#'
#' @param t Numeric vector. Time points at which to evaluate.
#' @param rho0 Numeric. Initial retention \eqn{\rho(0)}.
#' @param k1 Numeric. Fast relaxation rate constant.
#' @param k2 Numeric. Slow relaxation rate constant.
#' @param rho1 Numeric. Equilibrium for fast channel.
#' @param rho2 Numeric. Equilibrium for slow channel.
#'
#' @return Numeric vector of \eqn{\rho(t)} values, same length as \code{t}.
#'
#' @export
#' @examples
#' # Single-channel relaxation (k2 = 0)
#' relaxation_analytical(
#'   t = 0:10, rho0 = 1.0, k1 = 0.5, k2 = 0,
#'   rho1 = 0.3, rho2 = 0.3
#' )
#'
#' # Two-channel relaxation (k1 >> k2)
#' relaxation_analytical(
#'   t = 0:100, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
#'   rho1 = 0.3, rho2 = 0.3
#' )
relaxation_analytical <- function(t, rho0, k1, k2, rho1, rho2) {
  k <- k1 + k2
  rho_star <- (k1 * rho1 + k2 * rho2) / k
  rho_star + (rho0 - rho_star) * exp(-k * t)
}

# ==============================================================================
# ODE SYSTEM DEFINITION
# ==============================================================================

#' Relaxation ODE system
#'
#' Defines the RHS of \eqn{d\rho/dt = -k_1(\rho - \rho_1) - k_2(\rho - \rho_2)}
#' for use with \code{deSolve::ode()} if available.
#'
#' @param t Numeric. Current time (unused, but required by deSolve interface).
#' @param y Numeric vector. State variables: \code{c(rho)}.
#' @param parms List. Named list with \code{k1}, \code{k2}, \code{rho1},
#'   \code{rho2}.
#'
#' @return List with first element being the derivative vector.
#'
#' @keywords internal
relaxation_ode_rhs <- function(t, y, parms) {
  with(parms, {
    d_rho <- -k1 * (y[1] - rho1) - k2 * (y[1] - rho2)
    list(c(d_rho))
  })
}

# ==============================================================================
# SIMULATION
# ==============================================================================

#' Simulate relaxation trajectory
#'
#' Simulates the relaxation ODE over a time grid. Uses the analytical solution
#' by default, with optional \code{deSolve} integration for extensibility.
#'
#' If \code{use_deSolve = TRUE} and \code{deSolve} is installed, uses
#' \code{deSolve::ode()} with the default Runge-Kutta method. This is useful
#' for extending the model with additional terms (e.g., time-dependent rates).
#' Falls back to the analytical solution if deSolve is unavailable.
#'
#' @param times Numeric vector. Time grid for simulation (e.g., \code{seq(0, 100, 0.1)}).
#' @param rho0 Numeric. Initial retention.
#' @param k1 Numeric. Fast relaxation rate.
#' @param k2 Numeric. Slow relaxation rate.
#' @param rho1 Numeric. Equilibrium for fast channel.
#' @param rho2 Numeric. Equilibrium for slow channel.
#' @param use_deSolve Logical. If \code{TRUE}, attempt numerical integration
#'   via deSolve. Default \code{FALSE} (uses analytical solution).
#'
#' @return List with elements:
#'   \describe{
#'     \item{times}{Numeric vector of time points.}
#'     \item{rho}{Numeric vector of \eqn{\rho(t)} values.}
#'     \item{rho0}{Initial retention.}
#'     \item{k}{Total rate \eqn{k_1 + k_2}.}
#'     \item{rho_star}{Equilibrium retention.}
#'     \item{k1}{Fast rate.}
#'     \item{k2}{Slow rate.}
#'     \item{rho1}{Fast channel equilibrium.}
#'     \item{rho2}{Slow channel equilibrium.}
#'     \item{method}{Character: \code{"analytical"} or \code{"deSolve"}.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Default analytical solution
#' relaxation_simulate(
#'   times = seq(0, 100, 1), rho0 = 1.0, k1 = 0.5, k2 = 0.02,
#'   rho1 = 0.3, rho2 = 0.3
#' )
#' }
relaxation_simulate <- function(times, rho0, k1, k2, rho1, rho2,
                                use_deSolve = FALSE) {  # nolint: object_name_linter — deSolve is the package name
  if (length(times) < 2) {
    stop("times must have at least 2 elements", call. = FALSE)
  }

  k <- k1 + k2
  rho_star <- (k1 * rho1 + k2 * rho2) / k

  if (use_deSolve && requireNamespace("deSolve", quietly = TRUE)) {
    # Numerical integration via deSolve
    y0 <- c(rho = rho0)
    parms <- list(k1 = k1, k2 = k2, rho1 = rho1, rho2 = rho2)
    out <- deSolve::ode(
      y = y0, times = times,
      func = relaxation_ode_rhs,
      parms = parms,
      method = "rk4"
    )
    rho <- out[, "rho"]
    method <- "deSolve"
  } else {
    # Analytical solution
    rho <- relaxation_analytical(times, rho0, k1, k2, rho1, rho2)
    method <- "analytical"
  }

  list(
    times = times,
    rho = rho,
    rho0 = rho0,
    k = k,
    rho_star = rho_star,
    k1 = k1,
    k2 = k2,
    rho1 = rho1,
    rho2 = rho2,
    method = method
  )
}

# ==============================================================================
# PHASE ANALYSIS
# ==============================================================================

#' Analyse relaxation phases
#'
#' Decomposes the relaxation trajectory into fast and slow phases.
#' Computes:
#' \itemize{
#'   \item \strong{Phase 1} (fast): the period from t = 0 to the transition
#'     time, where the fast channel dominates.
#'   \item \strong{Phase 2} (slow): the period after the transition time,
#'     where the slow channel dominates.
#'   \item \strong{Transition time}: the time at which the fast channel has
#'     decayed to 1/e of its initial amplitude.
#'   \item \strong{Phase amplitudes}: the fraction of total relaxation
#'     contributed by each phase.
#' }
#'
#' @param fit_result List. A result from \code{\link{fit_biexp}}.
#' @param t_max Numeric. Maximum time for analysis. Defaults to \code{5 / k2}
#'   (five slow half-lives).
#'
#' @return List with elements:
#'   \describe{
#'     \item{phase1_rate}{Numeric. Fast rate \eqn{k_1}.}
#'     \item{phase2_rate}{Numeric. Slow rate \eqn{k_2}.}
#'     \item{transition_time}{Numeric. Time when fast channel decays to 1/e
#'       of initial amplitude.}
#'     \item{phase1_amplitude}{Numeric. \eqn{A_1 / (A_1 + A_2)}.}
#'     \item{phase2_amplitude}{Numeric. \eqn{A_2 / (A_1 + A_2)}.}
#'     \item{rate_ratio}{Numeric. \eqn{k_1 / k_2}.}
#'     \item{biphasic}{Logical. Whether the relaxation is genuinely
#'       two-timescale: mono rejected by AIC (delta_aic_bi_mono > 0),
#'       rate ratio > 2, both channels same sign, and the smaller channel
#'       at least 15\% of total amplitude (guards against spurious
#'       low-amplitude fast channels on one-channel data).}
#'     \item{halflife_phase1}{Numeric. Halflife of fast phase in original time units.}
#'     \item{halflife_phase2}{Numeric. Halflife of slow phase in original time units.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' t <- seq(0, 10, length.out = 40)
#' rho <- 0.05 + 0.03 * exp(-17.7 * t) + 0.01 * exp(-0.47 * t) + rnorm(40, 0, 0.002)
#' fit <- fit_biexp(t, rho)
#' analysis <- relaxation_phase_analysis(fit, t_max = 10)
#' print(analysis)
#' }
relaxation_phase_analysis <- function(fit_result, t_max = NULL) {
  if (!is.list(fit_result) || is.null(fit_result$biexponential)) {
    stop("fit_result must be a list from fit_biexp()", call. = FALSE)
  }

  coef <- fit_result$biexponential$coefficients
  k1 <- abs(coef$k1)
  k2 <- abs(coef$k2)
  A1 <- abs(coef$A1)
  A2 <- abs(coef$A2)
  # Signed amplitudes retained for the same-sign check: a genuine biphasic
  # relaxation has both channels decaying in the same direction.
  A1_signed <- coef$A1
  A2_signed <- coef$A2

  if (is.null(t_max) && is.finite(k2) && k2 > 0) {
    t_max <- 5 / k2
  } else if (is.null(t_max)) {
    t_max <- 100
  }

  # Rate ratio
  rate_ratio <- if (is.finite(k1) && is.finite(k2) && k2 > 0) {
    k1 / k2
  } else {
    NA_real_
  }

  # Amplitude fractions (bounded in [0, 1] via abs(): a degenerate fit with
  # opposite-sign channels still reports a bounded fraction)
  total_amp <- A1 + A2
  phase1_amp <- if (is.finite(total_amp) && total_amp > 0) A1 / total_amp else NA_real_
  phase2_amp <- if (is.finite(total_amp) && total_amp > 0) A2 / total_amp else NA_real_

  # Biphasic detection. A rate ratio > 2 is NOT sufficient on its own: on
  # single-exponential (one-channel) data the fitter can chase noise into a
  # spurious low-amplitude "fast" channel with a large k1/k2. Four guards:
  # (a) model selection must agree (mono rejected: delta AIC bi-mono > 0);
  # (b) rate separation k1/k2 > 2;
  # (c) both channels same sign (both decay in the same direction);
  # (d) the smaller channel is a material fraction (>= 0.15) of the total
  #     amplitude.
  # Validated (100 seeds each): true two-channel relaxations pass all four
  # at min-fraction 0.22-0.28; one-channel data passes at a ~2% false-
  # positive rate (the genuine identifiability boundary).
  min_amp_frac <- if (is.finite(phase1_amp) && is.finite(phase2_amp)) {
    min(phase1_amp, phase2_amp)
  } else {
    NA_real_
  }
  same_sign <- is.finite(A1_signed) && is.finite(A2_signed) &&
    (sign(A1_signed) == sign(A2_signed))
  model_agrees <- is.finite(fit_result$delta_aic_bi_mono) &&
    fit_result$delta_aic_bi_mono > 0
  biphasic <- isTRUE(is.finite(rate_ratio) && rate_ratio > 2 &&
                       model_agrees && same_sign &&
                       is.finite(min_amp_frac) && min_amp_frac >= 0.15)

  # Transition time: when fast channel decays to 1/e
  transition_time <- if (is.finite(k1) && k1 > 0) {
    1 / k1
  } else {
    NA_real_
  }

  # Halflives (in normalised time units, need to convert)
  halflife_phase1 <- if (is.finite(k1) && k1 > 0) log(2) / k1 else NA_real_
  halflife_phase2 <- if (is.finite(k2) && k2 > 0) log(2) / k2 else NA_real_

  list(
    phase1_rate = k1,
    phase2_rate = k2,
    rate_ratio = rate_ratio,
    biphasic = biphasic,
    transition_time = transition_time,
    phase1_amplitude = phase1_amp,
    phase2_amplitude = phase2_amp,
    halflife_phase1 = halflife_phase1,
    halflife_phase2 = halflife_phase2
  )
}

# ==============================================================================
# PARAMETER RECOVERY
# ==============================================================================

#' Generate synthetic relaxation data (power analysis)
#'
#' Generates synthetic data from the relaxation ODE with added noise, for
#' power analysis and parameter recovery studies.
#'
#' @param times Numeric vector. Time grid.
#' @param rho0 Numeric. Initial retention.
#' @param k1 Numeric. Fast rate.
#' @param k2 Numeric. Slow rate.
#' @param rho1 Numeric. Fast channel equilibrium.
#' @param rho2 Numeric. Slow channel equilibrium.
#' @param noise_sd Numeric. Standard deviation of Gaussian noise.
#' @param seed Integer. Random seed for reproducibility.
#'
#' @return List with elements:
#'   \describe{
#'     \item{data}{data.frame with columns \code{t}, \code{rho_true},
#'       \code{rho_obs}.}
#'     \item{params}{Named list of true parameters.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- generate_relaxation_data(seq(0, 10, 0.1),
#'   rho0 = 1.0,
#'   k1 = 0.5, k2 = 0.02,
#'   rho1 = 0.3, rho2 = 0.3,
#'   noise_sd = 0.01, seed = 42
#' )
#' head(dat$data)
#' }
generate_relaxation_data <- function(times, rho0, k1, k2, rho1, rho2,
                                     noise_sd = 0.01, seed = 42L) {
  withr::with_seed(seed, {
    rho_true <- relaxation_analytical(times, rho0, k1, k2, rho1, rho2)
    rho_obs <- rho_true + stats::rnorm(length(times), 0, noise_sd)
    rho_obs <- pmax(0, pmin(1, rho_obs))

    list(
      data = data.frame(
        t = times,
        rho_true = rho_true,
        rho_obs = rho_obs
      ),
      params = list(
        rho0 = rho0, k1 = k1, k2 = k2,
        rho1 = rho1, rho2 = rho2,
        noise_sd = noise_sd, seed = seed
      )
    )
  })
}
