#' Cross-kingdom parameter transfer (L3 test)
#'
#' The strongest test in the monograph: fit the integration-depth model
#' on plant (Orobanchaceae) data, then apply the same parameters to predict
#' bird (island bird flight-loss) morphological change ordering WITHOUT
#' refitting. If the ordering transfers across kingdoms, the principle is
#' substrate-independent.
#'
#' @section Theoretical Context:
#'
#' valence Prediction: integration-depth parameters transfer across kingdoms.
#' Competitor: substrates are independent — no parameter transfer.
#' DOES distinguish valence. This is the strongest test.
#'
#' @dft A1, A2, A6
#'
#' @name cross_kingdom_transfer
NULL

#' Fit the plant model (dependency score → loss rank)
#'
#' Fits a linear model: loss_rank ~ dependency_score using Orobanchaceae
#' gene-loss data. Returns the slope for cross-kingdom transfer.
#'
#' @param plant_data Data frame with dependency_score and loss_rank columns.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (slope, intercept, r_squared, p_value), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
fit_plant_model <- function(plant_data, seed = 42L) {
  withr::with_seed(seed, {
    validate_gene_categories(plant_data)

    # Use first available loss rank column
    loss_col <- grep("_loss_rank$", names(plant_data), value = TRUE)[1]

    fit <- lm(plant_data[[loss_col]] ~ plant_data$dependency_score)
    s <- summary(fit)

    result <- list(
      values = list(
        slope = unname(coef(fit)[2]),
        intercept = unname(coef(fit)[1]),
        r_squared = unname(s$r.squared),
        p_value = unname(s$coefficients[2, 4])
      ),
      metadata = list(
        seed = seed,
        n = nrow(plant_data),
        loss_col = loss_col,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Predict bird morphological change ordering from plant-derived slope
#'
#' Uses the plant-derived slope ( WITHOUT refitting) to predict
#' the ordering of bird morphological changes.
#'
#' @param bird_data Data frame with structure, dependency_score, observed_rank.
#' @param plant_slope Numeric. Slope from fit_plant_model()$values["slope"].
#'
#' @return Numeric vector. Predicted ranks for each bird structure.
#'
#' @dft A1
#'
#' @export
predict_bird_ordering <- function(bird_data, plant_slope) {
  validate_bird_morphology(bird_data)

  # Predict: rank = intercept + slope × dependency_score
  # We only use the slope (ordering), not the intercept (rate)
  # Plant loss_rank is inversely related to dependency (high dep = low loss_rank = retained).
  # Bird observed_rank is directly related to dependency (high dep = changes late = high rank).
  # Negate the slope so the direction matches: high dep → high predicted rank (changes late).
  predicted <- -plant_slope * bird_data$dependency_score

  # Convert to ranks (1 = first to change)
  rank(predicted, ties.method = "average")
}

#' Full cross-kingdom transfer test
#'
#' Fits on plant data, predicts bird ordering, computes Spearman ρ between
#' predicted and observed bird ranks. Also runs null control (random slope).
#'
#' @param plant_data Data frame with dependency_score and loss_rank.
#' @param bird_data Data frame with structure, dependency_score, observed_rank.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (plant_slope, bird_rho, bird_p, null_rho,
#'   null_p), metadata.
#'
#' @section Note on "transfer":
#'
#' predict_bird_ordering() ranks (plant_slope * dependency_score), and
#' rank(a*x) = rank(x) for any a > 0, so the plant slope MAGNITUDE is
#' discarded — only the slope SIGN transfers (a positive plant slope yields
#' the same ordering as dependency_score itself). This is an ordering-
#' concordance test (does bird observed_rank agree with dependency_score?),
#' not a full parameter transfer. This matches the oracle caveat ("Ordering
#' transfers across kingdoms; rate does not").
#'
#' @dft A1, A2, A6
#'
#' @export
transfer_test <- function(plant_data, bird_data, seed = 42L) {
  withr::with_seed(seed, {
    # Fit plant model
    plant_fit <- fit_plant_model(plant_data, seed = seed)
    plant_slope <- plant_fit$values[["slope"]]

    # Predict bird ordering using plant slope
    predicted_ranks <- predict_bird_ordering(bird_data, plant_slope)

    # Compare to observed
    observed_ranks <- bird_data$observed_rank
    cor_result <- cor.test(predicted_ranks, observed_ranks, method = "spearman")

    # Null control: distribution of random slopes (not a single draw). A
    # single runif(1) draw cannot support a null p-value; a distribution can.
    # null_p = proportion of random-slope orderings whose |rho| meets or
    # exceeds the observed |bird_rho|.
    n_null <- 1000L
    obs_abs_rho <- abs(unname(cor_result$estimate))
    null_rhos <- replicate(n_null, {
      random_slope <- runif(1, -1, 1)
      null_predicted <- random_slope * bird_data$dependency_score
      null_ranks <- rank(null_predicted, ties.method = "average")
      cor(null_ranks, observed_ranks, method = "spearman")
    })
    null_rho_mean <- mean(null_rhos, na.rm = TRUE)
    null_p <- mean(abs(null_rhos) >= obs_abs_rho, na.rm = TRUE)

    result <- list(
      values = list(
        plant_slope = unname(plant_slope),
        bird_rho = unname(cor_result$estimate),
        bird_p = unname(cor_result$p.value),
        null_rho = null_rho_mean,
        null_p = null_p
      ),
      metadata = list(
        seed = seed,
        n_plant = nrow(plant_data),
        n_bird = nrow(bird_data),
        n_bird_structures = length(unique(bird_data$structure)),
        n_null = n_null,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
