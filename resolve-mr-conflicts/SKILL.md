---
name: resolve-mr-conflicts
description: Resolve merge conflicts for merge requests in Git worktrees. Use when Codex is asked to continue or perform an MR merge/rebase conflict resolution, preserve target-branch behavior, keep a conflict-resolution log, validate with focused tests and lint, avoid commit/push unless explicitly authorized, and add tests when no existing merge/change covers the conflict behavior and tests are practical.
---

# Resolve MR Conflicts

## Operating Rules

- Treat the current worktree as shared with the user. Never revert unrelated edits and never use destructive Git commands unless the user explicitly asks.
- Do not commit or push unless the user explicitly authorizes it.
- Prefer resolving by preserving the target branch's behavior unless the user gives a different decision.
- Keep a running log. If the user names a path, use it; otherwise create `/private/tmp/mr-<id>-conflict-resolution-log.md` when an MR id is known, or `/private/tmp/mr-conflict-resolution-log.md`.
- Stage files that resolve merge conflicts so `git diff --name-only --diff-filter=U` becomes empty. Do not stage unrelated unstaged user edits.

## Workflow

1. Inspect the merge state:
   - Run `git status --short`.
   - Run `git diff --name-only --diff-filter=U`.
   - Run a strict marker scan such as `rg -n '^(<<<<<<<|=======$|>>>>>>>)( |$)'`.
   - Use `git ls-files -u` to understand stages before choosing a side.

2. Classify each conflict:
   - Simple marker conflict: edit the file to combine or choose sides according to the MR instructions.
   - `DU` or missing-side conflict: identify whether stage 2 or stage 3 represents the target branch, then keep the requested side.
   - Generated artifact: regenerate it through the project's normal command after code conflicts are resolved.
   - External dependency in tests: verify whether the referenced file exists in the target branch. If it does, restore the missing target-branch support files instead of weakening the test.

3. Preserve known behavior:
   - Before touching a conflicted file, search for nearby tests and target-branch implementation details.
   - If a file has no conflict markers and the user asked not to alter it, only inspect/validate it unless tests reveal a missing target-branch behavior needed to complete the merge.
   - When tests expose a missing target-branch behavior, apply the smallest patch that restores that behavior and record the reason in the log.

4. Add tests when needed:
   - If no existing merge, test, or target-branch change already covers the behavior at risk in a conflict, and it is practical to test locally, add or update focused tests.
   - Keep these tests narrow: one behavior per conflict decision, using existing test patterns.
   - Do not create broad or brittle tests just to satisfy coverage. If testing is impractical, record why in the log.

5. Validate:
   - Run `git diff --name-only --diff-filter=U` and require no output.
   - Run `git diff --check` and `git diff --cached --check`.
   - Run strict conflict-marker scan. If the user's literal marker command reports decorative `====` lines, explain the distinction and still run the strict scan.
   - Run focused tests for the touched behavior first, then broader related tests when risk justifies it.
   - Run lint on touched code. If configured ignore rules make a directory argument fail, rerun with explicit files or `--no-ignore` for the relevant files and record both outcomes.

## Log Contents

Keep the log concise but complete:

- Date and MR id if known.
- Conflict decisions by file.
- Any restored target-branch files or generated artifacts.
- Any added/updated tests, especially those added because no existing merge covered the conflict.
- Commands run and pass/fail outcomes.
- Known residual risks, ignored decorative marker matches, and unrelated user edits left untouched.

## Final Response

Report:

- Whether conflicts are fully resolved.
- Important files changed or restored.
- Tests/lint/checks run and their results.
- Any command that could not be run or needed an adjusted invocation.
- Explicitly confirm no commit/push was done when that was part of the request.
