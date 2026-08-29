# Glossary: Experimental Evolution + Statistical Methods

> Domain glossary for the §12 monograph review. Mechanical definitions, not
> pedagogical. Every term is referenced against the ground-truth oracle at
> `baseline/oracle.yml`.

---

## 1. LTEE (Long-Term Evolution Experiment)

**What it is.** The Lenski *E. coli* Long-Term Evolution Experiment: 12 founding
populations (all isogenic, asexual, non-recombining) propagated in a minimal
glucose medium since 1988. At the time of the analysis, 258 sequenced lines
spanning 50,000+ generations.

**What it tests.** The LTEE is the gold-standard system for observing mutation
accumulation under relaxed selection. Genes that are not under selection in the
laboratory environment accumulate loss-of-function mutations at a rate
determined by mutation rate × effective population size (Ne) — not by
functional importance. This makes it the ideal testbed for the **Use-it-or-lose-it
(UI) / passive-drift** prediction: function-loss mutations should drift
independently of beneficial mutations, because the function is not maintained.

**How it's used in §12.** The LTEE provides the data for **T7 (co-segregation
test)**. The question is: do loss-of-function mutations co-segregate with
beneficial mutations at the rate expected by chance (independent assortment),
or less than chance (passive drift of unused genes)?

---

## 2. Co-segregation

**Definition.** Co-segregation measures how often a loss-of-function mutation
appears in the same lineage as a beneficial mutation. In the LTEE context,
"co-segregation" means: given a lineage that accumulated a beneficial mutation
(conferring a fitness advantage in the glucose medium), what fraction of
function-loss mutations also appear in that same lineage?

**The LTEE numbers.**
- **Observed co-segregation rate: 36.4%** — the fraction of function-loss
  mutations that actually co-occur with beneficial mutations.
- **Expected under independent assortment: 61.7%** — the rate expected if
  function-loss mutations are randomly distributed across lineages (independent
  of beneficial mutations).
- **The difference (36.4% vs 61.7%) is significant (p = 0.0001).**

**Why this supports the framework.** The framework's prediction is that genes unused in the lab
environment are under no selection. Their loss-of-function mutations should
drift passively — meaning they are *less likely* to co-segregate with the
beneficial mutations that drive lineage fixation. If every gene were under
selection, loss-of-function mutations would be purged or hitchhike with
beneficial alleles. The observed rate (36.4%) is well below the chance
expectation (61.7%), consistent with passive drift of unused genes.

**Why it does NOT discriminate from independent assortment alone.** The caveat
is that the lower-than-expected co-segregation is also consistent with a
model where loss-of-function mutations are independently assorting across
lineages — i.e., the null model of independent assortment predicts the same
*direction* (lower than 100%). The paper reports this as **suggestive only**,
because the primary confound is hitchhiking (see below).

---

## 3. Hitchhiking

**Definition.** Hitchhiking (genetic draft) occurs when a neutral or mildly
deleterious allele reaches fixation because it is genetically linked to a
beneficial mutation that is under positive selection. In asexual populations
like the LTEE, the entire genome is one linkage block, so any mutation in a
lineage carrying a beneficial mutation will hitchhike to fixation — regardless
of its own fitness effect.

**Why it is the T7 confound.** The co-segregation test (T7) compares observed
co-segregation to independent assortment. But in an *asexual* population,
independent assortment does not hold — the entire genome is linked. The
expected rate under drift (61.7%) is computed assuming independent assortment
of unlinked loci, which is violated in the LTEE. Hitchhiking means that
function-loss mutations physically near beneficial mutations will co-segregate
more often than chance (because they are dragged along), while those far from
any beneficial mutation will co-segregate less often. The observed 36.4% could
reflect linkage architecture (which loss-of-function mutations happen to be
near beneficial mutations by chance) rather than passive drift. The paper
cites this as an explicit caveat: the null model is misspecified for an
asexual population.

**Bottom line.** Hitchhiking is the confound that prevents T7 from
discriminating the framework from independent assortment. The result is suggestive but
not definitive.

---

## 4. Permutation test (T6)

**Definition.** A permutation test (exact test) evaluates whether an observed
ordering is statistically significant by comparing it to all possible
orderings under the null hypothesis (random ordering). No distributional
assumptions — it is distribution-free.

**The 6/720 exact permutation.** For T6 (gene-loss ordering), the test asks:
given the observed rank-ordering of gene-loss events across species, how many
of the 720 possible orderings (6! = 720) produce a Spearman correlation as
extreme as the observed value? The answer is **6 out of 720**, which gives a
p-value of 6/720 = **0.0083**.

**What this means.** Only 6 orderings (out of 720 possible) match the
predicted ordering as well as or better than the observed data. This is strong
evidence against the null hypothesis of random gene-loss ordering. The
permutation test is the primary significance test for the ordering claim: it
tests whether integration-depth predicts gene-loss order better than chance.

**Supporting values (from oracle).**
- Spearman ρ (Orobanchaceae): 0.955
- Spearman ρ (Cuscuta): 0.986
- Cross-family concordance: 0.941
- All three are highly rank-correlated; the permutation test confirms the
  ordering is not random.

---

## 5. Spearman's rho (ρ)

**Definition.** Spearman's rank correlation coefficient (ρ) measures the
monotonic relationship between two variables using their ranks rather than
their raw values. It is a non-parametric statistic: it makes no assumptions
about normality, linearity, or homoscedasticity.

**Why it is used for gene-loss ordering.** Gene-loss ordering is inherently a
rank question: which genes are lost first, which are lost last. The predicted
order (by integration-depth) and the observed order (by empirical gene-loss
timing) are both rank sequences. Spearman's ρ is the natural test because:
- It assesses whether the ranks match, not whether the magnitudes match.
- It is robust to outliers (no assumption about the distribution of loss
  times).
- The null hypothesis (ρ = 0) is that the orderings are unrelated.

**Interpretation.** ρ = 0.955 means the predicted and observed rank-orderings
are nearly identical. ρ = 1.0 would be perfect; ρ = 0 would be random. The
permutation test (T6) confirms that this ρ value is not due to chance.

---

## 6. Quasibinomial GLM

**Definition.** A generalized linear model (GLM) with the quasibinomial family
models a binomial response (proportions: retained/total genes) but with an
extra dispersion parameter to account for
**overdispersion** — variance larger than the binomial assumption allows.

**Why it is used for retention data.** The retention matrix (e.g., the 8×6
Orobanchaceae retention matrix) contains proportions: for each combination of
species and gene depth, what fraction of genes at that depth are retained?
These proportions are overdispersed because:
- Genes are not independent (they share regulatory pathways, physical
  proximity, etc.).
- Species are not independent (shared evolutionary history).
- The binomial assumption (independence of each gene) is violated.

The quasibinomial GLM handles this by estimating a dispersion parameter φ from
the data, rather than fixing φ = 1 (as the standard binomial GLM does). The
coefficient estimates are the same as the binomial GLM, but the standard errors
are scaled by √φ, making the inference more conservative.

**T6 application.** The quasibinomial GLM tests whether integration-depth (dep)
positively predicts retention (the framework's prediction) and parasitism level (para)
negatively predicts retention (unprotected genes are shed). The results:
- dep coefficient: +0.84 (p = 0.0008) — deeper integration → higher retention
- para coefficient: -1.86 (p < 0.0001) — more parasitic → lower retention
- **Pseudo-R² = 0.82**

**What pseudo-R² means.** Pseudo-R² is a goodness-of-fit measure for GLMs
analogous to R² in linear regression. It compares the log-likelihood of the
fitted model to the null model (intercept-only). A value of 0.82 means the
model explains 82% of the deviance in the retention data — a very strong fit.
Unlike OLS R², it cannot be interpreted as "variance explained" in the strict
sense, but it is a reliable measure of proportional reduction in deviance.

**Cross-kingdom GLM (empirical formal model).** A separate additive GLM
(retention ~ dep + para) fit to the corrected 8×6 Orobanchaceae retention
matrix confirms:
- dep coefficient: +0.8375 (p = 0.0008)
- para coefficient: -1.8644 (p < 0.0001)
- pseudo-R² = 0.5515
- cross-kingdom ρ = +0.7545 (p = 0.0305)
- Result: the framework's prediction confirmed (dep positive, para negative).

---

## 7. Cross-kingdom rho

**Definition.** Cross-kingdom ρ is the Spearman rank correlation between a
parameter derived from one kingdom (plant gene-loss ordering) and an observed
ordering in another kingdom (bird morphological change ordering). It tests
whether the *ordering* of trait loss is transferable across evolutionary
lineages.

**The result.** Plant-derived parameters from the GLM (integration-depth
slope) predict the ordering of bird morphological changes with ρ = 0.755
(p = 0.031). This is the **L3 cross-kingdom test**.

**What it means: ordering claim, not rate claim.** The cross-kingdom ρ
measures whether the *rank order* of trait loss in plants predicts the *rank
order* of morphological change in birds. It does **not** measure whether the
rate of loss is the same. The oracle explicitly states: "Ordering transfers
across kingdoms; rate does not." This is the key prediction of the framework:
the hierarchy of integration-depth (which traits are most protected) is
conserved across deep evolutionary time, but the actual rate of loss depends
on lineage-specific parameters (Ne, mutation rate, selection pressure).

**Why this distinguishes the framework from alternatives.** A model where substrates are
completely independent (i.e., plant gene loss and bird morphology are driven
by different mechanisms) predicts ρ ≈ 0. The observed ρ = 0.755 with p =
0.031 rejects the independent-substrates null. It does not, however, tell us
*how fast* the morphology changes — only the *order* in which traits change.

---

## 8. Threshold model (ODE)

**Definition.** The threshold model is a deterministic ordinary differential
equation (ODE) that simulates genome reduction as a biphasic process. It is
**not an empirical fit** — it is a theoretical model that generates predictions
about the kinetics of gene loss.

**Components.**
- **Threshold parameter (θ = 2.5):** Genes with an integration-depth (d) ≥ θ
  are "protected" — they are retained at ~1.0 indefinitely. Genes with d < θ
  are "unprotected" — they decay to ~0 as the simulation progresses. The
  threshold is a hard cutoff (step function, not sigmoid).
- **Biphasicity = 1.0:** This is the model's output, not a setting. When
  biphasicity = 1.0, the model perfectly discriminates: protected traits
  retain at 1.0 (Phase 2, slow), unprotected traits shed to ~0 (Phase 1,
  fast). The value 1.0 means the biphasic signature is at its maximum — no
  intermediate states, no graded response.
- **Phase 1 rate:** 0.9999964 (unprotected genes lost almost immediately)
- **Phase 2 rate:** 3.5589 × 10⁻⁶ (protected genes retained essentially
  forever)
- **Early/late displacement ratio:** 280,980 — the ratio of the two rates,
  indicating complete temporal separation between the two phases.

**Why the model is deterministic, not empirical.** The threshold model is
governed by Axiom A2 (no randomness): the ODE is deterministic, parameterized
by the threshold θ, and produces exact numerical outputs. The values in the
oracle are **regression targets** — if the code changes and these values shift,
something is broken. The model does not fit to data; it generates a synthetic
prediction that the empirical data (T3) is then tested against.

**The final retention vector.** For depths [0, 1, 2, 3, 5] with θ = 2.5:
- Depth 0, 1, 2 (unprotected): retention ≈ [~0, ~0, ~0]
- Depth 3, 5 (protected): retention = [1, 1]
- This is the ideal biphasic pattern: all-or-nothing retention by depth.

**Relationship to T3.** T3 (Endosymbiont biphasic) is the *empirical* test that
fits the biphasic model to real endosymbiont genome data (R² = 0.920, BF =
6.7). The threshold model is the *theoretical* companion that defines what
biphasicity looks like in the ideal case.

---

## 9. Island bird morphology

**Definition.** A dataset of morphological changes in island bird species:
measurements of traits (e.g., beak shape, body size, wing reduction) that have
changed in island populations relative to their mainland ancestors. Island
birds are a classic system for studying convergent morphological evolution
under shared selective pressures (e.g., loss of flight, reduced territoriality,
altered foraging).

**What "morphological change ordering" means.** The dataset records not just
*that* traits changed, but the *order* in which they changed. For example, in
flightless island birds, did wing reduction precede or follow body size
change? The ordering is a rank sequence: which trait changes first, second,
third, etc.

**How it is used in the cross-kingdom test.** The cross-kingdom test (L3) asks:
does the integration-depth ordering of plant genes (which genes are lost
first) predict the ordering of morphological change in island birds (which
traits change first)? The answer is yes (ρ = 0.755, p = 0.031). This is
interpreted as evidence that the same hierarchy of functional protection
applies across kingdoms: traits with deeper integration in the organism's
biology are lost last (or retained longest) in both plants and birds.

**What it does NOT claim.** The test does not claim that the rate of
morphological change in birds matches the rate of gene loss in plants. The
bird species are not a model for plant evolution — they are a test of whether
the *ordering principle* (integration-depth hierarchy) is conserved across
deep evolutionary time. The oracle explicitly flags: "Ordering transfers across
kingdoms; rate does not."

---

## Summary table: T6, T7, L3 tests

| Test | Statistic | Value | p-value | Supports the framework? | Distinguishes? |
|------|-----------|-------|---------|-------------|----------------|
| T6 (ordering) | Spearman ρ | 0.955 | 0.0083 (perm) | Yes | Yes (from random) |
| T6 (GLM) | Pseudo-R² | 0.82 | 0.0001 | Yes | Yes |
| T7 (co-seg) | Observed % | 36.4% | 0.0001 | Yes (suggestive) | No (hitchhiking) |
| L3 (cross-kingdom) | Spearman ρ | 0.755 | 0.031 | Yes | Yes (from independent) |

## Deterministic model values

| Model | Parameter | Value | Meaning |
|-------|-----------|-------|---------|
| Threshold ODE | θ | 2.5 | Protection cutoff depth |
| Threshold ODE | Biphasicity | 1.0 | Perfect biphasic discrimination |
| Threshold ODE | Phase 1 rate | 0.9999964 | Unprotected → immediate loss |
| Threshold ODE | Phase 2 rate | 3.559 × 10⁻⁶ | Protected → essentially permanent |
| Formal GLM | dep coefficient | +0.8375 | Depth → retention (positive, p=0.0008) |
| Formal GLM | para coefficient | -1.8644 | Parasitism → loss (negative, p<0.0001) |
| Formal GLM | Pseudo-R² | 0.5515 | Deviance explained |
| Formal GLM | Cross-kingdom ρ | 0.7545 | Ordering transfers (p=0.0305) |