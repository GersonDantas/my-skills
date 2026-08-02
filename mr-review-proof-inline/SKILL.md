---
name: mr-review-proof-inline
description: Review GitHub Pull Requests in laudite/laudite with the generic gated proof-and-inline-comment workflow plus the complete bundled Laudite criteria, exact Figma validation when applicable, minimal approved proof tests, Laudite commit rules, and user-approved proof publication strategy. Use for Laudite PR reviews that require evidence, proof tests, or inline GitHub comments. Require a PR number or URL; a branch alone is insufficient.
---

# Laudite PR Review Proof Inline

## Base Protocol

Read and follow `$review-proof-inline` completely before reviewing. Use its GitHub section in `references/provider-operations.md` for remote reads and comment operations. This skill defines Laudite-specific overrides; when the two conflict, use this skill.

Keep the four base gates separate: candidate, proof, versioning, and publication. Approval at one gate never authorizes the next gate.

## Laudite Context

Use these fixed defaults:

- repository: `laudite/laudite`
- provider and CLI: GitHub and `gh`
- proof skill: `$test-proof`
- commit-message skill: `$get-commit-message-laudite`
- design skill: `$figma`
- criteria snapshot: `references/code-review-criteria.md`

Require a PR number or GitHub PR URL. Accept a branch, `code-review-central.md` path, or known review-comment `remoteId` only as supplemental context. If only a branch is supplied, ask for the PR number or URL.

Write all user-facing status, findings, reports, and GitHub comments in Brazilian Portuguese. Preserve code identifiers, commands, paths, API fields, and repository test-title conventions; keep `describe`, `it`, and `test` titles in English.

Treat the remote PR as the source of truth. Resolve its number, URL, source branch, target branch, current `headRefOid`, changed files, and complete patch before analysis. A supplied or generated review must match that PR and head.

## Review Context And Criteria

Before analyzing the diff:

1. Read `references/code-review-criteria.md` completely. Use it as the sole runtime source for the 95 official Notion criteria and supplemental Laudite criteria; do not query Notion by default.
2. State the snapshot source date in the first review status update.
3. Treat `AGENTS.md`, `CLAUDE.md`, repository guidance, and generated review files as supplemental. They may clarify but never replace or weaken the snapshot.
4. Prefer a compatible local review-plan generator. Reuse an existing result only after confirming the PR and head. Open `code-review-central.md` first when present; otherwise use the remote metadata, changed-file response, patch, and relevant surrounding code.

Review in two passes:

1. Behavioral pass for regressions, side effects, state leaks, security, performance, concurrency, persistence, error contracts, and requirement coverage.
2. Compliance pass for every applicable bundled criterion, including the base protocol's deletion-first complexity review.

Maintain an internal ledger containing criterion name, applicable files or `N/A` with reason, inspected evidence, and result as `pass`, `finding`, or `uncertain`. Read the complete supporting criterion before proposing a finding. Record applicability before dismissing a criterion, never manufacture findings for `N/A`, and investigate repository patterns before classifying an ambiguity as `uncertain`.

Use one cohesive review for a small PR and the base staged review for a large or cross-cutting PR. Present only consolidated, validated candidates.

## Figma

Apply Figma only when changed UI behavior or styling makes `Conformidade com o Design` applicable.

1. Find the primary Figma URL in the request, PR, or linked task. If the change is Figma-backed but no URL exists, ask for it.
2. Require the exact frame, layer, or variant with a node ID. Do not inspect an entire file or page without approval.
3. Read and follow `$figma` completely. For each unique exact node, use one `get_design_context` call and one `get_screenshot` call. Use metadata, variables, assets, mappings, or extra nodes only when needed to validate a concrete candidate or recover truncated context.
4. Deduplicate node IDs. Explain the expected expansion and obtain approval before inspecting a broad frame, page, multiple variants, or many subnodes.
5. If the source is invalid, inaccessible, missing its node ID, deleted, timed out, or unavailable, ask before using another Figma link, screenshot or export, task or PR criteria, or current implementation. Record the approved fallback and limitations; no fallback proves exact Figma parity.
6. When design conformity is inapplicable, make no Figma call and record `N/A` with reason.

## Candidate Gate

Follow the base candidate gate. For every candidate, include the target file and diff line, objective observation, concrete risk, exact official or supplemental criterion name, draft inline comment, and proof plan when useful. Complexity findings must also include their base classification, replacement, and estimated net line reduction.

Do not modify files, run proof commands, refine final comments, or perform GitHub writes before explicit approval. Continue only with approved candidates.

## Proof Gate

For each approved behavioral finding that benefits from automation:

1. Read and follow `$test-proof` completely.
2. Create the smallest failing test that proves observable behavior for the claimed reason, without changing production code.
3. Prefer unit, then integration, then end-to-end. Use strong oracles, mock only external boundaries, control time and randomness, and place new support mocks in a nearby `mocks` directory.
4. Run the narrowest useful command and record it.
5. Show the proof file and line, failing assertion, changed files, and why the failure proves the finding. State that nothing was staged, committed, pushed, fixed, or published, then wait for approval.

Treat a production fix as a separate request. Revise or remove only rejected proof work.

## Proof Publication Strategy

After the user approves each proof, present these choices with their CI consequences and let the user choose for that proof:

1. Separate proof branch or ref, recommended when the intentional failure would break or pollute the PR CI.
2. PR source branch, allowed only when the user explicitly accepts its CI and branch impact.
3. Local-only proof, which cannot produce a navigable remote proof link.

Do not infer one choice from an earlier proof or from approval at another gate. Derive any separate proof ref from the reviewed head and never force-push.

## Versioning Gate

After the strategy is selected:

1. Read and follow `$get-commit-message-laudite` completely.
2. Commit only approved proof files. Exclude production fixes, unrelated changes, generated logs, screenshots, and local stack artifacts.
3. Preserve existing changes. If unrelated files are staged, stop and ask the user to correct or approve the staging set.
4. Because `$get-commit-message-laudite` must not run `git add`, ask the user to stage only the approved proof files when none are staged.
5. Show staged files, destination ref, CI consequence, and generated commit message. Wait for explicit confirmation before `git commit --no-verify` and push.
6. After push, resolve the immutable commit SHA and proof line, then build the GitHub `blob/<commit>/<path>#L<line>` URL.

If commit or push fails, do not publish. Report the failure and preserve the local state for the user's decision.

## Publication Gate

Follow the base publication gate and GitHub provider operations. Re-fetch the PR head and changed files, confirm the diff anchor, add the immutable proof URL when available, and show the complete final Brazilian Portuguese comment for approval.

Publish or edit one inline comment per approved finding. Require a known `remoteId` for edits, fetch an existing comment before editing or deleting it, and never substitute a general PR comment when an inline anchor fails. Return to validation whenever the anchor, conclusion, tone, or scope changes.

## Close

Report concisely the PR and head reviewed, context and criteria snapshot used, Figma source and limitations when applicable, approved findings, proof files and commands, selected publication strategy, proof commit and push status, remaining local proof state, estimated net removable lines from approved complexity findings, and links to created, edited, or deleted comments.

Do not claim completion while any required approval, push, verification, or publication remains unresolved.
