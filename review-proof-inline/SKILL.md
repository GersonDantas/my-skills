---
name: review-proof-inline
description: Review GitHub pull requests or GitLab merge requests with two-pass analysis, independent candidate verification when available, human triage, optional failing proofs, and separately approved inline publication. Use for evidence-based PR/MR review or for proving, editing, or publishing review findings.
---

# Review Proof Inline

Review the remote PR or MR as the source of truth. Support any organization and repository. Detect provider, host, language, criteria, test and commit conventions from the request and repository; never import another organization's rules, tools, language, tracker, or design system as defaults.

Write user-facing updates, findings, reports, and comments in the user's language. Preserve identifiers, paths, commands, and repository-mandated test titles.

## Authorization boundaries

“Review” authorizes read-only work. A classification or approval at one gate never authorizes another operation. Obtain separate, explicit authorization for:

1. Resolving an existing remote review thread.
2. Creating or changing local proof files.
3. Staging approved files, committing, and pushing, each as its own action.
4. Creating, editing, or deleting each set of remote inline comments after a current-head preview.
5. Creating or updating tracker items, if the user separately requests that integration.

Never infer authorization from silence, a prior “approve all,” a triage label, or an earlier preview. If the user performs staging, commit, and push manually, accept their explicit report as a report of completed actions, not permission for agent writes; verify the remote commit and proof link before citing it. A production fix is a separate implementation request.

## 1. Resolve context and earlier discussions

Resolve provider and host, repository, PR number or MR IID, canonical URL, source and target branches, current remote head, base or diff refs, changed files, and complete patch. Accept a URL, a number with repository context, or the current branch only when it identifies exactly one open review. Ask for a URL if ambiguous; never guess from an unrelated checkout. Record fetch time and a compact context ledger. Retrieve truncated or paginated material before claiming complete coverage.

Read [provider-operations.md](references/provider-operations.md) for the detected provider before its CLI/API calls. Confirm that the CLI exists and is authenticated. Do not install software, log in interactively, or change credentials without authorization. For unsupported providers, review a locally available diff read-only and explain why remote publication is unavailable.

Read [previous-threads.md](references/previous-threads.md) before diff analysis when the provider supports resolvable review threads. Inventory prior inline discussions, assess unresolved items against the current head, and seek independent approval only for exact threads ready to resolve. Continue the review if the user declines. Do not infer a fix from a reply or an outdated marker.

Before analysis, read applicable `AGENTS.md`, `CONTRIBUTING.md`, review and test guides, and commit conventions. Inspect branch, remotes, working tree, and staging area. Preserve unrelated changes. Do not switch branches, reset, stash, clean, or overwrite files without authorization. Prefer remote read APIs when the checkout differs from the reviewed head. A generated review plan is usable only when provider, repository, review number, and head match.

## 2. Review and verify

Read [review-method.md](references/review-method.md). Apply repository rules and the baseline criteria there. Before diff analysis, ask once whether the user has supplemental criteria for this run. Apply only exact criteria the user supplies or identifies and explicitly approves; otherwise proceed. Read each approved source completely, record its source and snapshot date when it may drift, and state that date in the first review update. Do not silently persist supplemental criteria into this skill.

Complete behavior and compliance passes. Include a deletion-first complexity check. For a small change, use one cohesive pass. For a broad change, map dependencies, inspect slices by behavior, collect all results, then deduplicate. Delegate slices only when applicable agent instructions permit delegation; keep each slice's context bounded. Finish all slices before human triage. Do not stop at an internal progress report or ask the user to continue.

Validate candidate findings against callers, guards, requirements, and a precise changed diff line. Before presenting candidates, use a fresh independent verifier when permitted and available; follow the blind projection and fallback in [review-method.md](references/review-method.md). Verification is read-only and does not replace human triage. Reject unsupported, duplicate, pre-existing, or purely aesthetic concerns. Report verification limitations honestly.

When changed UI behavior or styling makes design conformity applicable, use the exact design target and the relevant design skill or tool. Ask for a missing source or target. Do not inspect broad frames or variants without approval. If exact design evidence is inaccessible, obtain approval before using a fallback and record its limits. Otherwise record design as `N/A` with reason.

## 3. Human triage

Present the complete consolidated candidate list with stable handles `[1..N]`. For each, show severity; file, changed line and side; observation; concrete risk; contract or criterion; draft inline comment; proof plan or why none helps; brief possible solution; and checks performed. For complexity, add `delete`, `stdlib`, `native`, `yagni`, or `shrink`, a concrete replacement, and estimated net lines removable. Offer solution detail if useful.

Accept prose, partial selection, and batches such as “rework 1,3 / debt 2 / discard 4.” These labels classify findings only: `rework` means the user wants correction considered before merge, `debt` means valid but non-blocking, and `discard` removes the candidate. They do not submit a blocking review, create a card, change code, or publish a comment. If no finding survives, report coverage limits and stop without inventing comments. State whether any local file or remote comment changed.

For selected findings, ask which behavioral items to prove. A user may approve a finding but decline proof. Maintainability findings do not require a failing test. After triage, follow [proof-and-publication.md](references/proof-and-publication.md) for proof, Git, current-head previews, publication, edits, and closure.

## Invariants

- Never create a proof before approval of its exact finding and proof work.
- Never stage before proof review and staging approval; never infer commit or push approval from staging approval.
- Never push a deliberately failing proof to the review source branch without explicit acceptance of its CI impact.
- Never cite a mutable branch or a proof file absent from the exact remote commit.
- Never publish before a new approval of the final body, anchor, operation, and current head.
- Never replace a failed inline anchor with a general comment or duplicate an intended edit.
- Never mix production fixes, unrelated changes, or generated artifacts into a proof commit.
