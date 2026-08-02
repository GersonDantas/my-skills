---
name: test-proof
description: Use this skill to prove a user-reported inconsistency or code review finding with the smallest useful failing test before changing production code. Trigger when the user reports inconsistent behavior, asks to prove a review finding with a test, or needs a failing test that demonstrates a bug; apply the built-in code-review and test-review criteria, run the narrowest test command, and stop at the proof unless the user explicitly asks for the fix.
---

# Test Proof

## Overview

Use this skill to convert an inconsistency into a small, reviewable failing test aligned with the repository's review standards.

Return all user-facing output in Brazilian Portuguese, including status updates and the final proof report. Keep code identifiers, commands, file paths, API fields, and test titles in their original language; `describe`, `it`, and `test` titles must remain in English.

Required flow:

1. Apply the built-in proof criteria before writing any test.
2. Define the expected behavior from a requirement, contract, production usage, documentation, or explicit review context.
3. Write the smallest failing test that proves the inconsistency for the right reason.
4. Run the narrowest useful test command.
5. Stop at the proof and report the result, unless the user explicitly asks for the production fix.

## Built-In Proof Criteria

Before writing tests, apply these criteria directly. Do not depend on repository-local review guidance files being present in the current branch.

Code and support criteria:

- review support code for behavioral regressions, side effects, state leaks, security issues, and performance risks
- reuse existing test helpers, factories, fixtures, components, services, store actions, constants, and utilities before adding new ones
- keep support code in established folders and responsibility boundaries
- avoid unnecessary hardcoding when a repository constant, helper, fixture, or pattern exists
- keep code names in English and consistent with the codebase
- avoid dead fixtures, mocks, parameters, or helpers that are not consumed
- place temporary local mocks in a nearby `mocks` folder and mark them with a `#TODO` comment when they are temporary

Test criteria:

- treat tests as false positives until they show real defect-detection signal
- validate intended behavior from requirement, contract, documentation, production usage, or explicit review context
- ask: "what real defect would this test detect?"
- prefer strong oracles: exact outputs, invariants, error contracts, or mutation-killing evidence
- do not rely on `toBeTruthy`, `toBeDefined`, broad snapshots, or `not.toThrow` as primary proof
- mock only external boundaries such as network, database, filesystem, clock, and third-party services
- avoid arbitrary sleeps, uncontrolled real time, unseeded randomness, shared global state, and implicit order dependency

## Behavior Rules

- Treat current behavior as suspicious until the expected behavior is confirmed by a requirement, contract, documentation, production usage, or explicit review context.
- Never write a test that only freezes current behavior without validating that it is correct.
- If the requirement is weak or ambiguous, state the gap before turning the inference into a test.
- Keep the proof scoped to the reported inconsistency or review finding.

## Test Rules

- Start at the smallest useful level: unit first, integration only when needed, and e2e only as a last resort.
- Make each test answer: "What real bug would this catch?"
- Write `describe`, `it`, and `test` titles in English.
- Assert behavior, not implementation details.
- Prefer strong oracles. Avoid `toBeTruthy`, `toBeDefined`, broad snapshots, and "does not throw" as the primary proof.
- Make the test fail for the right reason and catch a plausible defect, not merely execute code.
- Mock only external boundaries such as network, database, filesystem, clock, or third-party services.
- Do not mock business rules, validators, pure helpers, or internal logic the test is meant to validate.
- Place new local support mocks in a nearby `mocks` folder, following repository patterns.
- Keep tests deterministic: avoid arbitrary sleeps, real time without freezing, unseeded randomness, and global order dependencies.
- When testing errors, validate the error contract and resulting state, not only that an error occurred.

## Support Code Rules

- Reuse existing test helpers, factories, fixtures, and infrastructure before creating new support code.
- Keep names clear and consistent with the codebase.
- Add a `#TODO` comment only when a new mock is temporary or strictly local to the proof.
- Avoid unnecessary hardcoding when a repository constant, helper, or pattern exists.
- Do not add `console.log`, unnecessary comments, avoidable duplication, or files in inappropriate folders.
- In frontend code, preserve project patterns for store access, backend calls, and responsibility boundaries.

## Scope Rules

- Do not fix production code by default.
- Do not make the test pass by weakening the proof.
- If the proof requires a material test-design change, keep it minimal and tied to the validated bug.

## Output

Keep the result short and include:

- inconsistency translated into a test
- file changed
- command run
- observed result
- criterion used for the expected behavior, when relevant
- open assumption, if any

Write this report in Brazilian Portuguese.

## Lessons Learned

<!-- Update after each execution -->
<!-- Format: - [YYYY-MM-DD] Issue: Description | Solution: What was done | Prevention: How to avoid -->
- [2026-07-16] Issue: A user-configured voice key was interpolated into a prefix regex and only failed when another key forced the comparison | Solution: Proved the exact `Nothing to repeat` error with two keys, then replaced regex matching with literal prefix matching | Prevention: Include multiple configurable inputs in proofs for short-circuited comparisons and treat user-facing labels as literals unless regex syntax is an explicit contract
- [2026-07-16] Issue: An ignored local test kept failing after switching to the base branch and looked like a tracked branch regression | Solution: Verified both the JavaScript null-guard defect and that Jest discovers ignored files left in the working tree | Prevention: Check `git ls-files` and `git check-ignore` before attributing a local test failure to a branch or its CI suite
- [2026-07-27] Issue: An unsupported `dotenv` option silently left conflicting shell values in place for a repair script | Solution: Used the installed dependency with only the filesystem boundary mocked and asserted exact `.env.script` precedence | Prevention: Verify option support against the locked dependency version and add conflict tests for safety-critical environment loading
- [2026-07-28] Issue: A first-click visibility toggle inferred its result by rereading a preference while a fixed-height editor layout kept reserving hidden tab space | Solution: Proved the missing explicit toggle state and the 42 px bottom gap, then passed the desired state through the event and adopted a flex-growing content window | Prevention: Make persistence-backed controls emit their desired final state and validate responsive fill by comparing visible boundaries rather than assuming equal internal heights
