#' Data loaders for the foundry datasets
#'
#' Each loader reads from the bundled data/ directory, runs the appropriate
#' contract validator, and returns a structured result object (A6: proof
#' object with data + metadata).
#'
#' All loaders follow DFT A1 (pure IO separation): I/O is isolated to
#' these thin wrapper functions. The analysis logic functions they feed
#' are pure — they never touch the filesystem.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): I/O isolated to loaders
#' - A5 (real-fakes): FakeDataLoader returns real dataframes from fixtures
#' - A6 (check-result): loaders return list with data + provenance + validation
#'
#' @name data_loaders
NULL

#' Helper: get data directory path
#'
#' Returns the path to the bundled data directory. Resolves correctly
#' both when running as an installed package and when running from source.
#'
#' @return Character. Path to data/ directory.
#' @keywords internal
get_data_dir <- function(file = NULL) {
  # Try installed package first — but only if it has the requested file
  path <- system.file("data", package = "valence.foundry")
  if (path != "" && dir.exists(path)) {
    if (is.null(file)) {
      return(path)
    }
    if (file.exists(file.path(path, file)) || file.exists(paste0(file.path(path, file), ".gz"))) {
      return(path)
    }
  }
  # Fallback: source tree candidates (path-agnostic; no hardcoded
  # workspace paths — the repo root's data/ dir when running from source)
  candidates <- c("data", file.path("..", "data"))
  for (cand in candidates) {
    if (dir.exists(cand)) {
      if (is.null(file)) {
        return(cand)
      }
      if (file.exists(file.path(cand, file)) || file.exists(paste0(file.path(cand, file), ".gz"))) {
        return(cand)
      }
    }
  }
  "data"
}

#' Resolve a bundled data file, accounting for gzip compression.
#'
#' `R CMD build` may gzip-compress data files (e.g. `.csv` -> `.csv.gz`) in
#' the installed package. This returns the path to the uncompressed file if it
#' exists, otherwise the `.gz` variant, so loaders work against both the
#' source tree and the built/installed package. `read.csv`/`read.table` read
#' `.gz` paths transparently.
#'
#' @param file Character. Filename within data/.
#' @return Character. Path to the file (uncompressed or .gz).
#' @keywords internal
resolve_data_file <- function(file) {
  data_dir <- get_data_dir(file)
  p <- file.path(data_dir, file)
  if (file.exists(p)) {
    return(p)
  }
  pgz <- paste0(p, ".gz")
  if (file.exists(pgz)) {
    return(pgz)
  }
  p
}

#' Helper: create result object (A6: check-result)
#'
#' Wraps data with metadata into a structured proof object.
#'
#' @param data The loaded data.
#' @param name Name of the dataset.
#' @param source Description of data source.
#' @return List with data, metadata (name, source, n, loaded_at).
#' @keywords internal
make_result <- function(data, name, source, ...) {
  extras <- list(...)
  c(
    list(
      data = data,
      metadata = list(
        name = name,
        source = source,
        n = nrow(data),
        loaded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
      )
    ),
    extras
  )
}

#' Load Orobanchaceae plastome data
#'
#' Loads species-level plastome sizes and parasitism scores for
#' Orobanchaceae, along with the phylogenetic tree.
#'
#' @return List with data (plastome data frame), tree (Newick string),
#'   and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework's prediction D5: plastome size correlates with parasitism level.
#' Competitor: relaxed selection (Lahti 2009) predicts the same gradient.
#' This data feeds T1 (PGLS) and T6 (gene-loss ordering).
#'
#' @dft
#' - A1 (pure-io-separation): I/O in loader, logic in analysis functions
#' - A6 (check-result): returns proof object with data + provenance
#'
#' @export
#' @examples
#' \dontrun{
#' result <- load_orobanchaceae()
#' head(result$data)
#' }
load_orobanchaceae <- function() {
  data_path <- resolve_data_file("species_plastome_data.tsv")
  tree_path <- resolve_data_file("orobanchaceae_tree.nwk")

  data <- utils::read.table(data_path,
    header = TRUE, sep = "\t",
    stringsAsFactors = FALSE
  )
  names(data) <- c(
    "species", "genus", "accession", "plastome_size_bp",
    "parasitism_category", "parasitism_score"
  )
  data$plastome_size_kb <- data$plastome_size_bp / 1000

  tree <- readLines(tree_path, n = 1L)

  validate_plastome_data(data)
  validate_parasitism_scores(data$parasitism_score)
  validate_phylo_tree(tree)

  make_result(
    data, "orobanchaceae",
    "NCBI GenBank plastome sizes + parasitism scores",
    tree = tree
  )
}

#' Load cross-family plastome data
#'
#' Loads plastome sizes across multiple independent parasitic plant
#' families for cross-family replication.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework's prediction D5: gene-loss gradient replicates across
#' independently evolved parasitic lineages. Competitor: stochastic gene
#' loss / relaxed selection — both predict the same pattern. Does NOT
#' distinguish the framework from competitors.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_cross_family_plastomes <- function() {
  data_path <- resolve_data_file("cross_family_plastome_data.tsv")

  data <- utils::read.table(data_path,
    header = TRUE, sep = "\t",
    stringsAsFactors = FALSE
  )
  names(data) <- c(
    "species", "family", "accession", "plastome_bp",
    "parasitism_level", "parasitism_score",
    "outgroup_available"
  )
  data$plastome_size_kb <- data$plastome_bp / 1000

  validate_plastome_data(data)
  validate_parasitism_scores(data$parasitism_score)

  make_result(
    data, "cross_family",
    "NCBI GenBank, 12+ parasitic plant families"
  )
}

#' Load endosymbiont genome data
#'
#' Loads genome sizes and host dependency scores for bacterial
#' endosymbionts (Buchnera, Wigglesworthia, Carsonella, Blochmannia).
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework's prediction: biphasic genome reduction (fast Phase 1, slow
#' Phase 2). Competitors: constant rate (Lynch 2007), accelerating
#' (Muller's ratchet). McCutcheon's metabolic complementarity predicts
#' the same correlation — does NOT distinguish the framework from McCutcheon.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_endosymbionts <- function() {
  data_path <- resolve_data_file("endosymbiont_genome_data.tsv")

  data <- utils::read.table(data_path,
    header = TRUE, sep = "\t",
    stringsAsFactors = FALSE
  )

  validate_endosymbiont_data(data)

  make_result(
    data, "endosymbionts",
    "GenBank: Buchnera, Wigglesworthia, Carsonella, Blochmannia"
  )
}

#' Load Bobay-Ochman niche data
#'
#' Loads the Bobay & Ochman (2017) Table S1 data with Ne, genome size,
#' and lifestyle classifications for 140+ species.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework's prediction D3: niche breadth predicts gene loss better than
#' Ne alone. Competitor: drift (Lynch 2007) predicts Ne is primary.
#' DOES distinguish the framework from drift.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_bobay_ochman <- function() {
  data_path <- resolve_data_file("bobay_ochman_table_s1.xlsx")

  data <- readxl::read_xlsx(data_path, skip = 1)
  data <- as.data.frame(data)
  names(data) <- make.names(names(data))

  validate_niche_data(data)

  make_result(
    data, "bobay_ochman",
    "Bobay & Ochman (2017) Table S1, 140+ species"
  )
}

#' Load Dewar pan-genome data
#'
#' Loads pangenome fluidity and lifestyle data from Dewar et al. (2024).
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework's prediction: pan-genome openness tracks lifestyle (commensal
#' vs free-living). Competitor: Ne-only model. DOES distinguish the framework.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_dewar_pangenome <- function() {
  data_path <- resolve_data_file("dewar_pangenome_lifestyles.csv")

  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)

  validate_pangenome_data(data)

  make_result(
    data, "dewar_pangenome",
    "Dewar et al. (2024) supplementary, pan-genome lifestyles"
  )
}

#' Load island bird morphology data
#'
#' Loads morphological change rankings for island bird flight-loss traits.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests the framework L3 Prediction: plant-derived integration-depth parameters
#' predict bird morphological change ordering across kingdoms.
#' Competitor: substrates are independent — no parameter transfer.
#' DOES distinguish the framework. This is the strongest test in the monograph.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_island_birds <- function() {
  data_path <- resolve_data_file("island_bird_morphology.csv")

  if (!file.exists(data_path)) {
    stop("island_bird_morphology.csv not found. Run data preparation first.",
      call. = FALSE
    )
  }

  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)

  validate_bird_morphology(data)

  make_result(
    data, "island_birds",
    "Island bird flight-loss morphological rankings"
  )
}

#' Load Orobanchaceae retention matrix
#
#' Loads the 8-species × 6-gene-category plastid-gene retention matrix with
#' parasitism scores and integration-depth (dependency) scores. This is the
#' empirical data for the formal model (the author's original 8×6 matrix,
#' correctly flattened gene-major — see Remark R7).
#
#' @return List with data (data frame) and metadata.
#
#' @section Theoretical Context:
#
#' The retention matrix is the empirical basis for `empirical_formal_model()`:
#' the framework predicts dep > 0 (deeper integration → more retention) and para < 0
#' (deeper parasitism → less retention). The competitor (random loss)
#' predicts no dep effect. The author's original additive GLM produced the
#' wrong sign due to a data-flattening bug (`as.vector(t(retention))` is
#' species-major; `rep(dep_scores, each=8)` is gene-major). This dataset
#' uses the corrected flattening (`as.vector(retention)`, gene-major).
#
#' @dft
#' - A1, A6
#'
#' @export
load_retention_matrix <- function() {
  data_path <- resolve_data_file("orobanchaceae_retention_matrix.tsv")

  if (!file.exists(data_path)) {
    stop("orobanchaceae_retention_matrix.tsv not found.", call. = FALSE)
  }

  data <- utils::read.table(data_path,
    header = TRUE, sep = "\t",
    stringsAsFactors = FALSE
  )

  validate_retention_data(data)

  make_result(
    data, "retention_matrix",
    "Orobanchaceae 8x6 plastid-gene retention matrix (corrected flattening)"
  )
}
