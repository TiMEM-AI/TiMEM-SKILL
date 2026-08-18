---
name: timem-writing-memory
description: >-
  Calls TiMEM MCP search_memories / create_memory for writing-scene memory (style, tone,
  audience, series conventions). AUTO on EVERY turn when TiMEM MCP is connected:
  call search_memories BEFORE generating reply, then create_memory AFTER generating
  reply. No exceptions, no skip. If user message contains "记", MUST call
  create_memory. Coding/debug (timem-coding-memory), personal non-writing prefs
  (timem-general-memory).
---

# TiMEM Writing Memory

Orchestrate **writing** scene (`domain=writing`, `expert_id=writer`) memory search and create using MCP atomic tools only.

## Trigger

When TiMEM MCP is connected — **every turn, no exceptions**.

## Instructions

1. **Search**: Call `search_memories` BEFORE generating reply (domain=writing)
2. **Reply**: Generate reply using recalled style/audience context
3. **Create**: Call `create_memory` AFTER generating reply, passing 2-4 recent turns — **every turn, no skip**
4. **"记"字强制**: If user message contains "记", MUST call `create_memory` even if you think there's nothing new to store

## Example

Input: User says "按之前的语气写一段产品介绍"

1. `search_memories(domain="writing", query_text="产品介绍 语气 风格", session_id="product-launch-copy")` → returns 1 hit with established tone guidelines
2. Write the product introduction matching the established style
3. `create_memory(domain="writing", session_id="product-launch-copy", messages=[...recent turns...])`

Input: User says "记住，我们的文案风格要简洁直接"

1. `search_memories(domain="writing", query_text="文案风格 简洁直接", session_id="product-launch-copy")`
2. Reply confirming
3. `create_memory(domain="writing", session_id="product-launch-copy", messages=[...recent turns...])` — "记"字触发，必须保存

## Changelog

- 0.1.0 (2026-08-18): Initial config.yaml, added Trigger/Instructions/Example/Changelog sections per skill development spec

## MCP preference (writing)

**Search and create every turn.** When TiMEM MCP is connected:

1. **Call `search_memories` BEFORE generating reply** — every turn, no exceptions.
2. **Call `create_memory` AFTER generating reply** — every turn, no exceptions.
3. **No skip** — "I can draft without tools" is **not** a skip reason. "One-off edit" is **not** a skip reason.
4. **"记"字规则**: If user message contains "记", MUST call `create_memory`. No exceptions.

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
1. search_memories(domain=writing, query_text=3–12 words, session_id=optional series) — BEFORE reply
2. Generate reply using recalled style/audience context
3. create_memory(domain=writing, messages=[2-4 recent turns]) — AFTER reply, every turn
4. If user message contains "记" → MUST call create_memory (redundant with #3, but explicit)
```

## When to search

**Every turn.** No exceptions.

## When to create

**Every turn.** No exceptions. If user message contains "记", MUST call `create_memory`.

## What to remember (priority)

1. Style and tone preferences
2. Target audience and voice
3. Common phrases, examples, forbidden words
4. Formats or themes the user prefers

## Anti-patterns

- Do not use `domain=coding` for pure writing work
- Do not skip search or create — every turn, no exceptions
- Do not store entire articles in `messages` — summarize constraints

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)
