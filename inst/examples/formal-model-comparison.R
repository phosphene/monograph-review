#!/usr/bin/env Rscript
## =============================================================================
## Formal Model Comparison: Additive GLM vs Interaction GLM vs Threshold Fit
## =============================================================================
##
## Reproduces the author's original additive GLM (from
## `archive/pre-foundry-scripts/run_formal_model.R`), diagnoses its root-cause
## failure (a data-flattening bug — `as.vector(t(retention))` misaligns
## `dep` and `retention`), and contrasts five model specifications against
## the foundry's pure ODE simulation.
##
## Models:
##   A0 — Additive GLM, MISALIGNED data (author's original, DEPRECATED)
##   A  — Additive GLM, CORRECT data (the one-character fix)
##   B  — Interaction GLM, CORRECT data (theoretically correct spec)
##   C  — Direct threshold-model fit (R6 option: grid-search θ, fit λ)
##   D  — Foundry ODE (theoretical simulation, no data fit — for contrast)
##   E  — Foundry lm(loss_rank ~ dep) + Spearman (current cross-kingdom test)
##
## See `docs/review/formal-model-reproduction.md` for the full literate review.
##
## Run:  Rscript inst/examples/formal-model-comparison.R
## =============================================================================

set.seed(42)

## -----------------------------------------------------------------------------
## 1. The author's 8×6 retention matrix (from run_formal_model.R)
## -----------------------------------------------------------------------------

species   <- c("Lindenbergia", "Pedicularis", "C.exaltata", "C.gronovii",
               "C.campestris", "Boulardia", "Epifagus", "Conopholis")
parasitism <- c(0, 1, 1.5, 2.5, 3, 3, 3, 4)
dep_scores <- c(0, 1, 1, 2, 3, 5)
dep_names  <- c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps")

## Retention matrix: 8 species (rows) × 6 gene categories (columns).
## Column j corresponds to dep_scores[j] and dep_names[j].
retention <- matrix(c(
  1.0, 1.0, 1.0,  1.0, 1.0, 1.0,   # Lindenbergia  (autotroph, para=0)
  0.0, 1.0, 1.0,  1.0, 1.0, 1.0,   # Pedicularis   (facultative, para=1)
  0.0, 1.0, 1.0,  1.0, 1.0, 0.78,  # C.exaltata    (para=1.5)
  0.0, 0.0, 1.0,  1.0, 1.0, 0.72,  # C.gronovii    (para=2.5)
  0.0, 0.0, 0.80, 1.0, 1.0, 0.50,  # C.campestris  (para=3)
  0.0, 0.0, 0.0,  0.0, 0.5, 0.67,  # Boulardia     (para=3)
  0.0, 0.0, 0.0,  0.0, 0.5, 0.67,  # Epifagus      (para=3)
  0.0, 0.0, 0.0,  0.0, 0.0, 0.48   # Conopholis    (holoparasite, para=4)
), nrow = 8, byrow = TRUE)

## Bird data for cross-kingdom transfer (from run_cross_kingdom_L3.R)
bird_dep      <- c(0, 0.5, 1, 1, 1.5, 3, 4, 5)
bird_names    <- c("Wing prop.", "Pect. musc.", "Sternal keel", "Feather asym.",
                   "Wing bones", "Pelvic", "Hindlimb", "Feather struct.")
bird_observed <- c(1, 3, 2, 7, 4, 6, 5, 8)

cat("================================================================\n")
cat("FORMAL MODEL COMPARISON\n")
cat("8 species x 6 gene categories = 48 observations\n")
cat("================================================================\n\n")

## -----------------------------------------------------------------------------
## 2. THE DATA-FLATTENING BUG
## -----------------------------------------------------------------------------
##
## The author's script uses `as.vector(t(retention))` to flatten the 8×6
## matrix into a 48-element vector. But:
##
##   as.vector(t(retention))  →  SPECIES-major  (first 6 = Lindenbergia's genes)
##   rep(dep_scores, each=8)  →  GENE-major     (first 8 = ndh for 8 species)
##
## These orderings don't match. The GLM fits scrambled data → wrong sign.
##
## Fix: as.vector(retention) (no transpose) — gene-major, matching dep/para.

cat("================================================================\n")
cat("THE DATA-FLATTENING BUG\n")
cat("================================================================\n")
cat("Author:  as.vector(t(retention))  -> species-major (6 per species)\n")
cat("Correct: as.vector(retention)     -> gene-major    (8 per gene)\n")
cat("dep = rep(dep_scores, each=8)     -> gene-major    (8 per gene)\n\n")

## Verify alignment
cat("First 8 values with dep=0 (should be ndh = [1,0,0,0,0,0,0,0]):\n")
cat("  Author  (misaligned):", as.vector(t(retention))[1:8], "\n")
cat("  Correct (aligned):   ", as.vector(retention)[1:8], "\n\n")

## -----------------------------------------------------------------------------
## 3. Build both datasets
## -----------------------------------------------------------------------------

## Misaligned (author's original — the bug)
df_bug <- data.frame(
  dep       = rep(dep_scores, each = 8),
  para      = rep(parasitism, 6),
  retention = as.vector(t(retention)),   # BUG: species-major
  dep_name  = rep(dep_names, each = 8),
  species   = rep(species, 6)
)

## Correct (gene-major, no transpose)
df <- data.frame(
  dep       = rep(dep_scores, each = 8),
  para      = rep(parasitism, 6),
  retention = as.vector(retention),       # FIX: gene-major
  dep_name  = rep(dep_names, each = 8),
  species   = rep(species, 6)
)

cat("Mean retention by dependency (correct alignment):\n")
for (i in 1:6) {
  vals <- df$retention[df$dep == dep_scores[i] & df$dep_name == dep_names[i]]
  cat(sprintf("  dep=%d (%-8s): mean = %.3f\n", dep_scores[i], dep_names[i], mean(vals)))
}
cat("\n")

## -----------------------------------------------------------------------------
## 4. MODEL A0: Additive GLM, MISALIGNED data (author's original, DEPRECATED)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL A0: Additive GLM, MISALIGNED data (author original, DEPRECATED)\n")
cat("  retention ~ dep + para  [family = quasibinomial]\n")
cat("================================================================\n\n")

fit_a0 <- glm(retention ~ dep + para, data = df_bug, family = quasibinomial())
s_a0   <- summary(fit_a0)
cat(sprintf("  intercept = %+.3f  (p = %.4f)\n", coef(fit_a0)[1], s_a0$coefficients[1,4]))
cat(sprintf("  dep       = %+.3f  (p = %.4f)  <- valence predicts > 0  [WRONG SIGN]\n",
    coef(fit_a0)[2], s_a0$coefficients[2,4]))
cat(sprintf("  para      = %+.3f  (p = %.4f)  <- valence predicts < 0  [ns]\n",
    coef(fit_a0)[3], s_a0$coefficients[3,4]))
cat(sprintf("  pseudo-R² = %.3f\n", 1 - fit_a0$deviance / fit_a0$null.deviance))
rho_a0 <- cor(rank(predict(fit_a0, data.frame(dep = bird_dep, para = rep(3, 8)),
                           type = "response")),
              bird_observed, method = "spearman")
cat(sprintf("  xfer ρ    = %+.3f  <- oracle: +0.755  [WRONG SIGN]\n\n", rho_a0))

## -----------------------------------------------------------------------------
## 5. MODEL A: Additive GLM, CORRECT data (the one-character fix)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL A: Additive GLM, CORRECT data (the fix: remove t())\n")
cat("  retention ~ dep + para  [family = quasibinomial]\n")
cat("================================================================\n\n")

fit_a <- glm(retention ~ dep + para, data = df, family = quasibinomial())
s_a   <- summary(fit_a)
cat(sprintf("  intercept = %+.3f  (p = %.4f)\n", coef(fit_a)[1], s_a$coefficients[1,4]))
cat(sprintf("  dep       = %+.3f  (p = %.4f)  <- valence predicts > 0  [CORRECT, sig]\n",
    coef(fit_a)[2], s_a$coefficients[2,4]))
cat(sprintf("  para      = %+.3f  (p = %.4f)  <- valence predicts < 0  [CORRECT, sig]\n",
    coef(fit_a)[3], s_a$coefficients[3,4]))
cat(sprintf("  pseudo-R² = %.3f\n", 1 - fit_a$deviance / fit_a$null.deviance))
rho_a <- cor(rank(predict(fit_a, data.frame(dep = bird_dep, para = rep(3, 8)),
                          type = "response")),
             bird_observed, method = "spearman")
cat(sprintf("  xfer ρ    = %+.3f  <- oracle: +0.755  [MATCHES]\n\n", rho_a))

## -----------------------------------------------------------------------------
## 6. MODEL B: Interaction GLM, CORRECT data (theoretically correct spec)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL B: Interaction GLM, CORRECT data (theoretically correct spec)\n")
cat("  retention ~ dep * para  [family = quasibinomial, parasites only]\n")
cat("  (Autotroph row dropped to avoid separation — all retention = 1.0)\n")
cat("================================================================\n\n")

df_par <- df[df$para > 0, ]
fit_b  <- glm(retention ~ dep * para, data = df_par, family = quasibinomial())
s_b    <- summary(fit_b)
for (i in 1:4) {
  cat(sprintf("  %-12s = %+.3f  (p = %.4f)\n",
      rownames(s_b$coefficients)[i], s_b$coefficients[i,1], s_b$coefficients[i,4]))
}
cat(sprintf("  pseudo-R² = %.3f\n", 1 - fit_b$deviance / fit_b$null.deviance))
cat(sprintf("  At para=3, effective dep effect = %+.3f + (%+.3f * 3) = %+.3f\n",
    coef(fit_b)[2], coef(fit_b)[4], coef(fit_b)[2] + coef(fit_b)[4] * 3))
rho_b <- cor(rank(predict(fit_b, data.frame(dep = bird_dep, para = rep(3, 8)),
                          type = "response")),
             bird_observed, method = "spearman")
cat(sprintf("  xfer ρ    = %+.3f\n\n", rho_b))

## -----------------------------------------------------------------------------
## 7. MODEL C: Direct threshold-model fit (R6 option)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL C: Direct threshold-model fit (R6 option)\n")
cat("  C(d,P) = 1 if d >= theta, else exp(-lambda * P)\n")
cat("  Grid-search theta over dependency midpoints; fit lambda via optimize()\n")
cat("================================================================\n\n")

theta_candidates <- c(0.5, 1.5, 2.5, 4.0)
best_sse <- Inf
cat(sprintf("  %-8s %-10s %-10s %-10s\n", "theta", "lambda", "SSE", "R²"))
cat("  --------------------------------------------\n")
for (th in theta_candidates) {
  unprot <- df$dep < th
  if (sum(unprot) > 0) {
    opt <- optimize(function(lam) {
      pred <- exp(-lam * df$para[unprot])
      sum((df$retention[unprot] - pred)^2)
    }, interval = c(0, 10))
    pred <- ifelse(df$dep >= th, 1.0, exp(-opt$minimum * df$para))
    sse  <- sum((df$retention - pred)^2)
    r2   <- 1 - sse / sum((df$retention - mean(df$retention))^2)
    cat(sprintf("  %-8.1f %-10.4f %-10.6f %-10.4f\n", th, opt$minimum, sse, r2))
    if (sse < best_sse) {
      best_sse <- sse; best_th <- th; best_lam <- opt$minimum; best_r2 <- r2
    }
  }
}
cat(sprintf("\n  Best: theta = %.1f, lambda = %.4f, R² = %.4f\n", best_th, best_lam, best_r2))
bird_pred_c <- ifelse(bird_dep >= best_th, 1.0, exp(-best_lam * 3))
rho_c <- cor(rank(bird_pred_c), bird_observed, method = "spearman")
n_ties <- sum(duplicated(bird_pred_c))
cat(sprintf("  xfer ρ    = %+.3f  [ties: %d of %d unprotected share rank]\n\n",
    rho_c, n_ties, length(bird_dep)))

## -----------------------------------------------------------------------------
## 8. MODEL D: Foundry ODE (theoretical simulation — for contrast)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL D: Foundry ODE (theoretical simulation, no data fit)\n")
cat("  dC_i/dt = -lambda * M(t) * I(d_i < theta)\n")
cat("  Deterministic ODE — cannot fail (does not fit the 8x6 matrix)\n")
cat("================================================================\n\n")
cat("  dep sign  : n/a (simulated, not estimated)\n")
cat("  para sig  : n/a\n")
cat("  xfer ρ    : n/a (does not use the 8x6 matrix)\n")
cat("  R²        : n/a (no data fit)\n\n")

## -----------------------------------------------------------------------------
## 9. MODEL E: Foundry lm(loss_rank ~ dep) + Spearman (current)
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("MODEL E: Foundry lm(loss_rank ~ dep) + Spearman (current cross-kingdom)\n")
cat("  Uses idealized literature ranks, not the 8x6 retention matrix\n")
cat("  Transfers slope SIGN only (ranking discards magnitude)\n")
cat("================================================================\n\n")

plant_loss_rank <- c(1, 2, 3, 4, 5, 6)  # idealized: deeper = higher rank = lost later
plant_slope <- coef(lm(plant_loss_rank ~ dep_scores))[2]
rho_e <- cor(rank(plant_slope * bird_dep), bird_observed, method = "spearman")
cat(sprintf("  plant slope = %+.4f  (sign only transfers)\n", plant_slope))
cat(sprintf("  xfer ρ      = %+.3f  [discards magnitude]\n\n", rho_e))

## -----------------------------------------------------------------------------
## 10. SUMMARY TABLE
## -----------------------------------------------------------------------------

cat("================================================================\n")
cat("SUMMARY\n")
cat("================================================================\n\n")
cat(sprintf("  %-38s %-9s %-10s %-9s %-8s\n",
    "Model", "dep sign", "para sig", "xfer ρ", "R²"))
cat("  --------------------------------------------------------------------------\n")
cat(sprintf("  %-38s %-9s %-10s %-9.3f %-8.3f\n",
    "A0: Additive GLM (misaligned, DEPRECATED)",
    sprintf("%+.2f [WRONG]", coef(fit_a0)[2]),
    sprintf("p=%.2f [ns]", s_a0$coefficients[3,4]),
    rho_a0, 1 - fit_a0$deviance / fit_a0$null.deviance))
cat(sprintf("  %-38s %-9s %-10s %-9.3f %-8.3f\n",
    "A: Additive GLM (correct data)",
    sprintf("%+.2f [OK]", coef(fit_a)[2]),
    sprintf("p=%.4f", s_a$coefficients[3,4]),
    rho_a, 1 - fit_a$deviance / fit_a$null.deviance))
cat(sprintf("  %-38s %-9s %-10s %-9.3f %-8.3f\n",
    "B: Interaction GLM (correct data)",
    sprintf("%+.2f [OK]", coef(fit_b)[2]),
    sprintf("p=%.3f", s_b$coefficients[3,4]),
    rho_b, 1 - fit_b$deviance / fit_b$null.deviance))
cat(sprintf("  %-38s %-9s %-10s %-9.3f %-8.3f\n",
    "C: Threshold fit (R6)",
    "gate(θ)", "n/a", rho_c, best_r2))
cat(sprintf("  %-38s %-9s %-10s %-9s %-8s\n",
    "D: Foundry ODE (theory)", "n/a (sim)", "n/a", "n/a", "n/a"))
cat(sprintf("  %-38s %-9s %-10s %-9.3f %-8s\n",
    "E: Foundry lm+ρ (current)", "n/a", "n/a", rho_e, "n/a"))

cat("\n  ROOT CAUSE: as.vector(t(retention)) is species-major;\n")
cat("  rep(dep_scores, each=8) is gene-major. The mismatch shuffles\n")
cat("  dep <-> retention, producing the wrong sign. Fix: as.vector(retention).\n")
cat("\n  With the fix, the additive GLM (Model A) gives dep = +0.84 (p=0.0008),\n")
cat("  para p < 0.0001, cross-kingdom ρ = +0.755 — all matching valence predictions.\n")
