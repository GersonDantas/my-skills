---
name: review-proof-inline
description: Review GitHub pull requests or GitLab merge requests through a gated workflow that resolves the review target, inspects the diff and repository context, validates candidate findings with the user, creates minimal failing proof tests for approved behavioral issues, obtains approval before every write operation, and publishes or edits inline review comments with stable proof links. Use when the user asks for a PR or MR code review with evidence, proof tests, inline comments, comment editing, or a review flow that must not publish unapproved findings.
---

# Review Proof Inline

## Objective

Review a GitHub PR or GitLab MR from source context through a published inline comment while preserving repository state and requiring explicit approval at each irreversible or externally visible step.

Support any organization and repository. Detect provider, host, repository, language, test conventions, commit rules, and review guidance from the request and local checkout instead of assuming defaults.

## Language

Write user-facing status, findings, proof reports, and review comments in the user's language unless the user requests another language. Preserve code identifiers, paths, API fields, commands, and repository-mandated test-title conventions.

## Non-Negotiable Gates

Never collapse these gates. Approval for one gate does not imply approval for a later gate.

1. Candidate gate: present every validated finding and draft inline comment; wait for explicit approval before changing files or publishing.
2. Proof gate: create and run only approved proof tests; show the failing result; wait for explicit approval before staging, committing, or pushing.
3. Versioning gate: show the exact proof files, destination ref, CI consequence, and proposed commit message; wait for explicit approval before commit and push.
4. Publication gate: rebase the comment on current remote context, show the final body and anchor; wait for explicit approval before creating, editing, or deleting a remote comment.

Treat instructions such as "review this" as read-only authorization. Require explicit verbs such as "prove", "commit", "push", "publish", "edit", or "delete" for the corresponding operations.

## Required Context

Resolve all of the following before reviewing:

- provider and host
- repository or project identifier
- PR number or MR IID
- canonical URL
- source and target branches
- current remote head SHA
- merge base or provider diff refs when required
- changed files and complete patch

Accept a PR/MR URL, a number plus repository context, or the current branch when the provider CLI can resolve exactly one open review. If resolution is ambiguous, stop and ask for the PR/MR URL. Never guess a repository from an unrelated checkout.

Treat the remote PR/MR as the source of truth. A supplied branch, local review report, or cached diff is supplemental context and must match the remote target and current head.

## Provider Selection

Detect GitHub or GitLab from the review URL first, then from the authenticated repository remote. Read [references/provider-operations.md](references/provider-operations.md) completely after selecting the provider and before calling its CLI or API.

For unsupported providers, perform a read-only review only when the diff is locally available. Do not improvise remote comment writes; explain the missing provider operation and request a supported API path or manual publication.

Verify the selected CLI exists and is authenticated before provider API calls. Do not install software, start an interactive login, or alter credential configuration without user authorization.

## Repository Instructions And Workspace Safety

Before analysis:

1. Locate applicable `AGENTS.md`, `CONTRIBUTING.md`, review guides, test guides, and commit conventions.
2. Inspect the working tree, current branch, remotes, and staged files.
3. Preserve unrelated user changes. Do not switch branches, reset, stash, clean, or overwrite files without explicit approval.
4. Prefer provider APIs for read-only context when the local checkout does not match the review head.
5. Use a separate worktree or another isolated checkout for proof work when changing the current checkout would disturb user changes. Obtain approval before creating it if local policy requires approval.

Use a compatible generated review plan when one exists. Verify that its provider, repository, review number, and head SHA match. Otherwise build context from remote metadata, changed-file responses, the patch, and relevant surrounding code.

## Review Criteria

Apply repository-specific standards first, then these baseline criteria.

### Complexity

After behavioral review, run a deletion-first complexity pass. Look for dead code, unused dependencies, hand-rolled standard-library or native-platform behavior, speculative abstractions, single-implementation interfaces, configuration nobody changes, layers with one caller, and logic that has a materially shorter equivalent.

Classify each surviving complexity finding as `delete`, `stdlib`, `native`, `yagni`, or `shrink`. Record the exact location, what can be removed, its concrete replacement, and the estimated net line reduction. Reject aesthetic preferences and reductions that weaken correctness, security, accessibility, validation, error handling, or the smallest useful test.

### Production Code

- prioritize behavioral regressions, incorrect contracts, data loss, security flaws, concurrency errors, state leaks, and material performance risks
- trace inputs, state transitions, side effects, error paths, and downstream consumers across changed and unchanged code
- distinguish a root cause from a symptom or workaround
- reuse established helpers, services, abstractions, constants, and design-system primitives when their contract fits
- respect existing module boundaries and ownership
- reject dead state, unused effects, ignored results, unstable identity, and persistence that is only partially implemented
- verify authorization, validation, transaction, retry, and cleanup behavior at trust or failure boundaries
- avoid commenting on style unless it creates a concrete maintenance or correctness risk under repository rules

### Tests

- ask what real defect each new or changed test would detect
- establish expected behavior from requirements, contracts, docs, production usage, or explicit review context
- prefer exact outputs, invariants, error contracts, and mutation-sensitive assertions
- reject truthiness, existence-only assertions, broad snapshots, and `not.toThrow` as primary behavioral proof
- mock external boundaries, not the unit's own decisions
- control clocks and randomness; avoid arbitrary sleeps, shared mutable state, and order dependence
- do not mistake a test that reproduces current behavior for evidence that the behavior is correct

## Workflow

### 1. Resolve Remote Context

Fetch metadata, changed files, patch, and current head. Record a compact context ledger containing provider, repository, review number, URL, source, target, head SHA, base/diff refs, and fetch time.

If pagination, truncation, binary files, generated files, submodules, or large-file pointers make the diff incomplete, say so and retrieve the missing material before claiming complete coverage.

### 2. Build The Review Map

Summarize scope, touched domains, high-risk boundaries, generated or vendored files, and files that must be read together. Read relevant callers, consumers, schemas, types, tests, configuration, and migrations outside the patch when needed to validate behavior.

Use one cohesive pass for a small change. For a large or cross-cutting review, use staged passes:

1. context and dependency map
2. specialized passes by behavior or subsystem
3. validation and duplicate removal
4. consolidated findings

Include the complexity pass in either mode. Correctness findings take priority, but validated complexity findings belong in the same consolidated candidate list.

Do not expose speculative intermediate findings as final results.

### 3. Validate Findings

For every candidate:

1. Identify the exact changed diff line suitable for an inline anchor.
2. State the objective observation without guessing intent.
3. Trace the concrete failure scenario and affected caller or user.
4. Check surrounding and historical code for a contract that disproves the concern.
5. Determine whether a minimal automated proof is practical.
6. Reject duplicates, pure preferences, unsupported possibilities, and issues outside the changed behavior unless the change activates them.

Assign severity only from impact and likelihood. Do not inflate severity to make a finding persuasive.

### 4. Candidate Gate

Present the complete consolidated list. For each finding include:

- severity and concise title
- target file, changed line, and diff side
- objective observation
- concrete risk or regression path
- violated contract or criterion
- draft inline comment
- proof plan, or why an automated proof is not useful

For a complexity finding, also include its classification, proposed replacement, and estimated net line reduction. Do not require a failing proof test when the issue is maintainability rather than behavior.

If no finding survives validation, report that result with the coverage limits. Do not invent a comment to justify the review.

State that no file was changed and no remote comment was published. Wait for the user to approve all, approve selected items, request revisions, or reject them.

### 5. Create Minimal Proofs

For each approved behavioral finding, use an installed proof-test skill when available and applicable. Otherwise apply this embedded protocol:

1. Translate the finding into one observable expected behavior.
2. Choose the lowest useful level: unit, integration, then end-to-end.
3. Write the smallest test that fails for the claimed reason on the reviewed head.
4. Avoid production-code changes.
5. Run the narrowest command that executes the proof.
6. Confirm that the failure message and actual value demonstrate the approved finding rather than setup, environment, or unrelated failures.

Do not create a proof when the risk is configuration-only, security-sensitive to reproduce, destructive, flaky, prohibitively expensive, or already demonstrated by a stronger existing test. Explain the alternative evidence.

If the user approves a finding but declines proof work, or no useful proof is practical, skip the proof and versioning steps. Preserve the evidence limitation in the final draft and proceed to comment preparation only when publication was requested.

### 6. Proof Gate

Show:

- proof file and relevant line
- exact command run
- observed failing assertion or error
- why that failure proves the approved finding
- files changed by the proof
- any environment limitation

State that nothing was staged, committed, pushed, fixed, or published. Wait for explicit approval. If rejected, revise or remove only rejected proof work, rerun the narrow command, and return to this gate.

Treat a production fix as a separate implementation request. Never mix proof and fix changes without explicit authorization and separate scope.

### 7. Choose Proof Publication Strategy

A deliberately failing test can break the review branch CI. Before versioning each proof, ask the user to approve one strategy:

1. Separate proof branch or ref, preferred when remote policy permits it. Keep the reviewed source branch unchanged.
2. Review source branch, only when the user explicitly accepts the CI impact and has authority to update it.
3. Local-only proof. Do not claim a navigable remote proof link in the final comment.

Let the choice differ between proofs when their CI or branch impact differs. Never infer it from an earlier approval.

For a separate proof ref, derive it from the reviewed head so the failure remains attributable to the exact code reviewed. Avoid rewriting or force-pushing existing refs.

### 8. Versioning Gate

Read repository commit instructions. Use a specifically requested or repository-mandated commit-message skill when available; otherwise infer the style from repository guidance and recent history.

Show:

- exact files proposed for staging
- unrelated staged or unstaged files that will be excluded
- destination branch/ref and remote
- expected CI consequence
- proposed commit message

Wait for explicit approval before staging, committing, or pushing. Commit only approved proof files. Never use force push. If commit or push fails, stop and do not publish the comment.

After a successful push, resolve the immutable commit SHA and exact proof line. Build a provider-specific `blob/<commit>` link, never a local path or mutable branch link.

### 9. Prepare Final Comment

Re-fetch remote metadata, current head, diff refs, and changed files. Confirm that the approved inline anchor still exists in the current diff. Revalidate the finding if the reviewed code changed.

Keep each comment concise and human:

- objective observation
- concrete impact
- proof result
- immutable proof URL and short proof commit, when remotely available

If the proof changes the conclusion, severity, tone, or scope, return to the candidate gate. If only the immutable link was added, show the complete final comment at the publication gate.

### 10. Publication Gate

Show each final body with provider, repository, review number, file, line, diff side, current head SHA, and whether the operation is create or edit. For edits, require the provider comment identifier unless it is already present in the current run's ledger.

Wait for explicit approval. Then publish exactly the approved operations, one inline thread per finding. Never replace an inline comment with a general review note merely because the API anchor failed.

After each operation, verify the returned identifier, URL, body, path, line, side or position, and current association. Record these in the comment ledger to prevent duplicates.

If the provider rejects a stale position, re-fetch context and return to this gate whenever the anchor or body changes.

### 11. Edit Or Delete Existing Comments

Require explicit approval and exact remote identifiers. Fetch the existing comment first and show the before/after body for edits. Show the exact target and recovery implications for deletion. Never create a duplicate when the instruction is to edit.

### 12. Close

Report concisely:

- review target and head reviewed
- context source and coverage limits
- approved and rejected findings
- proof files, commands, and observed results
- proof ref, commit, and push status
- created, edited, or deleted comment links
- any uncommitted proof files or intentionally failing state left locally
- estimated net lines removable from approved complexity findings

Do not say the workflow is complete if a required approval, push, verification, or publication failed.

## Operational Invariants

- Never publish before candidate approval.
- Never version proof work before proof approval.
- Never push a failing proof to the source branch without explicit CI-impact approval.
- Never publish a proof URL until the exact file exists at the cited immutable remote commit.
- Never anchor against cached line numbers after the head changes.
- Never include production fixes or unrelated changes in a proof commit.
- Never treat silence or approval of an earlier gate as approval of a later write.
