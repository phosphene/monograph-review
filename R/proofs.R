#' Mathematical Proof Functions
#'
#' Pure analytical + numeric proofs (DFT axioms A1 pure-io-separation, A2
#' determinism, A6 check-result) for the dynamics module. Each returns a
#' \code{valence_proof} object carrying the statement, a LaTeX-like derivation,
#' an outcome, a logical verification flag, and a numeric corroboration.
#'
#' The proofs establish the mathematical backbone of three empirical tests:
#' \itemize{
#'   \item \strong{cusp catastrophe} — the bifurcation set \eqn{4a^3+27b^2=0}
#'     and the hysteresis loop area;
#'   \item \strong{autocatalytic growth} — positive diversity-dependence and
#'     boundedness of the per-capita rate;
#'   \item \strong{economics} — monotone option-value decay in commitment.
#' }
#'
#' @name proofs
NULL

# -----------------------------------------------------------------------------
# Number of real roots of the cusp cubic x^3 + a x + b = 0
# -----------------------------------------------------------------------------
.cusp_real_real_roots <- function(a, b) {
  roots <- polyroot(c(b, a, 0, 1))
  Re(roots)[abs(Im(roots)) < 1e-8]
}

# -----------------------------------------------------------------------------
# Outer (stable) branch separation x_hi(b) - x_lo(b) for a < 0, |b| < bcrit.
# -----------------------------------------------------------------------------
.cusp_branch_separation <- function(b, a) {
  roots <- sort(.cusp_real_real_roots(a, b))
  if (length(roots) < 2L) return(0)
  # Outer two real roots bound the bistable branch gap.
  max(roots) - min(roots)
}

#' Prove the cusp catastrophe bifurcation set
#'
#' Analytical proof for the cusp catastrophe equilibrium \eqn{x^3+ax+b=0}:
#' \itemize{
#'   \item For \eqn{a>0}: the cubic discriminant \eqn{\Delta=-4a^3-27b^2<0},
#'     so there is exactly \strong{1} real root — no bifurcation.
#'   \item For \eqn{a<0} and \eqn{|b|<b_{\\mathrm{crit}}}, where
#'     \eqn{b_{\\mathrm{crit}} = \\frac{2}{3\\sqrt{3}}(-a)^{3/2}},
#'     there are \strong{3} real roots — the bistable (cusp) regime.
#'   \item The bifurcation set where the regime switches is
#'     \eqn{4a^3+27b^2=0}.
#' }
#'
#' The numeric check counts the real roots of the cubic via the companion-matrix
#' eigenvalue routine; verification succeeds when the count matches theory.
#'
#' @param a Numeric. Cubic coefficient \eqn{a}.
#' @param b Numeric. Cubic coefficient \eqn{b}.
#'
#' @return A \code{valence_proof} object.
#'
#' @section Theoretical Context:
#'
#' The discriminant of \eqn{x^3+px+q} is \eqn{\Delta=-4p^3-27q^2}; here
#' \eqn{p=a}, \eqn{q=b}. Because \eqn{a>0 \\Rightarrow a^3>0}, we have
#' \eqn{-4a^3<0} and \eqn{-27b^2\\le 0}, hence \eqn{\Delta<0} (one real root).
#' When \eqn{a<0}, \eqn{-4a^3>0}, so \eqn{\Delta>0} precisely when
#' \eqn{27b^2 < -4a^3}, i.e. \eqn{|b|<b_{\\mathrm{crit}}}: three real roots.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' prove_cusp_bifurcation(a = -1, b = 0.2)
#' prove_cusp_bifurcation(a = 1, b = 0.2)
#' }
prove_cusp_bifurcation <- function(a, b) {
  if (!is.numeric(a) || length(a) != 1L || !is.finite(a)) {
    stop("a must be a single finite numeric", call. = FALSE)
  }
  if (!is.numeric(b) || length(b) != 1L || !is.finite(b)) {
    stop("b must be a single finite numeric", call. = FALSE)
  }

  crit_b <- if (a < 0) (2 / (3 * sqrt(3))) * (-a)^(3 / 2) else 0
  n_real <- length(.cusp_real_real_roots(a, b))

  statement <- paste0(
    "The equilibrium x^3 + a*x + b = 0 has 1 real root when a > 0, ",
    "and 3 real roots (bifurcation regime) when a < 0 and |b| < b_crit, ",
    "with bifurcation set 4*a^3 + 27*b^2 = 0."
  )

  derivation <- paste0(
    "Discriminant of x^3 + p*x + q is  D = -4*p^3 - 27*q^2, with p = a, q = b.\n",
    "  =>  D(a,b) = -4*a^3 - 27*b^2.\n",
    "Case a > 0:  -4*a^3 < 0 and -27*b^2 <= 0, so D < 0  (exactly one real root).\n",
    "Case a < 0:  -4*a^3 > 0.  D > 0  <=>  27*b^2 < -4*a^3\n",
    "  <=>  |b| < sqrt(-4*a^3/27) = 2/(3*sqrt(3)) * (-a)^(3/2) = b_crit.\n",
    "At |b| = b_crit the cubic has a double root: the bifurcation set is\n",
    "  4*a^3 + 27*b^2 = 0."
  )

  # Theory & numeric agreement.
  expected <- if (a > 0) 1L else if (a < 0 && abs(b) < crit_b) 3L else 1L
  verified <- isTRUE(n_real == expected)

  Valence_proof(
    statement = statement,
    derivation = derivation,
    result = "QED",
    verified = verified,
    numeric_check = n_real
  )
}

#' Prove the cusp hysteresis loop area
#'
#' Analytical proof that a cusp (\eqn{a<0}, control swept through the
#' bistable region) encloses a \emph{positive} hysteresis loop area equal to
#' \deqn{A = \\int_{-b_{\\mathrm{crit}}}^{b_{\\mathrm{crit}}}
#'   \\big(x_{\\mathrm{hi}}(b) - x_{\\mathrm{lo}}(b)\\big)\\,db}
#' where \eqn{x_{\\mathrm{hi}},x_{\\mathrm{lo}}} are the two outer real roots
#' of \eqn{x^3+ax+b}. This analytic integral is compared against the
#' trapezoid-rule loop area recovered from the numerical forward/reverse
#' sweep ([hysteresis_loop_area()]).
#'
#' @param a Numeric. Cusp coefficient \eqn{a} (must be \eqn{< 0} for a loop).
#' @param control_range Numeric vector of length 2. Control (b) sweep range.
#' @param n Integer. Number of control points for the numeric sweep.
#' @param tol Numeric. Relative tolerance between analytic and numeric area.
#'
#' @return A \code{valence_proof} object.
#'
#' @section Theoretical Context:
#'
#' Forward and reverse branch following trace the upper and lower stable
#' branches respectively; the enclosed region between them has area given by
#' the integral of the branch separation. The numeric integration returns
#' \eqn{0} when \eqn{a>0} (no hysteresis) and a positive value when
#' \eqn{a<0} and the sweep crosses the cusp. Verification requires the
#' analytic and numeric areas to agree to the given relative tolerance.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' prove_hysteresis_loop_area(a = -1, control_range = c(-2, 2), n = 200)
#' }
prove_hysteresis_loop_area <- function(a = -1, control_range = c(-2, 2),
                                       n = 200L, tol = 0.05) {
  if (!is.numeric(a) || length(a) != 1L || !is.finite(a)) {
    stop("a must be a single finite numeric", call. = FALSE)
  }
  if (!is.numeric(control_range) || length(control_range) != 2L) {
    stop("control_range must be a numeric vector of length 2", call. = FALSE)
  }
  if (control_range[1] >= control_range[2]) {
    stop("control_range must be increasing", call. = FALSE)
  }

  eq_fn <- make_cusp_equilibrium_fn(a = a)
  cv <- seq(control_range[1], control_range[2], length.out = n)
  num <- hysteresis_loop_area(cv, eq_fn, seed = 42L)
  numeric_area <- num$values$loop_area

  # Analytic area: integrate the outer-root separation over the bistable b-range.
  analytic_area <- 0
  if (a < 0) {
    bcrit <- (2 / (3 * sqrt(3))) * (-a)^(3 / 2)
    lo <- max(control_range[1], -bcrit)
    hi <- min(control_range[2], bcrit)
    if (hi > lo) {
      analytic_area <- stats::integrate(
        function(b) .cusp_branch_separation(b, a),
        lower = lo, upper = hi, subdivisions = 200L
      )$value
    }
  }

  has_loop <- (a < 0) && (numeric_area > 0)
  agreement <- if (numeric_area > 0) {
    abs(numeric_area - analytic_area) / max(numeric_area, 1e-12) <= tol
  } else {
    analytic_area == 0
  }
  verified <- has_loop && agreement && isTRUE(numeric_area >= 0)

  statement <- paste0(
    "The cusp (a < 0) encloses a positive hysteresis loop with area ",
    "A = integral of (x_hi - x_lo) over the bistable b-range; a > 0 gives ",
    "loop area 0. Numeric trapezoid area matches the analytic area."
  )

  derivation <- paste0(
    "Forward sweep follows upper stable branch x_hi(b), reverse the lower x_lo(b).\n",
    "Branch separation at b:  x_hi(b) - x_lo(b) = [largest - smallest real root].\n",
    "The roots coalesce at b = +/- b_crit (saddle-node), so the separation is 0\n",
    "at both ends and the enclosed area is finite:\n",
    "  A = int_{-b_crit}^{b_crit} (x_hi(b) - x_lo(b)) db.\n",
    sprintf("Numeric (trapezoid) area = %.6g ;  Analytic area = %.6g.",
            numeric_area, analytic_area)
  )

  Valence_proof(
    statement = statement,
    derivation = derivation,
    result = "QED",
    verified = verified,
    numeric_check = numeric_area
  )
}

#' Prove positive diversity-dependence of autocatalytic growth
#'
#' Analytical proof that for autocatalytic growth
#' \deqn{\\frac{dN}{dt} = r\\,N\\left(\\frac12 + \\frac12 \\frac{N}{N+K}\\right)}
#' the per-capita rate \eqn{f(N)=r\\left(\\frac12+\\frac12\\frac{N}{N+K}\\right)}
#' is monotonically \emph{increasing} in \eqn{N}:
#' \deqn{\\frac{df}{dN} = \\frac{r K}{2(N+K)^2} > 0\\quad(N>0)}
#' — in contrast to logistic growth, whose per-capita rate
#' \eqn{r(1-N/K)} \emph{decreases} (\eqn{df/dN = -r/K < 0}).
#'
#' @param r Numeric. Intrinsic growth rate (\eqn{>0}).
#' @param K Numeric. Saturation constant (\eqn{>0}).
#' @param N_max Numeric. Upper end of the diversity grid.
#' @param n_grid Integer. Number of grid points.
#'
#' @return A \code{valence_proof} object.
#'
#' @section Theoretical Context:
#'
#' Positive diversity-dependence (the Homo inversion) is the empirical
#' signature of autocatalytic cultural growth: the per-capita innovation rate
#' \emph{rises} as diversity accumulates. Standard niche-filling predicts the
#' opposite (a decreasing per-capita rate, logistic). The numeric check is the
#' minimal finite-difference slope of \eqn{f} over a grid of \eqn{N>0}: the
#' proof verifies it is strictly positive for autocatalytic and strictly
#' negative for the logistic comparator.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' prove_dd_sign(r = 1, K = 10, N_max = 50, n_grid = 100)
#' }
prove_dd_sign <- function(r = 1, K = 10, N_max = 50, n_grid = 100L) {
  if (!is.numeric(r) || length(r) != 1L || r <= 0) {
    stop("r must be a single positive numeric", call. = FALSE)
  }
  if (!is.numeric(K) || length(K) != 1L || K <= 0) {
    stop("K must be a single positive numeric", call. = FALSE)
  }

  NN <- seq(1e-6, N_max, length.out = n_grid)
  f <- r * (0.5 + 0.5 * NN / (NN + K))
  finite_diff <- diff(f) / diff(NN)

  # Logistic comparator per-capita rate.
  g <- r * (1 - NN / K)
  g_diff <- diff(g) / diff(NN)

  min_df <- min(finite_diff)
  max_dg <- max(g_diff)
  verified <- isTRUE(min_df > 0) && isTRUE(max_dg < 0)

  statement <- paste0(
    "For dN/dt = r*N*(1/2 + 1/2*N/(N+K)), the per-capita rate f(N) is ",
    "monotonically increasing (df/dN = rK/[2(N+K)^2] > 0), opposite to ",
    "logistic per-capita rate r*(1 - N/K), whose df/dN = -r/K < 0."
  )

  derivation <- paste0(
    "Per-capita rate of autocatalytic growth:\n",
    "  f(N) = r*(1/2 + 1/2 * N/(N+K)).\n",
    "Derivative (product/quocient rule, r, K constant):\n",
    "  df/dN = r * 1/2 * d/dN[N/(N+K)]\n",
    "        = r * 1/2 * [(N+K) - N]/(N+K)^2\n",
    "        = rK / (2*(N+K)^2)  > 0   for N > 0, K > 0.\n",
    "Logistic per-capita rate:\n",
    "  g(N) = r*(1 - N/K)   =>   dg/dN = -r/K < 0.\n",
    sprintf("Numeric: min(delta f/delta N) = %.6g ; max(delta g/delta N) = %.6g.",
            min_df, max_dg)
  )

  Valence_proof(
    statement = statement,
    derivation = derivation,
    result = "QED",
    verified = verified,
    numeric_check = min_df
  )
}

#' Prove the autocatalytic growth rate is bounded and rises 0.5r -> r
#'
#' For the autocatalytic per-capita rate
#' \eqn{f(N)=r\\left(\\frac12+\\frac12\\frac{N}{N+K}\\right)}:
#' \itemize{
#'   \item At \eqn{N=0}: \eqn{f(0)=r/2} (the "seed" rate).
#'   \item As \eqn{N\\to\\infty}: \eqn{f(N)\\to r} — the rate saturates at \eqn{r}.
#'   \item \eqn{f} is bounded above by \eqn{r} and below by \eqn{r/2}: no
#'     blow-up; growth is globally bounded.
#' }
#'
#' @param r Numeric. Intrinsic growth rate (\eqn{>0}).
#' @param K Numeric. Saturation constant (\eqn{>0}).
#' @param N_max Numeric. Upper end of the diversity grid.
#' @param n_grid Integer. Number of grid points.
#'
#' @return A \code{valence_proof} object.
#'
#' @section Theoretical Context:
#'
#' Boundedness precludes the "explosive" failure mode of a naive positive
#' feedback term. The rate interpolates between \eqn{r/2} and \eqn{r}, giving
#' early sub-ratal acceleration (superlinear counts) that later flattens to
#' linear-in-diversity — matching the empirics of accelerating-but-doomed
#' innovation systems. The numeric check reports the asymptotic rate
#' \eqn{r} and confirms the grid maximum never exceeds \eqn{r}.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' \dontrun{
#' prove_autocatalytic_growth_rate(r = 1, K = 10, N_max = 5000, n_grid = 200)
#' }
prove_autocatalytic_growth_rate <- function(r = 1, K = 10, N_max = 5000,
                                            n_grid = 200L) {
  if (!is.numeric(r) || length(r) != 1L || r <= 0) {
    stop("r must be a single positive numeric", call. = FALSE)
  }
  if (!is.numeric(K) || length(K) != 1L || K <= 0) {
    stop("K must be a single positive numeric", call. = FALSE)
  }

  NN <- seq(1e-9, N_max, length.out = n_grid)
  f <- r * (0.5 + 0.5 * NN / (NN + K))
  f0 <- r * 0.5                    # seed rate at N = 0
  fmax_grid <- max(f)              # observed grid maximum
  bounded_above <- isTRUE(fmax_grid <= r + 1e-9)
  bounded_below <- isTRUE(min(f) >= f0 - 1e-9)
  # The rate must rise from the seed value toward the asymptote r: require it
  # to reach a large (>=90%) fraction of r at the top of the grid, and be
  # monotonically non-decreasing (a strictly-non-constant rise).
  monotone <- isTRUE(all(diff(f) >= 0))
  rising <- isTRUE(f[n_grid] >= 0.9 * r)
  verified <- bounded_above && bounded_below && monotone && rising

  statement <- paste0(
    "The autocatalytic per-capita rate f(N) = r*(1/2 + 1/2*N/(N+K)) ",
    "transitions monotonically from ~r/2 (low N) to r (high N) and is ",
    "bounded in [r/2, r]: growth cannot blow up."
  )

  derivation <- paste0(
    "f(N) = r*(1/2 + 1/2 * N/(N+K)).\n",
    "At N = 0:   f(0) = r*(1/2 + 0) = r/2.\n",
    "As N -> infty, N/(N+K) -> 1, so  f -> r*(1/2 + 1/2) = r.\n",
    "Because 0 <= N/(N+K) < 1, we have  r/2 <= f(N) < r  for all finite N.\n",
    "Hence f is increasing (proved in prove_dd_sign) and bounded above by r;\n",
    "the ODE grows at most linearly in N, so counts remain bounded in time.\n",
    sprintf("Numeric: f(0) = %.6g ; f(N_max) = %.6g ; grid max = %.6g (asymptote r = %.6g).",
            f0, f[n_grid], fmax_grid, r)
  )

  Valence_proof(
    statement = statement,
    derivation = derivation,
    result = "QED",
    verified = verified,
    numeric_check = f[n_grid]
  )
}

# Keep R CMD check happy about the auxiliary (non-exported) helpers.
utils::globalVariables(c("stats::integrate"))