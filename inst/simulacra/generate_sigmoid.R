#' Generate steep-sigmoid synthetic data (Simulacrum 6 competitor)
#'
#' rho = rho_sat / (1 + exp(-s * (theta - theta_star)))
#'
#' @param seed Integer. Default 42.
#' @param n Integer. Total points. Default 20.
#' @param rho_sat Numeric. Default 0.35.
#' @param theta_star Numeric. Default 0.
#' @param s Numeric. Steepness. Default 10.
#' @param noise_sd Numeric. Default 0.02.

generate_steep_sigmoid <- function(seed = 42L, n = 20L,
                                   rho_sat = 0.35, theta_star = 0,
                                   s = 10, noise_sd = 0.02) {
  withr::with_seed(seed, {
    theta <- seq(-1, 1, length.out = n)
    rho_true <- rho_sat / (1 + exp(-s * (theta - theta_star)))
    rho <- rho_true + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(theta = theta, rho = rho, model = "sigmoid")

    list(
      values = list(n = n, true_rho_sat = rho_sat,
                    true_theta_star = theta_star, true_s = s,
                    true_noise = noise_sd),
      metadata = list(seed = seed, data = data,
                      params = list(n = n, rho_sat = rho_sat,
                                    theta_star = theta_star, s = s,
                                    noise_sd = noise_sd),
                      generator = "generate_steep_sigmoid", converged = TRUE)
    )
  })
}
