#' Dynamics Module Result Classes (S3 three-layer pattern)
#'
#' Implements Phosphene R Standards §7: constructor → validator → helper
#' for the dynamics module of valence.foundry.
#'
#' The dynamics module models three phenomena:
#' \itemize{
#'   \item \strong{Autocatalytic set dynamics} — positive diversity-dependence
#'     (the Homo inversion): per-capita innovation rate \emph{increases} with
#'     diversity N.
#'   \item \strong{Cusp catastrophe} — hysteresis / irreversibility in a
#'     system tracking a bistable equilibrium x³ + ax + b = 0.
#'   \item \strong{Economics} — commitment-driven (CDI) option-value decay and
#'     stochastic CDI paths.
#' }
#'
#' All classes follow DFT axioms:
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): fully deterministic, no RNG
#' - A6 (check-result): returns structured objects with values + metadata
#'
#' The base class is \code{valence_dynamics_result}; each module adds a subclass
#' carrying that base in its class vector so the base S3 methods
#' (\code{print()}, \code{summary()}, \code{as.data.frame()}) dispatch
#' uniformly.
#'
#' @name dynamics_classes
NULL

# ==============================================================================
# VI_DYNAMICS_RESULT (BASE CLASS)
# ==============================================================================

#' Create valence_dynamics_result object (constructor)
#'
#' Bare-metal constructor — assigns the base class without validation. Used
#' internally by the validator and helper. No type checking; trusts the caller
#' to provide the correct structure.
#'
#' @param values List. Named list of numeric/logical module outputs.
#' @param metadata List. Named list with provenance (params, seed, converged...).
#' @param test_name Character. Name of the originating test / module.
#' @param discriminating Logical. Whether the result distinguishes valence from the
#'   competitor model (distinct sign or pattern predicted).
#' @param status Character. Outcome status: "pass", "fail", or "inconclusive".
#'
#' @return valence_dynamics_result object (unvalidated)
#' @keywords internal
new_valence_dynamics_result <- function(values, metadata, test_name, discriminating,
                                   status) {
  structure(
    list(
      values = values,
      metadata = metadata,
      test_name = test_name,
      discriminating = discriminating,
      status = status
    ),
    class = "valence_dynamics_result"
  )
}

#' Validate valence_dynamics_result object
#'
#' Schema checks for the base class: verifies all top-level fields are present
#' with the correct types.
#'
#' @param x valence_dynamics_result object to validate.
#'
#' @return Invisible \code{x} if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_dynamics_result <- function(x) {
  if (!is.list(x)) {
    stop("valence_dynamics_result must be a list", call. = FALSE)
  }

  required_top <- c("values", "metadata", "test_name", "discriminating", "status")
  missing <- setdiff(required_top, names(x))
  if (length(missing) > 0) {
    stop("Missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (!is.list(x$values)) {
    stop("values must be a list", call. = FALSE)
  }
  if (!is.list(x$metadata)) {
    stop("metadata must be a list", call. = FALSE)
  }
  if (!is.character(x$test_name) || length(x$test_name) != 1L) {
    stop("test_name must be a single character", call. = FALSE)
  }
  if (!is.logical(x$discriminating) || length(x$discriminating) != 1L) {
    stop("discriminating must be a single logical", call. = FALSE)
  }
  if (!is.character(x$status) || length(x$status) != 1L) {
    stop("status must be a single character", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for valence_dynamics_result
#'
#' Public API: combines constructor + validator. Base-class instantiation is
#' rare (subclasses are preferred) but permitted for generic dynamics results.
#'
#' @param values See \code{new_valence_dynamics_result()}.
#' @param metadata See \code{new_valence_dynamics_result()}.
#' @param test_name Character. Default "dynamics".
#' @param discriminating Logical. Default TRUE.
#' @param status Character. Default "pass".
#'
#' @return Validated valence_dynamics_result object.
#' @export
Valence_dynamics_result <- function(values, metadata, test_name = "dynamics",
                               discriminating = TRUE, status = "pass") {
  res <- new_valence_dynamics_result(values, metadata, test_name, discriminating, status)
  validate_valence_dynamics_result(res)
}

# ==============================================================================
# VI_AUTOCATALYTIC_RESULT CLASS
# ==============================================================================

#' Create valence_autocatalytic_result object (constructor)
#'
#' Bare-metal constructor for autocatalytic set dynamics results.
#'
#' @param values List. Named list with fields:
#'   \item{diversity_dependence_sign}{character. "positive" (Homo inversion)
#'     or "negative" (niche-filling).}
#'   \item{per_capita_rate}{numeric vector. Per-capita innovation rate across
#'     diversity N.}
#'   \item{n_species}{numeric. Number of species / diversity values.}
#'   \item{time_series}{numeric vector. Innovation counts over time.}
#' @param metadata List. Provenance.
#' @param test_name Character.
#' @param discriminating Logical.
#' @param status Character.
#'
#' @return valence_autocatalytic_result object (unvalidated)
#' @keywords internal
new_valence_autocatalytic_result <- function(values, metadata, test_name,
                                        discriminating, status) {
  structure(
    list(
      values = values, metadata = metadata, test_name = test_name,
      discriminating = discriminating, status = status
    ),
    class = c("valence_autocatalytic_result", "valence_dynamics_result")
  )
}

#' Validate valence_autocatalytic_result object
#'
#' @param x valence_autocatalytic_result object to validate.
#'
#' @return Invisible \code{x} if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_autocatalytic_result <- function(x) {
  validate_valence_dynamics_result(x)

  vals <- x$values
  required_vals <- c("diversity_dependence_sign", "per_capita_rate",
                     "n_species", "time_series")
  missing_vals <- setdiff(required_vals, names(vals))
  if (length(missing_vals) > 0) {
    stop("Missing required value fields: ",
         paste(missing_vals, collapse = ", "), call. = FALSE)
  }
  if (!is.character(vals$diversity_dependence_sign) ||
        !(vals$diversity_dependence_sign %in% c("positive", "negative"))) {
    stop("diversity_dependence_sign must be 'positive' or 'negative'",
         call. = FALSE)
  }
  if (!is.numeric(vals$per_capita_rate)) {
    stop("per_capita_rate must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$n_species)) {
    stop("n_species must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$time_series)) {
    stop("time_series must be numeric", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for valence_autocatalytic_result
#'
#' Public API: combines constructor + validator. Fields are supplied directly
#' so callers can construct a validated result from computed quantities.
#'
#' @param diversity_dependence_sign Character. "positive" or "negative".
#' @param per_capita_rate Numeric vector. Per-capita innovation rate by N.
#' @param n_species Numeric. Number of species / diversity values.
#' @param time_series Numeric vector. Innovation counts over time.
#' @param metadata List. Provenance (default empty list).
#' @param test_name Character. Default "autocatalytic_set_dynamics".
#' @param discriminating Logical. Default TRUE.
#' @param status Character. Default "pass".
#'
#' @return Validated valence_autocatalytic_result object.
#' @export
Valence_autocatalytic_result <- function(diversity_dependence_sign, per_capita_rate,
                                    n_species, time_series, metadata = list(),
                                    test_name = "autocatalytic_set_dynamics",
                                    discriminating = TRUE, status = "pass") {
  values <- list(
    diversity_dependence_sign = diversity_dependence_sign,
    per_capita_rate = per_capita_rate,
    n_species = n_species,
    time_series = time_series
  )
  res <- new_valence_autocatalytic_result(values, metadata, test_name,
                                     discriminating, status)
  validate_valence_autocatalytic_result(res)
}

#' Coerce a raw autocatalytic result into a classed result
#'
#' Wraps the A6 list returned by [diversity_dependence_sign()] into a
#' \code{valence_autocatalytic_result}, computing the per-capita rate series from
#' the innovation counts when it is not already present.
#'
#' @param results List. Raw result list with \code{values} and \code{metadata}.
#' @param metadata List. Optional override of result metadata.
#'
#' @return Validated valence_autocatalytic_result object.
#' @export
as_valence_autocatalytic_result <- function(results, metadata = NULL) {
  if (!is.list(results) || is.null(results$values)) {
    stop("results must be a list with a 'values' element", call. = FALSE)
  }
  vals <- results$values
  meta <- if (is.null(metadata)) results$metadata else metadata

  time_series <- vals$innovation_counts
  if (is.null(time_series)) time_series <- vals$time_series
  if (is.null(time_series)) {
    stop("results$values must contain innovation_counts or time_series",
         call. = FALSE)
  }

  dd_sign <- vals$diversity_dependence_sign
  if (is.null(dd_sign)) dd_sign <- "inconclusive"

  # Per-capita rate series from successive counts: (N_{t+1} - N_t)/N_t.
  n <- length(time_series)
  if (n >= 2L) {
    pc_rate <- diff(time_series) / pmax(time_series[-n], .Machine$double.xmin)
  } else {
    pc_rate <- NA_real_
  }

  Valence_autocatalytic_result(
    diversity_dependence_sign = dd_sign,
    per_capita_rate = pc_rate,
    n_species = n,
    time_series = time_series,
    metadata = meta
  )
}

# ==============================================================================
# VI_CUSP_RESULT CLASS
# ==============================================================================

#' Create valence_cusp_result object (constructor)
#'
#' Bare-metal constructor for cusp catastrophe analysis results.
#'
#' @param values List. Named list with fields:
#'   \item{has_hysteresis}{logical. Whether forward != reverse sweeps.}
#'   \item{max_difference}{numeric. Max |forward - reverse| over control.}
#'   \item{loop_area}{numeric. Signed loop area (\\eqn{\\ge 0} for a genuine
#'     cusp, 0 when no hysteresis).}
#'   \item{equilibria}{numeric vector. Equilibrium state(s) at the sampled
#'     control values.}
#'   \item{bifurcation_set}{numeric. Critical \\eqn{|b|} threshold
#'     \\eqn{2/\\left(3\\sqrt{3}\\right)(-a)^{3/2}} for the sampled cusp.}
#' @param metadata List. Provenance.
#' @param test_name Character.
#' @param discriminating Logical.
#' @param status Character.
#'
#' @return valence_cusp_result object (unvalidated)
#' @keywords internal
new_valence_cusp_result <- function(values, metadata, test_name, discriminating,
                               status) {
  structure(
    list(
      values = values, metadata = metadata, test_name = test_name,
      discriminating = discriminating, status = status
    ),
    class = c("valence_cusp_result", "valence_dynamics_result")
  )
}

#' Validate valence_cusp_result object
#'
#' @param x valence_cusp_result object to validate.
#'
#' @return Invisible \code{x} if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_cusp_result <- function(x) {
  validate_valence_dynamics_result(x)

  vals <- x$values
  required_vals <- c("has_hysteresis", "max_difference", "loop_area",
                     "equilibria", "bifurcation_set")
  missing_vals <- setdiff(required_vals, names(vals))
  if (length(missing_vals) > 0) {
    stop("Missing required value fields: ",
         paste(missing_vals, collapse = ", "), call. = FALSE)
  }
  if (!is.logical(vals$has_hysteresis) || length(vals$has_hysteresis) != 1L) {
    stop("has_hysteresis must be a single logical", call. = FALSE)
  }
  if (!is.numeric(vals$max_difference) || length(vals$max_difference) != 1L) {
    stop("max_difference must be a single numeric", call. = FALSE)
  }
  if (!is.numeric(vals$loop_area) || length(vals$loop_area) != 1L) {
    stop("loop_area must be a single numeric", call. = FALSE)
  }
  if (!is.numeric(vals$equilibria)) {
    stop("equilibria must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$bifurcation_set)) {
    stop("bifurcation_set must be numeric", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for valence_cusp_result
#'
#' Public API: combines constructor + validator.
#'
#' @param has_hysteresis Logical.
#' @param max_difference Numeric.
#' @param loop_area Numeric.
#' @param equilibria Numeric vector.
#' @param bifurcation_set Numeric.
#' @param metadata List. Provenance.
#' @param test_name Character. Default "cusp_catastrophe".
#' @param discriminating Logical. Default TRUE.
#' @param status Character. Default "pass".
#'
#' @return Validated valence_cusp_result object.
#' @export
Valence_cusp_result <- function(has_hysteresis, max_difference, loop_area,
                           equilibria, bifurcation_set, metadata = list(),
                           test_name = "cusp_catastrophe",
                           discriminating = TRUE, status = "pass") {
  values <- list(
    has_hysteresis = has_hysteresis,
    max_difference = max_difference,
    loop_area = loop_area,
    equilibria = equilibria,
    bifurcation_set = bifurcation_set
  )
  res <- new_valence_cusp_result(values, metadata, test_name, discriminating, status)
  validate_valence_cusp_result(res)
}

#' Coerce a raw cusp result into a classed result
#'
#' Wraps the A6 list returned by [cusp_hysteresis_check()] or
#' [hysteresis_loop_area()] into a \code{valence_cusp_result}. Known fields are
#' mapped; unavailable ones fall back to safe defaults.
#'
#' @param results List. Raw list with \code{values} and \code{metadata}.
#' @param metadata List. Optional metadata override.
#'
#' @return Validated valence_cusp_result object.
#' @export
as_valence_cusp_result <- function(results, metadata = NULL) {
  if (!is.list(results) || is.null(results$values)) {
    stop("results must be a list with a 'values' element", call. = FALSE)
  }
  vals <- results$values
  meta <- if (is.null(metadata)) results$metadata else metadata

  has_hysteresis <- if (is.null(vals$has_hysteresis)) FALSE else vals$has_hysteresis
  max_difference <- if (is.null(vals$max_difference)) 0 else vals$max_difference
  loop_area <- if (is.null(vals$loop_area)) 0 else vals$loop_area

  # Equilibria series: prefer forward_states if present, else default.
  if (!is.null(vals$forward_states)) {
    equilibria <- vals$forward_states
    cv <- vals$control_values
  } else if (!is.null(vals$equilibria)) {
    equilibria <- vals$equilibria
    cv <- NULL
  } else {
    equilibria <- numeric(0)
    cv <- NULL
  }

  # Bifurcation threshold from control range midpoint, if available.
  bifurcation_set <- if (is.null(meta$a)) {
    if (!is.null(cv)) abs(median(cv)) else NA_real_
  } else {
    aa <- meta$a
    if (aa < 0) (2 / (3 * sqrt(3))) * (-aa)^(3 / 2) else 0
  }

  Valence_cusp_result(
    has_hysteresis = has_hysteresis,
    max_difference = max_difference,
    loop_area = loop_area,
    equilibria = equilibria,
    bifurcation_set = bifurcation_set,
    metadata = meta
  )
}

# ==============================================================================
# VI_ECONOMICS_RESULT CLASS
# ==============================================================================

#' Create valence_economics_result object (constructor)
#'
#' Bare-metal constructor for the economics module (commitment-driven option
#' decay and stochastic CDI paths).
#'
#' @param values List. Named list with fields:
#'   \item{cdi}{numeric vector. Commitment-diversity index trajectory.}
#'   \item{option_value}{numeric vector or matrix. Option value as a function
#'     of CDI (monotonically non-increasing).}
#'   \item{stochastic_paths}{numeric matrix (n_steps × n_paths). CDI paths,
#'     all entries bounded in [0, 1].}
#'   \item{threshold_disruption}{logical or numeric. Disruption outcome.}
#' @param metadata List. Provenance.
#' @param test_name Character.
#' @param discriminating Logical.
#' @param status Character.
#'
#' @return valence_economics_result object (unvalidated)
#' @keywords internal
new_valence_economics_result <- function(values, metadata, test_name,
                                    discriminating, status) {
  structure(
    list(
      values = values, metadata = metadata, test_name = test_name,
      discriminating = discriminating, status = status
    ),
    class = c("valence_economics_result", "valence_dynamics_result")
  )
}

#' Validate valence_economics_result object
#'
#' @param x valence_economics_result object to validate.
#'
#' @return Invisible \code{x} if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_economics_result <- function(x) {
  validate_valence_dynamics_result(x)

  vals <- x$values
  required_vals <- c("cdi", "option_value", "stochastic_paths",
                     "threshold_disruption")
  missing_vals <- setdiff(required_vals, names(vals))
  if (length(missing_vals) > 0) {
    stop("Missing required value fields: ",
         paste(missing_vals, collapse = ", "), call. = FALSE)
  }
  if (!is.numeric(vals$cdi)) {
    stop("cdi must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$option_value)) {
    stop("option_value must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$stochastic_paths)) {
    stop("stochastic_paths must be numeric", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for valence_economics_result
#'
#' Public API: combines constructor + validator.
#'
#' @param cdi Numeric vector. CDI trajectory.
#' @param option_value Numeric. Option value (or vector vs CDI).
#' @param stochastic_paths Numeric matrix. CDI paths (n_steps × n_paths).
#' @param threshold_disruption Logical or Numeric. Disruption outcome.
#' @param metadata List. Provenance.
#' @param test_name Character. Default "economics".
#' @param discriminating Logical. Default TRUE.
#' @param status Character. Default "pass".
#'
#' @return Validated valence_economics_result object.
#' @export
Valence_economics_result <- function(cdi, option_value, stochastic_paths,
                                threshold_disruption, metadata = list(),
                                test_name = "economics",
                                discriminating = TRUE, status = "pass") {
  values <- list(
    cdi = cdi,
    option_value = option_value,
    stochastic_paths = stochastic_paths,
    threshold_disruption = threshold_disruption
  )
  res <- new_valence_economics_result(values, metadata, test_name,
                                 discriminating, status)
  validate_valence_economics_result(res)
}

# ==============================================================================
# S3 METHODS (dispatch on the base class)
# ==============================================================================

#' Print a dynamics module result
#'
#' Human-readable console output for any \code{valence_dynamics_result} subclass.
#'
#' @param x A valence_dynamics_result (or subclass).
#' @param ... Unused, for S3 compatibility.
#'
#' @return Invisibly \code{x}.
#' @export
print.valence_dynamics_result <- function(x, ...) {
  cat("<!> valence.dynamics result:", x$test_name, "\n")
  cat("    status:", x$status,
      "| discriminating:", if (isTRUE(x$discriminating)) "yes" else "no", "\n")
  cat("    values:\n")
  for (nm in names(x$values)) {
    v <- x$values[[nm]]
    if (is.numeric(v) && length(v) > 4L) {
      cat(sprintf("      %-24s %s [%s values]\n", nm,
                  fmt_num(v[1]), length(v)))
    } else if (is.matrix(v)) {
      cat(sprintf("      %-24s %s x %s matrix\n", nm,
                  nrow(v), ncol(v)))
    } else {
      cat(sprintf("      %-24s %s\n", nm, paste(format(v), collapse = ", ")))
    }
  }
  invisible(x)
}

fmt_num <- function(x) {
  if (is.na(x)) return("NA")
  formatC(x, format = "g", digits = 5)
}

#' Summarise a dynamics module result
#'
#' Returns a tidy one-row data.frame summarising the key scalar outputs.
#'
#' @param object A valence_dynamics_result (or subclass).
#' @param ... Unused, for S3 compatibility.
#'
#' @return A data.frame with one row.
#' @export
summary.valence_dynamics_result <- function(object, ...) {
  vals <- object$values

  # Collect numeric scalar value fields (drop length-0 and matrices).
  scalars <- list()
  for (nm in names(vals)) {
    v <- vals[[nm]]
    if (is.numeric(v) && length(v) == 1L && !is.na(v)) {
      scalars[[nm]] <- v
    }
  }

  row <- c(
    data.frame(
      test_name = object$test_name,
      status = object$status,
      discriminating = object$discriminating,
      stringsAsFactors = FALSE
    ),
    scalars
  )
  as.data.frame(row, stringsAsFactors = FALSE)
}

#' Convert a dynamics module result to a data.frame
#'
#' @param x A valence_dynamics_result (or subclass).
#' @param row.names Ignored (single row).
#' @param optional Ignored.
#' @param ... Unused, for S3 compatibility.
#'
#' @return A one-row data.frame.
#' @export
as.data.frame.valence_dynamics_result <- function(x, row.names = NULL,
                                             optional = FALSE, ...) {
  summary(x)
}

# ==============================================================================
# VI_PROOF CLASS (S3 three-layer pattern)
# ==============================================================================

#' Create valence_proof object (constructor)
#'
#' Bare-metal constructor for a mathematical proof object.
#'
#' @param statement Character. The theorem being proved.
#' @param derivation Character. Multi-line derivation with LaTeX-like math.
#' @param result Character. Outcome, typically "QED".
#' @param verified Logical. Whether the numeric check corroborates.
#' @param numeric_check Numeric. Numeric corroboration value.
#'
#' @return valence_proof object (unvalidated)
#' @keywords internal
new_valence_proof <- function(statement, derivation, result, verified, numeric_check) {
  structure(
    list(statement = statement, derivation = derivation, result = result,
         verified = verified, numeric_check = numeric_check),
    class = "valence_proof"
  )
}

#' Validate valence_proof object
#'
#' @param x valence_proof object to validate.
#'
#' @return Invisible \code{x} if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_proof <- function(x) {
  if (!is.list(x)) {
    stop("valence_proof must be a list", call. = FALSE)
  }
  required <- c("statement", "derivation", "result", "verified", "numeric_check")
  missing <- setdiff(required, names(x))
  if (length(missing) > 0) {
    stop("Missing required fields: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  if (!is.character(x$statement) || length(x$statement) != 1L) {
    stop("statement must be a single character", call. = FALSE)
  }
  if (!is.character(x$derivation) || length(x$derivation) != 1L) {
    stop("derivation must be a single character", call. = FALSE)
  }
  if (!is.character(x$result) || length(x$result) != 1L) {
    stop("result must be a single character", call. = FALSE)
  }
  if (!is.logical(x$verified) || length(x$verified) != 1L) {
    stop("verified must be a single logical", call. = FALSE)
  }
  if (!is.numeric(x$numeric_check)) {
    stop("numeric_check must be numeric", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for valence_proof
#'
#' Public API: combines constructor + validator.
#'
#' @param statement Character. The theorem being proved.
#' @param derivation Character. Multi-line derivation with LaTeX-like math.
#' @param result Character. Outcome, default "QED".
#' @param verified Logical. Whether the numeric check corroborates.
#' @param numeric_check Numeric. Numeric corroboration value.
#'
#' @return Validated valence_proof object.
#' @export
Valence_proof <- function(statement, derivation, result = "QED", verified,
                     numeric_check) {
  res <- new_valence_proof(statement, derivation, result, verified, numeric_check)
  validate_valence_proof(res)
}

#' Print a valence_proof object
#'
#' Formats the proof: statement, derivation, and verification status.
#'
#' @param x A valence_proof object.
#' @param ... Unused, for S3 compatibility.
#'
#' @return Invisibly \code{x}.
#' @export
print.valence_proof <- function(x, ...) {
  cat("==================================================\n")
  cat("THEOREM\n  ", x$statement, "\n")
  cat("DERIVATION\n")
  der_lines <- strsplit(x$derivation, "\n", fixed = TRUE)[[1]]
  for (line in der_lines) {
    cat("   ", line, "\n")
  }
  cat("RESULT: ", x$result, "\n", sep = "")
  cat("WEIGHTED-CONFIDENCE CHECK:", if (isTRUE(x$verified)) "VERIFIED" else "NOT VERIFIED", "\n")
  cat("numeric_check =", formatC(x$numeric_check, format = "g", digits = 6), "\n")
  cat("==================================================\n")
  invisible(x)
}

#' Summarise a valence_proof object
#'
#' @param object A valence_proof object.
#' @param ... Unused, for S3 compatibility.
#'
#' @return A one-row data.frame (statement, result, verified, numeric_check).
#' @export
summary.valence_proof <- function(object, ...) {
  data.frame(
    statement = object$statement,
    result = object$result,
    verified = object$verified,
    numeric_check = object$numeric_check,
    stringsAsFactors = FALSE
  )
}

#' Convert a valence_proof object to a data.frame
#'
#' @param x A valence_proof object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Unused, for S3 compatibility.
#'
#' @return A one-row data.frame.
#' @export
as.data.frame.valence_proof <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary(x)
}