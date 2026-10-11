# Harmonization (Phase 6.5)

After resolution, analyze the **merged set** for the incoherence that mechanically joining two
*individually correct* sides produces. Results land in `state.json.harmonization`
(`blockers` / `followUps`) and `<studyDir>/FOLLOW-UPS.md`.

## Candidate-driven, NOT a repo sweep
The analysis starts **only** from:
- files touched by the merge,
- the golden list,
- convergent flows (Form 3),
- items tagged `rewrite` in Phase 2.

It is **never** a broad architectural audit of the repo.

## The six axes
1. **Functional duplication** — two implementations of the same behavior, one per side.
2. **Inconsistent patterns** — the two sides solve the same problem differently.
3. **Orphan dead code** — code left unreachable by the join.
4. **Naming drift** — the same concept named two ways.
5. **Missing abstraction** — the combination begs for a shared seam.
6. **Conflicting business rules** — the two sides encode contradictory logic.

## Two buckets — the boundary that decides what blocks
- **Blocks the merge** (functional/contractual incoherence): conflicting business rule,
  ambiguous contract, behavior incoherent between the sides → goes to the **human gate**;
  without explicit acceptance, **no commit**. → `state.json.harmonization.blockers`.
- **Follow-up post-merge** (quality, not functional): duplication, naming drift, missing
  abstraction, standardization, dead code → a **prioritized** list in `FOLLOW-UPS.md`.
  **Does not block the commit.** → `state.json.harmonization.followUps`.

## Re-validation loop
The analysis itself does not block; **execution is a neighbor skill's job** (keeps the 0–6
scope). But if the human chooses to **fix a finding before the commit**, that edit invalidates
Phase 6 → **re-run the parity gate** before closing.

## Altitude applies here too
The six-axis sweep runs **only when the merge contains a DEEP / golden-list item**. Under
`--lite`, or a merge that is only TRIVIAL/STANDARD, it reduces to the cheap structural checks
(obvious dead code, lint) — not the full audit.

## Ceiling rule
Phase 6.5 **points and prioritizes; it does NOT design the solution.** Specifying the fix is
the neighbor skill's work.

## Coherence bar (the Phase-7 gate this feeds)
**Functional coherence OR registered debt.** Functional/contractual incoherence is either
accepted by the human or already fixed; structural improvements (duplication / naming /
abstraction) may proceed as a registered follow-up — the bar does **not** require aesthetic
harmonization before the commit.
