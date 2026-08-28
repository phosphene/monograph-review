#' Autocatalytic set dynamics for post-substrate-shift regime
#'
#' After the substrate shift, valence predicts that innovations generate further
#' innovations faster than they are lost — positive diversity-dependence.
#' This is modeled via autocatalytic set theory (Kauffman style).
#'
#' @section Theoretical Context:
#'
#' valence Prediction: positive diversity-dependence in cultural substrate —
#' the Homo inversion (positively diversity-dependent speciation) is the
#' empirical signature. Competitor: standard niche-filling predicts
#' negatively diversity-dependent (logistic) growth.
#'
#' @dft A1, A2, A6
#'
#' @name autocatalytic_set
NULL

#' Check if an innovation set achieves autocatalytic closure
#'
#' An autocatalytic set is one where each innovation is catalyzed by at
#' least one other innovation in the set. Closure means the set is
#' self-sustaining.
#'
#' @param innovations Character vector. Names of innovations.
#' @param catalyst_matrix Logical matrix (n × n). catalyst_matrix[i,j] = TRUE
#'   if innovation i catalyzes innovation j.
#'
#' @return List (A6): values (achieves_closure, n_catalyzed, n_total), metadata.
#'
#' @dft A1, A6
#'
#' @export
autocatalytic_closure <- function(innovations, catalyst_matrix) {
  n <- length(innovations)

  if (!is.matrix(catalyst_matrix) || nrow(catalyst_matrix) != n ||
        ncol(catalyst_matrix) != n) {
    stop("catalyst_matrix must be n×n matching innovations length", call. = FALSE)
  }

  # Each innovation must be catalyzed by at least one other
  catalyzed_by <- apply(catalyst_matrix, 2, function(col) which(col))

  n_catalyzed <- sum(sapply(catalyzed_by, length) > 0)
  achieves_closure <- n_catalyzed == n

  result <- list(
    values = list(
      achieves_closure = achieves_closure,
      n_catalyzed = n_catalyzed,
      n_total = n,
      closure_fraction = n_catalyzed / n
    ),
    metadata = list(
      n = n,
      innovations = innovations,
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Compute diversity-dependence and growth-direction metrics
#'
#' For a time series of innovation counts, compute:
#' - growth_direction / growth_slope: whether counts increase over time (NOT
#'   diversity-dependence — just growth).
#' - is_superlinear: log-log slope > 1, a power-law proxy for accelerating
#'   growth (exploratory; conflates early acceleration with positive DD).
#' - diversity_dependence_slope / diversity_dependence_sign: the GENUINE
#'   diversity-dependence test — the slope of per-capita innovation rate
#'   (dN/dt)/N against diversity N. Positive = per-capita rate increases
#'   with N (the Homo inversion); negative = rate decreases with N
#'   (niche-filling, the competitor's model).
#'
#' @param innovation_counts Numeric vector. Innovation counts over time.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (growth_direction, growth_slope, growth_r_squared,
#'   log_log_slope, is_superlinear, diversity_dependence_slope,
#'   diversity_dependence_sign), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
diversity_dependence_sign <- function(innovation_counts, seed = 42L) {
  withr::with_seed(seed, {
    n <- length(innovation_counts)
    time <- seq_len(n)

    # Fit linear model: innovations ~ time. This measures GROWTH DIRECTION
    # (whether counts increase over time), NOT diversity-dependence. A system
    # can be growing (positive) yet negatively diversity-dependent (niche-
    # filling). The diversity-dependence test is below.
    mod <- lm(innovation_counts ~ time)
    slope <- unname(coef(mod)[2])
    r2 <- summary(mod)$r.squared

    # Test for superlinear (autocatalytic) dynamics
    # Log-log regression of innovations against time
    # Slope greater than 1 indicates superlinear dynamics. Use a small margin
    # above 1.0 so that exactly-linear data (true slope = 1) is not flagged
    # superlinear by floating-point noise in the regression estimate.
    log_mod <- lm(log(pmax(innovation_counts, 1)) ~ log(time))
    log_slope <- unname(coef(log_mod)[2])
    superlinear_margin <- 1e-6

    # Genuine diversity-dependence: per-capita innovation rate vs diversity N.
    # Positive DD (the Homo inversion) means the per-capita rate INCREASES
    # with N; negative DD (niche-filling) means it DECREASES. This is distinct
    # from growth_direction (whether counts increase over time) and from
    # is_superlinear (a power-law proxy that conflates early acceleration with
    # positive DD — logistic growth is superlinear early but negatively DD).
    if (n >= 3L) {
      n_prev <- innovation_counts[-n]  # nolint: object_name_linter.
      pc_rate <- diff(innovation_counts) / pmax(n_prev, .Machine$double.xmin)
      dd_fit <- lm(pc_rate ~ n_prev)  # nolint: object_name_linter.
      dd_slope <- unname(coef(dd_fit)[2])
    } else {
      dd_slope <- NA_real_
    }

    result <- list(
      values = list(
        growth_direction = ifelse(slope > 0, "positive", "negative"),
        growth_slope = slope,
        growth_r_squared = r2,
        log_log_slope = log_slope,
        is_superlinear = log_slope > 1.0 + superlinear_margin,
        diversity_dependence_slope = dd_slope,
        diversity_dependence_sign = ifelse(is.na(dd_slope), NA_character_,
          ifelse(dd_slope > 0, "positive", "negative")
        )
      ),
      metadata = list(
        seed = seed,
        n = n,
        time_range = range(time),
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
