#!/usr/bin/env Rscript
# scripts/run_pipeline.R — Execute the full the foundry pipeline and write results
#
# Runs every analysis stage against the bundled data, collects each stage's
# `values` (A6 proof object) keyed by the baseline-oracle entry name, and
# writes results.yml to an output directory. The output is consumed by
# tests/compare_baseline.py (the independent Python verifier) and by the
# Docker simulacrum stack's verifier container.
#
# Usage:
#   Rscript scripts/run_pipeline.R                 # writes test-output/results.yml
#   Rscript scripts/run_pipeline.R --output dir    # write to <dir>/results.yml
#
# Stages whose data or optional deps are unavailable are recorded as skipped
# (NA values + a reason) rather than aborting the run, so a partial pipeline
# still produces a verifiable artifact.

library(valence.foundry)

args <- commandArgs(trailingOnly = TRUE)
output_dir <- "test-output"
if (length(args) >= 2L && args[1] == "--output") output_dir <- args[2]
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

has_pkg <- function(p) requireNamespace(p, quietly = TRUE)
has_data <- function(f) nzchar(system.file("data", f, package = "valence.foundry"))

# Each runner returns a list(values = list(...), skipped = NULL) or
# list(skipped = "<reason>") on failure.
runners <- list(
  t1_orobanchaceae_pgls = function() {
    if (!has_pkg("ape") || !has_pkg("caper")) stop("ape/caper not installed")
    if (!has_data("species_plastome_data.tsv")) stop("orobanchaceae data not bundled")
    l <- load_orobanchaceae()
    pgls_orobanchaceae(l$data, l$tree, seed = 42)$values
  },
  t2_cross_family = function() {
    if (!has_data("cross_family_plastome_data.tsv")) stop("cross-family data not bundled")
    l <- load_cross_family_plastomes()
    pgls_cross_family(l$data, seed = 42)$values
  },
  t3_endosymbiont_biphasic = function() {
    if (!has_data("endosymbiont_genome_data.tsv")) stop("endosymbiont data not bundled")
    l <- load_endosymbionts()
    endosymbiont_biphasic(l$data, seed = 42)$values
  },
  t4_niche_vs_ne = function() {
    if (!has_pkg("readxl")) stop("readxl not installed")
    if (!has_data("bobay_ochman_table_s1.xlsx")) stop("bobay-ochman data not bundled")
    l <- load_bobay_ochman()
    niche_vs_ne(l$data, seed = 42)$values
  },
  t5_pangenome_fluidity = function() {
    if (!has_data("dewar_pangenome_lifestyles.csv")) stop("dewar data not bundled")
    l <- load_dewar_pangenome()
    pangenome_fluidity(l$data, seed = 42)$values
  },
  t6_gene_loss_ordering = function() {
    stop("gene-category dataset not bundled (items 4-6)")
  },
  t7_ltee_cosegregation = function() {
    ltee_cosegregation(seed = 42)$values
  },
  formal_model = function() {
    threshold_model(
      depths = c(0, 1, 2, 3, 5), lambda = 0.15, theta = 2.5,
      m0 = 10, alpha = 0.05, time = 100
    )$values
  },
  empirical_formal_model = function() {
    if (!has_data("orobanchaceae_retention_matrix.tsv")) stop("retention matrix not bundled")
    if (!has_data("island_bird_morphology.csv")) stop("island-bird data not bundled")
    plant <- load_retention_matrix()
    bird <- load_island_birds()
    empirical_formal_model(plant$data, bird$data, seed = 42)$values
  },
  cross_kingdom_l3 = function() {
    if (!has_data("island_bird_morphology.csv")) stop("island-bird data not bundled (items 4-6)")
    plant <- load_orobanchaceae()
    bird <- load_island_birds()
    transfer_test(plant$data, bird$data, seed = 42)$values
  }
)

results <- list()
for (name in names(runners)) {
  res <- tryCatch(
    list(values = runners[[name]](), skipped = NULL),
    error = function(e) list(values = NULL, skipped = conditionMessage(e))
  )
  if (!is.null(res$skipped)) {
    results[[name]] <- list(skipped = res$skipped)
    message(sprintf("SKIP %s: %s", name, res$skipped))
  } else {
    results[[name]] <- list(values = res$values)
    message(sprintf("OK   %s", name))
  }
}

out_path <- file.path(output_dir, "results.yml")
yaml::write_yaml(results, out_path)
cat(sprintf("\nWrote %s (%d stages: %d ok, %d skipped)\n",
  out_path,
  length(results),
  sum(!vapply(results, function(r) is.null(r$values), logical(1))),
  sum(vapply(results, function(r) is.null(r$values), logical(1)))
))
