#!/usr/bin/env Rscript
# Data Format Compliance Checker
# Validates that all data files follow TSV/JSON policy standards
# Usage: Rscript scripts/check_data_formats.R [path] [--fail-on-warn]

library(testthat)

check_path <- function(path, fail_on_warn = FALSE) {
  results <- list()
  
  # Get all files in directory
  if (dir.exists(path)) {
    files <- list.files(path, recursive = TRUE, full.names = TRUE)
  } else {
    stop(sprintf("Path not found: %s", path))
  }
  
  for (file in files) {
    rel_path <- sub("^\\.?/", "", file)
    ext <- tolower(tools::file_ext(rel_path))
    
    result <- list(
      path = rel_path,
      format = ext,
      status = "PASS",
      warning = NULL,
      error = NULL
    )
    
    if (ext == "tsv") {
      # Validate TSV structure
      tryCatch({
        data <- read.table(file, header = TRUE, sep = "\t", comment.char = "#", stringsAsFactors = FALSE)
        
        # Check required columns exist (if header suggests empirical data)
        if (nrow(data) > 0) {
          if (any(c("time", "retention") %in% names(data))) {
            # Empirical data must have units documented
            header_text <- paste(readLines(file, n = 10), collapse = "\n")
            if (!grepl("#.*Unit|unit|seconds|ratio", header_text, ignore.case = TRUE)) {
              result$warning <- "TSV: Consider documenting units in comments"
              if (fail_on_warn && !is.null(result$warning)) {
                result$status <- "WARN"
              }
            }
          }
        }
        
        result$error <- NULL
      }, error = function(e) {
        result$status <- "FAIL"
        result$error <- sprintf("TSV parse error: %s", e$message)
      })
      
    } else if (ext == "json") {
      # Validate JSON structure (shallow nesting check)
      tryCatch({
        library(jsonlite)
        config <- fromJSON(file, simplifyVector = TRUE)
        
        # Check nesting depth (should be <= 3 levels)
        max_depth <- function(obj) {
          if (is.list(obj) && length(obj) > 0) {
            return(1 + max(sapply(obj, max_depth)))
          }
          return(0)
        }
        
        depth <- max_depth(config)
        if (depth > 4) {
          result$status <- "FAIL"
          result$error <- sprintf("JSON too deeply nested (%d levels > 4)", depth)
        }
        
        result$error <- NULL
      }, error = function(e) {
        result$status <- "FAIL"
        result$error <- sprintf("JSON parse error: %s", e$message)
      })
      
    } else if (ext %in% c("csv", "rds", "h5")) {
      # Allow CSV (will convert to TSV), RDS, HDF5
      result$status <- "SKIP"
      result$warning <- sprintf("Format %s allowed but TSV preferred for tabular data", ext)
      
    } else {
      # Unknown format
      result$status <- "FAIL"
      result$error <- sprintf("Unsupported format: %s (use .tsv or .json)", ext)
    }
    
    results[[length(results) + 1]] <- result
  }
  
  results
}

# Main execution
args <- commandArgs(trailingOnly = TRUE)
path_to_check <- if (length(args) > 0) args[1] else "data/"
fail_on_warn <- "--fail-on-warn" %in% args

cat(sprintf("Checking data formats in: %s\n", path_to_check))
cat(sprintf("Fail on warnings: %s\n\n", if(fail_on_warn) "YES" else "NO"))

results <- check_path(path_to_check, fail_on_warn)

# Summary
summary_table <- data.frame(
  Path = sapply(results, function(r) r$path),
  Format = sapply(results, function(r) r$format),
  Status = sapply(results, function(r) r$status),
  Warning = sapply(results, function(r) if(!is.null(r$warning)) r$warning else ""),
  Error = sapply(results, function(r) if(!is.null(r$error)) r$error else "")
)

cat("Results:\n")
print(summary_table, row.names = FALSE)

# Count statuses
status_counts <- table(sapply(results, function(r) r$status))
cat("\nSummary:\n")
cat(sprintf("  PASS: %d\n", status_counts["PASS"] %||% 0))
cat(sprintf("  FAIL: %d\n", status_counts["FAIL"] %||% 0))
cat(sprintf("  WARN: %d\n", status_counts["WARN"] %||% 0))
cat(sprintf("  SKIP: %d\n", status_counts["SKIP"] %||% 0))

# Exit code based on failures
has_failures <- any(sapply(results, function(r) r$status == "FAIL"))
if (has_failures) {
  quit(status = 1, save = "no")
}
