#' Cusp catastrophe model for the framework irreversibility thresholds
#'
#' The cusp catastrophe describes a system where smooth changes in control
#' parameters produce sudden, irreversible jumps in state. The framework predicts that
#' capacity reallocation has this property — once a trait crosses the
#' protection threshold, recovery requires disproportionate effort.
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: irreversibility — substrate-shift creates a bifurcation
#' that is difficult to reverse. Competitor: gradual reversibility (standard
#' quantitative genetics predicts smooth recovery when selection pressure
#' is removed).
#'
#' @dft A1, A2, A6
#'
#' @name cusp_catastrophe
NULL

#' Compute the bifurcation point for the cusp catastrophe
#'
#' The cusp catastrophe has two control parameters (a, b) and the
#' bifurcation set is: |b| <= 2 × (a/3)^(3/2) / (27)^(1/2)
#' Simplified: bifurcation occurs when 4a³ + 27b² = 0
#'
#' @param a Numeric. First control parameter (splitting factor).
#' @param b Numeric. Second control parameter (normal factor).
#'
#' @return Numeric. 1 if at bifurcation point, 0 otherwise. Also returns
#'   the distance to the bifurcation set.
#' @export
cusp_bifurcation_point <- function(a, b) {
  # Distance from bifurcation set: 4a³ + 27b²
  # When this equals zero, we're at the bifurcation point
  distance <- 4 * a^3 + 27 * b^2

  at_bifurcation <- abs(distance) < 1e-6

  list(
    at_bifurcation = at_bifurcation,
    distance = distance,
    a = a,
    b = b
  )
}

#' Create a pure branch-following equilibrium function
#'
#' Returns a PURE function `(control_b, prev_state) -> next_state` that solves
#' the cusp equilibrium x^3 + a*x + b = 0 and returns the real root nearest
#' `prev_state` (branch-following). For single-root regions `prev_state` is
#' ignored. This function holds NO internal state — the branch-following
#' state is threaded by [cusp_hysteresis_check()], which makes the path-
#' dependence contract explicit (previously this was a stateful closure using
#' `<<-`, which hid the detection logic in the simulacrum; see math-review
#' Issue 4, resolved in Phase 3).
#'
#' @param a Numeric. First control parameter (splitting factor). For `a < 0`
#'   the system is in the cusp region (three real roots for some `b`);
#'   for `a >= 0` there is a single real root for all `b`.
#'
#' @return Function `(control_b, prev_state) -> numeric` (nearest stable root).
#'
#' @section Theoretical Context:
#'
#' the framework's prediction: irreversibility — the cusp catastrophe's fold bifurcation
#' produces path-dependent equilibria. For `a < 0`, the system has two stable
#' equilibria separated by an unstable one; crossing the bifurcation set
#' (`4a^3 + 27b^2 = 0`) forces a sudden jump to the other branch. The branch-
#' following contract makes this visible: a forward sweep (increasing `b`)
#' stays on one branch, while the reverse sweep (decreasing `b`) stays on
#' the other — producing hysteresis.
#'
#' Competitor: gradual reversibility (standard quantitative genetics predicts
#' smooth recovery when selection pressure is removed — no bifurcation, no
#' hysteresis).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' eq_fn <- make_cusp_equilibrium_fn(a = -1)
#' eq_fn(0.3, 1.0) # root nearest 1.0 (upper branch)
make_cusp_equilibrium_fn <- function(a = -1) {
  function(b, prev_state) {
    roots <- polyroot(c(b, a, 0, 1))
    real_roots <- Re(roots)[abs(Im(roots)) < 1e-10]
    if (length(real_roots) == 1) {
      real_roots[1]
    } else {
      # Pick the real root closest to the previous state (branch-following).
      real_roots[which.min(abs(real_roots - prev_state))]
    }
  }
}

#' Check for hysteresis (path dependence)
#'
#' the framework predicts that the forward path (increasing commitment) differs from
#' the reverse path (decreasing commitment) — this is the hallmark of
#' irreversibility in the cusp catastrophe.
#'
#' @section Branch-following contract:
#'
#' equilibrium_fn must be a PURE function `(control_value, prev_state) ->
#' next_state` that returns the stable equilibrium nearest `prev_state`
#' (branch-following). The branch-following state is threaded by THIS
#' function, not hidden inside a stateful closure — making the path-
#' dependence contract explicit. The reverse sweep starts from the forward
#' sweep's FINAL state (the standard hysteresis protocol: ramp up, then ramp
#' down from the top); in a multi-valued equilibrium (e.g. the cusp) the two
#' sweeps follow different branches, producing forward != reverse.
#'
#' @param control_values Numeric vector. Control parameter values to test.
#' @param equilibrium_fn Function(control_value, prev_state) -> next_state.
#'   Must be pure (no hidden state). See the contract above.
#' @param seed Integer. Seed for reproducibility.
#' @param initial_state Numeric. Starting state for the forward sweep.
#'   Default 0.
#'
#' @return List (A6): values (has_hysteresis, max_difference, n_control_values,
#'   forward_states, reverse_states, control_values), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
cusp_hysteresis_check <- function(control_values, equilibrium_fn, seed = 42L,
                                  initial_state = 0) {
  withr::with_seed(seed, {
    n <- length(control_values)

    # Forward sweep: increasing control, state threaded from initial_state.
    forward_states <- numeric(n)
    state <- initial_state
    for (i in seq_len(n)) {
      state <- equilibrium_fn(control_values[i], state)
      forward_states[i] <- state
    }

    # Reverse sweep: decreasing control, starting from the forward sweep's
    # FINAL state (ramp up, then ramp down from the top). In a multi-valued
    # equilibrium the reverse sweep follows a different branch than forward,
    # which is what produces path dependence.
    reverse_states <- numeric(n)
    for (i in seq_len(n)) {
      state <- equilibrium_fn(control_values[n - i + 1], state)
      reverse_states[i] <- state
    }

    # Hysteresis: forward != reverse at some control value.
    differences <- abs(forward_states - rev(reverse_states))
    has_hysteresis <- any(differences > 0.01, na.rm = TRUE)

    result <- list(
      values = list(
        has_hysteresis = has_hysteresis,
        max_difference = max(differences, na.rm = TRUE),
        n_control_values = n,
        forward_states = forward_states,
        reverse_states = reverse_states,
        control_values = control_values
      ),
      metadata = list(
        seed = seed,
        n = n,
        control_range = range(control_values),
        initial_state = initial_state,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
