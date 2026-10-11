#!/usr/bin/env bash
# =============================================================================
# checkpoint.sh — merge-conductor Phase 4 checkpoint (ONE MUTATION: git add)
# =============================================================================
# PURPOSE
#   Record one resolved point in the sequential resolution loop: stage the
#   resolved path(s), recompute the still-unresolved conflicts, and update the
#   verifiable run state (<studyDir>/.merge-conductor-state.json). Idempotent —
#   re-staging an already-staged file and re-merging the same fields is a no-op.
#
# GIT MUTATION
#   EXACTLY ONE: `git add -- <resolved-path>...`. Nothing else touches git
#   (no commit, no checkout, no config). State file write is a plain file write.
#
# INPUT
#   $1            <studyDir>         directory holding the state file
#   $2..$N        <resolved-path>... one or more paths just resolved by the host
#
# OUTPUT (stdout) — JSON:
#   {
#     "added":              ["<path>", ...],   # paths staged this call
#     "remainingConflicts": ["<path>", ...],   # git diff --diff-filter=U (UU/AA/DD...)
#     "stateFile":          "<studyDir>/.merge-conductor-state.json",
#     "stateUpdated":       true|false,
#     "status":             "ok" | "error",
#     "error":              "<message>"
#   }
#
# STATE MERGE (per assets/templates/state.schema.json)
#   * `checkpointed`: union of existing + newly added paths.
#   * `remainingConflicts`: replaced with the freshly recomputed UU set.
#   * If the file is absent, a MINIMAL valid state is created (version=1, plus
#     the required keys); fields the script does not own are left empty so other
#     phase writers can fill them. Existing fields are preserved (deep-ish merge
#     limited to the two fields this script owns).
# =============================================================================
set -euo pipefail

emit_error() {
  MC_ERR="$1" python3 -c '
import json, os
print(json.dumps({"status": "error", "error": os.environ["MC_ERR"]}))
'
  exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit_error "not inside a git work tree"

STUDY_DIR="${1:-}"
[ -n "$STUDY_DIR" ] || emit_error "missing studyDir (arg 1)"
shift || true
[ "$#" -ge 1 ] || emit_error "missing resolved path(s) (arg 2..N)"

# Collect resolved paths (the rest of argv).
RESOLVED_PATHS=("$@")

# --- THE ONE MUTATION: stage resolved paths ----------------------------------
# Use -- to separate paths from options; tolerate paths that are already staged.
git add -- "${RESOLVED_PATHS[@]}"

# --- recompute remaining conflicts (unmerged entries) ------------------------
# --diff-filter=U lists Unmerged paths (covers UU/AA/DD/AU/UA/DU/UD).
REMAINING="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"

STATE_FILE="${STUDY_DIR%/}/.merge-conductor-state.json"
mkdir -p "$STUDY_DIR" 2>/dev/null || true

# --- merge state.json via python3 (robust JSON) ------------------------------
# Pass added paths and remaining set through env + temp files to avoid arg
# quoting hazards (paths may contain spaces).
ADDED_TMP="$(mktemp "${TMPDIR:-/tmp}/mc-added.XXXXXX")"
REMAIN_TMP="$(mktemp "${TMPDIR:-/tmp}/mc-remain.XXXXXX")"
trap 'rm -f "$ADDED_TMP" "$REMAIN_TMP"' EXIT

# One path per line (NUL would be safer, but git add already accepted them;
# newline-delimited is fine for the state file and matches git diff output).
printf '%s\n' "${RESOLVED_PATHS[@]}" > "$ADDED_TMP"
printf '%s' "$REMAINING" > "$REMAIN_TMP"

MC_STATE_FILE="$STATE_FILE" MC_STUDY_DIR="$STUDY_DIR" \
MC_ADDED_FILE="$ADDED_TMP" MC_REMAIN_FILE="$REMAIN_TMP" \
python3 <<'PY'
import json, os

state_file = os.environ["MC_STATE_FILE"]
study_dir = os.environ["MC_STUDY_DIR"]

def lines(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return [l.rstrip("\n") for l in f if l.strip() != ""]
    except OSError:
        return []

added = lines(os.environ["MC_ADDED_FILE"])
remaining = lines(os.environ["MC_REMAIN_FILE"])

# Load existing state if present & valid; else start minimal.
state = None
if os.path.exists(state_file):
    try:
        with open(state_file, "r", encoding="utf-8") as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = None

if not isinstance(state, dict):
    # Minimal valid state honoring the schema's required keys.
    state = {
        "version": 1,
        "sides": {"ours": "", "theirs": "", "mergeBase": ""},
        "worktree": "",
        "studyDir": study_dir,
        "phasesDone": [],
        "remainingConflicts": [],
        "checkpointed": [],
    }

# Ensure required containers exist even on a partially-written prior state.
state.setdefault("version", 1)
state.setdefault("studyDir", study_dir)
state.setdefault("checkpointed", [])
state.setdefault("remainingConflicts", [])

# --- the two fields this script owns ---
# checkpointed = union(existing, added), order-stable.
seen = set()
merged_cp = []
for p in list(state.get("checkpointed", [])) + added:
    if p not in seen:
        seen.add(p)
        merged_cp.append(p)
state["checkpointed"] = merged_cp

# remainingConflicts = freshly recomputed UU set (authoritative).
state["remainingConflicts"] = remaining

updated = True
try:
    tmp = state_file + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, state_file)
except OSError as e:
    updated = False

print(json.dumps({
    "added": added,
    "remainingConflicts": remaining,
    "stateFile": state_file,
    "stateUpdated": updated,
    "status": "ok",
}, indent=2))
PY
