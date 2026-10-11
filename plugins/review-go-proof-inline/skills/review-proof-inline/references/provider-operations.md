# Provider Operations

Read the section for the detected provider completely before making provider calls. Prefer purpose-built connected tools when they expose all required read and inline-comment operations; otherwise use the authenticated provider CLI.

Replace placeholders with values resolved from the remote review. Never pass untrusted PR/MR text through shell evaluation.

## GitHub

### Read Context

Verify tooling and authentication:

```bash
command -v gh
gh auth status
```

Resolve repository and PR metadata:

```bash
gh repo view --json nameWithOwner,url
gh pr view <number-or-url> --repo <owner/repo> \
  --json number,title,url,headRefName,baseRefName,headRefOid,baseRefOid,commits,files,changedFiles
gh pr diff <number-or-url> --repo <owner/repo> --patch
gh api --paginate "repos/<owner/repo>/pulls/<number>/files?per_page=100"
```

`gh pr view` without an argument may resolve the PR for the current branch. Accept it only when it returns one unambiguous open PR in the intended repository.

Use the latest `headRefOid` as `commit_id` when publishing. Re-fetch it immediately before the publication gate:

```bash
gh pr view <number> --repo <owner/repo> --json headRefOid,files,url
```

### Create Inline Comment

For an added or context line use the new-file line and `RIGHT`. For a removed line use the old-file line and `LEFT`. Use `line`, not deprecated diff `position`.

```bash
gh api "repos/<owner/repo>/pulls/<number>/comments" \
  --method POST \
  --raw-field body='<approved-body>' \
  --raw-field commit_id='<current-head-sha>' \
  --raw-field path='<repo-relative-path>' \
  --field line=<line-number> \
  --raw-field side='<RIGHT-or-LEFT>'
```

For a multiline comment add `start_line` and `start_side`. After creation, verify `id`, `html_url`, `body`, `path`, `line` or `original_line`, `side`, and `commit_id`.

Creating review comments requires repository Pull requests write permission and triggers notifications.

### Edit Or Delete Inline Comment

Fetch before editing or deleting:

```bash
gh api "repos/<owner/repo>/pulls/comments/<comment-id>"
```

Edit only the approved body:

```bash
gh api "repos/<owner/repo>/pulls/comments/<comment-id>" \
  --method PATCH \
  --raw-field body='<approved-body>'
```

Delete only after explicit approval:

```bash
gh api "repos/<owner/repo>/pulls/comments/<comment-id>" --method DELETE
```

General PR timeline comments use issue-comment endpoints and are not interchangeable with inline review comments.

### Stable Proof Link

Use:

```text
https://<github-host>/<owner>/<repo>/blob/<proof-commit>/<test-path>#L<line>
```

For GitHub Enterprise, preserve the host resolved from the canonical PR URL and select the matching authenticated `gh` host.

## GitLab

### Read Context

Verify tooling and authentication:

```bash
command -v glab
glab auth status
```

Resolve project context from the MR URL or authenticated repository remote. URL-encode a namespaced project path when using it in API paths.

```bash
glab repo view
glab mr view <iid> --repo <group/project>
glab mr diff <iid> --repo <group/project>
glab api "projects/<url-encoded-project>/merge_requests/<iid>"
glab api --paginate "projects/<url-encoded-project>/merge_requests/<iid>/diffs?per_page=100"
```

Record `diff_refs.base_sha`, `diff_refs.start_sha`, and `diff_refs.head_sha`. Re-fetch them immediately before publication because GitLab diff positions require all three SHAs.

Before creating a diff discussion, fetch the latest MR diff version and use its `base_commit_sha`, `start_commit_sha`, and `head_commit_sha` as the position SHAs:

```bash
glab api "projects/<url-encoded-project>/merge_requests/<iid>/versions"
```

### Create Inline Discussion

For a text diff discussion, always send `old_path`, `new_path`, `base_sha`, `start_sha`, `head_sha`, and `position_type=text`.

For an added line, include `new_line` and omit `old_line`. Build a structured JSON payload in a temporary file so `position` is sent as an object:

```json
{
  "body": "<approved-body>",
  "position": {
    "position_type": "text",
    "base_sha": "<base-commit-sha>",
    "start_sha": "<start-commit-sha>",
    "head_sha": "<head-commit-sha>",
    "old_path": "<old-path>",
    "new_path": "<new-path>",
    "new_line": 18
  }
}
```

Send the payload without adding field flags:

```bash
glab api "projects/<url-encoded-project>/merge_requests/<iid>/discussions" \
  --method POST \
  --input <payload-file>
```

For a removed line, include `old_line` and omit `new_line`. For an unchanged line, include both fields with their respective old and new line numbers. Delete the temporary payload after the verified API response.

After creation, verify the discussion ID and the first note's ID, body, position paths, line, and diff SHAs. Keep both identifiers in the comment ledger because later editing and deletion require the discussion and note IDs.

Recent `glab` versions can also create diff discussions with `glab mr note create --file` and `--line` or `--old-line`. Prefer the API form when exact SHA control and response verification are required.

### Edit Or Delete Inline Discussion Note

Fetch the discussion first:

```bash
glab api "projects/<url-encoded-project>/merge_requests/<iid>/discussions/<discussion-id>"
```

Edit only the approved note body:

```bash
glab api "projects/<url-encoded-project>/merge_requests/<iid>/discussions/<discussion-id>/notes/<note-id>" \
  --method PUT \
  --raw-field body='<approved-body>'
```

Delete only after explicit approval:

```bash
glab api "projects/<url-encoded-project>/merge_requests/<iid>/discussions/<discussion-id>/notes/<note-id>" \
  --method DELETE
```

Do not substitute a general MR note for an inline discussion after a position error.

### Stable Proof Link

Use:

```text
https://<gitlab-host>/<group>/<project>/-/blob/<proof-commit>/<test-path>#L<line>
```

For self-managed GitLab, preserve the host from the canonical MR URL and select the matching authenticated `glab` host.

## Provider Write Failure

On authentication, permission, stale-head, invalid-position, rate-limit, or validation failure:

1. Record the exact operation and provider response.
2. Make no fallback write to another comment type.
3. Re-fetch remote context when safe.
4. Return to the publication gate if body, anchor, SHA, provider, or operation changes.
5. Report the failure without claiming publication.
