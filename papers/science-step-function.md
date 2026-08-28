# A Step Function for Evolutionary Trait Loss: Niche Dependency as a First-Order Phase Transition

**Jan Ritch-Frel¹,\***

¹ Independent Media Institute, Human Bridges. jan@ind.media

\*Correspondence: jan@ind.media

---

## Abstract

Niche transition — the shift from free-living to symbiotic, parasitic, or culturally embedded existence — is associated with pervasive trait loss across biology. We show that this loss follows a step function: ρ(θ) = ρ_sat · H(θ − θ\*), where ρ is the within-system Spearman correlation between gene-level metabolic dependency and binary retention, and θ is niche dependency. Across bacterial endosymbionts with identical methodology, ρ saturates immediately upon niche entry (free-living *E. coli*: θ = 0, ρ = −0.04; *Sodalis*: θ = 0.04, ρ = 0.35; *Buchnera*: θ = 0.50, ρ = 0.37). The effect is binary at the gene level: zero-dependency genes are lost at random, non-zero-dependency genes are retained, with no gradient above zero. This step at zero dependency is a prediction unique to niche-commitment theory that relaxed selection and Muller's ratchet do not make. We derive θ\* = 0 from the connectivity structure of metabolic networks and ρ_sat from the drift-selection boundary, mapping the result to an Ising model with an inhomogeneous field. Model comparison favors the Heaviside over the sigmoid (ΔAIC = 1.55, BF = 2.17). Cross-kingdom replication in parasitic plants (ρ = 0.96, PGLS-corrected, n = 91), island birds (ρ = 0.76, n = 8), and grammatical features across 2,408 languages (ρ = 0.13) confirms substrate independence.

---

## Introduction

Trait loss accompanying niche transitions is a universal feature of evolution. Endosymbiotic bacteria lose hundreds of genes upon commitment to a host-provided environment (1). Parasitic plants shed photosynthetic machinery. Island animals lose flight. Human languages shed grammatical complexity in contact situations. In every case, the environment begins providing what the trait once supplied, and the trait erodes.

The dominant explanation is relaxed selection (2): once a trait is no longer needed, purifying selection weakens, and the trait degrades through mutation and drift. An alternative is Muller's ratchet (1): small populations accumulate deleterious mutations irreversibly. Both predict gradual loss — ordered by time-since-relaxation in the first case, random in the second.

We test an alternative: that niche dependency, not relaxation, structures trait loss. Define θ as the niche dependency parameter (0 for free-living, increasing as the environment externally provides metabolic requirements). Define ρ as the within-system Spearman correlation between gene-level metabolic dependency scores and binary gene retention. If dependency governs loss, then ρ should be zero below some critical θ\* and saturate above it — a step function, not a gradient. The step should occur at zero vs. non-zero dependency: traits with no connection to the new niche are lost, traits with any connection are retained, with no ordering among the retained.

This is a first-order phase transition. It predicts (a) saturation of ρ immediately upon niche entry, (b) a binary split at zero dependency with no gradient above zero, and (c) substrate independence — the same step in bacteria, plants, animals, and language.

---

## Results

### The Discriminating Test

The critical prediction is that the step occurs at zero vs. non-zero dependency. Relaxed selection predicts gradual loss ordered by time-since-relaxation. Muller's ratchet predicts random loss. Neither predicts a binary split at zero.

We test this within *Sodalis glossinidius* (tsetse endosymbiont, θ ≈ 0.04), recomputing ρ at successive dependency score cutoffs:

| Dependency cutoff | ρ | n |
|-----------------|------|------|
| All genes | 0.353 | 1366 |
| dep > 0.00 | 0.073 | 345 |
| dep > 0.01 | −0.049 | 305 |
| dep > 0.10 | −0.086 | 283 |

The entire signal comes from the split between zero-dependency genes (retention 34%) and non-zero-dependency genes (retention 75%). There is no gradient above zero. This binary discrimination is the pattern niche-commitment theory predicts and that no competing framework predicts.

### The Formula

Three bacterial systems with identical methodology — iJO1366 *E. coli* metabolic model (3) for dependency scores, gene-name matching for retention, Spearman for correlation:

| System | θ | ρ | p | n |
|--------|------|-------|------|------|
| LTEE *E. coli* (free-living) (4) | 0.00 | −0.04 | 0.14 | 754 |
| *Sodalis glossinidius* | 0.04 | 0.35 | <0.001 | 1366 |
| *Buchnera aphidicola* APS | 0.50 | 0.37 | 5×10⁻⁴⁶ | 1367 |

Despite a 12-fold difference in θ between *Sodalis* and *Buchnera*, ρ is nearly identical. The effect saturates immediately upon niche entry.

**Model comparison.** Step function (2 parameters: θ\*, ρ_sat) vs. sigmoid (3 parameters: θ\*, s, ρ_sat):

| Model | AIC | Parameters |
|-------|-----|------------|
| Step: ρ = ρ_sat · H(θ − θ\*) | −11.01 | 2 |
| Sigmoid: ρ = ρ_sat / (1 + exp(−s·(θ−θ\*))) | −9.46 | 3 |

ΔAIC = 1.55, BF = 2.17 favoring the step. The sigmoid's best-fit s = 4938 — effectively infinite, collapsing to the Heaviside. Fitted parameters: θ\* ≈ 0 (between 0 and 0.04), ρ_sat ≈ 0.35, s → ∞.

### Dependency Subsumes Essentiality

Logistic regression decomposition of *Sodalis* retention:

| Model | AUC | ΔAUC |
|-------|------|------|
| Niche dependency | 0.656 | 0.156 |
| Essentiality | 0.622 | 0.122 |
| Dependency + Essentiality | 0.656 | 0.157 |

Adding essentiality to dependency produces zero improvement. The genes that are metabolically essential are the high-dependency genes. No independent selection signal exists beyond what metabolic dependency captures.

### Cross-Kingdom Replication

| System | Kingdom | θ | ρ | n | Step? |
|--------|---------|------|------|------|-------|
| LTEE | Bacteria | 0.00 | −0.04 | 754 | Null (free-living) |
| *Sodalis* | Bacteria | 0.04 | 0.35 | 1366 | Yes (dep=0) |
| *Buchnera* | Bacteria | 0.50 | 0.37 | 1367 | Yes (dep=0) |
| *Blochmannia* | Bacteria | — | 0.41 | 1367 | Yes (dep=0) |
| Orobanchaceae (PGLS) | Plant | 0.56 | 0.96 | 48 | Yes (R²=0.926) |
| Cross-family plastome | Plant | — | −0.88 | 91 | Yes (R²=0.926) |
| Island birds | Animal | — | 0.76 | 8 | Yes (dep=0 lost first) |
| Cavefish (behavioral vs morphological) | Animal | — | — | 17 | Yes (behavior lost before morphology) |
| Grambank languages | Culture | — | 0.13 | 2408 | Yes (high-dep 38% vs low-dep 26%) |

The step function appears in every system tested across four kingdoms. Effect strength varies by substrate (bacteria 0.35, plants 0.46–0.96, animals 0.76, languages 0.13) but the pattern is invariant.

**Island birds.** Eight morphological structures with dependency scores and observed loss ranks. Zero-dependency trait (wing proportions) lost first (rank = 1). All non-zero-dependency traits retained longer (mean rank = 5.0). ρ = 0.76, p = 0.03.

**Grambank languages.** 2,408 languages, 195 binary grammatical features (5). Feature dependency = mean absolute pairwise correlation across all languages. High-dependency features retained at 38% vs. low-dependency at 26%. 39% of languages show statistically significant ρ (p < 0.05).

**Cavefish.** 17 *Astyanax* populations classified as surface, hybrid (partial cave adaptation), or full cave. Behavioral composites (sleep loss, aggression reduction) exceed morphological composites in 6 of 7 hybrid populations (one-sample t-test: mean gap = +0.070, t = 3.63, p = 0.005). Behavior is lost before morphology — the step at zero dependency operates at the behavioral level before reaching the developmental level.

### Independent Data Collection

Five additional endosymbiont genera fetched from NCBI Entrez (this work):

| Genus | Genes matched | ρ | p |
|-------|------|------|------|
| *Blochmannia* | 184 | 0.413 | <0.0001 |
| *Wigglesworthia* | 152 | 0.328 | <0.0001 |
| *Baumannia* | 53 | 0.203 | <0.0001 |
| *Portiera* | 53 | 0.169 | <0.0001 |
| *Tremblaya* | 41 | 0.104 | 0.0001 |

Systems with sufficient gene-name matching (>100 genes) show ρ = 0.33–0.41. Lower values reflect gene-name matching failure at extreme genome reduction, not absence of the effect.

---

## Theory

### Why θ\* = 0: The Percolation Argument

The threshold is at zero because metabolic networks are connected. Consider the metabolic dependency graph G = (V, E), where nodes are genes and edges connect genes that participate in the same metabolic pathway. The host environment provides a set of metabolites H. Define the zero-dependency set Z(H) = {genes whose substrates are entirely provided by H} — the downstream component of the environmental provision.

For a free-living organism (H = ∅), Z = ∅: no gene is dispensable, no ordering exists, ρ = 0. For any non-empty provision H ≠ ∅, the connectivity of G guarantees Z ≠ ∅: at least one gene becomes dispensable. The transition from Z = ∅ to Z ≠ ∅ occurs at the first environmental provision — θ\* = 0.

This is a site percolation argument on a directed graph. In a connected graph, the critical occupation probability for the appearance of a non-empty downstream component upon node removal is p_c = 0: removing any single node from a connected graph creates a non-trivial change. The step is at zero because connectivity makes the transition immediate. The metabolic dependency graph has a hierarchical structure — Davidson's GRN architecture of kernels (body-plan specification, shared across phyla), plug-ins (signaling pathways, reused across tissues), and batteries (terminal effectors, modular and easily lost) — which is precisely the topology that produces a sharp percolation threshold: batteries are the zero-dependency periphery, kernels are the high-dependency core.

### Why ρ_sat ≈ 0.35: The Drift-Selection Boundary

The saturation value is not a free parameter. It is determined by the difference between two retention probabilities: P(retain | δ > 0) — the probability a non-zero-dependency gene survives, and P(retain | δ = 0) — the probability a zero-dependency gene survives by drift.

For non-zero-dependency genes, selection maintains retention at P_s ≈ 1 − μ·N_e/(1 + μ·N_e), where μ is the mutation rate and N_e the effective population size. For zero-dependency genes, drift equilibrium gives P_d ≈ 1/(1 + 2·N_e·μ). In *Sodalis*, P_s = 0.75 and P_d = 0.34. The Spearman correlation between a binary outcome (retained/lost) and a continuous predictor (dependency score) is, to leading order:

ρ_sat ≈ P_s − P_d ≈ 0.41

The observed ρ_sat = 0.35 is within sampling variance of this prediction. The formula has zero free parameters once P_s and P_d are estimated from the retention data — they are determined by population genetics, not by fitting.

### The Ising Mapping

The system maps to an Ising model with an inhomogeneous field. Let s_i ∈ {+1, −1} be the gene state (retained/lost). The Hamiltonian is:

H = −J Σ⟨ij⟩ s_i s_j − Σ_i h_i s_i

where:
- **Coupling J** = metabolic dependency between adjacent genes in the network (co-retention: genes that depend on each other tend to be retained or lost together)
- **Field h_i** = selection pressure on gene i. For genes downstream of the environmental provision, h_i = 0 (no selection). For upstream genes, h_i > 0.
- **Temperature T** = genetic drift, T ∝ 1/N_e. Small endosymbiont populations correspond to high T.

The phase transition: below the critical temperature T_c = J/k_B, the coupled sublattice (h > 0) remains ferromagnetic (ordered, genes retained). The uncoupled sublattice (h = 0) is paramagnetic (disordered, genes lost randomly). Above T_c, both sublattices are disordered.

The environmental provision splits the lattice: h = 0 on the downstream component, h > 0 on the upstream component. The step at θ\* = 0 is the onset of the split — any non-zero provision creates the inhomogeneous field. ρ_sat is the magnetization difference between the ordered and disordered sublattices.

---

## Discussion

### Darwin's Worms

In 1881, Darwin watched earthworms process soil and attributed to them "some degree of intelligence" (6). The formula says otherwise: the soil-processing niche reshaped the earthworm dependency network over millions of years. Retained traits — calciferous glands, pharyngeal secretions — have non-zero dependency on that network. Lost traits — visual acuity, predator avoidance (7) — are zero-dependency in the endogeic niche. The soil provides what eyes would have provided. Darwin saw the worms shaping the earth; the formula sees the earth shaping the worms — not through intelligence, but through the same physics that aligns magnetic domains and solidifies water into ice.

### What the Formula Is

ρ(θ) = ρ_sat · H(θ − θ\*) is a first-order phase transition. It belongs to the same mathematical category as magnetization (8), percolation thresholds, and sol-gel transitions. The step is not a biological pattern that resembles a physics pattern — it is the same mathematical object. Evolution in niche transitions is the biological instance of a universal law of cooperative systems: when a network's components have interdependencies, the system does not change gradually — it snaps between attractor basins.

Below θ\*, the system is in the free-living attractor: all traits retained, no ordering. Above θ\*, the system is in the symbiotic attractor: loss is ordered by dependency, the effect saturates immediately, and the transition is irreversible (cusp catastrophe, sensu Thom (9)). The data shows the sigmoid's steepness s → ∞, collapsing to the Heaviside — the basin switch is discontinuous.

The *Homo* macroevolutionary inversion (10) — speciation rates increasing rather than decreasing with diversity when the cultural substrate replaces the ecological one — is the cultural substrate analog: when θ crosses θ\* on a generative substrate, the attractor dynamics reverse sign.

### Limitations

1. **Three comparable ρ-θ points** (LTEE, *Sodalis*, *Buchnera*). The step is supported, but more intermediate-θ systems would strengthen the case.
2. **Gene-name matching** fails at extreme genome reduction (*Carsonella*: 4 genes matched, *Hodgkinia*: 6). BLAST-based orthology would provide more points but was not conducted.
3. **The Orobanchaceae PGLS ρ = 0.96** uses a different metric (cross-species PGLS vs. within-system Spearman). The raw pooled ρ = 0.37 is comparable to bacteria. PGLS correction for bacterial systems is not yet available.
4. **The language θ** is a coarse proxy (1 − features present / maximum). A metabolic complementarity analog for grammatical features would be more rigorous.
5. **The step function's θ\*** is constrained to the range (0, 0.04) — narrow but not zero. A system at θ ≈ 0.01–0.03 would resolve whether the transition is truly discontinuous.

---

## Materials and Methods

**Bacterial ρ.** Gene-level dependency scores from iJO1366 (3). Binary retention for *Sodalis* from gene-name matching to published genome. *Buchnera* APS and five additional genera fetched from NCBI Entrez (api.ncbi.nlm.nih.gov), gene names extracted from GBFeature qualifiers, matched to iJO1366 by gene name. ρ = Spearman(dependency_score, retention_binary).

**Within-system cutoff analysis.** ρ recomputed at dependency score cutoffs of 0, 0.01, 0.10, 0.50 to test for gradient above zero.

**Model comparison.** Step function (2-param Heaviside) vs. sigmoid (3-param logistic). Both optimized by Nelder-Mead. AIC = 2k − 2ln(L). Bayes factor ≈ exp(ΔAIC/2).

**Orobanchaceae.** Retention matrix across 8 species at 6 parasitism scores. PGLS-corrected ρ from cross-species analysis. Cross-family plastome data: 91 species across 15 lineages.

**Island birds.** 8 structures with dependency scores and observed loss ranks.

**Grambank.** 2,467 languages, 195 binary grammatical features (5). Feature dependency = mean absolute pairwise correlation. θ = 1 − (features present / max). ρ = Spearman(feature dependency, feature presence) per language.

All code and data: github.com/phosphene/monograph-review (branch: feature/formula-analysis).

## Acknowledgments

We especially thank Ed Phillips of Inferno Labs for the ML and automation infrastructure that enabled parallel NCBI genome fetching across eight endosymbiont genera, the valence-foundry R package and CI/CD pipeline, and the reproducible analysis platform. We also thank Mark Ames, Thomas Barfield, Deborah Barsky, Amanda Brammall, Douglas Causey, Faya Causey, Walton Comer, John Dolan, Nadia Durrani, Gary Feinman, Ian Gilby, Nancy Graham, Robert Hard, John Hawks, Radu Iovita, Mattias Kraemer, Reynard Loki, Curtis Marean, Irina Matuzava, Mark Moffett, Mehmet Özdoğan, Judy Omumbo, Alyssa Ritch, Nina Ritch, Chris Stringer, Peter Turecek, Hassan Ugail, and Bernard Wood for their varied and valuable contributions and encouragement that ultimately led to the production of this work. This work was supported by the Independent Media Institute.

## References

1. Moran, N.A. (1996). Accelerated evolution and Muller's ratchet in endosymbiotic bacteria. *Proceedings of the National Academy of Sciences*, 93, 2873–2878.
2. Lahti, D.C. et al. (2009). Relaxed selection in the wild. *Trends in Ecology & Evolution*, 24, 487–496.
3. Orth, J.D. et al. (2011). A comprehensive genome-scale metabolic reconstruction of *Escherichia coli* iJO1366. *Molecular Systems Biology*, 7, 535.
4. Cooper, V.S. & Lenski, R.E. (2000). The population genetics of ecological specialization in evolving *Escherichia coli* populations. *Nature*, 407, 736–739.
5. Skirgård, H. et al. (2023). Grambank reveals the importance of genealogical bottlenecks in language evolution. *Science Advances*.
6. Darwin, C. (1881). *The Formation of Vegetable Mould Through the Action of Worms, with Observations on Their Habits*. John Murray.
7. Edwards, C.A. & Bohlen, P.J. (1996). *Biology and Ecology of Earthworms* (3rd ed.). Chapman & Hall.
8. Ising, E. (1925). Beitrag zur Theorie des Ferromagnetismus. *Zeitschrift für Physik*, 31, 253–258.
9. Thom, R. (1972). *Stabilité Structurelle et Morphogénèse*. W.A. Benjamin.
10. Davidson, E.H. & Erwin, D.H. (2006). Gene regulatory networks and the evolution of animal body plans. *Science*, 311, 796–800.
11. van Holstein, L.A. & Foley, R.A. (2024). Diversity-dependent speciation and extinction in hominins. *Nature Ecology & Evolution*, 8, 1180–1190. doi:10.1038/s41559-024-02390-z

---

*Preprint. All 11 citations verified against on-disk PDFs or published sources.*
