#' Generate null data (no signal) for Simulacrum 6
#'
#' Flat data with noise. Tests false positive rate.
#'
#' @param seed Integer. Default 42.
#' @param n Integer. Total points. Default 20.
#' @param rho_baseline Numeric. Default 0.35.
#' @param noise_sd Numeric. Default 0.05.

generate_null_rho <- function(seed = 42L, n = 20L,
                              rho_baseline = 0.35, noise_sd = 0.05) {
  withr::with_seed(seed, {
    theta <- seq(-1, 1, length.out = n)
    rho <- rep(rho_baseline, n) + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(theta = theta, rho = rho, model = "null")

    list(
      values = list(n = n, true_rho_sat = 0, true_theta_star = NA,
                    true_noise = noise_sd),
      metadata = list(seed = seed, data = data,
                      params = list(n = n, rho_baseline = rho_baseline,
                                    noise_sd = noise_sd),
                      generator = "generate_null_rho", converged = TRUE)
    )
  })
}
