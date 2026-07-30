---
name: timem-writing-memory
description: >-
  Calls TiMEM MCP search_memories / create_memory for writing-scene memory (style, tone,
  audience, series conventions). Use when TiMEM MCP is connected and the user is creating
  content, copywriting, editing tone/style/audience, documentation, or creative writing
  (文案, 写作, 风格, 语气, 受众, 草稿, copy, tone, audience, style). Default: search early
  when prior style/audience may help — including without explicit recall wording. Skip only
  one-off grammar tweaks with no style context, coding/debug (timem-coding-memory), personal
  non-writing prefs (timem-general-memory), or when MCP is disconnected.
---

# TiMEM Writing Memory

Orchestrate **writing** scene (`domain=writing`, `expert_id=writer`) memory search and create using MCP atomic tools only.

## MCP preference (writing)

**Search default on; write default off.** When TiMEM MCP is connected and the turn is writing-related:

1. **Default: call `search_memories` first** when prior style, tone, audience, or series conventions could shape the draft — even without “按之前的语气”.
2. **When unsure → search** — Skip only one-off edits with no reusable style context.
3. **Do not under-call** — “I can draft without tools” is **not** a reason to skip search when style/audience may matter.
4. **Write stays gated** — more search ≠ more `create_memory`; create only when reusable style rules are confirmed.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: see [references/mcp-tools.md](references/mcp-tools.md)

## Parameters

| Field | Value |
|-------|-------|
| `domain` | `writing` |
| `session_id` | **Optional** — stable series/doc name (e.g. `blog-2026`, `product-launch-copy`) |

Do **not** use random UUIDs per turn.

## Per-turn checklist

```
- [ ] 1. Skip only one-off grammar/punctuation with no style context; else call search_memories FIRST
- [ ] 2. search_memories(domain=writing, query_text=3–12 words, session_id=optional series)
- [ ] 3. Apply verified style/audience constraints to draft
- [ ] 4. Produce or revise content
- [ ] 5. Gated create? Confirmed reusable style/audience/forbidden words → create_memory
```

## When to search

- User wants output matching prior style ("按之前的语气", "same tone as last time")
- User asks what style/audience was established
- Starting or continuing a piece where stored style/audience may help — **even without** explicit recall wording
- Starting a new piece in an ongoing series (use `session_id`)
- When unsure → **search**

Do **not** search for unrelated coding tasks or pure personal non-writing prefs.

## When to create

- User confirms style, tone, audience, or forbidden words to reuse
- User says remember this writing preference
- A reusable writing convention is established for a series

Do **not** create: one-off drafts with no reusable insight, full article dumps.

Max **0–3** writing memories per task.

## What to remember (priority)

1. Style and tone preferences
2. Target audience and voice
3. Common phrases, examples, forbidden words
4. Formats or themes the user prefers

## Anti-patterns

- Do not use `domain=coding` for pure writing work
- Do not skip search because the model can draft without tools when style/audience may matter
- Do not create every draft — write stays gated
- Do not store entire articles in `messages` — summarize constraints

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)
