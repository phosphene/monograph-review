# T7 Redesigned — Dependency-Ordered Loss in LTEE

## Design

**Original T7 (broken):** Co-segregation of loss mutations with beneficial sweeps in asexual LTEE E. coli. Null model (independent assortment) incoherent for asexual system — test uninformative by design.

**Redesigned T7:** Does metabolic dependency score (from FBA knockout of iJO1366) predict which genes accumulate loss-of-function mutations first in the LTEE?

- **The framework's prediction:** High-dependency genes should be lost LATER (preserved longer, under stronger functional constraint from downstream genes)
- **Relaxed selection (Lahti):** Selective constraint (dN/dS) should predict — genes under weaker selection go first, regardless of dependency
- **Neutral (Lynch):** Mutation rate × Ne should predict — effectively random with respect to dependency

## Data

- **iJO1366 model:** 1,367 genes, 2,583 reactions (from BiGG Models, already in workspace)
- **FBA knockout:** Computed dependency score for every gene (WT flux - KO flux / WT flux)
  - 261 essential (dep ≥ 0.99)
  - 45 partial (0.01 < dep < 0.99)
  - 1,061 nonessential (dep ≤ 0.01)
- **LTEE metagenomic data:** Good et al. 2017, population m1 (Ara-1, non-mutator)
  - 5,172 mutations tracked across 120 timepoints (gen 0-60,000, every 500 gen)
  - 271 LoF mutations (indel + sv + nonsense) across 193 genes
  - 4,699 total mutations across 2,478 genes
- **Gene mapping:** iJO1366 uses b-numbers (b1234); LTEE uses gene names (mutT, dnaE)
  - 31% of mutations mapped to b-numbers (gene name → b-number via iJO1366 annotation)
  - 754 unique genes matched

## Results

| Test | N | Statistic | p-value | Direction | the framework's prediction |
|------|---|-----------|---------|-----------|---------------|
| 1. dep vs time-to-first-ANY-mutation | 1,458 | ρ = -0.039 | 0.137 | Weak negative | Positive (LATER) |
| 2. dep vs time-to-first-LoF | 62 | ρ = -0.254 | 0.047 | Negative (earlier) | Positive (LATER) |
| 3. Mutated vs unmutated dep score | 754 vs 613 | Mann-Whitney | 0.030 | Mutated LOWER dep | ✓ SUPPORTS |
| 4. Essential vs nonessential timing | 226 vs 1,194 | Mann-Whitney | 0.786 | No difference | Essential LATER |
| 5. Fisher's exact (ess vs non mut rate) | 261 vs 1,061 | Fisher's | 0.082 | Marginal | Essential LESS mutated |

## Interpretation

**Mixed signal.** The redesigned T7 produces partial, inconsistent support for the framework:

- **Test 3 is the strongest signal:** Genes that accumulate mutations have significantly LOWER dependency scores than unmutated genes (p=0.030). This is consistent with the framework: highly depended-upon genes are under stronger purifying selection and resist mutation.
- **Tests 1 and 2 go the WRONG direction:** High-dependency genes are mutated EARLIER, not later (ρ negative). This may reflect the fact that essential genes are larger targets (more base pairs = higher mutation probability), or that the LTEE environment directly selects for loss of specific high-cost functions.
- **Tests 4 and 5 show weak/no signal:** Essential vs nonessential timing is not significantly different.

**Critical limitation — gene mapping:** Only 31% of LTEE mutations mapped to iJO1366 b-numbers. The unmapped genes are enriched for y-genes (hypothetical/poorly characterized) and systematic names that may not be in the iJO1366 annotation. A more complete mapping (via EcoCyc or RegulonDB) would improve power.

**Why this is still better than original T7:** The original T7 tested co-segregation with sweeps in an asexual system where the null model was incoherent. The redesigned test asks a meaningful question (does dependency predict mutation timing?) with a proper null model. The answer is mixed, but the test is at least informative — it can in principle distinguish the framework from alternatives.

## Files

- `gene_dependency_scores.tsv` — FBA knockout scores for all 1,367 iJO1366 genes
- `ltee_lof_mutations.tsv` — 228 LoF mutations with timing
- `t7_merged_analysis.tsv` — 62 LoF mutations matched to dependency scores
- `LTEE-metagenomic/` — Full Good et al. 2017 repository (cloned from GitHub)
