#!/usr/bin/env Rscript
# run_tests.R — Test runner for valence.foundry
#
# Usage:
#   Rscript run_tests.R             # Run all tests
#   Rscript run_tests.R unit        # Unit tests only
#   Rscript run_tests.R simulacra   # Simulacrum parameter-recovery tests
#   Rscript run_tests.R integration # End-to-end integration tests
#   Rscript run_tests.R regression  # Baseline-oracle regression tests
#
# The gate name (unit/simulacra/integration/regression) is mapped to a
# testthat filter regex that matches the corresponding file prefix. A known
# gate that matches zero files is a hard error — a silent no-op here would
# mean a CI gate runs nothing while reporting success (the exact failure mode
# this guard exists to prevent).
#
# Coverage is NOT run here: it re-runs the whole suite and would abort on any
# failing test in another gate. CI runs `covr::package_coverage()` as a
# separate, authoritative step in the unit job.

library(testthat)
library(valence.foundry)

arg <- if (length(commandArgs(trailingOnly = TRUE)) > 0) {
  commandArgs(trailingOnly = TRUE)[1]
} else {
  NULL
}

# Gate name -> testthat filter regex (matched against test file paths).
filter_map <- list(
  unit = "unit",
  simulacra = "simulacrum",
  integration = "integration",
  regression = "regression"
)

if (is.null(arg)) {
  filter <- NULL
  filter_label <- "all"
} else if (arg %in% names(filter_map)) {
  filter <- filter_map[[arg]]
  filter_label <- arg
} else {
  # Treat unknown args as a raw filter regex (back-compat).
  filter <- arg
  filter_label <- arg
}

cat("=== The Foundry Test Runner ===\n")
cat(sprintf("Gate: %s  (filter: %s)\n",
  if (is.null(filter_label)) "all" else filter_label,
  if (is.null(filter)) "(none)" else filter
))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Timestamp: %s\n\n",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
))

# Defensive guard: a known gate must match at least one test file. A gate that
# runs zero tests is almost certainly a wiring bug (file renamed, prefix
# changed) and must never pass silently.
if (!is.null(arg) && arg %in% names(filter_map)) {
  files <- testthat:::find_test_scripts("tests/testthat", filter = filter)
  if (length(files) == 0L) {
    stop(sprintf(
      "Gate '%s' matched 0 test files (filter='%s'). A CI gate that runs \
nothing cannot pass silently — fix the filter or add the test files.",
      arg, filter
    ), call. = FALSE)
  }
  cat(sprintf("Matched %d test file(s): %s\n\n",
    length(files), paste(basename(files), collapse = ", ")
  ))
}

results <- test_local(".", filter = filter, reporter = CheckReporter)

# Tally expectations by class. testthat_results do not carry top-level
# $passed/$failed/$skipped counters — the outcome is on each expectation in
# $results, so we must inspect expectation classes. A failure OR error counts
# as a failure (the gate must not pass silently when tests break).
tally <- function(results, class) {
  sum(vapply(results, function(t) {
    sum(vapply(t$results, function(e) inherits(e, class), logical(1)))
  }, integer(1)))
}

failed <- tally(results, "expectation_failure") +
  tally(results, "expectation_error")
passed <- tally(results, "expectation_success")
skipped <- tally(results, "expectation_skip")


cat(sprintf(
  "\n=== Results: %d passed, %d failed, %d skipped ===\n",
  passed, failed, skipped
))

if (failed > 0L) {
  stop(sprintf("%d test(s) failed in gate '%s'", failed, filter_label),
    call. = FALSE
  )
}
