# P5 Results — C4 Syndrome, Integration-Depth Signature from the C4 Literature

**Date:** 2026-08-24
**Gate:** INFERNO 79 — passed.

## Question

Does the C4 photosynthesis syndrome show the framework integration-depth signature — *function converges (invariant across origins, high integration), mechanism diverges (varying across origins, low integration)* — as coded by the C4 literature itself?

## Design (a priori, non-circular)

- **Hierarchy:** Christin & Osborne (2014, *New Phytologist* 204:1146) Table 1 provides a six-level phenotypic deconstruction: **Niche > Physiology > Function > Character > Characteristic > Component** — an integration-depth hierarchy defined by the C4 field, not by the framework.
- **Shared/varying coding:** from the same source's explicit statements: the *functions* are "present in all C4 plants, independently of their taxonomic origin," while the underlying *characters* "vary among C4 lineages" and were "assembled using one of numerous possible sets" of components, with components "repeatedly co-opted" (most C4 enzyme genes found at significant levels in C3 leaves).
- **Test:** do the invariant (shared) elements sit higher in the integration hierarchy than the varying elements? Niche excluded as environmental context, not organismal trait → 5 levels: Physiology (5, invariant), Function (4, invariant), Character (3), Characteristic (2), Component (1).

## Results

| Test | Value | p | n |
|------|-------|---|----|
| Wilcoxon (invariant > varying) | | 0.1 | 2 inv / 3 var |
| **Spearman ρ (integration depth × invariance)** | **+0.866** | 0.058 | 5 |
| Invariant in upper half of hierarchy | 2 / 2 | (binom 0.25) | 2 |

## Reading

**P5 POSITIVE — structural confirmation, with honest statistical limits.**

The C4 literature independently formalizes an integration-depth hierarchy (Table 1) and independently codes the shared/varying structure exactly as the framework predicts: invariant elements (C4 physiology, its tissue-level functions) sit at the top; varying elements (characters, characteristics, components) sit at the bottom. The alignment is perfect in direction (ρ = +0.866, 2/2 invariant in upper half, 0 in lower).

**The temporal claim validates the "mechanism before function" order — correctly understood.** Christin & Osborne note it is "widely accepted that several C4 characters, especially anatomical ones, were acquired before C4 physiology." A naive reading treats this as contradicting "enzyme-first" framing. But the integration-depth reading makes it a *prediction confirmed*: the varying, low-integration components (vein density, bundle-sheath distance, enzyme isoforms) accumulate first as modular substrate — present and reused in C3 context, "repeatedly co-opted" — and the high-integration whole-organism function (C4 physiology) is the convergent attractor that emerges when the substrate reaches threshold. This is the same *function converges, mechanism diverges* pattern P4 found in echolocation, now in a completely independent system and phenotype class (plant physiology/anatomy vs mammalian gene expression).

**Why the p-values are at floor:** with only 5 biological levels (2 invariant, 3 varying), the minimum attainable one-sided p is 0.1 by construction. P5 is a *structural* confirmation — the direction is perfect and the qualitative claims are explicit in the source — not a high-powered statistical test. It corroborates the cross-kingdom ordering claim; it does not carry it alone.

## Caveats

1. **Shared/varying coding is a reading.** The coding follows Christin & Osborne's own text and Table 1, but a skeptic could contest individual assignments. The hierarchy is theirs; the alignment is the finding.
2. **Level count is small.** 5 biological levels → statistics at floor. Strengthening would require a finer decomposition (e.g., Table 1's component-level entries per lineage) — future work, not this stage.
3. **Qualitative claims, quantitative direction.** P5 shows the literature's framework aligns with the framework; it does not measure an effect size. Its role in the monograph is corroboration of the integration-depth pattern across kingdoms (mammal gene expression, eubacterial genomes, plastid genomes, plant physiology).