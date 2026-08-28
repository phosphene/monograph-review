#' Generate biphasic genome reduction synthetic data (Simulacrum 2)
#'
#' Generates synthetic genome reduction time series following a logistic
#' (saturation/decelerating) curve, consistent with valence's biphasic kinetics
#' prediction: fast Phase 1 (unprotected traits shed rapidly) followed by
#' slow Phase 2 (protected traits resist loss).
#'
#' The generative model is:
#'   genome_bp = floor + (ancestor - floor) / (1 + exp(rate * (age - mid)))
#'
#' where:
#' - `rate` = 0.08 (fast phase rate, k1)
#' - `floor` ~ 400 kb (minimum genome size)
#' - `ancestor` ~ 4.5 Mb (ancestral genome size)
#' - k1/k2 = 20.0 (true ratio of fast to slow phase rates)
#'
#' @section Theoretical Context:
#'
#' valence Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' rapidly at rate k1) followed by slow Phase 2 (protected traits resist loss
#' at rate k2). The logistic/saturation curve is the empirical signature.
#'
#' Competitors:
#' - Constant rate (relaxed selection, Lahti 2009): predicts linear reduction
#' - Accelerating (Muller's ratchet): predicts accelerating reduction
#' - The biphasic (logistic/saturation) shape is unique to valence's threshold-gated model
#'
#' @param seed Integer. Seed for reproducibility. Default 42.
#' @param n_genera Integer. Number of genera to generate. Default 10.
#' @param age_range Numeric vector of length 2. Min and max symbiosis age
#'   in Myr. Default c(20, 200).
#' @param ancestor_size Numeric. Ancestral genome size in bp. Default 4.5e6.
#' @param floor_size Numeric. Minimum (asymptotic) genome size in bp. Default 4e5.
#' @param rate Numeric. Logistic rate parameter (k1, fast phase). Default 0.08.
#' @param mid Numeric. Midpoint of logistic transition in Myr. Default 70.
#' @param noise_sd Numeric. Standard deviation of Gaussian noise. Default 5000.
#'
#' @return List (A6 proof object):
#'   \item{values}{Named numeric vector: n_genera, true_rate, k1_k2_ratio,
#'     true_ancestor, true_floor, true_mid, noise_sd}
#'   \item{metadata}{List: seed, n, params (list of all generative params),
#'     data (data.frame with genus, symbiosis_age_mya, genome_bp),
#'     generator, converged}
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed, never hidden
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @examples
#' \dontrun{
#' result <- generate_biphasic_genome(seed = 42)
#' head(result$metadata$data)
#' }
#'
#' @name generate_biphasic_genome
NULL

#' Generate biphasic genome reduction synthetic data
#'
#' @param seed Integer. Seed for reproducibility.
#' @param n_genera Integer. Number of genera. Default 10.
#' @param age_range Numeric vector length 2. Age range in Myr. Default c(20, 200).
#' @param ancestor_size Numeric. Ancestral genome size in bp. Default 4.5e6.
#' @param floor_size Numeric. Minimum genome size in bp. Default 4e5.
#' @param rate Numeric. Logistic rate parameter (k1). Default 0.08.
#' @param mid Numeric. Midpoint of logistic. Default 70.
#' @param noise_sd Numeric. Noise standard deviation. Default 5000.
#'
#' @return A6 proof object with data in metadata.
#' @keywords internal
generate_biphasic_genome <- function(
  seed = 42L,
  n_genera = 10L,
  age_range = c(20, 200),
  ancestor_size = 4.5e6,
  floor_size = 4e5,
  rate = 0.08,
  mid = 70,
  noise_sd = 5000
) {
  withr::with_seed(seed, {
    # Use Mersenne-Twister + Inversion for full reproducibility (A2)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
    # Validate inputs
    stopifnot(
      is.numeric(seed), length(seed) == 1L,
      is.numeric(n_genera), length(n_genera) == 1L, n_genera >= 3L,
      is.numeric(age_range), length(age_range) == 2L,
      age_range[1] < age_range[2],
      is.numeric(ancestor_size), ancestor_size > 0,
      is.numeric(floor_size), floor_size > 0, floor_size < ancestor_size,
      is.numeric(rate), rate > 0,
      is.numeric(mid), mid > 0,
      is.numeric(noise_sd), noise_sd >= 0
    )

    # Generate evenly spaced ages
    ages <- seq(age_range[1], age_range[2], length.out = n_genera)

    # Logistic model for genome reduction over time
    genome_bp_raw <- floor_size + (ancestor_size - floor_size) /
      (1 + exp(rate * (ages - mid)))

    # Add Gaussian noise
    genome_bp <- genome_bp_raw + stats::rnorm(n_genera, 0, noise_sd)

    # Enforce non-negativity
    genome_bp <- pmax(genome_bp, 0)

    # Create genus names
    genera <- paste0("Genus_", LETTERS[seq_len(n_genera)])

    # Build data frame
    data <- data.frame(
      genus = genera,
      symbiosis_age_mya = ages,
      genome_bp = genome_bp,
      stringsAsFactors = FALSE
    )

    # k1/k2 ratio: k1 = rate, k2 = 0.004 (so k1/k2 = 0.08/0.004 = 20)
    k2 <- rate / 20.0

    result <- list(
      values = c(
        n_genera = n_genera,
        true_rate = rate,
        true_k2 = k2,
        k1_k2_ratio = rate / k2,
        true_ancestor = ancestor_size,
        true_floor = floor_size,
        true_mid = mid,
        noise_sd = noise_sd
      ),
      metadata = list(
        seed = seed,
        n = n_genera,
        params = list(
          n_genera = n_genera,
          age_range = age_range,
          ancestor_size = ancestor_size,
          floor_size = floor_size,
          rate = rate,
          mid = mid,
          noise_sd = noise_sd
        ),
        data = data,
        generator = "logistic_biphasic",
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Generate constant-rate (linear) genome reduction data for null control
#'
#' Generates synthetic genome reduction data following a linear model
#' (constant reduction rate), used as a null control where the logistic
#' (biphasic) model should NOT be preferred.
#'
#' @param seed Integer. Seed for reproducibility. Default 42.
#' @param n_genera Integer. Number of genera. Default 10.
#' @param age_range Numeric vector length 2. Age range in Myr. Default c(20, 200).
#' @param ancestor_size Numeric. Ancestral genome size in bp. Default 4.5e6.
#' @param reduction_rate Numeric. Constant reduction rate in bp/Myr. Default 20000.
#' @param noise_sd Numeric. Noise standard deviation. Default 50000.
#'
#' @return A6 proof object with data in metadata.
#' @keywords internal
generate_constant_rate_genome <- function(
  seed = 42L,
  n_genera = 10L,
  age_range = c(20, 200),
  ancestor_size = 4.5e6,
  reduction_rate = 20000,
  noise_sd = 50000
) {
  withr::with_seed(seed, {
    # Use Mersenne-Twister + Inversion for full reproducibility (A2)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
    stopifnot(
      is.numeric(seed), length(seed) == 1L,
      is.numeric(n_genera), n_genera >= 3L,
      is.numeric(age_range), length(age_range) == 2L,
      age_range[1] < age_range[2],
      is.numeric(ancestor_size), ancestor_size > 0,
      is.numeric(reduction_rate), reduction_rate > 0,
      is.numeric(noise_sd), noise_sd >= 0
    )

    ages <- seq(age_range[1], age_range[2], length.out = n_genera)

    # Linear model for genome reduction
    genome_bp_raw <- ancestor_size - reduction_rate * ages

    # Add noise
    genome_bp <- genome_bp_raw + stats::rnorm(n_genera, 0, noise_sd)

    # Enforce non-negativity
    genome_bp <- pmax(genome_bp, 0)

    genera <- paste0("Genus_", LETTERS[seq_len(n_genera)])

    data <- data.frame(
      genus = genera,
      symbiosis_age_mya = ages,
      genome_bp = genome_bp,
      stringsAsFactors = FALSE
    )

    result <- list(
      values = c(
        n_genera = n_genera,
        true_ancestor = ancestor_size,
        reduction_rate = reduction_rate,
        noise_sd = noise_sd
      ),
      metadata = list(
        seed = seed,
        n = n_genera,
        params = list(
          n_genera = n_genera,
          age_range = age_range,
          ancestor_size = ancestor_size,
          reduction_rate = reduction_rate,
          noise_sd = noise_sd
        ),
        data = data,
        generator = "linear_constant_rate",
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
