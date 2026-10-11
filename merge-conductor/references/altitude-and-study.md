# Altitude & Study

Phase 2 understands *what each side planned* and *how to reconcile it*, with depth scaled
**per item** — never a single global "lite" knob (that would lower depth exactly on the
dangerous junction files). Each item gets a study doc in `<studyDir>/NN-*.md`; its altitude is
recorded in `state.json.altitude`.

## The three altitudes
- **TRIVIAL** (formatting, import ordering, lockfile, generated) → a 1-line note.
- **STANDARD** → 3 sections: what each side changed and why / resolution plan / validation.
- **DEEP** (8 sections) — forced for, **conflict or not**:
  - junction files,
  - **golden-list** suspects (always DEEP),
  - invariant carriers,
  - **any co-change over a shared flow** — even with no physical conflict.

  DEEP criteria, stated as a rule: an item is DEEP whenever it is a **junction**, on the
  **golden list**, an **invariant carrier**, or a **flow co-change**. The golden list is
  **always DEEP**.

## The synthesis README — non-negotiable
Even in lite mode, the synthesis README is mandatory: **attack order + golden list + global
invariants + gates**. This is where the method's value concentrates. You shrink the *per-file*
doc, never the synthesis. `--lite` only downgrades the **STANDARD→note** default in small
repos; **DEEP stays forced** for junction/golden-list. The README always renders in full.

## Grounding the "why" in planning docs — *if they exist*
Tolerant of absence (like the optional prior-attempt input). If they exist, the study agent
reads, on both sides: `epic.md`/EPIC, `tasks.json`/TODO, the **PR/MR description**, and
CHANGELOG. If they do not exist, **silent fallback** to `git log` + PR/MR metadata — never burn
tokens hunting for what isn't there.

**CODE WINS a divergent doc:** if the doc disagrees with the code, the code is authoritative
(a stale doc must not anchor a tag to an abandoned intention).

## Per-item tagging
- **Initiative tag:** side A = epic/task X; side B = epic/task Y — so each item is attributed
  to the work that produced it.
- **Named strategy** (carried into Phase 4): `accept-one` · `combine` · `rewrite` (feeds the
  Phase 6.5 queue) · `escalate`. See `phases.md` / `harmonization.md`.

## `--lite` summary
`--lite` downgrades **STANDARD → note** in small repos and reduces automatic structural
checking in Phase 6.5 (see `harmonization.md`). It **never** touches DEEP: junction /
golden-list / invariant-carrier / flow co-change stay DEEP, and the synthesis README stays full.
