---
name: review-go-proof-inline
description: Review GitHub pull requests or GitLab merge requests that change Go code, tests, modules, or Go-facing behavior, using the approval and proof workflow from review-proof-inline plus conditionally loaded official Go criteria. Use for Go PR/MR reviews that require validated findings, minimal failing proofs, gated versioning, or approved inline comments.
---

# Review Go Proof Inline

## Base protocol

Read and follow `$review-proof-inline` completely before any provider call. Treat its remote context rules, repository safety, criteria ledger, candidate gate, proof gate, versioning gate, publication gate, and close report as authoritative.

Apply this skill only as a Go-specific criteria layer. Do not copy, weaken, combine, or bypass any base gate. Ask about supplemental criteria beyond the built-in Go sources below as required by the base skill.

## Confirm Go scope

After resolving the complete remote diff, verify that it changes human-written Go code, Go tests, module or workspace files, code generation inputs, or behavior consumed by Go packages. If not, continue with `$review-proof-inline` alone and record the Go layer as `N/A`.

Read the repository's Go version, toolchain directive, local instructions, lint configuration, and established package patterns before judging idioms. Apply repository rules first when they are stricter or intentionally different.

## Gate official documentation

Evaluate every gate from the diff and repository context without opening the linked page. Fail closed: when a gate does not pass, do not fetch that source and record it as `N/A` with the reason.

When a gate passes, open only that official page, read it completely before applying it, and record its URL, access date, available version or update date, applicable sections, evidence, and result in the criteria ledger. Do not substitute summaries, search snippets, aggregate style pages, or third-party guides without explicit user approval.

| Source | Gate |
| --- | --- |
| [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) | Pass only when the reviewed behavior changes at least one human-written `.go` file. |
| [Go Test Comments](https://go.dev/wiki/TestComments) | Pass only when the patch changes `_test.go` files, a validated candidate concerns test behavior or coverage, or the user approves designing a proof test. |
| [Effective Go](https://go.dev/doc/effective_go) | Pass only when a candidate hinges on a core-language idiom or API construction question not settled by repository guidance or Go Code Review Comments. Apply only still-relevant core guidance; the document is not actively updated and does not cover newer features such as generics or modules. |
| [Go Fuzzing](https://go.dev/doc/security/fuzz/) | Pass only when the diff changes parsing or handling of untrusted input and fuzzing is materially relevant to a security, crash, invariant, or round-trip concern. |

If a source cannot be read completely, do not make a finding that depends on it. Mark the criterion `uncertain`, state the coverage limit, and continue with independently established behavioral evidence.

## Review Go behavior

Run the base behavioral pass first. Trace package callers and consumers, errors and wrapping, context propagation and cancellation, goroutine ownership and exit, channel closure, shared-state synchronization, resource cleanup, nil and zero-value contracts, aliasing and copying, public API compatibility, serialization, and module boundaries when applicable.

Then apply only the official sources whose gates passed. Treat formatting or naming as a finding only when repository rules require it or it creates a concrete correctness, API, documentation, or maintenance risk. Reject preferences and advice unrelated to changed behavior.

Keep the base deletion-first complexity pass. Prefer deletion, the standard library, concrete types, synchronous control flow, and existing package patterns when they preserve the contract. Do not propose an interface, helper, dependency, goroutine, configuration point, or abstraction without a demonstrated need.

## Validate minimally

Use repository-provided commands first. Otherwise run the narrowest applicable read-only checks, expanding only when risk justifies it:

1. Inspect formatting with `gofmt -d` for changed human-written Go files.
2. Run focused `go test` commands for affected packages.
3. Run broader tests or `go vet` only when the change scope, repository policy, or candidate requires them.

Do not change production code during review. For an approved behavioral proof, follow `$test-proof` through the base proof gate and preserve all later approvals.

## Report

At the candidate gate, identify the exact official source and section supporting each Go-specific finding. In the close report, list each documentation gate as passed or `N/A`, the access date of every opened source, toolchain and coverage limits, checks run, and all state required by `$review-proof-inline`.
