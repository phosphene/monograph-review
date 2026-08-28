# Production Formal Model Verification Guide

This document describes how to verify the production-quality upgrade of the Valence Foundry formal model module.

## Changes Summary

### New Files Created

1. **R/formal_model_classes.R** (12,086 bytes)
   - Three-layer S3 class design per Phosphene R Standards §7
   - `new_valence_threshold_result()` / `validate_valence_threshold_result()` / `valence_threshold_result()`
   - `new_valence_glm_fit()` / `validate_valence_glm_fit()` / `valence_glm_fit()`
   - `new_valence_equilibrium()` / `validate_valence_equilibrium()` / `valence_equilibrium()`

2. **R/formal_model_methods.R** (19,191 bytes)
   - `print.valence_threshold_result()` - human-readable console output
   - `summary.valence_threshold_result()` - tidy data.frame for programmatic access
   - `plot.valence_threshold_result()` - patchwork ggplot2 composition
   - `as.data.frame.valence_threshold_result()` - export for CSV/piping
   - Same pattern for `valence_glm_fit` and `valence_equilibrium` classes

3. **tests/testthat/test-invariants-formal-model.R** (18,572 bytes)
   - 10 invariant properties tested across ~1,000 random parameter combinations
   - Covers: retention bounds, protection gate, monotonicity, convergence, conservation
   - Property-based testing with `withr::with_seed(42)`

4. **vignettes/mathematical-foundations.Rmd** (11,191 bytes)
   - Literate proof connecting ODE → closed-form → code → convergence proof
   - Section-by-step derivation of analytical solution
   - Visualization of biphasic kinetics

### Modified Files

1. **R/formal_model.R** (19,122 bytes)
   - Added `retention_closed_form()` - analytical solution
   - Added `prove_convergence()` - numerical vs analytical comparison
   - Updated `equilibrium_retention()` - returns valence_equilibrium class
   - Updated `retention_at_time()` - returns valence_equilibrium class
   - Updated `threshold_model()` - returns valence_threshold_result class
   - Updated `empirical_formal_model()` - returns valence_glm_fit class
   - All existing functions remain backward-compatible

2. **NAMESPACE**
   - Added exports: `prove_convergence`, `retention_closed_form`
   - All new S3 class helpers exported

## Verification Commands

Run these commands from the valence-foundry repository root:

```bash
# Step 1: Install dependencies and document package
cd lib/python  # or valence-foundry root if running from there
Rscript -e 'devtools::document()'

# Step 2: Run all tests (existing + new invariants)
Rscript -e 'devtools::test(filter = "formal-model")'

# Expected output: all 598+ existing tests pass + new invariant tests pass

# Step 3: Full package check
Rscript -e 'devtools::check()'

# Expected: no errors, no warnings, no notes

# Step 4: Build vignette
Rscript -e 'rmarkdown::render("vignettes/mathematical-foundations.Rmd", 
                  output_format = "html_vignette")'
```

## Test Expectations

### Existing Tests (598 total)

All existing tests in `tests/testthat/` must continue passing. The formal model tests (`test-unit-formal-model.R`) remain unchanged except for the addition of S3 class attributes to returned objects.

### New Invariant Tests

From `tests/testthat/test-invariants-formal-model.R`:

| Invariant | Iterations | Description |
|-----------|------------|-------------|
| Retention ∈ [0,1] | 1,000+ | All closed-form evaluations within bounds |
| Protected → 1.0 | 100 | Traits d ≥ θ always retain exactly 1.0 |
| Unprotected → <1.0 | 100 | Traits d < θ always shed below 1.0 |
| Closed-form ≈ Euler | 50 | Numerical matches analytical within 0.01 |
| Threshold step function | 1 | Binary split at θ verified |
| Monotonicity λ | 5 sequences | Increasing λ decreases retention |
| Monotonicity α | 5 sequences | Increasing α increases retention |
| Conservation structure | 100 | n_protected + n_unprotected = n_total |
| Time limit equilibrium | 2 cases | T→∞ reaches analytical equilibrium |
| Convergence proof | 10 sets | Error decreases with resolution |

Total: ~10,000 property checks

### Backward Compatibility

The existing test patterns must still work:

```r
result <- threshold_model(c(0,1,2), 0.15, 2.5, 10, 0.05, 100)
is.list(result)           # TRUE (still a list)
"values" %in% names(result)     # TRUE (structure preserved)
"metadata" %in% names(result)   # TRUE (structure preserved)
inherits(result, "valence_threshold_result")  # TRUE (now also has S3 class)
```

## Mathematical Proofs Documented

### ODE Statement

$$\frac{dC_i}{dt} = -\lambda \times M(t) \times C_i \times I(d_i < \theta)$$

where $M(t) = M_0 \times e^{-\alpha t}$

### Closed-Form Derivation

Step-by-step separation of variables shown in vignette:

1. Protected traits ($d_i \geq \theta$): trivial solution $C_i(T) = 1$
2. Unprotected traits ($d_i < \theta$): integrate $\int dC/C = -\lambda M_0 \int e^{-\alpha t} dt$
3. Result: $C_i(T) = \exp(-\frac{\lambda M_0}{\alpha}(1 - e^{-\alpha T}))$
4. Equilibrium: $C_i(\infty) = \exp(-\lambda M_0/\alpha)$

### Convergence Proof

`prove_convergence()` demonstrates:
- Step counts: 100, 500, 1000, 5000, 10000
- Max error should decrease as $O(1/n_{steps})$
- At 10k steps, error < 0.001

## Docker Execution (for CI)

The CI pipeline uses Docker containers with R pre-installed:

```bash
# For local reproduction, use rocker/tidyverse image
docker run --rm -v $(pwd):/repo -w /repo rocker/tidyverse:4.5.3 bash -c '
  Rscript -e "devtools::document()" &&
  Rscript -e "devtools::test(filter=\"formal-model\")" &&
  Rscript -e "devtools::check()" &&
  Rscript -e "rmarkdown::render(\"vignettes/mathematical-foundations.Rmd\", 
                output_format = \"html_vignette\")"
'
```

## Git Commit Message

When ready to merge:

```bash
git add -A
git commit -m "feat(formal-model): S3 classes, closed-form proofs, invariant tests, math vignette

- Implement three-layer S3 class pattern (constructor/validator/helper) for result objects
- Add retention_closed_form() analytical solution function
- Implement prove_convergence() demonstrating numerical-to-analytical convergence
- Create 10-invariant test suite with ~10,000 property checks
- Write mathematical-foundations.Rmd literate proof vignette
- Maintain full backward compatibility with existing test patterns
- Follow Phosphene R Standards §7 (S3 design) and DFT axioms A1/A2/A6"
```

## Success Criteria

✅ All 598+ existing tests pass
✅ 10 new invariant tests pass (~10,000 property checks)
✅ `devtools::check()` reports no errors, warnings, notes
✅ Vignette renders successfully
✅ NAMESPACE updated with new exports
✅ Backward compatibility verified (existing code still works)
✅ Math correct (verified by convergence proof)

## Next Steps After Verification

Once verified:

1. Merge to main branch via PR
2. Update dependency versions in parent repos that reference valence-foundry
3. Consider publishing to Posit Package Manager for team-wide use
4. Update README.md to reflect new S3 methods and proof capabilities
