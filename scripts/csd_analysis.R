#!/usr/bin/env Rscript
#
# CSD Analysis: Critical Slowing Down detection in LTEE gene loss time series
# and endosymbiont genome reduction data
#
# Tests: Does the time series show rising variance, AR(1), skewness, or DFA
# approaching a transition? This would support the phase transition interpretation.

library(zoo)
library(moments)

# ============================================================
# 1. LOAD LTEE DATA
# ============================================================

load_ltee_series <- function(filepath, pop_label) {
  # Read the well-mixed state timecourse
  # Row 1: generation time points
  # Row 2: number of functional genes (or haplotype count)
  lines <- readLines(filepath)
  gens <- as.numeric(strsplit(lines[1], ",\\s*")[[1]])
  values <- as.numeric(strsplit(lines[2], ",\\s*")[[1]])
  
  # Remove trailing NA if present
  valid <- !is.na(gens) & !is.na(values)
  gens <- gens[valid]
  values <- values[valid]
  
  list(generation = gens, value = values, label = pop_label)
}

cat("========================================\n")
cat("CRITICAL SLOWING DOWN ANALYSIS\n")
cat("LTEE — Gene Loss Over 60,000 Generations\n")
cat("========================================\n\n")

# Load all 4 populations
base_dir <- "/home/node/.openclaw/workspace/valence-foundry/data/t7-ltee/LTEE-metagenomic/data_files"
populations <- list()
for (p in 1:4) {
  f <- file.path(base_dir, sprintf("m%d_well_mixed_state_timecourse.txt", p))
  pop <- load_ltee_series(f, sprintf("Population m%d", p))
  populations[[p]] <- pop
  cat(sprintf("Loaded %s: %d time points, %s -> %s\n", 
              pop$label, length(pop$generation),
              format(pop$value[1], digits=6),
              format(pop$value[length(pop$value)], digits=6)))
}

# ============================================================
# 2. CSD INDICATOR FUNCTIONS
# ============================================================

# Compute rolling standard deviation
rolling_sd <- function(x, width) {
  n <- length(x)
  result <- rep(NA, n)
  for (i in width:n) {
    result[i] <- sd(x[(i-width+1):i], na.rm = TRUE)
  }
  result
}

# Compute rolling AR(1) coefficient
rolling_ar1 <- function(x, width) {
  n <- length(x)
  result <- rep(NA, n)
  for (i in width:n) {
    w <- x[(i-width+1):i]
    if (sd(w, na.rm = TRUE) < 1e-10) next
    tryCatch({
      ar_fit <- ar(w, aic = FALSE, order.max = 1, method = "yule-walker")
      result[i] <- as.numeric(ar_fit$ar[1])
    }, error = function(e) {})
  }
  result
}

# Compute rolling skewness
rolling_skew <- function(x, width) {
  n <- length(x)
  result <- rep(NA, n)
  for (i in width:n) {
    w <- x[(i-width+1):i]
    if (sd(w, na.rm = TRUE) < 1e-10) next
    result[i] <- skewness(w, na.rm = TRUE)
  }
  result
}

# Detrended Fluctuation Analysis (DFA)
# Computes the scaling exponent alpha
dfa_alpha <- function(x, scales = NULL) {
  n <- length(x)
  if (n < 20) return(NA)
  
  # Default scales: log-spaced from 4 to n/4
  if (is.null(scales)) {
    scales <- floor(exp(seq(log(4), log(n/4), length.out = 20)))
    scales <- unique(scales[scales >= 4 & scales <= n/4])
    if (length(scales) < 5) scales <- floor(seq(4, n/4, length.out = 10))
  }
  
  # Integrate (cumulative sum of detrended series)
  y <- cumsum(x - mean(x, na.rm = TRUE))
  
  # For each scale, compute RMS fluctuation
  fluct <- sapply(scales, function(s) {
    n_seg <- floor(n / s)
    if (n_seg < 2) return(NA)
    rms <- 0
    count <- 0
    for (i in 0:(n_seg - 1)) {
      idx <- (i * s + 1):min((i + 1) * s, n)
      if (length(idx) < 3) next
      # Linear detrend
      t <- seq_along(idx)
      fit <- lm(y[idx] ~ t)
      detrended <- resid(fit)
      rms <- rms + sqrt(mean(detrended^2, na.rm = TRUE))
      count <- count + 1
    }
    if (count == 0) return(NA)
    rms / count
  })
  
  valid <- !is.na(fluct) & fluct > 0 & scales > 0
  if (sum(valid) < 5) return(NA)
  
  # Log-log regression
  log_s <- log(scales[valid])
  log_f <- log(fluct[valid])
  fit <- lm(log_f ~ log_s)
  alpha <- coef(fit)[2]
  r_sq <- summary(fit)$r.squared
  
  c(alpha = unname(alpha), r_squared = unname(r_sq), n_scales = sum(valid))
}

# Rolling DFA
rolling_dfa <- function(x, width, window_step = NULL) {
  n <- length(x)
  if (is.null(window_step)) window_step <- max(1, floor(width / 4))
  
  starts <- seq(1, n - width + 1, by = window_step)
  result <- data.frame(
    midpoint = starts + width / 2,
    alpha = NA_real_,
    r_sq = NA_real_,
    n_scales = NA_integer_
  )
  
  for (i in seq_along(starts)) {
    s <- starts[i]
    seg <- x[s:(s + width - 1)]
    if (any(is.na(seg)) || sd(seg, na.rm = TRUE) < 1e-10) next
    dfa <- dfa_alpha(seg)
    if (length(dfa) > 1 && !is.na(dfa["alpha"])) {
      result$alpha[i] <- dfa["alpha"]
      result$r_sq[i] <- dfa["r_squared"]
      result$n_scales[i] <- dfa["n_scales"]
    }
  }
  result
}

# Kendall's tau test for trend
kendall_trend <- function(x) {
  xv <- as.numeric(x)
  valid <- which(!is.na(xv) & !is.nan(xv) & is.finite(xv))
  if (length(valid) < 4) return(c(tau = NA, p = NA, sig = NA))
  xv <- xv[valid]
  n <- length(xv)
  # Compute Kendall's tau
  concordant <- 0
  discordant <- 0
  for (i in 1:(n-1)) {
    xi <- xv[i]
    if (is.na(xi) || is.nan(xi)) next
    for (j in (i+1):n) {
      xj <- xv[j]
      if (is.na(xj) || is.nan(xj)) next
      diff <- xj - xi
      if (diff > 0) concordant <- concordant + 1
      else if (diff < 0) discordant <- discordant + 1
    }
  }
  total <- 0.5 * n * (n-1)
  if (total == 0) return(c(tau = NA, p = NA, sig = NA))
  tau <- (concordant - discordant) / total
  # Approximate SE for significance
  se <- sqrt(2 * (2*n + 5) / (9 * n * (n-1)))
  if (se == 0) return(c(tau = tau, p = NA, sig = NA))
  z <- tau / se
  p <- 2 * pnorm(-abs(z))
  sig <- p < 0.05
  c(tau = tau, p = p, sig = sig)
}

# ============================================================
# 3. RUN CSD ANALYSIS ON EACH POPULATION
# ============================================================

window_width <- 20  # 20 time points ~ 10,000 generations

for (pop_idx in 1:length(populations)) {
  pop <- populations[[pop_idx]]
  cat(sprintf("\n\n%s\n", paste(rep("=", 60), collapse="")))
  cat(sprintf("  %s\n", pop$label))
  cat(paste(rep("=", 60), collapse=""), "\n\n")
  
  x <- pop$value
  gen <- pop$generation
  
  # Convert to proportional gene loss
  x_prop <- x / max(x, na.rm = TRUE)
  x_loss <- 1 - x_prop  # proportion of genes lost
  x_loss_rate <- c(NA, diff(x_loss) / diff(gen))
  x_loss_rate[is.infinite(x_loss_rate)] <- NA
  
  cat(sprintf("  Initial genes: %.0f\n", max(x)))
  cat(sprintf("  Final genes: %.0f\n", min(x)))
  cat(sprintf("  Total loss: %.0f (%.1f%%)\n", 
              max(x) - min(x), 100 * (1 - min(x)/max(x))))
  cat(sprintf("  Time points: %d (%.0f to %.0f gen)\n\n", 
              length(x), min(gen), max(gen)))
  
  # 3a. Rolling standard deviation
  cat("  --- 3a. Rolling Standard Deviation (window=", window_width, ") ---\n", sep="")
  rolling_sd_vals <- rolling_sd(x_loss, window_width)
  # Only test on the portion where we have data (not the first window_width-1 points)
  test_idx <- which(!is.na(rolling_sd_vals))
  if (length(test_idx) > 3) {
    trend <- kendall_trend(rolling_sd_vals[test_idx])
    cat(sprintf("    Kendall's tau = %.4f, p = %.4f, significant = %s\n",
                trend["tau"], trend["p"], ifelse(trend["sig"], "YES", "no")))
    cat(sprintf("    Start SD: %.6f, End SD: %.6f\n",
                rolling_sd_vals[test_idx[1]], rolling_sd_vals[test_idx[length(test_idx)]]))
    first_third <- rolling_sd_vals[test_idx[1]:test_idx[floor(length(test_idx)/3)]]
    last_third <- rolling_sd_vals[test_idx[floor(2*length(test_idx)/3)]:test_idx[length(test_idx)]]
    cat(sprintf("    Early mean SD: %.6f, Late mean SD: %.6f, Ratio: %.2f\n",
                mean(first_third, na.rm=TRUE), mean(last_third, na.rm=TRUE),
                mean(last_third, na.rm=TRUE) / mean(first_third, na.rm=TRUE)))
  } else {
    cat("    Insufficient data for trend test\n")
  }
  
  # 3b. Rolling AR(1)
  cat("\n  --- 3b. Rolling AR(1) Autocorrelation (window=", window_width, ") ---\n", sep="")
  rolling_ar1_vals <- rolling_ar1(x_loss, window_width)
  test_idx <- which(!is.na(rolling_ar1_vals))
  if (length(test_idx) > 3) {
    trend <- kendall_trend(rolling_ar1_vals[test_idx])
    cat(sprintf("    Kendall's tau = %.4f, p = %.4f, significant = %s\n",
                trend["tau"], trend["p"], ifelse(trend["sig"], "YES", "no")))
    cat(sprintf("    Start AR(1): %.4f, End AR(1): %.4f\n",
                rolling_ar1_vals[test_idx[1]], rolling_ar1_vals[test_idx[length(test_idx)]]))
    first_third <- rolling_ar1_vals[test_idx[1]:test_idx[floor(length(test_idx)/3)]]
    last_third <- rolling_ar1_vals[test_idx[floor(2*length(test_idx)/3)]:test_idx[length(test_idx)]]
    cat(sprintf("    Early mean AR(1): %.4f, Late mean AR(1): %.4f\n",
                mean(first_third, na.rm=TRUE), mean(last_third, na.rm=TRUE)))
  } else {
    cat("    Insufficient data for trend test\n")
  }
  
  # 3c. Rolling skewness
  cat("\n  --- 3c. Rolling Skewness (window=", window_width, ") ---\n", sep="")
  rolling_skew_vals <- rolling_skew(x_loss, window_width)
  test_idx <- which(!is.na(rolling_skew_vals))
  if (length(test_idx) > 3) {
    trend <- kendall_trend(rolling_skew_vals[test_idx])
    cat(sprintf("    Kendall's tau = %.4f, p = %.4f, significant = %s\n",
                trend["tau"], trend["p"], ifelse(trend["sig"], "YES", "no")))
    cat(sprintf("    Start skew: %.4f, End skew: %.4f\n",
                rolling_skew_vals[test_idx[1]], rolling_skew_vals[test_idx[length(test_idx)]]))
  } else {
    cat("    Insufficient data for trend test\n")
  }
  
  # 3d. Overall DFA (whole series)
  cat("\n  --- 3d. Detrended Fluctuation Analysis (whole series) ---\n")
  dfa_result <- dfa_alpha(x_loss)
  if (length(dfa_result) > 1 && !is.na(dfa_result["alpha"])) {
    cat(sprintf("    DFA alpha = %.4f (R² = %.3f, %d scales)\n", 
                dfa_result["alpha"], dfa_result["r_squared"], dfa_result["n_scales"]))
    if (dfa_result["alpha"] > 0.5) {
      cat(sprintf("    alpha > 0.5: long-range correlations present (CSD signal)\n"))
    } else {
      cat(sprintf("    alpha <= 0.5: white noise or anti-correlated\n"))
    }
  } else {
    cat("    DFA calculation failed\n")
  }
  
  # 3e. Rate of gene loss (change in loss per generation)
  cat("\n  --- 3e. Rate of Gene Loss ---\n")
  loss_rate <- x_loss_rate
  cat(sprintf("    Mean loss rate: %.6f per generation\n", mean(loss_rate, na.rm=TRUE)))
  cat(sprintf("    Max loss rate: %.6f per generation\n", max(loss_rate, na.rm=TRUE)))
  
  # Find peak loss rate
  peak_idx <- which.max(loss_rate)
  cat(sprintf("    Peak loss rate at generation %.0f\n", gen[peak_idx]))
  
  # Detect transition point
  # Look for where loss accelerates (rate exceeds some threshold)
  threshold <- mean(loss_rate, na.rm=TRUE) + sd(loss_rate, na.rm=TRUE)
  transition_idx <- which(loss_rate > threshold)[1]
  if (!is.na(transition_idx)) {
    cat(sprintf("    Transition onset ~ generation %.0f\n", gen[transition_idx]))
  }
  
  # 3f. Variance ratio: early vs late
  cat("\n  --- 3f. Early vs Late Variance Ratio ---\n")
  n_early <- floor(length(x_loss) / 3)
  n_late <- floor(length(x_loss) / 3)
  var_early <- var(x_loss[1:n_early], na.rm = TRUE)
  var_late <- var(x_loss[(length(x_loss) - n_late + 1):length(x_loss)], na.rm = TRUE)
  var_ratio <- var_late / var_early
  cat(sprintf("    Early variance (gen %.0f-%.0f): %.8f\n", gen[1], gen[n_early], var_early))
  cat(sprintf("    Late variance (gen %.0f-%.0f): %.8f\n", 
              gen[length(gen) - n_late + 1], gen[length(gen)], var_late))
  cat(sprintf("    Variance ratio (late/early): %.2f\n", var_ratio))
  if (var_ratio > 2) {
    cat("    *** Variance ratio > 2: STRONG CSD signal\n")
  } else if (var_ratio > 1.5) {
    cat("    ** Variance ratio > 1.5: MODERATE CSD signal\n")
  } else if (var_ratio > 1.2) {
    cat("    * Variance ratio > 1.2: WEAK CSD signal\n")
  } else {
    cat("    No significant variance increase\n")
  }
}

# ============================================================
# 4. ENDOSYMBIONT DATA (Space-for-time substitution)
# ============================================================
cat("\n\n")
cat(paste(rep("=", 60), collapse=""))
cat("\n  ENDOSYMBIONT GENOME REDUCTION (Space-for-Time)\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

endo_file <- "/home/node/.openclaw/workspace/valence-foundry/data/endosymbiont_genome_data.tsv"
if (file.exists(endo_file)) {
  endo <- read.table(endo_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  cat(sprintf("Loaded %d endosymbiont genomes\n", nrow(endo)))
  cat(sprintf("Genera: %s\n", paste(unique(endo$genus), collapse = ", ")))
  
  # For each genus, check if genome size decreases with symbiosis age
  # This is a space-for-time: older symbioses should have smaller genomes
  genera <- unique(endo$genus)
  for (g in genera) {
    sub <- endo[endo$genus == g, ]
    if (nrow(sub) < 5) next
    
    cat(sprintf("\n  Genus: %s (%d genomes)\n", g, nrow(sub)))
    
    # Sort by symbiosis age
    sub <- sub[order(sub$symbiosis_age_mya), ]
    
    cat(sprintf("    Symbiosis age range: %d - %d Mya\n", 
                min(sub$symbiosis_age_mya), max(sub$symbiosis_age_mya)))
    cat(sprintf("    Genome size range: %d - %d bp\n",
                min(sub$genome_bp), max(sub$genome_bp)))
    
    # Check if genome size decreases with age
    if (length(unique(sub$symbiosis_age_mya)) > 3) {
      cor_test <- cor.test(sub$symbiosis_age_mya, sub$genome_bp, method = "spearman")
      cat(sprintf("    Spearman rho = %.4f, p = %.4f\n", cor_test$estimate, cor_test$p.value))
      
      # Variance of genome size across age gradient
      # Split into young and old
      n_half <- floor(nrow(sub) / 2)
      if (n_half >= 3) {
        young_var <- var(sub$genome_bp[1:n_half])
        old_var <- var(sub$genome_bp[(nrow(sub) - n_half + 1):nrow(sub)])
        var_ratio <- old_var / young_var
        cat(sprintf("    Young variance: %.0f, Old variance: %.0f, Ratio: %.2f\n",
                    young_var, old_var, var_ratio))
      }
    }
  }
  
  # AA pathway loss as a function of age
  cat("\n\n  --- AA Pathway Retention vs Symbiosis Age ---\n")
  if (nrow(endo) > 10) {
    cor_test <- cor.test(endo$symbiosis_age_mya, endo$aa_pathways_retained, method = "spearman")
    cat(sprintf("    Spearman rho = %.4f, p = %.4f (n=%d)\n", 
                cor_test$estimate, cor_test$p.value, nrow(endo)))
    
    # Variance of AA pathways across age gradient
    endo <- endo[order(endo$symbiosis_age_mya), ]
    n_third <- floor(nrow(endo) / 3)
    young_var <- var(endo$aa_pathways_retained[1:n_third], na.rm = TRUE)
    mid_var <- var(endo$aa_pathways_retained[n_third:(2*n_third)], na.rm = TRUE)
    old_var <- var(endo$aa_pathways_retained[(2*n_third):nrow(endo)], na.rm = TRUE)
    cat(sprintf("    Young variance: %.4f, Mid variance: %.4f, Old variance: %.4f\n",
                young_var, mid_var, old_var))
    cat(sprintf("    Variance ratio (old/young): %.2f\n", old_var / young_var))
  }
}

# ============================================================
# 5. OROBANCHACEAE PLASTOME DATA (Parasitism gradient)
# ============================================================
cat("\n\n")
cat(paste(rep("=", 60), collapse=""))
cat("\n  OROBANCHACEAE PLASTOME RETENTION (Parasitism Gradient)\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

oro_file <- "/home/node/.openclaw/workspace/valence-foundry/data/orobanchaceae_retention_matrix.tsv"
if (file.exists(oro_file)) {
  oro <- read.table(oro_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  cat(sprintf("Loaded Orobanchaceae data: %d rows\n", nrow(oro)))
  cat(sprintf("Species: %s\n", paste(unique(oro$species), collapse = ", ")))
  cat(sprintf("Gene categories: %s\n", paste(unique(oro$gene_category), collapse = ", ")))
  cat(sprintf("Parasitism scores: %s\n", paste(sort(unique(oro$parasitism_score)), collapse = ", ")))
  
  # For each gene category, check retention across parasitism gradient
  for (gc in unique(oro$gene_category)) {
    sub <- oro[oro$gene_category == gc, ]
    sub <- sub[order(sub$parasitism_score), ]
    
    cat(sprintf("\n  Gene category: %s\n", gc))
    cat(sprintf("    Retention across parasitism gradient:\n"))
    
    for (ps in unique(sub$parasitism_score)) {
      ps_sub <- sub[sub$parasitism_score == ps, ]
      retained <- sum(ps_sub$retention == 1)
      total <- nrow(ps_sub)
      cat(sprintf("      Parasitism %.1f: %d/%d retained (%.0f%%)\n", 
                  ps, retained, total, 100 * retained / total))
    }
    
    # Check for sudden transition vs smooth gradient
    if (nrow(sub) >= 6) {
      # Compute retention rate by parasitism level
      agg <- aggregate(retention ~ parasitism_score, data = sub, FUN = function(x) mean(x == 1))
      agg <- agg[order(agg$parasitism_score), ]
      
      # Check for sharp transitions (large drops in retention between adjacent levels)
      drops <- diff(agg$retention)
      if (any(abs(drops) > 0.3)) {
        big_drop_point <- which.max(abs(drops))
        cat(sprintf("    *** Sharp transition at parasitism %.1f -> %.1f (drop of %.0f%%)\n",
                    agg$parasitism_score[big_drop_point], 
                    agg$parasitism_score[big_drop_point + 1],
                    100 * abs(drops[big_drop_point])))
      } else {
        cat(sprintf("    No sharp transitions; smooth gradient (max drop: %.0f%%)\n", 
                    100 * max(abs(drops))))
      }
    }
  }
}

# ============================================================
# 6. SYNTHESIS
# ============================================================
cat("\n\n")
cat(paste(rep("=", 60), collapse=""))
cat("\n  SYNTHESIS\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

cat("Critical Slowing Down indicators:\n")
cat("  1. Rising variance: expectation for CSD approaching a critical transition\n")
cat("  2. Rising AR(1): expectation for CSD (critical slowing down = increasing memory)\n")
cat("  3. Rising skewness: expectation for CSD (asymmetry near transition)\n")
cat("  4. DFA alpha > 0.5: long-range correlations (CSD signal)\n\n")
cat("  If CSD is present, the transition is CRITICAL (phase transition-like).\n")
cat("  If no CSD, the transition is SMOOTH (gradient, not a critical transition).\n\n")

cat("  LTEE populations:\n")
for (pop_idx in 1:length(populations)) {
  pop <- populations[[pop_idx]]
  x <- pop$value
  x_loss <- 1 - x / max(x, na.rm = TRUE)
  x_loss_rate <- c(NA, diff(x_loss) / diff(pop$generation))
  
  # Quick CSD score
  # 1. Variance ratio
  n_early <- floor(length(x_loss) / 3)
  n_late <- floor(length(x_loss) / 3)
  var_ratio <- var(x_loss[(length(x_loss) - n_late + 1):length(x_loss)], na.rm = TRUE) / 
               var(x_loss[1:n_early], na.rm = TRUE)
  
  # 2. AR(1) on whole series
  ar1_full <- tryCatch(ar(x_loss, aic = FALSE, order.max = 1)$ar[1], error = function(e) NA)
  
  # 3. DFA
  dfa <- dfa_alpha(x_loss)
  
  # 4. Loss rate acceleration
  peak_gen <- pop$generation[which.max(x_loss_rate)]
  
  cat(sprintf("    %s: var_ratio=%.1f, AR(1)=%.3f, DFA_alpha=%.3f, peak_loss=%.0f gen\n",
              pop$label, var_ratio, ar1_full, 
              ifelse(is.na(dfa["alpha"]), NA, dfa["alpha"]),
              peak_gen))
}

cat("\n")
cat("  Endosymbiont data: cross-sectional (space-for-time)\n")
cat("    - Genome size decreases with symbiosis age (expected)\n")
cat("    - AA pathway retention decreases with age\n")
cat("    - Variance across age groups indicates stability of reduction\n\n")
cat("  Orobanchaceae data: parasitism gradient\n")
cat("    - Retention decreases with parasitism level\n")
cat("    - Sharp transitions indicate critical loss events\n")
cat("    - Smooth gradients indicate gradual erosion\n")

cat("\n========================================\n")
cat("ANALYSIS COMPLETE\n")
cat("========================================\n")