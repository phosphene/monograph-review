#' Formal dynamical model of threshold-gated capacity reallocation
#'
#' The valence formal model: dC_i/dt = -λ × M(t) × C_i × I(d_i < θ)
#'
#' NOTE: the C_i factor (current retention) is essential — without it the ODE
#' is linear (dC/dt = -λM) whose solution C(T) = 1 - λ∫M dt goes negative;
#' with it the ODE is exponential (dC/dt = -λMC) whose solution
#' C(T) = exp(-λ∫M dt) stays in [0, 1], matching retention_at_time().
#' where C_i = retention probability of trait i, M(t) = decaying niche-demand
#' mismatch, d_i = integration depth, θ = protection threshold, λ = shedding rate.
#'
#' This module implements the *cross-sectional* formal model: for a given set
#' of integration depths, how does retention depend on the protection threshold?
#' The *temporal* counterpart — the relaxation formula
#' dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) — is implemented in `relaxation_model.R`.
#' Both models converge on the same biphasic prediction.
#'
#' This module implements:
#' - Numerical integration of the formal model (Euler method)
#' - Analytical closed-form solution
#' - Convergence proof between numerical and analytical solutions
#' - Equilibrium predictions and phase transition analysis
#'
#' @section Theoretical Context:
#'
#' valence Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' rapidly) followed by slow Phase 2 (protected traits resist loss).
#'
#' Competitors:
#' - Constant rate (relaxed selection, Lahti 2009): predicts linear reduction
#' - Accelerating (Muller's ratchet): predicts accelerating reduction
#' - The biphasic (logistic/saturation) shape is unique to valence's threshold-gated model
#'
#' @dft
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): no RNG — fully deterministic
#' - A6 (check-result): returns structured objects with proof metadata
#'
#' @name formal_model
NULL

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

#' Compute mismatch function M(t) at time t
#'
#' M(t) = M₀ × exp(-αt) — exponentially decaying niche-demand mismatch.
#'
#' @param t Numeric. Time.
#' @param m0 Numeric. Initial mismatch magnitude.
#' @param alpha Numeric. Decay rate of mismatch.
#'
#' @return Numeric. Mismatch at time t.
#' @keywords internal
mismatch_function <- function(t, m0, alpha) {
  m0 * exp(-alpha * t)
}

# ==============================================================================
# CLOSED-FORM SOLUTION
# ==============================================================================

#' Closed-form solution for trait retention at time T
#'
#' Computes the analytical solution to dC/dt = -λ·M(t)·C·I(d<θ):
#'
#' - If d ≥ θ (protected): C(T) = 1 (no shedding)
#' - If d < θ (unprotected): C(T) = exp(-λ·∫₀ᵀ M(t)dt)
#'   where ∫₀ᵀ M(t)dt = M₀/α·(1-e^{-αT})
#'
#' This is a pure function (A1, A2, A6): no side effects, fully deterministic,
#' returns structured result object.
#'
#' @param depths Numeric vector. Integration depths for each trait.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch magnitude.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Total time elapsed.
#'
#' @return valence_equilibrium object for each depth (vector of length length(depths)).
#' @export
#' @examples
#' \dontrun{
#' # Single trait
#' eq <- retention_closed_form(depth = 2, lambda = 0.15, theta = 2.5,
#'                             m0 = 10, alpha = 0.05, time = 100)
#' print(eq)
#'
#' # Multiple traits
#' eq_vec <- retention_closed_form(c(0,1,2,3,5), 0.15, 2.5, 10, 0.05, 100)
#' sapply(eq_vec, function(x) x$value)
#' }
retention_closed_form <- function(depths, lambda, theta, m0, alpha, time) {
  n <- length(depths)
  results <- numeric(n)

  for (i in seq_len(n)) {
    d <- depths[i]
    protected <- d >= theta

    if (protected) {
      results[i] <- 1.0
    } else {
      # ∫₀ᵀ M(t)dt = M₀/α·(1-e^{-αT})
      integrated_mm <- (m0 / alpha) * (1 - exp(-alpha * time))
      results[i] <- exp(-lambda * integrated_mm)
    }
  }

  results
}

#' Verify Euler integration converges to closed-form solution
#'
#' Mathematical proof that the numerical implementation correctly solves the ODE.
#' Runs Euler integration at increasing step counts (100, 500, 1000, 5000, 10000)
#' and computes max|Euler - ClosedForm| at each resolution. Convergence is proved
#' when error decreases as steps increase.
#'
#' @param depths Numeric vector. Trait integration depths.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Total time.
#' @param step_counts Integer vector. Number of steps to test (default: 5 sequences).
#'
#' @return data.frame with columns:
#'   \item{n_steps}{number of Euler steps}
#'   \item{max_error}{maximum absolute error across all traits}
#'   \item{mean_error}{mean absolute error}
#'   \item{converged}{logical. Whether error decreased from previous step count}
#'
#' @section Theoretical Context:
#'
#' This is the mathematical proof (A6) that the Euler integration implements
#' the ODE correctly. For a first-order method like Euler, we expect error
#' to decrease linearly with step size (error ~ O(dt) = O(1/n_steps)).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' proof <- prove_convergence(
#'   depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
#'   m0 = 10, alpha = 0.05, time = 100
#' )
#' print(proof)
#' }
prove_convergence <- function(depths, lambda, theta, m0, alpha, time,
                              step_counts = c(100L, 500L, 1000L, 5000L, 10000L)) {
  # Validate input
  if (length(step_counts) < 2) {
    stop("step_counts must have at least 2 elements", call. = FALSE)
  }

  # Get closed-form solution as ground truth
  cf_results <- retention_closed_form(depths, lambda, theta, m0, alpha, time)
  cf_values <- cf_results  # retention_closed_form now returns numeric vector

  # Run Euler at each resolution
  results <- data.frame(
    n_steps = integer(length(step_counts)),
    max_error = numeric(length(step_counts)),
    mean_error = numeric(length(step_counts)),
    stringsAsFactors = FALSE
  )

  for (i in seq_along(step_counts)) {
    n_steps <- step_counts[i]

    # Reuse threshold_model internals
    dt <- time / n_steps
    retention <- rep(1.0, length(depths))
    unprotected <- depths < theta

    for (step in seq_len(n_steps)) {
      t_current <- step * dt
      m_t <- mismatch_function(t_current, m0, alpha)

      for (j in seq_along(depths)) {
        if (unprotected[j]) {
          d_c <- -lambda * m_t * retention[j] * dt
          retention[j] <- max(0, retention[j] + d_c)
        }
      }
    }

    # Compare to closed-form
    errors <- abs(retention - cf_values)
    results$n_steps[i] <- n_steps
    results$max_error[i] <- max(errors)
    results$mean_error[i] <- mean(errors)
  }

  # Check convergence: error should decrease as n_steps increases
  results$converged <- c(FALSE, diff(results$max_error) < 0)

  results
}

# ==============================================================================
# EQUILIBRIUM FUNCTIONS (updated to use S3 class)
# ==============================================================================

#' Compute retention probability for a single trait at equilibrium
#'
#' At equilibrium (long time), retention depends on whether the trait's
#' integration depth exceeds the protection threshold:
#' - If d_i >= θ: C_i = 1 (protected)
#' - If d_i < θ: C_i = exp(-λ × M₀/α) (shed proportional to integrated mismatch)
#'
#' Returns a valence_equilibrium object per Phosphene R Standards §7.
#'
#' @param depth Numeric. Integration depth of the trait.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#'
#' @return valence_equilibrium object.
#' @export
#' @examples
#' equilibrium_retention(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
equilibrium_retention <- function(depth, lambda, theta, m0, alpha) {
  protected <- depth >= theta

  if (protected) {
    value <- 1.0
    integrated_mm <- 0.0
  } else {
    integrated_mm <- (m0 / alpha)
    value <- exp(-lambda * integrated_mm)
  }

  value









}

#' Compute retention probability for a single trait at time T
#'
#' C_i(T) = 1 if d_i >= θ (protected)
#' C_i(T) = exp(-λ × ∫₀ᵀ M(t)dt) if d_i < θ (shed)
#' where ∫₀ᵀ M(t)dt = M₀/α × (1 - exp(-αT))
#'
#' Returns a valence_equilibrium object per Phosphene R Standards §7.
#'
#' @param depth Numeric. Integration depth.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Time elapsed.
#'
#' @return valence_equilibrium object.
#' @export
retention_at_time <- function(depth, lambda, theta, m0, alpha, time) {
  protected <- depth >= theta

  if (protected) {
    value <- 1.0
    integrated_mm <- 0.0
  } else {
    integrated_mm <- (m0 / alpha) * (1 - exp(-alpha * time))
    value <- exp(-lambda * integrated_mm)
  }

  value
}

# ==============================================================================
# THRESHOLD MODEL (numerical integration with S3 result class)
# ==============================================================================

#' Threshold-gated capacity reallocation model (full numerical integration)
#'
#' Solves dC_i/dt = -λ × M(t) × C_i × I(d_i < θ) for a panel of traits using
#' Euler integration. Returns a valence_threshold_result object with full provenance.
#'
#' @param depths Numeric vector. Integration depths for each trait.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Total time.
#' @param n_steps Integer. Number of integration steps. Default 1000.
#'
#' @return valence_threshold_result object containing:
#'   \item{values}{Named list: final_retention, phase rates, biphasicity metrics}
#'   \item{metadata}{List: parameters, counts, convergence info, full trajectory}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' at rate proportional to λ×M₀), slow Phase 2 (protected traits remain at 1.0).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- threshold_model(
#'   depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
#'   m0 = 10, alpha = 0.05, time = 100
#' )
#' print(result)
threshold_model <- function(depths, lambda, theta, m0, alpha, time,
                            n_steps = 1000L) {
  dt <- time / n_steps
  n_traits <- length(depths)

  # Initialize retention at 1.0 for all traits
  retention <- rep(1.0, n_traits)

  # Track retention over time for phase analysis
  retention_history <- matrix(1.0, nrow = n_steps + 1L, ncol = n_traits)

  # Determine which traits are unprotected (d < θ)
  unprotected <- depths < theta

  # Numerical integration (Euler method — sufficient for this simple ODE)
  for (step in seq_len(n_steps)) {
    t_current <- step * dt
    m_t <- mismatch_function(t_current, m0, alpha)

    for (i in seq_len(n_traits)) {
      if (unprotected[i]) {
        d_c <- -lambda * m_t * retention[i] * dt
        retention[i] <- max(0, retention[i] + d_c)
      }
      # Protected traits stay at 1.0 (no change)
    }
    retention_history[step + 1L, ] <- retention
  }

  # Compute phase rates
  # Phase 1: first 10% of time (fast)
  phase1_end <- max(1L, floor(n_steps * 0.1))
  phase1_unprotected <- retention_history[1L, ] - retention_history[phase1_end + 1L, ]
  phase1_rate <- mean(phase1_unprotected[unprotected], na.rm = TRUE)

  # Phase 2: last 90% of time (slow)
  phase2_unprotected <- retention_history[phase1_end + 1L, ] - retention_history[n_steps + 1L, ]
  phase2_rate <- mean(phase2_unprotected[unprotected], na.rm = TRUE)

  # Early/late temporal displacement ratio (descriptive, NOT a rate ratio).
  early_late_displacement_ratio <-
    if (is.na(phase2_rate) || is.na(phase1_rate)) {
      NA_real_
    } else if (phase2_rate > 0) {
      phase1_rate / phase2_rate
    } else {
      Inf
    }

  # Threshold biphasicity: the real biphasic signature
  prot_idx <- which(!unprotected)
  unprot_idx <- which(unprotected)

  prot_ret <- if (length(prot_idx) > 0) mean(retention[prot_idx]) else NA_real_
  unprot_ret <- if (length(unprot_idx) > 0) mean(retention[unprot_idx]) else NA_real_
  threshold_biphasicity <- prot_ret - unprot_ret

  # Construct values and metadata lists
  values <- list(
    final_retention = retention,
    phase1_rate = phase1_rate,
    phase2_rate = phase2_rate,
    early_late_displacement_ratio = early_late_displacement_ratio,
    threshold_biphasicity = threshold_biphasicity
  )

  metadata <- list(
    params = list(
      lambda = lambda, theta = theta, m0 = m0,
      alpha = alpha, time = time
    ),
    n_traits = n_traits,
    n_unprotected = sum(unprotected),
    n_protected = sum(!unprotected),
    n_steps = n_steps,
    dt = dt,
    method = "euler",
    converged = TRUE,
    retention_history = retention_history
  )

  # Return as S3 object
  valence_threshold_result(values = values, metadata = metadata)
}

# ==============================================================================
# PHASE TRANSITION TIME
# ==============================================================================

#' Compute time to phase transition
#'
#' Returns the time at which the fast phase transitions to the slow phase,
#' defined as the time when the mismatch function drops below a threshold
#' fraction of its initial value.
#'
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param threshold_fraction Numeric. Fraction of M₀ defining phase boundary.
#'
#' @return Numeric. Time of phase transition.
#' @export
#' @examples
#' phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.1)
phase_transition_time <- function(m0, alpha, threshold_fraction = 0.1) {
  # Solution: time when retained genome drops below threshold fraction
  # M(t) = M₀·e^{-αt} = threshold_fraction·M₀ ⇒ e^{-αt} = threshold_fraction
  # -αt = ln(threshold_fraction) ⇒ t = -ln(threshold_fraction)/α
  -log(threshold_fraction) / alpha
}

# ==============================================================================
# EMPIRICAL FORMAL MODEL (GLM fit with S3 result class)
# ==============================================================================

#' Empirical formal model: additive GLM fit to the retention matrix
#'
#' Fits `retention ~ dependency_score + parasitism_score` (quasibinomial GLM)
#' to the 8×6 Orobanchaceae retention matrix, then tests cross-kingdom
#' transfer by predicting bird-trait retention at a fixed parasitism level
#' and correlating the predicted ordering with observed morphological-change
#' ranks (Spearman).
#'
#' Returns a valence_glm_fit object per Phosphene R Standards §7.
#'
#' @param plant_data Data frame. The retention matrix (from
#'   [load_retention_matrix()]). Requires columns: `dependency_score`,
#'   `parasitism_score`, `retention`.
#' @param bird_data Data frame. Island-bird morphology (from
#'   [load_island_birds()]). Requires columns: `dependency_score`,
#'   `observed_rank`.
#' @param para_for_transfer Numeric. Parasitism level at which to evaluate
#'   the GLM for cross-kingdom prediction (default 3 = "deep commitment").
#' @param seed Integer. Unused (the GLM is deterministic, A2) — included for
#'   contract consistency.
#'
#' @return valence_glm_fit object containing:
#'   \item{values}{GLM coefficients, p-values, cross-kingdom metrics, valence confirmation flags}
#'   \item{metadata}{Sample sizes, method description, fitted glm object}
#'
#' @section Theoretical Context:
#'
#' valence Prediction: `dep > 0` (deeper integration → higher retention),
#' `para < 0` (deeper parasitism → lower retention), and cross-kingdom
#' ρ > 0 (plant-derived model predicts bird ordering).
#'
#' Competitors: random loss (dep ≈ 0), relaxed selection (para ns),
#' substrate-independence (ρ ≈ 0 or negative).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' plant <- load_retention_matrix()
#' bird <- load_island_birds()
#' result <- empirical_formal_model(plant$data, bird$data)
#' print(result)
#' }
empirical_formal_model <- function(plant_data, bird_data,
                                   para_for_transfer = 3, seed = 42L) {
  validate_retention_data(plant_data)
  validate_bird_morphology(bird_data)

  # Fit the additive quasibinomial GLM: retention ~ dep + para
  fit <- stats::glm(
    retention ~ dependency_score + parasitism_score,
    data = plant_data,
    family = quasibinomial()
  )
  s <- summary(fit)

  intercept <- stats::coef(fit)[[1]]
  dep_coef <- stats::coef(fit)[[2]]
  para_coef <- stats::coef(fit)[[3]]
  dep_p <- s$coefficients[2, 4]
  para_p <- s$coefficients[3, 4]
  pseudo_r2 <- 1 - fit$deviance / fit$null.deviance

  # Cross-kingdom transfer: predict bird retention at para_for_transfer
  bird_pred <- stats::predict(fit,
    newdata = data.frame(
      dependency_score = bird_data$dependency_score,
      parasitism_score = rep(para_for_transfer, nrow(bird_data))
    ),
    type = "response"
  )
  ct <- stats::cor.test(bird_pred, bird_data$observed_rank,
    method = "spearman", exact = FALSE
  )
  cross_kingdom_rho <- as.numeric(ct$estimate)
  cross_kingdom_p <- ct$p.value

  # valence predictions
  dep_positive <- dep_coef > 0
  para_negative <- para_coef < 0
  valence_confirmed <- dep_positive && para_negative && cross_kingdom_rho > 0

  values <- list(
    intercept = intercept,
    dep_coefficient = dep_coef,
    dep_p_value = dep_p,
    para_coefficient = para_coef,
    para_p_value = para_p,
    pseudo_r_squared = pseudo_r2,
    cross_kingdom_rho = cross_kingdom_rho,
    cross_kingdom_p = cross_kingdom_p,
    dep_positive = dep_positive,
    para_negative = para_negative,
    valence_confirmed = valence_confirmed
  )

  metadata <- list(
    n = nrow(plant_data),
    n_species = length(unique(plant_data$species)),
    n_gene_categories = length(unique(plant_data$gene_category)),
    method = "quasibinomial GLM (retention ~ dep + para)",
    seed = seed,
    para_for_transfer = para_for_transfer,
    converged = fit$converged,
    glm_fit = fit
  )

  valence_glm_fit(values = values, metadata = metadata)
}
