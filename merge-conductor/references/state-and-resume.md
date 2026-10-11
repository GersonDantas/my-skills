# State & Resume

## The state file
`<studyDir>/.merge-conductor-state.json` is the verifiable record for `--resume`, audit, and
handoff. Its full contract is `assets/templates/state.schema.json` — that schema is
authoritative; this file explains how the pieces are used. It is written by `checkpoint.sh`
after each resolved point, and by phase scripts as they complete.

Key fields (see the schema for the complete shape):
- `sides` — `ours` / `theirs` / `mergeBase` (+ `mergeBasesAll` for criss-cross).
- `worktree`, `studyDir`, `mode`.
- `phasesDone`, `remainingConflicts`, `checkpointed`, `attackOrder`, `altitude`.
- `decisions` — human decisions, each with `mandatoryHuman`.
- `rerere` — see `rerere-safety-contract.md`.
- `parityBySha` — see `parity-gate.md` (keyed by immutable parent SHA; cached).
- `toolchain` — per-package map (see `agnosticism-and-adapters.md`).
- `harmonization` — `blockers` (gate) + `followUps` (non-blocking).
- `convergenceCoverage` — the detector's fidelity tier (declared; no silent caps).

## What `--resume` re-hydrates
Not just `remainingConflicts` + rerere. It re-hydrates **three** things:
1. **`state.json`** — phases done, attack order, checkpointed paths, decisions, parity-by-SHA
   (cached parent baselines are reused, not recomputed).
2. **The README invariants** — the golden list + global invariants synthesized in Phase 2 are
   reloaded so the resumed session resolves against the same contract.
3. **Hardened rerere** — the guard re-asserts the isolated cache and re-loads
   `autoResolvedPendingReview`, so every replayed point is still treated as a conflict to review.

A large merge may therefore span several sessions without losing progress.

## Git safety tiers
Every git action is classified; the tier governs whether confirmation is required.

| Tier | Actions | Rule |
|------|---------|------|
| **read-only** | enumerate, `merge-tree` preview, parity, inventory, `git diff/log/status` | free |
| **reversible** | `git add` (checkpoint), create a dedicated worktree | allowed; recorded in `state.json` |
| **destructive** | the merge commit, `push`, `reset` / branch repoint | **explicit confirmation mandatory** |

**Never run a destructive action non-interactively without a flag.** Study/audit agents are
strictly read-only (no `add`/`commit`/`checkout`/`merge --abort`); the experiment runs in a
dedicated worktree so the dev's working folder is untouched.

## Decisions: mandatorily human vs merely recommended
- **Mandatorily human** (gate — `mandatoryHuman: true`): public contract, schema, migration,
  billing, auth, **test removal**. No commit without explicit acceptance.
- **Merely recommended** (proceed): everything else. The host resolves deterministically and
  records it, without stopping — this is what keeps the Phase 4 loop scalable for the human.
