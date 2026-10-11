#!/usr/bin/env bash
# =============================================================================
# rerere-guard.sh — merge-conductor rerere safety contract (B-rerere)
# =============================================================================
# PURPOSE
#   Make `git rerere` SAFE before the resolution loop. rerere matches conflicts
#   by hunk content and REPLAYS resolutions automatically — so a stale/untrusted
#   rr-cache (from a prior attempt, or a globally-enabled rerere in old sessions)
#   can SILENTLY re-apply wrong resolutions, even to a *similar* conflict in a
#   different file. This script reports that risk and SNAPSHOTS the cache so the
#   host can isolate/purge before enabling rerere.
#
# GIT MUTATION
#   EXACTLY ONE, and it is NOT a git state change: a filesystem `cp -r` of the
#   rr-cache into a timestamped snapshot under ${TMPDIR:-/tmp}. This script
#   DELIBERATELY does NOT run `git config rerere.enabled ...` (no global/local
#   side effect) and does NOT delete cache entries. It only REPORTS + SNAPSHOTS.
#
# HOW THE HOST MUST USE THIS (the contract — see references/rerere-safety-contract.md):
#   1. Run this guard FIRST (Phase 0), BEFORE any merge.
#   2. If recommendation is "isolate" or "purge", the host runs the whole merge
#      with an ISOLATED cache, e.g.:
#         git -c rerere.enabled=true -c rerere.autoupdate=false \
#             -c gc.rerereResolved=0 merge ...
#      pointing rerere at a clean dir (export GIT_CONFIG_* or a fresh
#      .git/rr-cache moved aside) — NEVER inherit untrusted entries.
#   3. EVERY file rerere auto-resolves during replay re-enters the resolution
#      loop as a conflict to RE-VERIFY (it is NOT treated as resolved).
#   4. A shared/persisted cache is allowed ONLY after steps 1-3.
#
# INPUT
#   [--isolate]   Advisory flag: when present, the recommendation is forced to
#                 "isolate" if any local cache entries exist (the host should run
#                 with a clean isolated cache). The flag does NOT itself toggle
#                 anything — isolation is performed by the host via `git -c ...`.
#
# OUTPUT (stdout) — JSON:
#   {
#     "globalEnabledBefore": true|false,   # rerere.enabled in global/system config
#     "localEnabled":        true|false|null,
#     "localCacheExists":    true|false,
#     "cacheDir":            "<.git/rr-cache abs path>",
#     "cacheEntryCount":     N,
#     "snapshot":            "<snapshot dir path|null>",
#     "isolateRequested":    true|false,
#     "recommendation":      "isolate" | "purge" | "proceed",
#     "rationale":           "<human-readable why>",
#     "status":              "ok" | "error",
#     "error":               "<message>"
#   }
#
# RECOMMENDATION LOGIC
#   * cache has entries  + --isolate          -> "isolate"  (run with clean cache)
#   * cache has entries  (no flag)            -> "purge"    (untrusted: isolate or clear)
#   * no entries, global rerere was enabled   -> "proceed"  (but enable explicitly/isolated)
#   * no entries, nothing enabled             -> "proceed"
# =============================================================================
set -euo pipefail

emit_error() {
  MC_ERR="$1" python3 -c '
import json, os
print(json.dumps({"status": "error", "error": os.environ["MC_ERR"]}))
'
  exit 0
}

ISOLATE=0
for arg in "$@"; do
  case "$arg" in
    --isolate) ISOLATE=1 ;;
    *) ;;  # ignore unknown args; this is plumbing
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit_error "not inside a git work tree"

GIT_DIR="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
[ -n "$GIT_DIR" ] || emit_error "could not resolve .git dir"
RR_DIR="${GIT_DIR%/}/rr-cache"

# --- rerere.enabled (global/system vs local) ---------------------------------
# `git config --get` returns non-zero when unset; tolerate it under set -e.
GLOBAL_ENABLED="$(git config --global --get rerere.enabled 2>/dev/null || true)"
SYSTEM_ENABLED="$(git config --system --get rerere.enabled 2>/dev/null || true)"
LOCAL_ENABLED="$(git config --local  --get rerere.enabled 2>/dev/null || true)"

is_true() { case "$(printf '%s' "${1:-}" | tr 'A-Z' 'a-z')" in true|1|yes|on) return 0 ;; *) return 1 ;; esac; }

GLOBAL_BOOL=false
if is_true "$GLOBAL_ENABLED" || is_true "$SYSTEM_ENABLED"; then GLOBAL_BOOL=true; fi

LOCAL_BOOL="null"
if [ -n "$LOCAL_ENABLED" ]; then
  if is_true "$LOCAL_ENABLED"; then LOCAL_BOOL=true; else LOCAL_BOOL=false; fi
fi

# --- count cache entries -----------------------------------------------------
# Each resolved conflict is a subdir of rr-cache containing preimage/postimage.
CACHE_EXISTS=false
ENTRY_COUNT=0
if [ -d "$RR_DIR" ]; then
  CACHE_EXISTS=true
  # count immediate subdirectories (one per recorded conflict)
  ENTRY_COUNT="$(find "$RR_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
fi

# --- THE ONE MUTATION: snapshot the rr-cache (filesystem copy) ---------------
SNAPSHOT=""
if [ "$CACHE_EXISTS" = true ] && [ "${ENTRY_COUNT:-0}" -gt 0 ]; then
  TS="$(date +%Y%m%dT%H%M%S)"
  TMPROOT="${TMPDIR:-/tmp}"
  SNAPSHOT="${TMPROOT%/}/mc-rr-cache-snapshot-${TS}"
  # Idempotent-ish: if the exact timestamped dir somehow exists, suffix with pid.
  [ -e "$SNAPSHOT" ] && SNAPSHOT="${SNAPSHOT}-$$"
  if cp -R "$RR_DIR" "$SNAPSHOT" 2>/dev/null; then :; else SNAPSHOT=""; fi
fi

# --- recommendation ----------------------------------------------------------
if [ "${ENTRY_COUNT:-0}" -gt 0 ]; then
  if [ "$ISOLATE" -eq 1 ]; then
    REC="isolate"; WHY="rr-cache has ${ENTRY_COUNT} untrusted entr(ies); run the merge with a clean ISOLATED cache via 'git -c rerere.enabled=true' pointed at an empty rr-cache."
  else
    REC="purge"; WHY="rr-cache has ${ENTRY_COUNT} pre-existing entr(ies) NOT validated by this run; isolate or clear before enabling rerere (snapshot taken). Re-pass --isolate to run isolated."
  fi
else
  REC="proceed"
  if [ "$GLOBAL_BOOL" = true ]; then
    WHY="no local rr-cache entries, but rerere.enabled is set globally/system-wide; enable explicitly for this run (prefer isolated) and re-verify every replayed file."
  else
    WHY="no rr-cache entries and rerere not globally enabled; safe to enable rerere for this run. Still re-verify any auto-resolved file."
  fi
fi

# =============================================================================
# Emit JSON
# =============================================================================
MC_GLOBAL="$GLOBAL_BOOL" MC_LOCAL="$LOCAL_BOOL" MC_CACHE_EXISTS="$CACHE_EXISTS" \
MC_RR_DIR="$RR_DIR" MC_ENTRY_COUNT="$ENTRY_COUNT" MC_SNAPSHOT="$SNAPSHOT" \
MC_ISOLATE="$ISOLATE" MC_REC="$REC" MC_WHY="$WHY" \
python3 <<'PY'
import json, os

def jbool(s):
    return {"true": True, "false": False, "null": None}.get(s.strip(), None)

out = {
    "globalEnabledBefore": jbool(os.environ.get("MC_GLOBAL", "false")),
    "localEnabled": jbool(os.environ.get("MC_LOCAL", "null")),
    "localCacheExists": jbool(os.environ.get("MC_CACHE_EXISTS", "false")),
    "cacheDir": os.environ.get("MC_RR_DIR", ""),
    "cacheEntryCount": int(os.environ.get("MC_ENTRY_COUNT", "0") or "0"),
    "snapshot": os.environ.get("MC_SNAPSHOT", "") or None,
    "isolateRequested": os.environ.get("MC_ISOLATE", "0") == "1",
    "recommendation": os.environ.get("MC_REC", "proceed"),
    "rationale": os.environ.get("MC_WHY", ""),
    "status": "ok",
}
print(json.dumps(out, indent=2))
PY
