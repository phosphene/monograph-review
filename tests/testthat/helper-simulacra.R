# helper-simulacra.R — source simulacrum generators by module
# One generator per file.

.simulacra_dir <- function() {
  d <- system.file("simulacra", package = "valence.foundry")
  if (file.exists(file.path(d, "generate_step.R"))) d
  else file.path(getwd(), "..", "..", "inst", "simulacra")
}

source_simulacrum <- function(file) {
  path <- file.path(.simulacra_dir(), file)
  if (!file.exists(path)) {
    stop("simulacrum generator not found: ", file, call. = FALSE)
  }
  source(path, local = FALSE)
}

source_simulacrum("generate_synthetic_population.R")
source_simulacrum("generate_biphasic_genome.R")
source_simulacrum("generate_cross_kingdom.R")
source_simulacrum("generate_cusp_system.R")
source_simulacrum("generate_autocatalytic.R")
source_simulacrum("generate_step.R")
source_simulacrum("generate_sigmoid.R")
source_simulacrum("generate_null_rho.R")
source_simulacrum("generate_percolation.R")
