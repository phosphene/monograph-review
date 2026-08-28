# Toy Realms — Speculative Explorers

## What These Are

The toy realms are interactive **simulations** — computational models that generate synthetic data from the valence equations and visualize the trajectory under different parameter settings. They are **not tests** of the hypothesis. They are tools for building intuition about how the framework's mechanisms operate. Each realm generates data from known equations, lets the user adjust parameters, and shows what the trajectory looks like under different conditions.

A **simulation** differs from a **simulacrum** (see the Simulacra page). A simulacrum tests whether the statistical pipeline can recover known parameters from synthetic data — it verifies the *methods*. A simulation explores what the model *does* under different parameter combinations — it builds understanding of the *dynamics*. Both use synthetic data, but for different purposes: one tests the tools, the other explores the theory.

## How to Read Each Realm

### Realm 1 — Genome Reduction (The Threshold Gate)

**What it explores:** How genome retention collapses as parasitism crosses the **protection threshold** (θ). Below the threshold, retention is approximately 1.0 (the trait is protected by its integration with other systems). Above the threshold, retention collapses to approximately 0.0 (the trait is no longer protected and enters relaxed selection). The transition is sharp, not gradual — valence predicts a threshold, not a smooth decline.

**What to look for:** The **threshold_biphasicity** metric (a binary indicator: 1.0 if the threshold cleanly separates protected from unprotected traits, 0.0 otherwise) approaches 1.0 in the interesting regime. At low θ, almost everything is unprotected and the trajectory looks monophasic (everything is shed). At high θ, almost everything is protected and little is shed. The interesting regime is intermediate θ, where the biphasic signal is strongest — some traits are protected and some are not, producing the rapid-then-slow trajectory the framework predicts.

### Realm 2 — Irreversibility (The Cusp Catastrophe)

**What it explores:** How **hysteresis** (path dependence) emerges at the cusp catastrophe's bifurcation point. **Hysteresis** means the system's state depends on its history, not just its current parameters: increasing commitment produces one trajectory, but decreasing commitment does not retrace that trajectory — the system has crossed a threshold from which it cannot return. The **hysteresis loop area** (the geometric area enclosed by the forward and reverse paths) quantifies how much irreversibility the system exhibits. Zero area means fully reversible; large area means deeply irreversible.

**What to look for:** The hysteresis loop — the forward and reverse paths diverge at the **bifurcation** (the parameter value where the system jumps from one stable state to another). The width of the hysteresis loop is the "commitment depth" that must be traversed before the system can return to the ancestral state. Below the threshold, the system is reversible; above it, it is not. This is the formal analog of the **specialization trap** described in §10.7: once a lineage crosses the commitment threshold, reversing the environmental parameter does not restore the ancestral state because the developmental scaffolding has been reallocated.

### Realm 3 — The *Homo* Inversion (Diversity-Dependence Sign Flip)

**What it explores:** The macroevolutionary inversion: positively **diversity-dependent speciation** in *Homo* vs negative diversity-dependence in other vertebrate clades. **Diversity-dependent speciation** means that the speciation rate depends on how many species already exist. In standard ecological radiations, more species means more competition for finite resources, so speciation rate *decreases* (negative diversity-dependence). Valence predicts that after a lineage shifts its primary **ingression substrate** (the resource base it exploits) from ecological to cultural, the dynamics reverse: cultural substrates expand under exploitation rather than depleting, so more species (or more cultural variants) produce more niches, and speciation rate *increases* (positive diversity-dependence).

**What to look for:** The **sign flip** — the slope of speciation rate vs species count changes from positive (autocatalytic, the *Homo* pattern) to negative (logistic, the standard pattern) when the substrate parameter is toggled. Both trajectories grow, but the per-capita-rate-vs-N slope has opposite signs. The discriminator is the slope sign, not whether growth occurs.

### Realm 4 — Cross-Kingdom Transfer (Model vs Sign-Only)

**What it explores:** When does the full model (using both dependency and commitment parameters) outperform **sign-only transfer** (using only the dependency ordering)? At low plant noise (clean data), the model transfer wins — the full parameter set predicts the bird ordering better. As noise increases, the two approaches converge — the magnitude information degrades and only the ordering survives. The **gap** between the two curves is the information lost to ranking — the magnitude the sign-only transfer discards.

**What to look for:** The gap between the green curve (model transfer) and the red curve (sign-only transfer). This gap is the information lost when we reduce the cross-kingdom claim from "parameters transfer" to "ordering transfers." The real data (§12.3.5) show ρ = 0.755 — the sign-only result, which corresponds to the right side of the plot where the curves converge. The model-transfer result would be stronger if we had enough data points to estimate both slopes precisely.
