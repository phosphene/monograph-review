# test-cultural-sign-reversal.R — H10: diversity-dependence sign reversal
#
# Tests that Homo (cultural substrate, β > 1) shows positive DD speciation
# and non-Homo (ecological substrate, β < 1) shows negative DD speciation,
# using Van Holstein & Foley (2024) Bayesian posteriors.
#
# @section Theoretical Context:
#
# the framework's prediction: β > 1 → positive diversity-dependent speciation;
# β < 1 → negative diversity-dependent speciation. This is the sign reversal.
# The Van Holstein & Foley (2024) data confirms this empirically.
#
# @dft A1, A6

library(testthat)

context("Cultural: H10 sign reversal (Van Holstein & Foley 2024)")

# Load the actual Bayesian posteriors from the downloaded Figshare data
# These are loaded from the Van Holstein data directory
.load_van_holstein_posteriors <- function() {
  base <- file.path(
    "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress",
    "data/van-holstein/Data_Code_Final"
  )

  configs <- list(
    list(
      name = "Broad_NHPP_homo",
      path = file.path(base, "PyRate/Outputs/Broad_occurrence_level/NHPP/homo_diversity_0_expSp_expEx_HP.log")
    ),
    list(
      name = "Broad_NHPP_nonhomo",
      path = file.path(base, "PyRate/Outputs/Broad_occurrence_level/NHPP/nonhomo_diversity_0_expSp_expEx_HP.log")
    ),
    list(
      name = "WoodBoyle_homo",
      path = file.path(base, "PyRate/Outputs/Wood-Boyle/homo_diversity_0_expSp_expEx_HP.log")
    ),
    list(
      name = "WoodBoyle_nonhomo",
      path = file.path(base, "PyRate/Outputs/Wood-Boyle/nonhomo_diversity_0_expSp_expEx_HP.log")
    )
  )

  posteriors <- list()
  for (cfg in configs) {
    if (file.exists(cfg$path)) {
      df <- utils::read.csv(cfg$path, sep = "\t")
      burned <- df[df$it >= 1000, ]
      gl_col <- grep("^Gl_", names(burned), value = TRUE)
      if (length(gl_col) > 0) {
        posteriors[[cfg$name]] <- burned[[gl_col[1]]]
      }
    }
  }
  posteriors
}

test_that("H10: Homo shows positive DD speciation (Broad NHPP)", {
  skip_if_not(
    file.exists(file.path(
      "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress",
      "data/van-holstein/Data_Code_Final/PyRate/Outputs",
      "Broad_occurrence_level/NHPP/homo_diversity_0_expSp_expEx_HP.log"
    )),
    "Van Holstein data not downloaded"
  )

  posteriors <- .load_van_holstein_posteriors()
  result <- sign_reversal_test(
    posteriors[["Broad_NHPP_homo"]],
    posteriors[["Broad_NHPP_nonhomo"]],
    config = "Broad_NHPP"
  )

  # Homo should have positive mean Gl (positive DD)
  expect_gt(result$values$homo_gl_mean, 0)
  # At least 60% of posterior should be positive
  expect_gt(result$values$homo_pct_positive, 60)
})

test_that("H10: non-Homo shows negative DD speciation (Broad NHPP)", {
  skip_if_not(
    file.exists(file.path(
      "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress",
      "data/van-holstein/Data_Code_Final/PyRate/Outputs",
      "Broad_occurrence_level/NHPP/nonhomo_diversity_0_expSp_expEx_HP.log"
    )),
    "Van Holstein data not downloaded"
  )

  posteriors <- .load_van_holstein_posteriors()
  result <- sign_reversal_test(
    posteriors[["Broad_NHPP_homo"]],
    posteriors[["Broad_NHPP_nonhomo"]],
    config = "Broad_NHPP"
  )

  # Non-Homo should have negative mean Gl (negative DD)
  expect_lt(result$values$nonhomo_gl_mean, 0)
  # Less than 50% of posterior should be positive
  expect_lt(result$values$nonhomo_pct_positive, 50)
})

test_that("H10: sign reversal confirmed across configurations", {
  skip_if_not(
    file.exists(file.path(
      "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress",
      "data/van-holstein/Data_Code_Final/PyRate/Outputs",
      "Broad_occurrence_level/NHPP/homo_diversity_0_expSp_expEx_HP.log"
    )),
    "Van Holstein data not downloaded"
  )

  posteriors <- .load_van_holstein_posteriors()

  # Test Broad NHPP
  result_broad <- sign_reversal_test(
    posteriors[["Broad_NHPP_homo"]],
    posteriors[["Broad_NHPP_nonhomo"]],
    config = "Broad_NHPP"
  )
  expect_true(result_broad$values$sign_reversal)

  # Test Wood-Boyle if available
  if (!is.null(posteriors[["WoodBoyle_homo"]]) &&
        !is.null(posteriors[["WoodBoyle_nonhomo"]])) {
    result_wb <- sign_reversal_test(
      posteriors[["WoodBoyle_homo"]],
      posteriors[["WoodBoyle_nonhomo"]],
      config = "WoodBoyle"
    )
    expect_true(result_wb$values$sign_reversal)
  }
})
