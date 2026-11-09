# Review II — Niche Construction Modeling (Active Vertex)

**Monograph under review:** Odling-Smee, F. J., Laland, K. N., & Feldman, M. W. (2003). *Niche Construction: The Neglected Process in Evolution*. Monographs in Population Biology, No. 37. Princeton University Press.

**Status:** Active — specification phase  
**Evaluation standard:** [`docs/review/review-evaluation-standard.md`](../review/review-evaluation-standard.md)  
**Implementation repository:** Primitives live in [`phosphene/order-relations`](https://github.com/phosphene/order-relations) (PR #7, NCT eco-inheritance)

---

## 1. The Claim Under Test

Odling-Smee, Laland, and Feldman position niche construction theory (NCT) as an axiomatic expansion of the Modern Synthesis: organisms do not merely undergo selection; they actively alter the selective environments that feed back on themselves and their descendants. The monograph asserts that organism-driven habitat modification acts as an autonomous evolutionary driver on par with natural selection, elevating **ecological inheritance** to an equal footing with genetic transmission.

## 2. The Monograph's Formal Architecture

The foundational models presented in the monograph are discrete-generation, multi-locus population genetics systems: a two-locus difference equation coupling a construction locus $E$ (which modifies an external resource) to a recipient locus $A$ (which experiences selection modulated by that resource).

Allele frequencies update across discrete generational intervals under fitness coefficients $W_i(R)$ that vary as a function of the external resource $R$:

$$x'_i = \frac{x_i W_i(R)}{\bar{W}}$$

The resource pool accumulates via the weighted construction contributions $c_k$ of active phenotypes and depletes at a linear degradation rate $\mu$:

$$R_{t+1} = (1 - \mu) R_t + \lambda \sum_{k} p_k c_k$$

## 3. Dynamical Deficits in the Monograph's Formulation

The monograph's reliance on these difference equations introduces severe analytical limitations when modeling actual physical animal dynamics:

1. **Timescale Compression.** Discrete-generation recursions treat ecological engineering and genetic fixation as synchronous events. Biological reality exhibits a radical timescale disparity: environmental modification occurs continuously on rapid behavioral/physiological timescales, whereas genetic response demands multiple generations.
2. **Spatial Homogenization.** The environmental variable $R$ is treated as a panmictic, well-mixed scalar. Physical animal construction — burrow complexes, middens, modified river hydrology, soil conditioning — is spatially explicit and governed by diffusion, local advection, and steep spatial gradients.
3. **Demographic Omission.** Total population size $N$ is held static to satisfy standard allele-frequency algebra. Genuine niche construction directly modifies local carrying capacities $K(R)$ and demographic growth rates, creating ecological feedback loops that cannot be resolved in a fixed-density model.

## 4. Review Focus

The review interrogates the core tension between NCT's sweeping conceptual agenda and its conservative modeling implementation: whether the monograph substantiates a revolutionary evolutionary mechanism, or whether its discrete equations merely re-parameterize extended phenotypes (Dawkins 1982) and niche-dependent selection coefficients under a different vocabulary. 

The re-parameterization question is conceptual and is treated on its own line of attack; the benchmark below sharpens the dynamical critique.

## 5. The Discrete–Continuous Correspondence Benchmark

Translating the monograph's foundational models into continuous, stiff-aware differential equations and running a direct numerical benchmark against the discrete two-locus recursion — framed as a **correspondence map**, not an artifact hunt. 

The discrete recursion is the monograph's actual model, not a discretization of a "true" continuous one; the legitimate question is where the two dynamical systems agree (the quasi-continuum limit) and where they genuinely bifurcate apart. Divergences are findings about the monograph's claims, not numerical trivia.

### Predicted Divergence Sites

1. **Stability Structure.** The discrete resource–allele map admits period-doubling and oscillatory dynamics that the continuous system cannot produce. Spurious attractors in the monograph's parameter space would undercut fixed-point-based claims about evolutionary outcomes.
2. **Well-Formedness of $R$.** The linear resource update $(1-\mu)R_t + \lambda\sum_k p_k c_k$ can drive $R$ negative with no stated reflecting boundary — a well-formedness violation at the evaluation standard's first vertex.
3. **The Timescale-Compression Deficit, Quantified.** Generation time $\tau$ as a control parameter: the two systems converge as $\tau \to 0$, and the $\tau$ at which their bifurcation diagrams stop matching is the monograph's timescale critique made numerical instead of rhetorical.

## 6. Implementation Home & Exit Gates

The verified discrete two-locus recursion primitives live in [`phosphene/order-relations`](https://github.com/phosphene/order-relations) (PR #7, NCT eco-inheritance). The benchmark code extends that repository, with review prose following this repository's `docs/review/` pattern. Exit gates, sweep axes, and the ODE specification will be stated in a formal benchmark spec before any code — the foundry's oracle pattern (every reported value checked against a stated prediction) applies to this vertex unchanged.
