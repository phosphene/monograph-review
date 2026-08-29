#' Generate step-function synthetic data (Simulacrum 6)
#'
#' rho = rho_sat * H(theta - theta_star)
#'
#' @param seed Integer. Default 42.
#' @param n_pre Integer. Pre-threshold points. Default 10.
#' @param n_post Integer. Post-threshold points. Default 10.
#' @param rho_sat Numeric. Default 0.35.
#' @param theta_star Numeric. Default 0.
#' @param noise_sd Numeric. Default 0.02.

generate_step_function <- function(seed = 42L, n_pre = 10L, n_post = 10L,
                                   rho_sat = 0.35, theta_star = 0,
                                   noise_sd = 0.02) {
  withr::with_seed(seed, {
    theta_pre <- seq(-1, theta_star - 0.01, length.out = n_pre)
    theta_post <- seq(theta_star + 0.01, 1, length.out = n_post)
    theta <- c(theta_pre, theta_post)
    rho_true <- c(rep(0, n_pre), rep(rho_sat, n_post))
    rho <- rho_true + rnorm(length(theta), 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(theta = theta, rho = rho, model = "step")

    list(
      values = list(n = n_pre + n_post, true_rho_sat = rho_sat,
                    true_theta_star = theta_star, true_noise = noise_sd),
      metadata = list(seed = seed, data = data,
                      params = list(n_pre = n_pre, n_post = n_post,
                                    rho_sat = rho_sat, theta_star = theta_star,
                                    noise_sd = noise_sd),
                      generator = "generate_step_function", converged = TRUE)
    )
  })
}
