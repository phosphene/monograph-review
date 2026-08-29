#' Bi-exponential recovery simulacrum
#'
#' Generates synthetic data from a known bi-exponential:
#'   rho(t) = rho_eq + A1*exp(-k1*t) + A2*exp(-k2*t)
#'
#' Tests whether nls() can recover k1, k2, A1, A2, rho_eq
#' from noisy data. Null control: mono-exponential data
#' (A2=0) — does the fitter falsely report bi-exponential?

generate_biexponential <- function(seed = 42L, n = 80L,
                                   rho_eq = 0.945,
                                   A1 = 0.04, k1 = 17.7,
                                    A2 = 0.005, k2 = 0.47,
                                    noise_sd = 0.002,
                                    t_max = 56500) {
  withr::with_seed(seed, {
    t <- seq(0, t_max, length.out = n)
    rho_true <- rho_eq + A1 * exp(-k1 * t / 10000) + A2 * exp(-k2 * t / 10000)
    rho <- rho_true + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(t = t, rho = rho, rho_true = rho_true, model = "biexponential")

    list(
      values = list(
        n = n,
        true_rho_eq = rho_eq,
        true_A1 = A1, true_k1 = k1,
        true_A2 = A2, true_k2 = k2,
        true_noise = noise_sd
      ),
      metadata = list(
        seed = seed, data = data,
        params = list(n = n, rho_eq = rho_eq, A1 = A1, k1 = k1,
                      A2 = A2, k2 = k2, noise_sd = noise_sd, t_max = t_max),
        generator = "generate_biexponential", converged = TRUE
      )
    )
  })
}


#' Mono-exponential data (null control for bi-exponential test)
#'
#' Generates synthetic data from a mono-exponential:
#'   rho(t) = rho_eq + A * exp(-k * t)
#'
#' If the bi-exponential fitter reports bi-exp on this data,
#' it's a false positive.

generate_monoexponential <- function(seed = 42L, n = 80L,
                                     rho_eq = 0.945,
                                     A = 0.045, k = 3.94,
                                     noise_sd = 0.002,
                                     t_max = 100) {
  withr::with_seed(seed, {
    t <- seq(0, t_max, length.out = n)
    rho_true <- rho_eq + A * exp(-k * t)
    rho <- rho_true + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(t = t, rho = rho, rho_true = rho_true, model = "monoexponential")

    list(
      values = list(
        n = n, true_rho_eq = rho_eq,
        true_A = A, true_k = k, true_noise = noise_sd
      ),
      metadata = list(
        seed = seed, data = data,
        params = list(n = n, rho_eq = rho_eq, A = A, k = k,
                      noise_sd = noise_sd, t_max = t_max),
        generator = "generate_monoexponential", converged = TRUE
      )
    )
  })
}


#' Cross-sectional sampling simulacrum
#'
#' Generates a bi-exponential time series, then samples it
#' at random points (cross-sectional). Tests whether the
#' cross-sectional data appears mono-exponential.

generate_crosssectional <- function(seed = 42L, n_longitudinal = 80L,
                                    n_cross = 30L,
                                    rho_eq = 0.945,
                                     A1 = 0.04, k1 = 17.7,
                                     A2 = 0.005, k2 = 0.47,
                                     noise_sd = 0.002,
                                     t_max = 56500) {
  withr::with_seed(seed, {
    # Full longitudinal trajectory
    t_full <- seq(0, t_max, length.out = n_longitudinal)
    rho_full <- rho_eq + A1 * exp(-k1 * t_full / 10000) + A2 * exp(-k2 * t_full / 10000)

    # Cross-sectional: sample at random time points
    t_cross <- sort(runif(n_cross, 0, t_max))
    rho_cross_true <- rho_eq + A1 * exp(-k1 * t_cross / 10000) + A2 * exp(-k2 * t_cross / 10000)
    rho_cross <- rho_cross_true + rnorm(n_cross, 0, noise_sd)
    rho_cross <- pmax(0, pmin(1, rho_cross))

    data <- data.frame(
      t = t_cross, rho = rho_cross, rho_true = rho_cross_true,
      model = "crosssectional"
    )

    list(
      values = list(
        n_longitudinal = n_longitudinal,
        n_cross = n_cross,
        true_rho_eq = rho_eq,
        true_A1 = A1, true_k1 = k1,
        true_A2 = A2, true_k2 = k2
      ),
      metadata = list(
        seed = seed, data = data,
        params = list(n_longitudinal = n_longitudinal, n_cross = n_cross,
                      rho_eq = rho_eq, A1 = A1, k1 = k1,
                      A2 = A2, k2 = k2, noise_sd = noise_sd, t_max = t_max),
        generator = "generate_crosssectional", converged = TRUE
      )
    )
  })
}


#' Discrete-level sampling simulacrum
#'
#' Generates a bi-exponential, then samples at discrete levels.
#' Tests whether discrete sampling produces a step-like pattern.

generate_discrete_levels <- function(seed = 42L, n_levels = 5L,
                                     n_per_level = 30L,
                                     rho_eq = 0.5,
                                       A1 = 0.3, k1 = 10,
                                       A2 = 0.1, k2 = 1,
                                       noise_sd = 0.05) {
  withr::with_seed(seed, {
    # Discrete levels represent parasitism levels 0-4
    levels <- 0:(n_levels - 1)
    # Map levels to "time" on the bi-exponential
    t_levels <- levels * 10  # arbitrary scaling

    data <- data.frame()
    for (lv in levels) {
      t <- t_levels[lv + 1]
      rho_true <- rho_eq + A1 * exp(-k1 * t / 100) + A2 * exp(-k2 * t / 100)
      rho <- rho_true + rnorm(n_per_level, 0, noise_sd)
      rho <- pmax(0, pmin(1, rho))
      data <- rbind(data, data.frame(
        level = lv, t = t, rho = rho, rho_true = rep(rho_true, n_per_level),
        model = "discrete_levels"
      ))
    }

    list(
      values = list(
        n_levels = n_levels, n_per_level = n_per_level,
        true_rho_eq = rho_eq,
        true_A1 = A1, true_k1 = k1,
        true_A2 = A2, true_k2 = k2
      ),
      metadata = list(
        seed = seed, data = data,
        params = list(n_levels = n_levels, n_per_level = n_per_level,
                      rho_eq = rho_eq, A1 = A1, k1 = k1,
                      A2 = A2, k2 = k2, noise_sd = noise_sd),
        generator = "generate_discrete_levels", converged = TRUE
      )
    )
  })
}
