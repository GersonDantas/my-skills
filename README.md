# My Skills

Skills I use to make conversations, learning, and development work clearer and easier to verify. Each folder contains a `SKILL.md`; some also include references, templates, or scripts used by the skill.

<p align="center">
  <a href="https://ko-fi.com/gerson_dantas" target="_blank" rel="noopener noreferrer">
    <img src="https://github.com/GersonDantas/img/blob/b81c0ba4adb694a7a65a91f64f7a1670d4d5c101/qrcode.png" alt="Support my work with a coffee on Ko-fi" height="200">
  </a>
</p>

<p align="center">If these skills help your work, you can <a href="https://ko-fi.com/gerson_dantas">buy me a coffee ☕</a>.</p>

## Why these skills exist

A skill captures a way of working that is worth repeating. This collection aims to reduce repeated explanations, preserve important decisions, and require evidence before declaring a problem solved. Some skills support communication and learning; others organize code reviews, bug proofs, and merges.

They do not replace project rules or the decisions of the people working on a project. Before using a skill in a repository, read its instructions, dependencies, and approval requirements.

## Choose a skill for the task

| Situation | Skill | What it does | How it helps |
| --- | --- | --- | --- |
| I need a concise answer | [`caveman`](./caveman/SKILL.md) | Cuts unnecessary words at different levels of brevity while preserving technical accuracy. | Makes updates and decisions easier to read without losing facts, risks, or commands. |
| I want to understand a topic gradually | [`explain-in-steps`](./explain-in-steps/SKILL.md) | Presents one idea at a time while letting me advance, revisit, skip, or combine steps. | Keeps the explanation manageable while I build the basics. |
| I want to investigate a problem together | [`interactive-session`](./interactive-session/SKILL.md) | Keeps the conversation to one point and 5–10 readable lines at a time, recording confirmed decisions as numbered definitions. Its default response language is Brazilian Portuguese unless requested otherwise. Original author: [Sidnei Araújo Júnior](https://github.com/sidnei-junior). English translation: Gerson Dantas. | Helps recover context, clarify expected behavior, and settle decisions before planning or implementation. |
| I need to see a flow or concept | [`show-me`](./show-me/SKILL.md) | Uses diagrams, code sketches, and other visuals at the chosen depth. | Makes relationships and alternatives easier to discuss. |
| I want to test an idea before building it | [`grill-me`](./grill-me/SKILL.md) | Interviews me about a plan, one question at a time, with a recommended answer. | Surfaces open decisions and dependencies early. |
| I want to learn a topic across sessions | [`teach`](./teach/SKILL.md) | Maintains a learning mission, resources, lessons, and learning records in a workspace. | Preserves continuity and creates material I can revisit. |
| I need a commit message | [`commit-message-copy`](./commit-message-copy/SKILL.md) | Writes a short Git-style message from the change. | Saves time and makes the history easier to scan. |
| I am building a project across several PRs | [`construir-projeto-em-prs`](./construir-projeto-em-prs/SKILL.md) | Splits work into verifiable increments, coordinates agents, and routes each PR through independent review and authorized integration. | Keeps delivery, evidence, dependencies, and approvals visible across the project. |
| I found a bug and want to prove it | [`test-proof`](./test-proof/SKILL.md) | Defines the expected behavior and writes the smallest test that fails for the right reason. | Establishes evidence of the defect before changing production code. |
| I am reviewing a PR or MR | [`review-proof-inline`](./review-proof-inline/SKILL.md) | Reviews behavior and complexity, verifies findings, and handles proofs and inline comments through separate approval steps. | Helps prevent unsupported findings or comments published before triage. |
| The PR or MR changes Go code | [`review-go-proof-inline`](./review-go-proof-inline/SKILL.md) | Adds Go-specific criteria to the general review workflow. | Checks contracts, concurrency, errors, and tests without treating style preferences as bugs. |
| A merge has conflicts | [`resolve-conflicts`](./resolve-conflicts/SKILL.md) | Plans the resolution, combines compatible changes, and validates the result. | Reduces the chance of discarding behavior from either branch. |
| I am resolving MR conflicts in a worktree | [`resolve-mr-conflicts`](./resolve-mr-conflicts/SKILL.md) | Records decisions, preserves target-branch behavior, and runs focused checks. | Keeps the resolution auditable and separate from unrelated changes. |
| A merge is large or both branches changed the same flow | [`merge-conductor`](./merge-conductor/SKILL.md) | Maps textual and semantic conflicts, guides resolution in stages, and compares the result with both original branches. | Helps catch regressions even when Git reports no conflict. |

The original `interactive-session` skill was written by [Sidnei Araújo Júnior](https://github.com/sidnei-junior). Gerson Dantas translated it into English.

## How they fit into everyday work

**Before implementation:** `interactive-session` helps resume a problem and record decisions in conversation; `grill-me` helps settle decisions; `show-me` and `explain-in-steps` help build shared understanding. For ongoing learning, `teach` keeps context across sessions.

**During development:** `construir-projeto-em-prs` organizes larger work into reviewed PRs. `test-proof` turns a suspected bug into an observable failing test. `commit-message-copy` helps document changes briefly. `caveman` keeps communication concise when that style is useful.

**During review and integration:** `review-proof-inline` organizes evidence and triage; `review-go-proof-inline` adds Go criteria. `resolve-conflicts` handles common conflicts, `resolve-mr-conflicts` supports an MR workflow, and `merge-conductor` helps when divergent changes need deeper analysis.

## Skill dependencies

Install each required companion skill alongside the skill you want to use. A reference in `SKILL.md` tells the model what to read when the workflow runs; it does not install that skill for you. Keep the complete folders as siblings in the same skills directory.

| Skill you want to use | Install these folders | When the companion is used |
| --- | --- | --- |
| [`explain-in-steps`](./explain-in-steps/SKILL.md) | [`explain-in-steps/`](./explain-in-steps/) and [`show-me/`](./show-me/) | `show-me` is read when the explanation uses visuals. The skill points to `../show-me/SKILL.md`. |
| [`review-proof-inline`](./review-proof-inline/SKILL.md) | [`review-proof-inline/`](./review-proof-inline/) and [`test-proof/`](./test-proof/) | `test-proof` is used when an approved finding needs a failing proof test. The review itself can run without that step. |
| [`review-go-proof-inline`](./review-go-proof-inline/SKILL.md) | [`review-go-proof-inline/`](./review-go-proof-inline/), [`review-proof-inline/`](./review-proof-inline/), and [`test-proof/`](./test-proof/) | The general review skill is required from the start; `test-proof` supports approved proof tests. |

For example, installing `review-go-proof-inline/` alone does **not** provide its base review workflow. Install all three folders listed in its row. [`construir-projeto-em-prs`](./construir-projeto-em-prs/SKILL.md) can run on its own and uses `review-proof-inline` for remote review when that skill is installed. Install the review bundle above if you want that workflow; its proof step also uses `test-proof`. Other skills in the catalog have no references to another personal skill in this repository.

## Install a bundled plugin

The three plugins package each main skill with the other skills it needs. Choose one package for the workflow you want:

| Plugin | Included skills | Best for |
| --- | --- | --- |
| [`explain-in-steps`](./plugins/explain-in-steps/) | `explain-in-steps`, `show-me` | Guided explanations with optional visuals. |
| [`review-proof-inline`](./plugins/review-proof-inline/) | `review-proof-inline`, `test-proof` | General PR and MR reviews. |
| [`review-go-proof-inline`](./plugins/review-go-proof-inline/) | `review-go-proof-inline`, `review-proof-inline`, `test-proof` | Go reviews; the general review workflow is already included. |

In Codex CLI, register the repository's plugin catalog once:

```text
codex plugin marketplace add GersonDantas/my-skills --sparse .agents/plugins
```

This makes the three plugins available. It does **not** install all of them. The sparse checkout limits the files checked out for the catalog; Git may still transfer additional repository data.

Then install **only the plugin you want**:

| Choice | Command |
| --- | --- |
| Guided explanations | `codex plugin add explain-in-steps@gerson-my-skills` |
| General PR/MR review | `codex plugin add review-proof-inline@gerson-my-skills` |
| Go PR/MR review | `codex plugin add review-go-proof-inline@gerson-my-skills` |

You can also select **Gerson's My Skills** in the ChatGPT desktop app's Plugins Directory and install one plugin there. The Go plugin already includes the general review and proof skills, so you do not need the general review plugin alongside it. Installing both review plugins would provide duplicate copies of those shared skills.

These packages are distributed through this GitHub repository's marketplace. They have not been submitted to the public OpenAI Plugins Directory. The top-level skill folders remain the source copies; when a source skill changes, the copies in every affected plugin need to be updated together.

## Usage

Open the folder of the skill you want and read its `SKILL.md`. To use it in Codex, install or share the complete skill folder, including `references/`, `assets/`, `scripts/`, and `agents/` when present. Some skills require particular tools or explicit approval for certain actions; their files describe those requirements.

The `resolve-conflicts` skill names the [Forge project](https://github.com/antinomyhq/forge/tree/main/.forge/skills/resolve-conflicts) as its source. Read its file before reusing or adapting it.

> This catalog covers personal skills unrelated to Laudite. The `mr-review-proof-inline` folder already in this repository is specific to Laudite and is not included in the list above.
