# Convergence Detector (Form 3)

The detector finds **co-change on the same flow without a textual conflict** (Form 3): both
sides evolved the same function/contract/invariant in different files that never collided.
If it misses, the README says "clean" and that is **false comfort** — worse than not having
the skill. If it explodes, it drowns the human. This contract makes detection **cheap,
reproducible, and calibrated for recall**.

It is **not a rigid script**: it is a model-guided task fed by mechanical candidate
generation. The script generates candidates; **the model only JUDGES the Top-K, it never
generates** (cost ceiling + reproducibility).

## Input
- The **diff of each side vs the merge-base** — not side-vs-side.
- `--find-renames` (`-M`) on, so a moved+edited symbol is still tracked.
- `git merge-base --all` — long-lived branches have criss-cross / multiple bases;
  diffing against a single base lies.

## Candidate generation (mechanical script, NO LLM)
1. **Extract changed/defined symbols** from each side: functions, exports, types, schema,
   route, event, env var, **config, feature-flag, migration**, table, payload, action, queue.
   Lexical-per-hunk at the floor; tree-sitter/LSP if available. **Shared state** touched by
   both sides (DB / migration / config / env / flag) is a first-class signal **even with no
   symbol overlap**.
2. **Resolve real import paths** before crossing — discard **barrels / index / re-exports**,
   otherwise everything "converges" on `index.ts`.
3. **Intersect the two change-sets, weighted by type-IDF rarity** (drops ubiquitous `id`,
   `data`, `return`). **Max priority to the def-on-one-side / use-on-the-other crossing** (one
   side alters the symbol, the other references it) — the high-precision, high-danger subclass.
   3.1 **Score-trail for shared state WITHOUT a symbol:** a co-touch on the same
   migration/flag/config/env/table has no symbol to IDF-weight — it enters the ranking by a
   **fixed weight per state-type** (migration/auth/schema = high; config/env = medium).
   Without its own trail, the "first-class" class would never compete for the K slots and
   would be decorative.
4. **Size guard:** if the aggregate diff exceeds a threshold (KB/lines), **degrade** to a pure
   import-graph / `dirstat` pass and emit a structured warning — never dump a massive diff
   into the LLM.

## Output
Top-K **ranked** candidates in JSON, each with **evidence**: the shared symbol, which side is
*def* / which is *use*, the two hunks, the score, and the signals. The model judges the K and
nothing else.

## Severity → altitude
- **DEEP automatic:** public contract / schema / API / payload, auth, billing, persistence,
  migration, queue/event, critical feature-flag, **a removed/altered test on the same flow**.
- **REVIEW mandatory:** same module + shared symbol + likely producer/consumer.
- **Note / inventory only:** directory proximity, barrel, generic route, mass-touched file.
- **Cut by `contract-risk × evidence-strength × centrality`, NEVER by number of files.**

## Calibration: for RECALL, not precision
Because a false negative has no safety net:
- **Rank, do not threshold.** The **def/use-crossing class is never cut**, whatever K is.
- The tail of "ubiquitous-identifier-only" candidates is **summarized, not enumerated**.
- **Backstop (mandatory):** convergence detected over **code with no test exercising it** →
  a **flagged follow-up** (not a silent pass). It is the only screen, since both parity axes
  (Phase 6) are blind to flow without a test.
- **Honest degradation:** if it ran lexical-only, the README declares "convergence coverage:
  lexical — may miss type coupling / dynamic dispatch / pub-sub" (the "No silent caps"
  principle). The fidelity tier is recorded in `state.json.convergenceCoverage`
  (`symbol-graph` | `tree-sitter` | `lexical` | `dirstat-only`).

## Noise filter (precise)
Suppress a candidate **only** when it is a **ubiquitous identifier + a generated/vendored/
barrel path**. **NEVER suppress by module proximity** — the most dangerous co-change is
cross-module, and filtering by module would kill the recall that justifies the skill.

## Provenance of the golden list / invariants
The **golden list** is the set of convergence candidates **the model confirmed** while judging
the Top-K. The **invariants** are declared by the model in the DEEP study of each item (or
seeded by the user). Neither is a magic artifact.
