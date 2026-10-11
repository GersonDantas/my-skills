#!/usr/bin/env bash
# =============================================================================
# discover-toolchain.sh — merge-conductor toolchain map (READ-ONLY)
# =============================================================================
# PURPOSE
#   Detect the test / build / lint commands and package manager per package,
#   so the parity gate (and the host) know how to run each toolchain. In a
#   monorepo this is a MAP keyed by package directory (not a single shape) —
#   different packages may use different toolchains.
#
# GIT MUTATION
#   NONE. Read-only filesystem inspection of manifests. (Does not even require
#   a git repo; works on any directory.)
#
# INPUT
#   [<dir>]   root to scan; default: current directory.
#
# OUTPUT (stdout) — JSON:
#   {
#     "root": {"test","build","lint","pkgManager","manifest"},
#     "packages": {
#       "<pkgDir-relative>": {"test","build","lint","pkgManager","manifest"},
#       ...
#     },
#     "status": "ok" | "error",
#     "error":  "<message>"
#   }
#   Each field is "" (empty) when NOT detected — the host then asks the user.
#
# DETECTION
#   * package.json  -> scripts.test/build/lint; pkgManager from lockfile
#                      (pnpm-lock.yaml->pnpm, yarn.lock->yarn, package-lock.json
#                      / npm-shrinkwrap.json->npm, bun.lockb->bun); default npm.
#   * Makefile      -> test/build/lint targets -> `make <target>`
#   * Cargo.toml    -> cargo test / cargo build / cargo clippy
#   * pyproject.toml / setup.cfg -> pytest / python -m build / ruff check
#   * go.mod        -> go test ./... / go build ./... / go vet ./...
#
# MONOREPO
#   Walks subdirectories up to depth 3 collecting every dir that has a manifest.
#   Skips heavy/vendored dirs (node_modules, .git, dist, build, target, vendor,
#   .venv, __pycache__) to stay cheap and avoid false packages.
# =============================================================================
set -euo pipefail

emit_error() {
  MC_ERR="$1" python3 -c '
import json, os
print(json.dumps({"status": "error", "error": os.environ["MC_ERR"]}))
'
  exit 0
}

ROOT="${1:-.}"
[ -d "$ROOT" ] || emit_error "not a directory: ${ROOT}"
ROOT_ABS="$(cd "$ROOT" 2>/dev/null && pwd)" || emit_error "cannot cd into: ${ROOT}"

MC_ROOT="$ROOT_ABS" python3 <<'PY'
import json, os, sys

try:
    import tomllib  # py3.11+
except ModuleNotFoundError:
    tomllib = None

ROOT = os.environ["MC_ROOT"]
SKIP_DIRS = {"node_modules", ".git", "dist", "build", "target", "vendor",
             ".venv", "venv", "__pycache__", ".next", ".nuxt", "coverage",
             ".turbo", ".cache", "out"}
MAX_DEPTH = 3

def read_text(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None

def detect_pkg_manager(d):
    # lockfile -> manager; default npm when only package.json present.
    if os.path.exists(os.path.join(d, "pnpm-lock.yaml")):
        return "pnpm"
    if os.path.exists(os.path.join(d, "yarn.lock")):
        return "yarn"
    if os.path.exists(os.path.join(d, "bun.lockb")):
        return "bun"
    if os.path.exists(os.path.join(d, "package-lock.json")) or \
       os.path.exists(os.path.join(d, "npm-shrinkwrap.json")):
        return "npm"
    return "npm"

def run_prefix(mgr):
    # how this manager invokes a package.json script
    return {"npm": "npm run", "pnpm": "pnpm run",
            "yarn": "yarn", "bun": "bun run"}.get(mgr, "npm run")

def from_package_json(d):
    raw = read_text(os.path.join(d, "package.json"))
    if raw is None:
        return None
    try:
        data = json.loads(raw)
    except ValueError:
        # malformed manifest — still report it as a package with empty cmds
        return {"test": "", "build": "", "lint": "", "pkgManager": detect_pkg_manager(d),
                "manifest": "package.json"}
    scripts = data.get("scripts", {}) or {}
    mgr = detect_pkg_manager(d)
    rp = run_prefix(mgr)
    def cmd(name):
        return f"{rp} {name}" if name in scripts else ""
    return {
        "test": cmd("test"),
        "build": cmd("build"),
        "lint": cmd("lint"),
        "pkgManager": mgr,
        "manifest": "package.json",
    }

def makefile_targets(d):
    for fn in ("Makefile", "makefile", "GNUmakefile"):
        p = os.path.join(d, fn)
        txt = read_text(p)
        if txt is None:
            continue
        targets = set()
        for line in txt.splitlines():
            # a target line looks like "name:" or "name: deps" at column 0
            if line and not line[0].isspace() and ":" in line:
                head = line.split(":", 1)[0].strip()
                if head and " " not in head and not head.startswith("."):
                    targets.add(head)
        def cmd(t):
            return f"make {t}" if t in targets else ""
        return {
            "test": cmd("test"),
            "build": cmd("build"),
            "lint": cmd("lint"),
            "pkgManager": "make",
            "manifest": fn,
        }
    return None

def from_cargo(d):
    if not os.path.exists(os.path.join(d, "Cargo.toml")):
        return None
    return {
        "test": "cargo test",
        "build": "cargo build",
        "lint": "cargo clippy",
        "pkgManager": "cargo",
        "manifest": "Cargo.toml",
    }

def from_python(d):
    has_pyproject = os.path.exists(os.path.join(d, "pyproject.toml"))
    has_setupcfg = os.path.exists(os.path.join(d, "setup.cfg"))
    has_setuppy = os.path.exists(os.path.join(d, "setup.py"))
    if not (has_pyproject or has_setupcfg or has_setuppy):
        return None
    # Try to pick a smarter lint/test if declared, else sensible defaults.
    lint = "ruff check ."
    test = "pytest"
    build = "python -m build"
    if has_pyproject and tomllib is not None:
        raw = read_text(os.path.join(d, "pyproject.toml"))
        if raw:
            try:
                data = tomllib.loads(raw)
            except Exception:
                data = {}
            # poetry projects build via poetry; PEP517 otherwise.
            tool = data.get("tool", {}) or {}
            if "poetry" in tool:
                build = "poetry build"
            # if ruff not configured but flake8 is, hint flake8
            if "ruff" not in tool and "flake8" in tool:
                lint = "flake8"
    manifest = ("pyproject.toml" if has_pyproject
                else "setup.cfg" if has_setupcfg else "setup.py")
    return {"test": test, "build": build, "lint": lint,
            "pkgManager": "python", "manifest": manifest}

def from_go(d):
    if not os.path.exists(os.path.join(d, "go.mod")):
        return None
    return {
        "test": "go test ./...",
        "build": "go build ./...",
        "lint": "go vet ./...",
        "pkgManager": "go",
        "manifest": "go.mod",
    }

# Priority order: JS first (most common in this org), then native/lang toolchains.
DETECTORS = [from_package_json, makefile_targets, from_cargo, from_python, from_go]

def detect_dir(d):
    """Return the FIRST matching toolchain shape for a dir, or None."""
    for det in DETECTORS:
        res = det(d)
        if res is not None:
            return res
    return None

def walk(root, max_depth):
    """Yield (abs_dir, depth) for root and descendants up to max_depth."""
    root = os.path.abspath(root)
    base_depth = root.rstrip(os.sep).count(os.sep)
    for cur, dirs, _files in os.walk(root):
        depth = cur.rstrip(os.sep).count(os.sep) - base_depth
        # prune
        dirs[:] = [x for x in dirs if x not in SKIP_DIRS and not x.startswith(".")]
        if depth >= max_depth:
            dirs[:] = []
        yield cur, depth

root_shape = detect_dir(ROOT) or {"test": "", "build": "", "lint": "",
                                   "pkgManager": "", "manifest": ""}

packages = {}
for d, depth in walk(ROOT, MAX_DEPTH):
    if os.path.abspath(d) == os.path.abspath(ROOT):
        continue  # root reported separately
    shape = detect_dir(d)
    if shape is not None:
        rel = os.path.relpath(d, ROOT)
        packages[rel] = shape

print(json.dumps({
    "root": root_shape,
    "packages": packages,
    "status": "ok",
}, indent=2))
PY
