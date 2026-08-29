# test-unit-data-loaders.R — Unit tests for data loaders
# DFT A5: fake_data_loader returns real dataframes, not mock recordings
# Tests: loaders return expected dims, correct types, contracts pass

library(testthat)

context("Data loaders")

# Use fake_data_loader for tests that don't touch the filesystem
# (DFT A5: real fakes, not mocks)

test_that("fake_data_loader returns orobanchaceae fixture", {
  loader <- fake_data_loader
  data <- loader$load("orobanchaceae")
  expect_s3_class(data, "data.frame")
  expect_equal(nrow(data), 5)
  expect_true("plastome_size_kb" %in% names(data) || "plastome_size_bp" %in% names(data))
  expect_true("parasitism_score" %in% names(data))
})

test_that("fake_data_loader returns gene categories fixture", {
  loader <- fake_data_loader
  data <- loader$load("gene_categories")
  expect_s3_class(data, "data.frame")
  expect_equal(nrow(data), 6)
  expect_true("dependency_score" %in% names(data))
  expect_true("orobanchaceae_loss_rank" %in% names(data))
})

test_that("fake_data_loader returns bird morphology fixture", {
  loader <- fake_data_loader
  data <- loader$load("bird_morphology")
  expect_s3_class(data, "data.frame")
  expect_equal(nrow(data), 8)
  expect_true("dependency_score" %in% names(data))
  expect_true("observed_rank" %in% names(data))
})

test_that("fake_data_loader lists available fixtures", {
  loader <- fake_data_loader
  available <- loader$list_available()
  expect_true("orobanchaceae" %in% available)
  expect_true("gene_categories" %in% available)
  expect_true("bird_morphology" %in% available)
})

test_that("fake_data_loader errors on unknown fixture", {
  loader <- fake_data_loader
  expect_error(loader$load("nonexistent"), "Unknown fixture")
})

# Tests that use bundled data (skip if data not available)

test_that("load_orobanchaceae returns valid result with data and tree", {
  skip_if_not(
    has_bundled_data("species_plastome_data.tsv"),
    "Bundled data not available"
  )

  result <- load_orobanchaceae()

  # A6: check-result — returns structured proof object
  expect_true(is_data_result(result))
  expect_true("data" %in% names(result))
  expect_true("metadata" %in% names(result))

  # Data structure
  expect_s3_class(result$data, "data.frame")
  expect_true("plastome_size_kb" %in% names(result$data))
  expect_true("parasitism_score" %in% names(result$data))
  expect_true(all(result$data$parasitism_score >= 0))
  expect_true(all(result$data$parasitism_score <= 4))

  # Metadata
  expect_equal(result$metadata$name, "orobanchaceae")
  expect_true(result$metadata$n > 0)
})

test_that("load_cross_family_plastomes returns valid result", {
  skip_if_not(
    has_bundled_data("cross_family_plastome_data.tsv"),
    "Bundled data not available"
  )

  result <- load_cross_family_plastomes()
  expect_true(is_data_result(result))
  expect_true("family" %in% names(result$data))
  expect_true(result$metadata$n > 10)
})

test_that("load_endosymbionts returns valid result", {
  skip_if_not(
    has_bundled_data("endosymbiont_genome_data.tsv"),
    "Bundled data not available"
  )

  result <- load_endosymbionts()
  expect_true(is_data_result(result))
  expect_true("genome_bp" %in% names(result$data))
  expect_true("symbiosis_age_mya" %in% names(result$data))
  expect_true(all(result$data$genome_bp > 0))
})

test_that("load_dewar_pangenome returns valid result", {
  skip_if_not(
    has_bundled_data("dewar_pangenome_lifestyles.csv"),
    "Bundled data not available"
  )

  result <- load_dewar_pangenome()
  expect_true(is_data_result(result))
  expect_true("pangenome_fluidity" %in% names(result$data))
  expect_true(all(result$data$pangenome_fluidity >= 0))
  expect_true(all(result$data$pangenome_fluidity <= 1))
})

test_that("load_bobay_ochman returns valid result", {
  skip_if_not(
    has_bundled_data("bobay_ochman_table_s1.xlsx"),
    "Bundled data not available"
  )
  skip_if_not(requireNamespace("readxl", quietly = TRUE), "readxl not installed")

  result <- load_bobay_ochman()
  expect_true(is_data_result(result))
  expect_true(result$metadata$n >= 100)
})

test_that("load_island_birds errors gracefully when data missing", {
  skip_if(
    has_bundled_data("island_bird_morphology.csv"),
    "Bird data exists — test the positive path instead"
  )

  expect_error(load_island_birds(), "not found")
})

test_that("load_island_birds returns valid result when data bundled", {
  skip_if_not(
    has_bundled_data("island_bird_morphology.csv"),
    "Bird data not bundled"
  )

  result <- load_island_birds()
  expect_true(is_data_result(result))
  expect_true("structure" %in% names(result$data))
  expect_true("dependency_score" %in% names(result$data))
  expect_true("observed_rank" %in% names(result$data))
  expect_true(result$metadata$n >= 5)
})

test_that("load_retention_matrix returns valid result", {
  skip_if_not(
    has_bundled_data("orobanchaceae_retention_matrix.tsv"),
    "Retention matrix not bundled"
  )

  result <- load_retention_matrix()
  expect_true(is_data_result(result))
  expect_s3_class(result$data, "data.frame")
  expect_equal(result$metadata$name, "retention_matrix")
  expect_equal(result$metadata$n, 48) # 8 species x 6 gene categories
  expect_true("species" %in% names(result$data))
  expect_true("parasitism_score" %in% names(result$data))
  expect_true("gene_category" %in% names(result$data))
  expect_true("dependency_score" %in% names(result$data))
  expect_true("retention" %in% names(result$data))
  expect_true(all(result$data$retention >= 0))
  expect_true(all(result$data$retention <= 1))
})

test_that("all loaders return A6 proof objects with metadata", {
  skip_if_not(
    has_bundled_data("species_plastome_data.tsv"),
    "Bundled data not available"
  )

  result <- load_orobanchaceae()

  # A6: check-result pattern
  expect_true(is.list(result))
  expect_true("data" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_true("name" %in% names(result$metadata))
  expect_true("source" %in% names(result$metadata))
  expect_true("n" %in% names(result$metadata))
  expect_true("loaded_at" %in% names(result$metadata))
})
