#' Empirical Test Registry and Pipeline
#'
#' A simple, dependency-free registry mapping test names to their implementing
#' functions, required data, discriminating status, expected value fields, and
#' the S3 result class they produce. The encoder can `register_test()` new
#' tests, inspect the registry with `list_tests()`, and drive the pipeline with
#' `run_test()` / `run_all_tests()`.
#'
#' The registry is stored in a package-internal environment. Registering
#' happens at load time (see `.onLoad`) for the built-in tests, and can be
#' extended at runtime by package consumers.
#'
#' @section Theoretical Context:
#'
#' This module operationalises DFT A6 (check-result): every test is wrapped in
#' a typed, validated S3 result object so downstream consumers can aggregate,
#' compare, and plot results without parsing heterogeneous raw lists. The
#' pipeline functions are pure with respect to the registry (A1): they read
#' the registry and return structured objects, never writing global state.
#'
#' @name test_registry
NULL

# =============================================================================
# Registry internals
# =============================================================================

#' Test registry environment
#'
#' A locked-down environment holding the current test registry. Keys are test
#' names; values are registry entries (lists).
#'
#' @keywords internal
.valence_test_registry <- new.env(parent = emptyenv())
class(.valence_test_registry) <- "valence_test_registry_env"
## Helper making the registry behave like a (bounded) named list for printing.
#' @export
print.valence_test_registry_env <- function(x, ...) {
  nms <- sort(ls(x))
  cat("valence test registry:", length(nms), "registered tests\n\n")
  if (length(nms)) {
    for (nm in nms) {
      e <- x[[nm]]
      cat(sprintf("  %-28s -> %s (discriminating: %s)\n",
                  nm, e$class, ifelse(isTRUE(e$discriminating), "yes", "no")))
    }
  }
  invisible(x)
}

#' Register a test (internal write)
#'
#' Writes one entry into the registry environment.
#'
#' @param entry List. Registry entry with name, fn, data_required,
#'   discriminating, expected_fields, class, valence_prediction.
#' @keywords internal
.valence_register <- function(entry) {
  assign(entry$name, entry, envir = .valence_test_registry)
  invisible(entry)
}

#' Determine the S3 result class for a test name
#'
#' @param name Character. Test name.
#' @return Character. Class name.
#' @keywords internal
.valence_class_for <- function(name) {
  entry <- .valence_test_registry[[name]]
  if (is.null(entry) || is.null(entry$class)) "valence_test_result" else entry$class
}

#' Build an S3 result object from a raw test list
#'
#' Routes a raw `values`/`metadata` list from an empirical test into the
#' appropriate S3 result class, computing base fields (statistic, p_value,
#' status) from the raw values and the registry entry.
#'
#' @param entry List. Registry entry.
#' @param raw List. Raw result with `values` and `metadata`.
#' @return S3 result object (see empirical_test_classes.R).
#' @keywords internal
.build_valence_result <- function(entry, raw) {
  cls <- entry$class %||% "valence_test_result"
  vals <- raw$values
  meta <- raw$metadata

  # Map a raw value key to the class's statistic slot where sensible.
  statistic_key <- entry$statistic_key %||% {
    # Heuristic: prefer a well-known single statistic name in the raw values.
    if (!is.null(vals$statistic)) "statistic" else NULL
  }
  statistic <- if (!is.null(statistic_key) && !is.null(vals[[statistic_key]])) {
    as.numeric(vals[[statistic_key]])
  } else {
    # Fallback: first single non-logical numeric scalar in values.
    num_i <- which(vapply(vals, function(v) is.numeric(v) && length(v) == 1 && !is.na(v), logical(1)))
    if (length(num_i)) as.numeric(vals[[num_i[1]]]) else NA_real_
  }

  p_value <- if (!is.null(vals$p_value) && is.numeric(vals$p_value)) {
    as.numeric(vals$p_value[1])
  } else if (!is.null(vals$permutation_p) && is.numeric(vals$permutation_p)) {
    as.numeric(vals$permutation_p[1])
  } else if (!is.null(vals$null_p) && is.numeric(vals$null_p)) {
    as.numeric(vals$null_p[1])
  } else {
    NA_real_
  }

  base <- list(
    test_name = entry$name,
    statistic = statistic,
    p_value = p_value,
    valence_prediction = entry$valence_prediction %||% "",
    discriminating = isTRUE(entry$discriminating),
    status = .valence_status_of(p_value),
    values = vals,
    metadata = meta
  )

  switch(cls,
    valence_pgls_result = do.call(valence_pgls_result, c(base, list(
      beta = .val_or_na(vals, "beta"),
      r_squared = .val_or_na(vals, "r_squared"),
      aic = .val_or_na(vals, "aic"),
      n = .val_or_na(vals, "n", .val_or_na(meta, "n"))
    ))),
    valence_niche_ne_result = do.call(valence_niche_ne_result, c(base, list(
      niche_r_squared = .val_or_na(vals, "niche_r_squared"),
      ne_r_squared = .val_or_na(vals, "ne_r_squared"),
      delta_aic = .val_or_na(vals, "aic_niche", .val_or_na(vals, "aic_ne")) -
        .val_or_na(vals, "aic_ne")
    ))),
    valence_fluidity_result = do.call(valence_fluidity_result, c(base, list(
      lifestyle_r_squared = .val_or_na(vals, "niche_r_squared"),
      ne_r_squared = .val_or_na(vals, "ne_r_squared"),
      p_value2 = p_value
    ))),
    valence_ordering_result = do.call(valence_ordering_result, c(base, list(
      rho = .val_or_na(vals, "spearman_rho"),
      p_value2 = .val_or_na(vals, "permutation_p", p_value),
      n_permutations = .val_or_na(vals, "n_permutations", .val_or_na(meta, "n_permutations"))
    ))),
    valence_transfer_result = do.call(valence_transfer_result, c(base, list(
      rho = .val_or_na(vals, "bird_rho"),
      p_value2 = .val_or_na(vals, "null_p", .val_or_na(vals, "bird_p")),
      n_null_draws = .val_or_na(vals, "n_null", .val_or_na(meta, "n_null"))
    ))),
    valence_cosegregation_result = do.call(valence_cosegregation_result, c(base, list(
      observed_pct = .val_or_na(vals, "observed_pct"),
      expected_pct = .val_or_na(vals, "expected_pct"),
      depletion_ratio = .val_or_na(vals, "depletion_ratio")
    ))),
    do.call(valence_test_result, base)
  )
}

#' Pull a named value from a list with an optional default (helper)
#'
#' @param lst List.
#' @param key Character.
#' @param fallback Value to return if `key` absent.
#' @return Value, fallback, or NA.
#' @keywords internal
.val_or_na <- function(lst, key, fallback = NA_real_) {
  if (!is.null(lst[[key]])) lst[[key]] else fallback
}

#' Convenience coalescing operator (internal)
#'
#' @param lhs Value.
#' @param rhs Fallback.
#' @return `lhs` if not NULL, else `rhs`.
#' @keywords internal
`%||%` <- function(lhs, rhs) {
  if (is.null(lhs) || (length(lhs) == 1 && is.na(lhs))) rhs else lhs
}

# =============================================================================
# Public registry API
# =============================================================================

#' Register an empirical test
#'
#' Adds (or replaces) a test in the registry. The test function must return a
#' list with `values` (named list of numeric metrics) and `metadata` (named
#' list of provenance) — the A6 proof-object shape used by the Empirical layer.
#'
#' @param name Character. Unique test name.
#' @param fn Function. Implements the test; accepts `...`.
#' @param data_required Character vector. Names of the data arguments the test
#'   needs (e.g. `"data"`, `c("plant_data", "bird_data")`). Use
#'   `character(0)` for tests that need no external data.
#' @param discriminating Logical. Whether the test distinguishes valence from
#'   competitors (as opposed to only being consistent with valence).
#' @param expected_fields Character vector. Value fields the test returns.
#' @param class Character. S3 result class to wrap the output in
#'   (default `"valence_test_result"`).
#' @param statistic_key Character. Optional name of the raw value field to use
#'   as the canonical statistic (otherwise auto-detected).
#' @param valence_prediction Character. Plain-language valence prediction statement.
#'
#' @return Invisibly returns the registry entry.
#' @export
#' @examples
#' \dontrun{
#' register_test(
#'   name = "my_test", fn = my_test,
#'   data_required = "data", discriminating = TRUE,
#'   expected_fields = c("rho", "p_value"), class = "valence_ordering_result"
#' )
#' }
register_test <- function(name, fn, data_required = character(0),
                          discriminating = FALSE,
                          expected_fields = character(0),
                          class = "valence_test_result",
                          statistic_key = NULL,
                          valence_prediction = "") {
  if (!is.character(name) || length(name) != 1 || !nzchar(name)) {
    stop("name must be a single non-empty character", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("fn must be a function", call. = FALSE)
  }
  if (!is.character(class) || length(class) != 1) {
    stop("class must be a single character", call. = FALSE)
  }
  if (!class %in% c("valence_test_result", "valence_pgls_result", "valence_niche_ne_result",
                    "valence_fluidity_result", "valence_ordering_result",
                    "valence_transfer_result", "valence_cosegregation_result")) {
    stop("Unknown result class: ", class, call. = FALSE)
  }

  entry <- list(
    name = name,
    fn = fn,
    data_required = data_required,
    discriminating = isTRUE(discriminating),
    expected_fields = expected_fields,
    class = class,
    statistic_key = statistic_key,
    valence_prediction = valence_prediction
  )
  .valence_register(entry)
  invisible(entry)
}

#' List registered tests
#'
#' @param discriminating_only Logical. If TRUE, only return tests flagged as
#'   discriminating (i.e. that distinguish valence from competitors).
#'
#' @return data.frame with columns: name, function, data_required,
#'   discriminating, expected_fields, class.
#' @export
list_tests <- function(discriminating_only = FALSE) {
  nms <- sort(ls(.valence_test_registry))
  if (length(nms) == 0) {
    return(data.frame(
      name = character(0), function_name = character(0),
      data_required = I(list()), discriminating = logical(0),
      expected_fields = I(list()), class = character(0),
      stringsAsFactors = FALSE
    ))
  }
  entries <- lapply(nms, function(nm) .valence_test_registry[[nm]])
  df <- data.frame(
    name = vapply(entries, `[[`, character(1), "name"),
    function_name = vapply(entries, function(e) deparse(substitute(e$fn))[1], character(1)),
    data_required = I(lapply(entries, `[[`, "data_required")),
    discriminating = vapply(entries, function(e) isTRUE(e$discriminating), logical(1)),
    expected_fields = I(lapply(entries, `[[`, "expected_fields")),
    class = vapply(entries, `[[`, character(1), "class"),
    stringsAsFactors = FALSE
  )
  # Better function name: use fn's formals-based name would be unstable; rely
  # on the entry field only when it is not just the placeholder.
  df$function_name <- vapply(entries, function(e) {
    nm <- attr(e$fn, "test_name")
    if (is.null(nm)) e$name else nm
  }, character(1))

  if (discriminating_only) {
    df <- df[df$discriminating, , drop = FALSE]
  }
  rownames(df) <- NULL
  df
}

#' Run a single registered test
#'
#' Executes the registered test function with the supplied arguments and wraps
#' the raw result in its S3 result class.
#'
#' @param name Character. Registered test name.
#' @param ... Arguments forwarded to the test function (e.g. `data`, `tree`,
#'   `seed`).
#'
#' @return An S3 empirical result object (see empirical_test_classes.R).
#' @export
#' @examples
#' \dontrun{
#' run_test("ltee_cosegregation", seed = 42)
#' }
run_test <- function(name, ...) {
  entry <- .valence_test_registry[[name]]
  if (is.null(entry)) {
    stop("Unknown test '", name, "'. See list_tests().", call. = FALSE)
  }
  raw <- entry$fn(...)
  .build_valence_result(entry, raw)
}

#' Run all registered tests
#'
#' Runs every registered test, collects the S3 result objects into a
#' `valence_test_suite`, and returns it. Tests that error are captured and reported
#' as failed entries rather than aborting the run.
#'
#' @param ... Arguments forwarded to every test function. Tests requiring
#'   different data must be run individually with `run_test()`; supply only
#'   arguments that are valid for all tests here.
#'
#' @return valence_test_suite object.
#' @export
#' @examples
#' \dontrun{
#' run_all_tests()
#' }
run_all_tests <- function(...) {
  nms <- sort(ls(.valence_test_registry))
  results <- vector("list", length(nms))
  statuses <- character(length(nms))
  for (i in seq_along(nms)) {
    entry <- .valence_test_registry[[nms[i]]]
    out <- tryCatch(
      .build_valence_result(entry, entry$fn(...)),
      error = function(e) {
        valence_test_result(
          test_name = nms[i],
          statistic = NA_real_,
          p_value = NA_real_,
          valence_prediction = entry$valence_prediction %||% "",
          discriminating = isTRUE(entry$discriminating),
          status = "n/a",
          values = list(error = conditionMessage(e)),
          metadata = list(failed = TRUE, error = conditionMessage(e))
        )
      }
    )
    results[[i]] <- out
    statuses[i] <- out$status
  }
  names(results) <- nms
  structure(
    list(
      results = results,
      ran_at = Sys.time(),
      n_tests = length(nms),
      n_significant = sum(statuses == "significant", na.rm = TRUE),
      n_failed = sum(vapply(results, function(r) {
        isTRUE(r$metadata$failed)
      }, logical(1)))
    ),
    class = "valence_test_suite"
  )
}

# =============================================================================
# valence_test_suite methods
# =============================================================================

#' Print valence_test_suite Object
#'
#' @param x valence_test_suite object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.valence_test_suite <- function(x, ...) {
  cat("valence_test_suite:", x$n_tests, "tests;",
      x$n_significant, "significant;", x$n_failed, "failed\n\n")
  if (x$n_tests == 0) {
    cat("  (no tests registered)\n")
    return(invisible(x))
  }
  rows <- lapply(x$results, function(r) {
    data.frame(
      test = r$test_name,
      statistic = if (is.null(r$statistic)) NA_real_ else r$statistic,
      p_value = if (is.null(r$p_value)) NA_real_ else r$p_value,
      status = r$status,
      disc = ifelse(isTRUE(r$discriminating), "yes", "no"),
      stringsAsFactors = FALSE
    )
  })
  tab <- do.call(rbind, rows)
  print(tab, row.names = FALSE)
  invisible(x)
}

#' Summary of valence_test_suite Object
#'
#' @param object valence_test_suite object.
#' @param ... Ignored.
#' @return data.frame stacking per-test summaries plus the class of each result.
#' @export
summary.valence_test_suite <- function(object, ...) {
  if (object$n_tests == 0) {
    return(data.frame())
  }
  rows <- lapply(object$results, function(r) {
    base <- .valence_base_summary(r)
    base$class <- class(r)[1]
    base$n <- if (!is.null(r$metadata$n)) r$metadata$n else NA_real_
    base
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Plot valence_test_suite Object
#'
#' Returns a ggplot2 forest plot of test statistics, points coloured by
#' significance status. Pure: returns the plot object without drawing it.
#'
#' @param x valence_test_suite object.
#' @param ... Ignored.
#' @return ggplot2 object.
#' @export
plot.valence_test_suite <- function(x, ...) {
  library(ggplot2)

  if (x$n_tests == 0) {
    stop("No tests to plot", call. = FALSE)
  }

  df <- do.call(rbind, lapply(x$results, function(r) {
    data.frame(
      test = r$test_name,
      statistic = if (is.null(r$statistic)) NA_real_ else as.numeric(r$statistic),
      p_value = if (is.null(r$p_value)) NA_real_ else as.numeric(r$p_value),
      status = r$status,
      disc = ifelse(isTRUE(r$discriminating), "Distinguishes valence", "Consistent w/ valence"),
      stringsAsFactors = FALSE
    )
  }))
  df <- df[!is.na(df$statistic), , drop = FALSE]

  ggplot(df, aes(x = statistic, y = reorder(test, statistic), color = status)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
    geom_point(size = 3) +
    geom_text(
      aes(label = sprintf("p = %s", ifelse(is.na(p_value), "NA",
                                           formatC(p_value, format = "g", digits = 3)))),
      hjust = -0.2, size = 3, color = "black"
    ) +
    scale_color_manual(
      values = c(significant = "#1f77b4", not_significant = "#ff7f0e", `n/a` = "grey50")
    ) +
    labs(
      title = "Empirical test suite",
      subtitle = "Points show the test statistic; colour is significance status",
      x = "Test statistic", y = NULL, color = "Status"
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom") +
    coord_cartesian(clip = "off")
}

# =============================================================================
# Default registration of built-in empirical tests
# =============================================================================

#' Register the built-in empirical tests (load hook)
#'
#' Populates the registry with the eight Empirical-layer tests. Called on
#' package load so the pipeline is ready immediately after `library()`.
#'
#' @keywords internal
.valence_register_builtin <- function() {
  # T1 / T2 — PGLS comparative results
  register_test(
    name = "pgls_orobanchaceae", fn = pgls_orobanchaceae,
    data_required = c("data", "tree"), discriminating = FALSE,
    expected_fields = c("beta", "r_squared", "p_value", "lambda", "n_species"),
    class = "valence_pgls_result", statistic_key = "beta",
    valence_prediction = "plastome size shrinks with parasitism depth (negative beta)"
  )
  register_test(
    name = "pgls_cross_family", fn = pgls_cross_family,
    data_required = "data", discriminating = FALSE,
    expected_fields = c("pearson_r", "n", "p_value"),
    class = "valence_pgls_result", statistic_key = "pearson_r",
    valence_prediction = "gene-loss gradient replicates across independent parasitic families"
  )
  # T3 — endosymbiont biphasic reduction (base result)
  register_test(
    name = "endosymbiont_biphasic", fn = endosymbiont_biphasic,
    data_required = "data", discriminating = FALSE,
    expected_fields = c("r_squared", "k1_k2_ratio", "bayes_factor"),
    class = "valence_test_result", statistic_key = "r_squared",
    valence_prediction = "biphasic (decelerating) genome reduction kinetics"
  )
  # T4 — niche vs Ne
  register_test(
    name = "niche_vs_ne", fn = niche_vs_ne,
    data_required = "data", discriminating = TRUE,
    expected_fields = c("niche_r_squared", "ne_r_squared", "aic_niche", "aic_ne"),
    class = "valence_niche_ne_result", statistic_key = "niche_r_squared",
    valence_prediction = "niche breadth predicts gene loss better than Ne"
  )
  # T5 — pan-genome fluidity
  register_test(
    name = "pangenome_fluidity", fn = pangenome_fluidity,
    data_required = "data", discriminating = TRUE,
    expected_fields = c("lifestyle_subsumes_ne", "niche_r_squared", "ne_r_squared"),
    class = "valence_fluidity_result", statistic_key = "niche_r_squared",
    valence_prediction = "pan-genome openness tracks lifestyle, not Ne alone"
  )
  # T6 — gene-loss ordering
  register_test(
    name = "gene_loss_ordering", fn = gene_loss_ordering,
    data_required = "data", discriminating = TRUE,
    expected_fields = c("spearman_rho", "permutation_p", "pseudo_r_squared"),
    class = "valence_ordering_result", statistic_key = "spearman_rho",
    valence_prediction = "integration depth orders gene loss (high rho)"
  )
  # T7 — LTEE co-segregation (no external data)
  register_test(
    name = "ltee_cosegregation", fn = ltee_cosegregation,
    data_required = character(0), discriminating = TRUE,
    expected_fields = c("observed_pct", "expected_pct", "p_value", "depletion_ratio"),
    class = "valence_cosegregation_result", statistic_key = "depletion_ratio",
    valence_prediction = "function loss co-segregates with adaptive sweeps less than chance"
  )
  # L3 — cross-kingdom transfer
  register_test(
    name = "transfer_test", fn = transfer_test,
    data_required = c("plant_data", "bird_data"), discriminating = TRUE,
    expected_fields = c("plant_slope", "bird_rho", "bird_p", "null_rho", "null_p"),
    class = "valence_transfer_result", statistic_key = "bird_rho",
    valence_prediction = "integration-depth parameters transfer across kingdoms"
  )
  invisible(TRUE)
}