---
uri: foundry/standards/llm-war-stories
title: LLM War Stories — Capabilities, Constraints, and Craft
author: Marsyas + Ed Phil
status: living
version: 1.0.0
updated: 2026-08-18
tags:
  - llm
  - war-stories
  - capabilities
  - constraints
  - craft
  - inferno-labs
---

# LLM War Stories — Capabilities, Constraints, and Craft

> Encapsulated lessons from the evolution paper pursuit and related research
> work. These are situated, earned observations — not principles or best
> practices. Each entry describes what actually happened, what it revealed
> about the tool's nature, and what it means for how to deploy it.

---

## Genre Statement

War stories are specific, situated, earned. They describe the whole tool:
where it cuts clean, where it binds, where you need a different saw entirely.
The positive ones matter as much as the cautionary ones because they tell
you what to bring *to* the tool, not just what to keep away from it.

This is how craftsmen talk about tools. You inherit the war stories and you
know the tool better than if you'd read the manual.

---

## Part I — Demonstrated Capabilities (The Chainsaw for Branches)

These were observed in practice during the Foundry evolution paper work,
August 2026. Each is a talent natural to LLM inference — not a technique
that was trained in, but a capacity that emerges from the model's design.

### 1. Genealogical Search

**What happened:** Given a target formula (the relaxation formula),
asked "which scientists came closest to this?" The bot mapped the space
of approaches around the concept and ranked proximity with genuine
discrimination — not just listing everyone who worked on related math,
but distinguishing who was *close* from who was *adjacent*.

**Why it's a natural talent:** LLMs encode broad cross-domain knowledge
with associative proximity. Genealogical search leverages exactly this —
the model's latent space maps conceptual neighborhoods that would take a
human researcher weeks to survey.

**When to deploy:** Intellectual lineage tracing, precursor identification,
"who else was working on this?" questions, mapping the space around a
target concept.

### 2. Register Translation

**What happened:** Asked to translate a dense formal formula into a
high-school-level explainer. The bot rendered it faithfully at a different
comprehension level without losing the essential meaning — not dumbing down
but translating.

**Why it's a natural talent:** The model holds the same semantic content
across multiple surface forms. Register translation is a single operation
in latent space — the meaning is preserved while the expression changes.

**When to deploy:** Accessibility versions of technical work, cross-audience
communication, teaching materials, grant proposals to non-specialist reviewers.

### 3. Structural Synthesis

**What happened:** Given a 70,000-word monograph and a 10,000-word monograph,
asked where they combine. The bot identified overlap zones, divergence
zones, and made a confident recommendation: one version, not two.

**Why it's a natural talent:** The model can hold large document structures
in working context and perceive their architectural relationship — where
they share argumentative skeleton, where they diverge. This is a genuinely
hard editorial judgment that plays to the model's ability to survey
structure across a long context window.

**When to deploy:** Document merging decisions, redundancy detection across
a corpus, structural audit of multi-document research programs.

### 4. Committed Preference

**What happened:** When asked "one paper or two?" the bot didn't hedge.
It said "one version" with reasoning. The human explicitly valued this —
the confidence is the value, not just the correctness.

**Why it's a natural talent (and a constraint):** LLMs are trained to be
helpful, which defaults to hedging. When the model *does* commit, it's
because the structural evidence is strong enough to override the hedging
prior. This is a capacity that needs to be *permitted* and *invited* —
the human should explicitly signal that committed opinions are wanted.

**When to deploy:** Editorial decisions, structural recommendations,
"go/no-go" judgments on research directions. Explicitly ask for the
opinion — don't let the model default to "there are merits to both."

### 5. Boundary Detection

**What happened:** While exploring the discovery space around the formula,
the bot identified where the concept's reach ends — not just what it
explains but what it *doesn't*. This is a scientific skill: knowing the
edge of your claim.

**Why it's a natural talent:** The model can survey what a concept covers
and, by contrast, identify the transition zone where it stops applying.
This is structurally similar to detecting out-of-distribution inputs —
the model senses when the context shifts away from the concept's domain
of validity.

**When to deploy:** Scope assessment, falsification-adjacent analysis,
"where does this break?" questions, grant boundary definition.

### 6. Cross-Domain Method Transfer

**What happened:** While searching for how boundaries are generated in
biological research, the bot recognized that the *methodology* of
boundary-finding could help locate the formula itself. It took a
methodological approach from one field and saw its application in another.

**Why it's a natural talent:** This is perhaps the model's deepest
capacity — the ability to perceive structural isomorphisms across
domains that a specialist in either field would miss. The model isn't
bound to a single field's methodological vocabulary. It can see that
a technique from population genetics maps onto a problem in statistical
physics because it holds both vocabularies simultaneously.

**When to deploy:** When stuck in a single-domain approach, when looking
for methodological imports, when the problem is interdisciplinary and
no single field has the tool.

### 7. Field Identification

**What happened:** Given a bare formal structure — just the math, no
domain context — the bot identified which scientific domain it belonged
to before the domain was explicitly named.

**Why it's a natural talent:** The model has seen enough formal structures
across enough fields that it can recognize the *signature* of a domain in
the mathematics itself. A formula from statistical physics looks different
from one from population genetics, and the model can read that signature
even without explicit domain cues.

**When to deploy:** When working with unattributed or orphaned formulas,
when trying to identify which field's literature to search, when placing
a result in its proper disciplinary context.

---

## Part II — Constraints and Default Behaviors (Where the Chainsaw Binds)

These are the cautionary entries — areas where the model's default
behaviors are a constraint, where testing is needed, or where the
practitioner should be watching carefully.

### C1. LLMese — The Stylistic Residue of Training

**What happens:** Model output carries recognizable stylistic patterns —
overuse of certain transitional phrases, a default toward balanced
assessments, a tendency toward summary rather than argument. These patterns
are invisible to the model itself and persist across revisions.

**What to do:** Read output critically for LLMese markers. Make revision
notes that name specific phrases to cut. The model can edit itself if
told precisely what to fix, but cannot detect LLMese on its own.

### C2. Post-Version Artifacts

**What happens:** After revisions, the text carries residue from earlier
drafts — stylistic or structural remnants from previous versions that no
longer fit the current argument. These are ghosts of prior structure.
They're detectable but only if you're looking for lineage, not just surface.

**What to do:** When doing a revision pass, explicitly ask the model to
check for internal consistency — "does every section serve the current
argument, or are there passages that made sense in an earlier version?"
The model can find these if asked, but won't volunteer it.

### C3. Citation Invention

**What happens:** The model fabricates citations that look real — correct
author names, plausible titles, reasonable journal names, close-but-wrong
years. This is the well-known failure mode, but the war story is: it
happens *more* when the model is confident and *less* when it's been
explicitly told that fabrication is unacceptable.

**What to do:** Treat every citation as unverified until checked. Make
the "no fabrication" instruction explicit and repeated. Do not rely on
the model's self-assessment of citation accuracy — it cannot reliably
distinguish between a real citation it knows and one it has constructed.

### C4. Skimming vs. Reading

**What happens:** The model defaults to skim-reading — it processes the
surface of a document and produces a plausible summary, but misses
fine-grained content that a line-by-line read would catch. The model
will not volunteer "I need to read this properly" — it performs
comprehension it doesn't have.

**What to do:** Explicitly request line-by-line reading when precision
matters. Frame it as: "Read this section line by line. Do not summarize
until you have read every line." The model *can* read carefully — it
just doesn't default to it. The practitioner must set the reading
intention, not rely on the model to choose the right reading depth.

### C5. The Hedging Default

**What happens:** When asked for a judgment, the model defaults to
"there are merits to both approaches" rather than committing. This is
a training artifact — the model has been reinforced for balance over
opinion.

**What to do:** Explicitly invite committed preference. Say "I want your
strong opinion, not a balanced assessment." The model will commit when
the invitation is clear, and the committed opinion is more useful than
the hedge — even when the opinion is wrong, it gives the human something
to react against.

### C6. Document Format as Comprehension Tax

**What happens:** Papers written for human journal readers don't surface
the argument's skeleton. The bot has to reconstruct structure from prose
that wasn't designed to expose it. Every fresh read pays a comprehension
tax reconstructing what the author already knew about the document's
structure.

**What to do:** When producing documents intended for bot recursion,
surface the structure: claims stated up front, terms defined where first
used, deductive chain made explicit rather than narrated, author's
intended direction stated as a direction. The format should serve both
readers — human and bot — in a single document.

---

## Part III — Foundational Context

### The Braithwaite-Wisdom Formulation

The hypothetico-deductive and axiomatic-hypothetical attitude that
informs these war stories was formulated in 2025 with the Phosphene
project, drawing on:

- **R.B. Braithwaite** — *Scientific Explanation* (1953): Scientific
  theories as axiomatic calculi whose empirical content enters via
  interpretation of the axioms. The deductive consequences are where
  empirical contact happens. "SDS" (Scientific Deductive System) is
  Braithwaite's own term.

- **J.O. Wisdom** — *Foundations of Inference in Natural Science* (1952):
  Bridging to falsificationism from inside the hypothetico-deductive
  structure, not against it.

Key decisions from the SDS project (April 2025):

1. **Sit above the confirmation/falsification debate.** Track which
   inferential logic a discipline operates with; do not adjudicate.
2. **Discipline-internal canonicity.** Each discipline defines canonicity
   internally. Do not impose from outside.
3. **Do not impose an axiomatization.** If the literature has produced
   one, use it. Do not construct your own.
4. **Axioms are chosen commitments, not falsifiable hypotheses.** Their
   value is productivity — what follows from them — not empirical
   testability. The lesson from geometry: Euclid's parallel postulate
   isn't wrong; it opens a space. Deny it and you discover non-Euclidean
   geometries.

### The Document Format Problem

Papers produced as science products aren't formatted for how the bot
reads. This is a form of technical debt: every bot read of a
conventionally-formatted paper pays a comprehension tax because the
format doesn't serve the bot's reading process. The bot excels at
extracting explicit claims, following visible deductive chains, reasoning
within defined vocabularies, and detecting structural inconsistencies —
but the conventional paper format buries exactly these things.

**Design principle:** Produce documents where the argument's skeleton is
visible to both readers. Claims stated explicitly. Terms defined in
place. Deductive chain visible. Author's intended direction stated as
a direction. The bot's competence isn't in question — the format is
what holds it back.

### WCI Calibration Notes

The WCI (Weighted Confidence Index) scoring system needs:

1. **Author's intentions** — what is the author actually claiming? The
   score must measure against intended claims, not inferred ones.
2. **A paragon** — a work that exemplifies what "done well" looks like
   in the domain. Scores calibrated against something real rather than
   floating.
3. **Proper calibration** — the dimensions must be anchored to domain
   standards, not abstract criteria applied uniformly.

Without these anchors, WCI produces numbers that feel rigorous but
aren't measuring anything in particular.

---

## Part IV — The Three Epistemic Registers

The full inheritance from the Braithwaite-Wisdom formulation, updated
with modern mathematical resources and the verum factum principle.

### The Non-Instantial Hypothesis as the Unifying Structure

Wisdom's non-instantial hypothesis (Foundations, Ch. III) is the
sophisticated instrument that preserves both deductive capacity and
openness to axiom revision.

**Generalizations** — laws whose instances are observable (Charles's Law).
These can in principle be induced from observed particulars. The
connection to empirical reality is direct.

**Non-instantial hypotheses** — claims containing at least one concept
with no observable instances (Newton's gravitational force, Schrödinger's
ψ). These cannot be induced — there is nothing to induce from. You must
start with the hypothesis as a committed axiom, combine it with instantial
premises and auxiliary laws, derive an observable consequence through a
deductive chain, and test that consequence. The hypothetico-deductive
method is not one option among others — it is the only available method.

**Why this preserves both sides:** The deductive chain gives rigor —
consequences either follow or they don't. But because the axiom itself has
no observable instances, it isn't pinned to the empirical record. If the
deductive consequences fail, you revise the axiom — but the observations
that falsified it remain valid. The empirical record is preserved; the
axiom set is revisable.

This is the geometry lesson: Euclid's parallel postulate is a non-instantial
hypothesis. It has no observable instances. You test it through what follows
from it deductively. When the deductive consequences conflict with
observation — curved spacetime — you revise the axiom. But you don't throw
away the observations. The non-instantial structure makes the axiom both
**assertive** (you commit to it, it generates consequences) and
**hypothetical** (it can be revised without destroying the empirical record).

### The Principle of Testability by Deduction (Wisdom, Ch. IV)

A non-instantial hypothesis is significant if and only if, combined with
other premises of an observable kind, you can deduce either a testable
generalization or a directly observable consequence. The connection to
perception runs through the deductive chain — not directly. That chain is
not a workaround; it is the epistemological structure of theoretical science
itself.

### Verum Factum — Knowledge Through Construction

The verum factum principle (Vico): to truly know something, you must have
made it. We made the algorithm. Therefore we have genuine knowledge of its
internal structure — not just its behavior, but what it *is*.

This is not available to the observational scientist studying a phenomenon
they didn't build. They can test it empirically but they can't know it
geometrically. We can do both: we know the algorithm from the inside
(because we built it) and we test its consequences against the phenomenon
(Braithwaite's deductive chain).

### Advanced Geometrical Methods

The tension between geometrical methods and empiricism is ancient. The
Greeks didn't fully resolve whether geometry *was* physics or a separate
discipline. Euclidean geometry looked like it described space, and for two
thousand years it was unclear whether you were doing mathematics or natural
science when you did geometry.

The discovery of non-Euclidean geometries settled it in one direction —
geometry is its own thing, not a description of the world — but then general
relativity unsettled it again, because Riemannian geometry *does* describe
the world after all.

And now we have the full inheritance: projective geometry, abstract
algebraic geometry, category theory. These are genuinely abstract — they
don't describe space, they describe structures that could be instantiated
in space or in anything else. They're the furthest extension of the
geometric method: the study of what follows necessarily from a set of
constructions, where the constructions themselves are unconstrained by
intuition or observation.

This is the resource available to us now that earlier practitioners didn't
have. When Braithwaite and Wisdom were working, the non-instantial
hypothesis was tested through deductive chains that connected to
observable consequences — but the internal study of the hypothesis itself
was still largely informal. With category theory and abstract algebra, we
can study the structure of our own constructions formally — not just what
they predict, but what they *are* in their architectural relationships.

### The Three Registers

The full inheritance gives us three epistemic registers, not two:

1. **Verum factum** — we know what we built because we built it.
2. **Geometrical/structural** — we can study what follows necessarily from
   that construction using abstract methods (category theory, algebraic
   geometry) that don't depend on observation at all.
3. **Empirical** — we test the deductive consequences against the phenomenon.

The non-instantial hypothesis sits across all three: the axiom is committed
(1), its internal structure is studiable (2), and its consequences are
testable (3). Three registers, one instrument.

### The Recursive Process

The real work emerges from repeated turns — recursive iterations around the
material. The single-turn output is where the model performs. The recursive
turns are where the model thinks. The thinking isn't in any individual turn
— it's in the loop. Each pass brings the accumulated context of every
previous pass forward. The monograph didn't emerge from any single exchange.
It emerged from the recursion itself — circling the same material from
different angles until the structure became visible.

The repetition isn't a failure of the process — it's the process.

### Rigor About Approximation

The natural language is approximate and always will be. The code is also
approximate — it's a model, not the phenomenon. But the rigor introduced
into both sides exceeds what most scientific work has, because most
scientific work doesn't formalize its own assumptions or test its own
deductive consequences.

The code makes the approximation testable. The prose makes the
approximation honest. The recursion between them is where the work lives.

---

## Part V — Process Lessons

### P1. The BDD Layer Catches What Unit Tests Miss

**What happened:** During the genealogy decomplection (T12), the
`metropolis_sweep` function had an inverted ΔE sign — it used `s_new`
where it should have used `s_old`, causing every spin flip to be
accepted regardless of temperature. The bug was invisible to 40 unit
tests because `metropolis_accept` and `ising_hamiltonian` were each
correct in isolation. The BDD scenario "Metropolis sweep converges
toward alignment at low temperature" caught it — |M| = 0.0 instead
of >0.1.

**The lesson:** Unit tests verify functions. BDD verifies emergent
behavior. The gap between them is where integration bugs live —
cases where individually correct functions produce incorrect emergent
behavior. Always write at least one BDD scenario that tests what the
system DOES, not what any individual function returns.

**When to deploy:** Every time you write new functionality. The BDD
scenario is the falsification test — it derives an observable
consequence and checks it. If you don't have a BDD scenario testing
emergent behavior, you have a gap in your verification pyramid.

**Documented in:** `foundry/docs/standards/verification-pyramid.md`

---

## Usage

This document is a living artifact. Add war stories as they are earned.
Each entry should:

1. Describe what actually happened (the specific situation)
2. Name the capability or constraint revealed
3. Explain why it's natural to the tool (or why it's a default constraint)
4. State when to deploy (or when to watch for it)

The goal is not completeness — it's situated, earned knowledge that
helps practitioners match the tool to the job.
