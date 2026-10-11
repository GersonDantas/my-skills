---
name: merge-conductor
description: "Use when a merge is complex or suspected-complex and deserves step-by-step care: epics, divergent/long-lived branches, or any merge where both sides changed the same flow (same function/contract/invariant) — with or without a physical conflict. Conducts conflict cartography (textual + semantic in auto-merged files + co-change without conflict), per-file altitude study, sequential checkpointed resolution with hardened git rerere, and dual parity validation (pass/fail + test-inventory) against the pristine parents. Also serves smaller merges without lowering care. Git-only, language-agnostic. NOT for trivial rebases or an isolated 1-file conflict with no shared flow."
safety-mode: write
disable-model-invocation: false
argument-hint: "<target-branch> [--into <base>] [--resume] [--dry-run] [--lite]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Agent
  - AskUserQuestion
compatibility: "Requires Git. Optional GitHub/GitLab CLI and tree-sitter/ctags/LSP. See references/agnosticism-and-adapters.md."
metadata:
  execution_profile: portable
  guard_policy_version: "1.0"
  guard_checkpoints: "Preflight,Runtime,Final"
  fallback_mode: best-effort
  skill_tier.current: multi-resource
---

## Pre-execution: Load External Context

Config strategy: `cascade`.


# Merge Conductor

Conduct a complex/suspected-complex merge between two divergent branches with the **study-first,
semantic-aware, checkpointed, parity-validated** method. The skill **conducts and proves**; it never
"auto-resolves conflicts". The rare value is the pair **convergence detection (Phase 1) + parity gate
against the pristine parents (Phase 6)** — the two things naive merges miss.

**Unit of care = co-change on the same flow**, not "the conflict". Both sides touched the same
function/contract/invariant. It shows up in three forms, all handled with equal rigor:
1. **Physical conflict** — git marked it (`UU`).
2. **Semantic conflict** — git auto-merged "clean" but the result is wrong (a junction file resolved to
   one side + consumers from the other).
3. **Co-change without conflict** — different files, no textual collision, both sides evolving the same
   flow (e.g. one side reshaped a payload, the other added a consumer of it).

## Core decision: conduct, not execute

| Actor | Does | Does NOT |
|-------|------|----------|
| **Scripts** | sense (read-only: enumerate, parity, inventory) + deterministic git plumbing (enable rerere, `git add` checkpoint). Emit **structured JSON**, idempotent, **no git mutation beyond the documented one**. | never edit a conflict resolution |
| **Model (host)** | reasoning, semantic analysis, **editing** the resolutions | — |
| **Human** | gate on **genuine** decisions only | — |

## When to Use

- A merge of epics, divergent/long-lived branches, or one where both sides changed the same flow
  (same function, public contract, schema, migration, shared invariant) — with or without a `UU` marker.
- Resuming/redoing a merge in progress (`--resume`).
- Smaller merges too, when invoked explicitly — without lowering the per-point care.

**Do NOT use** for: a trivial rebase, an isolated 1-file conflict with no shared flow, or fast-forward
merges. The Phase 0 preflight recommends a normal `git merge` when conflicts and divergence are below
threshold and there is no explicit invocation.

## Input

- `<target-branch>` — the branch being merged in. `--into <base>` sets the base (default: current branch).
- `--resume` — continue an in-progress run from `state.json` + README invariants + hardened rerere
  (re-hydration + git safety tiers: see references/state-and-resume.md).
- `--dry-run` — Phases 0–3 only (cartography + study + decisions); writes no code; delivers `<studyDir>/`.
- `--lite` — small repos: lower the per-file study default (STANDARD→note); DEEP stays forced for
  junction files / golden-list. Never lowers the Phase 6 parity gate.

`studyDir` defaults to `merge-study/`. Optional per-repo `.merge-conductor.yml` may set `studyDir`,
`validationBranch`, `mrTool`, test/build/lint overrides, and complexity thresholds.

## Workflow

Phases run in order. Read the referenced file when you enter a phase; the full per-phase contract lives in
references/phases.md. **Scope = Phases 0–6 + the thin tail of 7 (verified merge commit).** Phases
7-rest/8/9 (stacked MRs/cover pages, follow-up execution, validation-branch deploy) are delegated to
neighbor skills — see references/agnosticism-and-adapters.md.

0. **Freshness & recon** — `scripts/freshness.sh`: confirm both sides `== upstream` (abort on stale
   without confirmation), find merge-base (`--all`, criss-cross aware), discover an optional prior merge
   attempt. Run `scripts/rerere-guard.sh` first (see references/rerere-safety-contract.md — **mandatory**).
1. **Cartography** — `scripts/enumerate-conflicts.sh`: `git merge-tree` preview + dedicated worktree +
   `git merge --no-commit` + inventory (`UU`/modify-delete/add-add) + each side's diff vs merge-base.
   Then the **convergence detector** ranks co-change candidates — read references/convergence-detector.md.
2. **Study by altitude** — classify each item TRIVIAL/STANDARD/DEEP; fan out **read-only** study agents
   per theme (one dedicated worktree each); write `<studyDir>/NN-*.md` (templates:
   assets/templates/study-deep.md, assets/templates/study-standard.md) + the synthesis README
   (assets/templates/study-readme.md — attack order + golden list + invariants + gates). Read
   references/altitude-and-study.md.
3. **Decisions** — surface genuine product/architecture decisions to the human (AskUserQuestion); record
   them in the study docs.
4. **Sequential resolution loop** (mandatory invariant — the scalability mechanism). **One point at a
   time, in attack order** (junction before consumers). Per point: present (snippet + why) → human gate
   **only if a genuine decision** → host edits → `scripts/checkpoint.sh` (git add + state.json + rerere)
   → next. **Never batch.** Scale to arbitrary N comes from externalized memory (studyDir + state.json +
   rr-cache) + checkpoint-per-point + `--resume`, not from fitting everything in context. Any rerere
   auto-resolved point re-enters the loop as a point to review.
5. **Functional audit** — a read-only agent traces the critical flows end-to-end under both initiatives
   (not just "compiles"). Use assets/prompts/audit-agent.md.
6. **Parity gate (two axes)** — `scripts/pristine-parity.sh`: (a) pass/fail by test **identity** vs
   union of parents (flake re-run, union baseline); (b) **test-inventory** parity (merged tree's tests ⊇
   union of parents, minus justified removals) — catches deleted tests. Pyramid + cache-by-SHA for cost.
   Read references/parity-gate.md.
6.5. **Harmonization analysis** — candidate-driven (touched files / golden list / convergent flows /
   `rewrite`-tagged items), not a repo sweep. Two buckets: **blocks the merge** = functional/contractual
   incoherence (human gate); **follow-up** = duplication/naming/dead-code/abstraction (into FOLLOW-UPS,
   does not block). If the human fixes a finding pre-commit, **re-run Phase 6**. Read references/harmonization.md.
7. **Verified merge commit** (thin tail) — self-explanatory message (no internal codes). Catch-up of
   commits that landed during the work replays via rerere. Stacked MRs / cover pages / follow-up
   execution / deploy are **neighbor skills**, not this one.

### Resolution strategies (name them per item)
`accept-one` (one evolves/replaces the other) · `combine` (complementary, independent) · `rewrite`
(combination needs refactor for coherence → feeds the Phase 6.5 queue) · `escalate` (architectural
impact → human decision).

### Spawning study/audit agents
Keep the coordinator on the model and reasoning effort selected for the current session. They are hard
ceilings for ordinary study/audit agents: never select a more capable model or a higher reasoning effort. Before each
delegation, classify the work by its highest altitude and choose only among model overrides currently
advertised by the host; never guess or hard-code model identifiers in this skill:

- **TRIVIAL-only:** keep the one-line note in the coordinator; do not spawn an agent only for it.
- **STANDARD:** use the fastest or lowest-cost advertised general coding/review model capable of the
  theme, with medium effort capped by the coordinator's effort.
- **DEEP:** inherit the coordinator model and reasoning effort unchanged. Junction files, golden-list
  suspects, shared invariants, security/auth, migrations, schemas, public contracts, broad blast
  radius, and real ambiguity are always DEEP for routing.
- **Functional audit (Phase 5):** treat as DEEP regardless of file count; inherit the coordinator
  model and reasoning effort unchanged.

If a theme mixes altitudes, use the highest. If the runtime does not advertise enough capability or
cost information to choose safely, omit both overrides and inherit the coordinator model and effort.
When overriding the model, also set an explicit supported reasoning effort no higher than the
coordinator's so the target model's default cannot exceed the ceiling. Escalate one tier when evidence
is incomplete, agents disagree, or a suspected convergence cannot be traced, but never beyond either
ceiling for ordinary agents. The configured consultant is the separate exception below;
preserve explicit user overrides. Do
not spawn a separate agent only to choose a model. In Codex, use `fork_turns: "none"` for delegated
studies and include all required context in the task prompt.

Study agents are strictly read-only (no `add`/`commit`/`checkout`/`merge --abort`); each runs in its own
dedicated worktree (concurrency isolation). See assets/prompts/study-agent.md for the mandate.

### Configured consultant exception

Keep TRIVIAL/STANDARD/DEEP and Phase 5 routing above unchanged for ordinary agents.
DEEP alone does not promote work to consultant. The coordinator consults:
- In Phase 3, on architectural/public-contract proposals or unresolved ambiguous
  convergence, before presenting genuine decisions to the human.
- In Phase 4, after two substantive failed attempts at the same resolution point.
- At a substantial completed milestone, using the audit and parity evidence to
  assess residual risks; not once per file or every phase.
Explicit user requests and applicable global consultation triggers also apply.

Read agents/consultor.toml under CODEX_HOME (default ~/.codex); use its model,
reasoning effort and instructions even above coordinator ceilings. Prefer the
native consultor role, otherwise use supported explicit delegation overrides with
those instructions. Never hard-code model IDs or silently substitute. If config or
delegation is unavailable, report that limitation without claiming consultation.

Send a focused question with sufficient evidence and constraints, wait and assess
the result. Reuse the same consultation when appropriate; repeat only with new
evidence or a new decision. Consultant cannot edit or recursively delegate.
Study/audit agents return uncertainties to the coordinator, not to another agent.
Consultation never replaces the Phase 5 audit, Phase 6 parity tests, sequential
resolution checkpoints, or human approvals. If it leads to a pre-commit fix,
repeat the required parity validation.

## Scripts (sensing + plumbing only)

All emit structured JSON, are idempotent, and never mutate git beyond the one documented action. See
`scripts/` and `assets/templates/state.schema.json`.

| Script | Role |
|--------|------|
| `freshness.sh` | origin-diff + stale-guard + merge-base (`--all`) + optional prior-attempt discovery |
| `enumerate-conflicts.sh` | merge-tree preview + UU/modify-delete/add-add inventory + each-side diff vs base + dirstat seed |
| `rerere-guard.sh` | snapshot / isolate-or-purge / status of `rr-cache` (rerere safety contract) |
| `pristine-parity.sh` | parallel worktrees of both parents, cache-by-SHA, two-axis comparison, layered |
| `checkpoint.sh` | git add + state.json update + remaining-UU report |
| `discover-toolchain.sh` | per-package `{test,build,lint,pkgManager}` map |

The **convergence detector** and **theme clustering** are NOT rigid scripts — they are model-guided tasks
fed by the two diffs vs merge-base + dirstat/imports (references/convergence-detector.md).

## Examples

- Input: `merge-conductor feature/widget-v2 --into develop`
  Output: runs Phases 0–6, materializes `merge-study/` with attack order + golden list, resolves each
  point one-by-one with checkpoints, proves no regression via two-axis parity, lands a verified merge
  commit, and records harmonization follow-ups.

- Input: `merge-conductor feature/payments-refactor --dry-run`
  Output: Phases 0–3 only — cartography (incl. co-change candidates), per-altitude study docs, and the
  open decisions surfaced to the human; **no code written**; delivers `merge-study/` for review.

## Output

- A resolved, checkpointed merge with a verified, self-explanatory merge commit (bisectable).
- `<studyDir>/` — per-item study docs + synthesis README (attack order, golden list, invariants, gates).
- `<studyDir>/FOLLOW-UPS.md` — prioritized harmonization findings (template:
  assets/templates/follow-ups.md; executed by a neighbor skill).
- `<studyDir>/.merge-conductor-state.json` — verifiable state for `--resume`, audit, and handoff.

## Constraints

- Conduct, never auto-edit conflict resolutions in scripts.
- Git-only; treat `origin` as a default, not an invariant (forks/other remotes/shallow → confirm path).
- Bisectability: the merge commit builds and passes; cleanups are follow-ups.
- Never lower the Phase 6 parity gate, even under `--lite`.
- Lockfiles/generated/migrations are never semantically studied — clear markers and regenerate via the
  detected installer (references/agnosticism-and-adapters.md).

## Validation Contracts

### Preflight Checks
- Git repo; two resolvable branches; freshness OK (both `== upstream` or explicit confirmation); clean
  worktree; `rerere-guard.sh` executed; complexity preflight **run** (below threshold AND no explicit
  invocation → recommend a normal merge; **does not block** when explicitly invoked).

### Runtime Guardrails
- Study/audit agents are read-only and follow the runtime routing policy: TRIVIAL-only work stays in the
  coordinator, STANDARD may use an advertised economical model, and DEEP/audit work inherits the
  coordinator model and effort. These are hard ceilings for ordinary agents; the configured
  consultant follows the explicit exception above. Never guess or
  hard-code model identifiers and never rely on a target model's default effort.
- The Phase 4 loop is sequential and checkpointed per point; never batch.
- Decisions that are **mandatorily human** (public contract, schema, migration, billing/auth, test
  removal) gate; the rest proceed. Destructive git (merge commit, push, reset/repoint) needs explicit
  confirmation; never destructive non-interactively without a flag.
- Every rerere auto-resolved file is re-verified (treated as a conflict to review, not as resolved).

### Final Validation
- Zero conflict markers; pass/fail parity by identity green; test-inventory parity green (no unjustified
  deletion); merge commit compiles+passes (bisectable); harmonization (6.5) done with findings recorded;
  coherence bar met — **functional coherence OR registered debt** (no aesthetic harmonization required
  pre-commit); follow-ups recorded; `state.json` closed.

## Fallback Checklist

- **No symbol tool for the language** → convergence detector degrades to lexical (rare-identifier
  intersection); the README declares the degraded coverage ("lexical — may miss type/dynamic-dispatch
  couplings"). No silent caps.
- **Suite not hermetic / cannot run 3× locally** → parity falls back to changed-scope-only or CI-API
  baseline, marking baseline confidence.
- **No CI API available** → run scoped parity locally; record what was not covered.
- **No planning docs (epic/tasks/PR/CHANGELOG)** → silent fallback to `git log` + PR/MR metadata; never
  burn effort hunting for what does not exist.
- **No prior merge attempt** → skip that optional input; the method is unchanged.
- **Diff too large for semantic convergence** → degrade to dirstat + static import graph; emit a
  structured "too large" notice.
- **No `glab`/`gh` remote** → stop at the verified merge commit; MR/cover-page steps are skipped.

## Troubleshooting

- **Missing `<target-branch>`** → stop and ask for the branch to merge in; do not guess.
- **Missing dependency**: Git absent → hard stop (Git is mandatory). `gh`/`glab` absent → CI-baseline
  fallback unavailable; use local scoped parity and note it. tree-sitter/ctags/LSP absent → lexical
  convergence with the declared degradation. Test runner not detected → `discover-toolchain.sh` asks the
  user for the test/build/lint commands.
- **`git merge-base` ambiguous (criss-cross)** → `freshness.sh` reports all bases; pick with confirmation.
- **In-progress merge already present** → use `--resume` (re-hydrates `state.json` + invariants + rerere).

## Prerequisites

- Write access to the repo and a clean working tree (a dedicated worktree is created for the experiment).
- Git installed. No additional services required for the core (Phases 0–6); optional tooling improves
  fidelity/cost as listed in `compatibility`.
