---
name: explain-in-steps
description: Guide understanding one step at a time, using text or Show Me visuals at the user's chosen depth. Use when the user wants to grasp a concept without reading the whole explanation at once.
---

# Explain in Steps

Reveal one useful layer of a concept at a time. Start with the central idea in a short, self-contained first step so the user can stop early with a useful understanding. Add mechanisms, evidence, implications, and exceptions only on request.

## Build on Show Me

For visual output, read and follow [Show Me](../show-me/SKILL.md). Use its diagrams, code sketches, diffs, charts where real data warrants them, images, or focused HTML presentations as appropriate. Its summarized or detailed depth controls how rich each visual is; this skill controls the pace. Even a detailed presentation must reveal one step at a time. Do not ask again about depth when the user has already chosen it.

Keep Show Me's distinction between verified facts, inferences, proposals, and decisions. Cite inspected sources when explaining specific material. Label illustrative data rather than presenting it as measured fact.

## Let the user choose the format

- Honor a format already requested. Otherwise, ask once in the user's language: text in the conversation, visuals in the conversation, or interactive HTML. Recommend text for a simple idea, an inline visual for relationships or flows, and HTML only when navigation itself helps. If the user chooses text, do not create an HTML page.
- Allow switching format during the explanation without restarting. A visual step must convey the same essential point as its text version.
- For text or visuals in the conversation, show only the current step in each reply. For HTML, show only the first step initially and reveal later steps through explicit navigation; support keyboard and mobile use, and let the user stop without visiting every step.

## Advance only when asked

1. Identify the conclusion and the few prerequisites needed to understand it. Infer the audience and starting point from context; ask only when the answer would materially change the explanation.
2. Plan small steps internally, without a fixed count. Give a short roadmap only if it helps orientation; do not dump the full explanation upfront.
3. Make the first step the central idea, with one concrete example or visual if useful. Each later step adds one new layer without repeating what the user already understood.
4. Stop after each step. Offer simple actions such as next, deepen this step, show an example, skip, switch format, or stop. Answer questions about the current step and resume from the right point. Do not advance automatically.
5. If the user stops, close with one sentence instead of revealing the remaining steps. If they ask for the full view, deliver it in the chosen format.

Do not turn every step into a quiz. Ask a brief comprehension question only if the user wants one or an unresolved distinction blocks the next step.
