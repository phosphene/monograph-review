#' Contract validators for valence foundry data
#'
#' These functions validate inputs at function entry and outputs at exit,
#' enforcing the MPI Handoff Blueprint's pure-function contract discipline.
#' Every function in the package passes data through these validators before
#' processing and before returning results.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): validators are pure — no I/O, no side effects
#' - A6 (check-result): validators return structured validation results
#'
#' @name contracts
NULL

#' Validate a phylogenetic tree (Newick string)
#'
#' Checks that the input is a single character string containing a valid
#' Newick-format phylogeny with at least 3 taxa.
#'
#' @param tree Character scalar. Newick-format tree string.
#' @param min_taxa Integer. Minimum number of taxa. Default 3.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Phylogenetic trees are required for PGLS (T1, T2) to correct for
#' non-independence of species due to shared evolutionary history. Valence's
#' PGLS predictions require a resolved tree with branch lengths. A
#' competitor using non-phylogenetic regression (OLS) does not need this
#' contract — but OLS inflates false positives when species are
#' phylogenetically correlated.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A6 (check-result): returns structured result or stops with error
#'
#' @export
#' @examples
#' \dontrun{
#' validate_phylo_tree("(A:0.1,(B:0.2,C:0.3):0.1);")
#' }
validate_phylo_tree <- function(tree, min_taxa = 3L) {
  if (!is.character(tree) || length(tree) != 1L) {
    stop("tree must be a single character string (Newick format)", call. = FALSE)
  }
  if (nchar(tree) == 0L) {
    stop("tree must not be empty", call. = FALSE)
  }
  if (!grepl("^\\s*\\(", tree)) {
    stop("tree must start with '(' (Newick format)", call. = FALSE)
  }
  if (!grepl(";\\s*$", tree)) {
    stop("tree must end with ';' (Newick format)", call. = FALSE)
  }
  # Count taxa by counting colons (branch lengths) or labels
  taxa_count <- length(regmatches(tree, gregexpr("[A-Za-z_][A-Za-z0-9_]*:", tree))[[1]])
  if (taxa_count < min_taxa) {
    stop(sprintf("tree has %d taxa, need >= %d", taxa_count, min_taxa), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate plastome data
#'
#' Checks that the input is a data frame with required columns for PGLS
#' analysis: species name, plastome size, and parasitism score.
#'
#' @param data Data frame with species, plastome size, and parasitism columns.
#' @param required_cols Character vector. Required column names.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Plastome data tests valence's prediction that genome reduction tracks
#' parasitism depth (integration-depth ordering). The competitor
#' (relaxed selection, Lahti 2009) predicts the same gradient but
#' through a different mechanism. This data alone cannot distinguish
#' the two — that requires gene_category_spearman() for ordering.
#'
#' @dft
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A6 (check-result): returns structured result or stops with error
#'
#' @export
validate_plastome_data <- function(data,
                                   required_cols = c(
                                     "species", "plastome_size_kb",
                                     "parasitism_score"
                                   )) {
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  missing <- setdiff(required_cols, names(data))
  if (length(missing) > 0L) {
    stop(sprintf("data missing required columns: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  if (!is.numeric(data$plastome_size_kb)) {
    stop("plastome_size_kb must be numeric", call. = FALSE)
  }
  if (any(data$plastome_size_kb < 0, na.rm = TRUE)) {
    stop("plastome_size_kb must be non-negative", call. = FALSE)
  }
  if (!is.numeric(data$parasitism_score)) {
    stop("parasitism_score must be numeric", call. = FALSE)
  }
  if (any(data$parasitism_score < 0, na.rm = TRUE)) {
    stop("parasitism_score must be non-negative", call. = FALSE)
  }
  if (nrow(data) < 3L) {
    stop(sprintf("data has %d rows, need >= 3", nrow(data)), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate parasitism scores
#'
#' Checks that parasitism scores are integers 0–4 (autotroph to extreme
#' holoparasite), matching the Orobanchaceae gradient.
#'
#' @param scores Numeric vector. Parasitism scores (0 = autotroph, 4 = extreme holoparasite).
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' The parasitism score is valence's integration-depth proxy for Orobanchaceae:
#' higher score = deeper niche commitment = more capacity reallocation.
#' The competitor (relaxed selection) treats this as a time-since-relaxation
#' proxy. Both use the same variable but interpret it differently.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_parasitism_scores <- function(scores) {
  if (!is.numeric(scores)) {
    stop("scores must be numeric", call. = FALSE)
  }
  if (any(scores < 0, na.rm = TRUE) || any(scores > 4, na.rm = TRUE)) {
    stop("scores must be in range [0, 4]", call. = FALSE)
  }
  if (any(scores != floor(scores), na.rm = TRUE)) {
    stop("scores must be integers", call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate endosymbiont data
#'
#' Checks that the input has required columns for biphasic genome
#' reduction modeling: genome size, host dependency, symbiosis age.
#'
#' @param data Data frame with genome size and host dependency columns.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Endosymbiont data tests valence's biphasic kinetics prediction: fast
#' initial genome reduction (Phase 1) followed by slow reduction (Phase 2).
#' The competitor (constant-rate, Lynch 2007) predicts linear reduction.
#' McCutcheon's metabolic complementarity predicts the same correlation
#' as valence — this test does NOT distinguish valence from McCutcheon.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_endosymbiont_data <- function(data) {
  required <- c("species", "genome_bp", "aa_pathways_retained", "symbiosis_age_mya")
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf("data missing required columns: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  if (!is.numeric(data$genome_bp) || any(data$genome_bp <= 0, na.rm = TRUE)) {
    stop("genome_bp must be positive numeric", call. = FALSE)
  }
  if (!is.numeric(data$aa_pathways_retained) ||
        any(data$aa_pathways_retained < 0, na.rm = TRUE)) {
    stop("aa_pathways_retained must be non-negative numeric", call. = FALSE)
  }
  if (!is.numeric(data$symbiosis_age_mya) ||
        any(data$symbiosis_age_mya <= 0, na.rm = TRUE)) {
    stop("symbiosis_age_mya must be positive numeric", call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate gene category data
#'
#' Checks that the input maps gene categories to integration-depth
#' scores and loss ranks across lineages.
#'
#' @param data Data frame with category, dependency_score, and loss rank columns.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Gene category data tests valence's integration-depth ordering prediction:
#' deeply integrated functions (high dependency score) resist loss more
#' than shallowly integrated ones. The competitor (random loss) predicts
#' no ordering. This test DOES distinguish valence from random loss — it is
#' one of the distinguishing tests in the monograph.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_gene_categories <- function(data) {
  required <- c("category", "dependency_score")
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf("data missing required columns: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  if (!is.numeric(data$dependency_score)) {
    stop("dependency_score must be numeric", call. = FALSE)
  }
  if (any(data$dependency_score < 0, na.rm = TRUE)) {
    stop("dependency_score must be non-negative", call. = FALSE)
  }
  # Check for at least one loss rank column
  loss_cols <- grep("_loss_rank$", names(data), value = TRUE)
  if (length(loss_cols) < 1L) {
    stop("data must have at least one '*_loss_rank' column", call. = FALSE)
  }
  for (col in loss_cols) {
    if (!is.numeric(data[[col]])) {
      stop(sprintf("%s must be numeric", col), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Validate bird morphology data
#'
#' Checks that the input has structure names, dependency scores, and
#' observed morphological change ranks for island bird flight-loss.
#'
#' @param data Data frame with structure, dependency_score, and observed_rank.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Bird morphology data tests the L3 cross-kingdom prediction: plant-derived
#' integration-depth parameters predict bird morphological change ordering.
#' The competitor (substrates are independent) predicts no transfer. This
#' test DOES distinguish valence — it is the strongest test in the monograph.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_bird_morphology <- function(data) {
  required <- c("structure", "dependency_score", "observed_rank")
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf("data missing required columns: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  if (!is.numeric(data$dependency_score)) {
    stop("dependency_score must be numeric", call. = FALSE)
  }
  if (!is.numeric(data$observed_rank)) {
    stop("observed_rank must be numeric", call. = FALSE)
  }
  if (any(data$observed_rank < 1, na.rm = TRUE)) {
    stop("observed_rank must be >= 1 (1 = first to change)", call. = FALSE)
  }
  if (nrow(data) < 5L) {
    stop(sprintf("data has %d structures, need >= 5 for Spearman", nrow(data)),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Validate Orobanchaceae retention-matrix data
#
#' Checks that the input maps species × gene-category retention probabilities
#' with parasitism scores and integration-depth (dependency) scores — the
#' 8×6 matrix from the author's formal-model script (correctly flattened:
#' gene-major, one row per species-gene pair).
#
#' @param data Data frame with species, parasitism_score, gene_category,
#'   dependency_score, and retention columns.
#
#' @return Invisible TRUE if valid. Stops with error if invalid.
#
#' @section Theoretical Context:
#
#' The retention matrix is the empirical data for the formal model: it
#' records plastid-gene retention (0–1) for 8 Orobanchaceae species across a
#' parasitism gradient (0–4) and 6 gene categories with dependency scores
#' (0–5). Valence predicts: higher dependency → higher retention (dep > 0);
#' deeper parasitism → lower retention (para < 0). The competitor (random
#' loss) predicts no dep effect. The author's original GLM produced the wrong
#' sign because of a data-flattening bug (Remark R7); this validator guards
#' the corrected dataset.
#
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_retention_data <- function(data) {
  required <- c(
    "species", "parasitism_score", "gene_category",
    "dependency_score", "retention"
  )
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(sprintf(
      "data missing required columns: %s",
      paste(missing, collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.numeric(data$parasitism_score)) {
    stop("parasitism_score must be numeric", call. = FALSE)
  }
  if (any(data$parasitism_score < 0, na.rm = TRUE)) {
    stop("parasitism_score must be non-negative", call. = FALSE)
  }
  if (!is.numeric(data$dependency_score)) {
    stop("dependency_score must be numeric", call. = FALSE)
  }
  if (any(data$dependency_score < 0, na.rm = TRUE)) {
    stop("dependency_score must be non-negative", call. = FALSE)
  }
  if (!is.numeric(data$retention)) {
    stop("retention must be numeric", call. = FALSE)
  }
  if (any(data$retention < 0, na.rm = TRUE) ||
        any(data$retention > 1, na.rm = TRUE)) {
    stop("retention must be in [0, 1]", call. = FALSE)
  }
  if (nrow(data) < 10L) {
    stop(sprintf("data has %d rows, need >= 10 for GLM", nrow(data)),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Validate Bobay-Ochman niche data
#'
#' Checks that the input has species, Ne, and niche breadth columns
#' for the Ne vs niche regression.
#'
#' @param data Data frame with species, Ne, and niche-related columns.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Bobay-Ochman data tests valence's prediction that niche breadth predicts
#' gene loss better than Ne alone. The competitor (drift, Lynch 2007)
#' predicts Ne is the primary driver. This test DOES distinguish valence
#' from drift — it is a distinguishing test.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_niche_data <- function(data) {
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  # Must have either Ne or a column containing "Ne"
  ne_cols <- grep("Ne|ne", names(data), value = TRUE)
  if (length(ne_cols) < 1L) {
    stop("data must have a column containing 'Ne' (effective population size)",
      call. = FALSE
    )
  }
  # Must have lifestyle or niche breadth column
  niche_cols <- grep("niche|lifestyle|Life|habitat", names(data),
    value = TRUE, ignore.case = TRUE
  )
  if (length(niche_cols) < 1L) {
    stop("data must have a niche/lifestyle/habitat column", call. = FALSE)
  }
  if (nrow(data) < 10L) {
    stop(sprintf("data has %d rows, need >= 10 for regression", nrow(data)),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Validate pangenome data
#'
#' Checks that the input has species, pangenome fluidity, and lifestyle
#' columns for the pan-genome openness test.
#'
#' @param data Data frame with pangenome fluidity and lifestyle columns.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section Theoretical Context:
#'
#' Pangenome data tests valence's prediction that pan-genome openness tracks
#' lifestyle (commensal vs free-living). The competitor (Ne-only model)
#' predicts Ne drives pangenome size regardless of lifestyle. This test
#' DOES distinguish valence from the Ne-only model.
#'
#' @dft
#' - A1 (pure-io-separation): pure function
#'
#' @export
validate_pangenome_data <- function(data) {
  if (!is.data.frame(data)) {
    stop("data must be a data.frame", call. = FALSE)
  }
  if (!"pangenome_fluidity" %in% names(data)) {
    stop("data must have 'pangenome_fluidity' column", call. = FALSE)
  }
  lifestyle_cols <- grep("lifestyle|Life|Host_or_free|Obligate",
    names(data),
    value = TRUE, ignore.case = TRUE
  )
  if (length(lifestyle_cols) < 1L) {
    stop("data must have a lifestyle/host-association column", call. = FALSE)
  }
  if (!is.numeric(data$pangenome_fluidity)) {
    stop("pangenome_fluidity must be numeric", call. = FALSE)
  }
  if (any(data$pangenome_fluidity < 0, na.rm = TRUE) ||
        any(data$pangenome_fluidity > 1, na.rm = TRUE)) {
    stop("pangenome_fluidity must be in [0, 1]", call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate analysis results (check-result pattern, A6)
#'
#' Verifies that a function returned a properly structured result object
#' with data, metadata, and validation status.
#'
#' @param result List. Expected to contain 'values' and 'metadata'.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#'
#' @section DFT Axioms:
#' - A6 (check-result): validates that functions return proof objects
#'
#' @export
validate_result <- function(result) {
  if (!is.list(result)) {
    stop("result must be a list", call. = FALSE)
  }
  if (!"values" %in% names(result)) {
    stop("result must contain 'values'", call. = FALSE)
  }
  if (!"metadata" %in% names(result)) {
    stop("result must contain 'metadata'", call. = FALSE)
  }
  meta <- result$metadata
  if (!is.list(meta)) {
    stop("metadata must be a list", call. = FALSE)
  }
  if (!"seed" %in% names(meta)) {
    warning("metadata should contain 'seed' for reproducibility", call. = FALSE)
  }
  if (!"n" %in% names(meta)) {
    warning("metadata should contain 'n' (sample size)", call. = FALSE)
  }
  invisible(TRUE)
}
