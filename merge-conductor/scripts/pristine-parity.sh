#!/usr/bin/env bash
# =============================================================================
# pristine-parity.sh — merge-conductor Phase 6 parity gate (TWO AXES)
# =============================================================================
# PURPOSE
#   Prove the merged tree introduces NO regression vs the two pristine parents,
#   on TWO axes:
#     AXIS 1 (pass/fail by IDENTITY): the set of failing test-ids in the merged
#       tree must be a SUBSET of the union of failing test-ids in the parents.
#       (A test that already failed on a parent is not a new regression; a NEW
#       failure is.)
#     AXIS 2 (INVENTORY): the merged tree's set of test files/cases must be a
#       SUPERSET of the union of the parents' — minus justified removals. This
#       is the gate that catches "green because the test that would fail was
#       DELETED". Per the plan, axis 2 matters MORE than axis 1 for this method.
#
# GIT MUTATION
#   Effectively READ-ONLY: creates TEMPORARY `git worktree` checkouts for each
#   parent SHA and REMOVES them on exit (trap). It does NOT touch the current
#   working tree/index, creates no commits, advances no refs. Worktree add/remove
#   are the only git calls that write anything, and they are fully reverted.
#
# INPUT
#   $1 <merged-ref>   the resolved/merged tree to validate (often HEAD/worktree)
#   $2 <ours-ref>     parent A (the --into side)
#   $3 <theirs-ref>   parent B (incoming)
#   [--scope <glob>]  limit inventory/affected tests to a path glob (scoped parity)
#   [--ci-api]        baseline parents from CI API instead of local runs -> marks
#                     baselineConfidence=low (see NOTE). This script does NOT call
#                     the CI API itself; with --ci-api it SKIPS local parent runs
#                     and reports baselineSource=ci-api / indeterminate, leaving
#                     the actual CI fetch to the host.
#
# TEST COMMAND
#   * Override: env MC_TEST_CMD="<cmd>" (highest priority).
#   * Else: discover-toolchain.sh <repo-root> -> .root.test.
#   * If neither yields a command -> verdict indeterminate (NOT false-green).
#
# WORKTREE ISOLATION (mandatory for parallel/3-way runs)
#   Running the suite in 3 worktrees can COLLIDE on shared state (local DB,
#   Docker, fixed ports, FS cache) -> false failures. Parametrize per worktree:
#   set env MC_PARITY_ENV_PER_WORKTREE to a command that is sourced/run inside
#   each worktree before the suite to assign a unique port / conn-string, e.g.
#       export MC_PARITY_ENV_PER_WORKTREE='export PORT=$((20000 + RANDOM % 10000))'
#   The host owns the content; this script just runs it in each worktree.
#
# PARENT CACHE
#   Parents are immutable -> their result is cached at
#   ${TMPDIR:-/tmp}/mc-parity-<sha>.json and REUSED (skips re-running) across
#   the session and across --resume.
#
# OUTPUT (stdout) — JSON:
#   {
#     "baselineSource": "local" | "ci-api" | "scoped",
#     "baselineConfidence": "high" | "low",
#     "testCmd": "<cmd|null>",
#     "scope": "<glob|null>",
#     "parents": {
#       "ours":   {"sha","passfail","failing":[...],"inventory":[...],"cached":bool},
#       "theirs": {"sha","passfail","failing":[...],"inventory":[...],"cached":bool}
#     },
#     "merged": {"sha","passfail","failing":[...],"inventory":[...]},
#     "verdict": {
#       "passfail":  "ok" | "regression" | "indeterminate",
#       "inventory": "ok" | "missing-tests" | "indeterminate"
#     },
#     "newFailures":  [...],   # axis 1: failing in merged but in NEITHER parent
#     "missingTests": [...],   # axis 2: in union(parents) inventory but NOT in merged
#     "status": "ok" | "error",
#     "error":  "<message>"
#   }
#
# PRAGMATISM
#   If the suite cannot run (no command, runner error, non-hermetic), the axis
#   is "indeterminate" with an explanation — NEVER a false "ok". Identity-level
#   failing-test parsing is best-effort (JUnit-ish / TAP / "FAIL <file>"); when
#   it is not reliably parseable, passfail collapses to suite-level ok/regression
#   and identity arrays may be coarse — declared, not faked.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

emit_error() {
  MC_ERR="$1" python3 -c '
import json, os
print(json.dumps({"status": "error", "error": os.environ["MC_ERR"]}))
'
  exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit_error "not inside a git work tree"

MERGED_REF="${1:-}"; [ -n "$MERGED_REF" ] || emit_error "missing merged-ref (arg 1)"
OURS_REF="${2:-}";   [ -n "$OURS_REF" ]   || emit_error "missing ours-ref (arg 2)"
THEIRS_REF="${3:-}"; [ -n "$THEIRS_REF" ] || emit_error "missing theirs-ref (arg 3)"
shift 3 || true

SCOPE=""
CI_API=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope) shift; SCOPE="${1:-}";;
    --ci-api) CI_API=1;;
    *) ;;  # ignore unknown
  esac
  shift || true
done

MERGED_SHA="$(git rev-parse --verify "${MERGED_REF}^{commit}" 2>/dev/null || true)"
OURS_SHA="$(git rev-parse --verify "${OURS_REF}^{commit}" 2>/dev/null || true)"
THEIRS_SHA="$(git rev-parse --verify "${THEIRS_REF}^{commit}" 2>/dev/null || true)"
[ -n "$MERGED_SHA" ] || emit_error "merged-ref not resolvable: ${MERGED_REF}"
[ -n "$OURS_SHA" ]   || emit_error "ours-ref not resolvable: ${OURS_REF}"
[ -n "$THEIRS_SHA" ] || emit_error "theirs-ref not resolvable: ${THEIRS_REF}"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- resolve the test command ------------------------------------------------
TEST_CMD="${MC_TEST_CMD:-}"
if [ -z "$TEST_CMD" ] && [ -x "${SCRIPT_DIR}/discover-toolchain.sh" ]; then
  TEST_CMD="$(
    "${SCRIPT_DIR}/discover-toolchain.sh" "$REPO_ROOT" 2>/dev/null \
      | python3 -c 'import sys,json;
try:
  d=json.load(sys.stdin); print((d.get("root") or {}).get("test","") or "")
except Exception:
  print("")' 2>/dev/null || true
  )"
fi

# --- worktree bookkeeping (trap-cleaned) -------------------------------------
TMPROOT="${TMPDIR:-/tmp}"
WORKTREES=()
cleanup() {
  for wt in "${WORKTREES[@]:-}"; do
    [ -n "$wt" ] || continue
    git worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt" 2>/dev/null || true
  done
  git worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Inventory of test files for a given ref, via git ls-tree (no checkout needed).
# Heuristic test-file matcher across ecosystems; scoped by --scope when given.
inventory_for_ref() {
  local ref="$1"
  git ls-tree -r --name-only "$ref" 2>/dev/null \
    | grep -E '(^|/)(tests?|__tests__|spec)/|(\.|_)(test|spec)\.[A-Za-z0-9]+$|_test\.(go|py)$|test_.*\.py$' \
    | { if [ -n "$SCOPE" ]; then grep -E "$SCOPE" || true; else cat; fi; } \
    | sort -u
}

# Run the suite for a ref in an isolated temp worktree; returns via globals
# RUN_PASSFAIL ("pass"|"fail"|"indeterminate") and RUN_FAILING (newline list).
# Caches parent results by SHA.
RUN_PASSFAIL=""
RUN_FAILING=""
run_suite_for_sha() {
  local sha="$1" is_parent="$2" cache="${TMPROOT%/}/mc-parity-${1}.json"
  RUN_PASSFAIL=""; RUN_FAILING=""

  # cache hit (parents only)
  if [ "$is_parent" = "1" ] && [ -f "$cache" ]; then
    RUN_PASSFAIL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("passfail",""))' "$cache" 2>/dev/null || true)"
    RUN_FAILING="$(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1])).get("failing",[])))' "$cache" 2>/dev/null || true)"
    [ -n "$RUN_PASSFAIL" ] && { CACHED=1; return 0; }
  fi
  CACHED=0

  if [ -z "$TEST_CMD" ]; then
    RUN_PASSFAIL="indeterminate"; RUN_FAILING=""
    return 0
  fi

  local wt="${TMPROOT%/}/mc-wt-${sha}-$$"
  if ! git worktree add --detach --force "$wt" "$sha" >/dev/null 2>&1; then
    RUN_PASSFAIL="indeterminate"; RUN_FAILING=""
    return 0
  fi
  WORKTREES+=("$wt")

  # Run the suite inside the worktree, with optional per-worktree env isolation.
  local log="${TMPROOT%/}/mc-suite-${sha}-$$.log"
  local rc=0
  (
    cd "$wt" || exit 97
    # per-worktree resource isolation (ports/conn-strings) — host-provided
    if [ -n "${MC_PARITY_ENV_PER_WORKTREE:-}" ]; then
      eval "${MC_PARITY_ENV_PER_WORKTREE}" || true
    fi
    # shellcheck disable=SC2086
    eval "$TEST_CMD"
  ) >"$log" 2>&1 || rc=$?

  if [ "$rc" -eq 0 ]; then
    RUN_PASSFAIL="pass"
  elif [ "$rc" -eq 97 ]; then
    RUN_PASSFAIL="indeterminate"
  else
    RUN_PASSFAIL="fail"
  fi

  # Best-effort identity extraction of failing test files from the log.
  # Covers common shapes: "FAIL path", "not ok ... path", jest/vitest "✕"/"●".
  RUN_FAILING="$(
    grep -aE '(^| )FAIL |✕ |✗ |^not ok |● .* ›|FAILED ' "$log" 2>/dev/null \
      | sed -E 's/.*FAIL[ED]* +//; s/^not ok[ 0-9]*-? *//; s/[[:space:]]*\(.*$//' \
      | grep -aoE '[A-Za-z0-9_./-]+\.(test|spec)\.[A-Za-z0-9]+|[A-Za-z0-9_./-]+_test\.(go|py)|test_[A-Za-z0-9_./-]+\.py' \
      | sort -u || true
  )"

  # cache parents
  if [ "$is_parent" = "1" ]; then
    MC_PF="$RUN_PASSFAIL" MC_FAILING="$RUN_FAILING" \
    python3 -c '
import json, os, sys
fail=[l for l in os.environ.get("MC_FAILING","").splitlines() if l.strip()]
json.dump({"passfail":os.environ.get("MC_PF",""),"failing":fail}, open(sys.argv[1],"w"))
' "$cache" 2>/dev/null || true
  fi
  return 0
}

# --- CI-API short-circuit ----------------------------------------------------
# With --ci-api we do NOT run parents locally; baseline is left to the host and
# marked low-confidence / indeterminate so it can never produce a false green.
if [ "$CI_API" -eq 1 ]; then
  MERGED_INV="$(inventory_for_ref "$MERGED_SHA")"
  OURS_INV="$(inventory_for_ref "$OURS_SHA")"
  THEIRS_INV="$(inventory_for_ref "$THEIRS_SHA")"
  MC_TESTCMD="$TEST_CMD" MC_SCOPE="$SCOPE" \
  MC_MERGED_SHA="$MERGED_SHA" MC_OURS_SHA="$OURS_SHA" MC_THEIRS_SHA="$THEIRS_SHA" \
  MC_MERGED_INV="$MERGED_INV" MC_OURS_INV="$OURS_INV" MC_THEIRS_INV="$THEIRS_INV" \
  python3 <<'PY'
import json, os
def L(k): return [x for x in os.environ.get(k, "").splitlines() if x.strip()]
merged_inv, ours_inv, theirs_inv = L("MC_MERGED_INV"), L("MC_OURS_INV"), L("MC_THEIRS_INV")
union_inv = sorted(set(ours_inv) | set(theirs_inv))
missing = sorted(set(union_inv) - set(merged_inv))
out = {
    "baselineSource": "ci-api", "baselineConfidence": "low",
    "testCmd": os.environ.get("MC_TESTCMD") or None,
    "scope": os.environ.get("MC_SCOPE") or None,
    "parents": {
        "ours":   {"sha": os.environ["MC_OURS_SHA"], "passfail": "indeterminate",
                   "failing": [], "inventory": ours_inv, "cached": False},
        "theirs": {"sha": os.environ["MC_THEIRS_SHA"], "passfail": "indeterminate",
                   "failing": [], "inventory": theirs_inv, "cached": False},
    },
    "merged": {"sha": os.environ["MC_MERGED_SHA"], "passfail": "indeterminate",
               "failing": [], "inventory": merged_inv},
    # CI-API leaves parent pass/fail to the host -> identity axis indeterminate;
    # inventory axis is still computable from the trees (catches deleted tests).
    "verdict": {"passfail": "indeterminate",
                "inventory": ("ok" if not missing else "missing-tests")},
    "newFailures": [], "missingTests": missing, "status": "ok",
}
print(json.dumps(out, indent=2))
PY
  exit 0
fi

# --- local runs (the normal path) --------------------------------------------
run_suite_for_sha "$OURS_SHA" 1
OURS_PF="$RUN_PASSFAIL"; OURS_FAIL="$RUN_FAILING"; OURS_CACHED="$CACHED"
run_suite_for_sha "$THEIRS_SHA" 1
THEIRS_PF="$RUN_PASSFAIL"; THEIRS_FAIL="$RUN_FAILING"; THEIRS_CACHED="$CACHED"
run_suite_for_sha "$MERGED_SHA" 0
MERGED_PF="$RUN_PASSFAIL"; MERGED_FAIL="$RUN_FAILING"

OURS_INV="$(inventory_for_ref "$OURS_SHA")"
THEIRS_INV="$(inventory_for_ref "$THEIRS_SHA")"
MERGED_INV="$(inventory_for_ref "$MERGED_SHA")"

BASE_SRC="local"; [ -n "$SCOPE" ] && BASE_SRC="scoped"

# =============================================================================
# Emit JSON + compute the two-axis verdict in python.
# =============================================================================
MC_MODE="$BASE_SRC" MC_TESTCMD="$TEST_CMD" MC_SCOPE="$SCOPE" \
MC_MERGED_SHA="$MERGED_SHA" MC_OURS_SHA="$OURS_SHA" MC_THEIRS_SHA="$THEIRS_SHA" \
MC_MERGED_INV="$MERGED_INV" MC_OURS_INV="$OURS_INV" MC_THEIRS_INV="$THEIRS_INV" \
MC_MERGED_PF="$MERGED_PF" MC_OURS_PF="$OURS_PF" MC_THEIRS_PF="$THEIRS_PF" \
MC_MERGED_FAIL="$MERGED_FAIL" MC_OURS_FAIL="$OURS_FAIL" MC_THEIRS_FAIL="$THEIRS_FAIL" \
MC_OURS_CACHED="$OURS_CACHED" MC_THEIRS_CACHED="$THEIRS_CACHED" \
python3 <<'PY'
import json, os

def L(k): return [x for x in os.environ.get(k, "").splitlines() if x.strip()]

ours_inv, theirs_inv, merged_inv = L("MC_OURS_INV"), L("MC_THEIRS_INV"), L("MC_MERGED_INV")
ours_fail, theirs_fail, merged_fail = L("MC_OURS_FAIL"), L("MC_THEIRS_FAIL"), L("MC_MERGED_FAIL")
ours_pf = os.environ.get("MC_OURS_PF", "")
theirs_pf = os.environ.get("MC_THEIRS_PF", "")
merged_pf = os.environ.get("MC_MERGED_PF", "")

# ---- AXIS 1: pass/fail by identity ----
# new failures = failing in merged but in NEITHER parent's failing set.
union_fail = set(ours_fail) | set(theirs_fail)
new_failures = sorted(set(merged_fail) - union_fail)

if merged_pf == "indeterminate" or ours_pf == "indeterminate" or theirs_pf == "indeterminate":
    passfail_verdict = "indeterminate"
elif merged_pf == "pass":
    passfail_verdict = "ok"
else:
    # merged failed: regression only if there is at least one NEW failing id,
    # OR we cannot attribute the failure to a parent (no identity parsed).
    if new_failures:
        passfail_verdict = "regression"
    elif merged_fail:
        # merged has failures, all of which already failed on a parent -> ok
        passfail_verdict = "ok"
    else:
        # suite failed (rc!=0) but no failing ids parsed -> cannot prove subset
        passfail_verdict = "indeterminate"

# ---- AXIS 2: inventory superset ----
union_inv = sorted(set(ours_inv) | set(theirs_inv))
missing_tests = sorted(set(union_inv) - set(merged_inv))
inventory_verdict = "ok" if not missing_tests else "missing-tests"

out = {
    "baselineSource": os.environ.get("MC_MODE", "local"),
    "baselineConfidence": "high",
    "testCmd": os.environ.get("MC_TESTCMD") or None,
    "scope": os.environ.get("MC_SCOPE") or None,
    "parents": {
        "ours":   {"sha": os.environ["MC_OURS_SHA"], "passfail": ours_pf,
                   "failing": ours_fail, "inventory": ours_inv,
                   "cached": os.environ.get("MC_OURS_CACHED") == "1"},
        "theirs": {"sha": os.environ["MC_THEIRS_SHA"], "passfail": theirs_pf,
                   "failing": theirs_fail, "inventory": theirs_inv,
                   "cached": os.environ.get("MC_THEIRS_CACHED") == "1"},
    },
    "merged": {"sha": os.environ["MC_MERGED_SHA"], "passfail": merged_pf,
               "failing": merged_fail, "inventory": merged_inv},
    "verdict": {"passfail": passfail_verdict, "inventory": inventory_verdict},
    "newFailures": new_failures,
    "missingTests": missing_tests,
    "status": "ok",
}
print(json.dumps(out, indent=2))
PY
