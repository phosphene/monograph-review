# generate_synthetic_population.R — Simulacrum synthetic data generator
#
# Simulacrum 1: Parameter Recovery.
# Generates a synthetic trait panel from the valence threshold-gated capacity
# reallocation model (dC_i/dt = -λ × M(t) × I(d_i < θ)) with KNOWN parameters,
# so that the downstream pipeline can be proven to recover those parameters
# (STDD — Stochastic Test-Driven Development).
#
# Ground truth parameters:
#   λ  = 0.15   shedding rate
#   θ  = 2.5    protection threshold (integration depth)
#   M₀ = 10.0   initial niche-demand mismatch
#   α  = 0.05   mismatch decay rate
#
# DFT compliance:
#   A1 (pure-io-separation): pure function, no I/O, no side effects.
#   A2 (determinism): RNG fully controlled via withr::with_seed() with an
#      injectable seed and explicit Mersenne-Twister + Inversion RNG kinds for
#      cross-platform reproducibility.
#
# The generator is used by the simulacrum test bed to prove the pipeline CAN
# distinguish signal from noise before it is trusted on real Orobanchaceae data.

#' Generate a synthetic trait population from the valence threshold model
#'
#' Draws 50 species with integration depths spanning [0, 5], computes each
#' species' equilibrium retention via \code{threshold_model()}, adds Gaussian
#' measurement noise to the retention probability (clamped to [0, 1]), and
#' maps retention to plastome size (retention × 150000 ancestor size).
#' Parasitism score is the integration-depth proxy for Orobanchaceae: shallow
#' protection depth maps to high parasitism (more capacity reallocation), so
#' higher parasitism → smaller plastome (the valence signal the recovery test
#' must detect).
#'
#' @param n Integer. Number of species. Default 50.
#' @param lambda Numeric. Shedding rate. Default 0.15.
#' @param theta Numeric. Protection threshold. Default 2.5.
#' @param m0 Numeric. Initial mismatch. Default 10.0.
#' @param alpha Numeric. Mismatch decay rate. Default 0.05.
#' @param time Numeric. Integration time for \code{threshold_model()}. Default 100.
#' @param ancestor_size_bp Numeric. Ancestral plastome size. Default 150000.
#' @param noise_sd Numeric. SD of retention noise. Default 0.05.
#' @param seed Integer. Random seed (A2). Default 42.
#' @param rng_kind Character. Base RNG kind. Default "Mersenne-Twister".
#' @param rng_normal_kind Character. Normal RNG algorithm. Default "Inversion".
#' @param rng_sample_kind Character. Sample RNG kind. Default "Rejection".
#'
#' @return A data.frame with columns:
#'   \item{species}{Character. Species identifier.}
#'   \item{trait_depth}{Numeric. Integration depth in [0, 5].}
#'   \item{retention_prob}{Numeric. Noisy retention probability in [0, 1].}
#'   \item{plastome_size_bp}{Numeric. Plastome size = retention × 150000.}
#'   \item{parasitism_score}{Integer. 0 (autotroph) to 4 (extreme holoparasite).}
#'
#' @section DFT:
#' A1 (pure-io-separation), A2 (determinism).
#'
#' @name generate_synthetic_population
#' @export
generate_synthetic_population <- function(n = 50L,
                                          lambda = 0.15,
                                          theta = 2.5,
                                          m0 = 10.0,
                                          alpha = 0.05,
                                          time = 100,
                                          ancestor_size_bp = 150000,
                                          noise_sd = 0.05,
                                          seed = 42L,
                                          rng_kind = "Mersenne-Twister",
                                          rng_normal_kind = "Inversion") {
  withr::with_seed(
    seed,
    {
      # Integration depths spanning [0, 5]
      depths <- seq(0, 5, length.out = n)

      # Exact retention from the formal threshold model (vectorized via
      # threshold_model — equilibrium_retention/retention_at_time are NOT
      # vector-safe because they use `if` on scalar depth).
      model <- threshold_model(
        depths = depths, lambda = lambda, theta = theta,
        m0 = m0, alpha = alpha, time = time
      )
      retention_exact <- model$values[["final_retention"]]

      # Add measurement noise, clamped to [0, 1]
      retention_noisy <- retention_exact + stats::rnorm(n, 0, noise_sd)
      retention_noisy <- pmax(pmin(retention_noisy, 1), 0)

      # Plastome size proportional to retention
      plastome_size_bp <- retention_noisy * ancestor_size_bp

      # Parasitism score: inverse of protection depth (shallow = high
      # parasitism = more capacity reallocation = smaller plastome).
      # Maps depth [0,5] -> integer score [0,4], clamped.
      parasitism_score <- round(4 * (1 - depths / max(depths)))
      parasitism_score <- pmax(pmin(parasitism_score, 4L), 0L)

      data.frame(
        species = sprintf("sp_%02d", seq_len(n)),
        trait_depth = depths,
        retention_prob = retention_noisy,
        plastome_size_bp = plastome_size_bp,
        parasitism_score = parasitism_score,
        stringsAsFactors = FALSE
      )
    },
    .rng_kind = rng_kind,
    .rng_normal_kind = rng_normal_kind
  )
}
