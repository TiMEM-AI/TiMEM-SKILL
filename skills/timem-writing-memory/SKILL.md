---
name: timem-writing-memory
description: >-
  Orchestrates TiMEM writing-scene memory recall and persistence via MCP atomic tools.
  Use when TiMEM MCP is connected and the user is creating content, copywriting, editing tone,
  style, audience, documentation, or creative writing (文案, 写作, 风格, 语气, 受众).
---

# TiMEM Writing Memory

Orchestrate **writing** scene (`domain=writing`, `expert_id=writer`) memory search and create using MCP atomic tools only.

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
- [ ] 1. Decide if search is needed (see references/workflow.md)
- [ ] 2. If yes → search_memories(domain=writing, query_text=...)
- [ ] 3. Apply verified style/audience constraints to draft
- [ ] 4. Produce or revise content
- [ ] 5. Decide if create is needed
- [ ] 6. If yes → create_memory(domain=writing, messages=2-4 turns)
```

## When to search

- User wants output matching prior style ("按之前的语气", "same tone as last time")
- User asks what style/audience was established
- Starting a new piece in an ongoing series (use `session_id`)

Do **not** search for unrelated coding tasks.

## When to create

- User confirms style, tone, audience, or forbidden words to reuse
- User says remember this writing preference
- A reusable writing convention is established for a series

Do **not** create: one-off drafts with no reusable insight, full article dumps.

## What to remember (priority)

1. Style and tone preferences
2. Target audience and voice
3. Common phrases, examples, forbidden words
4. Formats or themes the user prefers

## Anti-patterns

- Do not call `should_*`, `begin_coding_turn`, or `end_coding_turn`
- Do not use `domain=coding` for pure writing work
- Do not store entire articles in `messages` — summarize constraints

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)
