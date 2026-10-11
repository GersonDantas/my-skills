# Agnosticism & Adapters

The skill is **git-only by declaration** — it does not pretend total neutrality. It is
language-agnostic *above* git via a capability interface that degrades honestly.

## Git-only, and `origin` is a default — not an invariant
`origin` is the default remote, but treat it as such: **forks, a remote with another name, and
shallow clones** all need a confirmed alternate path, not a silent assumption.
```sh
git remote                       # do not assume 'origin' exists
git rev-parse --is-shallow-repository   # shallow → merge-base/history may be incomplete → confirm
```

## Capability interface for symbols
Symbol extraction (used by the convergence detector) degrades down a ladder, never up:
**lexical → tree-sitter → LSP/ctags.** Lexical-per-hunk is the guaranteed floor; higher tiers
raise fidelity when present. The tier reached is declared in the README and
`state.json.convergenceCoverage` (no silent caps).

## `discover-toolchain` = a per-package MAP in a monorepo
`scripts/discover-toolchain.sh` produces a **`{test, build, lint, pkgManager}` map keyed by
package**, not one shape for the whole repo — a monorepo is multi-toolchain. Stored in
`state.json.toolchain`. When no runner is detected, it asks the user for the commands.

## Lockfiles / generated / migrations — a dedicated routine, never semantic study
These are **never** studied semantically. The routine is: **clear the conflict markers, then
regenerate via the detected installer.**
```sh
# pick by detected pkgManager / ecosystem:
npm install            # or: pnpm install / yarn install   → regenerate lockfile
cargo generate-lockfile
poetry lock
```
A migration file co-touched by both sides is still a **first-class convergence signal** (see
`convergence-detector.md`) — the *file's lockfile-like regeneration* is mechanical, but the
*decision* about colliding migrations is DEEP.

## Portability
Scripts are **POSIX `sh` + native git / Python**, not Node — so a repo in Python/Go/Rust needs
no Node runtime. **POSIX = portable on WSL/macOS/Linux**; pure Windows requires Git Bash or WSL.

## Scope cut — core vs neighbor skills
The **core is Phases 0–6 + the verified merge commit (thin tail of 7)**. What this skill
**invokes or hands off to**, but does not embed:
- **Phase 7-rest** — stacked MRs / cover pages → `mr-cover-page` / `commit`.
- **Phase 8** — follow-up execution (the `FOLLOW-UPS.md` items as their own projects) → a
  follow-up neighbor skill.
- **Phase 9** — deploy / validation-branch repoint → an org skill (the **least portable** part:
  `glab`/`gh`, `staging`/`qa`, environment infra).

Reason: single responsibility, and Phases 7-rest/8/9 are exactly where agnosticism leaks.
