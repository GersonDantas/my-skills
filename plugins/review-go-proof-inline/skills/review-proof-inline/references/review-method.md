# Review and verification method

Use this reference during diff analysis and candidate validation. Keep a compact internal ledger: criterion, applicable files or `N/A` with reason, evidence, and `pass`, `finding`, or `uncertain`. Group passes when many criteria apply; record findings and uncertainties individually. Read the complete applicable repository or user-approved criterion before citing it. A review plan or supplemental guide may clarify authoritative rules but may not silently weaken them.

## Two passes

1. **Behavior:** trace inputs, state transitions, side effects, error paths, and downstream consumers through changed and necessary unchanged code. Check regressions, authorization, validation, data loss, security, concurrency, persistence, state leaks, cleanup, performance, and requirements.
2. **Compliance:** apply repository rules, tests, and approved supplemental criteria. Then check complexity by looking for dead code, unused dependencies, hand-rolled standard-library or native behavior, speculative abstractions, single-use layers, unused configuration, and logic with a materially shorter equivalent.

For complexity candidates, record exact location, removable code, concrete replacement, estimated net line reduction, and one of `delete`, `stdlib`, `native`, `yagni`, or `shrink`. Reject reductions that weaken correctness, security, accessibility, validation, error handling, or the smallest useful test. Avoid findings for style alone unless a repository rule and concrete maintenance cost support them.

Check tests against established behavior from requirements, contracts, docs, production usage, or explicit review context. Prefer exact outputs, invariants, error contracts, and mutation-sensitive assertions. Truthiness, existence-only assertions, broad snapshots, and `not.toThrow` do not by themselves prove behavior. Mock external boundaries, control clocks and randomness, and avoid order dependence. A test that merely reproduces current behavior does not establish that behavior as correct.

Discard pre-existing issues outside changed behavior, formatting caught by tools, failures already made decisive by CI, risks with no concrete input, and candidates disproved by an existing guard. Check whether the change activates an otherwise old issue. Distinguish root cause from symptom.

## Scale and collection

For broad changes, map touched domains, high-risk boundaries, generated or vendored files, and files that must be read together. Read relevant callers, consumers, schemas, types, tests, configuration, and migrations. Review each behavioral slice, then collect, deduplicate, resolve disagreements, and finish every slice. When delegation is allowed, give each read-only reviewer only its slice, adjacent code, and applicable criteria. Wait for results; if delegation fails or is unavailable, finish sequentially. Do not describe an unfinished slice as reviewed.

## Candidate requirements

For each candidate, record a stable internal ID, severity based on impact and likelihood, category (`behavioral` or `maintainability`), exact changed-file line and side, objective observation, affected caller or user, contract or criterion, concrete risk, proposed comment, possible solution, checks, and proof plan. A behavioral candidate needs an observable input or state and wrong result. A maintenance candidate needs a supported rule or concrete cost and a smaller safe equivalent. Check surrounding and historical code for a contract that disproves it. An unresolved question can be reported as uncertainty without becoming a published finding.

## Blind verification

Before the human gate, give a fresh independent verifier only candidate ID, file, line and side, category, severity, factual failure scenario for behavior or observed cost/redundancy for maintenance, diff hunk, necessary code, and applicable source rules. Withhold the author's prose, conclusion, triage, and persuasive rule interpretation. Ask the verifier to seek counterevidence, inspect guards and actual callers, and return for each candidate:

- `confirmed`: observed input/state and wrong result for behavior, or established rule, references, and safe equivalence for maintenance;
- `plausible`: credible scenario or cost without direct confirmation, with the missing evidence named;
- `rejected`: concrete guard, contract, evidence, or scope reason that disproves the concern.

Record evidence, whether behavior was reproduced, verification method (`independent-agent` or `same-agent-fallback`), and runtime model only if known. Do not label a same-context recheck independent. A verifier cannot publish or mutate files. When delegation is forbidden or unavailable, perform the same counterevidence pass yourself, mark it as fallback, and disclose the limit. For critical external contracts, verify against a current primary source when available. Resolve disagreement with evidence; do not let a vote replace it. If a material disagreement or persistent critical uncertainty remains, use an applicable consultation policy or report uncertainty.

Only validated candidates reach the human gate. A `plausible` candidate must identify the unresolved fact and must not state it as established. If verification changes conclusion, severity, tone, or scope, revise the candidate before asking the user.
