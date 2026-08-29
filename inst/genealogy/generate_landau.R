#' Landau Mean-Field Free Energy — Stage 2 of the Genealogy
#'
#' F(M) = a*M^2 + b*M^4 + h*M
#' Equilibrium: minimize F over M grid.
#'
#' @param seed Integer. Default 42.
#' @param n_points Integer. Number of M values. Default 100.
#' @param a_range Numeric. Range of 'a'. Default c(-1, 1).
#' @param b Numeric. Quartic coefficient. Default 1.0.
#' @param h Numeric. External field. Default 0.0.
#'
#' @return List with data frame: a, M_eq, F_min, T_norm, stage

generate_landau <- function(seed = 42L, n_points = 100L,
                            a_range = c(-1, 1), b = 1.0, h = 0.0) {
  withr::with_seed(seed, {
    a_vals <- seq(a_range[1], a_range[2], length.out = n_points)
    M_grid <- seq(-1.5, 1.5, length.out = 200)
    M_eq <- numeric(n_points)
    F_min <- numeric(n_points)

    for (i in 1:n_points) {
      a <- a_vals[i]
      F <- a * M_grid^2 + b * M_grid^4 + h * M_grid
      eq_idx <- which.min(F)
      M_eq[i] <- M_grid[eq_idx]
      F_min[i] <- F[eq_idx]
    }

    T_norm <- a_vals + 1

    data <- data.frame(
      a = a_vals, M_eq = M_eq, F_min = F_min,
      T_norm = T_norm, b = b, h = h, stage = "landau"
    )

    list(
      values = list(n_points = n_points, b = b, h = h),
      metadata = list(
        seed = seed, data = data,
        params = list(n_points = n_points, a_range = a_range, b = b, h = h),
        generator = "generate_landau", converged = TRUE
      )
    )
  })
}
