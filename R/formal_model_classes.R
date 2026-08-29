#' Formal Model Result Classes (S3 three-layer pattern)
#'
#' Implements Phosphene R Standards §7: constructor → validator → helper
#' for all formal model result types.
#'
#' @section Theoretical Context:
#'
#' All functions follow DFT axioms:
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): fully deterministic, no RNG
#' - A6 (check-result): returns structured objects with metadata
#'
#' @name formal_model_classes
NULL

# ==============================================================================
# VI_THRESHOLD_RESULT CLASS
# ==============================================================================

#' Create valence_threshold_result object (constructor)
#'
#' Bare-metal constructor — assigns class without validation. Used internally
#' by the validator and helper. No type checking; trusts caller to provide
#' correct structure.
#'
#' @param values List. Named list with elements:
#'   \item{final_retention}{numeric vector of final retention values}
#'   \item{phase1_rate}{numeric. Rate during first 10% of time}
#'   \item{phase2_rate}{numeric. Rate during last 90% of time}
#'   \item{early_late_displacement_ratio}{numeric. Ratio of phase rates}
#'   \item{threshold_biphasicity}{numeric. Difference in means between groups}
#' @param metadata List. Named list with metadata fields:
#'   \item{params}{list of model parameters}
#'   \item{n_traits}{integer. Number of traits simulated}
#'   \item{n_unprotected}{integer. Number of unprotected traits}
#'   \item{n_protected}{integer. Number of protected traits}
#'   \item{n_steps}{integer. Number of Euler integration steps}
#'   \item{dt}{numeric. Time step size}
#'   \item{method}{character. Integration method used}
#'   \item{converged}{logical. Whether integration converged}
#'   \item{retention_history}{matrix. Full trajectory of retention over time}
#'
#' @return valence_threshold_result object (unvalidated)
#' @keywords internal
new_valence_threshold_result <- function(values, metadata) {
  structure(
    list(values = values, metadata = metadata),
    class = "valence_threshold_result"
  )
}

#' Validate valence_threshold_result object
#'
#' Schema checks: verifies that all required fields are present and have
#' correct types. Returns object invisibly if valid; stops with error if invalid.
#'
#' @param x valence_threshold_result object to validate.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_threshold_result <- function(x) {
  if (!is.list(x)) {
    stop("valence_threshold_result must be a list", call. = FALSE)
  }

  # Check top-level structure
  required_top <- c("values", "metadata")
  missing_top <- setdiff(required_top, names(x))
  if (length(missing_top) > 0) {
    stop("Missing required fields: ", paste(missing_top, collapse = ", "),
      call. = FALSE
    )
  }

  # Validate values
  vals <- x$values
  if (!is.numeric(vals$final_retention)) {
    stop("final_retention must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$phase1_rate) || !is.numeric(vals$phase2_rate)) {
    stop("phase rates must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$early_late_displacement_ratio)) {
    stop("early_late_displacement_ratio must be numeric", call. = FALSE)
  }
  if (!is.numeric(vals$threshold_biphasicity)) {
    stop("threshold_biphasicity must be numeric", call. = FALSE)
  }

  # Validate metadata
  meta <- x$metadata
  if (!is.list(meta)) {
    stop("metadata must be a list", call. = FALSE)
  }
  required_meta <- c(
    "params", "n_traits", "n_unprotected", "n_protected",
    "n_steps", "dt", "method", "converged"
  )
  missing_meta <- setdiff(required_meta, names(meta))
  if (length(missing_meta) > 0) {
    stop("Missing required metadata fields: ", paste(missing_meta, collapse = ", "),
      call. = FALSE
    )
  }
  if (!is.numeric(meta$n_traits) || !is.numeric(meta$n_unprotected) ||
        !is.numeric(meta$n_protected) || !is.numeric(meta$n_steps)) {
    stop("Count fields must be numeric", call. = FALSE)
  }
  if (!is.logical(meta$converged)) {
    stop("converged must be logical", call. = FALSE)
  }
  if (meta$converged && !is.matrix(meta$retention_history)) {
    stop("Converged results require retention_history matrix", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for the framework_threshold_result
#'
#' Public API: combines constructor + validator. Ensures all returned
#' objects are properly structured before leaving this module.
#'
#' @param values See new_valence_threshold_result().
#' @param metadata See new_valence_threshold_result().
#'
#' @return Validated valence_threshold_result object.
#' @export
valence_threshold_result <- function(values, metadata) {
  res <- new_valence_threshold_result(values, metadata)
  validate_valence_threshold_result(res)
}

# ==============================================================================
# VI_GLM_FIT CLASS
# ==============================================================================

#' Create valence_glm_fit object (constructor)
#'
#' Bare-metal constructor — assigns class without validation. Used internally
#' by the validator and helper.
#'
#' @param values List. Named list with GLM results:
#'   \item{intercept}{numeric. Model intercept}
#'   \item{dep_coefficient}{numeric. Dependency coefficient}
#'   \item{dep_p_value}{numeric. Dependency p-value}
#'   \item{para_coefficient}{numeric. Parasitism coefficient}
#'   \item{para_p_value}{numeric. Parasitism p-value}
#'   \item{pseudo_r_squared}{numeric. McFadden's pseudo R²}
#'   \item{cross_kingdom_rho}{numeric. Spearman correlation with bird ranks}
#'   \item{cross_kingdom_p}{numeric. Cross-kingdom test p-value}
#'   \item{dep_positive}{logical. Whether dep_coef > 0}
#'   \item{para_negative}{logical. Whether para_coef < 0}
#'   \item{valence_confirmed}{logical. Whether all the framework's predictions hold}
#' @param metadata List. Named list with metadata fields:
#'   \item{n}{integer. Number of observations}
#'   \item{n_species}{integer. Number of species}
#'   \item{n_gene_categories}{integer. Number of gene categories}
#'   \item{method}{character. Model specification}
#'   \item{seed}{integer. Random seed (42 for reproducibility)}
#'   \item{para_for_transfer}{numeric. Parasitism level for cross-kingdom test}
#'   \item{converged}{logical. Whether GLM converged}
#'   \item{glm_fit}{stats::glm object. Full fitted model (for diagnostics)}
#'
#' @return valence_glm_fit object (unvalidated)
#' @keywords internal
new_valence_glm_fit <- function(values, metadata) {
  structure(
    list(values = values, metadata = metadata),
    class = "valence_glm_fit"
  )
}

#' Validate valence_glm_fit object
#'
#' Schema checks: verifies GLM result structure and consistency.
#'
#' @param x valence_glm_fit object to validate.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_glm_fit <- function(x) {
  if (!is.list(x)) {
    stop("valence_glm_fit must be a list", call. = FALSE)
  }

  # Check values
  required_vals <- c(
    "intercept", "dep_coefficient", "dep_p_value",
    "para_coefficient", "para_p_value", "pseudo_r_squared",
    "cross_kingdom_rho", "cross_kingdom_p", "dep_positive",
    "para_negative", "valence_confirmed"
  )
  missing_vals <- setdiff(required_vals, names(x$values))
  if (length(missing_vals) > 0) {
    stop("Missing required value fields: ", paste(missing_vals, collapse = ", "),
      call. = FALSE
    )
  }

  # All coefficients and p-values should be numeric
  num_fields <- c(
    "intercept", "dep_coefficient", "dep_p_value",
    "para_coefficient", "para_p_value", "pseudo_r_squared",
    "cross_kingdom_rho", "cross_kingdom_p"
  )
  for (field in num_fields) {
    if (!is.numeric(x$values[[field]])) {
      stop(sprintf("%s must be numeric", field), call. = FALSE)
    }
  }

  # Logical flags
  logical_fields <- c("dep_positive", "para_negative", "valence_confirmed")
  for (field in logical_fields) {
    if (!is.logical(x$values[[field]])) {
      stop(sprintf("%s must be logical", field), call. = FALSE)
    }
  }

  # Check metadata
  meta <- x$metadata
  if (!is.list(meta)) {
    stop("metadata must be a list", call. = FALSE)
  }
  required_meta <- c(
    "n", "n_species", "n_gene_categories", "method", "seed",
    "para_for_transfer", "converged"
  )
  missing_meta <- setdiff(required_meta, names(meta))
  if (length(missing_meta) > 0) {
    stop("Missing required metadata fields: ", paste(missing_meta, collapse = ", "),
      call. = FALSE
    )
  }

  # Check GLM fit is present for diagnostics
  if (!inherits(meta$glm_fit, "glm")) {
    stop("metadata$glm_fit must be a stats::glm object", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for the framework_glm_fit
#'
#' Public API: combines constructor + validator.
#'
#' @param values See new_valence_glm_fit().
#' @param metadata See new_valence_glm_fit().
#'
#' @return Validated valence_glm_fit object.
#' @export
valence_glm_fit <- function(values, metadata) {
  res <- new_valence_glm_fit(values, metadata)
  validate_valence_glm_fit(res)
}

# ==============================================================================
# VI_EQUILIBRIUM CLASS
# ==============================================================================

#' Create valence_equilibrium object (constructor)
#'
#' Bare-metal constructor for equilibrium result at a single depth.
#'
#' @param value Numeric. Equilibrium retention value in [0, 1].
#' @param is_protected Logical. Whether trait is protected (depth >= theta).
#' @param params List. Model parameters used: lambda, theta, m0, alpha, time.
#' @param depth Numeric. Trait integration depth.
#' @param integrated_mismatch Numeric. Integrated mismatch ∫₀ᵀ M(t) dt.
#'
#' @return valence_equilibrium object (unvalidated)
#' @keywords internal
new_valence_equilibrium <- function(value, is_protected, params, depth, integrated_mismatch) {
  structure(
    list(
      value = value,
      is_protected = is_protected,
      params = params,
      depth = depth,
      integrated_mismatch = integrated_mismatch
    ),
    class = "valence_equilibrium"
  )
}

#' Validate valence_equilibrium object
#'
#' @param x valence_equilibrium object to validate.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#' @keywords internal
validate_valence_equilibrium <- function(x) {
  if (!is.list(x)) {
    stop("valence_equilibrium must be a list", call. = FALSE)
  }

  required <- c("value", "is_protected", "params", "depth", "integrated_mismatch")
  missing <- setdiff(required, names(x))
  if (length(missing) > 0) {
    stop("Missing required fields: ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.numeric(x$value) || length(x$value) != 1) {
    stop("value must be a single numeric", call. = FALSE)
  }
  if (x$value < 0 || x$value > 1) {
    stop("value must be in [0, 1]", call. = FALSE)
  }
  if (!is.logical(x$is_protected) || length(x$is_protected) != 1) {
    stop("is_protected must be a single logical", call. = FALSE)
  }
  if (!is.numeric(x$depth) || length(x$depth) != 1) {
    stop("depth must be a single numeric", call. = FALSE)
  }
  if (!is.list(x$params)) {
    stop("params must be a list", call. = FALSE)
  }
  if (!is.numeric(x$integrated_mismatch)) {
    stop("integrated_mismatch must be numeric", call. = FALSE)
  }

  invisible(x)
}

#' Public helper for the framework_equilibrium
#'
#' Public API: combines constructor + validator.
#'
#' @param value See new_valence_equilibrium().
#' @param is_protected See new_valence_equilibrium().
#' @param params See new_valence_equilibrium().
#' @param depth See new_valence_equilibrium().
#' @param integrated_mismatch See new_valence_equilibrium().
#'
#' @return Validated valence_equilibrium object.
#' @export
valence_equilibrium <- function(value, is_protected, params, depth, integrated_mismatch) {
  res <- new_valence_equilibrium(value, is_protected, params, depth, integrated_mismatch)
  validate_valence_equilibrium(res)
}
