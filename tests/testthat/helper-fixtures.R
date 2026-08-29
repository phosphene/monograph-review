# helper-fixtures.R — Shared test fixtures for the foundry
#
# DFT A5: Real in-process fakes, not mocks.
# fake_data_loader returns real dataframes from in-memory fixtures.

library(testthat)

# Resolve a bundled data file (installed with the package). "" if absent.
# Tests must use this rather than relative `data/` paths: testthat runs from
# tests/testthat/, so `file.path("data", ...)` would resolve to the wrong place
# and every bundled-data test would silently skip even when data is present.
# Also checks the `.gz` variant: `R CMD build` may gzip data files.
bundled_data <- function(file) {
  p <- system.file("data", file, package = "valence.foundry")
  if (nzchar(p)) return(p)
  system.file("data", paste0(file, ".gz"), package = "valence.foundry")
}
has_bundled_data <- function(file) {
  nzchar(bundled_data(file))
}

# Loader results carry data + provenance (data/metadata), distinct from the
# analysis proof objects (values/metadata) that validate_result() checks.
is_data_result <- function(result) {
  is.list(result) &&
    !is.null(result$data) &&
    is.list(result$metadata) &&
    all(c("name", "source", "n", "loaded_at") %in% names(result$metadata))
}

# Small deterministic fixtures for unit tests
.fixture_orobanchaceae <- data.frame(
  species = c("Lindenbergia", "Schwalbea", "Orobanche", "Phelipanche", "Conopholis"),
  plastome_size_kb = c(150.0, 120.0, 100.0, 75.0, 50.0),
  parasitism_score = c(0L, 1L, 2L, 3L, 4L),
  family = rep("Orobanchaceae", 5),
  stringsAsFactors = FALSE
)

.fixture_gene_categories <- data.frame(
  category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
  dependency_score = c(0, 1, 1, 2, 3, 5),
  orobanchaceae_loss_rank = c(1, 2, 2, 2, 3, 4),
  cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6),
  stringsAsFactors = FALSE
)

.fixture_bird_morphology <- data.frame(
  structure = c(
    "wing_prop", "pectoral_muscle", "sternal_keel",
    "wing_bones", "hindlimb", "pelvic_girdle",
    "feather_asymmetry", "feather_structure"
  ),
  dependency_score = c(0.0, 0.5, 1.0, 1.5, 4.0, 3.0, 1.0, 5.0),
  observed_rank = c(1, 3, 2, 4, 5, 6, 7, 8),
  stringsAsFactors = FALSE
)

# === Bi-exponential test fixtures ===
# Shared between test-unit-fit-biexp.R and test-unit-relaxation-model.R

.make_biexp_data <- function(n = 40, t_max = 10, c0 = 0.05, A1 = 0.03, k1 = 17.7,
                              A2 = 0.01, k2 = 0.47, noise_sd = 0.001, seed = 42) {
  withr::with_seed(seed, {
    t <- seq(0, t_max, length.out = n)
    rho <- c0 + A1 * exp(-k1 * t) + A2 * exp(-k2 * t) + rnorm(n, 0, noise_sd)
    list(t = t, rho = rho, params = list(c0 = c0, A1 = A1, k1 = k1, A2 = A2, k2 = k2))
  })
}

.make_monoexp_data <- function(n = 40, t_max = 10, c0 = 0.05, A = 0.04, k = 1.0,
                                 noise_sd = 0.001, seed = 42) {
  withr::with_seed(seed, {
    t <- seq(0, t_max, length.out = n)
    rho <- c0 + A * exp(-k * t) + rnorm(n, 0, noise_sd)
    list(t = t, rho = rho, params = list(c0 = c0, A = A, k = k))
  })
}

# fake_data_loader — returns real dataframes, not mock recordings
fake_data_loader <- R6::R6Class(
  "fake_data_loader",
  public = list(
    load = function(name) {
      switch(name,
        orobanchaceae = .fixture_orobanchaceae,
        gene_categories = .fixture_gene_categories,
        bird_morphology = .fixture_bird_morphology,
        stop("Unknown fixture: ", name, call. = FALSE)
      )
    },
    list_available = function() {
      c("orobanchaceae", "gene_categories", "bird_morphology")
    }
  )
)$new()
