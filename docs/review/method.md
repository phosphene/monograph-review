# Review Method and Naming Discipline — Working Notes

**Namespace:** lower — working notes behind the public documentation. This document holds the
methodological commitments and naming discipline the review proceeds under. It is not part of
the public top level; the root [`README`](../../README.md) links and indexes it, and this is
where derivation rules, qualifications, and commentary live.

---

## 1. Method commitments (Braithwaite–Wisdom picture of empirical science)

The review proceeds under commitments that are themselves part of the Braithwaite–Wisdom
picture of empirical science.

- **Explanation as deduction from higher hypotheses.** The monograph is examined as an ordered
  system of claims. Lower-level empirical generalizations must be exhibited as consequences of
  higher-level hypotheses; theoretical terms take their meaning from their place in the system
  together with their observable consequences. Only derivation propagates through the citation
  chain; speculation does not compound (Braithwaite, *Scientific Explanation*, 1953, chs. II–III).
- **Establishment by consequences.** A hypothesis is established by its verified empirical
  consequences; the weight of evidence, and so the degree of confidence it warrants, grows with
  the variety of consequences that survive testing (Braithwaite, ch. VI). This is the standard
  the review applies: a claim is supported by conditions that are stated and tested, or it is
  not advanced — or is advanced only as a proposal, explicitly marked untested. There is no
  third state.
- **Inference as austerity (Wisdom).** The move from observation to hypothesis must not
  attribute more than the evidence supports. Darwin's worms: patient observation of what
  earthworms do, reasoning from observable inputs and outputs without an extra causal
  ingredient. Where the argument exceeds its evidence, the excess is labeled — speculation,
  open question, hypothesis — and never cited as established fact.
- **Observation as the production of conditions (Wisdom).** Observations are the foundation of
  scientific method because they are the conditions in which statements can be made — and those
  conditions can be reproduced. The reproduction of the conditions is itself observation: to
  observe is to produce, or reproduce, the conditions under which a statement holds. The review
  therefore does not assert that observation is free of the observer's framework, nor does it
  assert that the research programs it draws on do or do not commute; neither is settled, and
  the argument depends on neither. It depends on the reproducibility of conditions: anyone who
  re-runs the analysis reproduces them, and may draw their own conclusions.
- **Induction as a policy, and the record.** The justification of induction is pragmatic — it is
  the policy best suited to achieving our aims, and it presupposes a reliable record of past
  trials (Braithwaite, ch. VIII). The record is therefore part of the method, not bookkeeping:
  reproducibility means same input, same output, enforced under CI against a pinned oracle.

## 2. Naming discipline (qualified naming, from Frege via Hickey–Tellman)

- **Sufficient positive predication.** An assertion is a positive predication: it states what a
  thing is, and thereby carries the implicit negation of what it is not. Specification by
  explicit negation is a weak form of specification — it contrasts rather than predicates, and
  leaves the positive claim underdetermined. Claims are therefore stated by what they are;
  explicit negation is reserved for reporting what happened to a rejected null, never as the
  primary form of a claim.
- **Qualified naming (Hickey–Tellman, from Frege).** Every name must carry sufficient semantic
  meaningfulness as a name. Genealogy: the triadic model of the name — sign, referent, sense —
  derives from Frege's theory of sense and reference (*Über Sinn und Bedeutung*, 1892);
  Tellman's naming chapter (*Elements of Clojure*, 2019) and Hickey's Clojure design practice
  restate it for software; this review extends it to research programs. An abstract term
  sufficient unto its abstraction — within mathematics or within a research program — is never a
  top-level claim on its own: it must be tied to the research program from which it draws its
  meaning. Such a term may appear inside a paragraph that names its program, but any name exposed
  at top level — a hypothesis, a thesis, metadata — must be fully qualified, its research-program
  namespace stated as part of the name.
- **Boundary rule for names.** How much qualification a name requires scales with the breadth of
  its usage. A word that has entered common usage — its namespace is the language itself, wide
  open — may stand unqualified (e.g., evolutionary science). A term bounded within a research
  program is namespaced to that program. No word is peculiar in itself: the rule is discipline
  over our own usage in public communications. A term with a legitimate usage in a research
  program may be quoted at a distance, fully qualified by naming the program (cell biology:
  cell-substrate adhesion; biochemistry: enzyme-substrate), but it is flagged as not part of a
  top-level namespace — not capable of being raised to that level — and in cross-domain research
  it is not used at the top level at all. Worked case: "substrate" in the sense this review
  needs belongs to no research program, so the L3 competitor is paraphrased in plain language —
  "independence of the two kingdoms predicts no transfer" — and the consciousness-research usage
  ("a biological substrate as the basis for human experience or cognition") is a vague analogy
  misapplied from cell biology; it may be mentioned only as "used as an analogy within some
  areas of armchair consciousness research" — kept at a distance, never adopted.
- **Top-level namespace discipline (applied to this repository, Ed Phil 2026-08-29).** Top-level
  namespaces within any project are reserved for public communications only about the given
  domain space under test — details of the implementation and all the technical aspects required,
  using only public language with fully qualified namespacing of all the basic acts. No mention
  of the rules — internal or external — that we need in order to derive this public documentation
  should ever be in the top level. All working notes, all qualifications, all commentary about
  usages and criticisms of other research programs live in a lower namespace within the project
  file system and are merely linked and indexed in the top-level README. This document is the
  home of those notes for the monograph review.
- **Self-specifying top level (Ed Phil #80721).** The top-level README is the place to practice
  proper public science discipline: everything is based on the use of top-level names or fully
  qualified namespaced names; every mathematical notation has a place; every formalism has a
  place; everything is clearly located within its own domain; the README is fully
  self-specifying — it makes public science sense in public language on its own, with no
  reliance on unstated context or on the lower namespace for meaning.
- **Public institution, common namespace (Ed Phil #80724, #80730).** A figure who is an
  institution of public science — Darwin is the worked case — is itself a common namespace:
  his name, his world, and his thinking are fully available to the top level without further
  qualification. Any mention of Darwin is public science. This is the clean case of the
  boundary rule: the breadth of his user distribution is maximal, so his names stand
  unqualified. The review's tradition is public and belongs at the top level: Darwin's
  earthworms (The Formation of Vegetable Mould, Through the Action of Worms, 1881) as the
  paradigm of inference from observable inputs and outputs, and J.O. Wisdom's study of
  scientific inference, Foundations of Inference in Natural Science (1952), which opens with
  Darwin for exactly this reason. Wisdom's work is also a good use of a top-level namespace:
  a plain title that names its subject simply. The genealogy is stated briefly and publicly
  in the top-level README; the working detail stays here.
- **Austerity of vocabulary.** No private models, no private metaphors, no terms imported from
  another domain. Every word is a resident of classical evolutionary science or is forced by the
  measurement itself; every model has a named public source. An import is a category error.

## 3. Substrate — the worked case, in full

"Substrate" has legitimate research-program usages that we can quote at a distance, each fully
qualified by naming the program: (a) biochemistry (enzyme-substrate — the molecule an enzyme
acts on), (b) ecology/benthic biology (the surface a community grows on), (c) cell biology
(cell-substrate adhesion). None is the sense the review requires (a domain in which a
quantitative process unfolds), so that sense is paraphrased in plain public language in the
root README: "independence of the two kingdoms predicts no transfer" — no program's private
sense adopted. The consciousness-research usage ("substrate independence of consciousness";
"a biological substrate as the basis for human experience or cognition" — Chalmers's
organizational invariance; integrated information theory) is a vague analogy misapplied from
cell biology; in public communication it may be mentioned only as "used as an analogy within
some areas of armchair consciousness research" — kept at a distance, never adopted.

The review's other substrate usages (substrate shift, non-DNA substrate, economic substrate)
live in internal review documents and are namespaced by their surrounding research-program
context; they are not public statements. If any were to move into a public top-level statement,
they too would need to be either tied to an existing public-science research-program usage or
paraphrased in plain language.

## 4. Source trail

- Braithwaite, *Scientific Explanation: A Study of the Function of Theory, Probability and Law
  in Science* (Cambridge, 1953).
- J.O. Wisdom — austere inference from observable inputs and outputs (Darwin's worms as model).
- Frege, *Über Sinn und Bedeutung* (1892) — the triadic model of the name.
- Tellman, *Elements of Clojure* (2019); Hickey, Clojure design practice — naming restated for
  software; the common core lives unqualified, everything else is namespaced.
- Hickey–Tellman principle of sufficient semantic meaningfulness (codified as C-09 in the
  canonical statements, topic 73336).
- Boundary rule for names: Ed Phil, topic 73336, 2026-08-29 (#80707, #80708, #80712, #80714,
  #80715). Top-level namespace discipline: Ed Phil (#80720).
