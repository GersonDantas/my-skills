# Post-merge follow-ups (commits separate from the merge commit)

> **Cut criterion** (decided `<YYYY-MM-DD>`): the merge commit carries the textual resolutions
> **plus only the semantic fixes strictly required for build + tests to pass** (bisectability).
> Everything that is cleanup, improvement, or a non-blocking adjustment goes here — one small,
> self-explanatory commit per item, landed right after the merge.
> **Message rule**: describe the real change (behavior, reason, impact); do **not** reference internal
> step codes / epic macros / this plan's labels. A cold reader of `git log --oneline` must understand it.

Items are added as the resolution points are worked through.

## Blocker vs. follow-up — the Phase 6.5 boundary

Two buckets decide what gates the commit:

- **Blocker (functional/contractual incoherence)** — conflicting business rule, ambiguous contract, behavior incoherent between the two sides. Goes to the **human gate**; without explicit acceptance, **do not commit**. If the human fixes it pre-commit, that edit invalidates Phase 6 → **re-run parity**. *(These do NOT live in this file — they block.)*
- **Quality follow-up (non-functional)** — duplication, naming drift, missing abstraction, standardization, dead code. Prioritized below. **Does not block the commit.**

This file holds only the second bucket.

## High priority

> Touches a real flow, a contract edge, or an operational risk — do soon, but it did not have to gate the merge.

1. **`<title>`** — `<what to do>`. **Why**: `<the risk/incoherence it removes>`. **Files**: `<path(s)>`. **Effort**: `<S/M/L>`. *(origin: study <NN> §<x> / audit / gate)*
2. `<...>`

## Medium priority

> Real cleanup with bounded blast radius; schedule after the high items.

3. **`<title>`** — `<what>`. **Why**: `<...>`. **Files**: `<...>`. **Effort**: `<S/M/L>`. *(origin: <...>)*
4. `<...>`

## Low priority

> Cosmetic / hygiene / nice-to-have; pick up opportunistically.

5. **`<title>`** — `<what>`. **Why**: `<...>`. **Files**: `<...>`. **Effort**: `<S/M/L>`. *(origin: <...>)*
6. `<...>`

## Long-term (registered debt, no date)

> Larger refactors the merge surfaced but should not attempt — recorded so the knowledge is not lost.

- **`<title>`** — `<the structural debt, e.g. "unify the three implementations of X that already diverged">`. **Why**: `<the pattern that caused merge friction>`. **Files**: `<the divergent copies>`. *(origin: <...>)*
