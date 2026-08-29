#' Data loaders for the framework cultural evolution datasets
#'
#' Each loader reads from the bundled data/ directory, runs validation,
#' and returns a structured result object (A6: proof object).
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): I/O isolated to loaders
#' - A6 (check-result): loaders return list with data + provenance
#'
#' @name cultural_data_loaders
NULL

#' Load Oswalt (1973) Table 7-2 — 12 societies with technounit data
#'
#' Oswalt, W.H. (1973) Habitat and Technology: The Evolution of Hunting.
#' Holt, Rinehart and Winston. Table 7-2, p. 161.
#'
#' @return List with data (data frame) and metadata.
#' @export
load_oswalt_1973 <- function() {
  data_path <- resolve_data_file("oswalt_1973_table7_2.csv")
  if (!file.exists(data_path)) {
    stop("oswalt_1973_table7_2.csv not found.", call. = FALSE)
  }
  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data$beta <- (data$components / data$types) - 1
  data$log_N <- log10(data$population_estimate)
  data$log_types <- log10(data$types)
  data$log_components <- log10(data$components)
  make_result(data, "oswalt_1973",
    "Oswalt 1973 Table 7-2: 12 societies, subsistence technology")
}

#' Load Oswalt (1976) Appendix — 29 societies with technounit data
#'
#' Oswalt, W.H. (1976) An Anthropological Analysis of Food-Getting
#' Technology. Wiley. Appendix: "Subsistants and their Technounits" (p. 233+).
#'
#' @return List with data (data frame) and metadata.
#' @export
load_oswalt_1976 <- function() {
  data_path <- resolve_data_file("oswalt_1976_technounits.csv")
  if (!file.exists(data_path)) {
    stop("oswalt_1976_technounits.csv not found.", call. = FALSE)
  }
  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data$beta <- (data$technounits / data$subsistants) - 1
  data$log_N <- log10(data$population_estimate)
  data$log_subsistants <- log10(data$subsistants)
  data$log_technounits <- log10(data$technounits)
  make_result(data, "oswalt_1976",
    "Oswalt 1976 Appendix: 29 societies, food-getting technology")
}

#' Load cross-domain beta comparison table
#'
#' Beta estimates across 12 cultural and biological domains.
#'
#' @return List with data (data frame) and metadata.
#' @export
load_cross_domain_beta <- function() {
  data_path <- resolve_data_file("cross_domain_beta.csv")
  if (!file.exists(data_path)) {
    stop("cross_domain_beta.csv not found.", call. = FALSE)
  }
  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  make_result(data, "cross_domain_beta",
    "Cross-domain beta estimates: 12 domains")
}

#' Load USPTO cumulative patent data (1836-2023)
#'
#' Source: Our World in Data (aggregates USPTO directly).
#'
#' @return List with data (data frame) and metadata.
#' @export
load_uspto_patents <- function() {
  data_path <- resolve_data_file("uspto_cumulative_patents.csv")
  if (!file.exists(data_path)) {
    stop("uspto_cumulative_patents.csv not found.", call. = FALSE)
  }
  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data$log_cumulative <- log10(data$cumulative_patents)
  data$year_centered <- data$year - mean(data$year)
  make_result(data, "uspto_patents",
    "USPTO utility patents 1836-2023 (Our World in Data)")
}
