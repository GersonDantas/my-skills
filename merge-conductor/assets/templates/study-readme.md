# Merge study: `<incoming-branch/theme>` ↔ `<base-branch/theme>`

> Synthesis README — the **non-negotiable** artifact (never dropped, even under `--lite`).
> It is where the method's value concentrates: attack order, the golden list, the global invariants, the gates.
> The per-file docs shrink in lite mode; this file does not.

**Study date**: `<YYYY-MM-DD>`

## What this is

`<One paragraph: an uncommitted merge draft between the two initiatives, with a per-conflict deep study. Each `NN-*.md` carries: both sides' business rules, hunk-by-hunk analysis, semantic conflicts in related auto-merged code, a step-by-step resolution plan, and validation.>`

| | |
|---|---|
| Draft worktree | `<absolute path to the dedicated worktree>` |
| Draft branch | `<merge/...-draft>` |
| Side A (ours / HEAD) | `<ref>` @ `<sha>` — `<initiative: what it is>` |
| Side B (theirs / MERGE_HEAD) | `<ref>` @ `<sha>` — `<initiative: what it is>` |
| Merge-base | `<sha>` (`<date>`) `<; note --all if criss-cross / multiple bases>` |
| Conflicts | `<N>` files (`<x content + y modify-delete + ...>`) |

`<State whether both branches were confirmed == origin at study time, and any fast-forward done first.>`

> ⚠️ **Prior merge attempt** (optional input — omit this block if none exists): branch/SHA `<ref>` (`<date>`) `<what it broke>`. Treat it as a **hostile reference**: study what it got wrong, do not import its resolutions. `<the one point, if any, where it was correct>`.

## Attack order

Resolve junction files before their consumers; keep a flow's co-changes next to the junction that generates them.

| # | File | Risk | Altitude | md |
|---|------|------|----------|-----|
| 1 | `<path>` | `<high/med/low>` — `<one-line why>` | `<DEEP/STANDARD/TRIVIAL>` | [<NN>](<NN>-*.md) |
| 2 | `<path>` | `<...>` | `<...>` | [<NN>](<NN>-*.md) |
| ... | `<...>` | `<...>` | `<...>` | `<...>` |

## Golden list — semantic conflicts & co-changes OUTSIDE the conflicted files

> Auto-merge "clean" ≠ correct. The dangerous pattern: *a junction file resolved to one side + consumers merged from the other*, in files that never collided. These fixes are **mandatory even with no conflict marker**. Each item names the why and the source md.

1. **`<path:line>`** — `<what auto-merged, why it is wrong post-merge, user-visible symptom, the fix>`. *(md <NN>)*
2. **`<path:line>`** — `<duplicated schema key / consumer of a reshaped payload / orphaned dead code / missing registration>`. *(md <NN>)*
3. `<...>`

**Pre-existing (NOT a regression of this merge; cleanup tickets, not blockers)**: `<list orphans/duplications that already existed on both sides>`.

## Post-merge invariants (what must stay true)

`<Bullet list aggregated from the DEEP studies' §4. Each = a fact the merged tree must preserve; phrase as a must. These re-hydrate on `--resume` alongside state.json.>`

- `<invariant — and what breaks if it regresses>`
- `<...>`

## Validation gates (before committing the merge)

The two parity axes + builds. Both axes run against the **pristine parents**, not the merged tree alone.

1. **Pass/fail parity by test identity** — failing `test-id`s in the merged tree ⊆ union of the parents' failures (flake re-run; new tests baselined against the side that introduced them).
2. **Test-inventory parity** — merged tree's test files/cases ⊇ union of both parents, minus **justified** removals. Catches "green because the tests that would fail were deleted."
3. **Syntax** — `node --check` / equivalent on every hand-resolved file (the syntactic seams).
4. **Lint** — full `<scope A>` + `<scope B>` (catches duplicated keys / orphaned consts the auto-merge left).
5. **Builds** — `<each affected build, incl. any separate bundler the golden list touches>`.
6. **E2E / smoke** — `<the end-to-end suites + a manual smoke of BOTH initiatives' core flow>`.

## Open decisions (consolidated)

`<The genuine product/architecture decisions surfaced across all DEEP studies, with the human's answer once given. Each affected md carries its own "Decisions" section with the consequence in the plan.>`

1. **`<decision>`** — `<resolution + the test/code consequence>`. *(md <NN>)*
2. `<...>`

`<Minor decisions resolved by the embedded recommendation in each md: `<one-line list>`.>`

## How to operate the draft

- **Resume the study**: the worktree holds the merge in progress; `UU` files have markers on disk. Do **not** `git add`/`commit` until the plans are approved (or run with `--resume`, which re-hydrates `state.json` + these invariants + the hardened rerere).
- **Abort the draft** (if needed): `git merge --abort` inside the worktree — does not affect the original branches.
- **Apply for real**: follow the attack order above, one file at a time, each with its md as the guide, checkpointing per point, validating the gates at the end.
