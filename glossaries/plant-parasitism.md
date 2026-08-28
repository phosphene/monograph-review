# PLANT/PARASITISM Domain Glossary

> Domain glossary for the Valence-Ingression monograph review.
> Defines terms mechanically — by how they work in the biology, not by analogy.
> All definitions are grounded in the vi-foundry's baseline tests (T1–T2, T6, formal model, L3).

---

## 1. Plastome

**Definition.** The plastid genome — the circular DNA molecule inside plastids (chloroplasts, chromoplasts, leucoplasts). In photosynthetic angiosperms, the plastome is typically 120–160 kb, encoding ~110–130 genes. It is maternally inherited (non-recombining, haploid, uniparental) and present in many copies per cell.

**What it carries.** Plastome genes fall into three functional classes:
- **Photosynthesis genes** (~50): subunits of photosystem I (psa), photosystem II (psb), cytochrome b6f (pet), ATP synthase (atp), ribulose-1,5-bisphosphate carboxylase/oxygenase large subunit (rbcL).
- **Gene expression machinery** (~30): ribosomal RNA (rrn), transfer RNA (trn), ribosomal proteins (rpl, rps), RNA polymerase subunits (rpoA, rpoB, rpoC1, rpoC2).
- **Other** (~10–20): NADH dehydrogenase (ndh), maturation factors, conserved open reading frames.

**Why parasitism affects it.** Parasitic plants reduce or lose photosynthesis entirely — they obtain carbon and water from a host. The plastome no longer needs to maintain the full photosynthetic gene complement. Because plastid function (plastome→plastid gene expression→plastid protein products) is the substrate the plastome serves, when plastid function is curtailed, the selection pressure maintaining plastome-encoded genes relaxes. The VI framework predicts that the *order* of gene loss is determined by each gene's integration depth — how many other plastid functions depend on its product. Photosynthesis-specific genes (ndh, psa, psb) are lost early; multi-functional housekeeping genes (rpl, rps, atp) are retained longer.

**How it's measured.** Plastome size (kb) is extracted from GenBank assembly records. In the foundry, the T1 test regresses plastome size against parasitism level across 12–19 Orobanchaceae species using PGLS. The oracle reports β = −23.5 kb per parasitism level (R² = 0.652, p = 1.25 × 10⁻⁹). The sign is negative: deeper parasitism → smaller plastome.

---

## 2. Orobanchaceae

**Definition.** The broomrape family — a large (~2,000 species in ~90 genera) plant family within Lamiales, characterized by the broadest known range of parasitism depth, from fully autotrophic through facultative hemiparasite to obligate holoparasite. It is the model system for parasitism gradient studies.

**Why it's the model system.** Three properties make it uniquely suited for testing parasitism-driven genome reduction:

1. **Continuous gradient.** Orobanchaceae contains the full 0–4 parasitism scale (see §3) within a single monophyletic clade. This means species can be compared without cross-family confounds: different parasitism levels share a common ancestor and a similar genomic background.

2. **Independent origins within the family.** Parasitism arose once in Orobanchaceae (the parasitic clade is monophyletic), but within that clade, different genera have independently evolved to different parasitism depths. This gives phylogenetic power: the correlation between parasitism and plastome size is not a single lineage effect.

3. **Well-sampled phylogeny.** The family has a resolved phylogeny (Newick tree bundled in the foundry as `orobanchaceae_tree.nwk`, 56 tips), enabling phylogenetically corrected regression (PGLS, see §4). Without a phylogeny, the shared ancestry of parasitic species would inflate the apparent correlation.

**The species used in the foundry.** The 8×6 retention matrix (see §6) uses these species, ordered by parasitism level:

| Species | para | Status |
|---------|------|--------|
| Lindenbergia | 0.0 | Autotroph (non-parasitic outgroup) |
| Pedicularis | 1.0 | Facultative hemiparasite |
| Castilleja exaltata | 1.5 | Facultative hemiparasite |
| Castilleja gronovii | 2.5 | Obligate hemiparasite |
| Castilleja campestris | 3.0 | Obligate hemiparasite |
| Boulardia | 3.0 | Obligate hemiparasite |
| Epifagus | 3.0 | Obligate holoparasite |
| Conopholis | 4.0 | Obligate holoparasite |

**Note on the scale.** The parasitism scores in the retention matrix are not integers — they are decimal values assigned by the author based on published descriptions of host dependence, haustorium morphology, and degree of photosynthesis retention. The 0–4 scale is a continuous index, not a categorical factor.

---

## 3. Parasitism Level / Depth

**Definition.** A quantitative index (0–4) of a plant species' commitment to parasitic lifestyle, combining haustorium function, host dependence, and photosynthetic capacity. The scale is the independent variable in T1, T2, and the formal model GLM.

**The 0–4 scale, mechanistically:**

| Level | Name | Photosynthesis | Host | Haustorium | Plastome phenotype |
|-------|------|---------------|------|------------|-------------------|
| 0 | Autotroph | Full | None | None | Full 120–160 kb plastome; all genes retained |
| 1 | Facultative hemiparasite | Retained | Optional — can survive without host | Functional haustorium present | Full plastome; ndh complex may be lost |
| 2 | Obligate hemiparasite (weak) | Retained | Required for completion of life cycle | Functional haustorium | Plastome ~120 kb; ndh lost, rpo sometimes lost |
| 3 | Obligate hemiparasite / holoparasite (variable) | Reduced or absent | Obligate; fully dependent | Large, functional | Plastome 70–110 kb; ndh, rpo, psa lost progressively; psb, atp partially retained |
| 4 | Holoparasite (obligate) | Absent | Obligate; no chlorophyll | Massive, extensive | Plastome 40–70 kb; only rpl, rps, trn retained; some species lose entire plastome |

**Mechanistic interpretation.** The parasitism level is a proxy for the intensity of **capacity reallocation** away from photosynthesis. At level 0, the plant allocates resources to its own carbon fixation. At level 4, every carbon molecule comes from the host, so the entire photosynthetic apparatus is dispensable. The VI framework predicts that the *rate* of plastome gene loss is gated by each gene's integration depth (see §7), not just by how long the species has been parasitic.

**Why it's a continuous index, not a categorical factor.** The literature (and the monograph) assigns decimal values (0.0, 1.0, 1.5, 2.5, 3.0, 4.0) because parasitism deepening is not a discrete jump. A species can be "more committed" than another at the same nominal level. The GLM (see §8) treats parasitism level as a continuous regressor, and the T1 PGLS regression estimates β = −23.5 kb change in plastome size per unit increase in parasitism level.

---

## 4. PGLS (Phylogenetic Generalized Least Squares)

**Definition.** A regression method that incorporates phylogenetic covariance among species as a correlation structure in the error term. Standard OLS assumes independent residuals; PGLS models the covariance matrix Σ as a function of the phylogeny, so that closely related species are expected to have correlated residual variation.

**Why phylogenetic correction matters.** Species are not independent data points. Two parasitic species that share a recent common ancestor will have similar plastome sizes partly because they share evolutionary history, *not* because parasitism independently caused both to shrink. Without correction, the effective sample size is inflated: 12 species with 10 close relatives may carry < 2 independent observations. PGLS models the covariance as:

```
V = σ² × C(λ)
```

where C(λ) = λ × (phylogenetic covariance matrix) + (1 − λ) × I. The parameter λ scales the contribution of phylogeny to the covariance structure.

**What λ (PageI's lambda) does.** λ is the phylogenetic signal parameter, estimated by maximum likelihood:
- **λ = 1**: the data follow a Brownian motion model of trait evolution — trait covariance is proportional to shared branch length.
- **λ = 0**: no phylogenetic signal — species are independent, and the model reduces to OLS.
- **0 < λ < 1**: partial phylogenetic signal — the covariance matrix is a weighted blend of the phylogenetic tree and the identity matrix.

The λ parameter is fit simultaneously with the regression coefficients. In the foundry, `caper::pgls` estimates λ by maximizing the likelihood of the model given the data. This is necessary because the strength of phylogenetic signal varies by trait: plastome size may have a different λ than body size.

**How T1 uses it.** The T1 test runs `plastome_size_kb ~ parasitism_score` with `caper::pgls` and λ estimated by ML. The oracle reports β = −23.5 kb/level, R² = 0.652, p = 1.25 × 10⁻⁹. The strong p-value survives the phylogenetic correction — the correlation is not a phylogenetic artifact.

**Why T1 is non-discriminating despite the strong p-value.** Relaxed selection (see §5) predicts the same gradient. The PGLS result *corroborates* VI (the predicted direction holds) but does not *discriminate* it from the competitor. This is honestly tagged in the oracle as `distinguishes_from_competitor: false`.

---

## 5. Relaxed Selection

**Definition.** The hypothesis that when a trait is no longer functional (e.g., photosynthesis in a parasitic plant), the purifying selection that maintained it is relaxed, and neutral mutations accumulate. The result is pseudogenization, then deletion. In the context of plastome reduction, relaxed selection predicts that genes with no function in the parasite are shed at a rate proportional to the mutation rate.

**The competitor prediction.** For the T1/T2 gradient tests, relaxed selection predicts the same empirical pattern as VI: deeper parasitism → smaller plastome. The mechanism differs:
- **VI**: capacity reallocation driven by integration depth — deeply integrated genes are retained because other functions depend on them, regardless of the gene's own function.
- **Relaxed selection**: when a gene's sole function (e.g., photosynthesis) is no longer needed, the gene is free to accumulate mutations under no selection. The rate of loss is mutation-rate-limited, not integration-depth-limited.

**Why T1/T2 cannot distinguish them.** Both mechanisms predict a monotonic gradient: species with less photosynthesis need fewer photosynthetic genes. The VI prediction adds a *specific ordering* of gene loss (deeply integrated → retained longer), but the T1/T2 tests only measure total plastome size, not which genes are lost. A species at level 3 could lose 30 kb via either mechanism — the size data alone cannot tell which.

**Where they can be distinguished.** The discriminating tests are:
- **T6 (gene-loss ordering):** VI predicts loss order by integration depth (ρ ≈ 0.96); relaxed selection predicts loss order by gene function (photosynthesis-specific genes go first, regardless of integration depth). The two predictions sometimes coincide (ndh is both shallow-integrated and photosynthetic) but diverge for multi-functional genes (rpl/rps are integration-deep but not photosynthesis-specific — VI predicts retention, relaxed selection predicts loss if they serve no plastid-translation function).
- **Formal model GLM:** VI predicts dep > 0 (higher dependency → higher retention) and para < 0 (deeper parasitism → lower retention). Relaxed selection predicts dep ≤ 0 (dependency should not matter — functionlessness, not integration, drives loss) and para < 0 (same gradient). The corrected GLM finds dep = +0.84 (p = 0.0008), which supports VI over relaxed selection.
- **T3 (biphasic kinetics):** VI predicts a threshold gate (fast loss of unprotected traits, then stasis). Relaxed selection predicts constant-rate loss (exponential decay of all unselected genes at the same rate). The biphasic shape distinguishes them — but T3 is currently misspecified for the available data (within-lineage test needed, not cross-sectional).

**The citation.** The monograph cites Lahti et al. (2009) "Relaxed selection in the wild" as the canonical statement of the relaxed selection hypothesis. The foundry tags it as the competitor for T1, T2, and the formal model.

---

## 6. Retention Matrix

**Definition.** The 8×6 data matrix recording plastid-gene *retention probability* for 8 Orobanchaceae species (at parasitism levels 0.0–4.0) across 6 gene categories with functional-dependency scores 0–5. It is the empirical substrate of the formal model GLM (empirical_formal_model) and the cross-kingdom transfer test.

**The matrix:**

| Species | para | ndh (0) | rpo (1) | psa (1) | psb (2) | atp (3) | rpl_rps (5) |
|---------|------|---------|---------|---------|---------|---------|-------------|
| Lindenbergia | 0.0 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| Pedicularis | 1.0 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| C. exaltata | 1.5 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.78 |
| C. gronovii | 2.5 | 0.00 | 0.00 | 1.00 | 1.00 | 1.00 | 0.72 |
| C. campestris | 3.0 | 0.00 | 0.00 | 0.80 | 1.00 | 1.00 | 0.50 |
| Boulardia | 3.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.50 | 0.67 |
| Epifagus | 3.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.50 | 0.67 |
| Conopholis | 4.0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.48 |

**Gene categories and their dependency scores:**

| Gene category | dep | Function |
|---------------|-----|----------|
| ndh | 0 | NADH dehydrogenase — plastid respiratory chain |
| rpo | 1 | Plastid-encoded RNA polymerase subunits |
| psa | 1 | Photosystem I core subunits |
| psb | 2 | Photosystem II core subunits |
| atp | 3 | ATP synthase subunits |
| rpl/rps | 5 | Plastid ribosomal proteins (large + small subunit) |

**What "retention" means.** Each cell is a *retention probability* in [0, 1], not a binary present/absent call. Values between 0 and 1 reflect partial retention across multiple gene copies, population-level polymorphism, or pseudogenization. For example, Conopholis (para = 4) has rpl_rps retention = 0.48 — meaning roughly half of the rpl/rps gene content is still detectable; the rest has been pseudogenized or deleted. The 1.0 values in Lindenbergia (para = 0) mean all 6 gene categories are fully intact in the autotroph.

**The pattern VI predicts.** Higher dependency (dep) → higher retention, especially at deeper parasitism. The mean retention by dependency (collapsed across species) is roughly monotonic:

| dep | Mean retention |
|-----|---------------|
| 0 | 0.125 |
| 1 | 0.375 (rpo) / 0.600 (psa) |
| 2 | 0.625 |
| 3 | 0.750 |
| 5 | 0.728 |

The GLM fits this pattern: dep effect = +0.84 (p = 0.0008), para effect = −1.86 (p < 0.0001), pseudo-R² = 0.55.

**Data provenance.** The matrix was originally computed in the author's script `run_formal_model.R` but had a data-flattening bug (`as.vector(t(retention))` — species-major — instead of `as.vector(retention)` — gene-major). The foundry corrected this (Remark R7). The corrected matrix is bundled as `data/orobanchaceae_retention_matrix.tsv`.

---

## 7. Integration Depth

**Definition.** The core concept of the Valence-Ingression (VI) framework. Integration depth of a trait (or gene, morphological structure, or biochemical pathway) is the number of *other functions* that depend on its product. A gene with high integration depth is one whose protein product is required by many downstream processes. It is not a measure of the gene's own essentiality in isolation — it measures the *consequences of its loss* for the rest of the system.

**Mechanistic interpretation.** Consider a gene that encodes a ribosomal protein (rpl). Its product is a component of the ribosome, which is required for translation of *all* plastid-encoded proteins — including those of photosystem I, photosystem II, ATP synthase, the RNA polymerase itself, and the NADH dehydrogenase. If the rpl gene is lost, the entire plastid translation machinery is compromised, taking down every function that depends on newly synthesized plastid proteins. This is high integration depth.

By contrast, ndh encodes a subunit of the NADH dehydrogenase complex, which participates in plastid respiration. Its loss affects only that one complex. No other plastid function depends on a functional NDH complex. This is low integration depth (dep = 0).

**Why deeply integrated genes are retained.** The VI framework posits a **protection threshold θ**: genes with integration depth d ≥ θ are "protected" — their loss would cause cascading failure in the system, so they are retained even when their own function is no longer directly needed. Genes with d < θ are "unprotected" — their loss affects only their own function, so they are shed when that function is no longer selected for.

The ODE formalizing this (the formal model):

```
dC_i/dt = −λ × M(t) × C_i × 𝟙(d_i < θ)
```

where C_i is retention probability, λ is the shedding rate, M(t) is the decaying niche-demand mismatch, and 𝟙(d_i < θ) is the indicator that expression is below the threshold. Protected traits (d_i ≥ θ) have dC_i/dt = 0 — they are never shed. Unprotected traits (d_i < θ) decay exponentially.

**Integration depth vs. relaxed selection.** Integration depth explains *why* some non-functional genes persist while others disappear. Under relaxed selection, *all* non-functional genes should be equally free to accumulate mutations. Under VI, only shallow-integrated genes are free; deeply integrated genes are retained by the functional dependencies of other traits on their product. The 8×6 retention matrix shows exactly this: ndh (dep = 0) is lost at para = 1; rpl_rps (dep = 5) is still at 0.48 even at para = 4.

**The empirical measure.** Integration depth is not directly observed. It is operationalized as a **functional dependency score** (dep score, see §8) — a composite measure of a gene's centrality in the plastid functional network. The monograph assigns dep scores 0–5 to the six Orobanchaceae gene categories based on literature review of plastid gene knockout phenotypes and protein-protein interaction data.

---

## 8. Functional Dependency (dep) Score

**Definition.** A numerical score (0–5 in the Orobanchaceae dataset) quantifying the integration depth of a gene category. The dep score is the independent variable in the formal model GLM and the cross-kingdom ordering test.

**How it is computed.** The dep score is a composite of three sub-measures, derived from the published literature on plastid gene function:

1. **Pleiotropy count** — the number of distinct downstream processes affected by knockout of the gene. A ribosomal protein (rpl) affects all 50+ plastid-encoded proteins; ndh affects only one complex. This is the primary component.

2. **Position in the plastid gene expression hierarchy** — whether the gene product is required for the expression of *other* plastid-encoded genes. rpo (RNA polymerase) is required to transcribe all other plastid genes; atp synthase is not required for any gene expression. Higher position in the hierarchy → higher dep.

3. **Knockout severity** — the phenotypic consequence of complete loss in an otherwise functional plastid. Lethal or severe growth defects indicate higher integration depth (the organism cannot compensate for the loss). Mild phenotypes indicate lower integration depth.

**The scoring system for the Orobanchaceae dataset:**

| dep | Gene(s) | Basis |
|-----|---------|-------|
| 0 | ndh | Knockout viable; no other plastid function depends on NDH activity. Only affects one complex. |
| 1 | rpo, psa | rpo: required to transcribe all plastid genes, but chloroplasts can import nuclear-encoded RNA polymerase. psa: required for photosystem I, but photosystem II is separable. |
| 2 | psb | Required for photosystem II; loss blocks the entire electron transport chain. More severe than psa loss because PSII is the entry point. |
| 3 | atp | Required for ATP synthesis; loss blocks all plastid energy metabolism. Knockout is essentially lethal. |
| 5 | rpl, rps | Required for plastid translation; loss blocks all plastid-encoded protein synthesis. Lethal in any functional plastid. Highest possible integration depth. |

**Why dep = 4 does not appear.** The 0–5 scale has no gene category at dep = 4 in the Orobanchaceae dataset. The author assigned scores based on the available plastid gene categories; the gap at dep = 4 is a property of the data, not the concept. The formal model ODE uses dep scores {0, 1, 2, 3, 5} with a protection threshold θ = 2.5, which means traits at dep ≥ 3 (atp, rpl_rps) are protected.

**What dep measures vs. what it does not.** Dep measures *systemic consequence* of loss — the number of other functions that depend on a gene's product. It is not:
- A measure of essentiality in isolation (a gene can be essential for a single function and still have dep = 0 if nothing else depends on it).
- A measure of expression level (highly expressed genes can have low integration depth if their product is used only by one pathway).
- A measure of sequence conservation (conserved genes may have low integration depth if they are conserved because they perform a single critical function, not because they are deeply integrated).

**The empirical prediction.** The GLM fit to the 8×6 retention matrix estimates:

```
dep coefficient = +0.84 (p = 0.0008)
```

The positive sign means: for each unit increase in dep score, the log-odds of retention increase by 0.84 — deeply integrated genes are retained more. This is the central empirical prediction of the VI framework. The corrected GLM (after the data-flattening bug fix) confirms this prediction.

---

## Cross-References

| Term | Appears in tests | Oracle entry |
|------|-----------------|-------------|
| Plastome | T1, T2, formal model | `t1_orobanchaceae_pgls`, `t2_cross_family` |
| Orobanchaceae | T1, T6, formal model | `t1_orobanchaceae_pgls`, `t6_gene_loss_ordering` |
| Parasitism level | T1, T2, formal model | All three |
| PGLS | T1, T2 | `t1_orobanchaceae_pgls`, `t2_cross_family` |
| Relaxed selection | T1, T2, formal model, T3 | Caveat on all three |
| Retention matrix | Formal model GLM | `empirical_formal_model` |
| Integration depth | T6, formal model, L3 | `t6_gene_loss_ordering`, `empirical_formal_model`, `cross_kingdom_l3` |
| Dep score | T6, formal model, L3 | Same as integration depth |

---

*Written for the vi-foundry review. All values from `baseline/oracle.yml` (v2026-08-16).*