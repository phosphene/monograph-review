# helper-genealogy.R — source genealogy generators by module
# One generator per file.

.genealogy_dir <- function() {
  d <- system.file("genealogy", package = "valence.foundry")
  if (file.exists(file.path(d, "generate_ising.R"))) {
    d
  } else {
    file.path(getwd(), "..", "..", "inst", "genealogy")
  }
}

source_genealogy <- function(file) {
  path <- file.path(.genealogy_dir(), file)
  if (!file.exists(path)) {
    stop("genealogy generator not found: ", file, call. = FALSE)
  }
  source(path, local = FALSE)
}

source_genealogy("generate_ising.R")
source_genealogy("generate_landau.R")
source_genealogy("generate_cusp.R")
source_genealogy("generate_drift_selection.R")
