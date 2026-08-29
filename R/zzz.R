#' Package load hooks
#'
#' Registers the built-in empirical tests with the test registry on package
#' load, so the pipeline is ready immediately after `library(valence.foundry)`.
#'
#' @name valence.foundry-load
NULL

#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Register the eight built-in Empirical-layer tests once, on load. Re-running
  # is idempotent: register_test() overwrites entries in place.
  .valence_register_builtin()
}
