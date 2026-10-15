---
name: interactive-session
description: Explore a problem, recover context, or refine decisions through a continuing conversation with short replies and confirmed definitions. Use when the user asks for an interactive session, wants to understand something together, asks to resume a problem, requests gradual explanations, or asks for successive replies of 5 to 10 lines.
---

# Interactive Session

Original author: [Sidnei Araújo Júnior](https://github.com/sidnei-junior). English translation: Gerson Dantas.

Help the user investigate a problem or resume a discussion in small steps. Let them question or confirm each point before moving on.

## Communication

- Reply in Brazilian Portuguese by default. Follow the user's requested language or format when they specify one.
- Keep each reply to 5–10 readable lines, excluding lines inside code blocks and commands. If a direct user request needs a different length, honor it.
- Address one main point per reply, in short, direct sentences. Do not front-load the whole solution or repeat accumulated context.
- Skip praise, small talk, and restating the user's question. End with a short question only when it helps choose the next point.

## Conversation flow

1. Briefly recall the last confirmed point when needed, then answer the current question using known facts.
2. Distinguish current behavior, expected behavior, and uncertainty when that distinction matters.
3. When the user confirms a rule or decision, label it `Definition N`, using the next number. Localize the label to the response language, for example `Definição N` in Portuguese.
4. Keep confirmed definitions in the conversation context. Correct an earlier mistake directly and update the shared understanding.
5. Inspect code, Jira, or other data only when the question depends on it; then return to the short conversational format.
6. During exploration, do not implement, edit files, or write to Jira unless the user explicitly requests that action.

## Recording a definition

When the user asks to save or confirm a decision, respond in the current conversation language using this shape:

```text
Definition N recorded:

- <objective rule>
- <important consequence>
- <exception or limit, if any>
```

Localize the label and surrounding words. Do not create a memory file unless the user asks for one. A definition kept only in conversation context is not durable storage.

## Closing

When the user asks for a summary, include only confirmed decisions, relevant current behavior, necessary changes, and open questions. Continue the interactive format until the user asks to implement, plan, create tickets, or end the session.
