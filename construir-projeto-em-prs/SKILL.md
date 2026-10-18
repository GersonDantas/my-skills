---
name: construir-projeto-em-prs
description: Deliver projects and multi-part changes through small PRs, using subagents for focused research and independent review, evidence for findings, and authorized integration. Use for accelerated development with agents and implementation, review, and correction cycles; trivial changes do not need this workflow.
---

# Build a Project Through PRs

Deliver the requested behavior in verifiable increments. Move faster through minimal scope, useful parallel research, and continuous review. Reuse existing tools, patterns, and teams; propose a new plugin, service, or role only when it solves a concrete need.

## Prepare the delivery

- Recover the objective, completion criteria, decisions, and authorizations from the conversation. Inspect project instructions, existing changes, and Git state before editing.
- State material assumptions and make a short plan covering behavior, dependencies, and validation for each increment. Ask only what prevents a safe decision.
- Split work by reviewable behavior, without imposing a PR count or line limit. Each increment should have a clear purpose and be verifiable against its stated base. Make dependencies between PRs explicit. Prefer sequential integration when a stack would only add propagation work and conflicts.
- Use the task's existing resources to track scope, dependencies, branch/PR, SHA, validation, pending findings, review, and authorizations. Avoid creating a new tracking system for a single delivery.

## Coordinate agents

This workflow calls for subagents for bounded research and independent review when they are available and permitted by the active policy. Use the configured roles; this skill does not install agents, change models, or expand permissions.

- The executor integrates the work. Consult the configured `consultor` role when team triggers apply. Parallelize independent questions; sequence decisions, proofs, corrections, and merges that depend on earlier results.
- Give each agent an objective, files or responsibility, minimum context, constraints, and expected evidence. Tell them others are working in the codebase and their changes must be preserved. Reuse already verified answers.
- If policy permits writing agents, assign non-overlapping ownership and isolate branches or worktrees when needed. With a read-only team, the executor implements and fixes while subagents research and review.
- Separate implementation authorship from review. An authorized writing agent or the executor can fix findings while preserving an independent reviewer. Independence means an agent other than the author of the change being reviewed. Requested read-only permission does not prove sandbox isolation.
- If required independent review is unavailable, continue safe work and report the limitation. Keep integration that depends on that review pending.

## Implement and validate

Understand the affected flow before choosing the smallest safe change. Use the standard library, native features, and existing patterns before adding dependencies or abstractions. Do not turn the delivery into a general project cleanup.

For bugs, reproduce the behavior when practical before fixing it. Validate the changed behavior first, including invalid input when relevant. Broaden checks only for a remaining risk, a new change, or a required gate. A coordination test with stubs does not prove real installation or integration; record the difference.

Documentation needed to understand or use an increment belongs in its PR. Update the README overview and status at the end to reflect the integrated result.

## Publish and review each increment

Respect existing authorizations by action and scope. Do not request an already authorized action again unless an explicit gate applies. This skill does not authorize publication, merge, team changes, or tag creation. It also does not add extra human approvals for already authorized local operations.

1. Check the diff and included files, preserve others' changes, and use Conventional Commits unless the repository has an explicit convention. Publish the PR only with applicable authorization. Describe the problem, final behavior, dependencies, and validation. Attach the PR to the task when the tool exists.
2. For remote review, use the installed `review-proof-inline` skill when available; read its instructions and needed references without copying or weakening its gates. If the user requires it and it is missing, report its absence and keep that review pending. Do not claim simulated compliance.
3. Send the independent reviewer the remote PR, exact base and SHA, criteria, and reading scope. Request two passes: behavior and compliance/simplification. Local prereview can catch issues early but does not replace review of the PR.
4. Treat findings as candidates. Verify the scenario, impact, and source of truth: the code actually executed, version, package, and hash used by the project. A tag, current documentation, or different environment may not represent that artifact. Seek independent counterverification for significant or disputed findings.
5. Follow the triage and proof authorizations required by the active review workflow. Reuse observed, verifiable evidence; counterevidence does not require new files. When new proof is needed, create the smallest useful one and try to reproduce the failure before fixing it. Record the actual result, including when the failure is absent, and preserve the approved strategy for storing evidence. If proof refutes a finding, return the counterevidence to the reviewer; do not change production code to satisfy a false positive.
6. For a confirmed finding and authorized fix, send the evidence to the person responsible for the correction. Validate the earlier failure and the fix, inspect the diff, and respect applicable stage, commit, and push gates, each within its authorized scope.
7. Request a new review of the remote HEAD after changes. Record the decision against its SHA. A subagent's technical approval is task evidence, not a formal review published to the provider; publishing comments or reviews is a separate action. If the project requires a formal review, fulfill that requirement too.

## Integrate and finish

Integrate only with applicable human authorization, approval of the current result, no blocking findings, and required checks passing. Authorization may have been granted earlier, such as "merge when the reviewer approves"; preserve its scope.

Check the base, remote HEAD, and check results immediately before merging. A later code change, conflict resolution, or new base affecting behavior requires validation and review of the affected result. Do not blindly reuse old approval. Use expected-SHA protection if the tool offers it.

After integrating a PR, carefully update the base of the next ones, resolve dependencies, and review resulting changes. At the end, check the integrated state, README, and working tree. Remove only your own disposable temporary resources, preserving proofs the user chose to keep.

Tags follow the project's release process and specific authorization. Do not move historical tags to represent new work. Report integrated or pending PRs, observed validations, real limits, and any exact blocker. Do not declare the delivery complete while a required step remains pending.
