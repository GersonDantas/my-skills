# Parity Gate (two axes)

Phase 6 proves the merged tree regresses **nothing** relative to the **pristine parents**. A
pass/fail check alone does **not** catch deleted tests — the classic failure mode is a merge
with green CI *because the tests that would expose the break were removed*. So two gates.
Driven by `scripts/pristine-parity.sh`; results land in `state.json.parityBySha`.

## Axis 1 — pass/fail by test IDENTITY (not count)
The set of `test-id`s that **fail** in the merged tree ⊆ the **union** of the parents' failures.
By **identity**, never by count or subset cardinality.
- **Flake re-run:** a candidate new-failure re-runs N× before it counts as a real new failure.
- **Union baseline:** a test that exists on only one parent is baselined against the side that
  introduced it.
- **Stable test identity:** when names are dynamic/parametrized/generated, define a stable
  `test-id` (e.g. `file + normalized name + case index`). Without it, identity parity collapses.
- **Flake never hides a regression:** the short re-run distinguishes flaky from new-failure but
  must never silence a genuinely new failure behind a retry.
- → `state.json.parityBySha[<sha>].passfail`: `ok | regression | indeterminate | pending`.

## Axis 2 — test INVENTORY parity *(the gate the pass/fail axis misses)*
The set of test files/cases in the merged tree ⊇ the **union** of the two parents, **minus
justified removals**. This is the direct defense against "green but broken": it catches a test
that was *deleted* during the merge.
- **More important than the pass/fail axis for this method.**
- A removal is only acceptable if justified (the feature it covered was intentionally removed,
  recorded as a human decision).
- → `state.json.parityBySha[<sha>].inventory`: `ok | missing-tests | indeterminate | pending`.

## Cost model — pyramid + cache + parallel + fallback
- **Pyramid (cheap → expensive):** fast lane first (build / lint / typecheck / smoke in scope)
  = blocking gate; then **impact selection** (run only the reverse-dependency closure of the
  diff when the runner supports it — `nx affected`, `vitest --related`, …); the **full suite
  only on a new failure or a high-risk item**.
- **Cache by SHA:** parents are immutable → compute the parent baseline **once**, reuse it
  across the session and on `--resume` (`parityBySha` is keyed by parent SHA).
- **Parallel worktrees:** run the merged tree and both parents in parallel — but **isolate
  shared state per worktree** (parametrize port / DB conn-string / FS cache per worktree),
  or parallel runs collide and produce false-positive failures.
- **CI-API fallback:** when the suite is not hermetic (can't faithfully run 3× locally), fetch
  the parents' known failures via the GitHub/GitLab API instead of running locally —
  **marking baseline confidence**: a CI baseline whose environment may differ becomes
  `indeterminate`, never "green".
  → `state.json.parityBySha[<sha>].baselineSource`: `local | ci-api | scoped`;
  `baselineConfidence`: `high | low` (low when the env may differ).

## Gate semantics
- Axis-1 `regression` **OR** Axis-2 `missing-tests` **blocks** the commit.
- `indeterminate` on either axis is **not** "green" — surface it; do not pass silently.
- The two axes are blind to flow with **no test** — the convergence detector's backstop
  (see `convergence-detector.md`) covers that gap by flagging a follow-up.
