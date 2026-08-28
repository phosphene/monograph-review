# Bacterial / Endosymbiont Domain Glossary

**Scope:** Terms used in T3–T5 of the VI monograph (§12.1.4–12.1.6), covering
endosymbiont genome reduction, niche breadth, effective population size, and
pan-genome fluidity. All definitions are mechanical — oriented toward what the
term measures, how the analysis operationalizes it, and what the oracle values
discriminate.

---

## 1. Endosymbiont

**Definition.** A bacterium that lives inside a host cell in a permanent,
obligate symbiosis. The bacterium cannot survive outside the host; the host
depends on the bacterium for metabolic functions the host cannot perform.

**Prototypical genera used in this foundry (T3):**

| Genus | Host | Symbiosis role |
|-------|------|----------------|
| *Buchnera* | Aphids | Essential amino acid synthesis |
| *Wigglesworthia* | Tsetse fly | Vitamin B provisioning |
| *Carsonella* | Psyllids | Essential amino acid synthesis |
| *Blochmannia* | Ants | Nitrogen recycling and nutrient provisioning |

**Why endosymbionts lose genes.** An endosymbiont is a stable, vertically
transmitted resident of host cells. The host environment provides most
metabolites, so genes encoding biosynthetic pathways the host already supplies
become non-functional — the bacterium can stop producing those enzymes and
reallocate the maintenance budget to core functions. Over evolutionary time,
this results in massive genome reduction. *Buchnera aphidicola* has a genome
of ~640 kb (compared to ~4,600 kb for free-living *E. coli*).

**Mechanism in VI terms.** The endosymbiont's ecological niche is the host
cell. Entry into that niche (the symbiosis event) triggers a capacity
reallocation cascade: traits that are not needed in the host environment
(low integration depth) are shed; traits that are essential for the symbiosis
(high integration depth, e.g., genes for amino acid biosynthesis the host
cannot perform) are retained. This is the same threshold-gated mechanism the
formal model simulates — genes below a protection threshold (θ) are shed,
genes above it are retained.

**Data source in foundry.** `data/endosymbiont_genome_data.tsv` — genome
sizes (bp), amino acid pathway retention, host dependency scores, and
symbiosis ages (Mya) for 10 endosymbiont genera, cross-sectional.

---

## 2. Biphasic Kinetics

**Definition.** A two-phase trajectory of genome reduction: a fast initial
phase (Phase 1) followed by a slow, asymptotic phase (Phase 2). The
mathematical signature is a decelerating (logistic/saturation) curve, not a
linear or exponential function.

**What the two phases ARE, mechanically:**

- **Phase 1 (fast — "unprotected genes shed"):** Immediately after the
  symbiosis event, the newly endosymbiotic bacterium still carries all the
  genes its free-living ancestor needed. Genes with low integration depth —
  those encoding biosynthetic pathways the host already supplies, or
  environmental sensing and defense functions irrelevant inside the host —
  are shed rapidly. The rate of loss is proportional to the initial
  niche-demand mismatch (M₀): the bigger the gap between the bacterium's
  ancestral genome and the genome it needs as an endosymbiont, the faster
  Phase 1 proceeds. In the formal model, this is governed by
  dC/dt = -λ·M(t)·C·I(d < θ) where M(t) is large at small t.

- **Phase 2 (slow — "protected genes retained"):** Once the low-hanging fruit
  has been discarded, the remaining genes are those with high integration
  depth — central metabolism, information processing, and the specific
  symbiont functions the host requires. These are above the protection
  threshold (θ), so the shedding rate drops to near zero. The genome enters
  a stable, reduced equilibrium. Further loss is negligible (or occurs at
  the rate of mutational decay of deeply integrated functions, which is
  orders of magnitude slower).

**Why biphasic kinetics distinguishes VI from its competitors (T3 oracle):**

| Model | Predicted shape | Biphasic? | T3 verdict |
|-------|----------------|-----------|------------|
| VI (threshold-gated) | Logistic/saturation — fast then slow | **Yes** | R² = 0.920, BF = 6.7 |
| Constant-rate (Lynch 2007) | Linear/log-linear — steady reduction proportional to Ne | **No** | Rejected by BF |
| Accelerating (Muller's ratchet) | Exponential — faster loss over time | **No** | Rejected by BF |

**Oracle values (T3):**
- R² = 0.920 — the logistic (biphasic) model explains 92% of variance in
  genome size across endosymbiont genera
- k₁/k₂ ratio = 19.0 — the rate of loss in Phase 1 is 19× faster than
  Phase 2. This is a temporal displacement ratio (how completely Phase 1
  finishes before Phase 2 begins), not a biological rate constant.
- Bayes factor = 6.7 — logistic beats exponential with moderate evidence

**Mechanical interpretation of the oracle values.** The R² = 0.920 means the
logistic curve fits the cross-sectional data (10 genera, genome size vs
symbiosis age) almost perfectly. The k₁/k₂ = 19.0 means the initial decline
is nearly complete before the plateau begins — the two phases are cleanly
separated. The BF = 6.7 means the logistic model is ~7× more likely than the
exponential model, given the data. This is moderate evidence (Kass & Raftery
1995: BF 3–20 is positive), but the small n = 10 genera means sensitivity to
individual data points is a legitimate caveat.

**What the formal model adds.** The theoretical model (`threshold_model` in
`R/formal_model.R`) is a deterministic ODE (no RNG, no noise) that produces
the biphasic signature as an emergent property of the threshold gate. For
depths [0, 1, 2, 3, 5] with θ = 2.5, it yields:
- Phase 1 rate ≈ 1.0 (unprotected traits shed completely)
- Phase 2 rate ≈ 3.6 × 10⁻⁶ (protected traits retain at 1.0)
- threshold_biphasicity = 1.0 (the gap between protected and unprotected
  retention fractions)

This is the *theoretical* prediction of the shape. T3 is the *empirical* test
on real endosymbiont data. Both agree.

---

## 3. Muller's Ratchet

**Definition.** The irreversible accumulation of deleterious mutations in
asexual populations. In a finite asexual population, the class of individuals
with the fewest deleterious mutations can be lost by chance (genetic drift).
Once the least-loaded class is lost, it cannot be regenerated (no
recombination to reassemble the least-loaded genotype). The next-best class
becomes the new least-loaded class, and the process repeats — the ratchet
clicks forward one notch at a time, steadily increasing the mutational load.

**Why it predicts accelerating gene loss.** As the ratchet clicks, the
population's mean fitness declines. This reduces effective population size
(Ne), which makes drift stronger, which makes the ratchet click faster —
positive feedback. Under Muller's ratchet, the rate of gene loss should
*accelerate* over time, not decelerate. Early in the endosymbiosis, the
genome is still large, mutational targets are abundant, and the ratchet
clicks gradually. Later, as the genome shrinks and Ne drops, each click
removes a larger fraction of the remaining functional genome.

**Why biphasic kinetics rules it out (mechanical).** The T3 data show a
*decelerating* trajectory — fast then slow, not slow then fast. The logistic
fit (BF = 6.7) beats the exponential fit. If Muller's ratchet were the
dominant force, the opposite would hold: accelerating loss would produce an
exponential (or super-exponential) decay curve, and the decelerating logistic
would fit worse. The data reject the ratchet's predicted shape.

**The ratchet's correct domain.** Muller's ratchet operates in all finite
asexual populations. The VI framework does not deny its existence — it denies
that the ratchet is the *primary* driver of the genome reduction trajectory
in endosymbionts. The biphasic shape shows that the dominant signal is
threshold-gated capacity reallocation (VI), not mutation-accumulation
feedback (Muller's ratchet). The ratchet may contribute noise at the margin
(especially in Phase 2, where the slow loss may include mutational decay of
deeply integrated functions), but it cannot explain the sharp initial decline
followed by a plateau.

---

## 4. Constant-Rate Model (Lynch 2007)

**Definition.** The hypothesis that genome reduction proceeds at a constant
rate proportional to the power of genetic drift (1/Ne). In Lynch's model,
genome size is shaped by the balance between mutation (which adds non-coding
DNA) and drift (which fixes or eliminates it). Larger populations (high Ne)
experience more efficient purifying selection, so they purge non-functional
DNA faster. Smaller populations (low Ne) accumulate non-functional DNA
because drift overwhelms selection. The predicted trajectory is linear or
log-linear — genome size declines at a rate proportional to 1/Ne, with no
biphasic component.

**Why it predicts a different shape from VI.** In Lynch's model, there is no
threshold, no "protected" vs "unprotected" class of genes. Every gene is
subject to the same drift-mutation-selection balance; the rate of loss is
determined by Ne, not by the functional architecture of the genome. The
predicted reduction curve is a single exponential decay (constant
proportional rate) or a linear decline (constant absolute rate) — not a
logistic/saturation curve with two distinct phases.

**Why biphasic kinetics rules it out (mechanical).** The T3 Bayes factor
directly compares the logistic (biphasic/VI) model against the exponential
(constant-rate/Lynch) model. BF = 6.7 means the logistic model is ~7× more
likely. The temporal displacement ratio (k₁/k₂ = 19.0) quantifies the
separation between the two phases — a constant-rate model cannot produce a
19× rate differential because it has only one rate.

**Where Lynch's model contributes.** The constant-rate model is not wrong
about everything — it captures the observation that drift matters for genome
evolution. The VI framework absorbs this: drift is a background process that
contributes to Phase 2 loss (the slow erosion of protected traits). But
Lynch's model cannot explain the order-of-magnitude rate difference between
Phase 1 and Phase 2, because it has no mechanism for a threshold gate. This
is why T4 (niche vs Ne) is the second discriminating test: if Ne were the
sole driver (Lynch), Ne would predict gene loss better than niche breadth.
T4 shows the opposite (niche R² = 0.343 vs Ne R² = 0.198).

---

## 5. Bayes Factor (Logistic vs Exponential)

**Definition.** The ratio of marginal likelihoods of two competing models
given the data. For T3, the two models are:

- **Logistic (numerator):** Genome size ~ floor + (ceil - floor) / (1 + e^{rate × (age - mid)}). This is a 4-parameter saturation curve representing biphasic kinetics (VI prediction).
- **Exponential (denominator):** Genome size ~ a × e^{-b × age}. This is a 2- or 3-parameter decay curve representing constant-rate reduction (Lynch competitor).

**The computation.** The Bayes factor is approximated from the BIC (Bayesian
Information Criterion):

    BF = exp((BIC_competitor - BIC_logistic) / 2)

This is a standard BIC approximation (Kass & Raftery, Raftery 1995), valid
for model comparison when the prior over models is uniform. The BIC
penalizes model complexity (4 parameters for logistic vs 2–3 for
exponential), so the logistic model must fit substantially better to
overcome the BIC penalty.

**What BF = 6.7 means.** The logistic model is approximately 6.7× more
likely than the exponential model, given the data. Per Kass & Raftery
(1995):

| BF | Evidence against H₀ (exponential) |
|----|-----------------------------------|
| 1–3 | Weak / not worth more than a bare mention |
| 3–20 | Positive |
| 20–150 | Strong |
| >150 | Very strong |

BF = 6.7 is positive evidence — the data favor the biphasic model over the
constant-rate model by a factor of ~7. This is not overwhelming (the
logistic model has 4 parameters vs 2 for the exponential, and n = 10 is
small), but it is the discriminating result: the biphasic curve fits
better than the constant-rate curve, consistent with VI's threshold-gated
mechanism and inconsistent with Lynch's drift-only model.

**Why it is the discriminating result.** A constant-rate model can produce
a high R² if the data are roughly monotonic (genome size decreases with
age). The question is not whether the data *can* be fit by a constant-rate
model — that is almost always true. The question is whether the biphasic
model fits *better* than the constant-rate model, after accounting for the
extra parameters. The Bayes factor answers this directly: yes, it fits
better. The logistic model's extra flexibility (two phases instead of one)
is justified by the data.

---

## 6. Niche Breadth

**Definition.** The range of ecological conditions a species can tolerate.
In bacteria, niche breadth is measured as the diversity of habitats a
bacterial species can occupy — from generalists (wide niche breadth, found
in many environments) to specialists (narrow niche breadth, restricted to
one or a few environments).

**How it is measured in the foundry (T4).** The data come from Bobay &
Ochman (2017) Table S1, covering 140 bacterial species. Niche breadth is
operationalized as a categorical lifestyle variable:

- **Generalist:** Found in multiple, diverse environments (e.g., soil, water,
  plant surfaces, animal hosts). High niche breadth.
- **Specialist:** Restricted to one or a few similar environments. Low niche
  breadth.
- **Obligate intracellular:** Restricted to a single host cell environment.
  Extreme specialist — effectively niche breadth = 1.

The analysis regresses pan-genome size (the gene-loss / capacity proxy) on
the lifestyle factor. The R² measures how much of the variance in gene loss
is explained by niche breadth alone.

**Why niche predicts gene loss better than Ne alone (T4 oracle).** The
oracle values are:

- Niche R² = 0.343 — niche breadth explains 34% of variance in gene loss
- Ne R² = 0.198 — effective population size explains 20% of variance

Niche breadth wins by ~73% (0.343 vs 0.198). The absolute values are modest
(neither predictor dominates), but the *direction and relative magnitude* are
the discriminating signal: niche breadth subsumes Ne as a predictor.

**Mechanical interpretation.** A specialist bacterium (e.g., an obligate
intracellular endosymbiont) has a narrow, stable environment. It does not
need genes for environmental stress resistance, alternative metabolic
pathways, or niche switching — these are low-integration-depth traits that
get shed. A generalist bacterium (e.g., free-living *Pseudomonas*) needs
these genes because it encounters diverse conditions. This is a functional
prediction: niche demands determine which genes are retained, and the
prediction is that niche breadth — the organism's position in ecological
space — drives gene loss more than the population-genetic parameter Ne.

**Why this discriminates VI from Lynch.** Lynch's drift-barrier model
predicts that Ne is the primary determinant of genome size: larger Ne → more
efficient purging of non-functional DNA. If Lynch were correct, Ne would
explain more variance than niche breadth. T4 shows the opposite. This does
not mean Ne is irrelevant (R² = 0.198 is non-zero), but it means the
niche-driven signal (R² = 0.343) is stronger — consistent with VI's
prediction that ecological commitment (niche entry) is the primary driver of
capacity reallocation, with drift as a secondary background process.

---

## 7. Effective Population Size (Ne)

**Definition.** The size of an idealized Wright-Fisher population that would
experience the same rate of genetic drift as the observed population. Ne is
almost always smaller than the census population size (N) because of
variation in reproductive success, population bottlenecks, and other
real-world factors. Ne is the quantity that determines the efficiency of
natural selection: in a large Ne population, selection is efficient (even
slightly deleterious mutations are purged); in a small Ne population, drift
dominates (deleterious mutations can fix by chance).

**Why Lynch uses Ne as the null model for genome reduction.** In Lynch's
framework (Lynch 2007, *The Origins of Genome Architecture*), genome size is
determined by the drift-barrier: small Ne populations cannot efficiently
purge non-functional DNA, so their genomes expand; large Ne populations
purge non-functional DNA efficiently, so their genomes are streamlined. The
prediction is monotonic: as Ne decreases, genome size increases (or, for
gene loss, genome reduction is slower in small Ne populations). This is a
one-parameter model — Ne alone predicts everything.

**Why VI says niche matters more than Ne.** The VI framework does not deny
that Ne contributes to genome evolution. It denies that Ne is the *primary*
driver. The mechanistic argument:

1. **Niche breadth determines which genes are needed.** A specialist
   bacterium in a stable environment does not need genes for environmental
   versatility. These genes are shed regardless of Ne — they are
   functionless in the restricted niche, and selection against them is
   strong (or at least, selection for maintaining them is absent).

2. **Ne determines the *noise* around the niche-driven signal.** Drift
   determines how efficiently the shedding happens, and whether
   slightly-deleterious-but-occasionally-useful genes are retained in a
   generalist. But it cannot explain *why* a specialist sheds 90% of its
   genome while a generalist sheds 10% — that is a niche effect.

3. **T4 demonstrates the niche signal is stronger.** Niche R² = 0.343 vs
   Ne R² = 0.198. Both are real, but niche dominates.

**Why this matters for the endosymbiont domain.** Endosymbionts have
extremely small Ne (they are transmitted vertically through small host
populations). Lynch's model would predict that their small Ne *causes*
genome reduction (drift fixes deleterious mutations). The VI framework
predicts that their narrow niche *causes* genome reduction (unnecessary
genes are shed), and the small Ne is a consequence of the endosymbiotic
lifestyle, not the cause of the reduction. The biphasic shape (T3) and the
niche dominance (T4) together support the VI interpretation.

---

## 8. Pan-Genome Fluidity

**Definition.** A measure of how much genetic material is exchanged between
strains of a bacterial species. The pan-genome is the union of all genes
found in all strains of a species. It has two components:

- **Core genome:** Genes present in every strain. These are essential for
  the species' basic biology — housekeeping, central metabolism, information
  processing. High integration depth.
- **Accessory genome:** Genes present in some but not all strains. These are
  flexible — acquired by horizontal gene transfer, lost in some lineages,
  conditionally useful. Low integration depth.

**"Open" vs "closed" pan-genome:**

- **Open pan-genome:** The number of new genes discovered per additional
  sequenced strain does not approach zero. The pan-genome size grows
  continuously as more strains are sequenced. This means the accessory
  genome is large and diverse — new genes are frequently acquired and
  shared. Typical of free-living bacteria that encounter diverse
  environments and other bacteria (HGT sources).

- **Closed pan-genome:** The number of new genes discovered per additional
  sequenced strain drops to near zero. The pan-genome is essentially the
  core genome — almost all strains share the same gene set. This means
  the accessory genome is small or absent. Typical of obligate
  intracellular bacteria (endosymbionts) that are isolated from other
  bacteria and have stable, uniform environments.

**How lifestyle tracks pan-genome openness (T5 oracle).** Dewar et al.
(2024) classify bacterial species by lifestyle (commensal/obligate
intracellular vs free-living) and measure pan-genome fluidity (the rate at
which new genes are encountered per new strain). The oracle value is:

- `lifestyle_subsumes_ne: true` — lifestyle predicts pan-genome openness
  better than Ne does. The lifestyle signal persists after controlling for
  Ne (pMCMC = 0.004).

**Mechanical interpretation.** An obligate intracellular endosymbiont
(closed pan-genome) has no need for HGT — it lives in a stable host cell
environment and has no access to other bacteria. Its genome is a closed
set of essential genes. A free-living bacterium (open pan-genome) encounters
diverse environments, other bacteria, mobile genetic elements, and
bacteriophages — it needs a flexible accessory genome for niche switching
and adaptation. This is a niche-driven prediction: the openness of the
pan-genome tracks the *lifestyle* (niche breadth), not the population
genetic parameter Ne.

**Lifestyle categories in the Dewar data:**

| Lifestyle | Description | Pan-genome type | Example genera |
|-----------|-------------|-----------------|----------------|
| Obligate intracellular | Cannot survive outside host | Closed | *Buchnera*, *Rickettsia*, *Chlamydia* |
| Facultative intracellular | Can survive inside and outside host | Mixed | *Listeria*, *Salmonella* |
| Commensal | Lives on/in host without causing disease | Moderately open | *Lactobacillus*, *Bifidobacterium* |
| Free-living | Independent of host | Open | *Pseudomonas*, *Bacillus*, *E. coli* |

**Why this discriminates VI from Ne-only models.** If Ne were the sole
driver of gene content evolution (Lynch), the open/closed pan-genome
distinction would be explained by Ne differences (free-living bacteria have
larger Ne than endosymbionts). The Dewar analysis shows that the lifestyle
signal remains after controlling for Ne — the niche-driven effect is
independent of the drift-driven effect. This is consistent with VI's
prediction that ecological commitment (lifestyle) determines the set of
genes a lineage needs to maintain, and the need determines the fluidity
of the pan-genome, not the other way around.

---

## Cross-References

| Term | Appears in tests | Oracle entry |
|------|------------------|--------------|
| Endosymbiont | T3, T5 | `t3_endosymbiont_biphasic` |
| Biphasic kinetics | T3, formal model | `t3_endosymbiont_biphasic`, `formal_model` |
| Muller's ratchet | T3 | `t3_endosymbiont_biphasic` (competitor) |
| Constant-rate model | T3, T4 | `t3_endosymbiont_biphasic`, `t4_niche_vs_ne` |
| Bayes factor | T3 | `t3_endosymbiont_biphasic` |
| Niche breadth | T4, T5 | `t4_niche_vs_ne`, `t5_pangenome_fluidity` |
| Ne | T4, T5 | `t4_niche_vs_ne`, `t5_pangenome_fluidity` |
| Pan-genome fluidity | T5 | `t5_pangenome_fluidity` |

---

*Glossary built from the VI Foundry baseline oracle, empirical test code, and
formal model. All oracle values are from `baseline/oracle.yml`. All code
references are to `R/empirical_tests.R` (empirical) and `R/formal_model.R`
(theoretical).*