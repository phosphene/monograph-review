#' P-Series: A Priori Integration-Depth Tests (Two-Component Metric)
#'
#' Corrected operationalization of integration depth, per the a priori
#' measurement protocol (`integration-depth-a-priori-protocol.md`). Two
#' components, both measured from the ancestral/undisturbed state, blind to
#' outcome:
#'
#' - **Component A — niche mismatch:** whether the occupied niche still demands
#'   a node's function (FBA essentiality under the occupied-niche condition,
#'   or a functional-category demand proxy). High mismatch -> shed in the fast
#'   phase.
#' - **Component B — integration position:** regulatory in-degree / dependency
#'   score / network centrality in the ancestral network. Among retained
#'   (low-mismatch) nodes, high integration -> conserved through the slow
#'   phase.
#'
#' The P-series replaces the naive global-centrality operationalization that
#' was falsified in E4-revised and T7-v2 (see negative ledger in the test pile).
#' Every stage consumes a pre-registered score file from `data/a-priori-scores/`
#' (frozen before outcome merge) and returns an A6 proof object.
#'
#' @name p_series
NULL

#' P1: Buchnera two-component retention
#'
#' Does the two-component metric (niche demand + integration position) predict
#' gene retention in Buchnera, where the naive global-centrality metric failed?
#'
#' Component B (integration position) = iJO1366 dependency_score, measured a
#' priori from the E. coli ancestor. Component A (niche demand) = functional
#' category proxy: amino-acid/cofactor biosynthesis genes are low-mismatch in
#' the aphid niche (host cannot supply them -> retained); other central
#' metabolism is high-mismatch (host supplies it -> shed). Aphid-condition FBA
#' is not yet available; the functional-category demand proxy is documented
#' metadata, not a hidden choice.
#'
#' @param scores Data frame from `data/a-priori-scores/p1_buchnera_scores.tsv`
#'   with columns: gene_id, name, dependency_score, essential, retained.
#' @param seed Integer. Seed for reproducibility.
#' @return List (A6 proof object): values + metadata.
#' @export
p1_buchnera_two_component <- function(scores, seed = 42L) {
  set.seed(seed)
  d <- scores[!is.na(scores$dependency_score), ]

  # Component B alone (replicates E4-revised): retained ~ dependency_score
  model_b <- glm(retained ~ dependency_score, data = d, family = binomial)
  # Component A alone (demand proxy): retained ~ essential
  # essential column is a 3-level string (essential/partial/nonessential)
  d$essential_flag <- as.integer(d$essential == "essential")
  model_a <- glm(retained ~ essential_flag, data = d, family = binomial)
  # Two-component model
  model_ab <- glm(retained ~ dependency_score + essential_flag, data = d, family = binomial)

  p_b <- summary(model_b)$coefficients["dependency_score", "Pr(>|z|)"]
  p_a <- summary(model_a)$coefficients["essential_flag", "Pr(>|z|)"]
  p_ab <- summary(model_ab)$coefficients["dependency_score", "Pr(>|z|)"]
  p_ab_essential <- summary(model_ab)$coefficients["essential_flag", "Pr(>|z|)"]

  r2_B <- 1 - as.numeric(logLik(model_b)) / as.numeric(logLik(glm(retained ~ 1, data = d, family = binomial)))
  r2_AB <- 1 - as.numeric(logLik(model_ab)) / as.numeric(logLik(glm(retained ~ 1, data = d, family = binomial)))

  # Niche-demand set: amino-acid / cofactor biosynthesis (low mismatch)
  aa_genes <- c(
    "argA", "argB", "argC", "argD", "argE", "argF", "argG", "argH", "argI",
    "ilvA", "ilvB", "ilvC", "ilvD", "ilvE", "ilvG", "ilvH", "ilvI", "ilvL", "ilvM", "ilvN",
    "leuA", "leuB", "leuC", "leuD",
    "lysA", "lysC",
    "metA", "metB", "metC", "metE", "metF", "metH", "metK", "metL", "metN", "metQ", "metR", "metT", "metW", "metY",
    "thrA", "thrB", "thrC",
    "trpA", "trpB", "trpC", "trpD", "trpE",
    "pheA", "pheB", "pheT", "pheS",
    "hisA", "hisB", "hisC", "hisD", "hisF", "hisG", "hisH", "hisI",
    "tyrA", "tyrB",
    "serA", "serB", "serC",
    "glyA",
    "proA", "proB", "proC",
    "cysE", "cysK", "cysM", "cysC", "cysD", "cysH", "cysI", "cysJ", "cysN", "cysP", "cysQ", "cysW", "cysU",
    "folA", "folB", "folC", "folD", "folE", "folK", "folP",
    "panB", "panC", "panD", "panE", "panF",
    "bioA", "bioB", "bioC", "bioD", "bioF", "bioH",
    "ribA", "ribB", "ribC", "ribD", "ribE", "ribF", "ribH",
    "nadA", "nadB", "nadC", "nadD", "nadE",
    "pdxA", "pdxB", "pdxH", "pdxK", "pdxY",
    "thiC", "thiD", "thiE", "thiF", "thiG", "thiH", "thiL", "thiM",
    "ubiA", "ubiB", "ubiC", "ubiD", "ubiE", "ubiF", "ubiG", "ubiH", "ubiX",
    "menA", "menB", "menC", "menD", "menE", "menF", "menG", "menH",
    "entA", "entB", "entC", "entD", "entE", "entF", "entS", "entT", "entX", "entY",
    "aroA", "aroB", "aroC", "aroD", "aroE", "aroF", "aroG", "aroH", "aroK", "aroL", "aroQ",
    "aspA", "aspC", "aspS",
    "gltA", "gltB", "gltD", "gltX",
    "asd", "dapA", "dapB", "dapC", "dapD", "dapE", "dapF", "dapH", "dapX",
    "pyrB", "pyrC", "pyrD", "pyrE", "pyrF", "pyrG", "pyrH", "pyrI", "pyrL", "pyrX",
    "carA", "carB", "purA", "purB", "purC", "purD", "purE", "purF",
    "purG", "purH", "purK", "purL", "purM", "purN", "purR", "purT",
    "purU",
    "guaA", "guaB",
    "upp", "udp", "udk",
    "deoA", "deoB", "deoC", "deoD",
    "tktA", "tktB", "talA", "talB",
    "rfa", "lpxA", "lpxB", "lpxC", "lpxD", "lpxK", "lpxL", "lpxM",
    "fabA", "fabB", "fabD", "fabF", "fabG", "fabH", "fabI", "fabZ",
    "accA", "accB", "accC", "accD",
    "pabA", "pabB", "pabC",
    "thyA"
  )
  d$low_mismatch <- as.integer(d$name %in% aa_genes)
  # Within the low-mismatch (niche-demand) set, does Component B order retention?
  data_lm <- d[d$low_mismatch == 1, ]
  rho_LM <- NA
  p_rho_lm <- NA
  if (nrow(data_lm) >= 3 && length(unique(data_lm$retained)) > 1) {
    ct <- cor.test(data_lm$dependency_score, data_lm$retained, method = "spearman")
    rho_LM <- ct$estimate
    p_rho_lm <- ct$p.value
  }

  list(
    values = list(
      beta_B = unname(coef(model_b)["dependency_score"]),
      p_B = p_b,
      beta_A = unname(coef(model_a)["essential"]),
      p_A = p_a,
      beta_B_AB = unname(coef(model_ab)["dependency_score"]),
      p_B_AB = p_ab,
      p_A_AB = p_ab_essential,
      pseudo_r2_B = r2_B,
      pseudo_r2_AB = r2_AB,
      rho_componentB_lowmismatch = rho_LM,
      p_rho_componentB_lowmismatch = p_rho_lm,
      n = nrow(d),
      n_low_mismatch = nrow(data_lm)
    ),
    metadata = list(
      seed = seed,
      n = nrow(d),
      n_retained = sum(d$retained),
      test = "p1_buchnera_two_component",
      components = paste0(
        "A: functional-category demand proxy (amino-acid/cofactor biosynthesis); ",
        "B: iJO1366 dependency_score"
      ),
      a_priori = "scores frozen pre-outcome; retained merged at registration",
      note = "Replaces naive global-centrality operationalization falsified in E4-revised"
    )
  )
}

#' P2: LTEE loss timing with niche-specific FBA
#'
#' Does niche-specific mismatch (Component A) predict loss timing in the LTEE,
#' and does integration position (Component B) order timing among survivors?
#'
#' Component A = niche_mismatch flag: essential in rich media (dep_full=1) but
#' dispensable in LTEE glucose-minimal (dep_ltee_env=0) -> high mismatch ->
#' predict EARLY loss. Component B = string_ppi_degree (integration position).
#' Tests the refined prediction from T7-v2: niche-specific dependency, not
#' global integration, drives loss timing.
#'
#' @param scores Data frame from `data/a-priori-scores/p2_ltee_scores.tsv` with
#'   columns: gene, b_number, fba_dep_full, fba_dep_ltee_env,
#'   string_ppi_degree, niche_mismatch, first_gen.
#' @param seed Integer. Seed for reproducibility.
#' @return List (A6 proof object): values + metadata.
#' @export
p2_ltee_niche_fba <- function(scores, seed = 42L) {
  set.seed(seed)
  d <- scores
  d$first_gen <- as.numeric(d$first_gen)

  # Component A: niche-mismatch genes lost earlier? (Mann-Whitney on first_gen)
  mm_test <- tryCatch(
    wilcox.test(first_gen ~ niche_mismatch, data = d, alternative = "less"),
    error = function(e) NULL
  )
  median_high_mm <- median(d$first_gen[d$niche_mismatch == 1], na.rm = TRUE)
  median_low_mm <- median(d$first_gen[d$niche_mismatch == 0], na.rm = TRUE)
  p_mm <- if (is.null(mm_test)) NA else mm_test$p.value

  # Component B: among low-mismatch genes, does integration position (STRING degree) order timing?
  data_lm <- d[d$niche_mismatch == 0 & !is.na(d$string_ppi_degree), ]
  rho_B <- NA
  p_rho_b <- NA
  if (nrow(data_lm) >= 3) {
    ct <- cor.test(data_lm$string_ppi_degree, data_lm$first_gen, method = "spearman")
    rho_B <- ct$estimate
    p_rho_b <- ct$p.value
  }

  # Component B on full set (T7-v2 replication): degree vs timing
  data_full <- d[!is.na(d$string_ppi_degree), ]
  rho_full <- NA
  p_rho_full <- NA
  if (nrow(data_full) >= 3) {
    ct <- cor.test(data_full$string_ppi_degree, data_full$first_gen, method = "spearman")
    rho_full <- ct$estimate
    p_rho_full <- ct$p.value
  }

  list(
    values = list(
      median_first_gen_high_mismatch = median_high_mm,
      median_first_gen_low_mismatch = median_low_mm,
      p_earlier_high_mismatch = p_mm,
      n_high_mismatch = sum(d$niche_mismatch == 1, na.rm = TRUE),
      rho_degree_timing_lowmismatch = rho_B,
      p_rho_degree_timing_lowmismatch = p_rho_b,
      n_low_mismatch_deg = nrow(data_lm),
      rho_degree_timing_full = rho_full,
      p_rho_degree_timing_full = p_rho_full,
      n = nrow(d)
    ),
    metadata = list(
      seed = seed,
      n = nrow(d),
      test = "p2_ltee_niche_fba",
      components = "A: niche_mismatch (rich-essential & glucose-dispensable); B: string_ppi_degree",
      a_priori = "scores frozen pre-outcome; first_gen merged at registration",
      note = "Refined prediction from T7-v2: niche-specific dependency drives loss timing"
    )
  )
}

#' P3: Plastid erosion order among retained core
#'
#' Does a priori functional position (Component B) order plastid gene erosion
#' as parasitism deepens in Orobanchaceae?
#'
#' The retention matrix carries a priori dependency scores (0,1,2,3,5) per
#' functional category, assigned from plastid functional-network position, not
#' from observed loss. Test: across the parasitism gradient, does a priori
#' dependency order retention (core photosynthesis persists, peripheral erodes)?
#'
#' @param scores Data frame from `data/orobanchaceae_retention_matrix.tsv` with
#'   columns: species, parasitism_score, gene_category, dependency_score,
#'   retention.
#' @param seed Integer. Seed for reproducibility.
#' @return List (A6 proof object): values + metadata.
#' @export
p3_plastid_erosion_order <- function(scores, seed = 42L) {
  set.seed(seed)
  d <- scores

  # Per species: does a priori dependency_score order retention?
  sp_rhos <- sapply(split(d, d$species), function(sub) {
    if (length(unique(sub$dependency_score)) < 2 || length(unique(sub$retention)) < 2) {
      return(NA)
    }
    cor(sub$dependency_score, sub$retention, method = "spearman")
  })
  sp_rhos <- sp_rhos[!is.na(sp_rhos)]

  # Pooled: dependency_score vs retention across all species (species as covariate)
  m <- glm(retention ~ dependency_score + parasitism_score, data = d, family = binomial)
  p_dep <- summary(m)$coefficients["dependency_score", "Pr(>|z|)"]

  # Erosion order: within core categories, does dependency order the parasitism at which loss occurs?
  # (retention drops from 1 to 0 as parasitism deepens)

  list(
    values = list(
      mean_species_rho = if (length(sp_rhos)) mean(sp_rhos) else NA,
      n_species_with_signal = length(sp_rhos),
      beta_dependency = unname(coef(m)["dependency_score"]),
      p_dependency = p_dep,
      n = nrow(d),
      n_species = length(unique(d$species))
    ),
    metadata = list(
      seed = seed,
      n = nrow(d),
      test = "p3_plastid_erosion_order",
      components = "B: a priori functional-position dependency_score (categorical)",
      a_priori = "dependency_score assigned from plastid functional-network position, not observed loss",
      note = "Extends E6 (core-peripheral) to continuous erosion ordering"
    )
  )
}

#' P4: Echolocation convergence — a priori centrality contrast
#'
#' Does integration position (Component B) order convergence? Prediction:
#' convergent genes are LESS integrated than conserved genes in the same
#' functional domain (auditory/sensory/developmental machinery) — the
#' 'function converges, mechanism diverges' pattern.
#'
#' A priori: convergent gene symbols (Parker et al. 2013, Tables S6/S7/S12) and
#' a conserved control (hearing/deafness + developmental-patterning kernels)
#' are frozen in `data/a-priori-scores/p4_echolocation_symbols.tsv`. STRING
#' v12.0 human network centrality (degree, eigenvector, closeness) is computed
#' from an independent proteomics network — non-circular to the convergence
#' calls.
#'
#' @param symbols Data frame from `data/a-priori-scores/p4_echolocation_symbols.tsv`
#'   with columns: gene, class (convergent|conserved).
#' @param centralities Named list of per-protein centrality dicts
#'   (from `data/raw/echolocation/string_centralities.json`).
#' @param sym_to_prot Named list mapping gene symbol -> character vector of
#'   STRING protein ids (from `data/raw/echolocation/string_maps.json`).
#' @param seed Integer. Seed for reproducibility.
#' @return List (A6 proof object): values + metadata.
#' @export
p4_echolocation_centrality <- function(symbols, centralities, sym_to_prot, seed = 42L) {
  set.seed(seed)
  conv_syms <- unique(symbols$gene[symbols$class == "convergent"])
  cons_syms <- unique(symbols$gene[symbols$class == "conserved"])
  conv_prots <- unique(unlist(sym_to_prot[conv_syms]))
  cons_prots <- unique(unlist(sym_to_prot[cons_syms]))
  conv_prots <- conv_prots[conv_prots %in% names(centralities)]
  cons_prots <- cons_prots[cons_prots %in% names(centralities)]
  cons_prots <- setdiff(cons_prots, conv_prots)

  metrics <- c("deg", "ev", "cl")
  res <- sapply(metrics, function(met) {
    ca <- vapply(conv_prots, function(p) centralities[[p]][[met]], numeric(1))
    ba <- vapply(cons_prots, function(p) centralities[[p]][[met]], numeric(1))
    wt <- tryCatch(wilcox.test(ca, ba, alternative = "less"), error = function(e) NULL)
    pv <- if (is.null(wt)) NA else wt$p.value
    d <- (mean(ba) - mean(ca)) / sqrt((var(ca) + var(ba)) / 2)
    c(
      conv_mean = mean(ca), cons_mean = mean(ba), p_conv_less = pv,
      cohens_d = d, n_conv = length(ca), n_cons = length(ba)
    )
  })
  list(
    values = list(
      deg = as.list(res[, "deg"]), ev = as.list(res[, "ev"]), cl = as.list(res[, "cl"]),
      n_convergent = length(conv_prots), n_conserved = length(cons_prots),
      source = "Parker et al. 2013 Tables S6/S7/S12; STRING v12.0 human"
    ),
    metadata = list(
      seed = seed, test = "p4_echolocation_centrality",
      a_priori = "symbol lists frozen pre-centrality; STRING network independent of convergence calls",
      note = "Correct null is conserved genes in same domain, not whole-genome background"
    )
  )
}

#' P5: C4 syndrome — integration-depth signature from the C4 literature
#'
#' Does the C4 photosynthesis syndrome show the framework integration-depth signature?
#' Christin & Osborne (2014, New Phytol) provide (a) a hierarchical
#' deconstruction of the C4 syndrome into phenotypic levels (Table 1: Niche >
#' Physiology > Function > Character > Characteristic > Component) and
#' (b) explicit statements that the FUNCTIONS are "present in all C4 plants,
#' independently of their taxonomic origin" while the underlying CHARACTERS
#' "vary among C4 lineages" and are "assembled using one of numerous possible
#' sets" of components, with components "repeatedly co-opted."
#'
#' the framework's prediction: the shared/invariant elements sit HIGHER in the integration
#' hierarchy (function converges = protected attractor), the varying elements
#' sit LOWER (mechanism diverges = modular substrate). Both the hierarchy and
#' the shared/varying coding come from the independent C4 literature, not from
#' the framework — the test is whether they align.
#'
#' @param syndrome Data frame with columns: level, integration_depth (higher =
#'   more integrated), invariant (0/1: shared across origins per Christin &
#'   Osborne), rationale.
#' @param seed Integer. Seed for reproducibility.
#' @return List (A6 proof object): values + metadata.
#' @export
p5_c4_integration_depth <- function(syndrome, seed = 42L) {
  set.seed(seed)
  d <- syndrome
  d <- d[!is.na(d$integration_depth), ]
  # Test 1: do invariant elements sit higher in the hierarchy?
  inv <- d$invariant == 1
  if (sum(inv) >= 2 && sum(!inv) >= 2) {
    wt <- wilcox.test(d$integration_depth[inv], d$integration_depth[!inv], alternative = "greater")
    p_higher <- wt$p.value
  } else {
    p_higher <- NA
  }
  # Test 2: Spearman rank correlation between integration depth and invariance
  rho <- NA
  p_rho <- NA
  if (length(unique(d$integration_depth)) >= 3) {
    ct <- cor.test(d$integration_depth, d$invariant, method = "spearman")
    rho <- ct$estimate
    p_rho <- ct$p.value
  }
  # Test 3: exact binomial — invariant elements in upper half of hierarchy
  med <- median(d$integration_depth, na.rm = TRUE)
  upper <- d$integration_depth >= med
  inv_upper <- sum(inv & upper)
  inv_lower <- sum(inv & !upper)
  binom_p <- NA
  if (inv_upper + inv_lower > 0) {
    binom_p <- binom.test(inv_upper, inv_upper + inv_lower, p = 0.5, alternative = "greater")$p.value
  }
  list(
    values = list(
      p_invariant_higher = p_higher,
      rho_depth_invariance = rho,
      p_rho = p_rho,
      binom_p_upper_half = binom_p,
      n_invariant_upper = inv_upper,
      n_invariant_lower = inv_lower,
      n_levels = nrow(d)
    ),
    metadata = list(
      seed = seed, test = "p5_c4_integration_depth",
      source = "Christin & Osborne 2014 New Phytol Table 1 + text",
      a_priori = "hierarchy and shared/varying coding from C4 literature, not the framework",
      prediction = "function converges (invariant, high integration); mechanism diverges (varying, low integration)"
    )
  )
}
