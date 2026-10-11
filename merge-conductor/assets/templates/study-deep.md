# Conflict <NN> — `<path/to/file.ext>`

> DEEP study template (8 sections). Use for junction files, golden-list suspects,
> invariant carriers, and **any co-change on a shared flow — conflict or not**.
> Fill every `<...>`. Keep prose tight; cite `file:line` and short snippets where the exact text is load-bearing.

- **Path**: `<path/to/file.ext>`
- **Type**: `<content | modify-delete | add-add | co-change>`  <!-- co-change = no `UU` marker; both sides evolved the same flow -->
- **Theme**: `<theme/cluster this file belongs to>`
- **Altitude**: DEEP
- **Risk**: `<low | medium | high>` — `<one line: why this is the level it is; name the two initiatives that collide here>`

## 1. Role of the file in the system

`<What this file does in the running system. The public surface it exposes (endpoints, exports, schema, events, routes), and who consumes it. Name the consumers that matter for this merge — they are where a semantic conflict lands.>`

## 2. What side A (`<ours | HEAD | base-branch>`) changed & why

`<Base line count → side A line count, if telling. The central business rule side A introduced/changed.>`

**Initiative tag (side A)**: `<epic / task / PR-MR id — the planning-doc tag this work belongs to; "git-log only" if no planning doc exists>`

**Key commits (side A)**:
- `<sha>` — `<what + why>`
- `<sha>` — `<what + why>`

**Structural changes**:
- `<symbol/section moved/added/reshaped + file:line in the working tree>`
- `<...>`

## 3. What side B (`<theirs | MERGE_HEAD | incoming-branch>`) changed & why

`<Base line count → side B line count. The central business rule side B introduced/changed. Note explicitly anything side B does NOT know about (e.g. a new collection/model only side A introduced) — that gap is usually the semantic bug.>`

**Initiative tag (side B)**: `<epic / task / PR-MR id — or "git-log only">`

**Key commits (side B)**:
- `<sha>` — `<what + why>`
- `<sha>` — `<what + why>`

**Structural changes**:
- `<...>`

## 4. Consolidated invariants (what must stay true post-merge)

`<Numbered list. Each invariant = a fact the merged result must preserve, drawn from BOTH sides. These seed the README's "Post-merge invariants" and are what the Phase 5 audit traces. Be concrete: name the function/contract/wire-key/test that proves each one.>`

1. **`<area>`**: `<the invariant, stated as a must>`. `<which side owns it; what breaks if it regresses>`
2. **`<area>`**: `<...>`
3. `<...>`

## 5. Hunk-by-hunk analysis

> One block per conflict hunk. For each: what each side has, the auto-merged context above/below that constrains the choice, and the concrete resolution. Flag any hunk where picking one side alone leaves the file non-loading (`ReferenceError`, missing symbol) — those are forced, not judgment calls.

### H1 — lines `<a–b>` (`<what this region is>`)
- **Side A**: `<what A has here>`
- **Side B**: `<what B has here>`
- **Context (auto-merged)**: `<the surrounding code that constrains the choice, with file:line>`
- **Resolution**: `<accept-A | accept-B | union | rewrite>` — `<exact instruction + why; note any rename/var the rest of the function depends on>`

### H2 — lines `<a–b>` (`<...>`)
- `<...>`

<!-- repeat per hunk -->

## 6. Semantic conflicts & suspicious auto-merged code (the golden-list angle)

> The high-value section. Files git auto-merged "clean" but that are now wrong because this file resolved to one side while a consumer/sibling resolved to the other. Each item = a fix that is **mandatory even though there is no conflict marker**. This is what naive merges miss and what the README's golden list aggregates.

1. **`<path:line>`** — `<what auto-merged, why it is wrong post-merge, the user-visible symptom>`. **Fix**: `<concrete instruction>`. `<CRITICAL | follow-up>`
2. **`<path:line>`** — `<dead code orphaned by the merge / duplicated key / consumer of a changed payload>`. **Fix**: `<...>`
3. `<...>`

## 7. Resolution plan (concrete, named strategy)

**Strategy**: `<accept-one | combine | rewrite | escalate>` — `<one-line justification: why this strategy for this file>`

**Principle**: `<the one-sentence rule that decides every hunk here, e.g. "tenancy = side A; licensing contract = side B; each B lookup gains the new param">`

1. `<H-ref or area>`: `<concrete step>`
2. `<H-ref or area>`: `<concrete step; include the consolidated code block if a hunk head must be hand-written>`
3. **Cleanup**: `<dead code to remove, lint to run on this + any auto-merged sibling the golden list flagged>`

## 8. Validation (commands)

```bash
<commands that prove THIS file's resolution — scoped tests, lint for the failure modes this file can introduce (e.g. no-dupe-keys), a module-load smoke check>
```

`<Manual/staging scenarios that reproduce what a prior attempt broke or what the two initiatives must both still do, if any.>`

## Open questions for the human (genuine decisions only)

> Only list decisions a human must own (conflicting business rule, ambiguous contract, mandatorily-human per the gate: public contract / schema / migration / billing / auth / test removal). If a choice is deterministic or zero-cost, resolve it in §7 — do not surface it here.

- **Q1 — `<the decision>`**: `<side A wants X for reason; side B wants Y for reason; the tension>`. Options: **(i)** `<...>` · **(ii)** `<...>`. `<your reading, if any>`
- **Q2 — `<...>`**: `<...>`
