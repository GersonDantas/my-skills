# Proof, Git, and inline publication

Follow this after human triage. Keep a local ledger linking each stable finding handle to the approved body, proof state, remote comment ID, and current review head. A ledger is evidence, not authorization for another operation.

## Optional proof

Ask which approved behavioral findings the user wants to prove. Approval of triage alone does not authorize local edits. For each selected finding, read and follow `$test-proof` completely when available. Its proof protocol governs test design and reporting; this skill's language, workspace, and authorization gates remain authoritative. Repository-mandated test titles and support-file conventions take precedence. If `$test-proof` is unavailable:

1. State one observable expected behavior and choose the lowest useful test level.
2. Write the smallest test that fails for the claimed reason on the reviewed head, without changing production code.
3. Run the narrowest command and confirm that the assertion or actual value demonstrates the finding rather than setup or environment failure.

Use an isolated worktree or checkout if proof edits would disturb unrelated user changes, with any approval local policy requires. Do not create a failing proof for configuration-only risk, destructive or security-sensitive reproduction, flaky or costly scenarios, or a claim already shown by stronger evidence. Explain the alternative. A maintenance finding needs evidence of rule, references, cost, and safe replacement, not a deliberately failing test.

Show the proof file and line, exact command, decisive result, what it demonstrates, all changed files, and environmental limits. State that nothing was staged, committed, pushed, fixed, or published. Obtain explicit approval of the proof result before any Git action. If rejected, revise or remove only the rejected proof and rerun the narrow check.

## Proof destination and separate Git gates

For each approved proof, present the three destinations. Let the user choose one for all proofs or individually:

1. **Separate proof branch/ref**, derived from the exact reviewed head, preferred when remote policy permits; keep the source branch unchanged.
2. **Review source branch**, only with explicit acceptance of the deliberately failing test's CI impact and authority to update that branch.
3. **Local only**, with no remote proof URL in the comment.

Do not infer a destination from an earlier approval. Never rewrite or force-push an existing ref. Read repository commit rules. Use a requested or mandatory commit-message skill when available; otherwise follow repository guidance and recent history.

For a remote proof, show exact files to stage, unrelated staged and unstaged files to exclude, destination ref and remote, CI consequence, and proposed commit message. If unrelated files are already staged, ask the user to correct staging or explicitly authorize an exact staging adjustment. Obtain separate authorization immediately before each agent-run step: **stage**, then **commit**, then **push**. At each step report the result and confirm the next operation's exact target. Commit only approved proof files. If a step fails, preserve state and stop before publication. Never include production fixes, unrelated changes, logs, screenshots, or local environment artifacts.

If the user reports that they completed staging, commit, and push manually, perform read-only checks for the remote full SHA, proof path, and exact line. Do not ask for agent-run Git approval or treat the report as permission to mutate. Cite only a verified immutable `blob/<full-sha>/<path>#L<line>` link on the reviewed repository. See [provider-operations.md](provider-operations.md) for provider URL shapes. If no remote proof exists, say that the proof ran locally and give no inaccessible local link to the review author.

## Prepare final comments

Proceed toward publication only when the user has requested it. Approval of findings or proof work alone is not a publication request.

Re-fetch review metadata, head, diff refs, and changed files immediately before publication. Confirm each approved finding still holds and the changed-line anchor still exists. If the head changed, revalidate the issue. If proof or new code changes conclusion, severity, tone, or scope, return to human triage. A new immutable proof link alone can be incorporated into the publication preview.

Keep one concise inline comment per approved finding: objective observation, concrete effect, specific action or focused question, and proof result when executed. Include immutable proof URL and short commit when remotely available; otherwise state the local-only result. Do not claim that a merely plausible concern was reproduced. For edits, fetch the existing inline comment and show before and after; require its exact remote identifier. For deletion, show exact target and recovery implications. Never create a duplicate when asked to edit.

## Publication gate and readback

Show the final body and exact operation (`create`, `edit`, or `delete`) for each finding, with provider, host, repository, review number, file, line, diff side, current head, and remote identifier for edits or deletions. Ask for new explicit approval of this preview. An earlier candidate, proof, staging, commit, or push approval never authorizes publication. If any body, operation, review target, anchor, or head changes, show a new preview and obtain new approval.

Publish only the approved operations using the selected provider's inline API in [provider-operations.md](provider-operations.md). For creations and edits, verify returned IDs, URLs, bodies, paths, lines, sides or positions, head/diff association, and review association. For deletion, retain the pre-delete metadata, verify the API success response, then read the same target again to confirm absence; an authentication or permission error does not prove deletion. Store readback in the ledger to prevent duplicates. If an anchor is stale or rejected, re-fetch and return to this gate if any preview field changes. Never fall back to a general review comment.

## Close

Report the review target and head, context and criteria sources with snapshot dates when relevant, coverage and design limits, accepted/rejected findings, proof files and decisive commands/results, proof destination and Git status, inline comment links and readback status, local failing files left behind, and estimated net lines removable for accepted complexity findings. Do not claim completion when a required approval, push, readback, or publication failed. Debt classification alone creates no tracker item; a separately requested tracker integration needs its own exact preview and authorization.
