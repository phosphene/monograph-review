#' Per-file coverage report for the framework Foundry package.
#'
#' Computes package coverage with covr::package_coverage() and prints a
#' per-file breakdown (lines covered / total / percent, ascending) so the
#' CI log shows exactly where the coverage gaps are. Writes
#' coverage-report.json (which the old inline coverage step claimed to
#' upload but never produced — the artifact step was silently finding
#' nothing).
#'
#' Implementation note: the per-file tally is computed from
#' `as.data.frame(cov)` (the coverage object is a data frame with one row
#' per instrumented line: `filename`, `functions`, `line`, `value`, where
#' `value` is the execution count and NA marks untraceable lines). This
#' avoids depending on covr::tally_coverage()'s column names, which have
#' shifted across covr versions. `percent_coverage()` counts value > 0 over
#' non-NA values; we mirror that per file.
#'
#' Intended to be called from the CI workflow's "Check coverage" step.
#'
#' @param min_pct Numeric. Coverage gate percentage; stops if overall is
#'   below this. Default 80.
#'
#' @return Invisibly, the per-file data frame (file, total, covered,
#'   percent). Primarily side-effect: prints the breakdown and writes
#'   coverage-report.json.
write_coverage_report <- function(min_pct = 80) {
  cov <- covr::package_coverage()
  pct <- covr::percent_coverage(cov)
  message("Coverage: ", round(pct, 2), "%")

  df <- as.data.frame(cov)
  df <- df[!is.na(df$value), , drop = FALSE]

  by_file <- split(df$value, df$filename)
  per_file <- do.call(rbind, lapply(names(by_file), function(f) {
    v <- by_file[[f]]
    data.frame(
      file = f,
      total = length(v),
      covered = sum(v > 0),
      percent = round(100 * sum(v > 0) / length(v), 1),
      stringsAsFactors = FALSE
    )
  }))
  per_file <- per_file[order(per_file$percent), , drop = FALSE]
  rownames(per_file) <- NULL

  message("--- per-file coverage (ascending) ---")
  for (i in seq_len(nrow(per_file))) {
    message(sprintf(
      "  %-45s %6.1f%%  (%d/%d lines)",
      basename(per_file$file[i]), per_file$percent[i],
      per_file$covered[i], per_file$total[i]
    ))
  }

  # Write the machine-readable report (fixes the silent artifact bug).
  writeLines(jsonlite::toJSON(
    list(
      overall_percent = as.numeric(round(pct, 2)),
      per_file = per_file
    ),
    auto_unbox = TRUE, pretty = TRUE
  ), "coverage-report.json")

  if (pct < min_pct) {
    stop("Coverage below ", min_pct, "%: ", round(pct, 2), "%")
  }
  invisible(per_file)
}

write_coverage_report()
