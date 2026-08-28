---
uri: vi-foundry/docs/genealogy-simulacra
title: Genealogy Simulacra — Natural Language Walkthrough of the Mathematical Chain
author: Flow
status: living
version: 1.0.0
updated: 2026-08-19
tags:
  - genealogy
  - simulacra
  - natural-language
  - ising
  - landau
  - cusp
  - relaxation
---

# Genealogy Simulacra

A natural-language walkthrough of the mathematical genealogy chain.
Each simulacrum describes what the math does, why it matters, and where
it sits in the lineage. The prose is the surface; the formulas and tests
are the substrate.

---

## Simulacrum 1 — The Ising Lattice (1925)

Ernst Ising was a student in Hamburg. His supervisor, Wilhelm Lenz,
had proposed a model of ferromagnetism: a grid of atomic spins, each
pointing up or down, interacting with their neighbors. Lenz asked Ising
to solve it.

Ising solved the one-dimensional case in his 1925 thesis and found
no phase transition — the model doesn't magnetize in 1D. He concluded
(hastily, as it turned out) that the model was fundamentally broken.
It wasn't. In 1944, Lars Onsager solved the two-dimensional case and
showed that it DOES have a phase transition: at a critical temperature
Tc ≈ 2.27 (in units where J = 1, k_B = 1), the spins spontaneously align.

The Hamiltonian is simple:

    H = −J·Σ σᵢσⱼ − h·Σ σᵢ

J is the coupling strength. When J > 0, neighbors prefer to align
(ferromagnetic). When J < 0, they prefer to anti-align. The external
field h biases the system toward one orientation. The energy is lowest
when all spins agree and highest when they alternate.

The Metropolis algorithm (1953) samples from this energy landscape.
Pick a random spin. Propose flipping it. If the flip lowers the energy,
accept. If it raises the energy, accept with probability exp(−βΔE).
Run this for long enough and the lattice converges to the Boltzmann
distribution — the equilibrium defined by the Hamiltonian.

Below Tc, the lattice magnetizes: most spins align, and |M| → 1.
Above Tc, the lattice disordered: spins fluctuate, and |M| → 0.
The transition is sharp. This is the phase transition that Landau
will formalize in 1937 and that Thom will classify in 1972.

**What the test verifies:** A 4×4 lattice of all-aligned spins has
energy −32.0 (the ferromagnetic minimum). A 16×16 lattice run through
100 Metropolis sweeps at T = 2.0 (below Tc) should have magnetization
above 0.5.

---

## Simulacrum 2 — The Landau Landscape (1937)

Lev Landau was 29 when he published his mean-field theory of phase
transitions. He didn't start from the Ising model — he started from
symmetry. A phase transition breaks a symmetry: above Tc, the system
is symmetric (no preferred direction); below Tc, the symmetry is broken
(the system chooses a direction).

Landau wrote the free energy as a polynomial in the order parameter M:

    F(M) = a·M² + b·M⁴ + h·M

The coefficient a is temperature-dependent. Above Tc, a > 0: F has one
minimum at M = 0 (symmetric). Below Tc, a < 0: F has two minima at
±√(−a/2b) (symmetry broken). An external field h shifts the minimum
and selects one orientation.

The connection to Ising is exact in the mean-field limit: the Ising
magnetization IS the Landau order parameter M, and the Ising Hamiltonian
produces the Landau free energy when the microscopic spins are averaged
out (mean-field approximation).

But Landau did something Ising didn't: he wrote down the relaxation
equation. With Evgeny Lifshitz, in *Statistical Physics* (1935), he
described what happens when the system is NOT at equilibrium:

    dM/dt = −∂F/∂M

The system relaxes toward the nearest minimum of F. The rate of
relaxation is proportional to how far the system is from equilibrium —
the gradient of the free energy. This is the Landau-Lifshitz relaxation
equation, and it is the direct ancestor of the VI relaxation formula.

When written with TWO relaxation channels — fast (low-integration traits)
and slow (deeply integrated traits) — the Landau-Lifshitz equation
becomes:

    dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)

The bi-exponential. The same formula used in chemistry since the 1880s,
in physics since the 1930s, in pharmacology since the 1950s, and in MRI
since the 1980s. The VI insight: evolution IS a relaxation process.

**What the test verifies:** Below Tc (a = −2.0), the equilibrium
magnetization is near ±1.0 (the two minima). An external field
(h = −5.0) selects the positive minimum. Above Tc (a = 1.0), the
free energy at M = 0 is zero (the symmetric minimum).

---

## Simulacrum 3 — The Cusp (1972)

René Thom was a Fields Medalist who turned to topology and catastrophe
theory. In *Structural Stability and Morphogenesis* (1972), he classified
the elementary catastrophes — the generic ways in which a system's
equilibria can appear, disappear, or merge as parameters change.

The cusp catastrophe is the simplest one that produces bistability. Its
potential is:

    V(x) = x⁴/4 + a·x²/2 + b·x

This is structurally identical to the Landau free energy — same
polynomial, different notation. The difference is in what Thom did
with it. He asked: where does the NUMBER of equilibria change?

The critical points of V satisfy dV/dx = x³ + ax + b = 0. The
discriminant of this cubic is:

    Δ = −(4a³ + 27b²)

When Δ > 0, there are three real roots — two stable equilibria
(the walls of the well) and one unstable (the barrier between them).
When Δ < 0, there is one real root — a single equilibrium. The boundary
Δ = 0 is the cusp: the point where equilibria are created or destroyed.

This is the geometric formalization of what Ising saw statistically
(the phase transition) and Landau saw energetically (the free energy
landscape). Thom saw it topologically: the number of equilibria is
determined by the shape of the potential, and the shape changes as
parameters cross the bifurcation set.

For the VI framework, the cusp describes where the relaxation landscape
becomes bistable — where the system has a choice between two equilibria.
Niche commitment is the parameter change that pushes the system across
the cusp boundary, from one equilibrium to another. The relaxation
formula describes the trajectory; the cusp describes the landscape
the trajectory runs on.

**What the test verifies:** In the bistable region (a = −1.0, b = 0.0),
the discriminant is positive (three real roots). In the monostable
region (a = 1.0, b = 0.0), it's negative (one real root). At the cusp
point (a = 0, b = 0), it's zero — the degenerate transition.

---

## Simulacrum 4 — The Relaxation Formula (2026)

The synthesis. Take the Landau-Lifshitz equation dM/dt = −∂F/∂M. Write
it with two relaxation channels — one for traits that are loosely
integrated (easy to shed, fast) and one for traits that are deeply
embedded (hard to lose, slow). You get:

    dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)

The analytical solution is a bi-exponential:

    ρ(t) = ρ_eq + A₁·exp(−k₁·t) + A₂·exp(−k₂·t)

where ρ_eq = (k₁·ρ₁ + k₂·ρ₂)/(k₁ + k₂) is the combined equilibrium.

The fast phase (k₁, large) corresponds to shedding low-integration
traits — what Davidson and Erwin (2006) call "batteries" in the gene
regulatory network hierarchy: shallow, peripheral gene modules that
are easy to delete without breaking the developmental program. The
slow phase (k₂, small) corresponds to erosion of "plug-ins" and
"kernels" — deeper architectural elements that are woven into the
organism's developmental program and resist loss.

The formula is verified against the 60,000-generation E. coli
Long-Term Evolution Experiment (LTEE): segmented regression finds a
breakpoint at generation ~7,000, and the bi-exponential beats the
mono-exponential with ΔAIC = 190 (decisive, per Akaike, 1974).

The same mathematical form is standard in:
- Chemistry: first-order approach to equilibrium (since the 1880s)
- Physics: Landau-Lifshitz magnetic relaxation (since the 1930s)
- Pharmacokinetics: two-compartment models (since the 1950s)
- MRI: T2 tissue relaxation (since the 1980s)

Every pharmacist and radiologist uses this formula. The VI insight
is that evolution uses it too.

**What the test verifies:** At t = 0, the formula returns ρ_eq + A₁ + A₂.
At t → ∞, it returns ρ_eq. On known bi-exponential data, the fit
recovers the parameters and the bi-exponential wins on AIC (ΔAIC < −4).
On mono-exponential data, the bi-exponential is NOT decisively preferred
(ΔAIC > −10) — the formula doesn't hallucinate structure that isn't there.

---

## Simulacrum 5 — The Banking Upcycle and P7 (1967 / 1986 / 2024)

When the niche shifts from ecological (finite, depletable) to cultural
(generative, expanding), the attractor dynamics reverse sign. The same
formula, but with POSITIVE rate constants — capacity accumulation
instead of capacity loss.

Richard Goodwin (1913–2002) modeled the business cycle as a predator-prey
system in "A Growth Cycle" (1967): wage share and employment oscillate
like foxes and rabbits. Hyman Minsky (1919–1996) overlaid debt
accumulation: stability breeds instability as firms take on more debt
during good times, until the debt burden exceeds what profits can
service. The Minsky moment — when debt exceeds D_max AND profit rate
turns negative — triggers a crisis that writes off debt and resets the
cycle.

The cultural accumulation term is the P7 prediction:

    dN/dt = μ·N^α·(1 − N/N_max) + φ·D·λ

When α > 1, growth is super-exponential: the rate of diversification
INCREASES with system complexity. This is the sign reversal of the
biological relaxation formula, where the rate of capacity loss
DECREASES with time (the slow phase dominates as the fast phase
completes). Cultural systems accelerate; biological systems decelerate.

This is consistent with van Holstein and Foley (2024), who found
positively diversity-dependent speciation in *Homo* — the only lineage
where speciation rate increases with species count. Every other lineage
shows the biological pattern: speciation rate decreases as the niche
fills up.

**What the test verifies:** Super-exponential growth data (dN/dt ∝ N^1.5)
is detected as positive DD (α > 1). Exponential growth is neutral
(α ≈ 1). Saturating growth is negative DD (α < 1). The Goodwin-Minsky
ODE returns five derivatives, instruments grow (dN/dt > 0), and debt
grows when interest exceeds profit (dD/dt > 0).

---

## Simulacrum 6 — The Falsified Branch: Wright-Fisher (1930)

Not every genealogical branch survives. The ρ_sat ≈ 0.35 claim — that
the saturation value of the step function is derivable from Wright-Fisher
drift-selection dynamics — was tested and falsified (ticket T2).

Sewall Wright (1889–1988) and R.A. Fisher (1890–1962) independently
developed this model in 1930. A beneficial allele starts at frequency
p in a population of N diploid individuals. Each generation, the
frequency is sampled from a binomial with selection-adjusted probability.
The allele either fixes (reaches frequency 1.0) or is lost (reaches 0.0).

The function is retained in the package — not because the claim survived,
but because a negative result is still a result. Removing it would
falsify the provenance of the ρ_sat claim. The function carries its
own falsification in its docstring.

**What the test verifies:** With delta = 0 (neutral), fixation rate ≈
p_init = 0.5 (Kimura, 1962). With delta = 0.5 (strong selection),
fixation rate > 0.8. The math is correct; the claim it was testing
was not.
