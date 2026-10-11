# Conflict <NN> — `<path/to/file.ext>`

> STANDARD study template (3 sections). Use when both sides changed the file but it is
> not a junction / golden-list / invariant carrier / shared-flow co-change (those are DEEP).
> Fill every `<...>`. If while filling this you discover a shared-flow coupling, promote the file to DEEP.

- **Path**: `<path/to/file.ext>`
- **Type**: `<content | modify-delete | add-add | co-change>`
- **Altitude**: STANDARD
- **Risk**: `<low | medium>` — `<one line>`

## 1. What each side changed & why

- **Side A (`<ours/HEAD>`)** — `<the change + the business reason>`. Initiative: `<epic/task/PR id or "git-log only">`. `<key sha(s) if useful>`.
- **Side B (`<theirs/MERGE_HEAD>`)** — `<the change + the business reason>`. Initiative: `<epic/task/PR id or "git-log only">`. `<key sha(s)>`.
- **Do they touch the same logic?** `<yes/no + where>`. `<If yes and it is a contract/invariant, stop and promote to DEEP.>`

## 2. Resolution plan

**Strategy**: `<accept-one | combine | rewrite | escalate>` — `<one-line justification>`

1. `<concrete step — which side wins per region, what to drop, any var/import the rest of the file needs kept>`
2. `<...>`

`<Note any sibling file auto-merged on the same flow that must move in lockstep — even without a conflict marker.>`

## 3. Validation (commands)

```bash
<scoped command(s) that prove this resolution: targeted test, syntax/lint check, or module-load smoke>
```
