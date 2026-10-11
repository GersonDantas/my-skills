#!/usr/bin/env bash
# =============================================================================
# enumerate-conflicts.sh — merge-conductor Phase 1 sensor (READ-ONLY PREVIEW)
# =============================================================================
# PURPOSE
#   Preview the merge WITHOUT touching the working tree or index, classify the
#   conflicts (content / modify-delete / add-add), seed the theme clustering
#   with a dirstat, and materialize each side's diff-vs-merge-base to temp
#   files — those two diffs are the INPUT to the convergence detector (Form 3).
#
# GIT MUTATION
#   NONE on the working tree / index / refs. Uses `git merge-tree --write-tree`,
#   which writes loose tree/blob objects into the object DB as a side effect of
#   computing the merge (standard plumbing; it does NOT advance any ref, does
#   NOT stage, does NOT checkout). The real `git merge` is the HOST's job, not
#   this script's — we only PREVIEW here.
#
# INPUT
#   $1 <ours-ref>    base side (--into side)
#   $2 <theirs-ref>  incoming target branch
#
# OUTPUT (stdout) — JSON:
#   {
#     "conflicts": {
#       "content":      ["<path>", ...],
#       "modifyDelete": ["<path>", ...],
#       "addAdd":       ["<path>", ...],
#       "other":        ["<raw CONFLICT line>", ...]   # unclassified types
#     },
#     "conflictCount": N,
#     "cleanMerge":    true|false,          # true when merge-tree had no conflicts
#     "dirstat":       [{"path":"<dir>","pct":<float>}, ...],
#     "diffsVsBase":   {"ours":"<tmpfile|null>","theirs":"<tmpfile|null>"},
#     "mergeBase":     "<sha|null>",
#     "status":        "ok" | "error",
#     "error":         "<message>"          # only when status == error
#   }
#
# NOTES
#   * merge-tree exits NON-ZERO (1) when the merge conflicts — that is EXPECTED,
#     not a failure. We capture rc and parse regardless.
#   * The two diff tmp files are left on disk on purpose (consumed downstream);
#     the host is responsible for cleanup of ${TMPDIR}/mc-diff-*.
#   * Does NOT run `git merge` (that is host orchestration).
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

OURS_REF="${1:-}"
THEIRS_REF="${2:-}"
[ -n "$OURS_REF" ]   || emit_error "missing ours-ref (arg 1)"
[ -n "$THEIRS_REF" ] || emit_error "missing theirs-ref (arg 2)"

OURS_SHA="$(git rev-parse --verify "${OURS_REF}^{commit}" 2>/dev/null || true)"
THEIRS_SHA="$(git rev-parse --verify "${THEIRS_REF}^{commit}" 2>/dev/null || true)"
[ -n "$OURS_SHA" ]   || emit_error "ours-ref not resolvable: ${OURS_REF}"
[ -n "$THEIRS_SHA" ] || emit_error "theirs-ref not resolvable: ${THEIRS_REF}"

MERGE_BASE="$(git merge-base "$OURS_SHA" "$THEIRS_SHA" 2>/dev/null || true)"

# --- merge-tree preview (no tree/index mutation) -----------------------------
# rc=0 clean, rc=1 conflicts (expected), rc>1 real error.
set +e
MT_OUT="$(git merge-tree --write-tree "$OURS_SHA" "$THEIRS_SHA" 2>&1)"
MT_RC=$?
set -e
if [ "$MT_RC" -gt 1 ]; then
  emit_error "git merge-tree failed (rc=${MT_RC}): $(printf '%s' "$MT_OUT" | head -1)"
fi

# Extract the CONFLICT (...) message lines. These appear after the tree OID and
# the conflicted-stage block. Grepping them directly is robust across the
# blank-line boundary between the two output sections.
CONFLICT_LINES="$(printf '%s\n' "$MT_OUT" | grep -E '^CONFLICT \(' || true)"

# --- dirstat seed (theme clustering input) -----------------------------------
# dirstat of what THEIRS brings relative to base. `...` picks the merge-base.
# Tolerant of failure (e.g. unrelated histories) — empty seed is acceptable.
DIRSTAT_RAW=""
if [ -n "$MERGE_BASE" ]; then
  DIRSTAT_RAW="$(git diff --dirstat=files,0 "${MERGE_BASE}...${THEIRS_SHA}" 2>/dev/null || true)"
fi

# --- diffs vs merge-base (convergence-detector input) ------------------------
# -M = follow renames (criss-cross / long-lived branches rename heavily).
DIFF_OURS_FILE=""
DIFF_THEIRS_FILE=""
if [ -n "$MERGE_BASE" ]; then
  TMPROOT="${TMPDIR:-/tmp}"
  DIFF_OURS_FILE="${TMPROOT%/}/mc-diff-ours-${OURS_SHA}.diff"
  DIFF_THEIRS_FILE="${TMPROOT%/}/mc-diff-theirs-${THEIRS_SHA}.diff"
  git diff -M "$MERGE_BASE" "$OURS_SHA"   > "$DIFF_OURS_FILE"   2>/dev/null || DIFF_OURS_FILE=""
  git diff -M "$MERGE_BASE" "$THEIRS_SHA" > "$DIFF_THEIRS_FILE" 2>/dev/null || DIFF_THEIRS_FILE=""
fi

# =============================================================================
# Emit JSON (env-passed to python; parsing/classification done in python).
# =============================================================================
MC_CONFLICTS="$CONFLICT_LINES" MC_DIRSTAT="$DIRSTAT_RAW" \
MC_DIFF_OURS="$DIFF_OURS_FILE" MC_DIFF_THEIRS="$DIFF_THEIRS_FILE" \
MC_MERGE_BASE="$MERGE_BASE" MC_MT_RC="$MT_RC" \
python3 <<'PY'
import json, os, re

content, modify_delete, add_add, other = [], [], [], []

# Recognized merge-tree CONFLICT message shapes:
#   CONFLICT (content): Merge conflict in <path>
#   CONFLICT (add/add): Merge conflict in <path>
#   CONFLICT (modify/delete): <path> deleted in <X> and modified in <Y>. ...
re_in   = re.compile(r'^CONFLICT \(([^)]+)\): Merge conflict in (.+)$')
re_md   = re.compile(r'^CONFLICT \(modify/delete\): (.+?) deleted in .+ and modified in .+')
re_del2 = re.compile(r'^CONFLICT \([^)]*delete[^)]*\): (.+?) deleted in ')

for line in os.environ.get("MC_CONFLICTS", "").splitlines():
    line = line.rstrip("\n")
    if not line:
        continue
    m = re_in.match(line)
    if m:
        kind, path = m.group(1).strip(), m.group(2).strip()
        if kind == "content":
            content.append(path)
        elif kind in ("add/add",):
            add_add.append(path)
        elif "delete" in kind:
            modify_delete.append(path)
        else:
            other.append(line)
        continue
    m = re_md.match(line) or re_del2.match(line)
    if m:
        modify_delete.append(m.group(1).strip())
        continue
    other.append(line)

# de-dup, preserve order
def uniq(seq):
    seen, out = set(), []
    for x in seq:
        if x not in seen:
            seen.add(x); out.append(x)
    return out

content, modify_delete, add_add = uniq(content), uniq(modify_delete), uniq(add_add)

dirstat = []
for line in os.environ.get("MC_DIRSTAT", "").splitlines():
    line = line.strip()
    if not line:
        continue
    # format: "  12.5% some/dir/"
    m = re.match(r'^([\d.]+)%\s+(.*)$', line)
    if m:
        try:
            dirstat.append({"path": m.group(2).strip(), "pct": float(m.group(1))})
        except ValueError:
            pass

count = len(content) + len(modify_delete) + len(add_add) + len(other)
mt_rc = os.environ.get("MC_MT_RC", "")

out = {
    "conflicts": {
        "content": content,
        "modifyDelete": modify_delete,
        "addAdd": add_add,
        "other": other,
    },
    "conflictCount": count,
    "cleanMerge": (mt_rc == "0" and count == 0),
    "dirstat": dirstat,
    "diffsVsBase": {
        "ours": os.environ.get("MC_DIFF_OURS", "") or None,
        "theirs": os.environ.get("MC_DIFF_THEIRS", "") or None,
    },
    "mergeBase": os.environ.get("MC_MERGE_BASE", "").strip() or None,
    "status": "ok",
}
print(json.dumps(out, indent=2))
PY
