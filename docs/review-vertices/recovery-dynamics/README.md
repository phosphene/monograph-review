# Review I — Recovery Dynamics (Founding Vertex)

**Monograph under review:** Ritch-Frel, J. (2026). *Animal Recovery Dynamics and Multiscale Relaxation*.  
**Status:** Review complete; computational artifact live (`valence.foundry`)  
**Evaluation standard:** [`docs/review/review-evaluation-standard.md`](../review/review-evaluation-standard.md)  
**Foundry package:** `valence.foundry` (R package in this repository root)

---

## 1. The Claim Under Test

The monograph under review proposes the following statement about animal life as supported by empirical test:

> When an animal is displaced from its homeorhetic trajectory — by exercise, injury, infection, or anesthesia — its return is a multiscale relaxation: a recovery composed of multiple superimposed decay rates. High-resolution temporal tracking resolves this recovery into two distinct phases: a rapid, tissue-autonomous phase present even in aneural animals, and a prolonged phase that follows. The ratio of the two recovery timescales (τ₁/τ₂) varies systematically with integration structure, remaining invariant within an evolutionary grade and shifting across major transitions in organization. What the two phases are, physically — tissue-autonomous versus systemically integrated processes — is a labeled, sourced hypothesis under test, outside the empirical spine.

An empirical attempt at some measurement:
- Multiscale (non-mono-exponential) recovery;
- Two distinct phases appear at temporal resolutions;
- A rapid phase present in aneural animals (tissue-autonomous, in the cell-autonomous lineage of developmental genetics);
- A negative control (sleep slow-wave activity recovers as a single exponential) showing the claim is specific, not vacuous.

Classical scaffolding carries that core: homeorhetic trajectory (Waddington 1957); recovery timescales τ₁, τ₂ as the within-organism kinetic structure, with fast and slow as tempo and mode in Simpson's sense (1944) reserved for grade-level divergence and anchored by the fast-slow continuum of life history (Stearns 1983; Wikelski et al. 2003; Réale et al. 2010); integration structure (Olson & Miller 1958; Cheverud 1996); evolutionary grade (Huxley 1958; Simpson 1944).

## 2. Systems of Study

The empirical work spans a deliberately wide sample of animal life, from the invertebrate to the vertebrate, from the sessile to the highly mobile:

- **Earthworms** (*Lumbricus terrestris*) — Darwin's own study organism; a model of inference from observable behaviors.
- **Nematodes, fruit flies, and other laboratory invertebrates** — short-generation systems in which recovery dynamics can be observed across the whole life course.
- **Zebrafish** (*Danio rerio*) — a vertebrate model with a resolved developmental sequence and a nervous system that develops late relative to the earliest recovery dynamics.
- **Domesticated mammals** — dogs, horses, and the laboratory mouse (*Mus musculus*); lineage records provide the comparative frame for integration structure.
- **Sleep states in humans and songbirds (e.g., the zebra finch)** — the negative control: slow-wave activity recovers as a single tempo.

## 3. Tradition & Lineage

This review stands in a tradition of observational naturalism. Charles Darwin is an exemplar: his final book, *The Formation of Vegetable Mould, Through the Action of Worms* (1881), models patient inference from observable behavior — what the animals do, from observable inputs and outputs. 

J.O. Wisdom opens his study of scientific inference, *Foundations of Inference in Natural Science* (1952), with Darwin for exactly this reason: the earthworm study is a model of drawing no more from an observation than it licenses. Our genealogy descends from that tradition — observation first, austerity of inference, all claims tested against data. The tradition governs both vertices.

## 4. Mathematical Methods

The statistical procedures are standard in evolutionary and physiological literature, validated against known truth before use:

- **Model selection among recovery shapes:** Single-exponential versus two-tempo (bi-exponential) fits, compared by information criteria (ΔAICc) and Bayes factors (BF > 6 moderate evidence, BF > 10 strong). Core contrast: mono rejected 28/28 at beat-level resolution.
- **PGLS (Phylogenetic Generalized Least Squares):** Regression correcting for non-independence of species due to shared evolutionary history ($\lambda$ parameter measures phylogenetic signal in residuals).
- **Exact permutation tests:** Non-parametric significance enumeration (all orderings; for six items, all 720), preferred over asymptotic approximations for small samples.
- **Biphasic kinetics:** Two distinct rates (fast phase followed by slow phase); mathematical signature a logistic (saturation) curve distinguishable from linear or exponential alternatives.
- **Cross-kingdom parameter transfer:** Parameters estimated in one kingdom applied to another without refitting; controls for kingdom-specific confounds.

### Notation and Conventions

| Symbol | Meaning |
|--------|---------|
| τ₁, τ₂ | The two recovery timescales — fast and slow decay constants of the two-phase fit |
| ΔAICc | Difference in corrected Akaike information criterion between competing model fits |
| BF | Bayes factor — evidence ratio between compared models |
| β | Regression coefficient (PGLS slope), in reported units (kb per level for T1) |
| R² | Coefficient of determination — share of variance explained |
| ρ | Spearman's rank correlation coefficient |
| λ | Phylogenetic signal — strength of shared-evolutionary-history correlation in residuals |
| p | Attained significance level of stated test |

## 5. Bundled Data Sets

All data are bundled in `data/` with provenance documented in YAML (`data/README.md`):

- **NCBI GenBank:** Plastome sizes and phylogenies (parasitic plant gradient).
- **Bobay & Ochman (2017) Table S1:** Niche breadth data (bacterial endosymbionts).
- **Dewar et al. (2024) supplementary:** Pan-genome data.
- **Good et al. (2017):** LTEE metagenomic data (12 populations of *E. coli* tracked since 1988).
- **MIT-BIH ST Change and Sleep-EDF archives (PhysioNet):** Beat-level cardiac recovery data (mono rejected 28/28) and slow-wave sleep negative control.

## 6. Implementation Architecture (`valence.foundry`)

- **Three-pillar separation:** Every analysis decomposes into (A) pure data preparation, (B) seed-locked deterministic model fitting, and (C) pure result extraction. Thin `main()` wrappers for I/O.
- **Structured results:** Return `values` + `metadata` (seed, sample size, convergence status, elapsed time) allowing complete computational traceability.
- **Manifest conformance:** Pipeline declared in YAML manifest (`pipeline.yml`); runtime tests verify conformance.
- **Stochastic Test-Driven Development (STDD):** Exact assertions for deterministic math; controlled seeds + parameter recovery, null control, and distributional verification (Kolmogorov–Smirnov) for stochastic steps.
- **Simulacrum:** Controlled synthetic environments with known ground truth verified prior to empirical evaluation.
- **Baseline oracle:** [`baseline/oracle.yml`](../../baseline/oracle.yml) records every reported value with numerical tolerance.

## 7. Key Results Oracle

| Test | What It Measures | Key Value | Distinguishes Thesis? |
|------|-----------------|-----------|------------------------|
| **T1: Orobanchaceae PGLS** | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts same gradient |
| **T3: Endosymbiont biphasic** | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| **T6: Gene-loss ordering** | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| **L3: Cross-kingdom transfer** | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — independence of kingdoms predicts no transfer |

## 8. Calibration Program

Ticketed work program (11 tickets, C1–C8 + E1–E3) in hypothetico-axiomatic form:
- **E1 (Coverage gate):** Unit coverage lifted to 93.25% (PR #22). Fixed 2 robustness bugs.
- **E2 (Property invariants):** Re-enabled `test-invariants-empirical.R` across all generators.
- **Roadmap:** C6 (Monte Carlo error) → C1 → C2 → C5 → C4 → C7 → C3 → C8 → E3. Full ticket ledger in [`docs/review/self-calibration-tickets.md`](../review/self-calibration-tickets.md).
