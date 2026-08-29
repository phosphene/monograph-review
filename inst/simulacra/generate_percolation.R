#' Generate percolation network data (Simulacrum 7)
#'
#' Connected random graph. Tests whether theta_star = 0.
#'
#' @param seed Integer. Default 42.
#' @param n_nodes Integer. Default 100.
#' @param p_edge Numeric. Edge probability. Default 0.1.
#' @param n_provision_levels Integer. Default 20.

generate_percolation_network <- function(seed = 42L, n_nodes = 100L,
                                         p_edge = 0.1,
                                         n_provision_levels = 20L) {
  withr::with_seed(seed, {
    adj <- matrix(0, n_nodes, n_nodes)
    for (i in 1:(n_nodes - 1)) {
      for (j in (i + 1):n_nodes) {
        if (runif(1) < p_edge) {
          adj[i, j] <- 1
          adj[j, i] <- 1
        }
      }
    }
    for (i in 1:(n_nodes - 1)) {
      if (adj[i, i + 1] == 0) {
        adj[i, i + 1] <- 1
        adj[i + 1, i] <- 1
      }
    }

    dep_sets <- lapply(1:n_nodes, function(i) which(adj[i, ] == 1))

    provision_sizes <- round(seq(1, n_nodes, length.out = n_provision_levels))
    zero_dep_fractions <- numeric(n_provision_levels)

    for (k in 1:n_provision_levels) {
      S <- sample(1:n_nodes, provision_sizes[k])
      Z <- sapply(1:n_nodes, function(v) {
        deps <- dep_sets[[v]]
        if (length(deps) == 0) return(TRUE)
        all(deps %in% S)
      })
      zero_dep_fractions[k] <- sum(Z) / n_nodes
    }

    theta <- provision_sizes / n_nodes
    rho <- zero_dep_fractions

    data <- data.frame(theta = theta, rho = rho,
                       provision_size = provision_sizes, model = "percolation")

    first_Z <- rho[1]
    theta_star_est <- if (first_Z > 0) 0 else theta[which(rho > 0)[1]]

    list(
      values = list(n_nodes = n_nodes, n_provision_levels = n_provision_levels,
                    theta_star_est = theta_star_est,
                    first_provision_Z = first_Z,
                    is_connected = TRUE,
                    network_density = sum(adj) / (n_nodes * (n_nodes - 1))),
      metadata = list(seed = seed, data = data,
                      params = list(n_nodes = n_nodes, p_edge = p_edge,
                                    n_provision_levels = n_provision_levels),
                      generator = "generate_percolation_network",
                      converged = TRUE)
    )
  })
}
