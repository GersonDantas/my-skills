# Previous inline review threads

Read this before diff analysis for GitHub or GitLab. This inventory is read-only. General PR/MR comments and ordinary notes are not resolvable inline threads.

Fetch every page of the current review's inline threads. For each, retain remote ID, resolution state, outdated state if provided, file and line, comments with author/body/URL, and the current-head code needed to assess it. Avoid fetching unrelated conversation data. Use the authenticated host selected in [provider-operations.md](provider-operations.md).

On GitHub, use the PR GraphQL `reviewThreads` connection and its page cursor. Read `id`, `isResolved`, `isOutdated`, `path`, `line`, `originalLine`, and the comments needed to understand the issue. GitHub's `resolveReviewThread` mutation accepts the exact thread ID. On GitLab, paginate `GET /projects/:id/merge_requests/:merge_request_iid/discussions`; use `id`, `individual_note`, notes, `resolvable`, `resolved`, and diff position when present. A resolvable MR discussion can be resolved with `PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id` and `resolved=true`. Do not treat a non-resolvable discussion as an inline thread to close.

Report counts of resolved and open threads. Give each open thread a stable handle `[C1..]`, path and line, short issue summary, URL, and evidence-based status:

- `ready to resolve`: the current head addresses the exact issue, with code or test evidence;
- `still open`: the issue remains or the evidence is insufficient.

A reply, outdated marker, or moved diff line alone does not prove a fix. Do not count an already resolved thread as a new finding. Check whether an open prior thread duplicates a new candidate and link the existing thread instead of proposing a duplicate.

If any thread is ready, show its handle, remote ID, current-head evidence, and exact proposed resolution. Ask for approval of that subset only. A reply to this gate authorizes only the mapped thread resolutions, not proof work, comments, or other writes. If the user declines, leave threads unchanged and continue reviewing. Before each approved mutation, confirm the thread still maps to the same review and is unresolved; after it, read the thread again and confirm `isResolved` or `resolved`. If state or evidence changed, return to this gate. Report any failed operation without claiming resolution.

If the provider cannot expose complete threads, report the coverage limit and continue the code review. Do not invent an equivalent resolution call for another provider.
