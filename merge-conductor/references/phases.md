# Phases

Strict order, 0 → 7. Read the relevant section on entering a phase. **Scope = Phases 0–6 +
the thin tail of 7 (verified merge commit).** Phase 7-rest (stacked MRs / cover pages),
Phase 8 (follow-up execution), Phase 9 (validation-branch deploy/repoint) are neighbor
skills this one invokes/hands off to — not embedded (see `agnosticism-and-adapters.md`).

Each phase: objective · script/agent · input→output · gate.

## Phase 0 — Freshness & recon
- **Objective:** establish a trustworthy starting point and arm rerere safely.
- **Uses:** `scripts/rerere-guard.sh` (run **first** — mandatory, see `rerere-safety-contract.md`),
  then `scripts/freshness.sh`.
- **In→out:** branch names → both sides confirmed `== upstream`; merge-base(s) via
  `git merge-base --all` (criss-cross aware); optional prior-attempt SHAs; rr-cache
  snapshot + global `rerere.enabled` recorded into `state.json`.
- **Gate:** stale side (not `== upstream`) aborts without explicit confirmation. Ambiguous
  base (>1 merge-base) requires a confirmed pick.

## Phase 1 — Cartography
- **Objective:** enumerate every point of care across all three forms (physical conflict,
  semantic conflict, co-change without conflict).
- **Uses:** `scripts/enumerate-conflicts.sh` (`git merge-tree` preview + dedicated worktree +
  `git merge --no-commit` + `UU`/modify-delete/add-add inventory + each side's diff vs base +
  `dirstat` seed), then the **convergence detector** (model-guided, fed by the two diffs — see
  `convergence-detector.md`).
- **In→out:** merge-base + two tips → inventory + Top-K ranked co-change candidates w/ evidence.
- **Gate:** none (sensing). The detector ranks for recall; the model judges the K.

## Phase 2 — Study by altitude
- **Objective:** understand *what each side planned* and *how to reconcile it*, depth per item.
- **Uses:** read-only study agents fanned out **per theme**, each in its own worktree
  (`assets/prompts/study-agent.md`); templates in `assets/templates/`.
- **In→out:** Phase 1 inventory → `<studyDir>/NN-*.md` per item (TRIVIAL/STANDARD/DEEP) + the
  synthesis README (attack order + golden list + invariants + gates). See `altitude-and-study.md`.
- **Gate:** none, but the synthesis README is **non-negotiable** even under `--lite`.

## Phase 3 — Decisions
- **Objective:** surface genuine product/architecture decisions before any code is written.
- **Uses:** `AskUserQuestion`.
- **In→out:** study docs → human decisions appended to the docs and `state.json.decisions`
  (with `mandatoryHuman` flagged).
- **Gate:** genuine decisions only. `--dry-run` stops here and delivers `<studyDir>/`.

## Phase 4 — Sequential resolution loop  *(mandatory invariant — the scalability mechanism)*
- **Objective:** resolve each point of care correctly, one at a time, in attack order
  (junction file before its consumers; flow co-changes alongside the junction that drives them).
- **Uses:** host edits the resolution; `scripts/checkpoint.sh` (git add + `state.json` update +
  rerere records).
- **In→out:** one point → edited + checkpointed resolution → next point.
- **The loop (never batch, never "all at once"):**

  ```
  present (didactic: snippet of what changes + the why)
     → human gate ONLY if a genuine decision (else proceed: deterministic)
     → host edits the resolution
     → checkpoint.sh: git add + state.json update + rerere records
     → next point
  ```

- **Why sequential = scalable to arbitrary N** (the load-bearing point): scale does **not**
  come from fitting everything in context — it comes from **externalized state +
  checkpoint-per-point + resume**:
  - memory lives outside the context window: `<studyDir>/*.md` (study) + `state.json`
    (progress) + `rr-cache` (resolutions);
  - N points processed in attack order, each checkpointed — a 5-conflict and a 500-conflict
    merge use the *same* loop;
  - `--resume` continues from `state.json` in a fresh window/session without losing progress —
    a large merge may span several sessions.
- **Two boundaries that preserve the scale:**
  1. **Sequential is the RESOLUTION (Phase 4); the STUDY (Phases 1–2) is parallel fan-out**
     (agents per theme). Parallel scales analysis; sequential+checkpoint scales resolution.
     Do not conflate them.
  2. **The human gate is SELECTIVE, not per-conflict** — it fires only on a genuine decision
     (altitude rule + "mandatory-human vs recommended"). Trivial/deterministic points flow
     without stopping; otherwise N conflicts = N approvals and it would not scale *for the
     human*.
- **rerere interaction:** every rerere auto-resolved point **re-enters the loop as a point to
  review** (treated as a conflict, not as resolved) — replay never skips the cycle. See
  `rerere-safety-contract.md`.
- **Named strategies (chosen per item in Phase 2, applied here):** `accept-one` (one side
  evolves/replaces the other) · `combine` (complementary, independent) · `rewrite` (the
  combination needs a refactor for coherence → **feeds the Phase 6.5 queue**) · `escalate`
  (architectural impact → human decision).
- **Gate:** mandatorily-human decisions (public contract / schema / migration / billing/auth /
  test removal) gate; the rest proceed.

## Phase 5 — Functional audit
- **Objective:** prove the critical flows work end-to-end under **both** initiatives — not just
  "it compiles".
- **Uses:** a read-only audit agent (`assets/prompts/audit-agent.md`).
- **In→out:** merged tree → traced flows + incoherence flagged for Phase 6.5.
- **Gate:** none directly; findings feed the parity gate and harmonization.

## Phase 6 — Parity gate (two axes)
- **Objective:** prove no regression against the **pristine parents**.
- **Uses:** `scripts/pristine-parity.sh` (parallel parent worktrees, cache-by-SHA, layered
  cost). See `parity-gate.md`.
- **In→out:** merged tree + both parent SHAs → (a) pass/fail parity by test **identity** vs
  union of parents; (b) **test-inventory** parity (merged ⊇ union minus justified removals —
  catches deleted tests).
- **Gate:** Axis-1 regression OR Axis-2 missing-tests blocks. Flake never hides a regression;
  an `indeterminate` baseline is not "green".

## Phase 6.5 — Harmonization analysis
- **Objective:** catch the incoherence that joining two *individually correct* sides produces.
- **Uses:** candidate-driven analysis (touched files / golden list / convergent flows /
  `rewrite`-tagged items), **not** a repo sweep. See `harmonization.md`.
- **In→out:** merged set → two buckets: **blocks the merge** (functional/contractual
  incoherence → human gate) vs **follow-up** (quality → `FOLLOW-UPS.md`, does not block).
- **Gate:** functional/contractual incoherence needs explicit human acceptance before commit.
  **Loop:** a pre-commit human fix invalidates Phase 6 → **re-run the parity gate** before close.

## Phase 7 — Verified merge commit  *(thin tail; the rest is neighbor skills)*
- **Objective:** land a self-explanatory, bisectable merge commit.
- **Uses:** host writes the commit; rerere replays catch-up of commits that landed during the
  work (each replay re-verified per the rerere contract).
- **In→out:** fully-resolved, checkpointed tree → one merge commit (no internal codes);
  `state.json` closed.
- **Gate:** zero conflict markers; both parity axes green; harmonization done + recorded;
  coherence bar met (**functional coherence OR registered debt**). Destructive git (the merge
  commit, push, repoint) needs explicit confirmation.
- **Out of scope (neighbors):** stacked MRs / cover pages → `mr-cover-page`/`commit`; follow-up
  execution → follow-up skill; deploy / validation-branch repoint → org skill.
