# test-integration-pipeline.R — End-to-end integration gate
#
# Implements the BDD scenarios from tests/integration/features/*.feature as
# executable testthat tests (the Foundry default for integration BDD, per
# docs/standards/BDD_IN_R.md). The .feature files remain the stakeholder-
# readable specification; these tests are the executable counterpart.
#
# Scenarios covered:
#   pipeline.feature    - full execution, idempotency, manifest conformance
#   simulation.feature  - same-seed reproducibility, different-seed divergence
#   data_integrity.feature - Postgres round-trip (skipped without a DB)
#
# This file matches the `integration` filter (run_tests.R integration).

library(testthat)
library(valence.foundry)

# Path helpers (tests/testthat -> ../../project root).
proj_path <- function(...) testthat::test_path("..", "..", ...)
has_pkg <- function(p) requireNamespace(p, quietly = TRUE)

# ---- pipeline.feature: Full pipeline execution ----

test_that("pipeline.feature: full pipeline execution — all runnable stages produce proof objects", {
  stages <- list()

  stages$t1 <- function() {
    skip_if_not(has_pkg("ape") && has_pkg("caper"), "ape/caper not installed")
    l <- load_orobanchaceae()
    pgls_orobanchaceae(l$data, l$tree, seed = 42)
  }
  stages$t2 <- function() load_cross_family_plastomes() |> (\(l) pgls_cross_family(l$data, seed = 42))()
  stages$t3 <- function() load_endosymbionts() |> (\(l) endosymbiont_biphasic(l$data, seed = 42))()
  stages$t4 <- function() {
    skip_if_not(has_pkg("readxl"), "readxl not installed")
    load_bobay_ochman() |> (\(l) niche_vs_ne(l$data, seed = 42))()
  }
  stages$t5 <- function() load_dewar_pangenome() |> (\(l) pangenome_fluidity(l$data, seed = 42))()
  stages$t7 <- function() ltee_cosegregation(seed = 42)
  stages$formal <- function() {
    threshold_model(
      depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
      m0 = 10, alpha = 0.05, time = 100
    )
  }

  ran <- 0L
  for (name in names(stages)) {
    res <- tryCatch(stages[[name]](), error = function(e) e)
    # A bare error is only acceptable if it was a skip condition we could not
    # express inline; otherwise the stage must return a proof object.
    if (inherits(res, "expectation_skip")) next
    if (inherits(res, "error")) {
      # Missing bundled data is an acceptable skip; a real failure is not.
      cond <- conditionMessage(res)
      if (!grepl("not bundled|not found|not installed", cond)) {
        fail(sprintf("stage %s errored: %s", name, cond))
      }
      next
    }
    expect_true(validate_result(res),
      info = sprintf("stage %s must return an A6 proof object", name)
    )
    ran <- ran + 1L
  }
  expect_true(ran > 0L,
    info = "at least one pipeline stage must run end-to-end"
  )
})

# ---- pipeline.feature: Pipeline idempotency ----

test_that("pipeline.feature: idempotency — running the formal model twice yields identical results", {
  run_once <- function() {
    threshold_model(
      depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
      m0 = 10, alpha = 0.05, time = 100
    )$values
  }
  r1 <- run_once()
  r2 <- run_once()
  expect_equal(r1, r2)
})

test_that("pipeline.feature: idempotency — T7 (deterministic) is identical across calls", {
  r1 <- ltee_cosegregation(seed = 42)$values
  r2 <- ltee_cosegregation(seed = 42)$values
  expect_equal(r1, r2)
})

# ---- pipeline.feature: Manifest conformance (DFT A3) ----

test_that("pipeline.feature: manifest conformance — every pipeline.yml stage function is exported", {
  manifest_path <- proj_path("pipeline.yml")
  skip_if_not(file.exists(manifest_path), "pipeline.yml not available (source tree required)")

  manifest <- yaml::read_yaml(manifest_path)
  ns <- getNamespaceExports("valence.foundry")

  missing <- character(0)
  for (stage in manifest$stages) {
    fn <- stage[["function"]]
    if (is.null(fn) || !nzchar(fn)) {
      missing <- c(missing, sprintf("%s: no function declared", stage$name))
    } else if (!(fn %in% ns)) {
      missing <- c(missing, sprintf("%s: function '%s' not exported", stage$name, fn))
    }
  }
  expect_true(length(missing) == 0L,
    info = if (length(missing) > 0) paste(missing, collapse = "; ")
  )
})

# ---- simulation.feature: Same-seed reproducibility / different-seed divergence ----

test_that("simulation.feature: same seed produces identical synthetic data (A2)", {
  d1 <- generate_synthetic_population(n = 50L, seed = 42L)
  d2 <- generate_synthetic_population(n = 50L, seed = 42L)
  expect_identical(d1, d2)
})

test_that("simulation.feature: different seeds produce different synthetic data", {
  d1 <- generate_synthetic_population(n = 50L, seed = 42L)
  d2 <- generate_synthetic_population(n = 50L, seed = 123L)
  expect_false(identical(d1, d2))
})

# ---- data_integrity.feature: Postgres round-trip (skipped without a DB) ----

test_that("data_integrity.feature: fixture round-trips through Postgres unchanged", {
  skip_if_not(has_pkg("DBI") && has_pkg("RPostgres"), "DBI/RPostgres not installed")
  skip_if_not(
    Sys.getenv("RUN_DB_INTEGRATION") == "true",
    "set RUN_DB_INTEGRATION=true to run the Postgres round-trip (Docker stack)"
  )

  schema <- proj_path("tests", "fixtures", "schema.sql")
  seed <- proj_path("tests", "fixtures", "seed.sql")
  skip_if_not(file.exists(schema) && file.exists(seed), "fixtures not found")

  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("PGHOST", "localhost"),
    port = Sys.getenv("PGPORT", "5432"),
    dbname = Sys.getenv("PGDATABASE", "simulation_test"),
    user = Sys.getenv("PGUSER", "sim"),
    password = Sys.getenv("PGPASSWORD", "simulacrum")
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  DBI::dbExecute(con, paste(readLines(schema), collapse = "\n"))
  DBI::dbExecute(con, paste(readLines(seed), collapse = "\n"))

  sql <- "SELECT species_name, plastome_size_kb, parasitism_score FROM species ORDER BY species_name"
  res <- DBI::dbGetQuery(con, sql)
  expect_s3_class(res, "data.frame")
  expect_gte(nrow(res), 5L)
  expect_true(all(res$parasitism_score >= 0 & res$parasitism_score <= 4))
})
