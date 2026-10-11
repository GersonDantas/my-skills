#!/usr/bin/env bash
# =============================================================================
# freshness.sh — merge-conductor Phase 0 sensor (READ-ONLY)
# =============================================================================
# PURPOSE
#   Confirm both merge sides are in sync with their upstream, locate the
#   merge-base(s) (criss-cross aware), and OPTIONALLY discover a prior merge
#   attempt to feed the rerere-purge target and the "what not to repeat" study.
#
# GIT MUTATION
#   NONE. Pure inspection: git rev-parse / rev-list / merge-base / for-each-ref.
#   This script never writes refs, never stages, never checks out.
#
# INPUT
#   $1 <ours-ref>    base side (the --into side); default: current branch
#   $2 <theirs-ref>  incoming target branch being merged in
#
# OUTPUT (stdout) — JSON:
#   {
#     "ours":   {"ref","sha","upstream","upstreamInSync","ahead","behind"},
#     "theirs": {"ref","sha","upstream","upstreamInSync","ahead","behind"},
#     "mergeBase":     "<sha|null>",
#     "mergeBasesAll": ["<sha>", ...],
#     "crissCross":    true|false,        # >1 merge-base = ambiguous/criss-cross
#     "priorAttempt":  {"found":bool, "refs":[{"ref","sha","why"}, ...]},
#     "status":        "ok" | "error",
#     "error":         "<message>"        # only when status == error
#   }
#
# NOTES
#   * Tolerant of refs with no configured upstream (upstreamInSync=null).
#   * priorAttempt is a HEURISTIC (merge commits with 2 parents near the
#     merge-base + branches matching merge/*). Tolerant of finding nothing —
#     never fails for absence of a prior attempt.
#   * On unresolvable refs / not-a-repo, emits a JSON error object (no crash).
# =============================================================================
set -euo pipefail

emit_error() {
  # $1 = message. Emit a valid JSON error object and exit 0 (host parses JSON).
  MC_ERR="$1" python3 -c '
import json, os
print(json.dumps({"status": "error", "error": os.environ["MC_ERR"]}))
'
  exit 0
}

# --- guards ------------------------------------------------------------------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit_error "not inside a git work tree"

OURS_REF="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)}"
THEIRS_REF="${2:-}"
[ -n "$OURS_REF" ]   || emit_error "could not determine ours-ref (no arg, detached HEAD?)"
[ -n "$THEIRS_REF" ] || emit_error "missing theirs-ref (arg 2): the branch to merge in"

OURS_SHA="$(git rev-parse --verify "${OURS_REF}^{commit}" 2>/dev/null || true)"
THEIRS_SHA="$(git rev-parse --verify "${THEIRS_REF}^{commit}" 2>/dev/null || true)"
[ -n "$OURS_SHA" ]   || emit_error "ours-ref not resolvable to a commit: ${OURS_REF}"
[ -n "$THEIRS_SHA" ] || emit_error "theirs-ref not resolvable to a commit: ${THEIRS_REF}"

# --- upstream sync (tolerant of no upstream) ---------------------------------
# Returns "<upstream-ref>\t<ahead>\t<behind>" or empty when no upstream.
upstream_status() {
  local ref="$1" up lr ahead behind
  up="$(git rev-parse --abbrev-ref --symbolic-full-name "${ref}@{upstream}" 2>/dev/null || true)"
  [ -n "$up" ] || { printf '\t\t'; return 0; }
  # left-right count: LEFT = commits in ref not in upstream (ahead),
  #                   RIGHT = commits in upstream not in ref (behind).
  lr="$(git rev-list --left-right --count "${ref}...${ref}@{upstream}" 2>/dev/null || true)"
  if [ -n "$lr" ]; then
    ahead="$(printf '%s' "$lr"  | awk '{print $1}')"
    behind="$(printf '%s' "$lr" | awk '{print $2}')"
  else
    ahead=""; behind=""
  fi
  printf '%s\t%s\t%s' "$up" "$ahead" "$behind"
}

OURS_UP_RAW="$(upstream_status "$OURS_REF")"
THEIRS_UP_RAW="$(upstream_status "$THEIRS_REF")"

OURS_UP="$(printf '%s' "$OURS_UP_RAW"   | cut -f1)"
OURS_AHEAD="$(printf '%s' "$OURS_UP_RAW"  | cut -f2)"
OURS_BEHIND="$(printf '%s' "$OURS_UP_RAW" | cut -f3)"
THEIRS_UP="$(printf '%s' "$THEIRS_UP_RAW"   | cut -f1)"
THEIRS_AHEAD="$(printf '%s' "$THEIRS_UP_RAW"  | cut -f2)"
THEIRS_BEHIND="$(printf '%s' "$THEIRS_UP_RAW" | cut -f3)"

# --- merge-base(s) -----------------------------------------------------------
# merge-base --all returns non-zero (1) when there is NO common ancestor;
# capture and treat as "no base" instead of letting -e kill us.
MB_ALL="$(git merge-base --all "$OURS_SHA" "$THEIRS_SHA" 2>/dev/null || true)"
MB_FIRST="$(git merge-base "$OURS_SHA" "$THEIRS_SHA" 2>/dev/null || true)"

# --- prior-attempt discovery (heuristic, tolerant) ---------------------------
# 1) merge/* branches (and tags) — classic "previous merge attempt" naming.
# 2) merge commits (2+ parents) reachable from either side whose parents
#    include both an ours-descendant and a theirs-descendant flavor, near base.
# Collected as TSV "ref<TAB>sha<TAB>why"; deduped by sha; capped to keep JSON small.
PRIOR_TSV="$(
  {
    # naming heuristic: refs under merge/ on any namespace
    git for-each-ref --format='%(refname:short)%09%(objectname)%09merge/* branch or tag' \
        'refs/heads/merge/*' 'refs/remotes/*/merge/*' 'refs/tags/merge/*' 2>/dev/null || true
    # structural heuristic: recent merge commits (2 parents) touching the two sides
    if [ -n "$MB_FIRST" ]; then
      git rev-list --merges --max-count=50 "$OURS_SHA" "$THEIRS_SHA" 2>/dev/null \
        | while IFS= read -r mc; do
            [ -n "$mc" ] || continue
            npar="$(git rev-list --parents -n1 "$mc" 2>/dev/null | wc -w | tr -d ' ')"
            # rev-list --parents prints "<commit> <p1> <p2> ..."; >=3 tokens => >=2 parents
            if [ "${npar:-0}" -ge 3 ]; then
              printf '%s\t%s\t%s\n' \
                "$(git rev-parse --short "$mc")" "$mc" "merge commit (2+ parents) near base"
            fi
          done
    fi
  } | awk -F'\t' '!seen[$2]++' | head -20
)"

# =============================================================================
# Emit JSON — pass everything via env to avoid shell-quoting hazards in python.
# =============================================================================
MC_OURS_REF="$OURS_REF" MC_OURS_SHA="$OURS_SHA" \
MC_OURS_UP="$OURS_UP" MC_OURS_AHEAD="$OURS_AHEAD" MC_OURS_BEHIND="$OURS_BEHIND" \
MC_THEIRS_REF="$THEIRS_REF" MC_THEIRS_SHA="$THEIRS_SHA" \
MC_THEIRS_UP="$THEIRS_UP" MC_THEIRS_AHEAD="$THEIRS_AHEAD" MC_THEIRS_BEHIND="$THEIRS_BEHIND" \
MC_MB_FIRST="$MB_FIRST" MC_MB_ALL="$MB_ALL" MC_PRIOR_TSV="$PRIOR_TSV" \
python3 <<'PY'
import json, os

def side(prefix):
    up = os.environ.get(f"MC_{prefix}_UP", "") or None
    ahead = os.environ.get(f"MC_{prefix}_AHEAD", "")
    behind = os.environ.get(f"MC_{prefix}_BEHIND", "")
    ahead_i = int(ahead) if ahead.strip() != "" else None
    behind_i = int(behind) if behind.strip() != "" else None
    # in sync = upstream exists AND ahead==0 AND behind==0; null when no upstream.
    if up is None or ahead_i is None or behind_i is None:
        in_sync = None
    else:
        in_sync = (ahead_i == 0 and behind_i == 0)
    return {
        "ref": os.environ.get(f"MC_{prefix}_REF", ""),
        "sha": os.environ.get(f"MC_{prefix}_SHA", ""),
        "upstream": up,
        "upstreamInSync": in_sync,
        "ahead": ahead_i,
        "behind": behind_i,
    }

mb_all = [l for l in os.environ.get("MC_MB_ALL", "").splitlines() if l.strip()]
mb_first = os.environ.get("MC_MB_FIRST", "").strip() or None

prior_refs = []
for line in os.environ.get("MC_PRIOR_TSV", "").splitlines():
    if not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) >= 3:
        prior_refs.append({"ref": parts[0], "sha": parts[1], "why": parts[2]})

out = {
    "ours": side("OURS"),
    "theirs": side("THEIRS"),
    "mergeBase": mb_first,
    "mergeBasesAll": mb_all,
    "crissCross": len(mb_all) > 1,
    "priorAttempt": {"found": len(prior_refs) > 0, "refs": prior_refs},
    "status": "ok",
}
print(json.dumps(out, indent=2))
PY
