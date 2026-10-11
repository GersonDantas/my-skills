# Rerere Safety Contract

`git rerere` records conflict resolutions keyed by hunk content and **replays them
automatically**. That convenience is a footgun for a conducted merge.

## The footgun
- **Untrusted pre-existing resolutions** in the cache — `.git/rr-cache` **or a global cache** —
  from a prior attempt, or from old sessions that had `rerere.enabled` set globally — get
  **re-applied silently** the moment rerere is armed and catch-up runs.
- rerere can **auto-resolve a *similar* conflict** in another file, wrongly, **with no conflict
  marker left** — so it never enters the resolution loop on its own.
- **The risk exists independently of whether there was a prior attempt.** A populated global
  cache is enough.

## The contract (mandatory, before arming rerere)
Run `scripts/rerere-guard.sh` in Phase 0, **before** `freshness.sh`.

1. **Snapshot** the `rr-cache` and **check global `rerere.enabled`.**
   Record both into `state.json.rerere` (`cacheSnapshot`, `globalEnabledBefore`).
2. **Isolate or purge** any resolution NOT validated by *this* run. Running with a **clean,
   isolated rr-cache is the safe default** (`state.json.rerere.isolated = true`). Prior-attempt
   resolutions (discovered in Phase 0) are an explicit purge target.
3. **Re-verify every replay.** Any file rerere auto-resolved is added to the **mandatory review
   list** — treated as a conflict, not as resolved — and listed in
   `state.json.rerere.autoResolvedPendingReview`. It re-enters the Phase 4 loop as a point to
   review (the replay never skips the cycle).
4. **A shareable / persisted cache is allowed only after (1)–(3).** Once this run's resolutions
   are recorded and validated, the cache may be shared across runs/devs.

## Mapping to `state.json.rerere.*`
| Field | Set by | Meaning |
|-------|--------|---------|
| `globalEnabledBefore` | step 1 | was `rerere.enabled` true globally before this run |
| `cacheSnapshot` | step 1 | path of the rr-cache snapshot taken before arming |
| `isolated` | step 2 | true when running with an isolated/clean rr-cache (safe default) |
| `autoResolvedPendingReview` | step 3 | files rerere auto-resolved that MUST be re-verified |

## Useful commands
```sh
git config --get rerere.enabled            # step 1: detect global state
cp -a "$(git rev-parse --git-dir)/rr-cache" "$snapshot"   # step 1: snapshot
rm -rf "$(git rev-parse --git-dir)/rr-cache"              # step 2: isolate (safe default)
git rerere status                          # step 3: which conflicts rerere touched
git rerere diff                            # step 3: what it replayed — feed the review list
```
On `--resume`, the guard re-asserts the isolated cache and re-loads
`autoResolvedPendingReview` so replayed points are still treated as conflicts to review.
